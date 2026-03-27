Red [
    Title:   "QTorres — Compilador"
    Purpose: "Transforma un diagrama (modelo de grafo) en código Red dentro del .qvi"
]

; ══════════════════════════════════════════════════
; DIALECTO: emit
; ══════════════════════════════════════════════════
; El compilador no usa interpolación de strings.
; Cada bloque registrado define un bloque `emit` que es código Red
; con palabras que hacen referencia a los puertos del bloque.
;
; El compilador:
;   1. Ordena los nodos topológicamente
;   2. Para cada nodo, busca su definición en el block-registry
;   3. Toma el bloque `emit` y sustituye las palabras de los puertos
;      por los nombres reales de las variables (que vienen de los wires)
;   4. El resultado es código Red generado por manipulación de bloques Red
;
; Ejemplo:
;   El bloque 'add tiene: emit [result: a + b]
;   El nodo "Suma" recibe wire de "A" en puerto 'a y de "B" en puerto 'b
;   El compilador sustituye: a → A, b → B, result → Suma
;   Resultado: [Suma: A + B]
;
; Esto es manipulación de bloques Red, no strings. El código generado
; es un bloque Red que se puede componer, inspeccionar y ejecutar.

; ══════════════════════════════════════════════════
; TOPOLOGICAL-SORT
; ══════════════════════════════════════════════════
;
; Algoritmo de Kahn (BFS).
; Entrada:  un objeto diagrama con /nodes y /wires (make-diagram).
; Salida:   un block! con los nodos en orden de compilación,
;           o un error si se detecta un ciclo.

topological-sort: func [
    diagram [object!]
    /local nodes wires in-degree id-to-node queue result nid w
][
    nodes:  diagram/nodes
    wires:  diagram/wires

    in-degree:  make map! []
    id-to-node: make map! []
    foreach n nodes [
        in-degree/(n/id): 0
        id-to-node/(n/id): n
    ]

    foreach w wires [
        ; Ignorar wires con extremos virtuales (IDs negativos: iter, SR-left, SR-right)
        if all [w/from-node >= 0  w/to-node >= 0] [
            in-degree/(w/to-node): in-degree/(w/to-node) + 1
        ]
    ]

    queue: copy []
    foreach n nodes [
        if in-degree/(n/id) = 0 [append queue n/id]
    ]

    result: copy []
    while [not empty? queue] [
        nid: take queue
        append result id-to-node/:nid
        foreach w wires [
            if all [w/from-node = nid  w/to-node >= 0] [
                in-degree/(w/to-node): in-degree/(w/to-node) - 1
                if in-degree/(w/to-node) = 0 [append queue w/to-node]
            ]
        ]
    ]

    if (length? result) <> (length? nodes) [
        cause-error 'user 'message ["topological-sort: ciclo detectado en el diagrama"]
    ]

    result
]

; ══════════════════════════════════════════════════
; BUILD-SORTED-ITEMS
; ══════════════════════════════════════════════════
;
; Extiende topological-sort para incluir estructuras (while-loop)
; junto con los nodos normales en el orden de compilación.
;
; Las estructuras participan como nodos virtuales:
;   - Dependencia entrada: wire externo a SR-left  (to-node = st/id)
;   - Dependencia salida:  wire externo desde SR-right (from-node = st/id)
;
; Devuelve un bloque con objetos (nodo o estructura) en orden topológico.
; Para distinguirlos: los objetos de estructura tienen campo 'shift-regs.

build-sorted-items: func [
    diagram [object!]
    /local all-items in-degree id-to-item queue result nid w item
][
    all-items: copy diagram/nodes
    if all [in diagram 'structures  block? diagram/structures] [
        foreach st diagram/structures [append all-items st]
    ]

    in-degree:  make map! []
    id-to-item: make map! []
    foreach item all-items [
        in-degree/(item/id): 0
        id-to-item/(item/id): item
    ]

    foreach w diagram/wires [
        if w/from-node >= 0 [
            if not none? select in-degree w/to-node [
                in-degree/(w/to-node): in-degree/(w/to-node) + 1
            ]
        ]
    ]

    queue: copy []
    foreach item all-items [
        if in-degree/(item/id) = 0 [append queue item/id]
    ]

    result: copy []
    while [not empty? queue] [
        nid: take queue
        append result id-to-item/:nid
        foreach w diagram/wires [
            if w/from-node = nid [
                if not none? select in-degree w/to-node [
                    in-degree/(w/to-node): in-degree/(w/to-node) - 1
                    if in-degree/(w/to-node) = 0 [append queue w/to-node]
                ]
            ]
        ]
    ]

    result
]

; ══════════════════════════════════════════════════
; BIND-EMIT
; ══════════════════════════════════════════════════
;
; Sustituye los nombres de puertos en un bloque emit por variables reales.
;
; emit-block: bloque con palabras que corresponden a puertos
;             Ejemplo: [result: a + b]
; bindings:   bloque plano de pares [puerto valor ...]
;             Los valores pueden ser cualquier tipo Red.
;             Ejemplo: [a X  b Y  result Suma]
;
; Maneja word!, set-word! y bloques anidados. El resto pasa sin cambios.

bind-emit: func [
    emit-block [block!]
    bindings   [block!]
    /local result item k v
][
    result: copy []
    foreach item emit-block [
        case [
            word? item [
                v: select bindings item
                either none? v [
                    append result item
                ][
                    ; /only para block! values (ej: array defaults) — evita aplanar
                    either block? v [append/only result v] [append result v]
                ]
            ]
            set-word? item [
                k: to-word item
                v: select bindings k
                append result either all [v  any [word? v  lit-word? v]] [to-set-word v] [item]
            ]
            block? item [
                append/only result bind-emit item bindings
            ]
            true [append result item]
        ]
    ]
    result
]

; ══════════════════════════════════════════════════
; HELPERS
; ══════════════════════════════════════════════════

; Nombre de variable para el puerto de salida de un nodo.
; Convenio: name_portname  (ej: add_1_result)
; Usa node/name (DT-024), nunca node/label/text.
port-var: func [node [object!] port-name [word! lit-word!]] [
    to-word rejoin [node/name "_" to-word port-name]
]

; Construye los bindings [puerto var ...] para un nodo concreto del diagrama:
;   - puertos de salida: variable propia (label_portname)
;   - puertos de entrada: variable del nodo fuente conectado por wire
;   - configs: valor del nodo o el default de la definición
build-bindings: func [
    node    [object!]
    diagram [object!]
    bdef    [object!]
    /local bindings p w src cfg-val found _var
][
    bindings: copy []

    foreach p bdef/outputs [
        append bindings p/name
        append bindings port-var node p/name
    ]

    foreach p bdef/inputs [
        foreach w diagram/wires [
            if all [w/to-node = node/id  (to-word w/to-port) = p/name] [
                case [
                    ; Nodos virtuales negativos: iter (-3) y SR-left (-1)
                    w/from-node < 0 [
                        ; Iter (-3): from-port ya es la variable (_while_N_i)
                        ; SR-left (-1): from-port es sr/name → variable es _sr_name
                        _var: either w/from-node = -1 [
                            to-word rejoin ["_" form w/from-port]
                        ][
                            w/from-port
                        ]
                        append bindings p/name
                        append bindings _var
                    ]
                    ; Nodo fuente normal
                    true [
                        found: false
                        foreach src diagram/nodes [
                            if src/id = w/from-node [
                                append bindings p/name
                                append bindings port-var src w/from-port
                                found: true
                            ]
                        ]
                        ; Nodo fuente es una estructura (SR-right → externo, task 10.5)
                        if all [not found  in diagram 'structures  block? diagram/structures] [
                            foreach st diagram/structures [
                                if st/id = w/from-node [
                                    ; Variable SR: _sr_name
                                    append bindings p/name
                                    append bindings to-word rejoin ["_" form w/from-port]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]

    foreach cfg bdef/configs [
        ; any [none false] = none en Red → usar either/none? explícito
        cfg-val: either none? select node/config cfg/name [cfg/default] [select node/config cfg/name]
        append bindings cfg/name
        ; /only evita aplanar block! values (ej: array defaults como [1.0 2.0])
        append/only bindings cfg-val
    ]

    bindings
]

; Devuelve true si el primer output del bloque es de tipo array.
node-array-input?: func [node /local bdef] [
    bdef: find-block to-word node/type
    if all [bdef  not empty? bdef/outputs] [
        return bdef/outputs/1/type = 'array
    ]
    false
]

; Devuelve true si el primer output del bloque es de tipo booleano.
node-boolean-input?: func [node /local bdef] [
    bdef: find-block to-word node/type
    if all [bdef  not empty? bdef/outputs] [
        return bdef/outputs/1/type = 'boolean
    ]
    false
]

; Devuelve true si el primer output del bloque es de tipo string.
node-string-input?: func [node /local bdef] [
    bdef: find-block to-word node/type
    if all [bdef  not empty? bdef/outputs] [
        return bdef/outputs/1/type = 'string
    ]
    false
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
                foreach src outer-diagram/nodes [
                    if src/id = w/from-node [
                        n-val: port-var src to-word w/from-port
                    ]
                ]
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
                    foreach src outer-diagram/nodes [
                        if src/id = w/from-node [
                            init-val: port-var src to-word w/from-port
                        ]
                    ]
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
                foreach src outer-diagram/nodes [
                    if src/id = w/from-node [
                        init-val: port-var src to-word w/from-port
                    ]
                ]
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
        cond-node: none
        foreach nd st/nodes [if nd/id = st/cond-wire/from [cond-node: nd]]
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
        sel-node: none
        foreach nd outer-diagram/nodes [
            if nd/id = st/selector-wire/from [sel-node: nd]
        ]
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

; ══════════════════════════════════════════════════
; COMPILE-BODY
; ══════════════════════════════════════════════════
;
; Genera el bloque de cómputo headless listo para ejecutar con do.
; Incluye todos los nodos normales y las estructuras.

compile-body: func [
    diagram [object!]
    /local sorted code item bdef
][
    sorted: build-sorted-items diagram
    code: copy []
    foreach item sorted [
        case [
            find [while-loop for-loop case-structure] item/type [
                append code compile-structure/no-gui item diagram
            ]
            true [
                bdef: find-block item/type
                if all [bdef  bdef/emit] [
                    append code bind-emit bdef/emit (build-bindings item diagram bdef)
                ]
            ]
        ]
    ]
    code
]

; ══════════════════════════════════════════════════
; COMPILE-DIAGRAM
; ══════════════════════════════════════════════════
;
; Genera los componentes de código para un VI completo:
;   /headless:  block! ejecutable con do (usa config defaults)
;   /ui-layout: block! para view layout (controles + botón Run + indicadores)
;
; Para nodos de categoría 'input: el run-body lee de campos de texto del UI.
; Para nodos de categoría 'output: el run-body escribe en etiquetas del UI.
; Para nodos math: usa bind-emit igual que compile-body.

compile-diagram: func [
    diagram [object!]
    /local sorted headless run-body ui-layout item node bdef face-n cfg-val w src src-var bindings
][
    sorted:   build-sorted-items diagram
    headless: compile-body diagram

    ; ── Cuerpo del botón Run (modo UI) ────────────────────────
    run-body: copy []
    foreach item sorted [
        case [
            find [while-loop for-loop] item/type [
                append run-body compile-structure item diagram
            ]
            item/type = 'case-structure [
                append run-body compile-case-structure/no-gui item diagram
            ]
            true [
                node: item
                bdef: find-block node/type
                if none? bdef [continue]
                case [
                    bdef/category = 'input [
                        case [
                            node-array-input? node [
                                ; Array control: valor fijo del config (no hay field editable — DT-028)
                                if bdef/emit [
                                    append run-body bind-emit bdef/emit (build-bindings node diagram bdef)
                                ]
                            ]
                            true [
                                face-sym: to-word rejoin ["f_" node/id]
                                case [
                                    node-boolean-input? node [
                                        append run-body compose [(to-set-word port-var node 'result) (to-path reduce [face-sym 'data])]
                                    ]
                                    node-string-input? node [
                                        append run-body compose [(to-set-word port-var node 'result) (to-path reduce [face-sym 'text])]
                                    ]
                                    true [
                                        append run-body compose [(to-set-word port-var node 'result) to-float (to-path reduce [face-sym 'text])]
                                    ]
                                ]
                            ]
                        ]
                    ]
                    bdef/category = 'output [
                        face-sym: to-word rejoin ["t_" node/id]
                        foreach w diagram/wires [
                            if w/to-node = node/id [
                                ; Fuente: nodo normal
                                foreach src diagram/nodes [
                                    if src/id = w/from-node [
                                        src-var: port-var src to-word w/from-port
                                        append run-body compose [(to set-path! reduce [face-sym 'text]) form (src-var)]
                                    ]
                                ]
                                ; Fuente: estructura (SR-right → indicador externo)
                                if all [in diagram 'structures  block? diagram/structures] [
                                    foreach st diagram/structures [
                                        if st/id = w/from-node [
                                            src-var: to-word rejoin ["_" form w/from-port]
                                            append run-body compose [(to set-path! reduce [face-sym 'text]) form (src-var)]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                    true [
                        if bdef/emit [
                            bindings: build-bindings node diagram bdef
                            append run-body bind-emit bdef/emit bindings
                        ]
                    ]
                ]
            ]
        ]
    ]

    ; ── Layout del Front Panel ────────────────────────────────
    ui-layout: copy []
    foreach item sorted [
        if in item 'shift-regs [continue]  ; saltar estructuras
        node: item
        bdef: find-block node/type
        if none? bdef [continue]
        if bdef/category = 'input [
            ; Array control: sin widget — valor fijo, no aparece en UI layout
            if node-array-input? node [continue]

            face-n: to-word rejoin ["f_" node/id]
            ; any [none false] = none en Red (false es falsy) → usar either/none? explícito
            cfg-val: either none? select node/config 'default [
                case [
                    node-boolean-input? node [false]
                    node-string-input?  node [""]
                    true                     [0.0]
                ]
            ][
                select node/config 'default
            ]
            node-label: either all [node/label  object? node/label] [node/label/text] [any [node/name ""]]
            append ui-layout 'text
            ; UI layout usa label/text (display) para textos visibles (DT-024)
            append ui-layout node-label
            append ui-layout to-set-word face-n
            case [
                node-boolean-input? node [
                    ; Control booleano: check face, lee face/data (logic!)
                    append ui-layout 'check
                    append ui-layout node-label
                    append ui-layout cfg-val
                ]
                node-string-input? node [
                    ; Control string: field editable, lee face/text directamente
                    append ui-layout 'field
                    append ui-layout cfg-val
                ]
                true [
                    append ui-layout 'field
                    append ui-layout form cfg-val
                ]
            ]
        ]
    ]

    append ui-layout 'button
    append ui-layout "Run"
    append/only ui-layout run-body
    foreach item sorted [
        if in item 'shift-regs [continue]  ; saltar estructuras
        node: item
        bdef: find-block node/type
        if none? bdef [continue]
        if bdef/category = 'output [
            face-n: to-word rejoin ["t_" node/id]
            append ui-layout 'text
            ; UI layout usa label/text (display) para textos visibles (DT-024)
            append ui-layout either all [node/label  object? node/label] [node/label/text] [any [node/name ""]]
            append ui-layout to-set-word face-n
            append ui-layout 'text
            append ui-layout "---"
        ]
    ]

    result-map: make map! []
    result-map/headless:  headless
    result-map/ui-layout: ui-layout
    result-map
]

#include %../runner/runner.red
