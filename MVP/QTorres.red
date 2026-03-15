Red [
    Title:   "QTorres MVP"
    Author:  "QTorres contributors"
    Version: 0.1.0
    Purpose: "MVP: editor visual - .qvi ejecutable"
    Needs:   'View
]

; ══════════════════════════════════════════════════
; Estado global
; ══════════════════════════════════════════════════

next-id: 1
fp-items: copy []
bd-nodes: copy []
bd-wires: copy []

; Drag FP
fp-drag: none
fp-doff: none

; Drag BD
bd-drag: none
bd-doff: none

; Wiring
wire-src:  none
wire-port: none
mouse-pos: none

; Faces
fp-canvas: none
bd-canvas: none
fp-win: none
bd-win: none

; ══════════════════════════════════════════════════
; Config
; ══════════════════════════════════════════════════

bw: 120
bh: 50
pr: 8

gen-id: does [
    n: next-id
    next-id: next-id + 1
    n
]

; ══════════════════════════════════════════════════
; Puertos por tipo
; ══════════════════════════════════════════════════

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

ncolor: func [t] [
    switch t [
        control   [135.190.240]
        indicator [240.220.100]
        add       [120.200.120]
        sub       [255.150.100]
    ]
]

; ══════════════════════════════════════════════════
; Hit tests
; ══════════════════════════════════════════════════

hit-port: func [px py] [
    foreach n bd-nodes [
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

hit-node: func [px py] [
    found: none
    foreach n bd-nodes [
        if all [px >= n/x  px <= (n/x + bw)  py >= n/y  py <= (n/y + bh)] [
            found: n
        ]
    ]
    found
]

hit-fp: func [px py] [
    found: none
    foreach item fp-items [
        if all [px >= item/x  px <= (item/x + 140)  py >= item/y  py <= (item/y + 40)] [
            found: item
        ]
    ]
    found
]

; ══════════════════════════════════════════════════
; Sync FP -> BD
; ══════════════════════════════════════════════════

sync-fp-to-bd: func [item [object!]] [
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
; Render FP
; ══════════════════════════════════════════════════

render-fp: func [] [
    d: copy []
    foreach item fp-items [
        clr: either item/kind = 'control [135.190.240] [240.220.100]
        lbl: either item/kind = 'control [rejoin ["Val: " item/default]] ["---"]
        append d compose [
            pen black  line-width 1  fill-pen (clr)
            box (as-pair item/x item/y) (as-pair (item/x + 140) (item/y + 40)) 5
            fill-pen black
            text (as-pair (item/x + 5) (item/y + 5)) (item/label)
            text (as-pair (item/x + 5) (item/y + 22)) (lbl)
        ]
    ]
    d
]

; ══════════════════════════════════════════════════
; Render BD
; ══════════════════════════════════════════════════

render-bd: func [] [
    d: copy []

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
            append d compose [
                pen 80.80.80  line-width 2
                line (p1) (as-pair mx p1/y) (as-pair mx p2/y) (p2)
            ]
        ]
    ]

    if all [wire-src mouse-pos] [
        sp: port-xy wire-src wire-port 'out
        append d compose [
            pen orange  line-width 2
            line (sp) (mouse-pos)
        ]
    ]

    foreach n bd-nodes [
        c: ncolor n/type
        append d compose [
            pen black  line-width 1  fill-pen (c)
            box (as-pair n/x n/y) (as-pair (n/x + bw) (n/y + bh)) 6
            fill-pen black
            text (as-pair (n/x + 10) (n/y + 8)) (n/label)
        ]
        tl: switch n/type [control ["CTRL"] indicator ["IND"] add ["ADD +"] sub ["SUB -"]]
        append d compose [text (as-pair (n/x + 10) (n/y + 28)) (tl)]

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

; ══════════════════════════════════════════════════
; Front Panel window
; ══════════════════════════════════════════════════

open-front-panel: does [
    if fp-win [show fp-win  exit]

    fp-canvas: make face! [
        type: 'base
        offset: 155x22
        size: 600x490
        color: white
        flags: [all-over]
        draw: render-fp
        actors: make object! [
            on-down: func [face event] [
                px: event/offset/x  py: event/offset/y
                n: hit-fp px py
                if n [
                    fp-drag: n
                    fp-doff: as-pair (px - n/x) (py - n/y)
                    return none
                ]
                fp-drag: none
            ]
            on-over: func [face event] [
                if all [fp-drag fp-doff event/down?] [
                    fp-drag/x: event/offset/x - fp-doff/x
                    fp-drag/y: event/offset/y - fp-doff/y
                    face/draw: render-fp
                ]
            ]
            on-up: func [face event] [
                fp-drag: none
                fp-doff: none
            ]
        ]
    ]

    btn-ctrl: make face! [
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
                fp-canvas/draw: render-fp
                bd-canvas/draw: render-bd
            ]
        ]
    ]

    btn-ind: make face! [
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
                fp-canvas/draw: render-fp
                bd-canvas/draw: render-bd
            ]
        ]
    ]

    fp-palette: make face! [
        type: 'group-box
        text: "Paleta"
        offset: 5x5
        size: 145x120
        pane: reduce [btn-ctrl btn-ind]
    ]

    fp-info: make face! [
        type: 'base
        offset: 155x5
        size: 600x15
        color: 240.240.240
        draw: [pen gray  text 5x1 "Arrastra controles/indicadores"]
    ]

    fp-win: make face! [
        type: 'window
        text: "QTorres - Front Panel"
        size: 760x520
        offset: 50x50
        pane: reduce [fp-palette fp-info fp-canvas]
    ]

    view/no-wait fp-win
]

; ══════════════════════════════════════════════════
; Block Diagram window
; ══════════════════════════════════════════════════

open-block-diagram: does [
    if bd-win [show bd-win  exit]

    bd-canvas: make face! [
        type: 'base
        offset: 155x22
        size: 700x490
        color: 245.245.240
        flags: [all-over]
        draw: render-bd
        actors: make object! [
            on-down: func [face event] [
                px: event/offset/x
                py: event/offset/y

                h: hit-port px py
                if h [
                    hn: h/1  hp: h/2  hd: h/3
                    either wire-src = none [
                        if hd = 'out [
                            wire-src: hn
                            wire-port: hp
                            mouse-pos: event/offset
                            face/draw: render-bd
                        ]
                    ][
                        if all [hd = 'in  wire-src/id <> hn/id] [
                            append bd-wires make object! [
                                from-id: wire-src/id
                                from-p:  wire-port
                                to-id:   hn/id
                                to-p:    hp
                            ]
                        ]
                        wire-src: none
                        wire-port: none
                        mouse-pos: none
                        face/draw: render-bd
                    ]
                    return none
                ]

                n: hit-node px py
                if n [
                    wire-src: none  wire-port: none  mouse-pos: none
                    bd-drag: n
                    bd-doff: as-pair (px - n/x) (py - n/y)
                    return none
                ]

                wire-src: none  wire-port: none  mouse-pos: none
                bd-drag: none
                face/draw: render-bd
            ]

            on-over: func [face event] [
                px: event/offset/x
                py: event/offset/y
                if all [bd-drag bd-doff event/down?] [
                    bd-drag/x: px - bd-doff/x
                    bd-drag/y: py - bd-doff/y
                    face/draw: render-bd
                    return none
                ]
                if wire-src [
                    mouse-pos: as-pair px py
                    face/draw: render-bd
                ]
            ]

            on-up: func [face event] [
                bd-drag: none
                bd-doff: none
            ]
        ]
    ]

    btn-add: make face! [
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
                bd-canvas/draw: render-bd
            ]
        ]
    ]

    btn-sub: make face! [
        type: 'button
        text: "Resta (-)"
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
                bd-canvas/draw: render-bd
            ]
        ]
    ]

    bd-palette: make face! [
        type: 'group-box
        text: "Bloques"
        offset: 5x5
        size: 145x120
        pane: reduce [btn-add btn-sub]
    ]

    bd-info: make face! [
        type: 'base
        offset: 155x5
        size: 700x15
        color: 240.240.240
        draw: [pen gray  text 5x1 "Clic rojo(salida) -> clic azul(entrada) = wire | Drag = mover"]
    ]

    bd-win: make face! [
        type: 'window
        text: "QTorres - Block Diagram"
        size: 880x520
        offset: 200x100
        pane: reduce [bd-palette bd-info bd-canvas]
    ]

    view/no-wait bd-win
]

; ══════════════════════════════════════════════════
; Compilador: modelo -> .qvi
; ══════════════════════════════════════════════════

compile-to-qvi: func [filename [file!]] [
    fp-block: copy []
    foreach item fp-items [
        either item/kind = 'control [
            append fp-block compose/deep [
                control [id: (item/id) type: 'numeric label: (item/label) default: (item/default)]
            ]
        ][
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
            wire [from: (w/from-id) port: (to-lit-word form w/from-p) to: (w/to-id) port: (to-lit-word form w/to-p)]
        ]
    ]

    diagram-block: compose/deep [
        front-panel: [(fp-block)]
        block-diagram: [
            nodes: [(nd-block)]
            wires: [(wr-block)]
        ]
    ]

    code-lines: copy []

    foreach item fp-items [
        if item/kind = 'control [
            append code-lines rejoin [item/label ": " item/default newline]
        ]
    ]

    op-nodes: copy []
    foreach n bd-nodes [
        if any [n/type = 'add  n/type = 'sub] [append op-nodes n]
    ]

    foreach n op-nodes [
        input-a: "0.0"
        input-b: "0.0"
        foreach w bd-wires [
            if w/to-id = n/id [
                foreach src bd-nodes [
                    if src/id = w/from-id [
                        either w/to-p = 'a [input-a: src/label] [input-b: src/label]
                    ]
                ]
            ]
        ]
        op: either n/type = 'add [" + "] [" - "]
        append code-lines rejoin [n/label ": " input-a op input-b newline]
    ]

    foreach item fp-items [
        if item/kind = 'indicator [
            foreach w bd-wires [
                if w/to-id = item/id [
                    foreach src bd-nodes [
                        if src/id = w/from-id [
                            append code-lines rejoin [item/label ": " src/label newline]
                        ]
                    ]
                ]
            ]
        ]
    ]

    foreach item fp-items [
        if item/kind = 'indicator [
            append code-lines rejoin ["print " item/label newline]
        ]
    ]

    out: copy {Red [title: "QTorres VI"]^/^/}
    append out "; -- CABECERA GRAFICA --^/"
    append out "; QTorres lee esta seccion para reconstruir la vista.^/"
    append out "; Para Red es solo una asignacion sin efectos.^/^/"
    append out "qvi-diagram: "
    append out mold diagram-block
    append out "^/^/"
    append out "; -- CODIGO GENERADO --^/"
    append out "; Generado por QTorres. Ejecutable con Red directamente.^/^/"
    foreach line code-lines [append out line]

    write filename out
    filename
]

; ══════════════════════════════════════════════════
; Ventana principal
; ══════════════════════════════════════════════════

btn-gen: make face! [
    type: 'button
    text: "Generar .qvi"
    offset: 20x70
    size: 150x40
    actors: make object! [
        on-click: func [face event] [
            next-id: 1
            clear fp-items
            clear bd-nodes
            clear bd-wires
            wire-src: none  wire-port: none  mouse-pos: none
            fp-drag: none   bd-drag: none

            if fp-win [unview/only fp-win  fp-win: none]
            if bd-win [unview/only bd-win  bd-win: none]

            open-front-panel
            open-block-diagram
        ]
    ]
]

btn-save: make face! [
    type: 'button
    text: "Guardar"
    offset: 185x70
    size: 150x40
    actors: make object! [
        on-click: func [face event] [
            either empty? fp-items [
                print "No hay nada que guardar."
            ][
                fname: request-file/save/filter ["QTorres VI" "*.qvi"]
                if fname [
                    fname-str: form fname
                    unless find fname-str ".qvi" [
                        fname: to-file rejoin [fname-str ".qvi"]
                    ]
                    result: compile-to-qvi fname
                    print rejoin ["Guardado: " result]
                ]
            ]
        ]
    ]
]

title-lbl: make face! [
    type: 'base
    offset: 20x10
    size: 320x30
    color: 240.240.240
    draw: [pen navy  text 0x0 "QTorres - Programacion Visual"]
]

sub-lbl: make face! [
    type: 'base
    offset: 20x40
    size: 320x25
    color: 240.240.240
    draw: [pen gray  text 0x0 "Entorno visual tipo LabVIEW sobre Red-Lang"]
]

help-lbl: make face! [
    type: 'base
    offset: 20x120
    size: 320x50
    color: 240.240.240
    draw: [pen gray  text 0x0 "1) Pulsa 'Generar .qvi' para abrir editor^/2) Anade controles, indicadores, bloques, wires^/3) Pulsa 'Guardar' para exportar .qvi ejecutable"]
]

main-win: make face! [
    type: 'window
    text: "QTorres MVP v0.1"
    size: 360x180
    color: 240.240.240
    pane: reduce [title-lbl sub-lbl btn-gen btn-save help-lbl]
]

view main-win
