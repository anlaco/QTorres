Red [
    Title:   "Telekino — Compilador (estructuras de control)"
    Purpose: "Compilación de while-loop, for-loop y case-structure"
]

; ══════════════════════════════════════════════════
; COMPILE-STRUCTURE
; ══════════════════════════════════════════════════
;
; Genera el bloque de código para una estructura while-loop:
;   _sr_name: <init-value o variable-externa>  ; por cada SR
;   _while_N_i: 0
;   until [
;       <nodos internos compilados>
;       _sr_name: <nodo-que-escribe-en-SR>      ; actualización SR
;       _while_N_i: _while_N_i + 1
;       <condición>   ; true si no conectada
;   ]
;
; outer-diagram: diagrama que contiene la estructura (para wires externos de SR).

compile-structure: func [
    st           [object!]
    outer-diagram [object!]
    /no-gui       ; omite do-events/no-wait (modo headless — sin View)
    /local iter-sym sub-diag sorted code loop-body until-body node bdef cond-expr cond-node
           sr sr-sym init-val w src src-node n-sym n-val
][
    ; ── CASE-STRUCTURE: compila a case/either ──────────────────────
    if st/type = 'case-structure [
        return compile-case-structure/no-gui st outer-diagram
    ]

    iter-sym: to-word rejoin ["_" st/name "_i"]

    ; Sub-diagrama ficticio: expone nodes/wires para topological-sort y build-bindings
    sub-diag: make object! [
        nodes: st/nodes
        wires: st/wires
    ]

    code: copy []

    ; ── FOR-LOOP: compila a loop N [...] ───────────────────────
    if st/type = 'for-loop [
        ; Resolver wire de N obligatorio desde outer-diagram/wires
        n-sym: to-word rejoin ["_" st/name "_N"]
        n-val: none
        foreach w outer-diagram/wires [
            if all [w/to-node = st/id  w/to-port = 'count] [
                src: find-node-by-id outer-diagram/nodes w/from-node
                if src [n-val: port-var src to-word w/from-port]
            ]
        ]
        if none? n-val [
            print rejoin ["ERROR: For Loop '" st/name "' — terminal N no conectado (obligatorio)"]
            return copy []
        ]

        ; Init N (to-integer: controles producen float!, loop requiere integer!)
        append code to-set-word n-sym
        append code 'to-integer
        append code n-val

        ; Init SRs (mismo patrón que while-loop)
        foreach sr st/shift-regs [
            sr-sym:   to-word rejoin ["_" sr/name]
            init-val: sr/init-value
            foreach w outer-diagram/wires [
                if all [w/to-node = st/id  (to-word w/to-port) = to-word sr/name] [
                    src: find-node-by-id outer-diagram/nodes w/from-node
                    if src [init-val: port-var src to-word w/from-port]
                ]
            ]
            append code to-set-word sr-sym
            append code init-val
        ]

        ; Init contador de iteración
        append code to-set-word iter-sym
        append code 0

        ; Compilar cuerpo interno
        loop-body: copy []
        sorted: either empty? st/nodes [copy []] [topological-sort sub-diag]
        foreach node sorted [
            bdef: find-block node/type
            if all [bdef  bdef/emit] [
                append loop-body bind-emit bdef/emit (build-bindings node sub-diag bdef)
            ]
        ]

        ; Actualización de SRs
        foreach sr st/shift-regs [
            sr-sym: to-word rejoin ["_" sr/name]
            foreach w st/wires [
                if all [w/to-node = -2  (to-word w/to-port) = to-word sr/name] [
                    foreach src-node st/nodes [
                        if src-node/id = w/from-node [
                            append loop-body to-set-word sr-sym
                            append loop-body port-var src-node to-word w/from-port
                        ]
                    ]
                ]
            ]
        ]

        ; Incrementar _i
        append loop-body to-set-word iter-sym
        append loop-body iter-sym
        append loop-body to-word "+"
        append loop-body 1

        ; GUI responsiva (DT-027) — solo en modo UI (no en headless)
        unless no-gui [append/only loop-body to-path [do-events no-wait]]

        ; loop N [body]
        append code 'loop
        append code n-sym
        append/only code loop-body

        return code
    ]

    ; ── WHILE-LOOP: compila a until [...] ──────────────────────

    ; ── Inicialización de shift registers ──────────────────────
    foreach sr st/shift-regs [
        sr-sym:   to-word rejoin ["_" sr/name]
        init-val: sr/init-value  ; valor por defecto (literal)
        ; ¿Hay un wire externo que inicializa este SR?
        foreach w outer-diagram/wires [
            if all [w/to-node = st/id  (to-word w/to-port) = to-word sr/name] [
                src: find-node-by-id outer-diagram/nodes w/from-node
                if src [init-val: port-var src to-word w/from-port]
            ]
        ]
        append code to-set-word sr-sym
        append code init-val
    ]

    ; Inicialización del contador de iteración
    append code to-set-word iter-sym
    append code 0

    ; Compilar cuerpo interno
    until-body: copy []
    sorted: either empty? st/nodes [copy []] [topological-sort sub-diag]
    foreach node sorted [
        bdef: find-block node/type
        if all [bdef  bdef/emit] [
            append until-body bind-emit bdef/emit (build-bindings node sub-diag bdef)
        ]
    ]

    ; ── Actualización de shift registers (antes del incremento) ─
    foreach sr st/shift-regs [
        sr-sym: to-word rejoin ["_" sr/name]
        foreach w st/wires [
            if all [w/to-node = -2  (to-word w/to-port) = to-word sr/name] [
                foreach src-node st/nodes [
                    if src-node/id = w/from-node [
                        append until-body to-set-word sr-sym
                        append until-body port-var src-node to-word w/from-port
                    ]
                ]
            ]
        ]
    ]

    ; Incrementar iteración: _iter: _iter + 1
    append until-body to-set-word iter-sym
    append until-body iter-sym
    append until-body to-word "+"
    append until-body 1

    ; Ceder control a la GUI una vez por iteración (DT-027 Fase 2)
    ; do-events/no-wait: procesa eventos pendientes y vuelve inmediatamente
    ; Solo en modo UI — en headless no hay View y do-events cuelga
    unless no-gui [append/only until-body to-path [do-events no-wait]]

    ; Condición final (última expresión del until)
    cond-expr: either st/cond-wire [
        cond-node: find-node-by-id st/nodes st/cond-wire/from
        either cond-node [
            port-var cond-node st/cond-wire/port
        ][
            true
        ]
    ][
        true  ; sin condición conectada: ejecuta una vez
    ]
    append until-body cond-expr

    ; until [body]
    append code 'until
    append/only code until-body

    code
]

; ══════════════════════════════════════════════════
; COMPILE-CASE-STRUCTURE
; ══════════════════════════════════════════════════
;
; Genera el bloque de código para una Case Structure:
;   _case_selector: <variable-externa>
;   case _case_selector [
;       0 [<nodos del frame 0>]
;       1 [<nodos del frame 1>]
;       default [<nodos del default frame>]
;   ]
;
; Si el selector es booleano, genera:
;   _case_selector: <variable-externa>
;   either _case_selector [<frame true>] [<frame false>]
;
; outer-diagram: diagrama que contiene la estructura.

compile-case-structure: func [
    st           [object!]
    outer-diagram [object!]
    /no-gui
    /local code sel-var sel-type sel-node sel-port frame bdef sub-diag sorted frame-code case-block case-item
            frame-label
][
    code: copy []

    ; ── Resolver selector wire ───────────────────────────────────
    sel-var: none
    sel-type: 'number  ; default
    if st/selector-wire [
        sel-node: find-node-by-id outer-diagram/nodes st/selector-wire/from
        if sel-node [
            sel-port: to-word st/selector-wire/port
            sel-var: port-var sel-node sel-port
            ; Detectar tipo del selector
            bdef: find-block sel-node/type
            if bdef [
                foreach p bdef/outputs [
                    if p/name = sel-port [sel-type: p/type]
                ]
            ]
        ]
    ]
    if none? sel-var [
        print rejoin ["WARNING: Case Structure '" st/name "' — selector no conectado, usando 0"]
        sel-var: 0
    ]

    ; Variable del selector
    append code to-set-word to-word rejoin ["_" st/name "_selector"]
    append code sel-var

    ; ── Selector booleano → either ─────────────────────────────────
    if sel-type = 'boolean [
        case-block: copy []
        append case-block 'either
        append case-block to-word rejoin ["_" st/name "_selector"]

        ; Frame true (primer frame)
        frame-code: copy []
        if all [block? st/frames  not empty? st/frames] [
            frame: st/frames/1
            sub-diag: make object! [nodes: frame/nodes  wires: frame/wires]
            sorted: either empty? frame/nodes [copy []] [topological-sort sub-diag]
            foreach node sorted [
                bdef: find-block node/type
                if all [bdef  bdef/emit] [
                    append frame-code bind-emit bdef/emit (build-bindings node sub-diag bdef)
                ]
            ]
        ]
        append/only case-block frame-code

        ; Frame false (segundo frame si existe)
        frame-code: copy []
        if all [block? st/frames  (length? st/frames) >= 2] [
            frame: st/frames/2
            sub-diag: make object! [nodes: frame/nodes  wires: frame/wires]
            sorted: either empty? frame/nodes [copy []] [topological-sort sub-diag]
            foreach node sorted [
                bdef: find-block node/type
                if all [bdef  bdef/emit] [
                    append frame-code bind-emit bdef/emit (build-bindings node sub-diag bdef)
                ]
            ]
        ]
        append/only case-block frame-code

        append code case-block
        return code
    ]

    ; ── Selector numérico → case [sel = 0 [...] sel = 1 [...] true [...]] ──
    sel-word: to-word rejoin ["_" st/name "_selector"]
    inner-block: copy []
    has-default: false

    if block? st/frames [
        foreach frame st/frames [
            frame-code: copy []
            sub-diag: make object! [nodes: frame/nodes  wires: frame/wires]
            sorted: either empty? frame/nodes [copy []] [topological-sort sub-diag]
            foreach node sorted [
                bdef: find-block node/type
                if all [bdef  bdef/emit] [
                    append frame-code bind-emit bdef/emit (build-bindings node sub-diag bdef)
                ]
            ]
            frame-label: any [attempt [to-integer frame/label]  'default]
            either frame-label = 'default [
                append inner-block true
                has-default: true
            ][
                append inner-block sel-word
                append inner-block '=
                append inner-block frame-label
            ]
            append/only inner-block frame-code
        ]
    ]

    ; Añadir default vacío si no hay ninguno
    if not has-default [
        append inner-block true
        append/only inner-block copy []
    ]

    append code 'case
    append/only code inner-block
    code
]
