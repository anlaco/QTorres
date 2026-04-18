Red [
    Title:   "QTorres — File I/O (carga de .qvi)"
    Purpose: "load-vi + helpers — reconstruye el modelo desde un .qvi"
]

; ══════════════════════════════════════════════════
; LOAD-VI
; ══════════════════════════════════════════════════
;
; Lee un fichero .qvi, extrae qvi-diagram y reconstruye el modelo en memoria.
; El código generado se ignora — QTorres recompila desde qvi-diagram (DT-011).
; Un .qvi con solo qvi-diagram (sin código generado) es válido.

; Convierte set-words a words en un bloque (recursivo para sub-bloques).
; Permite que make-node/make-wire funcionen igual con .qvi nuevos (set-words)
; y con .qvi antiguos (words). model.red no necesita cambios.
norm-spec: func [spec [block!] /local result item] [
    result: copy []
    foreach item spec [
        case [
            set-word? item [append result to-word item]
            block?    item [append/only result norm-spec item]
            true           [append result item]
        ]
    ]
    result
]

; Parsea una lista de nodos [node [...] ...] y devuelve objetos make-node.
; Si abs-x/abs-y están dados, convierte coords relativas a absolutas.
load-node-list: func [
    nodes-data [block!] names [block!]
    /absolute abs-x abs-y
    /local node-spec nx ny n
][
    collect [
        parse nodes-data [
            any [
                'node set node-spec block! (
                    ; Convertir coords relativas a absolutas si se indica
                    if absolute [
                        nx: any [select node-spec 'x  0]
                        ny: any [select node-spec 'y  0]
                        node-spec: copy node-spec
                        if pos: find node-spec 'x [pos/2: nx + abs-x]
                        if pos: find node-spec 'y [pos/2: ny + abs-y]
                    ]
                    ; Subvi: cargar connector desde el fichero referenciado
                    n: either (select node-spec 'type) = 'subvi [
                        make-subvi-node node-spec
                    ][
                        make-node node-spec
                    ]
                    if select node-spec 'name [append names select node-spec 'name]
                    keep n
                )
                | skip
            ]
        ]
    ]
]

; Parsea una lista de wires [wire [...] ...] y devuelve objetos make-wire.
load-wire-list: func [wires-data [block!] /local wire-spec] [
    collect [
        parse wires-data [
            any [
                'wire set wire-spec block! (
                    keep make-wire compose [
                        from: (select wire-spec 'from)
                        from-port: (any [select wire-spec 'from-port  select wire-spec 'port])
                        to: (select wire-spec 'to)
                        to-port: (any [select wire-spec 'to-port  select wire-spec 'port])
                    ]
                )
                | skip
            ]
        ]
    ]
]

load-vi: func [
    path [file!]
    /local src pos qd bd-data nodes-data wires-data structs-data d names st-spec st st-nodes st-wires cond-data
           sr-data sr-spec frame-data fr-spec fr-nodes fr-wires sel-data fr st-kw st-label-text
][
    src: load path

    ; Buscar el set-word qvi-diagram: en el bloque cargado
    pos: find src to-set-word 'qvi-diagram
    if none? pos [
        cause-error 'user 'message ["load-vi: qvi-diagram no encontrado en " mold path]
    ]
    ; Normalizar set-words → words en todo el qvi-diagram
    qd: norm-spec pos/2

    bd-data: select qd 'block-diagram
    if none? bd-data [
        cause-error 'user 'message ["load-vi: block-diagram no encontrado"]
    ]

    d: make-diagram any [select qd 'name  form path]

    nodes-data:   select bd-data 'nodes
    wires-data:   select bd-data 'wires
    structs-data: select bd-data 'structures

    ; Recopilar names para sincronizar contadores (DT-024)
    names: copy []

    if nodes-data  [d/nodes: load-node-list nodes-data names]
    if wires-data  [d/wires: load-wire-list wires-data]

    ; ── Cargar structures (while-loop, for-loop, case-structure) ───────
    if all [structs-data  block? structs-data] [
        parse structs-data [
            any [
                set st-kw ['while-loop | 'for-loop | 'case-structure] set st-spec block! (
                    st: make-structure compose [
                        id:   (any [select st-spec 'id   0])
                        type: (st-kw)
                        name: (any [select st-spec 'name ""])
                        x:    (any [select st-spec 'x    0])
                        y:    (any [select st-spec 'y    0])
                        w:    (any [select st-spec 'w    300])
                        h:    (any [select st-spec 'h    200])
                        active-frame: (any [select st-spec 'active-frame  0])
                    ]
                    ; Label
                    st-label-text: case [
                        st-kw = 'for-loop ["For Loop"]
                        st-kw = 'case-structure ["Case Structure"]
                        true ["While Loop"]
                    ]
                    st/label: either select st-spec 'label [
                        make-label select st-spec 'label
                    ][
                        make-label compose [text: (st-label-text) visible: true]
                    ]
                    ; Shift registers (solo para loops)
                    if find [while-loop for-loop] st-kw [
                        sr-data: any [select st-spec 'shift-registers  []]
                        parse sr-data [
                            any [
                                'sr set sr-spec block! (
                                    append st/shift-regs make-shift-register compose [
                                        id:         (any [select sr-spec 'id          0])
                                        name:       (any [select sr-spec 'name        ""])
                                        data-type:  (any [select sr-spec 'data-type   'number])
                                        init-value: (any [select sr-spec 'init-value  0.0])
                                        y-offset:   (any [select sr-spec 'y-offset    40])
                                    ]
                                    if select sr-spec 'name [append names select sr-spec 'name]
                                )
                                | skip
                            ]
                        ]
                    ]
                    ; Frames (solo para case-structure)
                    if st-kw = 'case-structure [
                        frame-data: any [select st-spec 'frames  []]
                        parse frame-data [
                            any [
                                'frame set fr-spec block! (
                                    fr: make-frame fr-spec
                                    ; Nodos del frame: coords relativas → absolutas
                                    fr-nodes: any [select fr-spec 'nodes  []]
                                    fr/nodes: load-node-list/absolute fr-nodes names st/x st/y
                                    ; Wires del frame
                                    fr-wires: any [select fr-spec 'wires  []]
                                    fr/wires: load-wire-list fr-wires
                                    append st/frames fr
                                )
                                | skip
                            ]
                        ]
                        ; Selector wire
                        sel-data: select st-spec 'selector
                        st/selector-wire: either all [sel-data  not empty? sel-data] [
                            make object! [
                                from: any [select sel-data 'from  0]
                                port: any [select sel-data 'port  'result]
                            ]
                        ][
                            none
                        ]
                    ]
                    ; Nodos internos (para loops): coords relativas → absolutas
                    if find [while-loop for-loop] st-kw [
                        st-nodes: any [select st-spec 'nodes  []]
                        st/nodes: load-node-list/absolute st-nodes names st/x st/y
                        st-wires: any [select st-spec 'wires  []]
                        st/wires: load-wire-list st-wires
                    ]
                    ; Wire de condición solo para while-loop
                    if st-kw = 'while-loop [
                        cond-data: select st-spec 'condition
                        st/cond-wire: either all [cond-data  not empty? cond-data] [
                            make object! [
                                from: any [select cond-data 'from  0]
                                port: any [select cond-data 'port  'result]
                            ]
                        ][
                            none
                        ]
                    ]
                    if st/name [append names st/name]
                    append d/structures st
                )
                | skip
            ]
        ]
    ]

    ; ── Cargar connector (Fase 3: Sub-VI) ────────────────────────────────
    conn-data: select qd 'connector
    if all [conn-data  block? conn-data  not empty? conn-data] [
        d/connector: copy []
        parse conn-data [
            any [
                'input set conn-spec block! (
                    append d/connector reduce [
                        'input
                        any [select conn-spec 'pin 0]
                        any [select conn-spec 'label ""]
                        any [select conn-spec 'id 0]
                    ]
                )
                | 'output set conn-spec block! (
                    append d/connector reduce [
                        'output
                        any [select conn-spec 'pin 0]
                        any [select conn-spec 'label ""]
                        any [select conn-spec 'id 0]
                    ]
                )
                | skip
            ]
        ]
    ]

    ; Sincronizar contadores de names
    unless empty? names [sync-name-counters names]

    ; Cargar front-panel
    d/front-panel: either value? 'load-panel-from-diagram [
        load-panel-from-diagram qd
    ][
        copy []
    ]

    d
]

; ══════════════════════════════════════════════════════════
; LOAD-PANEL-FROM-DIAGRAM — Phase 4
; ══════════════════════════════════════════════════════════
;
; Carga front-panel items desde qvi-diagram (formato: qd).
; Retorna bloque de objetos make-fp-item.

load-panel-from-diagram: func [qd [block!] /local fp-raw items item kw id type name lbl default config offset item-spec] [
    fp-raw: select qd to-set-word 'front-panel
    items: copy []

    unless block? fp-raw [return items]

    parse fp-raw [
        any [
            set kw word! set item-spec block! (
                ; Construir spec completo para make-fp-item
                spec: copy []
                append spec to-set-word 'id
                append spec any [select item-spec 'id  0]
                append spec to-set-word 'type
                append spec any [select item-spec 'type 'control]
                append spec to-set-word 'name
                append spec any [select item-spec 'name ""]

                ; Normalizar label
                lbl-block: any [select item-spec 'label [text: ""]]
                unless block? lbl-block [lbl-block: compose [text: (lbl-block)]]
                if none? select lbl-block 'text   [append lbl-block compose [text: ""]]
                if none? select lbl-block 'visible [append lbl-block compose [visible: true]]
                if none? select lbl-block 'offset  [append lbl-block compose [offset: 0x0]]
                append spec to-set-word 'label
                append/only spec lbl-block

                append spec to-set-word 'default
                append/only spec any [select item-spec 'default copy []]

                append spec to-set-word 'config
                append/only spec any [select item-spec 'config copy []]

                append spec to-set-word 'offset
                append spec any [select item-spec 'offset 0x0]

                item: make-fp-item spec
                append items item
            )
            | skip
        ]
    ]

    items
]
