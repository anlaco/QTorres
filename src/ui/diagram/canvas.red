Red [
    Title:   "QTorres — Block Diagram Canvas"
    Purpose: "Canvas con bloques arrastrables (Fase 0 - Spike #1)"
    Needs:   'View
]

; ── Config ─────────────────────────────────────────────
bw: 120                             ; ancho de bloque
bh: 50                              ; alto de bloque

; ── Estado ─────────────────────────────────────────────
bd-nodes:   copy []
drag-node:  none
drag-off:   none

; ── ID generator ───────────────────────────────────────
next-id: 1
gen-id: does [n: next-id  next-id: next-id + 1  n]

; ── Color por tipo de nodo ─────────────────────────────
ncolor: func [t] [
    switch t [
        control   [135.190.240]
        indicator [240.220.100]
        add       [120.200.120]
        sub       [255.150.100]
    ]
]

; ── Render ─────────────────────────────────────────────
; Genera lista de primitivas Draw para todos los nodos.
render-bd: func [/local d c tl] [
    d: copy []
    foreach n bd-nodes [
        c: ncolor n/type
        append d compose [
            pen black  line-width 1  fill-pen (c)
            box (as-pair n/x n/y) (as-pair (n/x + bw) (n/y + bh)) 6
            fill-pen black
            text (as-pair (n/x + 10) (n/y + 13)) (n/label)
        ]
        tl: switch n/type [
            control   ["CTRL"]
            indicator ["IND"]
            add       ["ADD +"]
            sub       ["SUB -"]
        ]
        append d compose [
            text (as-pair (n/x + 10) (n/y + 28)) (tl)
        ]
    ]
    d
]

; ── Hit-test ───────────────────────────────────────────
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

; ── Canvas factory ─────────────────────────────────────
; Crea una face de tipo base con drag & drop de bloques.
make-canvas: func [w [integer!] h [integer!]] [
    make face! [
        type: 'base
        size: as-pair w h
        color: 245.245.240
        flags: [all-over]
        draw: render-bd
        actors: make object! [
            on-down: func [face event] [
                n: hit-node event/offset/x event/offset/y
                either n [
                    drag-node: n
                    drag-off: event/offset - as-pair n/x n/y
                ][
                    drag-node: none
                ]
            ]
            on-over: func [face event] [
                if all [drag-node drag-off event/down?] [
                    drag-node/x: event/offset/x - drag-off/x
                    drag-node/y: event/offset/y - drag-off/y
                    face/draw: render-bd
                ]
            ]
            on-up: func [face event] [
                drag-node: none
                drag-off:  none
            ]
        ]
    ]
]

; ══════════════════════════════════════════════════════════
; Demo standalone — ejecutar: red src/ui/diagram/canvas.red
; ══════════════════════════════════════════════════════════

; Nodos de ejemplo
append bd-nodes make object! [id: gen-id  type: 'control    label: "A"         x: 40   y: 60 ]
append bd-nodes make object! [id: gen-id  type: 'control    label: "B"         x: 40   y: 170]
append bd-nodes make object! [id: gen-id  type: 'add        label: "Add_3"     x: 250  y: 100]
append bd-nodes make object! [id: gen-id  type: 'sub        label: "Sub_4"     x: 250  y: 230]
append bd-nodes make object! [id: gen-id  type: 'indicator  label: "Resultado" x: 460  y: 100]
append bd-nodes make object! [id: gen-id  type: 'indicator  label: "Resta"     x: 460  y: 230]

canvas: make-canvas 700 480
canvas/offset: 10x38

view make face! [
    type: 'window
    text: "QTorres — Canvas Spike (Issue #1)"
    size: 720x540
    offset: 100x80
    pane: reduce [
        make face! [
            type: 'base  offset: 10x8  size: 700x25  color: 240.240.240
            draw: [pen gray text 5x5 "Arrastra los bloques por el canvas"]
        ]
        canvas
    ]
]
