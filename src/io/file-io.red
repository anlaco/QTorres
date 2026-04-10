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
        ; Incluir file para nodos subvi (Fase 3)
        if all [in n 'file  n/file] [
            append node-spec-blk 'file
            append/only node-spec-blk n/file
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

    ; ── Structures (while-loop, for-loop, case-structure) ───────────────
    structs-block: copy []
    if all [object? diagram  in diagram 'structures  block? diagram/structures] [
        foreach st diagram/structures [
            lbl-text: either all [st/label  object? st/label] [st/label/text] [
                case [
                    st/type = 'for-loop ["For Loop"]
                    st/type = 'case-structure ["Case Structure"]
                    true ["While Loop"]
                ]
            ]
            lbl-block: compose [text: (lbl-text)  visible: (true)]
            ; Shift registers
            sr-block: copy []
            if in st 'shift-regs [
                foreach sr st/shift-regs [
                    append sr-block 'sr
                    append/only sr-block compose [
                        id: (sr/id)  name: (sr/name)  data-type: (sr/data-type)
                        init-value: (sr/init-value)  y-offset: (sr/y-offset)
                    ]
                ]
            ]
            ; Nodos internos: coords RELATIVAS a la estructura
            st-nodes-block: serialize-nodes/relative st/nodes st/x st/y
            st-wires-block: serialize-wires st/wires
            ; Keyword de estructura según tipo
            append structs-block st/type
            ; Bloque de datos según tipo
            case [
                st/type = 'for-loop [
                    append/only structs-block compose/only [
                        id: (st/id)  name: (st/name)  label: (lbl-block)
                        x: (st/x)  y: (st/y)  w: (st/w)  h: (st/h)
                        shift-registers: (sr-block)
                        nodes: (st-nodes-block)
                        wires: (st-wires-block)
                    ]
                ]
                st/type = 'while-loop [
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
                st/type = 'case-structure [
                    ; Frames
                    frames-block: copy []
                    foreach fr st/frames [
                        fr-nodes-block: serialize-nodes/relative fr/nodes st/x st/y
                        fr-wires-block: serialize-wires fr/wires
                        append frames-block 'frame
                        append/only frames-block compose/only [
                            id: (fr/id)  label: (fr/label)
                            nodes: (fr-nodes-block)
                            wires: (fr-wires-block)
                        ]
                    ]
                    ; Selector wire
                    sel-spec: either st/selector-wire [
                        compose [from: (st/selector-wire/from)  port: (st/selector-wire/port)]
                    ][
                        none
                    ]
                    append/only structs-block compose/only [
                        id: (st/id)  name: (st/name)  label: (lbl-block)
                        x: (st/x)  y: (st/y)  w: (st/w)  h: (st/h)
                        frames: (frames-block)
                        active-frame: (st/active-frame)
                        selector: (either sel-spec [sel-spec] [[]])
                    ]
                ]
            ]
        ]
    ]

    ; ── Connector (solo si el VI se usa como sub-VI, Fase 3) ──────────────
    connector-block: copy []
    if all [in diagram 'connector  block? diagram/connector  not empty? diagram/connector] [
        foreach conn-item diagram/connector [
            ; conn-item: [type pin label id] donde type es 'input o 'output
            append connector-block conn-item/1
            append/only connector-block compose/only [
                pin: (conn-item/2)  label: (conn-item/3)  id: (conn-item/4)
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
        connector: (connector-block)
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
    /subvi      ; si true, genera context [exec: func [...]] en lugar de either
    /local meta-raw bd-raw nodes-raw wires-raw structs-raw fp-raw
           nodes-str wires-str structs-str layout-str fp-str
           node-block wire-block struct-block sr-block fp-kw fp-spec i item kind-pos
           st-nodes-raw st-wires-raw st-srs-raw st-nodes-str st-wires-str st-srs-str
           fr-block fr-nodes-raw fr-wires-raw fr-nodes-str fr-wires-str frames-raw frames-str
           has-connector
][
    ; Detectar si el diagrama tiene connector (para modo sub-VI)
    has-connector: any [subvi  false]
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
                set struct-kw ['while-loop | 'for-loop | 'case-structure] set struct-block block! (
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
                    ; ── Case Structure: frames ─────────────────────────────
                    frames-str: copy ""
                    if struct-kw = 'case-structure [
                        frames-raw: any [select struct-block 'frames  []]
                        parse frames-raw [
                            any [
                                'frame set fr-block block! (
                                    fr-nodes-raw: any [select fr-block 'nodes  []]
                                    fr-wires-raw: any [select fr-block 'wires  []]
                                    fr-nodes-str: copy ""
                                    parse fr-nodes-raw [
                                        any [
                                            'node set node-block block! (
                                                append fr-nodes-str rejoin ["                            node " mold node-block "^/"]
                                            ) | skip
                                        ]
                                    ]
                                    fr-wires-str: copy ""
                                    parse fr-wires-raw [
                                        any [
                                            'wire set wire-block block! (
                                                append fr-wires-str rejoin ["                            wire " mold wire-block "^/"]
                                            ) | skip
                                        ]
                                    ]
                                    append frames-str rejoin [
                                        "                    frame [^/"
                                        "                        id: " mold any [select fr-block 'id  0]
                                        "  label: " mold any [select fr-block 'label "0"] "^/"
                                        "                        nodes: [^/" fr-nodes-str "                        ]^/"
                                        "                        wires: [^/" fr-wires-str "                        ]^/"
                                        "                    ]^/"
                                    ]
                                ) | skip
                            ]
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
                        ; frames y selector solo en case-structure
                        either struct-kw = 'case-structure [
                            rejoin [
                                either empty? frames-str [""] [rejoin [
                                    "            frames: [^/" frames-str "            ]^/"
                                ]]
                                "            active-frame: " mold any [select struct-block 'active-frame  0] "^/"
                                "            selector: " mold any [select struct-block 'selector  []] "^/"
                            ]
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

    ; ── Generar includes para sub-VIs (Fase 3) ─────────────────────────────
    includes-str: copy ""
    svf-list: select compiled 'subvi-files
    if all [block? svf-list  not empty? svf-list] [
        ; Guardar valor actual de qtorres-runtime
        append includes-str "_saved-qtorres-runtime: value? 'qtorres-runtime^/"
        append includes-str "qtorres-runtime: true^/"
        foreach svf svf-list [
            append includes-str rejoin ["#include " mold svf "^/"]
        ]
        ; Restore se hace al final del código generado
    ]

    ; ── Generar código según modo: VI normal o Sub-VI (Fase 3) ─────────────
    either has-connector [
        ; Modo Sub-VI: generar context [exec: func [...] [...]]
        ; El standalone guard se incluye automáticamente
        ; TODO: extraer parámetros del connector para el func
        func-name: to-word diagram-name
        generated-code: rejoin [
            either empty? includes-str [""] [rejoin [
                includes-str
                "; --- Restaurar qtorres-runtime si estaba definido ---^/"
                "if not _saved-qtorres-runtime [unset 'qtorres-runtime]^/^/"
            ]]
            "; --- Helpers de runtime ---^/"
            "arr-subset-helper: func [arr st ln] [copy/part skip arr to-integer st to-integer ln]^/^/"
            "; --- CÓDIGO GENERADO — no editar, se regenera al guardar ---^/"
            func-name ": context [^/"
            "    exec: func [] [^/"  ; TODO: extraer parámetros del connector
            "        " mold/only compiled/headless "^/"
            "    ]^/"
            "]^/^/"
            "; --- Standalone guard ---^/"
            "if not value? 'qtorres-runtime [^/"
            "    view layout [^/"
            layout-str
            "    ]^/"
            "]^/"
        ]
    ][
        ; Modo VI normal: either UI/headless
        generated-code: rejoin [
            either empty? includes-str [""] [rejoin [
                includes-str
                "; --- Restaurar qtorres-runtime si estaba definido ---^/"
                "if not _saved-qtorres-runtime [unset 'qtorres-runtime]^/^/"
            ]]
            "; --- Helpers de runtime ---^/"
            "arr-subset-helper: func [arr st ln] [copy/part skip arr to-integer st to-integer ln]^/^/"
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
        generated-code
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
    ; Detectar si es un Sub-VI (tiene connector definido)
    either all [in diagram 'connector  block? diagram/connector  not empty? diagram/connector] [
        content: format-qvi/subvi diagram/name qd compiled
    ][
        content: format-qvi diagram/name qd compiled
    ]
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
;
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

; ══════════════════════════════════════════════════════════
; SAVE-PANEL-TO-DIAGRAM (movido desde panel.red — 4A refactor)
; ══════════════════════════════════════════════════════════

save-panel-to-diagram: func [front-panel-items /local items item kw spec] [
    items: copy []
    foreach item front-panel-items [
        kw: case [
            item/type = 'control           ['control]
            item/type = 'bool-control      ['bool-control]
            item/type = 'bool-indicator    ['bool-indicator]
            item/type = 'str-control       ['str-control]
            item/type = 'str-indicator     ['str-indicator]
            item/type = 'arr-control       ['arr-control]
            item/type = 'arr-indicator     ['arr-indicator]
            item/type = 'cluster-control   ['cluster-control]
            item/type = 'cluster-indicator ['cluster-indicator]
            item/type = 'waveform-chart    ['waveform-chart]
            item/type = 'waveform-graph    ['waveform-graph]
            true                           ['indicator]
        ]
        spec: copy []
        repend spec [to-set-word 'id  item/id  to-set-word 'type  item/type  to-set-word 'name  item/name]
        append spec to-set-word 'label
        append/only spec compose/deep [text: (item/label/text) visible: (item/label/visible) offset: (item/label/offset)]
        append spec to-set-word 'default
        either block? item/value [append/only spec copy item/value] [append spec item/value]
        if item/data-type = 'cluster [
            append spec to-set-word 'config
            append/only spec copy any [item/config  copy []]
        ]
        repend spec [to-set-word 'offset  item/offset]
        append items kw
        append/only items spec
    ]
    reduce [to-set-word 'front-panel  items]
]

; ══════════════════════════════════════════════════════════
; QLIB — Librería de VIs con namespacing
; ══════════════════════════════════════════════════════════
;
; Una .qlib es un directorio con un manifiesto qlib.red + .qvi miembros.
;
; Formato de qlib.red:
;   qlib [
;       name:        "math"
;       version:     1
;       description: "Operaciones matemáticas"
;       members:     [%add.qvi %subtract.qvi]
;   ]

; Carga un directorio .qlib y devuelve un objeto con:
;   name, version, description, dir, members (bloque de file! absolutos)
; Devuelve none si el directorio no es un .qlib válido.
load-qlib: func [
    "Carga el manifiesto de un directorio .qlib"
    qlib-dir [file!]
    /local manifest raw qd name version desc members-raw members m abs-path
][
    if not dir? qlib-dir [return none]
    manifest: to-file rejoin [form qlib-dir "qlib.red"]
    if not exists? manifest [return none]
    raw: attempt [load manifest]
    if not block? raw [return none]
    if any [empty? raw  raw/1 <> 'qlib] [return none]
    qd: raw/2
    if not block? qd [return none]

    name:        any [select qd 'name        ""]
    version:     any [select qd 'version     1]
    desc:        any [select qd 'description ""]
    members-raw: any [select qd 'members     copy []]

    ; Resolver rutas de miembros relativas al directorio de la librería
    members: copy []
    foreach m members-raw [
        if file? m [
            abs-path: to-file rejoin [form qlib-dir form m]
            if exists? abs-path [append members abs-path]
        ]
    ]

    make object! compose/only [
        name:        (name)
        version:     (version)
        description: (desc)
        dir:         (qlib-dir)
        members:     (members)
    ]
]

; Busca directorios .qlib en los directorios dados.
; Uso: find-qlibs/from %./mi-proyecto/
; Devuelve bloque de objetos qlib (puede estar vacío).
find-qlibs: func [
    "Busca librerías .qlib en el directorio dado"
    /from project-dir [file!]
    /local search-dirs libs d d-str qlib-dir obj
][
    search-dirs: copy []
    if from [append search-dirs clean-path project-dir]

    libs: copy []
    foreach p search-dirs [
        if all [p  exists? p  dir? p] [
            foreach d read p [
                d-str: form d
                if all [dir? d  find d-str ".qlib"] [
                    qlib-dir: to-file rejoin [form p form d]
                    obj: load-qlib qlib-dir
                    if obj [append libs obj]
                ]
            ]
        ]
    ]
    libs
]

#include %../ui/diagram/canvas.red
