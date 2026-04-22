Red [
    Title:   "Telekino — File I/O (serialización + formato .qvi)"
    Purpose: "serialize-diagram + format-qvi: convierte modelo → texto .qvi"
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
            compose [text: (n/label/text)  visible: (n/label/visible)  offset: (n/label/offset)]
        ][
            compose [text: (either string? n/label [n/label] [""])  visible: (true)  offset: 0x0]
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
        ; Guardar valor actual de telekino-runtime
        append includes-str "_saved-telekino-runtime: value? 'telekino-runtime^/"
        append includes-str "telekino-runtime: true^/"
        foreach svf svf-list [
            append includes-str rejoin ["#include " mold svf "^/"]
        ]
        ; Restore se hace al final del código generado
    ]

    ; ── Generar código según modo: VI normal o Sub-VI (Fase 3) ─────────────
    either has-connector [
        ; Modo Sub-VI: generar context [exec: func [...] [...]]
        func-name: to-word diagram-name
        generated-code: rejoin [
            either empty? includes-str [""] [rejoin [
                includes-str
                "; --- Restaurar telekino-runtime si estaba definido ---^/"
                "if not _saved-telekino-runtime [unset 'telekino-runtime]^/^/"
            ]]
            "; --- Helpers de runtime ---^/"
            "arr-subset-helper: func [arr st ln] [copy/part skip arr to-integer st to-integer ln]^/"
            "_make-tcp-connection: func [a? h p] [make object! [active?: a?  host: h  port: p]]^/"
            "_tcp-open-helper: func [host port timeout-ms /local ok] [ok: tcp/connect host to-integer port  _make-tcp-connection ok host to-integer port]^/"
            "_tcp-write-helper: func [conn data /local bytes] [if not conn/active? [return reduce [conn 0]]  bytes: length? to-binary data  tcp/send data  reduce [conn bytes]]^/"
            "_tcp-read-helper: func [conn sz timeout-ms /local buf bytes] [if not conn/active? [return reduce [conn {} 0]]  tcp/set-timeout to-integer timeout-ms  buf: tcp/receive to-integer sz  either buf [bytes: length? buf  reduce [conn to string! buf bytes]] [reduce [conn {} 0]]]^/"
            "_tcp-close-helper: func [conn] [if not conn/active? [return conn]  tcp/close  _make-tcp-connection false conn/host conn/port]^/^/"
            "; --- CÓDIGO GENERADO — no editar, se regenera al guardar ---^/"
            func-name ": context [^/"
            "    exec: func [] [^/"  ; TODO: extraer parámetros del connector
            "        " mold/only compiled/headless "^/"
            "    ]^/"
            "]^/^/"
            "; --- Standalone guard ---^/"
            "if not value? 'telekino-runtime [^/"
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
                "; --- Restaurar telekino-runtime si estaba definido ---^/"
                "if not _saved-telekino-runtime [unset 'telekino-runtime]^/^/"
            ]]
            "; --- Helpers de runtime ---^/"
            "arr-subset-helper: func [arr st ln] [copy/part skip arr to-integer st to-integer ln]^/"
            "_make-tcp-connection: func [a? h p] [make object! [active?: a?  host: h  port: p]]^/"
            "_tcp-open-helper: func [host port timeout-ms /local ok] [ok: tcp/connect host to-integer port  _make-tcp-connection ok host to-integer port]^/"
            "_tcp-write-helper: func [conn data /local bytes] [if not conn/active? [return reduce [conn 0]]  bytes: length? to-binary data  tcp/send data  reduce [conn bytes]]^/"
            "_tcp-read-helper: func [conn sz timeout-ms /local buf bytes] [if not conn/active? [return reduce [conn {} 0]]  tcp/set-timeout to-integer timeout-ms  buf: tcp/receive to-integer sz  either buf [bytes: length? buf  reduce [conn to string! buf bytes]] [reduce [conn {} 0]]]^/"
            "_tcp-close-helper: func [conn] [if not conn/active? [return conn]  tcp/close  _make-tcp-connection false conn/host conn/port]^/^/"
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
