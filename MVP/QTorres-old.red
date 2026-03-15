Red [
    Title:   "QTorres MVP"
    Author:  "QTorres contributors"
    Version: 0.1.0
    Purpose: "MVP: editor visual → .qvi ejecutable"
    Needs:   'View
]

; ══════════════════════════════════════════════════
; Estado global del modelo
; ══════════════════════════════════════════════════

next-id: 1

; Front Panel items: cada uno es object! con id, kind ('control | 'indicator), label, x, y, default
fp-items: copy []

; Block Diagram nodes: id, type ('control | 'indicator | 'add | 'sub), label, x, y, ports
bd-nodes: copy []

; Wires: cada uno es object! con from-node, from-port, to-node, to-port
bd-wires: copy []

; Estado de wiring interactivo
wire-start: none        ; object! del nodo origen o none
wire-start-port: none   ; 'out, 'a, 'b, 'result, 'in ...
wire-mouse: none        ; posición actual del ratón durante wiring

; Dragging state — separado por ventana
fp-dragging: none
fp-drag-offset: none
bd-dragging: none
bd-drag-offset: none

; Referencia a las faces (se asignan al abrir)
fp-canvas-face: none
bd-canvas-face: none
fp-win: none
bd-win: none

; ══════════════════════════════════════════════════
; Helpers
; ══════════════════════════════════════════════════

gen-id: does [
    n: next-id
    next-id: next-id + 1
    n
]

; Tamaño de bloques
node-w: 120
node-h: 50
port-r: 8

; Encontrar nodo bajo un punto en el diagrama
find-node-at: func [nodes [block!] px [integer!] py [integer!]] [
    result: none
    foreach n nodes [
        if all [
            px >= n/x
            px <= (n/x + node-w)
            py >= n/y
            py <= (n/y + node-h)
        ] [
            result: n
        ]
    ]
    result
]

; Encontrar puerto bajo un punto. Devuelve [nodo puerto-nombre] o none.
; Solo detecta clics FUERA del cuerpo del nodo (en los círculos de puerto).
find-port-at: func [nodes [block!] px [integer!] py [integer!]] [
    foreach n nodes [
        ; Puertos de entrada (lado izquierdo) — solo si px < borde izquierdo del nodo
        if px <= (n/x + 4) [
            ports-in: get-in-ports n
            iy: n/y + 15
            foreach p ports-in [
                cx: n/x - port-r
                cy: iy
                if all [
                    (absolute (px - cx)) <= (port-r + 8)
                    (absolute (py - cy)) <= (port-r + 8)
                ] [
                    return reduce [n p]
                ]
                iy: iy + 18
            ]
        ]
        ; Puertos de salida (lado derecho) — solo si px > borde derecho del nodo
        if px >= (n/x + node-w - 4) [
            ports-out: get-out-ports n
            oy: n/y + 15
            foreach p ports-out [
                cx: n/x + node-w + port-r
                cy: oy
                if all [
                    (absolute (px - cx)) <= (port-r + 8)
                    (absolute (py - cy)) <= (port-r + 8)
                ] [
                    return reduce [n p]
                ]
                oy: oy + 18
            ]
        ]
    ]
    none
]

; Puertos de entrada de un nodo según su tipo
get-in-ports: func [n [object!]] [
    switch n/type [
        control   [ copy [] ]
        indicator [ copy [in] ]
        add       [ copy [a b] ]
        sub       [ copy [a b] ]
    ]
]

; Puertos de salida de un nodo según su tipo
get-out-ports: func [n [object!]] [
    switch n/type [
        control   [ copy [out] ]
        indicator [ copy [] ]
        add       [ copy [result] ]
        sub       [ copy [result] ]
    ]
]

; Posición de un puerto para dibujar wires
port-pos: func [n [object!] port-name [word!] direction [word!]] [
    either direction = 'in [
        ports: get-in-ports n
        idx: index? find ports port-name
        as-pair (n/x - port-r) (n/y + 15 + ((idx - 1) * 18))
    ] [
        ports: get-out-ports n
        idx: index? find ports port-name
        as-pair (n/x + node-w + port-r) (n/y + 15 + ((idx - 1) * 18))
    ]
]

; Color del nodo según tipo
node-color: func [type [word!]] [
    switch type [
        control   [sky]
        indicator [yello]
        add       [leaf]
        sub       [255.127.80]
    ]
]

; ══════════════════════════════════════════════════
; Sincronización Front Panel → Block Diagram
; ══════════════════════════════════════════════════

; Cuando se añade un control/indicador al Front Panel,
; se crea automáticamente un nodo en el Block Diagram.

sync-fp-to-bd: func [item [object!]] [
    ; Buscar si ya existe un nodo BD con el mismo id
    exists: false
    foreach n bd-nodes [
        if n/id = item/id [exists: true]
    ]
    if not exists [
        append bd-nodes make object! [
            id:    item/id
            type:  item/kind
            label: item/label
            x:     50
            y:     30 + ((length? bd-nodes) * 70)
        ]
    ]
]

; ══════════════════════════════════════════════════
; Renderizado del Front Panel canvas (Draw)
; ══════════════════════════════════════════════════

render-fp: func [] [
    cmds: copy [pen black]
    foreach item fp-items [
        clr: either item/kind = 'control [sky] [yello]
        append cmds compose [
            fill-pen (clr)
            box (as-pair item/x item/y) (as-pair (item/x + 140) (item/y + 40)) 5
            fill-pen black
            text (as-pair (item/x + 5) (item/y + 5)) (item/label)
            text (as-pair (item/x + 5) (item/y + 22)) (either item/kind = 'control [
                rejoin ["Val: " item/default]
            ] [
                "---"
            ])
        ]
    ]
    cmds
]

; ══════════════════════════════════════════════════
; Renderizado del Block Diagram canvas (Draw)
; ══════════════════════════════════════════════════

render-bd: func [] [
    cmds: copy [pen black line-width 1]

    ; Dibujar wires
    foreach w bd-wires [
        ; encontrar nodos
        fn: none  tn: none
        foreach n bd-nodes [
            if n/id = w/from-node [fn: n]
            if n/id = w/to-node  [tn: n]
        ]
        if all [fn tn] [
            p1: port-pos fn w/from-port 'out
            p2: port-pos tn w/to-port 'in
            ; Dibujo rectilinear
            mx: to-integer ((p1/x + p2/x) / 2)
            append cmds compose [
                pen gray line-width 2
                line (p1) (as-pair mx p1/y) (as-pair mx p2/y) (p2)
            ]
        ]
    ]

    ; Wire en progreso
    if all [wire-start wire-mouse] [
        sp: port-pos wire-start wire-start-port 'out
        append cmds compose [
            pen orange line-width 2
            line (sp) (wire-mouse)
        ]
    ]

    ; Dibujar nodos
    foreach n bd-nodes [
        clr: node-color n/type
        append cmds compose [
            line-width 1
            pen black
            fill-pen (clr)
            box (as-pair n/x n/y) (as-pair (n/x + node-w) (n/y + node-h)) 4
            fill-pen black
            text (as-pair (n/x + 8) (n/y + 4)) (n/label)
        ]
        ; Label de tipo (pequeño)
        type-label: switch n/type [
            control   ["CTRL"]
            indicator ["IND"]
            add       ["ADD +"]
            sub       ["SUB −"]
        ]
        append cmds compose [
            text (as-pair (n/x + 8) (n/y + 22)) (type-label)
        ]

        ; Puertos de entrada
        ports-in: get-in-ports n
        iy: n/y + 15
        foreach p ports-in [
            append cmds compose [
                pen black
                fill-pen 70.130.230
                circle (as-pair (n/x - port-r) iy) (port-r)
                fill-pen black
                text (as-pair (n/x - port-r - 22) (iy - 7)) (form p)
            ]
            iy: iy + 18
        ]

        ; Puertos de salida
        ports-out: get-out-ports n
        oy: n/y + 15
        foreach p ports-out [
            append cmds compose [
                pen black
                fill-pen 230.70.70
                circle (as-pair (n/x + node-w + port-r) oy) (port-r)
                fill-pen black
                text (as-pair (n/x + node-w + port-r + 10) (oy - 7)) (form p)
            ]
            oy: oy + 18
        ]
    ]

    cmds
]

; ══════════════════════════════════════════════════
; Front Panel: ventana
; ══════════════════════════════════════════════════

open-front-panel: does [
    if fp-win [
        ; ya abierta, traer al frente
        show fp-win
        exit
    ]

    fp-canvas-face: make face! [
        type: 'base
        size: 600x500
        color: white
        flags: [all-over]
        draw: render-fp
        actors: make object! [
            on-down: func [face event] [
                ; Click sobre item → empezar drag
                px: event/offset/x  py: event/offset/y
                foreach item fp-items [
                    if all [
                        px >= item/x  px <= (item/x + 140)
                        py >= item/y  py <= (item/y + 40)
                    ] [
                        fp-dragging: item
                        fp-drag-offset: as-pair (px - item/x) (py - item/y)
                        return true
                    ]
                ]
                fp-dragging: none
            ]
            on-over: func [face event] [
                if all [fp-dragging fp-drag-offset event/down?] [
                    fp-dragging/x: event/offset/x - fp-drag-offset/x
                    fp-dragging/y: event/offset/y - fp-drag-offset/y
                    face/draw: render-fp
                ]
            ]
            on-up: func [face event] [
                fp-dragging: none
                fp-drag-offset: none
            ]
        ]
    ]

    fp-win: make face! [
        type: 'window
        text: "QTorres — Front Panel"
        size: 760x520
        offset: 50x50
        pane: reduce [
            ; Paleta
            make face! [
                type: 'group-box
                text: "Paleta"
                offset: 5x5
                size: 145x120
                pane: reduce [
                    make face! [
                        type: 'button
                        text: "Control Num."
                        offset: 10x20
                        size: 120x35
                        actors: make object! [
                            on-click: func [face event] [
                                new-id: gen-id
                                item: make object! [
                                    id: new-id
                                    kind: 'control
                                    label: rejoin ["Ctrl_" new-id]
                                    x: 20
                                    y: 20 + ((length? fp-items) * 55)
                                    default: 0.0
                                ]
                                append fp-items item
                                sync-fp-to-bd item
                                fp-canvas-face/draw: render-fp
                                bd-canvas-face/draw: render-bd
                            ]
                        ]
                    ]
                    make face! [
                        type: 'button
                        text: "Indicador Num."
                        offset: 10x60
                        size: 120x35
                        actors: make object! [
                            on-click: func [face event] [
                                new-id: gen-id
                                item: make object! [
                                    id: new-id
                                    kind: 'indicator
                                    label: rejoin ["Ind_" new-id]
                                    x: 20
                                    y: 20 + ((length? fp-items) * 55)
                                    default: 0.0
                                ]
                                append fp-items item
                                sync-fp-to-bd item
                                fp-canvas-face/draw: render-fp
                                bd-canvas-face/draw: render-bd
                            ]
                        ]
                    ]
                ]
            ]
            ; Canvas
            make face! [
                type: 'text
                text: "Arrastra controles/indicadores desde la paleta"
                offset: 155x5
                size: 600x15
            ]
            fp-canvas-face
        ]
    ]

    fp-canvas-face/offset: 155x22
    fp-canvas-face/size: 600x490

    view/no-wait fp-win
]

; ══════════════════════════════════════════════════
; Block Diagram: ventana
; ══════════════════════════════════════════════════

open-block-diagram: does [
    if bd-win [
        show bd-win
        exit
    ]

    bd-canvas-face: make face! [
        type: 'base
        size: 700x500
        color: 250.250.245
        flags: [all-over]
        draw: render-bd
        actors: make object! [
            on-down: func [face event] [
                px: event/offset/x  py: event/offset/y

                ; 1. ¿Clic en puerto? → iniciar/completar wire
                hit: find-port-at bd-nodes px py
                if hit [
                    n: hit/1
                    p: hit/2

                    either wire-start = none [
                        ; Solo podemos iniciar desde puertos de salida
                        out-ports: get-out-ports n
                        if find out-ports p [
                            wire-start: n
                            wire-start-port: p
                            face/draw: render-bd
                        ]
                    ] [
                        ; Completar wire: destino debe ser puerto de entrada
                        in-ports: get-in-ports n
                        if all [
                            find in-ports p
                            wire-start/id <> n/id
                        ] [
                            append bd-wires make object! [
                                from-node: wire-start/id
                                from-port: wire-start-port
                                to-node:   n/id
                                to-port:   p
                            ]
                        ]
                        wire-start: none
                        wire-start-port: none
                        wire-mouse: none
                        face/draw: render-bd
                    ]
                    return true
                ]

                ; 2. ¿Clic en nodo? → iniciar drag
                n: find-node-at bd-nodes px py
                if n [
                    ; cancelar wire si estabamos en modo wire
                    wire-start: none
                    wire-start-port: none
                    wire-mouse: none
                    bd-dragging: n
                    bd-drag-offset: as-pair (px - n/x) (py - n/y)
                    return true
                ]

                ; 3. Clic en vacío → cancelar wire
                wire-start: none
                wire-start-port: none
                wire-mouse: none
                bd-dragging: none
                face/draw: render-bd
            ]
            on-over: func [face event] [
                px: event/offset/x  py: event/offset/y
                ; Drag de nodo
                if all [bd-dragging bd-drag-offset event/down?] [
                    bd-dragging/x: px - bd-drag-offset/x
                    bd-dragging/y: py - bd-drag-offset/y
                    face/draw: render-bd
                    return true
                ]
                ; Wire en progreso
                if wire-start [
                    wire-mouse: as-pair px py
                    face/draw: render-bd
                ]
            ]
            on-up: func [face event] [
                bd-dragging: none
                bd-drag-offset: none
            ]
        ]
    ]

    bd-win: make face! [
        type: 'window
        text: "QTorres — Block Diagram"
        size: 880x520
        offset: 200x100
        pane: reduce [
            ; Paleta de bloques
            make face! [
                type: 'group-box
                text: "Bloques"
                offset: 5x5
                size: 145x120
                pane: reduce [
                    make face! [
                        type: 'button
                        text: "Suma (+)"
                        offset: 10x20
                        size: 120x35
                        actors: make object! [
                            on-click: func [face event] [
                                new-id: gen-id
                                append bd-nodes make object! [
                                    id: new-id
                                    type: 'add
                                    label: rejoin ["Add_" new-id]
                                    x: 200 + (random 150)
                                    y: 50 + (random 300)
                                ]
                                bd-canvas-face/draw: render-bd
                            ]
                        ]
                    ]
                    make face! [
                        type: 'button
                        text: "Resta (−)"
                        offset: 10x60
                        size: 120x35
                        actors: make object! [
                            on-click: func [face event] [
                                new-id: gen-id
                                append bd-nodes make object! [
                                    id: new-id
                                    type: 'sub
                                    label: rejoin ["Sub_" new-id]
                                    x: 200 + (random 150)
                                    y: 50 + (random 300)
                                ]
                                bd-canvas-face/draw: render-bd
                            ]
                        ]
                    ]
                ]
            ]
            ; Instrucciones
            make face! [
                type: 'text
                text: "Clic en puerto (rojo=salida) → clic en puerto (azul=entrada) para conectar"
                offset: 155x5
                size: 700x15
            ]
            bd-canvas-face
        ]
    ]

    bd-canvas-face/offset: 155x22
    bd-canvas-face/size: 700x490

    view/no-wait bd-win
]

; ══════════════════════════════════════════════════
; Compilador MVP: modelo → código .qvi
; ══════════════════════════════════════════════════

compile-to-qvi: func [filename [file!]] [
    ; 1. Construir cabecera qvi-diagram
    fp-block: copy []
    foreach item fp-items [
        either item/kind = 'control [
            append fp-block compose/deep [
                control [id: (item/id) type: 'numeric label: (item/label) default: (item/default)]
            ]
        ] [
            append fp-block compose/deep [
                indicator [id: (item/id) type: 'numeric label: (item/label)]
            ]
        ]
    ]

    nd-block: copy []
    foreach n bd-nodes [
        append nd-block compose/deep [
            node [id: (n/id) type: (to-lit-word form n/type) x: (n/x) y: (n/y) label: (n/label)]
        ]
    ]

    wr-block: copy []
    foreach w bd-wires [
        append wr-block compose/deep [
            wire [from: (w/from-node) port: (to-lit-word form w/from-port) to: (w/to-node) port: (to-lit-word form w/to-port)]
        ]
    ]

    diagram-block: compose/deep [
        front-panel: [(fp-block)]
        block-diagram: [
            nodes: [(nd-block)]
            wires: [(wr-block)]
        ]
    ]

    ; 2. Compilar código ejecutable
    code-lines: copy []

    ; Asignar defaults de controles
    foreach item fp-items [
        if item/kind = 'control [
            append code-lines rejoin [item/label ": " item/default newline]
        ]
    ]

    ; Ordenamiento topológico simple
    ; Nodos que no son control ni indicator
    op-nodes: copy []
    foreach n bd-nodes [
        if any [n/type = 'add  n/type = 'sub] [
            append op-nodes n
        ]
    ]

    ; Para cada nodo operación, resolver inputs y generar código
    foreach n op-nodes [
        ; Buscar wires de entrada a este nodo
        input-a: "0.0"
        input-b: "0.0"
        foreach w bd-wires [
            if w/to-node = n/id [
                ; Buscar label del nodo fuente
                foreach src bd-nodes [
                    if src/id = w/from-node [
                        either w/to-port = 'a [
                            input-a: src/label
                        ] [
                            input-b: src/label
                        ]
                    ]
                ]
            ]
        ]
        op: either n/type = 'add [" + "] [" - "]
        append code-lines rejoin [n/label ": " input-a op input-b newline]
    ]

    ; Asignar resultados a indicadores
    foreach item fp-items [
        if item/kind = 'indicator [
            ; Buscar wire que llega a este indicador
            foreach w bd-wires [
                if w/to-node = item/id [
                    foreach src bd-nodes [
                        if src/id = w/from-node [
                            append code-lines rejoin [item/label ": " src/label newline]
                        ]
                    ]
                ]
            ]
        ]
    ]

    ; Print de indicadores
    foreach item fp-items [
        if item/kind = 'indicator [
            append code-lines rejoin ["print " item/label newline]
        ]
    ]

    ; 3. Escribir fichero
    out: copy {Red [title: "QTorres VI"]^/^/}
    append out "; ── CABECERA GRÁFICA ─────────────────────────────^/"
    append out "; QTorres lee esta sección para reconstruir la vista.^/"
    append out "; Para Red es solo una asignación sin efectos.^/^/"
    append out "qvi-diagram: "
    append out mold diagram-block
    append out "^/^/"
    append out "; ── CÓDIGO GENERADO ──────────────────────────────^/"
    append out "; Generado por QTorres al guardar. Ejecutable con Red directamente.^/^/"
    foreach line code-lines [
        append out line
    ]

    write filename out
    filename
]

; ══════════════════════════════════════════════════
; Ventana principal
; ══════════════════════════════════════════════════

view [
    title "QTorres MVP v0.1"
    backdrop 240.240.240

    text 300x30 font-size 14 "QTorres — Programación Visual" font-color navy
    return

    text 300x20 font-size 9 "Entorno visual tipo LabVIEW sobre Red-Lang"
    return
    pad 0x10

    button "Generar .qvi" 150x40 [
        ; Reset del modelo
        next-id: 1
        clear fp-items
        clear bd-nodes
        clear bd-wires
        wire-start: none
        wire-start-port: none
        wire-mouse: none
        dragging: none
        drag-offset: none

        ; Cerrar ventanas anteriores si existen
        if fp-win [
            unview/only fp-win
            fp-win: none
        ]
        if bd-win [
            unview/only bd-win
            bd-win: none
        ]

        open-front-panel
        open-block-diagram
    ]

    pad 10x0

    button "Guardar" 150x40 [
        either empty? fp-items [
            print "No hay nada que guardar."
        ][
            ; Solicitar nombre de fichero
            fname: request-file/save/filter ["QTorres VI" "*.qvi"]
            if fname [
                ; Asegurar extensión .qvi
                fname-str: form fname
                unless find fname-str ".qvi" [
                    fname: to-file rejoin [fname-str ".qvi"]
                ]
                result: compile-to-qvi fname
                print rejoin ["Guardado: " result]
            ]
        ]
    ]

    return
    pad 0x10
    text 300x40 font-size 8 font-color gray
        "1) Pulsa 'Generar .qvi' para abrir el editor^/2) Añade controles, indicadores, bloques y wires^/3) Pulsa 'Guardar' para exportar como .qvi ejecutable"
]
