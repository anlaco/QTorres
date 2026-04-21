Red [
    Title:   "Telekino — Compilador (body: compile-body, compile-diagram, sub-VI calls)"
    Purpose: "Núcleo del compilador — orquesta emit + estructuras para generar cuerpo y layout"
]

; ══════════════════════════════════════════════════
; SUBVI COMPILATION (Fase 3)
; ══════════════════════════════════════════════════

; Genera código para llamar a un sub-VI.
; La función del sub-VI viene de node/config/func-name.
; Los argumentos vienen de los wires conectados a los puertos de entrada del connector.
; Los resultados se asignan a variables de los puertos de salida.
compile-subvi-call: func [
    node    [object!]
    diagram [object!]
    /local func-name connector inputs outputs code arg-vars out-var w src pin-word
][
    code: copy []

    ; Obtener función y connector del config
    func-name: select node/config 'func-name
    connector: select node/config 'connector
    if any [none? func-name  none? connector] [return code]

    inputs: any [select connector 'inputs  copy []]
    outputs: any [select connector 'outputs  copy []]

    ; Recolectar argumentos de los wires conectados a cada puerto de entrada
    ; inputs es [pin label id  pin label id ...]
    arg-vars: copy []
    repeat i ((length? inputs) / 3) [
        pin-word: to-word rejoin ["p" inputs/(i * 3 - 2)]  ; pin → 'p1, 'p2...
        found: false
        foreach w diagram/wires [
            if all [
                w/to-node = node/id
                (to-word w/to-port) = pin-word
            ][
                src: find-node-by-id diagram/nodes w/from-node
                if src [
                    append arg-vars port-var src to-word w/from-port
                    found: true
                ]
            ]
        ]
        ; Si no hay wire, usar valor por defecto 0.0
        if not found [append arg-vars 0.0]
    ]

    ; Generar llamada: resultado: func-name/exec arg1 arg2 ...
    ; outputs es [pin label id  pin label id ...]
    ; Por simplicidad, asumimos una sola salida (la primera)
    if not empty? outputs [
        out-pin: to-word rejoin ["p" outputs/1]  ; pin del primer output
        out-var: port-var node out-pin
        append code to-set-word out-var
    ]

    ; Añadir la llamada a la función: func-name/exec (append/only para no extender el path)
    append/only code to-path reduce [to-word func-name 'exec]
    foreach arg arg-vars [append code arg]

    code
]

; ══════════════════════════════════════════════════
; COMPILE-BODY
; ══════════════════════════════════════════════════
;
; Genera el bloque de cómputo headless listo para ejecutar con do.
; Incluye todos los nodos normales y las estructuras.

compile-body: func [
    diagram  [object!]
    /with-prints  ; añade print por indicador — solo para ejecución standalone (red-cli .qvi)
    /local sorted code item bdef
][
    sorted: build-sorted-items diagram
    code: copy []
    foreach item sorted [
        case [
            find [while-loop for-loop case-structure] item/type [
                append code compile-structure/no-gui item diagram
            ]
            item/type = 'bundle              [append code emit-bundle                   item diagram]
            item/type = 'unbundle            [append code emit-unbundle                 item diagram]
            item/type = 'cluster-control     [append code emit-cluster-control-headless item diagram]
            item/type = 'cluster-indicator   [append code emit-cluster-indicator-headless item diagram]
            item/type = 'subvi               [append code compile-subvi-call            item diagram]
            true [
                bdef: find-block item/type
                if all [bdef  bdef/emit] [
                    append code bind-emit bdef/emit (build-bindings item diagram bdef)
                ]
            ]
        ]
    ]

    ; Prints para modo standalone (red-cli .qvi) — solo con /with-prints
    if with-prints [
        foreach item sorted [
            bdef: find-block item/type
            if none? bdef [continue]
            if bdef/category = 'output [
                if all [in diagram 'wires  block? diagram/wires] [
                    foreach w diagram/wires [
                        if w/to-node = item/id [
                            src: find-node-by-id diagram/nodes w/from-node
                            if src [
                                src-var: port-var src to-word w/from-port
                                lbl: either all [item/label  object? item/label] [item/label/text] [any [item/name ""]]
                                ; Construir [print rejoin ["label" ": " form var-word]] sin compose
                                append code 'print
                                append code 'rejoin
                                append/only code reduce [copy lbl ": " 'form to-word src-var]
                            ]
                        ]
                    ]
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
    headless: compile-body/with-prints diagram

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
            item/type = 'bundle            [append run-body emit-bundle            item diagram]
            item/type = 'unbundle          [append run-body emit-unbundle          item diagram]
            item/type = 'cluster-control   [append run-body emit-cluster-control   item diagram]
            item/type = 'cluster-indicator [append run-body emit-cluster-indicator item diagram]
            item/type = 'subvi             [append run-body compile-subvi-call     item diagram]
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
                                src: find-node-by-id diagram/nodes w/from-node
                                if src [
                                    src-var: port-var src to-word w/from-port
                                    append run-body compose [(to set-path! reduce [face-sym 'text]) form (src-var)]
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

    ; ── Recopilar sub-VIs referenciados para #include (Fase 3) ────────────
    subvi-files: copy []
    subvi-names: copy []
    foreach item sorted [
        if item/type = 'subvi [
            if all [in item 'file  file? item/file] [
                ; Evitar duplicados
                if not find subvi-files item/file [
                    append subvi-files item/file
                    ; Recopilar nombre de función para validación
                    func-nm: select item/config 'func-name
                    if func-nm [
                        append subvi-names func-nm
                    ]
                ]
            ]
        ]
    ]

    result-map: make map! []
    result-map/headless:  headless
    result-map/ui-layout: ui-layout
    result-map/subvi-files: subvi-files
    result-map/subvi-names: subvi-names
    result-map
]
