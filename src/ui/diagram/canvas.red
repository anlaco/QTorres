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
col-wire-sel:   0.160.200
col-port-in:    50.110.200
col-port-out:   195.80.25
col-sel:        0.175.210
col-text:       240.245.250

; ══════════════════════════════════════════════════════════
; GEOMETRÍA DE NODOS — funciones puras sin side-effects
; ══════════════════════════════════════════════════════════
ncolor: func [node-type] [
    switch node-type [
        control   [col-block-ctrl]
        indicator [col-block-ind]
        add       [col-block-op]
        sub       [col-block-op]
        mul       [col-block-op]
        div       [col-block-op]
        display   [col-block-op]
        subvi     [col-block-op]
        default   [col-block-op]
    ]
]

in-ports: func [node] [
    switch node/type [
        control   [[]]
        indicator [[value]]
        add       [[a b]]
        sub       [[a b]]
        mul       [[a b]]
        div       [[a b]]
        display   [[value]]
        subvi     [[in1 in2]]
        default   [[]]
    ]
]

out-ports: func [node] [
    switch node/type [
        control   [[result]]
        indicator [[]]
        add       [[result]]
        sub       [[result]]
        mul       [[result]]
        div       [[result]]
        display   [[]]
        subvi     [[out]]
        default   [[]]
    ]
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
        nodes:         copy []
        wires:         copy []
        front-panel:   copy []
        next-id:       1
        selected-node: none
        selected-wire: none
        selected-fp:   none
        drag-node:     none
        drag-fp:       none
        drag-off:      none
        wire-src:      none
        wire-port:     none
        mouse-pos:     none
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

render-bd: func [model /local cmds src-node dst-node out-xy in-xy mid-x wire-color block-color type-label ports in-port-y out-port-y node wire src-port-xy] [
    cmds: copy []

    ; 0) Grid de fondo
    append cmds render-grid 880 490

    ; 1) Wires permanentes (ortogonales con punto medio estilo LabVIEW)
    foreach wire model/wires [
        src-node: none  dst-node: none
        foreach node model/nodes [
            if node/id = wire/from-node [src-node: node]
            if node/id = wire/to-node   [dst-node: node]
        ]
        if all [src-node dst-node] [
            out-xy: port-xy src-node wire/from-port 'out
            in-xy:  port-xy dst-node wire/to-port   'in
            mid-x:  to-integer (out-xy/x + in-xy/x) / 2
            wire-color: either same? wire model/selected-wire [col-wire-sel] [col-wire]
            append cmds compose [
                pen (wire-color)  line-width 2
                line (out-xy) (as-pair mid-x out-xy/y) (as-pair mid-x in-xy/y) (in-xy)
            ]
        ]
    ]

    ; 2) Wire temporal (mientras el usuario elige destino)
    if all [model/wire-src model/mouse-pos] [
        src-port-xy: port-xy model/wire-src model/wire-port 'out
        append cmds compose [
            pen col-wire  line-width 2
            line (src-port-xy) (model/mouse-pos)
        ]
    ]

    ; 3) Nodos con puertos
    foreach node model/nodes [
        block-color: ncolor node/type
        ; Cuerpo del bloque
        append cmds compose [
            pen (block-color - 20.20.20)  line-width 1  fill-pen (block-color)
            box (as-pair node/x node/y) (as-pair (node/x + block-width) (node/y + block-height)) 5
        ]
        ; Banda izquierda de categoría
        append cmds compose [
            pen off  fill-pen (block-color + 30.30.30)
            box (as-pair node/x node/y) (as-pair (node/x + 4) (node/y + block-height)) 0
        ]
        ; Texto: tipo + label (DT-022)
        type-label: switch node/type [
            control   ["CTRL"]
            indicator ["IND"]
            add       ["ADD +"]
            sub       ["SUB -"]
            mul       ["MUL *"]
            div       ["DIV /"]
            display   ["DISP"]
            subvi     ["SUBVI"]
            default   [uppercase form node/type]
        ]
        either all [node/label  object? node/label  node/label/visible] [
            append cmds compose [
                fill-pen col-text
                text (as-pair (node/x + 10) (node/y + 10)) (node/label/text)
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

        ; Puertos de entrada (izquierda)
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

        ; Puertos de salida (derecha)
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

        ; Borde de selección (cian)
        if same? node model/selected-node [
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
; HIT-TEST — funciones puras, reciben modelo y coordenadas
; ══════════════════════════════════════════════════════════
hit-port: func [model mouse-x mouse-y /local ports out-y center-x center-y in-y node port] [
    foreach node model/nodes [
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

hit-wire: func [model mouse-x mouse-y /local tolerance src-node dst-node out-xy in-xy mid-x wire node] [
    tolerance: 8
    foreach wire model/wires [
        src-node: none  dst-node: none
        foreach node model/nodes [
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

; ══════════════════════════════════════════════════════════
; CANVAS FACTORY — render-diagram devuelve una face funcional
;   El modelo se almacena en face/extra para que los actores
;   puedan acceder sin depender de variables globales.
; ══════════════════════════════════════════════════════════

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

; ── Paleta de bloques ────────────────────────────────────────────
; vars de módulo para el diálogo de paleta (mismo patrón que rename)
palette-canvas: none
palette-pos-x:  0
palette-pos-y:  0

palette-add-node: func [node-type /local n nid] [
    nid: gen-node-id palette-canvas/extra
    n: make-node compose [id: (nid) type: (node-type) x: (palette-pos-x) y: (palette-pos-y)]
    append palette-canvas/extra/nodes n
    palette-canvas/draw: render-bd palette-canvas/extra
    show palette-canvas
    unview
]

open-palette: func [face x y] [
    palette-canvas: face
    palette-pos-x:  x
    palette-pos-y:  y
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
        button "Cancelar"    [unview]
    ]
]

; Borra el elemento seleccionado (nodo o wire).
; Llamar desde el on-key del window padre con: canvas-delete-selected canvas
canvas-delete-selected: func [canvas /local model node-id] [
    model: canvas/extra
    case [
        model/selected-wire [
            if found: find model/wires model/selected-wire [
                remove found
            ]
            model/selected-wire: none
            canvas/draw: render-bd model
        ]
        model/selected-node [
            node-id:   model/selected-node/id
            node-name: model/selected-node/name
            node-type: model/selected-node/type
            remove-each wire model/wires [any [wire/from-node = node-id  wire/to-node = node-id]]
            remove-each node model/nodes  [node/id = node-id]
            model/selected-node: none
            model/drag-node:     none
            ; Sync FP: borrar item correspondiente si es control/indicator
            if all [
                find [control indicator] node-type
                _pref: select model 'panel-ref
            ][
                remove-each item model/front-panel [item/name = node-name]
                _pref/draw: render-fp-panel model model/size/x model/size/y
                show _pref
            ]
            canvas/draw: render-bd model
        ]
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

                ; 1) Puerto?
                hit-result: hit-port model mouse-x mouse-y
                if hit-result [
                    hit-nd:        hit-result/1
                    hit-port-name: hit-result/2
                    hit-dir:       hit-result/3
                    either model/wire-src = none [
                        if hit-dir = 'out [
                            model/wire-src:  hit-nd
                            model/wire-port: hit-port-name
                            model/mouse-pos: event/offset
                            face/draw: render-bd model
                        ]
                    ][
                        if all [hit-dir = 'in  model/wire-src/id <> hit-nd/id] [
                            append model/wires make object! [
                                from-node:  model/wire-src/id
                                from-port:  model/wire-port
                                to-node:    hit-nd/id
                                to-port:    hit-port-name
                            ]
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none
                        face/draw: render-bd model
                    ]
                    return none
                ]

                ; 2) Nodo? (seleccionar + drag)
                hit-ref: hit-node model mouse-x mouse-y
                if hit-ref [
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none
                    model/selected-wire: none
                    model/selected-node: hit-ref
                    model/drag-node: hit-ref
                    model/drag-off: as-pair (mouse-x - hit-ref/x) (mouse-y - hit-ref/y)
                    face/draw: render-bd model
                    return none
                ]

                ; 3) Wire?
                hit-ref: hit-wire model mouse-x mouse-y
                if hit-ref [
                    model/selected-wire: hit-ref
                    model/selected-node: none
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none
                    face/draw: render-bd model
                    return none
                ]

                ; 4) Clic en vacío: cancelar todo
                model/wire-src: none  model/wire-port: none  model/mouse-pos: none
                model/drag-node: none  model/selected-wire: none  model/selected-node: none
                face/draw: render-bd model
            ]

            on-over: func [face event /local mouse-x mouse-y model] [
                model: face/extra
                mouse-x: event/offset/x
                mouse-y: event/offset/y
                if all [model/drag-node model/drag-off event/down?] [
                    model/drag-node/x: mouse-x - model/drag-off/x
                    model/drag-node/y: mouse-y - model/drag-off/y
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
                        append model/wires make object! [
                            from-node:  model/wire-src/id
                            from-port:  model/wire-port
                            to-node:    hit-result/1/id
                            to-port:    hit-result/2
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none
                        face/draw: render-bd model
                    ]
                ]
                model/drag-node: none
                model/drag-off:  none
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

            on-dbl-click: func [face event /local mouse-x mouse-y model node label-text] [
                model: face/extra
                mouse-x: event/offset/x
                mouse-y: event/offset/y
                node: hit-node model mouse-x mouse-y
                either node [
                    ; Nodo existente → diálogo de renombrado
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
    append demo-model/wires make object! [
        from-node:  demo-model/nodes/:i/id
        from-port:  'result
        to-node:    demo-model/nodes/(i + 1)/id
        to-port:    'a
    ]
]

if find form system/options/script "canvas.red" [
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
