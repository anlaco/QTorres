Red [
    Title:   "QTorres — File I/O"
    Purpose: "Guardar y cargar VIs (.qvi), proyectos (.qproj) y otros tipos de fichero QTorres"
]

; ══════════════════════════════════════════════════
; SERIALIZE-DIAGRAM
; ══════════════════════════════════════════════════
;
; Convierte el objeto diagrama en memoria al formato de bloque qvi-diagram.
; Formato nuevo (DT-022/024):
;   node [id: 1  type: 'control  name: "ctrl_1"  label: [text: "A" visible: true]  x: 100  y: 100]
;   wire [from: 1  from-port: 'result  to: 2  to-port: 'a]

; Serializa una lista de nodos a bloque [node [...] node [...] ...]
; Si rel-x/rel-y están dados, las coords se hacen relativas a ese offset.
serialize-nodes: func [
    nodes [block!] /relative rel-x rel-y
    /local nodes-block n lbl-block nx ny node-spec-blk
][
    nodes-block: copy []
    foreach n nodes [
        lbl-block: either all [n/label  object? n/label] [
            compose [text: (n/label/text)  visible: (n/label/visible)]
        ][
            compose [text: (either string? n/label [n/label] [""])  visible: (true)]
        ]
        nx: either relative [n/x - rel-x] [n/x]
        ny: either relative [n/y - rel-y] [n/y]
        ; Incluir config si no está vacío (permite round-trip de valores de constantes)
        node-spec-blk: compose/only [
            id: (n/id)  type: (n/type)
            name: (either select n 'name [n/name] [""])
            label: (lbl-block)
            x: (nx)  y: (ny)
        ]
        if all [in n 'config  not empty? n/config] [
            append node-spec-blk 'config
            append/only node-spec-blk copy n/config
        ]
        append nodes-block 'node
        append/only nodes-block node-spec-blk
    ]
    nodes-block
]

; Serializa una lista de wires a bloque [wire [...] wire [...] ...]
serialize-wires: func [wires [block!] /local wires-block w] [
    wires-block: copy []
    foreach w wires [
        append wires-block 'wire
        append/only wires-block compose [
            from: (w/from-node)  from-port: (w/from-port)
            to:   (w/to-node)    to-port:   (w/to-port)
        ]
    ]
    wires-block
]

serialize-diagram: func [
    diagram [object!]
    /local nodes-block wires-block structs-block st lbl-block st-nodes-block st-wires-block cond-spec
           sr-block sr
][
    nodes-block:  serialize-nodes  diagram/nodes
    wires-block:  serialize-wires  diagram/wires

    ; ── Structures (while-loop, for-loop) ──────────────────────────────
    structs-block: copy []
    if all [object? diagram  in diagram 'structures  block? diagram/structures] [
        foreach st diagram/structures [
            lbl-text: either all [st/label  object? st/label] [st/label/text] [
                either st/type = 'for-loop ["For Loop"] ["While Loop"]
            ]
            lbl-block: compose [text: (lbl-text)  visible: (true)]
            ; Shift registers
            sr-block: copy []
            foreach sr st/shift-regs [
                append sr-block 'sr
                append/only sr-block compose [
                    id: (sr/id)  name: (sr/name)  data-type: (sr/data-type)
                    init-value: (sr/init-value)  y-offset: (sr/y-offset)
                ]
            ]
            ; Nodos internos: coords RELATIVAS a la estructura
            st-nodes-block: serialize-nodes/relative st/nodes st/x st/y
            st-wires-block: serialize-wires st/wires
            ; Keyword de estructura según tipo
            append structs-block st/type
            ; Bloque de datos: condition solo para while-loop
            either st/type = 'for-loop [
                append/only structs-block compose/only [
                    id: (st/id)  name: (st/name)  label: (lbl-block)
                    x: (st/x)  y: (st/y)  w: (st/w)  h: (st/h)
                    shift-registers: (sr-block)
                    nodes: (st-nodes-block)
                    wires: (st-wires-block)
                ]
            ][
                cond-spec: either st/cond-wire [
                    compose [from: (st/cond-wire/from)  port: (st/cond-wire/port)]
                ][
                    none
                ]
                append/only structs-block compose/only [
                    id: (st/id)  name: (st/name)  label: (lbl-block)
                    x: (st/x)  y: (st/y)  w: (st/w)  h: (st/h)
                    shift-registers: (sr-block)
                    condition: (either cond-spec [cond-spec] [[]])
                    nodes: (st-nodes-block)
                    wires: (st-wires-block)
                ]
            ]
        ]
    ]

    compose/only [
        meta:         [description: "" version: 1 author: "" tags: []]
        icon:         []
        block-diagram: (compose/only [
            nodes: (nodes-block)
            wires: (wires-block)
            structures: (structs-block)
        ])
    ]
]

; ══════════════════════════════════════════════════
; FORMAT-QVI
; ══════════════════════════════════════════════════
;
; Construye el string .qvi con formato multi-línea e indentación.
; qd usa set-words como claves (de serialize-diagram), se navega con to-set-word.

format-qvi: func [
    diagram-name [string!]
    qd           [block!]   ; resultado de serialize-diagram (set-words como claves)
    compiled     [map!]     ; resultado de compile-diagram
    /local meta-raw bd-raw nodes-raw wires-raw structs-raw fp-raw
           nodes-str wires-str structs-str layout-str fp-str
           node-block wire-block struct-block sr-block fp-kw fp-spec i item kind-pos
           st-nodes-raw st-wires-raw st-srs-raw st-nodes-str st-wires-str st-srs-str
][
    ; Navegar qd con to-set-word (claves son set-words)
    meta-raw:    any [select qd to-set-word 'meta   [description: "" version: 1 author: "" tags: []]]
    bd-raw:      select qd to-set-word 'block-diagram
    nodes-raw:   either bd-raw [select bd-raw to-set-word 'nodes]      [copy []]
    wires-raw:   either bd-raw [select bd-raw to-set-word 'wires]      [copy []]
    structs-raw: either bd-raw [select bd-raw to-set-word 'structures] [copy []]

    ; ── Nodes ──────────────────────────────────────────────────────────────
    nodes-str: copy ""
    if nodes-raw [
        parse nodes-raw [
            any [
                'node set node-block block! (
                    append nodes-str rejoin ["            node " mold node-block "^/"]
                )
                | skip
            ]
        ]
    ]

    ; ── Wires ──────────────────────────────────────────────────────────────
    wires-str: copy ""
    if wires-raw [
        parse wires-raw [
            any [
                'wire set wire-block block! (
                    append wires-str rejoin ["            wire " mold wire-block "^/"]
                )
                | skip
            ]
        ]
    ]

    ; ── Structures ─────────────────────────────────────────────────────────
    structs-str: copy ""
    if all [structs-raw  not empty? structs-raw] [
        parse structs-raw [
            any [
                set struct-kw ['while-loop | 'for-loop] set struct-block block! (
                    st-nodes-raw: any [select struct-block 'nodes  []]
                    st-wires-raw: any [select struct-block 'wires  []]
                    st-srs-raw:   any [select struct-block 'shift-registers  []]
                    st-nodes-str: copy ""
                    parse st-nodes-raw [
                        any [
                            'node set node-block block! (
                                append st-nodes-str rejoin ["                    node " mold node-block "^/"]
                            ) | skip
                        ]
                    ]
                    st-wires-str: copy ""
                    parse st-wires-raw [
                        any [
                            'wire set wire-block block! (
                                append st-wires-str rejoin ["                    wire " mold wire-block "^/"]
                            ) | skip
                        ]
                    ]
                    st-srs-str: copy ""
                    parse st-srs-raw [
                        any [
                            'sr set sr-block block! (
                                append st-srs-str rejoin ["                    sr " mold sr-block "^/"]
                            ) | skip
                        ]
                    ]
                    append structs-str rejoin [
                        "        " form struct-kw " [^/"
                        "            id: " mold any [select struct-block 'id  0]
                        "  name: " mold any [select struct-block 'name  ""]
                        "  label: " mold any [select struct-block 'label  []] "^/"
                        "            x: " mold any [select struct-block 'x  0]
                        "  y: " mold any [select struct-block 'y  0]
                        "  w: " mold any [select struct-block 'w  300]
                        "  h: " mold any [select struct-block 'h  200] "^/"
                        either empty? st-srs-str [""] [rejoin [
                            "            shift-registers: [^/" st-srs-str "            ]^/"
                        ]]
                        ; condition solo en while-loop
                        either struct-kw = 'while-loop [
                            rejoin ["            condition: " mold any [select struct-block 'condition  []] "^/"]
                        ][""]
                        "            nodes: [^/" st-nodes-str "            ]^/"
                        "            wires: [^/" st-wires-str "            ]^/"
                        "        ]^/"
                    ]
                )
                | skip
            ]
        ]
    ]

    ; ── Front Panel (opcional — solo si qd incluye front-panel:) ──────────
    fp-raw: select qd to-set-word 'front-panel
    fp-str: copy ""
    if fp-raw [
        parse fp-raw [
            any [
                set fp-kw word! set fp-spec block! (
                    append fp-str rejoin ["        " form fp-kw " " mold fp-spec "^/"]
                )
                | skip
            ]
        ]
    ]

    ; ── Layout del Front Panel ─────────────────────────────────────────────
    ; Estructura: [text "lbl" f_N: field "val" ... button "Run" [...] text "lbl" t_N: text "---" ...]
    layout-str: copy ""
    i: 1
    while [i <= length? compiled/ui-layout] [
        item: compiled/ui-layout/:i
        case [
            item = 'button [
                append layout-str rejoin [
                    "        button " mold compiled/ui-layout/(i + 1) " "
                    mold compiled/ui-layout/(i + 2) "^/"
                ]
                i: i + 3
            ]
            item = 'text [
                kind-pos: i + 3
                append layout-str rejoin [
                    "        text " mold compiled/ui-layout/(i + 1) " "
                    mold compiled/ui-layout/(i + 2) " "
                    mold compiled/ui-layout/:kind-pos " "
                    mold compiled/ui-layout/(i + 4) "^/"
                ]
                i: i + 5
            ]
            true [
                append layout-str rejoin ["        " mold item "^/"]
                i: i + 1
            ]
        ]
    ]

    rejoin [
        "Red [Title: " mold diagram-name " Needs: 'View]^/^/"
        "qvi-diagram: [^/"
        "    meta: " mold meta-raw "^/"
        "    icon: []^/"
        "    block-diagram: [^/"
        "        nodes: [^/"
        nodes-str
        "        ]^/"
        "        wires: [^/"
        wires-str
        "        ]^/"
        either empty? structs-str [""] [rejoin [
            "        structures: [^/"
            structs-str
            "        ]^/"
        ]]
        "    ]^/"
        either empty? fp-str [""] [rejoin ["    front-panel: [^/" fp-str "    ]^/"]]
        "]^/^/"
        "; --- CÓDIGO GENERADO — no editar, se regenera al guardar ---^/"
        "either empty? system/options/args [^/"
        "    view layout [^/"
        layout-str
        "    ]^/"
        "][^/"
        "    " mold/only compiled/headless "^/"
        "]^/"
    ]
]

; ══════════════════════════════════════════════════
; SAVE-VI
; ══════════════════════════════════════════════════
;
; Escribe el fichero .qvi completo:
;   1. Cabecera Red con Needs: 'View
;   2. qvi-diagram: [...] — fuente de verdad (DT-011)
;   3. Código generado: modo dual UI/headless (DT-009, DT-012)
;
; Run NO llama a save-vi. Son operaciones independientes (DT-010).

save-vi: func [
    path    [file!]
    diagram [object!]
    /local compiled qd content fp-items
][
    compiled: compile-diagram diagram
    qd: serialize-diagram diagram
    ; Incluir front-panel si está disponible (requiere panel.red cargado)
    fp-items: select diagram 'front-panel
    if all [
        value? 'save-panel-to-diagram
        block? fp-items
        not empty? fp-items
    ][
        append qd save-panel-to-diagram fp-items
    ]
    content: format-qvi diagram/name qd compiled
    write path content
    path
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
                    n: make-node node-spec
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
           sr-data sr-spec
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

    ; ── Cargar structures (while-loop, for-loop) ──────────────────
    if all [structs-data  block? structs-data] [
        parse structs-data [
            any [
                set st-kw ['while-loop | 'for-loop] set st-spec block! (
                    st: make-structure compose [
                        id:   (any [select st-spec 'id   0])
                        type: (st-kw)
                        name: (any [select st-spec 'name ""])
                        x:    (any [select st-spec 'x    0])
                        y:    (any [select st-spec 'y    0])
                        w:    (any [select st-spec 'w    300])
                        h:    (any [select st-spec 'h    200])
                        label: (any [select st-spec 'label  compose [text: (either st-kw = 'for-loop ["For Loop"] ["While Loop"])]])
                    ]
                    ; Shift registers
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
                    ; Nodos internos: coords relativas → absolutas
                    st-nodes: any [select st-spec 'nodes  []]
                    st/nodes: load-node-list/absolute st-nodes names st/x st/y
                    ; Wires internos
                    st-wires: any [select st-spec 'wires  []]
                    st/wires: load-wire-list st-wires
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

#include %../ui/diagram/canvas.red
