Red [
    Title:   "QTorres — Block Diagram Canvas"
    Purpose: "Canvas modular: render-diagram recibe modelo explícito (Issue #11)"
    Needs:   'View
]

; ══════════════════════════════════════════════════════════
; CONFIG — constantes visuales, sin estado mutable
; ══════════════════════════════════════════════════════════
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
    case [
        node/type = 'bundle [cluster-in-ports node]
        true                [any [block-in-ports to-word node/type  []]]
    ]
]

; Devuelve los puertos de salida de un nodo.
; Para unbundle: puertos dinámicos desde config/fields.
; Para el resto: consulta el block-registry.
out-ports: func [node] [
    case [
        node/type = 'unbundle [cluster-out-ports node]
        true                   [any [block-out-ports to-word node/type  []]]
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
; bundle/unbundle: variable según número de campos.
; Resto: block-height fijo.
node-height: func [node /local n-in n-out] [
    case [
        any [node/type = 'bundle  node/type = 'unbundle] [
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
make-diagram-model: func [] [
    make object! [
        nodes:          copy []
        wires:          copy []
        structures:     copy []
        front-panel:    copy []
        next-id:        1
        selected-node:  none
        selected-wire:  none
        selected-fp:    none
        selected-struct: none
        drag-node:      none
        drag-fp:        none
        drag-struct:    none
        drag-struct-off: none
        resize-struct:  none
        drag-off:       none
        drag-is-label:  false
        wire-src:        none
        wire-port:       none
        wire-src-struct: none   ; estructura que contiene el terminal [i] o SR activo
        wire-src-sr:     none   ; SR object si wire-src es un terminal SR (▲ o ▼)
        selected-sr:     none   ; [struct sr] cuando un terminal SR está seleccionado
        mouse-pos:       none
        broken-wire:     none
    ]
]

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
        src-node: none  dst-node: none
        foreach node nodes [
            if node/id = wire/from-node [src-node: node]
            if node/id = wire/to-node   [dst-node: node]
        ]
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
        if any [node/type = 'bundle  node/type = 'unbundle] [
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
            arr-control    ["ARR"]
            arr-indicator  ["ARR"]
            build-array    ["BUILD[]"]
            index-array    ["IDX[]"]
            array-size     ["SIZE[]"]
            array-subset   ["SUB[]"]
        ] [uppercase form node/type]
        either all [node/label  object? node/label  node/label/visible] [
            append cmds compose [
                fill-pen col-text
                text (as-pair (node/x + 10) (node/y + 10)) (any [node/label/text ""])
                text (as-pair (node/x + 10) (node/y + 26)) (type-label)
            ]
        ][
            either all [node/label  string? node/label] [
                append cmds compose [
                    fill-pen col-text
                    text (as-pair (node/x + 10) (node/y + 10)) (node/label)
                    text (as-pair (node/x + 10) (node/y + 26)) (type-label)
                ]
            ][
                append cmds compose [
                    fill-pen col-text
                    text (as-pair (node/x + 10) (node/y + 14)) (type-label)
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
                text (as-pair (node/x - port-radius - 22) (in-port-y - 7)) (form port)
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
                text (as-pair (node/x + block-width + port-radius + 12) (out-port-y - 7)) (form port)
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
    type-label: either node/type = 'bundle ["BUNDLE"] ["UNBUNDLE"]
    append cmds compose [
        fill-pen col-text
        text (as-pair (node/x + 8) (node/y + 14)) (type-label)
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

    ; 8) Handle de resize — esquina inferior-derecha
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
            foreach nd model/nodes [if nd/id = st/selector-wire/from [sel-src: nd]]
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
            text (as-pair (bx + 8) (by + 6)) (st/label/text)
        ]
    ]

    ; 3) Terminal iteración [i] — cuadrado azul abajo-izquierda
    append cmds compose [
        pen (col-struct-border)  line-width 1  fill-pen (col-struct-term-i)
        box (as-pair (bx + 8) (by2 - tx - 8))
            (as-pair (bx + 8 + tx) (by2 - 8)) 2
        pen off  fill-pen col-text
        text (as-pair (bx + 11) (by2 - tx - 5)) "i"
    ]

    ; 4) Terminal condición [●] — círculo verde abajo-derecha (solo while-loop)
    if st/type = 'while-loop [
        append cmds compose [
            pen (col-struct-border)  line-width 1  fill-pen (col-struct-term-cond)
            circle (as-pair (bx2 - 16) (by2 - 16)) 8
        ]
    ]

    ; 4b) Terminal count [N] — cuadrado naranja arriba-izquierda (solo for-loop)
    if st/type = 'for-loop [
        append cmds compose [
            pen (col-struct-border)  line-width 1  fill-pen (col-wire)
            box (as-pair (bx + 8) (by + 8))
                (as-pair (bx + 8 + tx) (by + 8 + tx)) 2
            pen off  fill-pen col-text
            text (as-pair (bx + 11) (by + 11)) "N"
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
                    text (as-pair (bx + 10) (by + y-off - 7)) (form sr/init-value)
                ]
            ]
        ]
    ]

    ; 6) Handle de resize — cuadrado 8x8 esquina inferior-derecha
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
                foreach nd st/nodes [
                    if nd/id = w/to-node [
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
            ]
            ; SR-left (-1) → nodo interno
            if w/from-node = -1 [
                _sr-found: find-sr st/shift-regs w/from-port
                if _sr-found [
                    foreach nd st/nodes [
                        if nd/id = w/to-node [
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
            ]
            ; Nodo interno → SR-right (-2)
            if w/to-node = -2 [
                _sr-found: find-sr st/shift-regs w/to-port
                if _sr-found [
                    foreach nd st/nodes [
                        if nd/id = w/from-node [
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
    ]

    ; 9) Wires internos normales (entre nodos reales)
    append cmds render-wire-list st/wires st/nodes model/selected-wire

    ; 10) Nodos internos
    append cmds render-node-list st/nodes model/selected-node

    ; 11) Wire de condición — línea desde el nodo fuente hasta el terminal ●
    if st/cond-wire [
        do [
            cond-src: none
            foreach nd st/nodes [if nd/id = st/cond-wire/from [cond-src: nd]]
            if cond-src [
                src-xy: port-xy cond-src st/cond-wire/port 'out
                dst-xy: as-pair (bx2 - 16) (by2 - 16)
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
                        foreach _nd model/nodes [if _nd/id = _sw/from-node [_snd: _nd]]
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
                            _snd: none
                            foreach _nd model/nodes [if _nd/id = _sw/from-node [_snd: _nd]]
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
                            foreach _nd model/nodes [if _nd/id = _sw/to-node [_snd: _nd]]
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

; ══════════════════════════════════════════════════════════
; HIT-TEST — funciones puras, reciben modelo y coordenadas
; ══════════════════════════════════════════════════════════

; Devuelve la estructura que contiene el nodo, o none si es externo.
; Para case-structure, busca en el frame activo.
node-structure: func [model node /local st nd frame] [
    foreach st model/structures [
        ; While/For loop: buscar en st/nodes
        if find [while-loop for-loop] st/type [
            foreach nd st/nodes [
                if nd/id = node/id [return st]
            ]
        ]
        ; Case structure: buscar en frame activo
        if st/type = 'case-structure [
            if all [block? st/frames  st/active-frame < length? st/frames] [
                frame: st/frames/(st/active-frame + 1)
                foreach nd frame/nodes [
                    if nd/id = node/id [return st]
                ]
            ]
        ]
    ]
    none
]

; Devuelve la estructura que contiene el punto, o none.
point-in-structure?: func [model mouse-x mouse-y /local st] [
    foreach st model/structures [
        if all [
            mouse-x >= st/x  mouse-x <= (st/x + st/w)
            mouse-y >= st/y  mouse-y <= (st/y + st/h)
        ] [return st]
    ]
    none
]

; Devuelve [struct node] si el punto cae sobre un nodo interno, o none.
; Para case-structure, busca en el frame activo.
hit-structure-node: func [model mouse-x mouse-y /local st node frame] [
    foreach st model/structures [
        ; Case Structure: buscar en frame activo
        if st/type = 'case-structure [
            if all [block? st/frames  st/active-frame < length? st/frames] [
                frame: st/frames/(st/active-frame + 1)
                foreach node frame/nodes [
                    if all [
                        mouse-x >= node/x  mouse-x <= (node/x + block-width)
                        mouse-y >= node/y  mouse-y <= (node/y + block-height)
                    ] [return reduce [st node]]
                ]
            ]
        ]
        ; While/For Loop: buscar en st/nodes
        if find [while-loop for-loop] st/type [
            foreach node st/nodes [
                if all [
                    mouse-x >= node/x  mouse-x <= (node/x + block-width)
                    mouse-y >= node/y  mouse-y <= (node/y + block-height)
                ] [return reduce [st node]]
            ]
        ]
    ]
    none
]

; Devuelve [struct 'cond|'iter|'count|'selector] si el punto cae sobre un terminal, o none.
; 'iter = terminal iteración [i] abajo-izquierda (while/for)
; 'cond = terminal condición [●] abajo-derecha (while)
; 'count = terminal count [N] arriba-izquierda (for)
; 'selector = terminal selector [?] arriba-izquierda (case)
hit-structure-terminal: func [model mouse-x mouse-y /local st bx by by2 bx2 tx tol nav-h] [
    tol: 8
    nav-h: case-nav-height
    foreach st model/structures [
        bx: st/x  by: st/y  by2: st/y + st/h  bx2: st/x + st/w
        tx: struct-terminal-size
        ; Case Structure: terminal selector arriba-izquierda debajo de la barra de navegación
        if st/type = 'case-structure [
            if all [
                mouse-x >= (bx + 8 - tol)  mouse-x <= (bx + 22 + tol)
                mouse-y >= (by + nav-h + 4 - tol)  mouse-y <= (by + nav-h + 18 + tol)
            ] [return reduce [st 'selector]]
        ]
        ; While/For Loop: terminal iteración [i] abajo-izquierda
        if find [while-loop for-loop] st/type [
            if all [
                mouse-x >= (bx + 8 - tol)  mouse-x <= (bx + 8 + tx + tol)
                mouse-y >= (by2 - tx - 8 - tol)  mouse-y <= (by2 - 8 + tol)
            ] [return reduce [st 'iter]]
        ]
        ; Terminal condición [●]: círculo en (bx2-16, by2-16) radio 8 — solo while-loop
        if st/type = 'while-loop [
            if all [
                (absolute (mouse-x - (bx2 - 16))) <= (8 + tol)
                (absolute (mouse-y - (by2 - 16))) <= (8 + tol)
            ] [return reduce [st 'cond]]
        ]
        ; Terminal count [N]: cuadrado (bx+8, by+8) → (bx+8+tx, by+8+tx) — solo for-loop
        if st/type = 'for-loop [
            if all [
                mouse-x >= (bx + 8 - tol)  mouse-x <= (bx + 8 + tx + tol)
                mouse-y >= (by + 8 - tol)   mouse-y <= (by + 8 + tx + tol)
            ] [return reduce [st 'count]]
        ]
    ]
    none
]

; Devuelve la estructura si el punto cae sobre el handle de resize, o none.
; Handle: esquina inferior-derecha 10x10px
hit-structure-resize: func [model mouse-x mouse-y /local st bx2 by2] [
    foreach st model/structures [
        bx2: st/x + st/w  by2: st/y + st/h
        if all [
            mouse-x >= (bx2 - 12)  mouse-x <= (bx2 + 2)
            mouse-y >= (by2 - 12)  mouse-y <= (by2 + 2)
        ] [return st]
    ]
    none
]

; Devuelve la estructura si el punto cae sobre el borde (~10px de margen), o none.
; El borde excluye esquina resize (ya detectada antes) y terminales.
hit-structure-border: func [model mouse-x mouse-y /local st bx by bx2 by2 bw] [
    bw: 10
    foreach st model/structures [
        bx: st/x  by: st/y  bx2: st/x + st/w  by2: st/y + st/h
        if all [
            mouse-x >= bx  mouse-x <= bx2
            mouse-y >= by  mouse-y <= by2
            any [
                mouse-x <= (bx + bw)
                mouse-x >= (bx2 - bw)
                mouse-y <= (by + bw)
                mouse-y >= (by2 - bw)
            ]
        ] [return st]
    ]
    none
]

; Devuelve [struct sr 'left|'right] si el punto cae sobre un terminal SR, o none.
; ▲ = borde izquierdo (lectura), ▼ = borde derecho (escritura)
hit-structure-sr: func [model mouse-x mouse-y /local st sr cy bx bx2 tol] [
    tol: sr-terminal-half + 4
    foreach st model/structures [
        bx: st/x  bx2: st/x + st/w
        if block? st/shift-regs [
            foreach sr head st/shift-regs [
                cy: to-integer st/y + sr/y-offset
                if all [
                    (absolute (mouse-x - bx)) <= tol
                    (absolute (mouse-y - cy)) <= tol
                ] [return reduce [st sr 'left]]
                if all [
                    (absolute (mouse-x - bx2)) <= tol
                    (absolute (mouse-y - cy)) <= tol
                ] [return reduce [st sr 'right]]
            ]
        ]
    ]
    none
]

; ══════════════════════════════════════════════════════════
; HIT-TEST — Case Structure
; ══════════════════════════════════════════════════════════

; Devuelve [struct 'prev|'next|'add|'remove] si el punto cae sobre botones de navegación.
hit-case-nav-buttons: func [model mouse-x mouse-y /local st bx by bx2 btn-h tol] [
    btn-h: case-btn-size
    tol: 4
    foreach st model/structures [
        if st/type = 'case-structure [
            bx: st/x  by: st/y  bx2: st/x + st/w
            ; Solo verificar si está en la barra de navegación
            if all [mouse-y >= (by + tol)  mouse-y <= (by + case-nav-height - tol)] [
                ; ◀ (prev) en x: bx+8 a bx+26
                if all [mouse-x >= (bx + 8 - tol)  mouse-x <= (bx + 26 + tol)] [
                    return reduce [st 'prev]
                ]
                ; ▶ (next) en x: bx+28 a bx+46
                if all [mouse-x >= (bx + 28 - tol)  mouse-x <= (bx + 46 + tol)] [
                    return reduce [st 'next]
                ]
                ; [+] (add) en x: bx2-48 a bx2-30
                if all [mouse-x >= (bx2 - 48 - tol)  mouse-x <= (bx2 - 30 + tol)] [
                    return reduce [st 'add]
                ]
                ; [-] (remove) en x: bx2-26 a bx2-8
                if all [mouse-x >= (bx2 - 26 - tol)  mouse-x <= (bx2 - 8 + tol)] [
                    return reduce [st 'remove]
                ]
            ]
        ]
    ]
    none
]

; Devuelve [struct 'selector] si el punto cae sobre el terminal selector [?].
hit-case-terminal: func [model mouse-x mouse-y /local st bx by tol nav-h] [
    tol: 8
    nav-h: case-nav-height
    foreach st model/structures [
        if st/type = 'case-structure [
            bx: st/x  by: st/y
            ; Terminal selector: cuadrado en (bx+8, by+nav-h+4) → (bx+22, by+nav_h+18)
            if all [
                mouse-x >= (bx + 8 - tol)  mouse-x <= (bx + 22 + tol)
                mouse-y >= (by + nav-h + 4 - tol)  mouse-y <= (by + nav-h + 18 + tol)
            ] [return reduce [st 'selector]]
        ]
    ]
    none
]

; Devuelve [struct node] si el punto cae sobre un nodo interno del frame activo.
; Para case-structure, solo busca en el frame activo.
hit-case-frame-node: func [model mouse-x mouse-y /local st frame node] [
    foreach st model/structures [
        if st/type = 'case-structure [
            if all [block? st/frames  st/active-frame < length? st/frames] [
                frame: st/frames/(st/active-frame + 1)
                foreach node frame/nodes [
                    if all [
                        mouse-x >= node/x  mouse-x <= (node/x + block-width)
                        mouse-y >= node/y  mouse-y <= (node/y + block-height)
                    ] [return reduce [st node]]
                ]
            ]
        ]
    ]
    none
]

hit-port: func [model mouse-x mouse-y /local ports out-y center-x center-y in-y node port all-nodes st frame] [
    ; Reúne todos los nodos: normales + internos de estructuras (while/for + case frames activos)
    all-nodes: copy model/nodes
    if block? model/structures [
        foreach st model/structures [
            if find [while-loop for-loop] st/type [
                foreach node st/nodes [append all-nodes node]
            ]
            if st/type = 'case-structure [
                if all [block? st/frames  st/active-frame < length? st/frames] [
                    frame: st/frames/(st/active-frame + 1)
                    foreach node frame/nodes [append all-nodes node]
                ]
            ]
        ]
    ]
    foreach node all-nodes [
        ports: out-ports node
        out-y: node/y + 12
        foreach port ports [
            center-x: node/x + block-width + port-radius
            center-y: out-y
            if all [(absolute (mouse-x - center-x)) < 16  (absolute (mouse-y - center-y)) < 16] [
                return reduce [node port 'out]
            ]
            out-y: out-y + 20
        ]
        ports: in-ports node
        in-y: node/y + 12
        foreach port ports [
            center-x: node/x - port-radius
            center-y: in-y
            if all [(absolute (mouse-x - center-x)) < 16  (absolute (mouse-y - center-y)) < 16] [
                return reduce [node port 'in]
            ]
            in-y: in-y + 20
        ]
    ]
    none
]

hit-node: func [model mouse-x mouse-y /local found-node node h] [
    found-node: none
    foreach node model/nodes [
        h: node-height node
        if all [
            mouse-x >= node/x  mouse-x <= (node/x + block-width)
            mouse-y >= node/y  mouse-y <= (node/y + h)
        ] [found-node: node]
    ]
    found-node
]

; Comprueba si el punto (mx my) está sobre algún wire de la lista dada.
hit-wire-in-list: func [wires nodes mouse-x mouse-y /local tolerance src-node dst-node out-xy in-xy mid-x wire node] [
    tolerance: 8
    foreach wire wires [
        src-node: none  dst-node: none
        foreach node nodes [
            if node/id = wire/from-node [src-node: node]
            if node/id = wire/to-node   [dst-node: node]
        ]
        if all [src-node dst-node] [
            out-xy: port-xy src-node wire/from-port 'out
            in-xy:  port-xy dst-node wire/to-port   'in
            mid-x:  to-integer (out-xy/x + in-xy/x) / 2
            if all [
                (absolute (mouse-y - out-xy/y)) < tolerance
                mouse-x >= (min out-xy/x mid-x)  mouse-x <= (max out-xy/x mid-x)
            ] [return wire]
            if all [
                (absolute (mouse-x - mid-x)) < tolerance
                mouse-y >= (min out-xy/y in-xy/y)  mouse-y <= (max out-xy/y in-xy/y)
            ] [return wire]
            if all [
                (absolute (mouse-y - in-xy/y)) < tolerance
                mouse-x >= (min mid-x in-xy/x)  mouse-x <= (max mid-x in-xy/x)
            ] [return wire]
        ]
    ]
    none
]

hit-wire: func [model mouse-x mouse-y /local w st frame] [
    ; Wires normales
    w: hit-wire-in-list model/wires model/nodes mouse-x mouse-y
    if w [return w]
    ; Wires internos de estructuras
    if block? model/structures [
        foreach st model/structures [
            ; While/For loop: st/wires
            if find [while-loop for-loop] st/type [
                w: hit-wire-in-list st/wires st/nodes mouse-x mouse-y
                if w [return w]
            ]
            ; Case structure: frame activo
            if all [st/type = 'case-structure  block? st/frames  st/active-frame < length? st/frames] [
                frame: st/frames/(st/active-frame + 1)
                w: hit-wire-in-list frame/wires frame/nodes mouse-x mouse-y
                if w [return w]
            ]
        ]
    ]
    none
]

; ══════════════════════════════════════════════════════════
; CANVAS FACTORY — render-diagram devuelve una face funcional
;   El modelo se almacena en face/extra para que los actores
;   puedan acceder sin depender de variables globales.
; ══════════════════════════════════════════════════════════

; Alterna el valor booleano de un nodo bool-const.
; node/config es un bloque de pares [clave valor ...].
toggle-bool-const: func [node /local cur pos] [
    cur: any [select node/config 'default  false]
    either pos: find node/config 'default [
        pos/2: not cur
    ][
        append node/config reduce ['default  not cur]
    ]
]

; Abre diálogo para editar el valor de una constante numérica.
; Patrón view/no-wait con vars de módulo (igual que rename-dialog).
open-const-edit-dialog: func [node canvas-face /local cur-val] [
    cur-val: any [select node/config 'default  0.0]
    const-dialog-node:   node
    const-dialog-canvas: canvas-face
    const-dialog-field:  none
    view/no-wait compose [
        title "Editar constante"
        text "Valor:" return
        const-dialog-field: field 150 (form cur-val)
        on-enter [
            apply-const-value const-dialog-node const-dialog-field/text
            const-dialog-canvas/draw: render-bd const-dialog-canvas/extra
            unview
        ]
        return
        button "OK" [
            apply-const-value const-dialog-node const-dialog-field/text
            const-dialog-canvas/draw: render-bd const-dialog-canvas/extra
            unview
        ]
        button "Cancelar" [unview]
    ]
]

; Actualiza node/config 'default con el nuevo valor numérico.
apply-const-value: func [node new-text /local val pos] [
    val: attempt [to-float new-text]
    if none? val [exit]
    either pos: find node/config 'default [
        pos/2: val
    ][
        append node/config reduce ['default val]
    ]
]

; Aplica valor string a un nodo y refresca el canvas.
; Función auxiliar para evitar set-path con valor literal en compose/deep.
str-apply-and-refresh: func [nd txt cnv] [
    apply-str-value nd txt
    cnv/draw: render-bd cnv/extra
]

; Abre diálogo para editar el valor de una constante o control string.
; Usa compose/deep para incrustar node y canvas-face directamente en los handlers,
; evitando el bug de variables de módulo compartidas cuando dos diálogos están abiertos.
open-str-edit-dialog: func [node canvas-face /local cur-val] [
    cur-val: copy any [select node/config 'default  ""]
    view/no-wait compose/deep [
        title "Editar string"
        text "Valor:" return
        field 200 (cur-val)
        on-enter [
            ; face = el field (on-enter se dispara en el field)
            str-apply-and-refresh (node) copy face/text (canvas-face)
            unview
        ]
        return
        button "OK" [
            ; Buscar el field en los panes del panel padre
            foreach pf face/parent/pane [
                if pf/type = 'field [
                    str-apply-and-refresh (node) copy pf/text (canvas-face)
                    break
                ]
            ]
            unview
        ]
        button "Cancelar" [unview]
    ]
]

; Actualiza node/config 'default con el nuevo valor string.
apply-str-value: func [node new-text /local pos] [
    either pos: find node/config 'default [
        pos/2: new-text
    ][
        append node/config reduce ['default new-text]
    ]
]

; Actualiza node/config 'default con un block! de valores numéricos parseados desde texto.
; El usuario introduce valores separados por espacios, ej: "1.0 2.0 3.0"
apply-arr-value: func [node new-text /local pos vals tok parsed-block] [
    parsed-block: copy []
    vals: split trim new-text " "
    foreach tok vals [
        tok: trim tok
        if not empty? tok [
            append parsed-block any [attempt [to-float tok]  attempt [to-integer tok]  0.0]
        ]
    ]
    either pos: find node/config 'default [
        pos/2: parsed-block
    ][
        append node/config reduce ['default parsed-block]
    ]
]

arr-apply-and-refresh: func [nd txt cnv] [
    apply-arr-value nd txt
    cnv/draw: render-bd cnv/extra
]

; Abre diálogo para editar el valor de un array constante.
; El usuario introduce números separados por espacios: "1.0 2.0 3.0"
open-arr-edit-dialog: func [node canvas-face /local cur-val cur-text] [
    cur-val: any [select node/config 'default  copy []]
    cur-text: form cur-val   ; "1.0 2.0 3.0"
    view/no-wait compose/deep [
        title "Editar array"
        text "Valores (separados por espacios):" return
        field 250 (cur-text)
        on-enter [
            arr-apply-and-refresh (node) copy face/text (canvas-face)
            unview
        ]
        return
        button "OK" [
            foreach pf face/parent/pane [
                if pf/type = 'field [
                    arr-apply-and-refresh (node) copy pf/text (canvas-face)
                    break
                ]
            ]
            unview
        ]
        button "Cancelar" [unview]
    ]
]

apply-rename-label: func [node new-text] [
    either empty? new-text [
        if all [node/label  object? node/label] [
            node/label/visible: false
        ]
    ][
        either all [node/label  object? node/label] [
            node/label/text: new-text
            node/label/visible: true
        ][
            node/label: new-text
        ]
    ]
]

; ── Cluster edit dialog ──────────────────────────────────────────────────

; Guarda la lista de campos en node/config/fields.
apply-cluster-fields: func [node fields-block /local pos] [
    either pos: find node/config 'fields [
        pos/2: fields-block
    ][
        append node/config reduce ['fields  fields-block]
    ]
]

; Parsea el texto del área de edición ("nombre:tipo" por línea) a [nombre 'tipo ...].
parse-cluster-fields-text: func [text /local result lines parts fname ftype] [
    result: copy []
    foreach line split text "^/" [
        line: trim line
        if not empty? line [
            parts: split line ":"
            if (length? parts) >= 2 [
                fname: to-word trim parts/1
                ftype: to-word trim parts/2
                unless find [number boolean string] ftype [ftype: 'number]
                append result fname
                append result to lit-word! ftype
            ]
        ]
    ]
    result
]

; Aplica campos parseados y refresca el canvas.
cluster-apply-and-refresh: func [nd txt cnv] [
    apply-cluster-fields nd parse-cluster-fields-text txt
    cnv/draw: render-bd cnv/extra
    show cnv
]

; Vars de módulo para el diálogo de edición de cluster (mismo patrón que rename)
cluster-dialog-node:   none
cluster-dialog-canvas: none
cluster-dialog-area:   none

; Abre diálogo para editar los campos de un bundle/unbundle.
; El usuario introduce campos en formato "nombre:tipo", uno por línea.
open-cluster-edit-dialog: func [node canvas-face /local cur-fields cur-text] [
    cluster-dialog-node:   node
    cluster-dialog-canvas: canvas-face
    cluster-dialog-area:   none
    cur-fields: cluster-fields node
    cur-text: copy ""
    foreach [fn ft] cur-fields [
        append cur-text rejoin [form fn ":" form to-word ft "^/"]
    ]
    view/no-wait compose/deep [
        title "Editar campos del cluster"
        text {Formato: nombre:tipo (uno por línea)} return
        text {Tipos: number  boolean  string} return
        cluster-dialog-area: area 260x180 (cur-text)
        return
        button "OK" [
            cluster-apply-and-refresh (node) copy cluster-dialog-area/text (canvas-face)
            unview
        ]
        button "Cancelar" [unview]
    ]
]

; Estado del diálogo de renombrado (view/no-wait requiere vars de módulo
; porque la función retorna antes de que el usuario cierre el diálogo).
rename-dialog-node:   none
rename-dialog-canvas: none
rename-dialog-field:  none

; Estado del diálogo de edición de constante numérica (mismo patrón)
const-dialog-node:    none
const-dialog-canvas:  none
const-dialog-field:   none

; ── Paleta de bloques ────────────────────────────────────────────
; vars de módulo para el diálogo de paleta (mismo patrón que rename)
palette-canvas: none
palette-pos-x:  0
palette-pos-y:  0
palette-struct: none   ; none = añadir a model/nodes, structure = añadir a st/nodes

; Añade un nodo al destino correcto: estructura interna o diagrama principal.
palette-add-node: func [node-type /local n nid model] [
    model: palette-canvas/extra
    nid: gen-node-id model
    n: make-node compose [id: (nid) type: (node-type) x: (palette-pos-x) y: (palette-pos-y)]
    either palette-struct [
        ; Case structure: añadir al frame activo
        if all [palette-struct/type = 'case-structure  block? palette-struct/frames] [
            if palette-struct/active-frame < length? palette-struct/frames [
                append palette-struct/frames/(palette-struct/active-frame + 1)/nodes n
            ]
        ]
        ; While/For loop: añadir a st/nodes
        if find [while-loop for-loop] palette-struct/type [
            append palette-struct/nodes n
        ]
    ][
        append model/nodes n
    ]
    palette-canvas/draw: render-bd model
    show palette-canvas
    unview
]

; Crea una nueva estructura while-loop y la añade al diagrama.
palette-add-structure: func [type [word!] /local nid st model] [
    model: palette-canvas/extra
    nid: gen-node-id model
    st: make-structure compose [id: (nid) type: (type) x: (palette-pos-x) y: (palette-pos-y)]
    if type = 'case-structure [append st/frames make-frame [id: 0 label: "0"]]
    append model/structures st
    palette-canvas/draw: render-bd model
    show palette-canvas
    unview
]

open-palette: func [face x y /struct target-struct] [
    palette-canvas: face
    palette-pos-x:  x
    palette-pos-y:  y
    palette-struct: target-struct
    view/no-wait [
        title "Añadir bloque"
        text "Aritmética:"  return
        button 80 "Add +"    [palette-add-node 'add]
        button 80 "Sub -"    [palette-add-node 'sub]
        button 80 "Mul *"    [palette-add-node 'mul]
        button 80 "Div /"    [palette-add-node 'div]    return
        text "Constante / salida:"  return
        button 80 "Const"    [palette-add-node 'const]
        button 80 "Display"  [palette-add-node 'display]  return
        text "Lógica:"  return
        button 80 "AND"      [palette-add-node 'and-op]
        button 80 "OR"       [palette-add-node 'or-op]
        button 80 "NOT"      [palette-add-node 'not-op]
        button 80 "B-Const"  [palette-add-node 'bool-const]  return
        text "Comparadores:"  return
        button 80 ">"        [palette-add-node 'gt-op]
        button 80 "<"        [palette-add-node 'lt-op]
        button 80 "="        [palette-add-node 'eq-op]
        button 80 "!="       [palette-add-node 'neq-op]  return
        text "String:"  return
        button 80 "S-Const"  [palette-add-node 'str-const]
        button 80 "Concat"   [palette-add-node 'concat]
        button 80 "Len"      [palette-add-node 'str-length]
        button 80 "→STR"     [palette-add-node 'to-string]  return
        text "Array:"  return
        button 80 "Arr[]"    [palette-add-node 'arr-const]
        button 80 "Build[]"  [palette-add-node 'build-array]
        button 80 "Index[]"  [palette-add-node 'index-array]  return
        button 80 "Size[]"   [palette-add-node 'array-size]
        button 80 "Subset[]" [palette-add-node 'array-subset]  return
        text "Cluster:"  return
        button 80 "Bundle"   [palette-add-node 'bundle]
        button 80 "Unbundle" [palette-add-node 'unbundle]  return
        text "Estructuras:"  return
        button 80 "While"    [palette-add-structure 'while-loop]
        button 80 "For"      [palette-add-structure 'for-loop]
        button 80 "Case"     [palette-add-structure 'case-structure]  return
        button 80 "Add SR"   [
            if palette-struct [
                unview
                open-add-sr-dialog palette-canvas palette-struct
            ]
        ]
        return
        button "Cancelar"    [unview]
    ]
]

; ── Shift Register helpers ──────────────────────────────────────────

; Añade un SR de tipo dado a la estructura, calculando el y-offset automáticamente.
add-sr-to-structure: func [st dtype /local y sr] [
    y: 40 + (50 * length? st/shift-regs)
    sr: make-shift-register compose [data-type: (dtype)  y-offset: (y)]
    append st/shift-regs sr
]

; Vars de módulo para diálogos SR (patrón view/no-wait)
add-sr-canvas: none
add-sr-struct:  none
sr-edit-canvas: none
sr-edit-sr-obj: none

; Abre diálogo para elegir el tipo del nuevo shift register.
open-add-sr-dialog: func [canvas st] [
    add-sr-canvas: canvas
    add-sr-struct:  st
    view/no-wait [
        title "Añadir shift register"
        text "Tipo de dato:"  return
        button 80 "Number"  [add-sr-to-structure add-sr-struct 'number
                              add-sr-canvas/draw: render-bd add-sr-canvas/extra
                              show add-sr-canvas  unview]
        button 80 "Boolean" [add-sr-to-structure add-sr-struct 'boolean
                              add-sr-canvas/draw: render-bd add-sr-canvas/extra
                              show add-sr-canvas  unview]
        button 80 "String"  [add-sr-to-structure add-sr-struct 'string
                              add-sr-canvas/draw: render-bd add-sr-canvas/extra
                              show add-sr-canvas  unview]    return
        button "Cancelar" [unview]
    ]
]

; Actualiza el init-value de un SR desde texto.
apply-sr-init-value: func [sr new-text /local val] [
    val: switch sr/data-type [
        string  [new-text]
        boolean [any [attempt [to-logic new-text]  false]]
    ]
    if none? val [val: any [attempt [to-float new-text]  0.0]]
    sr/init-value: val
]

; Abre diálogo para editar el valor inicial de un SR.
open-sr-edit-dialog: func [canvas sr /local cur] [
    sr-edit-canvas: canvas
    sr-edit-sr-obj: sr
    cur: form sr/init-value
    view/no-wait compose [
        title "Valor inicial SR"
        text (rejoin [sr/name "  [" form sr/data-type "]"]) return
        text "Valor inicial:" return
        sr-edit-fld: field 150 (cur)
        on-enter [
            apply-sr-init-value sr-edit-sr-obj sr-edit-fld/text
            sr-edit-canvas/draw: render-bd sr-edit-canvas/extra
            unview
        ]
        return
        button "OK" [
            apply-sr-init-value sr-edit-sr-obj sr-edit-fld/text
            sr-edit-canvas/draw: render-bd sr-edit-canvas/extra
            unview
        ]
        button "Cancelar" [unview]
    ]
]

; Borra el elemento seleccionado (nodo, wire o estructura completa).
; Llamar desde el on-key del window padre con: canvas-delete-selected canvas
canvas-delete-selected: func [canvas /local model node-id node-name node-type st found _pref _sst _ssr _frame] [
    model: canvas/extra

    ; SR seleccionado: borrar de la estructura + limpiar wires asociados
    if model/selected-sr [
        _sst: model/selected-sr/1
        _ssr: model/selected-sr/2
        ; Borrar wires internos que usen este SR (from: -1 o to: -2 con from-port/to-port = sr/name)
        remove-each w _sst/wires [
            any [
                all [w/from-node = -1  w/from-port = to-word _ssr/name]
                all [w/to-node   = -2  w/to-port   = to-word _ssr/name]
            ]
        ]
        ; Borrar wires externos (to-node = st/id  to-port = sr/name, o from-node = st/id from-port = sr/name)
        remove-each w model/wires [
            any [
                all [w/to-node   = _sst/id  w/to-port   = to-word _ssr/name]
                all [w/from-node = _sst/id  w/from-port = to-word _ssr/name]
            ]
        ]
        remove-each sr _sst/shift-regs [same? sr _ssr]
        model/selected-sr:     none
        model/selected-struct: none
        canvas/draw: render-bd model
        exit
    ]

    ; Wire seleccionado: buscar en model/wires y en wires internos
    if model/selected-wire [
        found: find model/wires model/selected-wire
        if found [remove found]
        if block? model/structures [
            foreach st model/structures [
                ; While/For loop: st/wires
                found: find st/wires model/selected-wire
                if found [remove found]
                ; Case structure: st/frames/*/wires
                if all [st/type = 'case-structure  block? st/frames] [
                    foreach _frame st/frames [
                        found: find _frame/wires model/selected-wire
                        if found [remove found]
                    ]
                ]
            ]
        ]
        if model/selected-struct [
            st: model/selected-struct
            if all [st/type = 'case-structure  block? st/frames  st/active-frame < length? st/frames] [
                _frame: st/frames/(st/active-frame + 1)
                found: find _frame/wires model/selected-wire
                if found [remove found]
            ]
        ]
        model/selected-wire: none
        canvas/draw: render-bd model
        exit
    ]

    ; Nodo interno seleccionado (tanto selected-node como selected-struct están activos)
    if model/selected-node [
        if model/selected-struct [
            node-id: model/selected-node/id
            st: model/selected-struct
            ; Case structure: buscar en frame activo
            if all [st/type = 'case-structure  block? st/frames  st/active-frame < length? st/frames] [
                _frame: st/frames/(st/active-frame + 1)
                remove-each wire _frame/wires [any [wire/from-node = node-id  wire/to-node = node-id]]
                remove-each nd _frame/nodes [nd/id = node-id]
            ]
            ; While/For loop: buscar en st/nodes
            if find [while-loop for-loop] st/type [
                remove-each wire st/wires [any [wire/from-node = node-id  wire/to-node = node-id]]
                remove-each nd st/nodes [nd/id = node-id]
            ]
            model/selected-node: none
            model/selected-struct: none   ; limpiar para que el 2º evento key no borre la estructura
            model/drag-node: none
            canvas/draw: render-bd model
            exit
        ]
        ; Nodo externo seleccionado
        node-id:   model/selected-node/id
        node-name: model/selected-node/name
        node-type: model/selected-node/type
        remove-each wire model/wires [any [wire/from-node = node-id  wire/to-node = node-id]]
        remove-each node model/nodes  [node/id = node-id]
        model/selected-node: none
        model/drag-node:     none
        ; Sync FP: borrar item correspondiente si es control/indicator
        _pref: select model 'panel-ref
        if all [
            find [control indicator bool-control bool-indicator str-control str-indicator] node-type
            _pref
        ][
            remove-each item model/front-panel [item/name = node-name]
            _pref/draw: render-fp-panel model model/size/x model/size/y
            show _pref
        ]
        canvas/draw: render-bd model
        exit
    ]

    ; Estructura completa seleccionada (borde, sin nodo seleccionado)
    if model/selected-struct [
        st: model/selected-struct
        ; Limpiar wire de N si es for-loop
        if st/type = 'for-loop [
            remove-each w model/wires [
                all [w/to-node = st/id  w/to-port = 'count]
            ]
        ]
        ; Limpiar selector-wire si es case-structure
        if st/type = 'case-structure [
            st/selector-wire: none
        ]
        remove-each s model/structures [same? s st]
        model/selected-struct: none
        canvas/draw: render-bd model
    ]
]

; render-diagram model canvas-width canvas-height → face
; Crea una face base con bloques arrastrables, creación de wires,
; hit-testing y renombrado por doble clic.
render-diagram: func [model canvas-width canvas-height /local canvas-face] [
    canvas-face: make face! [
        type:  'base
        size:  as-pair canvas-width canvas-height
        flags: [all-over]
        extra: model                    ; modelo accesible desde actores via face/extra
        actors: make object! [

            on-down: func [face event /local mouse-x mouse-y model hit-result hit-nd hit-port-name hit-dir hit-ref] [
                model: face/extra
                mouse-x: event/offset/x
                mouse-y: event/offset/y

                ; 1) Puerto? (incluye nodos internos de estructuras)
                hit-result: hit-port model mouse-x mouse-y
                if hit-result [
                    hit-nd:        hit-result/1
                    hit-port-name: hit-result/2
                    hit-dir:       hit-result/3
                    either model/wire-src = none [
                        if hit-dir = 'out [
                            model/broken-wire: none
                            model/wire-src:  hit-nd
                            model/wire-port: hit-port-name
                            model/mouse-pos: event/offset
                            face/draw: render-bd model
                        ]
                    ][
                        ; Completar wire — manejo SR-aware
                        do [
                            _hit-ok: false
                            if all [hit-dir = 'in  model/wire-src/id <> hit-nd/id] [
                                _out-t: port-out-type model/wire-src model/wire-port
                                if model/wire-src-sr [_out-t: model/wire-src-sr/data-type]
                                if model/wire-src/id = -3 [_out-t: 'number]
                                _hit-ok: _out-t = port-in-type hit-nd hit-port-name
                            ]
                            either _hit-ok [
                                model/broken-wire: none
                                src-st: any [model/wire-src-struct  node-structure model model/wire-src]
                                dst-st: node-structure model hit-nd
                                ; SR-left (-1): solo conecta a nodo INTERNO de la misma estructura
                                _sr-ok: true
                                if model/wire-src/id = -1 [
                                    if not all [dst-st  same? dst-st src-st] [_sr-ok: false]
                                ]
                                ; SR-right (-2): solo conecta a nodo EXTERNO
                                if model/wire-src/id = -2 [
                                    if dst-st [_sr-ok: false]
                                ]
                                if _sr-ok [
                                    wire-list: either all [src-st  dst-st  same? src-st dst-st] [
                                        src-st/wires
                                    ] [
                                        model/wires
                                    ]
                                    actual-from-node: model/wire-src/id
                                    actual-from-port: model/wire-port
                                    ; Iter (-3): from-port = nombre var iter
                                    if model/wire-src/id = -3 [
                                        actual-from-port: to-word rejoin ["_" model/wire-src-struct/name "_i"]
                                    ]
                                    ; SR (-1 o -2): from-port = sr/name; SR-right usa struct ID como from-node
                                    if model/wire-src-sr [
                                        actual-from-port: to-word model/wire-src-sr/name
                                        if model/wire-src/id = -2 [
                                            actual-from-node: model/wire-src-struct/id
                                        ]
                                    ]
                                    append wire-list make-wire compose [
                                        from: (actual-from-node)
                                        from-port: (actual-from-port)
                                        to: (hit-nd/id)
                                        to-port: (hit-port-name)
                                    ]
                                ]
                            ][
                                ; Tipos incompatibles: wire roto rojo
                                if all [hit-dir = 'in  model/wire-src/id <> hit-nd/id] [
                                    _bw-src: either model/wire-src-sr [
                                        either model/wire-src/id = -1 [
                                            sr-xy model/wire-src-struct model/wire-src-sr 'left
                                        ][
                                            sr-xy model/wire-src-struct model/wire-src-sr 'right
                                        ]
                                    ][
                                        port-xy model/wire-src model/wire-port 'out
                                    ]
                                    model/broken-wire: reduce [_bw-src  port-xy hit-nd hit-port-name 'in]
                                ]
                            ]
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none
                        model/wire-src-struct: none  model/wire-src-sr: none
                        face/draw: render-bd model
                    ]
                    return none
                ]

                ; 2) Nodo interno de estructura? (antes que borde/nodo normal)
                hit-result: hit-structure-node model mouse-x mouse-y
                if hit-result [
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                    model/broken-wire: none
                    model/selected-wire: none
                    model/selected-sr: none
                    model/selected-struct: hit-result/1
                    model/selected-node: hit-result/2
                    model/drag-node: hit-result/2
                    model/drag-off: as-pair (mouse-x - hit-result/2/x) (mouse-y - hit-result/2/y)
                    if hit-result/2/type = 'bool-const [toggle-bool-const hit-result/2]
                    face/draw: render-bd model
                    return none
                ]

                ; 2.5) Terminal SR (▲ izquierdo o ▼ derecho)?
                hit-result: hit-structure-sr model mouse-x mouse-y
                if hit-result [
                    do [
                        _st:   hit-result/1
                        _sr:   hit-result/2
                        _side: hit-result/3
                        either model/wire-src [
                            ; Hay wire activo — intentar completar conexión en SR terminal
                            _completed: false
                            if _side = 'left [
                                ; External → SR-left: wire-src debe ser nodo EXTERNO
                                if all [model/wire-src/id > 0  none? node-structure model model/wire-src] [
                                    _out-t: port-out-type model/wire-src model/wire-port
                                    either _out-t = _sr/data-type [
                                        model/broken-wire: none
                                        append model/wires make-wire compose [
                                            from: (model/wire-src/id)  from-port: (model/wire-port)
                                            to: (_st/id)  to-port: (to-word _sr/name)
                                        ]
                                    ][
                                        model/broken-wire: reduce [
                                            port-xy model/wire-src model/wire-port 'out
                                            sr-xy _st _sr 'left
                                        ]
                                    ]
                                    _completed: true
                                ]
                            ]
                            if _side = 'right [
                                ; Internal → SR-right: wire-src debe ser nodo INTERNO de esta estructura
                                _src-st: node-structure model model/wire-src
                                if all [_src-st  same? _src-st _st] [
                                    _out-t: port-out-type model/wire-src model/wire-port
                                    either _out-t = _sr/data-type [
                                        model/broken-wire: none
                                        append _st/wires make-wire compose [
                                            from: (model/wire-src/id)  from-port: (model/wire-port)
                                            to: -2  to-port: (to-word _sr/name)
                                        ]
                                    ][
                                        model/broken-wire: reduce [
                                            port-xy model/wire-src model/wire-port 'out
                                            sr-xy _st _sr 'right
                                        ]
                                    ]
                                    _completed: true
                                ]
                            ]
                            model/wire-src: none  model/wire-port: none
                            model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                            face/draw: render-bd model
                            return none
                        ][
                            ; Sin wire activo: seleccionar SR e iniciar wire
                            model/selected-sr:     reduce [_st _sr]
                            model/selected-struct: none
                            model/selected-node:   none
                            model/selected-wire:   none
                            model/broken-wire:     none
                            _sr-nd: make object! [
                                id: either _side = 'left [-1] [-2]
                                type: either _side = 'left ['sr-left] ['sr-right]
                                name: to-word _sr/name
                                ports: []  config: []  label: none  x: 0  y: 0
                            ]
                            model/wire-src:        _sr-nd
                            model/wire-port:       to-word _sr/name
                            model/wire-src-struct: _st
                            model/wire-src-sr:     _sr
                            model/mouse-pos:       event/offset
                            face/draw: render-bd model
                            return none
                        ]
                    ]
                ]

                ; 3) Botones de navegación de Case Structure (◀ ▶ [+][-])?
                hit-result: hit-case-nav-buttons model mouse-x mouse-y
                if hit-result [
                    _cst: hit-result/1
                    _act: hit-result/2
                    switch _act [
                        prev [
                            if all [_cst/frames  _cst/active-frame > 0] [
                                _cst/active-frame: _cst/active-frame - 1
                            ]
                        ]
                        next [
                            if all [_cst/frames  _cst/active-frame < ((length? _cst/frames) - 1)] [
                                _cst/active-frame: _cst/active-frame + 1
                            ]
                        ]
                        add [
                            append _cst/frames make-frame compose [
                                id: (length? _cst/frames)
                                label: (form length? _cst/frames)
                            ]
                            _cst/active-frame: (length? _cst/frames) - 1
                        ]
                        remove [
                            if all [_cst/frames  (length? _cst/frames) > 1] [
                                remove at _cst/frames (_cst/active-frame + 1)
                                if _cst/active-frame >= length? _cst/frames [
                                    _cst/active-frame: (length? _cst/frames) - 1
                                ]
                            ]
                        ]
                    ]
                    model/selected-struct: _cst
                    model/selected-node: none
                    model/selected-wire: none
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none
                    face/draw: render-bd model
                    return none
                ]

                ; 3.5) Terminal selector de Case Structure?
                hit-result: hit-case-terminal model mouse-x mouse-y
                if hit-result [
                    _cst: hit-result/1
                    either model/wire-src [
                        ; Completar wire al selector
                        do [
                            _sel-ok: false
                            _out-t: either model/wire-src-sr [model/wire-src-sr/data-type] [
                                either model/wire-src/id = -3 ['number] [
                                    port-out-type model/wire-src model/wire-port
                                ]
                            ]
                            ; Selector acepta number o boolean
                            if find [number boolean] _out-t [_sel-ok: true]
                            either _sel-ok [
                                _cst/selector-wire: make object! [
                                    from: model/wire-src/id
                                    port: model/wire-port
                                ]
                                model/broken-wire: none
                            ][
                                _nav-h: case-nav-height
                                _sel-xy: as-pair (_cst/x + 15) (_cst/y + _nav-h + 11)
                                model/broken-wire: reduce [port-xy model/wire-src model/wire-port 'out  _sel-xy]
                            ]
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none
                        model/wire-src-struct: none  model/wire-src-sr: none
                    ][
                        ; Sin wire activo: seleccionar estructura
                        model/selected-struct: _cst
                        model/selected-node: none
                        model/selected-wire: none
                    ]
                    face/draw: render-bd model
                    return none
                ]

                ; 4) Terminal de estructura (condición/iteración)?
                hit-result: hit-structure-terminal model mouse-x mouse-y
                if hit-result [
                    ; Terminal [i]: si no hay wire activo, iniciar wire desde iteración
                    if all [hit-result/2 = 'iter  none? model/wire-src] [
                        do [
                            _st: hit-result/1
                            iter-nd: make object! [
                                id: -3  type: 'iter  name: _st/name
                                ports: []  config: []  label: none  x: 0  y: 0
                            ]
                            model/wire-src:        iter-nd
                            model/wire-port:       'i
                            model/wire-src-struct: _st
                            model/mouse-pos:       event/offset
                        ]
                        face/draw: render-bd model
                        return none
                    ]

                    ; Si hay wire-src activo + terminal condición → conectar (while-loop)
                    if all [model/wire-src  hit-result/2 = 'cond] [
                        either (port-out-type model/wire-src model/wire-port) = 'boolean [
                            ; Guardar cond-wire en la estructura
                            hit-result/1/cond-wire: make object! [
                                from: model/wire-src/id
                                port: model/wire-port
                            ]
                            model/broken-wire: none
                        ][
                            ; Tipo incompatible: mostrar error
                            model/broken-wire: reduce [
                                port-xy model/wire-src model/wire-port 'out
                                as-pair (hit-result/1/x + hit-result/1/w - 16)
                                        (hit-result/1/y + hit-result/1/h - 16)
                            ]
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                        face/draw: render-bd model
                        return none
                    ]
                    ; Si hay wire-src activo + terminal [N] → conectar (for-loop, externo)
                    if all [model/wire-src  hit-result/2 = 'count] [
                        do [
                            _fst: hit-result/1
                            _htx: to-integer (struct-terminal-size / 2)
                            _ndst: as-pair (to-integer _fst/x + 8 + _htx)
                                           (to-integer _fst/y + 8 + _htx)
                            either (port-out-type model/wire-src model/wire-port) = 'number [
                                ; Eliminar wire previo de N si existía
                                remove-each _w model/wires [
                                    all [_w/to-node = _fst/id  _w/to-port = 'count]
                                ]
                                append model/wires make-wire compose [
                                    from: (model/wire-src/id)  from-port: (model/wire-port)
                                    to: (_fst/id)  to-port: "count"
                                ]
                                model/broken-wire: none
                            ][
                                model/broken-wire: reduce [
                                    port-xy model/wire-src model/wire-port 'out
                                    _ndst
                                ]
                            ]
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                        face/draw: render-bd model
                        return none
                    ]
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                    model/broken-wire: none
                    model/selected-struct: hit-result/1
                    model/selected-node: none
                    model/selected-wire: none
                    face/draw: render-bd model
                    return none
                ]

                ; 4) Handle de resize de estructura?
                hit-result: hit-structure-resize model mouse-x mouse-y
                if hit-result [
                    model/selected-struct: hit-result
                    model/resize-struct: hit-result
                    model/selected-node: none
                    model/selected-wire: none
                    face/draw: render-bd model
                    return none
                ]

                ; 5) Borde de estructura (drag)?
                hit-result: hit-structure-border model mouse-x mouse-y
                if hit-result [
                    model/selected-struct: hit-result
                    model/drag-struct: hit-result
                    model/drag-struct-off: as-pair (mouse-x - hit-result/x) (mouse-y - hit-result/y)
                    model/selected-node: none
                    model/selected-wire: none
                    face/draw: render-bd model
                    return none
                ]

                ; 6) Nodo normal externo? — antes que interior de estructura
                ;    (fix bug #7: nodo arrastrado dentro del while queda accesible)
                hit-ref: hit-node model mouse-x mouse-y
                if hit-ref [
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                    model/wire-src-struct: none
                    model/broken-wire: none
                    model/selected-wire: none
                    model/selected-struct: none
                    model/selected-sr: none
                    model/selected-node: hit-ref
                    model/drag-node: hit-ref
                    model/drag-off: as-pair (mouse-x - hit-ref/x) (mouse-y - hit-ref/y)
                    ; bool-const: clic alterna T/F (igual que LabVIEW)
                    if hit-ref/type = 'bool-const [toggle-bool-const hit-ref]
                    face/draw: render-bd model
                    return none
                ]

                ; 7) Interior de estructura (fondo → seleccionar estructura, paleta interna futura)?
                hit-result: point-in-structure? model mouse-x mouse-y
                if hit-result [
                    model/selected-struct: hit-result
                    model/selected-node: none
                    model/selected-wire: none
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                    model/wire-src-struct: none
                    face/draw: render-bd model
                    return none
                ]

                ; 8) Wire normal?
                hit-ref: hit-wire model mouse-x mouse-y
                if hit-ref [
                    model/selected-wire: hit-ref
                    model/selected-node: none
                    model/selected-struct: none
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                    face/draw: render-bd model
                    return none
                ]

                ; 9) Clic en vacío: cancelar todo
                model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                model/broken-wire: none
                model/drag-node: none  model/selected-wire: none
                model/selected-node: none  model/selected-struct: none
                face/draw: render-bd model
            ]

            on-over: func [face event /local mouse-x mouse-y model dx dy _st _frame _nodes] [
                model: face/extra
                mouse-x: event/offset/x
                mouse-y: event/offset/y

                ; Drag de nodo (normal o interno)
                if all [model/drag-node model/drag-off event/down?] [
                    model/drag-node/x: mouse-x - model/drag-off/x
                    model/drag-node/y: mouse-y - model/drag-off/y
                    ; Clamp nodo interno dentro de la estructura (margen 20px)
                    if model/selected-struct [
                        _st: model/selected-struct
                        ; Case Structure: clamp Considerar nav-height para Y
                        _nav-h: either _st/type = 'case-structure [case-nav-height + 4] [22]
                        model/drag-node/x: max (_st/x + 20)
                                           min (_st/x + _st/w - block-width - 20)
                                               model/drag-node/x
                        model/drag-node/y: max (_st/y + _nav-h)
                                           min (_st/y + _st/h - block-height - 20)
                                               model/drag-node/y
                    ]
                    face/draw: render-bd model
                    return none
                ]

                ; Resize de estructura
                if all [model/resize-struct event/down?] [
                    model/resize-struct/w: max 120 (mouse-x - model/resize-struct/x)
                    model/resize-struct/h: max 80  (mouse-y - model/resize-struct/y)
                    face/draw: render-bd model
                    return none
                ]

                ; Drag de estructura (borde): mover estructura + nodos internos
                if all [model/drag-struct model/drag-struct-off event/down?] [
                    dx: mouse-x - model/drag-struct-off/x - model/drag-struct/x
                    dy: mouse-y - model/drag-struct-off/y - model/drag-struct/y
                    model/drag-struct/x: model/drag-struct/x + dx
                    model/drag-struct/y: model/drag-struct/y + dy
                    ; Mover nodos de todos los frames (case) o nodos internos (while/for)
                    either model/drag-struct/type = 'case-structure [
                        if block? model/drag-struct/frames [
                            foreach _frame model/drag-struct/frames [
                                foreach nd _frame/nodes [
                                    nd/x: nd/x + dx
                                    nd/y: nd/y + dy
                                ]
                                foreach w _frame/wires [
                                    ; Wires internos no necesitan moverse (coords son absolutas en memoria)
                                ]
                            ]
                        ]
                    ][
                        ; While/For Loop
                        foreach nd model/drag-struct/nodes [
                            nd/x: nd/x + dx
                            nd/y: nd/y + dy
                        ]
                    ]
                    face/draw: render-bd model
                    return none
                ]

                if model/wire-src [
                    model/mouse-pos: as-pair mouse-x mouse-y
                    face/draw: render-bd model
                ]
            ]

            on-up: func [face event /local model hit-result] [
                model: face/extra
                ; Completar wire si se suelta sobre un puerto de entrada (drag-to-connect)
                if model/wire-src [
                    hit-result: hit-port model event/offset/x event/offset/y
                    if all [
                        hit-result
                        hit-result/3 = 'in
                        model/wire-src/id <> hit-result/1/id
                    ][
                        ; 3.6 Rutar wire: interno (misma estructura) vs normal
                        do [
                            src-st: any [
                                model/wire-src-struct
                                node-structure model model/wire-src
                            ]
                            dst-st: node-structure model hit-result/1
                            wire-list: either all [src-st  dst-st  same? src-st dst-st] [
                                src-st/wires
                            ] [
                                model/wires
                            ]
                            actual-from-node: model/wire-src/id
                            actual-from-port: model/wire-port
                            if model/wire-src/id = -3 [
                                actual-from-port: to-word rejoin ["_" model/wire-src-struct/name "_i"]
                            ]
                            if model/wire-src-sr [
                                actual-from-port: to-word model/wire-src-sr/name
                                if model/wire-src/id = -2 [
                                    actual-from-node: model/wire-src-struct/id
                                ]
                            ]
                            append wire-list make-wire compose [
                                from: (actual-from-node)
                                from-port: (actual-from-port)
                                to: (hit-result/1/id)
                                to-port: (hit-result/2)
                            ]
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                        face/draw: render-bd model
                    ]
                ]
                model/drag-node: none
                model/drag-off:  none
                model/drag-struct: none
                model/drag-struct-off: none
                model/resize-struct: none
            ]

            on-key: func [face event /local model] [
                model: face/extra
                if any [
                    find [delete backspace] event/key
                    find [#"^(7F)" #"^H"] event/key
                ][
                    canvas-delete-selected face
                ]
            ]

            on-dbl-click: func [face event /local mouse-x mouse-y model node label-text st-hit struct-hit sr-hit] [
                model: face/extra
                mouse-x: event/offset/x
                mouse-y: event/offset/y

                ; 0) Terminal SR: editar valor inicial
                sr-hit: hit-structure-sr model mouse-x mouse-y
                if sr-hit [
                    open-sr-edit-dialog face sr-hit/2
                    exit
                ]

                ; Primero: nodo interno de estructura
                st-hit: hit-structure-node model mouse-x mouse-y
                if st-hit [
                    node: st-hit/2
                    if node/type = 'const [open-const-edit-dialog node face  exit]
                    if find [str-const str-control] node/type [open-str-edit-dialog node face  exit]
                    if find [arr-const arr-control] node/type [open-arr-edit-dialog node face  exit]
                    if find [bundle unbundle] node/type [open-cluster-edit-dialog node face  exit]
                    rename-dialog-node:   node
                    rename-dialog-canvas: face
                    rename-dialog-field:  none
                    label-text: either all [node/label  object? node/label] [node/label/text] [
                        either string? node/label [node/label] [""]
                    ]
                    view/no-wait compose [
                        title "Renombrar nodo"
                        text "Label:" return
                        rename-dialog-field: field 200 (label-text)
                        on-enter [
                            apply-rename-label rename-dialog-node rename-dialog-field/text
                            rename-dialog-canvas/draw: render-bd rename-dialog-canvas/extra
                            unview
                        ]
                        return
                        button "OK" [
                            apply-rename-label rename-dialog-node rename-dialog-field/text
                            rename-dialog-canvas/draw: render-bd rename-dialog-canvas/extra
                            unview
                        ]
                        button "Cancelar" [unview]
                    ]
                    exit
                ]

                ; Nodo existente: doble clic → editar valor o renombrar label
                node: hit-node model mouse-x mouse-y
                if node [
                    if node/type = 'const [
                        open-const-edit-dialog node face
                        exit
                    ]
                    if find [str-const str-control] node/type [
                        open-str-edit-dialog node face
                        exit
                    ]
                    if find [arr-const arr-control] node/type [
                        open-arr-edit-dialog node face
                        exit
                    ]
                    if find [bundle unbundle] node/type [
                        open-cluster-edit-dialog node face
                        exit
                    ]
                    rename-dialog-node:   node
                    rename-dialog-canvas: face
                    rename-dialog-field:  none
                    label-text: either all [node/label  object? node/label] [node/label/text] [
                        either string? node/label [node/label] [""]
                    ]
                    view/no-wait compose [
                        title "Renombrar nodo"
                        text "Label:" return
                        rename-dialog-field: field 200 (label-text)
                        on-enter [
                            apply-rename-label rename-dialog-node rename-dialog-field/text
                            rename-dialog-canvas/draw: render-bd rename-dialog-canvas/extra
                            unview
                        ]
                        return
                        button "OK" [
                            apply-rename-label rename-dialog-node rename-dialog-field/text
                            rename-dialog-canvas/draw: render-bd rename-dialog-canvas/extra
                            unview
                        ]
                        button "Cancelar" [unview]
                    ]
                ]
            ]
            on-alt-down: func [face event /local mouse-x mouse-y model struct-hit] [
                model: face/extra
                mouse-x: event/offset/x
                mouse-y: event/offset/y
                struct-hit: point-in-structure? model mouse-x mouse-y
                either struct-hit [
                    open-palette/struct face mouse-x mouse-y struct-hit
                ][
                    open-palette face mouse-x mouse-y
                ]
            ]
        ]
    ]
    canvas-face/color: col-canvas
    canvas-face/draw: render-bd model
    canvas-face
]

; ══════════════════════════════════════════════════════════
; DEMO STANDALONE — ejecutar: red src/ui/diagram/canvas.red
; Stress test: 20 nodos / 15 wires (Issue #4)
; ══════════════════════════════════════════════════════════

if find form system/options/script "canvas.red" [
    demo-model: make-diagram-model

    num-cols:    4
    col-spacing: 210
    row-spacing: 90
    start-x:     40
    start-y:     20

    repeat i 20 [
        col-idx:   (i - 1) % num-cols
        row-idx:   (i - 1) / num-cols
        node-type: either odd? i ['add] ['sub]
        label-text: either node-type = 'add ["Add"] ["Sub"]
        node-id: gen-node-id demo-model
        append demo-model/nodes make object! [
            id:    node-id
            type:  node-type
            name:  rejoin [form node-type "_" node-id]
            label: make object! [
                text:    label-text
                visible: false
                offset:  0x-15
            ]
            x:     start-x + (col-idx * col-spacing)
            y:     start-y + (row-idx * row-spacing)
        ]
    ]

    repeat i 15 [
        append demo-model/wires make-wire compose [
            from: (demo-model/nodes/:i/id)
            from-port: 'result
            to: (demo-model/nodes/(i + 1)/id)
            to-port: 'a
        ]
    ]

    canvas: render-diagram demo-model 880 490
    canvas/offset: 10x38

    view make face! [
        type:   'window
        text:   "QTorres — Canvas modular (Issue #11)"
        size:   900x540
        offset: 80x60
        pane:   reduce [
            make face! [
                type: 'base  offset: 10x8  size: 880x25  color: 200.203.212
                draw: [pen 60.70.90  text 5x15 "Arrastra | clic wire/nodo = seleccionar | doble clic = renombrar | Delete = borrar"]
            ]
            canvas
        ]
        actors: make object! [
            on-key: func [face event] [
                if any [
                    find [delete backspace] event/key
                    find [#"^(7F)" #"^H"] event/key
                ][
                    canvas-delete-selected canvas
                ]
            ]
        ]
    ]
]

#include %../panel/panel.red
