Red [
    Title:   "QTorres MVP"
    Author:  "QTorres contributors"
    Version: 0.1.0
    Purpose: "MVP: editor visual -> .qvi ejecutable"
    Needs:   'View
]

; ==============================================================================
; Estado global
; ==============================================================================

next-id: 1
gen-id: does [n: next-id  next-id: next-id + 1  n]

; Front Panel items
fp-items: copy []

; Block Diagram nodes y wires
bd-nodes: copy []
bd-wires: copy []

; Drag state (BD)
bd-drag-node: none
bd-drag-off:  none

; Drag state (FP)
fp-drag-item: none
fp-drag-off:  none

; Wire state
wire-src:  none
wire-port: none
mouse-pos: none

; Window refs
fp-win: none
bd-win: none
fp-canvas: none
bd-canvas: none

; Ultimo fichero guardado
last-saved: none

; ==============================================================================
; Config
; ==============================================================================

bw: 120
bh: 50
pr: 8

; ==============================================================================
; Puertos por tipo
; ==============================================================================

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

; ==============================================================================
; Sincronizacion FP -> BD
; ==============================================================================

sync-fp-to-bd: func [item] [
    exists: false
    foreach n bd-nodes [if n/id = item/id [exists: true]]
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

; ==============================================================================
; Render Front Panel
; ==============================================================================

render-fp: func [] [
    d: copy []
    foreach item fp-items [
        clr: either item/kind = 'control [135.190.240] [240.220.100]
        val-text: either item/kind = 'control [
            rejoin ["Val: " item/default]
        ][
            either item/default = 0.0 ["---"] [rejoin ["= " item/default]]
        ]
        append d compose [
            pen black  line-width 1  fill-pen (clr)
            box (as-pair item/x item/y) (as-pair (item/x + 140) (item/y + 40)) 5
            fill-pen black
            text (as-pair (item/x + 5) (item/y + 5)) (item/label)
            text (as-pair (item/x + 5) (item/y + 22)) (val-text)
        ]
    ]
    d
]

; ==============================================================================
; Render Block Diagram
; ==============================================================================

render-bd: func [] [
    d: copy []

    ; Wires
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

    ; Wire temporal
    if all [wire-src mouse-pos] [
        sp: port-xy wire-src wire-port 'out
        append d compose [
            pen orange  line-width 2
            line (sp) (mouse-pos)
        ]
    ]

    ; Nodos
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

        ; Puertos entrada (azul, izquierda)
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
        ; Puertos salida (rojo, derecha)
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

; ==============================================================================
; Hit tests (BD) — mismo patron que prueba-bd.red
; ==============================================================================

hit-port: func [px py] [
    foreach n bd-nodes [
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

hit-node: func [px py] [
    found: none
    foreach n bd-nodes [
        if all [px >= n/x  px <= (n/x + bw)  py >= n/y  py <= (n/y + bh)] [
            found: n
        ]
    ]
    found
]

; Hit test FP
hit-fp-item: func [px py] [
    found: none
    foreach item fp-items [
        if all [px >= item/x  px <= (item/x + 140)  py >= item/y  py <= (item/y + 40)] [
            found: item
        ]
    ]
    found
]

; ==============================================================================
; Compilador: modelo -> .qvi
; ==============================================================================

compile-to-qvi: func [filename] [
    ; Cabecera
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

    ; Codigo ejecutable
    code-lines: copy []

    ; Defaults de controles
    foreach item fp-items [
        if item/kind = 'control [
            append code-lines rejoin [item/label ": " item/default newline]
        ]
    ]

    ; Nodos operacion
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

    ; Indicadores
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

    ; Print indicadores
    foreach item fp-items [
        if item/kind = 'indicator [
            append code-lines rejoin ["print " item/label newline]
        ]
    ]

    ; Escribir fichero
    out: copy {Red [title: "QTorres VI"]^/^/}
    append out "; -- CABECERA GRAFICA --^/"
    append out "; QTorres lee esta seccion para reconstruir la vista.^/"
    append out "; Para Red es solo una asignacion sin efectos.^/^/"
    append out "qvi-diagram: "
    append out mold diagram-block
    append out "^/^/"
    append out "; -- CODIGO GENERADO --^/"
    append out "; Generado por QTorres al guardar. Ejecutable con Red directamente.^/^/"
    foreach line code-lines [append out line]

    write filename out
    filename
]

; ==============================================================================
; Abrir Front Panel
; ==============================================================================

open-front-panel: does [
    if fp-win [show fp-win  exit]

    fp-canvas: make face! [
        type: 'base
        size: 580x480
        offset: 155x25
        color: white
        flags: [all-over]
        draw: render-fp
        actors: make object! [
            on-down: func [face event] [
                px: event/offset/x  py: event/offset/y
                item: hit-fp-item px py
                if item [
                    fp-drag-item: item
                    fp-drag-off: as-pair (px - item/x) (py - item/y)
                    return none
                ]
                fp-drag-item: none
            ]
            on-over: func [face event] [
                if all [fp-drag-item fp-drag-off event/down?] [
                    fp-drag-item/x: event/offset/x - fp-drag-off/x
                    fp-drag-item/y: event/offset/y - fp-drag-off/y
                    face/draw: render-fp
                ]
            ]
            on-up: func [face event] [
                fp-drag-item: none
                fp-drag-off: none
            ]
            on-dbl-click: func [face event] [
                px: event/offset/x  py: event/offset/y
                item: hit-fp-item px py
                if all [item  item/kind = 'control] [
                    ; Dialogo para editar valor
                    edit-item: item
                    edit-val: none
                    edit-dlg: make face! [
                        type: 'window
                        text: rejoin ["Valor de " item/label]
                        size: 300x100
                        offset: 350x350
                        pane: reduce [
                            make face! [
                                type: 'text  text: "Valor numerico:"
                                offset: 10x10  size: 280x20
                            ]
                            make face! [
                                type: 'field  text: form item/default
                                offset: 10x35  size: 200x28
                                actors: make object! [
                                    on-enter: func [face event] [
                                        edit-val: face/text
                                        unview/only edit-dlg
                                    ]
                                ]
                            ]
                            make face! [
                                type: 'button  text: "OK"
                                offset: 220x35  size: 60x28
                                actors: make object! [
                                    on-click: func [face event] [
                                        fld: edit-dlg/pane/2
                                        edit-val: fld/text
                                        unview/only edit-dlg
                                    ]
                                ]
                            ]
                        ]
                    ]
                    view/no-wait edit-dlg
                    do-events
                    if edit-val [
                        v: attempt [to-float edit-val]
                        if v [edit-item/default: v]
                    ]
                    face/draw: render-fp
                ]
            ]
        ]
    ]

    btn-ctrl: make face! [
        type: 'button  text: "Control Num."
        offset: 15x25  size: 120x35
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
                if bd-canvas [bd-canvas/draw: render-bd]
            ]
        ]
    ]

    btn-ind: make face! [
        type: 'button  text: "Indicador Num."
        offset: 15x65  size: 120x35
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
                if bd-canvas [bd-canvas/draw: render-bd]
            ]
        ]
    ]

    palette-box: make face! [
        type: 'base  offset: 5x5  size: 145x110  color: 225.225.225
        draw: [pen gray box 0x0 144x109 4  pen black text 10x5 "Paleta"]
        pane: reduce [btn-ctrl btn-ind]
    ]

    lbl: make face! [
        type: 'base  offset: 155x5  size: 580x18  color: 240.240.240
        draw: [pen gray text 5x2 "Arrastra controles/indicadores"]
    ]

    fp-win: make face! [
        type: 'window
        text: "QTorres - Front Panel"
        size: 740x510
        offset: 30x50
        pane: reduce [palette-box lbl fp-canvas]
    ]

    view/no-wait fp-win
]

; ==============================================================================
; Abrir Block Diagram
; ==============================================================================

open-block-diagram: does [
    if bd-win [show bd-win  exit]

    bd-canvas: make face! [
        type: 'base
        size: 680x480
        offset: 155x25
        color: 245.245.240
        flags: [all-over]
        draw: render-bd
        actors: make object! [
            on-down: func [face event] [
                px: event/offset/x
                py: event/offset/y

                ; 1. Puerto?
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

                ; 2. Nodo?
                n: hit-node px py
                if n [
                    wire-src: none  wire-port: none  mouse-pos: none
                    bd-drag-node: n
                    bd-drag-off: as-pair (px - n/x) (py - n/y)
                    return none
                ]

                ; 3. Vacio
                wire-src: none  wire-port: none  mouse-pos: none
                bd-drag-node: none
                face/draw: render-bd
            ]

            on-over: func [face event] [
                px: event/offset/x
                py: event/offset/y
                if all [bd-drag-node bd-drag-off event/down?] [
                    bd-drag-node/x: px - bd-drag-off/x
                    bd-drag-node/y: py - bd-drag-off/y
                    face/draw: render-bd
                    return none
                ]
                if wire-src [
                    mouse-pos: as-pair px py
                    face/draw: render-bd
                ]
            ]

            on-up: func [face event] [
                bd-drag-node: none
                bd-drag-off: none
            ]
        ]
    ]

    btn-add: make face! [
        type: 'button  text: "Suma (+)"
        offset: 15x25  size: 120x35
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
        type: 'button  text: "Resta (-)"
        offset: 15x65  size: 120x35
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

    palette-box: make face! [
        type: 'base  offset: 5x5  size: 145x110  color: 225.225.225
        draw: [pen gray box 0x0 144x109 4  pen black text 10x5 "Bloques"]
        pane: reduce [btn-add btn-sub]
    ]

    lbl: make face! [
        type: 'base  offset: 155x5  size: 680x18  color: 240.240.240
        draw: [pen gray text 5x2 "Clic rojo(salida) -> clic azul(entrada) para wire | Arrastra nodos"]
    ]

    bd-win: make face! [
        type: 'window
        text: "QTorres - Block Diagram"
        size: 840x510
        offset: 180x100
        pane: reduce [palette-box lbl bd-canvas]
    ]

    view/no-wait bd-win
]

; ==============================================================================
; Ventana principal
; ==============================================================================

main-win: make face! [
    type: 'window
    text: "QTorres MVP v0.1"
    size: 500x180
    offset: 100x200
    color: 240.240.240
    pane: reduce [
        make face! [
            type: 'base  offset: 20x10  size: 300x28  color: 240.240.240
            draw: [pen navy text 0x0 "QTorres - Programacion Visual"]
        ]
        make face! [
            type: 'base  offset: 20x38  size: 300x18  color: 240.240.240
            draw: [pen gray text 0x0 "Entorno visual tipo LabVIEW sobre Red-Lang"]
        ]
        make face! [
            type: 'button  text: "Generar .qvi"
            offset: 20x70  size: 140x40
            actors: make object! [
                on-click: func [face event] [
                    next-id: 1
                    clear fp-items
                    clear bd-nodes
                    clear bd-wires
                    wire-src: none  wire-port: none  mouse-pos: none
                    bd-drag-node: none  bd-drag-off: none
                    fp-drag-item: none  fp-drag-off: none
                    if fp-win [unview/only fp-win  fp-win: none]
                    if bd-win [unview/only bd-win  bd-win: none]
                    open-front-panel
                    open-block-diagram
                ]
            ]
        ]
        make face! [
            type: 'button  text: "Guardar"
            offset: 180x70  size: 140x40
            actors: make object! [
                on-click: func [face event] [
                    either empty? fp-items [
                        print "Nada que guardar."
                    ][
                        ; Dialogo simple para nombre de fichero
                        save-name: none
                        save-dlg: make face! [
                            type: 'window
                            text: "Guardar como..."
                            size: 400x120
                            offset: 300x300
                            pane: reduce [
                                make face! [
                                    type: 'text  text: "Nombre del fichero (.qvi):"
                                    offset: 10x10  size: 380x20
                                ]
                                make face! [
                                    type: 'field  text: "mi-programa.qvi"
                                    offset: 10x35  size: 380x28
                                    actors: make object! [
                                        on-enter: func [face event] [
                                            save-name: face/text
                                            unview/only save-dlg
                                        ]
                                    ]
                                ]
                                make face! [
                                    type: 'button  text: "Guardar"
                                    offset: 150x75  size: 100x35
                                    actors: make object! [
                                        on-click: func [face event] [
                                            fld: save-dlg/pane/2
                                            save-name: fld/text
                                            unview/only save-dlg
                                        ]
                                    ]
                                ]
                            ]
                        ]
                        view/no-wait save-dlg
                        do-events
                        if save-name [
                            unless find save-name ".qvi" [
                                save-name: rejoin [save-name ".qvi"]
                            ]
                            fname: to-file save-name
                            result: compile-to-qvi fname
                            last-saved: fname
                            print rejoin ["Guardado: " result]
                        ]
                    ]
                ]
            ]
        ]
        make face! [
            type: 'base  offset: 20x125  size: 460x45  color: 240.240.240
            draw: [
                pen gray
                text 0x0  "1) Pulsa 'Generar .qvi' para abrir el editor"
                text 0x15 "2) Controles, indicadores, bloques y wires"
                text 0x30 "3) Guardar y luego Ejecutar"
            ]
        ]
        make face! [
            type: 'button  text: "Ejecutar .qvi"
            offset: 340x70  size: 140x40
            actors: make object! [
                on-click: func [face event] [
                    if empty? bd-nodes [
                        print "No hay diagrama para ejecutar."
                        return none
                    ]
                    print "Ejecutando diagrama..."
                    print "-----------------------------"

                    ; Construir tabla de valores: id -> valor
                    vals: copy []
                    foreach item fp-items [
                        if item/kind = 'control [
                            append vals item/id
                            append vals item/default
                        ]
                    ]

                    ; Ejecutar nodos operacion
                    foreach n bd-nodes [
                        if any [n/type = 'add  n/type = 'sub] [
                            va: 0.0  vb: 0.0
                            foreach w bd-wires [
                                if w/to-id = n/id [
                                    src-val: select vals w/from-id
                                    if src-val [
                                        either w/to-p = 'a [va: src-val] [vb: src-val]
                                    ]
                                ]
                            ]
                            res: either n/type = 'add [va + vb] [va - vb]
                            ; Guardar resultado
                            pos: find vals n/id
                            either pos [poke vals (1 + index? pos) res] [
                                append vals n/id
                                append vals res
                            ]
                            print rejoin [n/label ": " res]
                        ]
                    ]

                    ; Actualizar indicadores
                    foreach item fp-items [
                        if item/kind = 'indicator [
                            foreach w bd-wires [
                                if w/to-id = item/id [
                                    src-val: select vals w/from-id
                                    if src-val [
                                        item/default: src-val
                                        print rejoin [item/label ": " src-val]
                                    ]
                                ]
                            ]
                        ]
                    ]

                    print "-----------------------------"
                    print "Ejecucion completada."
                    ; Refrescar Front Panel para mostrar resultados
                    if fp-canvas [fp-canvas/draw: render-fp]
                ]
            ]
        ]
    ]
]

view main-win
