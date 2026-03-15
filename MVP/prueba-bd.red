Red [
    Title: "Prueba Block Diagram"
    Needs: 'View
]

; === Estado ===
nodes: reduce [
    make object! [id: 1  label: "A"    type: 'control    x: 50   y: 60 ]
    make object! [id: 2  label: "B"    type: 'control    x: 50   y: 180]
    make object! [id: 3  label: "Add"  type: 'add        x: 250  y: 120]
    make object! [id: 4  label: "Out"  type: 'indicator   x: 450  y: 120]
]

wires: copy []

drag-node: none
drag-off:  none
wire-src:  none
wire-port: none
mouse-pos: none

; === Config ===
bw: 120                ; ancho nodo
bh: 50                 ; alto nodo
pr: 8                  ; radio puerto

; === Puertos por tipo ===
in-ports: func [n] [
    switch n/type [
        control   [[]]
        indicator [[in]]
        add       [[a b]]
        sub       [[a b]]
    ]
]
out-ports: func [n] [
    switch n/type [
        control   [[out]]
        indicator [[]]
        add       [[result]]
        sub       [[result]]
    ]
]

; Posicion de un puerto
port-xy: func [n pname dir] [
    either dir = 'in [
        ps: in-ports n
        i: index? find ps pname
        as-pair (n/x - pr) (n/y + 12 + ((i - 1) * 20))
    ][
        ps: out-ports n
        i: index? find ps pname
        as-pair (n/x + bw + pr) (n/y + 12 + ((i - 1) * 20))
    ]
]

; Color por tipo
ncolor: func [t] [
    switch t [
        control   [135.190.240]
        indicator [240.220.100]
        add       [120.200.120]
        sub       [255.150.100]
    ]
]

; === Dibujar ===
render: func [] [
    d: copy []

    ; Wires
    foreach w wires [
        sn: none  dn: none
        foreach n nodes [
            if n/id = w/from-id [sn: n]
            if n/id = w/to-id   [dn: n]
        ]
        if all [sn dn] [
            p1: port-xy sn w/from-p 'out
            p2: port-xy dn w/to-p   'in
            mx: to-integer (p1/x + p2/x) / 2
            append d compose [
                pen 80.80.80  line-width 2
                line (p1) (as-pair mx p1/y) (as-pair mx p2/y) (p2)
            ]
        ]
    ]

    ; Wire temporal
    if all [wire-src mouse-pos] [
        sp: port-xy wire-src wire-port 'out
        append d compose [
            pen orange  line-width 2
            line (sp) (mouse-pos)
        ]
    ]

    ; Nodos
    foreach n nodes [
        c: ncolor n/type
        append d compose [
            pen black  line-width 1  fill-pen (c)
            box (as-pair n/x n/y) (as-pair (n/x + bw) (n/y + bh)) 6
            fill-pen black
            text (as-pair (n/x + 10) (n/y + 8)) (n/label)
        ]
        tl: switch n/type [control ["CTRL"] indicator ["IND"] add ["ADD +"] sub ["SUB −"]]
        append d compose [text (as-pair (n/x + 10) (n/y + 28)) (tl)]

        ; Puertos de entrada (azul, izquierda)
        ps: in-ports n
        iy: n/y + 12
        foreach p ps [
            append d compose [
                pen black  fill-pen 50.100.220
                circle (as-pair (n/x - pr) iy) (pr)
                fill-pen black
                text (as-pair (n/x - pr - 22) (iy - 7)) (form p)
            ]
            iy: iy + 20
        ]
        ; Puertos de salida (rojo, derecha)
        ps: out-ports n
        oy: n/y + 12
        foreach p ps [
            append d compose [
                pen black  fill-pen 220.60.60
                circle (as-pair (n/x + bw + pr) oy) (pr)
                fill-pen black
                text (as-pair (n/x + bw + pr + 12) (oy - 7)) (form p)
            ]
            oy: oy + 20
        ]
    ]
    d
]

; === Hit test: puerto ===
; Devuelve [nodo port-name 'in|'out] o none
hit-port: func [px py] [
    foreach n nodes [
        ; Salida (derecha)
        ps: out-ports n
        oy: n/y + 12
        foreach p ps [
            cx: n/x + bw + pr
            cy: oy
            if all [(absolute (px - cx)) < 16  (absolute (py - cy)) < 16] [
                return reduce [n p 'out]
            ]
            oy: oy + 20
        ]
        ; Entrada (izquierda)
        ps: in-ports n
        iy: n/y + 12
        foreach p ps [
            cx: n/x - pr
            cy: iy
            if all [(absolute (px - cx)) < 16  (absolute (py - cy)) < 16] [
                return reduce [n p 'in]
            ]
            iy: iy + 20
        ]
    ]
    none
]

; === Hit test: nodo cuerpo ===
hit-node: func [px py] [
    ; Buscar el ultimo (el de encima)
    found: none
    foreach n nodes [
        if all [px >= n/x  px <= (n/x + bw)  py >= n/y  py <= (n/y + bh)] [
            found: n
        ]
    ]
    found
]

; === Ventana ===
canvas: make face! [
    type: 'base
    size: 800x500
    offset: 0x22
    color: 245.245.240
    flags: [all-over]
    draw: render
    actors: make object! [
        on-down: func [face event] [
            px: event/offset/x
            py: event/offset/y

            ; 1. Puerto?
            h: hit-port px py
            if h [
                hn: h/1  hp: h/2  hd: h/3
                either wire-src = none [
                    ; Iniciar wire desde salida
                    if hd = 'out [
                        wire-src: hn
                        wire-port: hp
                        mouse-pos: event/offset
                        face/draw: render
                    ]
                ][
                    ; Completar wire en entrada
                    if all [hd = 'in  wire-src/id <> hn/id] [
                        append wires make object! [
                            from-id: wire-src/id
                            from-p:  wire-port
                            to-id:   hn/id
                            to-p:    hp
                        ]
                    ]
                    wire-src: none
                    wire-port: none
                    mouse-pos: none
                    face/draw: render
                ]
                return none
            ]

            ; 2. Nodo?
            n: hit-node px py
            if n [
                wire-src: none  wire-port: none  mouse-pos: none
                drag-node: n
                drag-off: as-pair (px - n/x) (py - n/y)
                return none
            ]

            ; 3. Vacio → cancelar
            wire-src: none  wire-port: none  mouse-pos: none
            drag-node: none
            face/draw: render
        ]

        on-over: func [face event] [
            px: event/offset/x
            py: event/offset/y
            if all [drag-node drag-off event/down?] [
                drag-node/x: px - drag-off/x
                drag-node/y: py - drag-off/y
                face/draw: render
                return none
            ]
            if wire-src [
                mouse-pos: as-pair px py
                face/draw: render
            ]
        ]

        on-up: func [face event] [
            drag-node: none
            drag-off: none
        ]
    ]
]

lbl: make face! [
    type: 'base
    offset: 0x0
    size: 800x20
    color: 230.230.230
    draw: [pen gray  text 10x3 "Drag: clic+arrastra nodo | Wire: clic rojo → clic azul | Clic vacío: cancelar"]
]

win: make face! [
    type: 'window
    text: "Prueba: Drag + Wires"
    size: 800x522
    pane: reduce [lbl canvas]
]

view win
