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
col-wire-sel:   0.160.200
col-port-in:    50.110.200
col-port-out:   195.80.25
col-sel:        0.175.210
col-text:       240.245.250

; Colores de estructuras contenedoras (while-loop)
col-struct-border:     55.80.120    ; borde azulado oscuro
col-struct-bg:         205.210.220  ; fondo ligeramente más oscuro que canvas
col-struct-term-i:     50.100.180   ; terminal iteración (azul como control)
col-struct-term-cond:  20.160.20    ; terminal condición (verde como wire bool)
struct-terminal-size:  14           ; tamaño del cuadrado terminal i y handle resize

; ══════════════════════════════════════════════════════════
; GEOMETRÍA DE NODOS — funciones puras sin side-effects
; ══════════════════════════════════════════════════════════
; Devuelve el color de un tipo de nodo leyendo la categoría del block-registry.
block-color: func [node-type /local cat] [
    cat: block-category to-word node-type
    case [
        cat = 'input  [col-block-ctrl]
        cat = 'output [col-block-ind]
        true          [col-block-op]
    ]
]

; Devuelve los puertos de entrada de un nodo consultando el block-registry.
in-ports: func [node] [ any [block-in-ports to-word node/type  []] ]

; Devuelve los puertos de salida de un nodo consultando el block-registry.
out-ports: func [node] [ any [block-out-ports to-word node/type  []] ]

; Devuelve el tipo de dato de un puerto de salida ('number por defecto).
port-out-type: func [node port-name /local bdef p] [
    bdef: find-block to-word node/type
    if none? bdef [return 'number]
    foreach p bdef/outputs [
        if p/name = to-word port-name [return p/type]
    ]
    'number
]

; Devuelve el tipo de dato de un puerto de entrada ('number por defecto).
port-in-type: func [node port-name /local bdef p] [
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
        true                 [col-wire]
    ]
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
        wire-src-struct: none   ; estructura que contiene el terminal [i] activo
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
            either all [wire-dtype = 'string  not same? wire selected-wire] [
                append cmds compose [pen (wire-color)  line-width 2]
                append cmds draw-dashed-segment out-xy              as-pair mid-x out-xy/y
                append cmds draw-dashed-segment as-pair mid-x out-xy/y  as-pair mid-x in-xy/y
                append cmds draw-dashed-segment as-pair mid-x in-xy/y  in-xy
            ][
                append cmds compose [
                    pen (wire-color)  line-width 2
                    line (out-xy) (as-pair mid-x out-xy/y) (as-pair mid-x in-xy/y) (in-xy)
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

render-structure: func [
    "Genera Draw cmds para una estructura contenedora (while-loop)"
    st model
    /local cmds bx by bx2 by2 tx
][
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

    ; 4) Terminal condición [●] — círculo verde abajo-derecha
    append cmds compose [
        pen (col-struct-border)  line-width 1  fill-pen (col-struct-term-cond)
        circle (as-pair (bx2 - 16) (by2 - 16)) 8
    ]

    ; 5) Handle de resize — cuadrado 8x8 esquina inferior-derecha
    append cmds compose [
        pen col-struct-border  line-width 1  fill-pen (col-struct-border + 40.40.40)
        box (as-pair (bx2 - 10) (by2 - 10)) (as-pair bx2 by2) 0
    ]

    ; 6) Borde de selección cian — solo cuando la estructura en sí está seleccionada
    ;    (no cuando se ha seleccionado un nodo interno)
    if all [same? st model/selected-struct  none? model/selected-node] [
        append cmds compose [
            pen col-sel  line-width 2  fill-pen off
            box (as-pair (bx - 3) (by - 3)) (as-pair (bx2 + 3) (by2 + 3)) 10
            line-width 1
        ]
    ]

    ; 7) Wires desde terminal [i] hacia nodos internos (from-node < 0 = iter virtual)
    do [
        half-tx: to-integer (tx / 2)   ; 14/2 = 7 — precomputado para evitar precedencia
        iter-src: as-pair (to-integer bx + 8 + half-tx) (to-integer by2 - half-tx - 8)
        foreach w st/wires [
            if w/from-node < 0 [
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
        ]
    ]

    ; 8) Wires internos normales (entre nodos reales)
    append cmds render-wire-list st/wires st/nodes model/selected-wire

    ; 9) Nodos internos
    append cmds render-node-list st/nodes model/selected-node

    ; 10) Wire de condición — línea desde el nodo fuente hasta el terminal ●
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

    ; 3) Wire temporal (mientras el usuario elige destino)
    if all [model/wire-src model/mouse-pos] [
        src-port-xy: either model/wire-src-struct [
            ; Origen virtual: terminal [i] — calcular centro del cuadrado
            do [
                _st:  model/wire-src-struct
                _tx:  struct-terminal-size
                _htx: to-integer (_tx / 2)   ; 7 — precomputado para evitar precedencia
                as-pair (to-integer _st/x + 8 + _htx)
                        (to-integer _st/y + _st/h - _htx - 8)
            ]
        ][
            port-xy model/wire-src model/wire-port 'out
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
node-structure: func [model node /local st nd] [
    foreach st model/structures [
        foreach nd st/nodes [
            if nd/id = node/id [return st]
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
hit-structure-node: func [model mouse-x mouse-y /local st node] [
    foreach st model/structures [
        foreach node st/nodes [
            if all [
                mouse-x >= node/x  mouse-x <= (node/x + block-width)
                mouse-y >= node/y  mouse-y <= (node/y + block-height)
            ] [return reduce [st node]]
        ]
    ]
    none
]

; Devuelve [struct 'cond|'iter] si el punto cae sobre un terminal, o none.
; 'iter = terminal iteración [i] abajo-izquierda
; 'cond = terminal condición [●] abajo-derecha
hit-structure-terminal: func [model mouse-x mouse-y /local st bx by2 bx2 tx tol] [
    tol: 8
    foreach st model/structures [
        bx: st/x  by2: st/y + st/h  bx2: st/x + st/w
        tx: struct-terminal-size
        ; Terminal iteración: cuadrado (bx+8, by2-tx-8) → (bx+8+tx, by2-8)
        if all [
            mouse-x >= (bx + 8 - tol)  mouse-x <= (bx + 8 + tx + tol)
            mouse-y >= (by2 - tx - 8 - tol)  mouse-y <= (by2 - 8 + tol)
        ] [return reduce [st 'iter]]
        ; Terminal condición: círculo en (bx2-16, by2-16) radio 8
        if all [
            (absolute (mouse-x - (bx2 - 16))) <= (8 + tol)
            (absolute (mouse-y - (by2 - 16))) <= (8 + tol)
        ] [return reduce [st 'cond]]
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

hit-port: func [model mouse-x mouse-y /local ports out-y center-x center-y in-y node port all-nodes st] [
    ; Reúne todos los nodos: normales + internos de estructuras
    all-nodes: copy model/nodes
    if block? model/structures [
        foreach st model/structures [
            foreach node st/nodes [append all-nodes node]
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

hit-node: func [model mouse-x mouse-y /local found-node node] [
    found-node: none
    foreach node model/nodes [
        if all [
            mouse-x >= node/x  mouse-x <= (node/x + block-width)
            mouse-y >= node/y  mouse-y <= (node/y + block-height)
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

hit-wire: func [model mouse-x mouse-y /local w st] [
    ; Wires normales
    w: hit-wire-in-list model/wires model/nodes mouse-x mouse-y
    if w [return w]
    ; Wires internos de estructuras
    if block? model/structures [
        foreach st model/structures [
            w: hit-wire-in-list st/wires st/nodes mouse-x mouse-y
            if w [return w]
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
        append palette-struct/nodes n
    ][
        append model/nodes n
    ]
    palette-canvas/draw: render-bd model
    show palette-canvas
    unview
]

; Crea una nueva estructura while-loop y la añade al diagrama.
palette-add-structure: func [/local nid st model] [
    model: palette-canvas/extra
    nid: gen-node-id model
    st: make-structure compose [id: (nid) x: (palette-pos-x) y: (palette-pos-y)]
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
        button 80 "Sub -"    [palette-add-node 'sub]    return
        button 80 "Mul *"    [palette-add-node 'mul]
        button 80 "Div /"    [palette-add-node 'div]    return
        text "Constante / salida:"  return
        button 80 "Const"    [palette-add-node 'const]
        button 80 "Display"  [palette-add-node 'display]  return
        text "Lógica:"  return
        button 80 "AND"      [palette-add-node 'and-op]
        button 80 "OR"       [palette-add-node 'or-op]   return
        button 80 "NOT"      [palette-add-node 'not-op]
        button 80 "B-Const"  [palette-add-node 'bool-const]  return
        text "Comparadores:"  return
        button 80 ">"        [palette-add-node 'gt-op]
        button 80 "<"        [palette-add-node 'lt-op]   return
        button 80 "="        [palette-add-node 'eq-op]   return
        text "String:"  return
        button 80 "S-Const"  [palette-add-node 'str-const]
        button 80 "Concat"   [palette-add-node 'concat]         return
        button 80 "Len"      [palette-add-node 'str-length]
        button 80 "→STR"     [palette-add-node 'to-string]      return
        text "Estructuras:"  return
        button 80 "While"    [palette-add-structure]             return
        button "Cancelar"    [unview]
    ]
]

; Borra el elemento seleccionado (nodo, wire o estructura completa).
; Llamar desde el on-key del window padre con: canvas-delete-selected canvas
canvas-delete-selected: func [canvas /local model node-id node-name node-type st found _pref] [
    model: canvas/extra
    ; Wire seleccionado: buscar en model/wires y en wires internos
    if model/selected-wire [
        found: find model/wires model/selected-wire
        if found [remove found]
        if block? model/structures [
            foreach st model/structures [
                found: find st/wires model/selected-wire
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
            remove-each wire st/wires [any [wire/from-node = node-id  wire/to-node = node-id]]
            remove-each nd st/nodes   [nd/id = node-id]
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
                        either all [
                            hit-dir = 'in
                            model/wire-src/id <> hit-nd/id
                            (port-out-type model/wire-src model/wire-port) = (port-in-type hit-nd hit-port-name)
                        ][
                            model/broken-wire: none
                            ; 3.6 Rutar wire: interno (misma estructura) vs normal
                            ; wire-src-struct se usa para nodos virtuales ([i] terminal)
                            do [
                                src-st: any [
                                    model/wire-src-struct
                                    node-structure model model/wire-src
                                ]
                                dst-st: node-structure model hit-nd
                                wire-list: either all [src-st  dst-st  same? src-st dst-st] [
                                    src-st/wires
                                ] [
                                    model/wires
                                ]
                                ; Para terminal [i] (from-node < 0): from-port = nombre var iter
                                actual-from-port: either model/wire-src/id < 0 [
                                    to-word rejoin ["_" model/wire-src-struct/name "_i"]
                                ][
                                    model/wire-port
                                ]
                                append wire-list make-wire compose [
                                    from: (model/wire-src/id)
                                    from-port: (actual-from-port)
                                    to: (hit-nd/id)
                                    to-port: (hit-port-name)
                                ]
                            ]
                        ][
                            ; Tipos incompatibles: mostrar wire roto en rojo
                            if all [hit-dir = 'in  model/wire-src/id <> hit-nd/id] [
                                model/broken-wire: reduce [
                                    port-xy model/wire-src model/wire-port 'out
                                    port-xy hit-nd hit-port-name 'in
                                ]
                            ]
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none
                        face/draw: render-bd model
                    ]
                    return none
                ]

                ; 2) Nodo interno de estructura? (antes que borde/nodo normal)
                hit-result: hit-structure-node model mouse-x mouse-y
                if hit-result [
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none
                    model/broken-wire: none
                    model/selected-wire: none
                    model/selected-struct: hit-result/1
                    model/selected-node: hit-result/2
                    model/drag-node: hit-result/2
                    model/drag-off: as-pair (mouse-x - hit-result/2/x) (mouse-y - hit-result/2/y)
                    if hit-result/2/type = 'bool-const [toggle-bool-const hit-result/2]
                    face/draw: render-bd model
                    return none
                ]

                ; 3) Terminal de estructura (condición/iteración)?
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

                    ; Si hay wire-src activo + terminal condición → conectar
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
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none
                        face/draw: render-bd model
                        return none
                    ]
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none
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
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none
                    model/wire-src-struct: none
                    model/broken-wire: none
                    model/selected-wire: none
                    model/selected-struct: none
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
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none
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
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none
                    face/draw: render-bd model
                    return none
                ]

                ; 9) Clic en vacío: cancelar todo
                model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none
                model/broken-wire: none
                model/drag-node: none  model/selected-wire: none
                model/selected-node: none  model/selected-struct: none
                face/draw: render-bd model
            ]

            on-over: func [face event /local mouse-x mouse-y model dx dy] [
                model: face/extra
                mouse-x: event/offset/x
                mouse-y: event/offset/y

                ; Drag de nodo (normal o interno)
                if all [model/drag-node model/drag-off event/down?] [
                    model/drag-node/x: mouse-x - model/drag-off/x
                    model/drag-node/y: mouse-y - model/drag-off/y
                    ; 3.2 Clamp nodo interno dentro de la estructura (margen 20px)
                    if model/selected-struct [
                        model/drag-node/x: max (model/selected-struct/x + 20)
                                           min (model/selected-struct/x + model/selected-struct/w - block-width - 20)
                                               model/drag-node/x
                        model/drag-node/y: max (model/selected-struct/y + 22)
                                           min (model/selected-struct/y + model/selected-struct/h - block-height - 20)
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
                    foreach nd model/drag-struct/nodes [
                        nd/x: nd/x + dx
                        nd/y: nd/y + dy
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
                            actual-from-port: either model/wire-src/id < 0 [
                                to-word rejoin ["_" model/wire-src-struct/name "_i"]
                            ][
                                model/wire-port
                            ]
                            append wire-list make-wire compose [
                                from: (model/wire-src/id)
                                from-port: (actual-from-port)
                                to: (hit-result/1/id)
                                to-port: (hit-result/2)
                            ]
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none
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

            on-dbl-click: func [face event /local mouse-x mouse-y model node label-text st-hit struct-hit] [
                model: face/extra
                mouse-x: event/offset/x
                mouse-y: event/offset/y

                ; Primero: nodo interno de estructura
                st-hit: hit-structure-node model mouse-x mouse-y
                if st-hit [
                    node: st-hit/2
                    if node/type = 'const [open-const-edit-dialog node face  exit]
                    if find [str-const str-control] node/type [open-str-edit-dialog node face  exit]
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

                ; Segundo: interior de estructura (fondo) → paleta interna
                struct-hit: point-in-structure? model mouse-x mouse-y
                if struct-hit [
                    open-palette/struct face mouse-x mouse-y struct-hit
                    exit
                ]

                node: hit-node model mouse-x mouse-y
                either node [
                    ; Nodo existente: const/str-const/str-control → editar valor; resto → renombrar label
                    if node/type = 'const [
                        open-const-edit-dialog node face
                        exit
                    ]
                    if find [str-const str-control] node/type [
                        open-str-edit-dialog node face
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
                ][
                    ; Espacio vacío → paleta para añadir nuevo bloque
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
