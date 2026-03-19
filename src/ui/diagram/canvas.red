Red [
    Title:   "QTorres — Block Diagram Canvas"
    Purpose: "Canvas modular: render-diagram recibe modelo explícito (Issue #11)"
    Needs:   'View
]

; ══════════════════════════════════════════════════════════
; CONFIG — constantes visuales, sin estado mutable
; ══════════════════════════════════════════════════════════
bw: 120   bh: 50   pr: 8   grid-size: 20

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
ncolor: func [t] [
    switch t [
        control   [col-block-ctrl]
        indicator [col-block-ind]
        add       [col-block-op]
        sub       [col-block-op]
    ]
]

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

; ══════════════════════════════════════════════════════════
; MODELO — todo el estado mutable vive aquí
; ══════════════════════════════════════════════════════════
make-diagram-model: func [] [
    make object! [
        nodes:         copy []
        wires:         copy []
        next-id:       1
        selected-node: none
        selected-wire: none
        drag-node:     none
        drag-off:      none
        wire-src:      none
        wire-port:     none
        mouse-pos:     none
    ]
]

gen-node-id: func [model /local n] [
    n: model/next-id
    model/next-id: model/next-id + 1
    n
]

; ══════════════════════════════════════════════════════════
; RENDER — funciones puras que reciben modelo y devuelven
;          bloques de primitivas Draw
; ══════════════════════════════════════════════════════════
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

render-bd: func [model /local d sn dn p1 p2 mx wire-color c tl ps iy oy n w sp] [
    d: copy []

    ; 0) Grid de fondo
    append d render-grid 880 490

    ; 1) Wires permanentes (ortogonales con punto medio estilo LabVIEW)
    foreach w model/wires [
        sn: none  dn: none
        foreach n model/nodes [
            if n/id = w/from-id [sn: n]
            if n/id = w/to-id   [dn: n]
        ]
        if all [sn dn] [
            p1: port-xy sn w/from-p 'out
            p2: port-xy dn w/to-p   'in
            mx: to-integer (p1/x + p2/x) / 2
            wire-color: either same? w model/selected-wire [col-wire-sel] [col-wire]
            append d compose [
                pen (wire-color)  line-width 2
                line (p1) (as-pair mx p1/y) (as-pair mx p2/y) (p2)
            ]
        ]
    ]

    ; 2) Wire temporal (mientras el usuario elige destino)
    if all [model/wire-src model/mouse-pos] [
        sp: port-xy model/wire-src model/wire-port 'out
        append d compose [
            pen col-wire  line-width 2
            line (sp) (model/mouse-pos)
        ]
    ]

    ; 3) Nodos con puertos
    foreach n model/nodes [
        c: ncolor n/type
        ; Cuerpo del bloque
        append d compose [
            pen (c - 20.20.20)  line-width 1  fill-pen (c)
            box (as-pair n/x n/y) (as-pair (n/x + bw) (n/y + bh)) 5
        ]
        ; Banda izquierda de categoría
        append d compose [
            pen off  fill-pen (c + 30.30.30)
            box (as-pair n/x n/y) (as-pair (n/x + 4) (n/y + bh)) 0
        ]
        ; Texto: tipo + label (DT-022)
        tl: switch n/type [
            control   ["CTRL"]
            indicator ["IND"]
            add       ["ADD +"]
            sub       ["SUB -"]
        ]
        either all [n/label  object? n/label  n/label/visible] [
            append d compose [
                fill-pen col-text
                text (as-pair (n/x + 10) (n/y + 10)) (n/label/text)
                text (as-pair (n/x + 10) (n/y + 26)) (tl)
            ]
        ][
            either all [n/label  string? n/label] [
                append d compose [
                    fill-pen col-text
                    text (as-pair (n/x + 10) (n/y + 10)) (n/label)
                    text (as-pair (n/x + 10) (n/y + 26)) (tl)
                ]
            ][
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

        ; Borde de selección (cian)
        if same? n model/selected-node [
            append d compose [
                pen col-sel  line-width 2  fill-pen off
                box (as-pair (n/x - 3) (n/y - 3)) (as-pair (n/x + bw + 3) (n/y + bh + 3)) 6
                line-width 1
            ]
        ]
    ]
    d
]

; ══════════════════════════════════════════════════════════
; HIT-TEST — funciones puras, reciben modelo y coordenadas
; ══════════════════════════════════════════════════════════
hit-port: func [model px py /local ps oy cx cy iy n p] [
    foreach n model/nodes [
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

hit-node: func [model px py /local found n] [
    found: none
    foreach n model/nodes [
        if all [
            px >= n/x  px <= (n/x + bw)
            py >= n/y  py <= (n/y + bh)
        ] [found: n]
    ]
    found
]

hit-wire: func [model px py /local tol sn dn p1 p2 mx w n] [
    tol: 8
    foreach w model/wires [
        sn: none  dn: none
        foreach n model/nodes [
            if n/id = w/from-id [sn: n]
            if n/id = w/to-id   [dn: n]
        ]
        if all [sn dn] [
            p1: port-xy sn w/from-p 'out
            p2: port-xy dn w/to-p   'in
            mx: to-integer (p1/x + p2/x) / 2
            if all [
                (absolute (py - p1/y)) < tol
                px >= (min p1/x mx)  px <= (max p1/x mx)
            ] [return w]
            if all [
                (absolute (px - mx)) < tol
                py >= (min p1/y p2/y)  py <= (max p1/y p2/y)
            ] [return w]
            if all [
                (absolute (py - p2/y)) < tol
                px >= (min mx p2/x)  px <= (max mx p2/x)
            ] [return w]
        ]
    ]
    none
]

; ══════════════════════════════════════════════════════════
; CANVAS FACTORY — render-diagram devuelve una face funcional
;   El modelo se almacena en face/extra para que los actores
;   puedan acceder sin depender de variables globales.
; ══════════════════════════════════════════════════════════

; Estado del diálogo de renombrado (view/no-wait requiere vars de módulo
; porque la función retorna antes de que el usuario cierre el diálogo).
rename-node: none
rename-cvs:  none
rename-fld:  none

; Borra el elemento seleccionado (nodo o wire).
; Llamar desde el on-key del window padre con: canvas-delete-selected canvas
canvas-delete-selected: func [canvas /local model nid] [
    model: canvas/extra
    case [
        model/selected-wire [
            remove find model/wires model/selected-wire
            model/selected-wire: none
            canvas/draw: render-bd model
        ]
        model/selected-node [
            nid: model/selected-node/id
            remove-each w model/wires [any [w/from-id = nid  w/to-id = nid]]
            remove-each n model/nodes  [n/id = nid]
            model/selected-node: none
            model/drag-node:     none
            canvas/draw: render-bd model
        ]
    ]
]

; render-diagram model w h → face
; Crea una face base con bloques arrastrables, creación de wires,
; hit-testing y renombrado por doble clic.
render-diagram: func [model w h /local f] [
    f: make face! [
        type:  'base
        size:  as-pair w h
        flags: [all-over]
        extra: model                    ; modelo accesible desde actores via face/extra
        actors: make object! [

            on-down: func [face event /local px py m h hn hp hd n] [
                m: face/extra
                px: event/offset/x
                py: event/offset/y

                ; 1) Puerto?
                h: hit-port m px py
                if h [
                    hn: h/1  hp: h/2  hd: h/3
                    either m/wire-src = none [
                        if hd = 'out [
                            m/wire-src:  hn
                            m/wire-port: hp
                            m/mouse-pos: event/offset
                            face/draw: render-bd m
                        ]
                    ][
                        if all [hd = 'in  m/wire-src/id <> hn/id] [
                            append m/wires make object! [
                                from-id: m/wire-src/id
                                from-p:  m/wire-port
                                to-id:   hn/id
                                to-p:    hp
                            ]
                        ]
                        m/wire-src: none  m/wire-port: none  m/mouse-pos: none
                        face/draw: render-bd m
                    ]
                    return none
                ]

                ; 2) Nodo? (seleccionar + drag)
                n: hit-node m px py
                if n [
                    m/wire-src: none  m/wire-port: none  m/mouse-pos: none
                    m/selected-wire: none
                    m/selected-node: n
                    m/drag-node: n
                    m/drag-off: as-pair (px - n/x) (py - n/y)
                    face/draw: render-bd m
                    return none
                ]

                ; 3) Wire?
                n: hit-wire m px py
                if n [
                    m/selected-wire: n
                    m/selected-node: none
                    m/wire-src: none  m/wire-port: none  m/mouse-pos: none
                    face/draw: render-bd m
                    return none
                ]

                ; 4) Clic en vacío: cancelar todo
                m/wire-src: none  m/wire-port: none  m/mouse-pos: none
                m/drag-node: none  m/selected-wire: none  m/selected-node: none
                face/draw: render-bd m
            ]

            on-over: func [face event /local px py m] [
                m: face/extra
                px: event/offset/x
                py: event/offset/y
                if all [m/drag-node m/drag-off event/down?] [
                    m/drag-node/x: px - m/drag-off/x
                    m/drag-node/y: py - m/drag-off/y
                    face/draw: render-bd m
                    return none
                ]
                if m/wire-src [
                    m/mouse-pos: as-pair px py
                    face/draw: render-bd m
                ]
            ]

            on-up: func [face event /local m] [
                m: face/extra
                m/drag-node: none
                m/drag-off:  none
            ]

            on-key: func [face event /local m] [
                m: face/extra
                if any [
                    find [delete backspace] event/key
                    find [#"^(7F)" #"^H"] event/key
                ][
                    canvas-delete-selected face
                ]
            ]

            on-dbl-click: func [face event /local px py m n lbl-text] [
                m: face/extra
                px: event/offset/x
                py: event/offset/y
                n: hit-node m px py
                if n [
                    ; Guardar refs en vars de módulo (persisten tras view/no-wait)
                    rename-node: n
                    rename-cvs:  face
                    rename-fld:  none
                    lbl-text: either all [n/label  object? n/label] [n/label/text] [
                        either string? n/label [n/label] [""]
                    ]
                    view/no-wait compose [
                        title "Renombrar nodo"
                        text "Label:" return
                        rename-fld: field 200 (lbl-text)
                        on-enter [
                            either empty? rename-fld/text [
                                if all [rename-node/label  object? rename-node/label] [
                                    rename-node/label/visible: false
                                ]
                            ][
                                either all [rename-node/label  object? rename-node/label] [
                                    rename-node/label/text: rename-fld/text
                                    rename-node/label/visible: true
                                ][
                                    rename-node/label: rename-fld/text
                                ]
                            ]
                            rename-cvs/draw: render-bd rename-cvs/extra
                            unview
                        ]
                        return
                        button "OK" [
                            either empty? rename-fld/text [
                                if all [rename-node/label  object? rename-node/label] [
                                    rename-node/label/visible: false
                                ]
                            ][
                                either all [rename-node/label  object? rename-node/label] [
                                    rename-node/label/text: rename-fld/text
                                    rename-node/label/visible: true
                                ][
                                    rename-node/label: rename-fld/text
                                ]
                            ]
                            rename-cvs/draw: render-bd rename-cvs/extra
                            unview
                        ]
                        button "Cancelar" [unview]
                    ]
                ]
            ]
        ]
    ]
    f/color: col-canvas
    f/draw: render-bd model
    f
]

; ══════════════════════════════════════════════════════════
; DEMO STANDALONE — ejecutar: red src/ui/diagram/canvas.red
; Stress test: 20 nodos / 15 wires (Issue #4)
; ══════════════════════════════════════════════════════════

demo-model: make-diagram-model

cols:    4
col-gap: 210
row-gap: 90
sx:      40
sy:      20

repeat i 20 [
    col:   (i - 1) % cols
    row:   (i - 1) / cols
    ntype: either odd? i ['add] ['sub]
    lbl-text: either ntype = 'add ["Add"] ["Sub"]
    nid: gen-node-id demo-model
    append demo-model/nodes make object! [
        id:    nid
        type:  ntype
        name:  rejoin [form ntype "_" nid]
        label: make object! [
            text:    lbl-text
            visible: false
            offset:  0x-15
        ]
        x:     sx + (col * col-gap)
        y:     sy + (row * row-gap)
    ]
]

repeat i 15 [
    append demo-model/wires make object! [
        from-id: demo-model/nodes/:i/id
        from-p:  'result
        to-id:   demo-model/nodes/(i + 1)/id
        to-p:    'a
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
