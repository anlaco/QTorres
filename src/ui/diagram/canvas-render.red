Red [
    Title:   "QTorres — canvas-render"
    Purpose: "Render puro del Block Diagram: constantes visuales, geometría y Draw."
    Needs:   'View
]

; ── canvas-render.red ─────────────────────────────────────────────
; Render puro del Block Diagram: constantes visuales, geometría de
; nodos y funciones Draw. Incluido desde canvas.red.
; No contiene estado mutable ni side-effects de UI.
; ──────────────────────────────────────────────────────────────────

block-width: 120   block-height: 50   port-radius: 8   grid-size: 20

col-canvas:     225.228.235
col-grid:       200.203.212
col-block-ctrl: 50.100.180
col-block-ind:  175.125.20
col-block-op:   55.75.105
col-wire:       195.95.20
col-wire-bool:  20.160.20
col-wire-str:   220.100.160
col-wire-cluster: 139.69.19
col-wire-sel:   0.160.200
col-port-in:    50.110.200
col-port-out:   195.80.25
col-sel:        0.175.210
col-text:       240.245.250
col-black:      0.0.0

; Colores de estructuras contenedoras (while-loop)
col-struct-border:     55.80.120    ; borde azulado oscuro
col-struct-bg:         205.210.220  ; fondo ligeramente más oscuro que canvas
col-struct-term-i:     50.100.180   ; terminal iteración (azul como control)
col-struct-term-cond:  20.160.20    ; terminal condición (verde como wire bool)
struct-terminal-size:  14           ; tamaño del cuadrado terminal i y handle resize
sr-terminal-half:      6            ; semitamaño del triángulo SR (triángulo 12px total)

; Case Structure — dimensiones
case-nav-height:       24           ; altura de la barra de navegación
case-btn-size:         18           ; tamaño de botones ◀ ▶ [+][-]
col-case-nav-bg:       160.185.215  ; fondo de barra de navegación

; Compensación vertical de texto (8px en Linux por diferencia de baseline)
text-dy: either system/platform = 'Linux [8] [0]

; ══════════════════════════════════════════════════════════
; GEOMETRÍA DE NODOS — funciones puras sin side-effects
; ══════════════════════════════════════════════════════════
; Devuelve el color de un tipo de nodo leyendo la categoría del block-registry.
block-color: func [node-type /local cat] [
    cat: block-category to-word node-type
    case [
        cat = 'input   [col-block-ctrl]
        cat = 'output  [col-block-ind]
        cat = 'cluster [col-wire-cluster]
        true           [col-block-op]
    ]
]

; Devuelve los puertos de entrada de un nodo.
; Para bundle: puertos dinámicos desde config/fields.
; Para el resto: consulta el block-registry.
in-ports: func [node] [
    either node/type = 'bundle [
        cluster-in-ports node
    ][
        any [block-in-ports to-word node/type  []]
    ]
]

; Devuelve los puertos de salida de un nodo.
; Para unbundle: puertos dinámicos desde config/fields.
; Para el resto: consulta el block-registry.
out-ports: func [node] [
    either node/type = 'unbundle [
        cluster-out-ports node
    ][
        any [block-out-ports to-word node/type  []]
    ]
]

; Devuelve el tipo de dato de un puerto de salida ('number por defecto).
; Para unbundle: los puertos de salida son campos dinámicos del cluster.
port-out-type: func [node port-name /local bdef p] [
    if node/type = 'unbundle [return cluster-field-type node to-word port-name]
    bdef: find-block to-word node/type
    if none? bdef [return 'number]
    foreach p bdef/outputs [
        if p/name = to-word port-name [return p/type]
    ]
    'number
]

; Devuelve el tipo de dato de un puerto de entrada ('number por defecto).
; Para bundle: los puertos de entrada son campos dinámicos del cluster.
port-in-type: func [node port-name /local bdef p] [
    if node/type = 'bundle [return cluster-field-type node to-word port-name]
    bdef: find-block to-word node/type
    if none? bdef [return 'number]
    foreach p bdef/inputs [
        if p/name = to-word port-name [return p/type]
    ]
    'number
]

; Devuelve el color de wire para un tipo de dato.
wire-data-color: func [data-type] [
    case [
        data-type = 'boolean [col-wire-bool]
        data-type = 'string  [col-wire-str]
        data-type = 'cluster [col-wire-cluster]
        data-type = 'array   [col-wire]   ; mismo naranja que number, diferenciado por línea doble
        true                 [col-wire]
    ]
]

; Devuelve la posición del terminal SR (▲ borde izquierdo o ▼ borde derecho).
sr-xy: func [st sr side] [
    either side = 'left [
        as-pair st/x (to-integer st/y + sr/y-offset)
    ][
        as-pair (to-integer st/x + st/w) (to-integer st/y + sr/y-offset)
    ]
]

; Devuelve el color del terminal SR según su data-type.
sr-type-color: func [data-type] [
    case [
        data-type = 'boolean [col-wire-bool]
        data-type = 'string  [col-wire-str]
        data-type = 'array   [col-wire]
        true                 [col-wire]
    ]
]

; Busca un SR por nombre en un bloque de shift-regs.
; Usa while/pick para evitar problemas de posición de serie con foreach.
find-sr: func [shift-regs [block!] port-name [word!] /local k sr] [
    k: 1
    while [k <= length? shift-regs] [
        sr: pick shift-regs k
        if (to-word sr/name) = port-name [return sr]
        k: k + 1
    ]
    none
]

; Genera comandos Draw para una línea daseada horizontal o vertical.
; Simula el patrón característico del wire string (visual-spec §4.2).
draw-dashed-segment: func [p1 [pair!] p2 [pair!] /local cmds dash gap pos end-v horiz] [
    cmds: copy []
    dash: 5  gap: 3
    horiz: p1/y = p2/y
    either horiz [
        pos: p1/x  end-v: p2/x
        if pos > end-v [pos: p2/x  end-v: p1/x]
        while [pos < end-v] [
            append cmds compose [
                line (as-pair pos p1/y) (as-pair (min pos + dash end-v) p1/y)
            ]
            pos: pos + dash + gap
        ]
    ][
        pos: p1/y  end-v: p2/y
        if pos > end-v [pos: p2/y  end-v: p1/y]
        while [pos < end-v] [
            append cmds compose [
                line (as-pair p1/x pos) (as-pair p1/x (min pos + dash end-v))
            ]
            pos: pos + dash + gap
        ]
    ]
    cmds
]

port-xy: func [node port-name direction /local ports port-index found] [
    either direction = 'in [
        ports: in-ports node
        found: find ports port-name
        port-index: either found [index? found] [1]
        as-pair (node/x - port-radius) (node/y + 12 + ((port-index - 1) * 20))
    ][
        ports: out-ports node
        found: find ports port-name
        port-index: either found [index? found] [1]
        as-pair (node/x + block-width + port-radius) (node/y + 12 + ((port-index - 1) * 20))
    ]
]

; Devuelve la altura visual de un nodo.
; bundle/unbundle/cluster-control/cluster-indicator: variable según número de campos.
; Resto: block-height fijo.
node-height: func [node /local n-in n-out] [
    case [
        find [bundle unbundle cluster-control cluster-indicator] node/type [
            n-in:  length? in-ports node
            n-out: length? out-ports node
            max block-height (12 + (max n-in n-out) * 20 + 10)
        ]
        true [block-height]
    ]
]

; ══════════════════════════════════════════════════════════
; MODELO — todo el estado mutable vive aquí
; ══════════════════════════════════════════════════════════
; make-diagram-model movida a model.red (4A refactor)

gen-node-id: func [model /local next-id] [
    next-id: model/next-id
    model/next-id: model/next-id + 1
    next-id
]

; ══════════════════════════════════════════════════════════
; RENDER — funciones puras que reciben modelo y devuelven
;          bloques de primitivas Draw
; ══════════════════════════════════════════════════════════
render-grid: func [canvas-width canvas-height /local cmds x y] [
    cmds: compose [pen (col-grid)  fill-pen (col-grid)  line-width 1]
    x: grid-size
    while [x < canvas-width] [
        y: grid-size
        while [y < canvas-height] [
            append cmds compose [circle (as-pair x y) 1]
            y: y + grid-size
        ]
        x: x + grid-size
    ]
    cmds
]

; ── Helpers de render: reutilizables por render-bd y render-structure ────────

render-wire-list: func [
    "Genera Draw cmds para una lista de wires dado su lista de nodos fuente"
    wires nodes selected-wire
    /local cmds wire src-node dst-node out-xy in-xy mid-x wire-dtype wire-color node
][
    cmds: copy []
    foreach wire wires [
        src-node: find-node-by-id nodes wire/from-node
        dst-node: find-node-by-id nodes wire/to-node
        if all [src-node dst-node] [
            out-xy: port-xy src-node wire/from-port 'out
            in-xy:  port-xy dst-node wire/to-port   'in
            mid-x:  to-integer (out-xy/x + in-xy/x) / 2
            wire-dtype: port-out-type src-node wire/from-port
            wire-color: either same? wire selected-wire [col-wire-sel] [wire-data-color wire-dtype]
            case [
                all [wire-dtype = 'string  not same? wire selected-wire] [
                    append cmds compose [pen (wire-color)  line-width 2]
                    append cmds draw-dashed-segment out-xy              as-pair mid-x out-xy/y
                    append cmds draw-dashed-segment as-pair mid-x out-xy/y  as-pair mid-x in-xy/y
                    append cmds draw-dashed-segment as-pair mid-x in-xy/y  in-xy
                ]
                all [wire-dtype = 'array  not same? wire selected-wire] [
                    ; Línea doble: trazo grueso exterior + trazo fino interior del color del canvas
                    append cmds compose [
                        pen (wire-color)  line-width 4
                        line (out-xy) (as-pair mid-x out-xy/y) (as-pair mid-x in-xy/y) (in-xy)
                        pen col-canvas  line-width 1
                        line (out-xy) (as-pair mid-x out-xy/y) (as-pair mid-x in-xy/y) (in-xy)
                    ]
                ]
                true [
                    append cmds compose [
                        pen (wire-color)  line-width 2
                        line (out-xy) (as-pair mid-x out-xy/y) (as-pair mid-x in-xy/y) (in-xy)
                    ]
                ]
            ]
        ]
    ]
    cmds
]

render-node-list: func [
    "Genera Draw cmds para una lista de nodos"
    nodes selected-node
    /local cmds node node-color type-label ports in-port-y out-port-y port
][
    cmds: copy []
    foreach node nodes [
        ; bundle/unbundle tienen render propio (altura variable, puertos dinámicos)
        if find [bundle unbundle] node/type [
            append cmds render-cluster-node node selected-node
            continue
        ]
        node-color: block-color node/type
        append cmds compose [
            pen (node-color - 20.20.20)  line-width 1  fill-pen (node-color)
            box (as-pair node/x node/y) (as-pair (node/x + block-width) (node/y + block-height)) 5
        ]
        append cmds compose [
            pen off  fill-pen (node-color + 30.30.30)
            box (as-pair node/x node/y) (as-pair (node/x + 4) (node/y + block-height)) 0
        ]
        type-label: switch/default node/type [
            control        ["DBL"]
            indicator      ["DBL"]
            add            ["ADD +"]
            sub            ["SUB -"]
            mul            ["MUL *"]
            div            ["DIV /"]
            display        ["DISP"]
            subvi          ["SUBVI"]
            const          [form any [select node/config 'default  0.0]]
            bool-const     [either any [select node/config 'default  false] ["T"] ["F"]]
            bool-control   ["TF"]
            bool-indicator ["TF"]
            and-op         ["AND"]
            or-op          ["OR"]
            not-op         ["NOT"]
            gt-op          [">"]
            lt-op          ["<"]
            eq-op          ["="]
            str-const      [any [select node/config 'default  ""]]
            str-control    [to-string any [select node/config 'default  "STR"]]
            str-indicator  ["STR"]
            concat         ["CONCAT"]
            str-length     ["LEN"]
            to-string      ["→STR"]
            arr-const      [rejoin ["[" form any [select node/config 'default  copy []] "]"]]
            arr-control       ["ARR"]
            arr-indicator     ["ARR"]
            cluster-control   ["CLU"]
            cluster-indicator ["CLU"]
            build-array    ["BUILD[]"]
            index-array    ["IDX[]"]
            array-size     ["SIZE[]"]
            array-subset   ["SUB[]"]
        ] [uppercase form node/type]
        either all [node/label  object? node/label  node/label/visible] [
            append cmds compose [
                fill-pen col-text
                text (as-pair (node/x + 10) (node/y + 10 + text-dy)) (any [node/label/text ""])
                text (as-pair (node/x + 10) (node/y + 26 + text-dy)) (type-label)
            ]
        ][
            either all [node/label  string? node/label] [
                append cmds compose [
                    fill-pen col-text
                    text (as-pair (node/x + 10) (node/y + 10 + text-dy)) (node/label)
                    text (as-pair (node/x + 10) (node/y + 26 + text-dy)) (type-label)
                ]
            ][
                append cmds compose [
                    fill-pen col-text
                    text (as-pair (node/x + 10) (node/y + 14 + text-dy)) (type-label)
                ]
            ]
        ]
        ports: in-ports node
        in-port-y: node/y + 12
        foreach port ports [
            append cmds compose [
                pen col-port-in  fill-pen col-port-in
                circle (as-pair (node/x - port-radius) in-port-y) (port-radius)
                fill-pen col-text
                text (as-pair (node/x - port-radius - 22) (in-port-y - 7 + text-dy)) (form port)
            ]
            in-port-y: in-port-y + 20
        ]
        ports: out-ports node
        out-port-y: node/y + 12
        foreach port ports [
            append cmds compose [
                pen col-port-out  fill-pen col-port-out
                circle (as-pair (node/x + block-width + port-radius) out-port-y) (port-radius)
                fill-pen col-text
                text (as-pair (node/x + block-width + port-radius + 12) (out-port-y - 7 + text-dy)) (form port)
            ]
            out-port-y: out-port-y + 20
        ]
        if same? node selected-node [
            append cmds compose [
                pen col-sel  line-width 2  fill-pen off
                box (as-pair (node/x - 3) (node/y - 3)) (as-pair (node/x + block-width + 3) (node/y + block-height + 3)) 6
                line-width 1
            ]
        ]
    ]
    cmds
]

; ══════════════════════════════════════════════════════════
; RENDER-CLUSTER-NODE — Bundle / Unbundle con puertos dinámicos
; ══════════════════════════════════════════════════════════

render-cluster-node: func [
    "Genera Draw cmds para un nodo bundle/unbundle con altura variable y puertos coloreados"
    node selected-node
    /local cmds node-color h type-label ports in-port-y out-port-y port port-col
][
    cmds: copy []
    node-color: col-wire-cluster
    h: node-height node

    ; Cuerpo del nodo (altura variable)
    append cmds compose [
        pen (node-color - 20.20.20)  line-width 1  fill-pen (node-color)
        box (as-pair node/x node/y) (as-pair (node/x + block-width) (node/y + h)) 5
        pen off  fill-pen (node-color + 30.30.30)
        box (as-pair node/x node/y) (as-pair (node/x + 4) (node/y + h)) 0
    ]

    ; Etiqueta de tipo centrada verticalmente
    type-label: case [
        node/type = 'bundle            ["BUNDLE"]
        node/type = 'unbundle          ["UNBUNDLE"]
        node/type = 'cluster-control   ["CLU-CTRL"]
        true                           ["CLU-IND"]
    ]
    append cmds compose [
        fill-pen col-text
        text (as-pair (node/x + 8) (node/y + 14 + text-dy)) (type-label)
    ]

    ; Puertos de entrada (coloreados por tipo de campo)
    ports: in-ports node
    in-port-y: node/y + 12
    foreach port ports [
        port-col: wire-data-color port-in-type node port
        append cmds compose [
            pen (port-col)  fill-pen (port-col)
            circle (as-pair (node/x - port-radius) in-port-y) (port-radius)
            fill-pen col-text
            text (as-pair (node/x - port-radius - 22) (in-port-y - 7)) (form port)
        ]
        in-port-y: in-port-y + 20
    ]

    ; Puertos de salida (coloreados por tipo de campo o cluster)
    ports: out-ports node
    out-port-y: node/y + 12
    foreach port ports [
        port-col: wire-data-color port-out-type node port
        append cmds compose [
            pen (port-col)  fill-pen (port-col)
            circle (as-pair (node/x + block-width + port-radius) out-port-y) (port-radius)
            fill-pen col-text
            text (as-pair (node/x + block-width + port-radius + 12) (out-port-y - 7)) (form port)
        ]
        out-port-y: out-port-y + 20
    ]

    ; Borde de selección
    if same? node selected-node [
        append cmds compose [
            pen col-sel  line-width 2  fill-pen off
            box (as-pair (node/x - 3) (node/y - 3)) (as-pair (node/x + block-width + 3) (node/y + h + 3)) 6
            line-width 1
        ]
    ]
    cmds
]

; ══════════════════════════════════════════════════════════
; RENDER-CASE-STRUCTURE — Case Structure con múltiples frames
; ══════════════════════════════════════════════════════════

render-case-structure: func [
    "Genera Draw cmds para una Case Structure con barra de navegación"
    st model
    /local cmds bx by bx2 by2 nav-h act-frame frame-label sel-x
][
    cmds: copy []
    bx: st/x  by: st/y  bx2: st/x + st/w  by2: st/y + st/h
    nav-h: case-nav-height

    ; 1) Fondo + borde del contenedor
    append cmds compose [
        pen (col-struct-border)  line-width 2  fill-pen (col-struct-bg)
        box (as-pair bx by) (as-pair bx2 by2) 8
        line-width 1
    ]

    ; 2) Barra de navegación (fondo más oscuro)
    append cmds compose [
        pen (col-struct-border)  fill-pen (col-case-nav-bg)
        box (as-pair (bx + 2) (by + 2)) (as-pair (bx2 - 2) (by + nav-h)) 4
    ]

    ; 3) Label "Case Structure"
    if all [st/label  object? st/label] [
        append cmds compose [
            pen off  fill-pen col-black
            text (as-pair (bx + 8) (by + 5 + text-dy)) (st/label/text)
        ]
    ]

    ; 4) Botones de navegación ◀ ▶ [+][-]
    ; ◀ (izquierda) en x: bx+8
    append cmds compose [
        pen (col-struct-border)  line-width 1  fill-pen (col-struct-bg + 30.30.30)
        box (as-pair (bx + 8) (by + 4)) (as-pair (bx + 26) (by + 22)) 2
        fill-pen (col-black)
        text (as-pair (bx + 13) (by + 4 + text-dy)) "<"
    ]
    ; ▶ (derecha) en x: bx+28
    append cmds compose [
        pen (col-struct-border)  line-width 1  fill-pen (col-struct-bg + 30.30.30)
        box (as-pair (bx + 28) (by + 4)) (as-pair (bx + 46) (by + 22)) 2
        fill-pen (col-black)
        text (as-pair (bx + 33) (by + 4 + text-dy)) ">"
    ]

    ; 5) Indicador de frame activo
    act-frame: either all [block? st/frames  st/active-frame < length? st/frames] [
        st/frames/(st/active-frame + 1)
    ][
        none
    ]
    frame-label: either act-frame [act-frame/label] ["?"]
    append cmds compose [
        fill-pen (col-black)
        text (as-pair (bx + 52) (by + 5 + text-dy)) (frame-label)
    ]

    ; 6) Botones [+][-] en esquina derecha de la barra
    ; [+] en x: bx2-48
    append cmds compose [
        pen (col-struct-border)  line-width 1  fill-pen (col-struct-bg + 20.20.20)
        box (as-pair (bx2 - 48) (by + 4)) (as-pair (bx2 - 30) (by + 22)) 2
        fill-pen (col-black)
        text (as-pair (bx2 - 43) (by + 4 + text-dy)) "+"
    ]
    ; [-] en x: bx2-26
    append cmds compose [
        pen (col-struct-border)  line-width 1  fill-pen (col-struct-bg + 20.20.20)
        box (as-pair (bx2 - 26) (by + 4)) (as-pair (bx2 - 8) (by + 22)) 2
        fill-pen (col-black)
        text (as-pair (bx2 - 20) (by + 4 + text-dy)) "-"
    ]

    ; 7) Terminal selector [?] — esquina superior izquierda debajo de la barra
    ;    (número entero = naranja, booleano = verde)
    sel-x: bx + 8
    append cmds compose [
        pen (col-struct-border)  line-width 1  fill-pen (col-wire)
        box (as-pair sel-x (by + nav-h + 4))
             (as-pair (sel-x + 14) (by + nav-h + 18)) 2
        fill-pen (col-black)
        text (as-pair (sel-x + 3) (by + nav-h + 3 + text-dy)) "?"
    ]

    ; 8) Handle de resize — esquina inferior-derecha 10x10
    append cmds compose [
        pen col-struct-border  line-width 1  fill-pen (col-struct-border + 40.40.40)
        box (as-pair (bx2 - 10) (by2 - 10)) (as-pair bx2 by2) 0
    ]

    ; 9) Borde de selección cian
    if all [same? st model/selected-struct  none? model/selected-node] [
        append cmds compose [
            pen col-sel  line-width 2  fill-pen off
            box (as-pair (bx - 3) (by - 3)) (as-pair (bx2 + 3) (by2 + 3)) 10
            line-width 1
        ]
    ]

    ; 10) Wire del selector (si hay selector-wire)
    if st/selector-wire [
        do [
            sel-src: none
            sel-src: find-node-by-id model/nodes st/selector-wire/from
            if sel-src [
                src-xy: port-xy sel-src st/selector-wire/port 'out
                dst-xy: as-pair (sel-x + 7) (by + nav-h + 11)
                mid-cx: to-integer (src-xy/x + dst-xy/x) / 2
                ; Color según tipo: detectado del wire conectado
                append cmds compose [
                    pen (col-wire)  line-width 2
                    line (src-xy) (as-pair mid-cx src-xy/y) (as-pair mid-cx dst-xy/y) (dst-xy)
                    line-width 1
                ]
            ]
        ]
    ]

    ; 11) Renderizar nodos y wires del frame activo
    if act-frame [
        append cmds render-node-list act-frame/nodes model/selected-node
        append cmds render-wire-list act-frame/wires act-frame/nodes model/selected-wire
    ]

    cmds
]

render-structure: func [
    "Genera Draw cmds para una estructura contenedora (while-loop, for-loop, case-structure)"
    st model
    /local cmds bx by bx2 by2 tx sr sr-col y-off _w _sr-has-ext-wire
            _sr-found _src-xy _in-xy _out-xy _dst-xy _mid-x _sr-col2
][
    ; Bifurcación: Case Structure tiene renderizado propio
    if st/type = 'case-structure [
        return render-case-structure st model
    ]

    ; ── WHILE/FOR LOOP ─────────────────────────────────────
    cmds: copy []
    bx: st/x  by: st/y  bx2: st/x + st/w  by2: st/y + st/h
    tx: struct-terminal-size

    ; 1) Fondo + borde del contenedor
    append cmds compose [
        pen (col-struct-border)  line-width 2  fill-pen (col-struct-bg)
        box (as-pair bx by) (as-pair bx2 by2) 8
        line-width 1
    ]

    ; 2) Label arriba-izquierda
    if all [st/label  object? st/label] [
        append cmds compose [
            pen off  fill-pen (col-struct-border)
            text (as-pair (bx + 8) (by + 6 + text-dy)) (st/label/text)
        ]
    ]

    ; 3) Terminal iteración [i] — cuadrado azul abajo-izquierda
    append cmds compose [
        pen (col-struct-border)  line-width 1  fill-pen (col-struct-term-i)
        box (as-pair (bx + 8) (by2 - tx - 8))
            (as-pair (bx + 8 + tx) (by2 - 8)) 2
        pen off  fill-pen col-text
        text (as-pair (bx + 11) (by2 - tx - 5 + text-dy)) "i"
    ]

    ; 4) Terminal condición [●] — círculo verde abajo-derecha (solo while-loop)
    ; Desplazado a bx2-24, by2-24 para no solapar con el handle de resize (14x14)
    if st/type = 'while-loop [
        append cmds compose [
            pen (col-struct-border)  line-width 1  fill-pen (col-struct-term-cond)
            circle (as-pair (bx2 - 24) (by2 - 24)) 8
        ]
    ]

    ; 4b) Terminal count [N] — cuadrado naranja arriba-izquierda (solo for-loop)
    if st/type = 'for-loop [
        append cmds compose [
            pen (col-struct-border)  line-width 1  fill-pen (col-wire)
            box (as-pair (bx + 8) (by + 8))
                (as-pair (bx + 8 + tx) (by + 8 + tx)) 2
            pen off  fill-pen col-text
            text (as-pair (bx + 11) (by + 11 + text-dy)) "N"
        ]
    ]

    ; 5) Terminales shift register — ▲ borde izquierdo, ▼ borde derecho
    if block? st/shift-regs [
        foreach sr head st/shift-regs [
            sr-col: sr-type-color sr/data-type
            y-off:  sr/y-offset
            append cmds compose [
                pen (col-struct-border)  line-width 1  fill-pen (sr-col)
                ; ▲ izquierdo (lectura — valor entra al loop)
                triangle (as-pair (bx - sr-terminal-half) (by + y-off + sr-terminal-half))
                         (as-pair (bx + sr-terminal-half) (by + y-off + sr-terminal-half))
                         (as-pair bx (by + y-off - sr-terminal-half))
                ; ▼ derecho (escritura — valor sale del loop)
                triangle (as-pair (bx2 - sr-terminal-half) (by + y-off - sr-terminal-half))
                         (as-pair (bx2 + sr-terminal-half) (by + y-off - sr-terminal-half))
                         (as-pair bx2 (by + y-off + sr-terminal-half))
            ]
            ; Texto init-value junto al ▲ — solo si no hay wire externo conectado a este SR
            _sr-has-ext-wire: false
            foreach _w model/wires [
                if all [_w/to-node = st/id  (to-word _w/to-port) = to-word sr/name] [
                    _sr-has-ext-wire: true
                ]
            ]
            unless _sr-has-ext-wire [
                append cmds compose [
                    pen off  fill-pen (col-struct-border)
                    text (as-pair (bx + 10) (by + y-off - 7 + text-dy)) (form sr/init-value)
                ]
            ]
        ]
    ]

    ; 6) Handle de resize — cuadrado 10x10 esquina inferior-derecha
    append cmds compose [
        pen col-struct-border  line-width 1  fill-pen (col-struct-border + 40.40.40)
        box (as-pair (bx2 - 10) (by2 - 10)) (as-pair bx2 by2) 0
    ]

    ; 7) Borde de selección cian — solo cuando la estructura en sí está seleccionada
    ;    (no cuando se ha seleccionado un nodo interno)
    if all [same? st model/selected-struct  none? model/selected-node] [
        append cmds compose [
            pen col-sel  line-width 2  fill-pen off
            box (as-pair (bx - 3) (by - 3)) (as-pair (bx2 + 3) (by2 + 3)) 10
            line-width 1
        ]
    ]

    ; 7b) Highlight del SR seleccionado — círculos cian en ambos triángulos
    if all [model/selected-sr  same? st model/selected-sr/1] [
        do [
            _sel-sr: model/selected-sr/2
            _sel-y:  to-integer by + _sel-sr/y-offset
            append cmds compose [
                pen col-sel  line-width 2  fill-pen off
                circle (as-pair bx _sel-y) (sr-terminal-half + 4)
                circle (as-pair bx2 _sel-y) (sr-terminal-half + 4)
                line-width 1
            ]
        ]
    ]

    ; 8) Wires desde terminales virtuales: iter (-3), SR-left (-1), SR-right (-2)
    do [
        half-tx: to-integer (tx / 2)   ; 14/2 = 7 — precomputado para evitar precedencia
        iter-src: as-pair (to-integer bx + 8 + half-tx) (to-integer by2 - half-tx - 8)
        foreach w st/wires [
            ; Iter (-3) → nodo interno
            if w/from-node = -3 [
                nd: find-node-by-id st/nodes w/to-node
                if nd [
                    in-xy: port-xy nd w/to-port 'in
                    mid-x: to-integer (iter-src/x + in-xy/x) / 2
                    append cmds compose [
                        pen col-wire  line-width 2
                        line (iter-src) (as-pair mid-x iter-src/y)
                             (as-pair mid-x in-xy/y) (in-xy)
                        line-width 1
                    ]
                ]
            ]
            ; SR-left (-1) → nodo interno
            if w/from-node = -1 [
                _sr-found: find-sr st/shift-regs w/from-port
                if _sr-found [
                    nd: find-node-by-id st/nodes w/to-node
                    if nd [
                        _src-xy: sr-xy st _sr-found 'left
                        _in-xy:  port-xy nd w/to-port 'in
                        _mid-x:  to-integer (_src-xy/x + _in-xy/x) / 2
                        _sr-col2: sr-type-color _sr-found/data-type
                        append cmds compose [
                            pen (_sr-col2)  line-width 2
                            line (_src-xy) (as-pair _mid-x _src-xy/y)
                                 (as-pair _mid-x _in-xy/y) (_in-xy)
                            line-width 1
                        ]
                    ]
                ]
            ]
            ; Nodo interno → SR-right (-2)
            if w/to-node = -2 [
                _sr-found: find-sr st/shift-regs w/to-port
                if _sr-found [
                    nd: find-node-by-id st/nodes w/from-node
                    if nd [
                        _out-xy: port-xy nd w/from-port 'out
                        _dst-xy: sr-xy st _sr-found 'right
                        _mid-x:  to-integer (_out-xy/x + _dst-xy/x) / 2
                        _sr-col2: sr-type-color _sr-found/data-type
                        append cmds compose [
                            pen (_sr-col2)  line-width 2
                            line (_out-xy) (as-pair _mid-x _out-xy/y)
                                 (as-pair _mid-x _dst-xy/y) (_dst-xy)
                            line-width 1
                        ]
                    ]
                ]
            ]
        ]
    ]

    ; 9) Wires internos normales (entre nodos reales)
    append cmds render-wire-list st/wires st/nodes model/selected-wire

    ; 10) Nodos internos
    append cmds render-node-list st/nodes model/selected-node

    ; 11) Wire de condición — línea desde el nodo fuente hasta el terminal ●
    if st/cond-wire [
        do [
            cond-src: none
            cond-src: find-node-by-id st/nodes st/cond-wire/from
            if cond-src [
                src-xy: port-xy cond-src st/cond-wire/port 'out
                dst-xy: as-pair (bx2 - 24) (by2 - 24)
                mid-cx: to-integer (src-xy/x + dst-xy/x) / 2
                append cmds compose [
                    pen (col-wire-bool)  line-width 2
                    line (src-xy) (as-pair mid-cx src-xy/y) (as-pair mid-cx dst-xy/y) (dst-xy)
                ]
            ]
        ]
    ]

    cmds
]

render-bd: func [model /local cmds src-port-xy mid st] [
    cmds: copy []

    ; 0) Grid de fondo
    append cmds render-grid 880 490

    ; 1) Estructuras contenedoras (detrás de los nodos normales)
    if block? model/structures [
        foreach st model/structures [
            append cmds render-structure st model
        ]
    ]

    ; 2) Wires permanentes normales
    append cmds render-wire-list model/wires model/nodes model/selected-wire

    ; 2b) Wires externos de shift registers (ext→▲ y ▼→ext) y wire N de for-loop
    if block? model/structures [
        foreach _sst model/structures [
            foreach _sw model/wires [
                ; For-loop: External → [N] (to-node = structure ID, to-port = "count")
                if all [_sst/type = 'for-loop  _sw/to-node = _sst/id  _sw/to-port = 'count] [
                    do [
                        _snd: none
                        _snd: find-node-by-id model/nodes _sw/from-node
                        if _snd [
                            _sout: port-xy _snd _sw/from-port 'out
                            _htx: to-integer (struct-terminal-size / 2)
                            _ndst: as-pair (to-integer _sst/x + 8 + _htx)
                                           (to-integer _sst/y + 8 + _htx)
                            _smx: to-integer (_sout/x + _ndst/x) / 2
                            append cmds compose [
                                pen (col-wire)  line-width 2
                                line (_sout) (as-pair _smx _sout/y)
                                     (as-pair _smx _ndst/y) (_ndst)
                                line-width 1
                            ]
                        ]
                    ]
                ]
                ; External → SR-left (to-node = structure ID)
                if _sw/to-node = _sst/id [
                    do [
                        _sfound: either block? _sst/shift-regs [find-sr _sst/shift-regs _sw/to-port] [none]
                        if _sfound [
                            _snd: find-node-by-id model/nodes _sw/from-node
                            if _snd [
                                _sout: port-xy _snd _sw/from-port 'out
                                _sdst: sr-xy _sst _sfound 'left
                                _smx:  to-integer (_sout/x + _sdst/x) / 2
                                _scol: sr-type-color _sfound/data-type
                                append cmds compose [
                                    pen (_scol)  line-width 2
                                    line (_sout) (as-pair _smx _sout/y)
                                         (as-pair _smx _sdst/y) (_sdst)
                                    line-width 1
                                ]
                            ]
                        ]
                    ]
                ]
                ; SR-right → external (from-node = structure ID)
                if _sw/from-node = _sst/id [
                    do [
                        _sfound: either block? _sst/shift-regs [find-sr _sst/shift-regs _sw/from-port] [none]
                        if _sfound [
                            _snd: none
                            _snd: find-node-by-id model/nodes _sw/to-node
                            if _snd [
                                _ssrc: sr-xy _sst _sfound 'right
                                _sin:  port-xy _snd _sw/to-port 'in
                                _smx:  to-integer (_ssrc/x + _sin/x) / 2
                                _scol: sr-type-color _sfound/data-type
                                append cmds compose [
                                    pen (_scol)  line-width 2
                                    line (_ssrc) (as-pair _smx _ssrc/y)
                                         (as-pair _smx _sin/y) (_sin)
                                    line-width 1
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]

    ; 3) Wire temporal (mientras el usuario elige destino)
    if all [model/wire-src model/mouse-pos] [
        src-port-xy: do [
            _sxy: none
            ; SR-left virtual (-1) — ▲ borde izquierdo
            if all [model/wire-src-struct  model/wire-src-sr  model/wire-src/id = -1] [
                _sxy: sr-xy model/wire-src-struct model/wire-src-sr 'left
            ]
            ; SR-right virtual (-2) — ▼ borde derecho
            if all [none? _sxy  model/wire-src-struct  model/wire-src-sr  model/wire-src/id = -2] [
                _sxy: sr-xy model/wire-src-struct model/wire-src-sr 'right
            ]
            ; Iter virtual (-3) — cuadrado [i]
            if all [none? _sxy  model/wire-src-struct] [
                _st2:  model/wire-src-struct
                _tx2:  struct-terminal-size
                _htx2: to-integer (_tx2 / 2)
                _sxy: as-pair (to-integer _st2/x + 8 + _htx2)
                              (to-integer _st2/y + _st2/h - _htx2 - 8)
            ]
            ; Puerto de nodo normal
            if none? _sxy [_sxy: port-xy model/wire-src model/wire-port 'out]
            _sxy
        ]
        append cmds compose [
            pen col-wire  line-width 2
            line (src-port-xy) (model/mouse-pos)
        ]
    ]

    ; 4) Wire roto — error visual de tipos incompatibles
    if model/broken-wire [
        append cmds compose [pen 210.30.30  line-width 2]
        append cmds draw-dashed-segment model/broken-wire/1 model/broken-wire/2
        mid: as-pair to-integer (model/broken-wire/1/x + model/broken-wire/2/x) / 2
                     to-integer (model/broken-wire/1/y + model/broken-wire/2/y) / 2
        append cmds compose [
            pen 210.30.30  line-width 2
            line (as-pair mid/x - 5 mid/y - 5) (as-pair mid/x + 5 mid/y + 5)
            line (as-pair mid/x + 5 mid/y - 5) (as-pair mid/x - 5 mid/y + 5)
        ]
    ]

    ; 5) Nodos normales (encima de las estructuras)
    append cmds render-node-list model/nodes model/selected-node

    cmds
]
