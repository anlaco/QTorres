Red [
    Title:   "QTorres — Block Diagram Canvas"
    Purpose: "Canvas con bloques arrastrables y wires (Fase 0 - Spike #1 y #2)"
    Needs:   'View
]

; ── Config ─────────────────────────────────────────────
bw: 120                             ; ancho de bloque
bh: 50                              ; alto de bloque
pr: 8                               ; radio de puerto

; ── Estado ─────────────────────────────────────────────
bd-nodes:   copy []
bd-wires:   copy []
drag-node:    none
drag-off:     none
wire-src:     none                  ; nodo origen del wire en creacion
wire-port:    none                  ; puerto origen del wire en creacion
mouse-pos:    none                  ; posicion del raton durante creacion de wire
selected-wire: none                 ; wire seleccionado por clic
selected-node: none                 ; nodo seleccionado por clic

; ── ID generator ───────────────────────────────────────
next-id: 1
gen-id: does [n: next-id  next-id: next-id + 1  n]

; ── Paleta de colores ───────────────────────────────────
col-canvas:     225.228.235    ; fondo canvas (gris frío claro)
col-grid:       200.203.212    ; puntos de cuadrícula
col-block-ctrl: 50.100.180     ; control (azul)
col-block-ind:  175.125.20     ; indicador (ámbar)
col-block-op:   55.75.105      ; operación (pizarra)
col-wire:       195.95.20      ; wire numérico (naranja oscuro)
col-wire-sel:   0.160.200      ; wire seleccionado (cian)
col-port-in:    50.110.200     ; puerto entrada (azul)
col-port-out:   195.80.25      ; puerto salida (naranja)
col-sel:        0.175.210      ; borde selección nodo (cian)
col-text:       240.245.250    ; texto en bloques (blanco)

; ── Color por tipo de nodo ─────────────────────────────
ncolor: func [t] [
    switch t [
        control   [col-block-ctrl]
        indicator [col-block-ind]
        add       [col-block-op]
        sub       [col-block-op]
    ]
]

; ── Puertos por tipo de nodo ────────────────────────────
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

; Calcula la posicion (x,y) de un puerto en el canvas.
port-xy: func [n pname dir /local ps i] [
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

; ── Grid de puntos ──────────────────────────────────────
grid-size: 20

render-grid: func [cw ch /local d x y] [
    d: copy [pen col-grid  fill-pen col-grid  line-width 1]
    x: grid-size
    while [x < cw] [
        y: grid-size
        while [y < ch] [
            append d compose [circle (as-pair x y) 1]
            y: y + grid-size
        ]
        x: x + grid-size
    ]
    d
]

; ── Render ─────────────────────────────────────────────
; Genera primitivas Draw para wires, wire temporal, nodos y puertos.
render-bd: func [/local d sn dn p1 p2 mx wire-color c tl ps iy oy] [
    d: copy []

    ; 0) Grid de fondo
    append d render-grid 880 490

    ; 1) Wires permanentes (linea con punto medio estilo LabVIEW)
    foreach w bd-wires [
        sn: none  dn: none
        foreach n bd-nodes [
            if n/id = w/from-id [sn: n]
            if n/id = w/to-id   [dn: n]
        ]
        if all [sn dn] [
            p1: port-xy sn w/from-p 'out
            p2: port-xy dn w/to-p   'in
            mx: to-integer (p1/x + p2/x) / 2
            wire-color: either same? w selected-wire [col-wire-sel] [col-wire]
            append d compose [
                pen (wire-color)  line-width 2
                line (p1) (as-pair mx p1/y) (as-pair mx p2/y) (p2)
            ]
        ]
    ]

    ; 2) Wire temporal (mientras el usuario elige destino)
    if all [wire-src mouse-pos] [
        sp: port-xy wire-src wire-port 'out
        append d compose [
            pen col-wire  line-width 2
            line (sp) (mouse-pos)
        ]
    ]

    ; 3) Nodos con puertos
    foreach n bd-nodes [
        c: ncolor n/type
        ; Cuerpo del bloque — borde sutil más oscuro que el fill
        append d compose [
            pen (c - 20.20.20)  line-width 1  fill-pen (c)
            box (as-pair n/x n/y) (as-pair (n/x + bw) (n/y + bh)) 5
        ]
        ; Banda izquierda de color (acento visual de categoría)
        append d compose [
            pen off  fill-pen (c + 30.30.30)
            box (as-pair n/x n/y) (as-pair (n/x + 4) (n/y + bh)) 0
        ]
        ; Texto: tipo (siempre visible) y label (según visibilidad DT-022)
        tl: switch n/type [
            control   ["CTRL"]
            indicator ["IND"]
            add       ["ADD +"]
            sub       ["SUB -"]
        ]
        ; Label del nodo — solo si visible (DT-022)
        either all [n/label  object? n/label  n/label/visible] [
            append d compose [
                fill-pen col-text
                text (as-pair (n/x + 10) (n/y + 10)) (n/label/text)
                text (as-pair (n/x + 10) (n/y + 26)) (tl)
            ]
        ][
            ; Sin label visible o label legacy (string): mostrar lo que haya
            either all [n/label  string? n/label] [
                append d compose [
                    fill-pen col-text
                    text (as-pair (n/x + 10) (n/y + 10)) (n/label)
                    text (as-pair (n/x + 10) (n/y + 26)) (tl)
                ]
            ][
                ; Sin label visible: solo tipo
                append d compose [
                    fill-pen col-text
                    text (as-pair (n/x + 10) (n/y + 14)) (tl)
                ]
            ]
        ]

        ; Puertos de entrada (izquierda)
        ps: in-ports n
        iy: n/y + 12
        foreach p ps [
            append d compose [
                pen col-port-in  fill-pen col-port-in
                circle (as-pair (n/x - pr) iy) (pr)
                fill-pen col-text
                text (as-pair (n/x - pr - 22) (iy - 7)) (form p)
            ]
            iy: iy + 20
        ]

        ; Puertos de salida (derecha)
        ps: out-ports n
        oy: n/y + 12
        foreach p ps [
            append d compose [
                pen col-port-out  fill-pen col-port-out
                circle (as-pair (n/x + bw + pr) oy) (pr)
                fill-pen col-text
                text (as-pair (n/x + bw + pr + 12) (oy - 7)) (form p)
            ]
            oy: oy + 20
        ]

        ; Resalte de nodo seleccionado (borde cian)
        if same? n selected-node [
            append d compose [
                pen col-sel  line-width 2  fill-pen off
                box (as-pair (n/x - 3) (n/y - 3)) (as-pair (n/x + bw + 3) (n/y + bh + 3)) 6
                line-width 1
            ]
        ]
    ]
    d
]

; ── Hit-test ───────────────────────────────────────────
; Devuelve [nodo puerto direccion] si (px,py) cae en un puerto, o none.
hit-port: func [px py /local ps oy cx cy iy] [
    foreach n bd-nodes [
        ; Puertos de salida (derecha)
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
        ; Puertos de entrada (izquierda)
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

; Devuelve el nodo bajo (px, py) o none.
hit-node: func [px py /local found] [
    found: none
    foreach n bd-nodes [
        if all [
            px >= n/x  px <= (n/x + bw)
            py >= n/y  py <= (n/y + bh)
        ] [found: n]
    ]
    found
]

; Devuelve el wire bajo (px,py) con tolerancia de 8px, o none.
; Los wires son ortogonales: 3 segmentos (H, V, H) con punto medio.
hit-wire: func [px py /local tol sn dn p1 p2 mx] [
    tol: 8
    foreach w bd-wires [
        sn: none  dn: none
        foreach n bd-nodes [
            if n/id = w/from-id [sn: n]
            if n/id = w/to-id   [dn: n]
        ]
        if all [sn dn] [
            p1: port-xy sn w/from-p 'out
            p2: port-xy dn w/to-p   'in
            mx: to-integer (p1/x + p2/x) / 2
            ; Segmento 1: horizontal p1 → (mx, p1/y)
            if all [
                (absolute (py - p1/y)) < tol
                px >= (min p1/x mx)  px <= (max p1/x mx)
            ] [return w]
            ; Segmento 2: vertical (mx, p1/y) → (mx, p2/y)
            if all [
                (absolute (px - mx)) < tol
                py >= (min p1/y p2/y)  py <= (max p1/y p2/y)
            ] [return w]
            ; Segmento 3: horizontal (mx, p2/y) → p2
            if all [
                (absolute (py - p2/y)) < tol
                px >= (min mx p2/x)  px <= (max mx p2/x)
            ] [return w]
        ]
    ]
    none
]

; ── Canvas factory ─────────────────────────────────────
; Crea una face con drag & drop de bloques y creacion de wires.
make-canvas: func [w [integer!] h [integer!] /local f] [
    f: make face! [
        type: 'base
        size: as-pair w h
        flags: [all-over]
        draw: render-bd
        actors: make object! [
            on-down: func [face event /local px py h hn hp hd n] [
                px: event/offset/x
                py: event/offset/y

                ; 1) Puerto?
                h: hit-port px py
                if h [
                    hn: h/1  hp: h/2  hd: h/3
                    either wire-src = none [
                        ; Primer clic: iniciar wire desde puerto de salida
                        if hd = 'out [
                            wire-src: hn
                            wire-port: hp
                            mouse-pos: event/offset
                            face/draw: render-bd
                        ]
                    ][
                        ; Segundo clic: completar wire en puerto de entrada
                        if all [hd = 'in  wire-src/id <> hn/id] [
                            append bd-wires make object! [
                                from-id: wire-src/id
                                from-p:  wire-port
                                to-id:   hn/id
                                to-p:    hp
                            ]
                        ]
                        wire-src: none  wire-port: none  mouse-pos: none
                        face/draw: render-bd
                    ]
                    return none
                ]

                ; 2) Nodo? (seleccionar + drag)
                n: hit-node px py
                if n [
                    wire-src: none  wire-port: none  mouse-pos: none
                    selected-wire: none
                    selected-node: n
                    drag-node: n
                    drag-off: as-pair (px - n/x) (py - n/y)
                    face/draw: render-bd
                    return none
                ]

                ; 3) Wire?
                n: hit-wire px py
                if n [
                    selected-wire: n
                    selected-node: none
                    wire-src: none  wire-port: none  mouse-pos: none
                    face/draw: render-bd
                    return none
                ]

                ; 4) Clic en vacio: cancelar todo
                wire-src: none  wire-port: none  mouse-pos: none
                drag-node: none  selected-wire: none  selected-node: none
                face/draw: render-bd
            ]
            on-over: func [face event /local px py] [
                px: event/offset/x
                py: event/offset/y
                ; Drag de nodo
                if all [drag-node drag-off event/down?] [
                    drag-node/x: px - drag-off/x
                    drag-node/y: py - drag-off/y
                    face/draw: render-bd
                    return none
                ]
                ; Wire temporal: seguir el raton
                if wire-src [
                    mouse-pos: as-pair px py
                    face/draw: render-bd
                ]
            ]
            on-up: func [face event] [
                drag-node: none
                drag-off:  none
            ]
            on-dbl-click: func [face event /local px py n inp-face cvs lbl-text] [
                px: event/offset/x
                py: event/offset/y
                n: hit-node px py
                if n [
                    cvs: face
                    inp-face: none
                    ; Obtener texto actual de la label (DT-022: objeto o string legacy)
                    lbl-text: either all [n/label  object? n/label] [n/label/text] [
                        either string? n/label [n/label] [""]
                    ]
                    view/flags compose [
                        title "Renombrar nodo"
                        text "Label:" return
                        inp-face: field 200 (lbl-text)
                        on-enter [
                            either empty? inp-face/text [
                                ; Auto-ocultar: label vacía → invisible (DT-022)
                                if all [n/label  object? n/label] [
                                    n/label/visible: false
                                ]
                            ][
                                either all [n/label  object? n/label] [
                                    n/label/text: inp-face/text
                                    n/label/visible: true
                                ][
                                    n/label: inp-face/text
                                ]
                            ]
                            cvs/draw: render-bd
                            unview
                        ]
                        return
                        button "OK" [
                            either empty? inp-face/text [
                                if all [n/label  object? n/label] [
                                    n/label/visible: false
                                ]
                            ][
                                either all [n/label  object? n/label] [
                                    n/label/text: inp-face/text
                                    n/label/visible: true
                                ][
                                    n/label: inp-face/text
                                ]
                            ]
                            cvs/draw: render-bd
                            unview
                        ]
                        button "Cancelar" [unview]
                    ] [modal]
                ]
            ]
        ]
    ]
    f/color: col-canvas
    f
]

; ══════════════════════════════════════════════════════════
; Demo standalone — ejecutar: red src/ui/diagram/canvas.red
; ══════════════════════════════════════════════════════════

; ── Demo: 20 nodos / 15 wires (Issue #4 stress test) ──────────────────────
; Cuadrícula 4 columnas × 5 filas con nodos ADD y SUB alternados.
; 15 wires encadenando nodos consecutivos (result → a).
; Arrastra un nodo para verificar que no hay lag perceptible.

cols:    4
col-gap: 210
row-gap: 90
sx:      40
sy:      20

; Demo usa objetos con estructura nueva (DT-022/024)
; Label como objeto, name como identificador estático
demo-name-ctr: 0
repeat i 20 [
    col:   (i - 1) % cols
    row:   (i - 1) / cols
    ntype: either odd? i ['add] ['sub]
    demo-name-ctr: demo-name-ctr + 1
    lbl-text: either ntype = 'add ["Add"] ["Sub"]
    nm: rejoin [form ntype "_" demo-name-ctr]
    append bd-nodes make object! [
        id:    gen-id
        type:  ntype
        name:  nm
        label: make object! [
            text:    lbl-text
            visible: false          ; operadores: label oculta por defecto (DT-022)
            offset:  0x-15
        ]
        x:     sx + (col * col-gap)
        y:     sy + (row * row-gap)
    ]
]

repeat i 15 [
    append bd-wires make object! [
        from-id: bd-nodes/:i/id
        from-p:  'result
        to-id:   bd-nodes/(i + 1)/id
        to-p:    'a
    ]
]

canvas: make-canvas 880 490
canvas/offset: 10x38

view make face! [
    type:   'window
    text:   "QTorres — Canvas (Issue #1 #2 #3 #4)"
    size:   900x540
    offset: 80x60
    pane:   reduce [
        make face! [
            type: 'base  offset: 10x8  size: 880x25  color: 200.203.212
            draw: [pen 60.70.90  text 5x15 "Arrastra nodos | clic wire/nodo = seleccionar | doble clic nodo = renombrar | Delete/Backspace = borrar"]
        ]
        canvas
    ]
    actors: make object! [
        on-key: func [face event /local nid] [
            if any [
                find [delete backspace] event/key
                find [#"^(7F)" #"^H"] event/key
            ][
                case [
                    selected-wire [
                        remove find bd-wires selected-wire
                        selected-wire: none
                        canvas/draw: render-bd
                    ]
                    selected-node [
                        nid: selected-node/id
                        remove-each w bd-wires [
                            any [w/from-id = nid  w/to-id = nid]
                        ]
                        remove-each n bd-nodes [n/id = nid]
                        selected-node: none
                        drag-node: none
                        canvas/draw: render-bd
                    ]
                ]
            ]
        ]
    ]
]
