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

serialize-diagram: func [
    diagram [object!]
    /local nodes-block wires-block n w lbl-block
][
    nodes-block: copy []
    foreach n diagram/nodes [
        ; Serializar label como bloque con set-words (DT-022)
        lbl-block: either all [n/label  object? n/label] [
            compose [text: (n/label/text)  visible: (n/label/visible)]
        ][
            ; Fallback para label legacy (string)
            compose [text: (either string? n/label [n/label] [""])  visible: true]
        ]
        append nodes-block 'node
        append/only nodes-block compose/only [
            id: (n/id)  type: (n/type)
            name: (either select n 'name [n/name] [""])
            label: (lbl-block)
            x: (n/x)  y: (n/y)
        ]
    ]

    wires-block: copy []
    foreach w diagram/wires [
        append wires-block 'wire
        append/only wires-block compose [
            from: (w/from-node)  from-port: (w/from-port)
            to:   (w/to-node)    to-port:   (w/to-port)
        ]
    ]

    compose/only [
        meta:         [description: "" version: 1 author: "" tags: []]
        icon:         []
        block-diagram: (compose/only [nodes: (nodes-block) wires: (wires-block)])
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
    /local meta-raw bd-raw nodes-raw wires-raw fp-raw
           nodes-str wires-str layout-str fp-str
           node-block wire-block fp-kw fp-spec i item kind-pos
][
    ; Navegar qd con to-set-word (claves son set-words)
    meta-raw:  any [select qd to-set-word 'meta   [description: "" version: 1 author: "" tags: []]]
    bd-raw:    select qd to-set-word 'block-diagram
    nodes-raw: either bd-raw [select bd-raw to-set-word 'nodes] [copy []]
    wires-raw: either bd-raw [select bd-raw to-set-word 'wires] [copy []]

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
    /local compiled qd content
][
    compiled: compile-diagram diagram
    qd: serialize-diagram diagram
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

load-vi: func [
    path [file!]
    /local src pos qd bd-data nodes-data wires-data d node-spec wire-spec names ns ws
][
    src: load path

    ; Buscar el set-word qvi-diagram: en el bloque cargado
    pos: find src to-set-word 'qvi-diagram
    if none? pos [
        cause-error 'user 'message ["load-vi: qvi-diagram no encontrado en " mold path]
    ]
    ; Normalizar set-words → words en todo el qvi-diagram (ficheros nuevos usan set-words)
    qd: norm-spec pos/2

    bd-data:    select qd 'block-diagram
    if none? bd-data [
        cause-error 'user 'message ["load-vi: block-diagram no encontrado"]
    ]

    d: make-diagram any [select qd 'name  form path]

    nodes-data: select bd-data 'nodes
    wires-data: select bd-data 'wires

    ; Recopilar names existentes para sincronizar contadores (DT-024)
    names: copy []

    if nodes-data [
        parse nodes-data [
            any [
                'node set node-spec block! (
                    ; make-node acepta tanto label: "A" como label: [text: "A"] (retrocompat)
                    append d/nodes make-node node-spec
                    ; Recopilar name si existe
                    if select node-spec 'name [
                        append names select node-spec 'name
                    ]
                )
                | skip
            ]
        ]
    ]

    if wires-data [
        parse wires-data [
            any [
                'wire set wire-spec block! (
                    append d/wires make-wire compose [
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

    ; Sincronizar contadores de names para evitar colisiones al crear nuevos nodos
    unless empty? names [sync-name-counters names]

    ; Cargar front-panel desde qvi-diagram (requiere panel.red cargado)
    d/front-panel: either value? 'load-panel-from-diagram [
        load-panel-from-diagram qd
    ][
        copy []
    ]

    d
]
