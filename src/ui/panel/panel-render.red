Red [
    Title:   "QTorres — panel-render"
    Purpose: "Render puro del Front Panel: constantes visuales, helpers de tipo y Draw."
    Needs:   'View
]

; ── panel-render.red ──────────────────────────────────────────────
; Render puro del Front Panel. Incluido desde panel.red.
; No contiene estado mutable ni side-effects de UI.
; ──────────────────────────────────────────────────────────────────

; ══════════════════════════════════════════════════════════
; CONSTANTS — visual configuration
; ══════════════════════════════════════════════════════════
fp-canvas-color:     225.228.235
fp-control-color:    50.100.180
fp-indicator-color:  175.125.20
fp-text-color:       240.245.250
fp-selected-color:   0.175.210
fp-border-color:     30.60.120
fp-item-width:       120
fp-item-height:      40
fp-label-height:     20
fp-label-above:      18
fp-run-button-height: 30

; Waveform dimensions (área de trazado)
fp-chart-width:      200
fp-chart-height:     160

; GTK-010: en Linux/GTK, Draw text usa baseline como Y en vez de top-left.
; Compensamos añadiendo fp-text-dy a todas las coordenadas Y de texto.
fp-text-dy: either system/platform = 'Linux [8] [0]

fp-color?: func [item-type] [
    either find [control bool-control str-control arr-control cluster-control] item-type [fp-control-color] [fp-indicator-color]
]

fp-border-color?: func [item-type] [
    either find [control bool-control str-control arr-control cluster-control] item-type [fp-control-color - 20.20.20] [fp-indicator-color - 20.20.20]
]

; fp-cluster-fields → model.red (4A)

fp-cluster-height: func [item /local n] [
    n: (length? fp-cluster-fields item) / 2
    20 + (max 1 n) * 20
]

fp-type-label?: func [item-type] [
    case [
        item-type = 'control        ["DBL"]
        item-type = 'indicator      ["DBL"]
        item-type = 'bool-control   ["TF"]
        item-type = 'bool-indicator ["TF"]
        item-type = 'str-control    ["STR"]
        item-type = 'str-indicator  ["STR"]
        item-type = 'arr-control      ["ARR"]
        item-type = 'arr-indicator    ["ARR"]
        item-type = 'cluster-control  ["CLU"]
        item-type = 'cluster-indicator ["CLU"]
        item-type = 'waveform-chart   ["CHART"]
        item-type = 'waveform-graph   ["GRAPH"]
        true                          [uppercase form item-type]
    ]
]

; ══════════════════════════════════════════════════════════
; FP-ITEM — Constructor following DT-022/023 pattern
; ══════════════════════════════════════════════════════════
; fp-default-label → model.red (4A)

; make-fp-item → model.red (4A)

fp-value-text: func [item] [
    either block? item/value [
        rejoin ["[" form item/value "]"]
    ][
        form item/value
    ]
]

; ══════════════════════════════════════════════════════════
; RENDER DRAW — pure functions, receive model, return Draw block
; ══════════════════════════════════════════════════════════
render-fp-grid: func [w h /local cmds gx gy] [
    cmds: compose [pen 200.203.212  fill-pen 200.203.212  line-width 1]
    gx: 20
    while [gx < w] [
        gy: 20
        while [gy < h] [
            append cmds compose [circle (as-pair gx gy) 1]
            gy: gy + 20
        ]
        gx: gx + 20
    ]
    cmds
]

; Genera segmentos de línea discontinua a lo largo de un rectángulo
dashed-box: func [x1 y1 x2 y2 dash gap /local cmds pos lim step] [
    cmds: copy []
    pos: x1  lim: x2
    while [pos < lim] [
        step: min dash (lim - pos)
        append cmds compose [line (as-pair pos y1) (as-pair (pos + step) y1)]
        pos: pos + dash + gap
    ]
    pos: y1  lim: y2
    while [pos < lim] [
        step: min dash (lim - pos)
        append cmds compose [line (as-pair x2 pos) (as-pair x2 (pos + step))]
        pos: pos + dash + gap
    ]
    pos: x2  lim: x1
    while [pos > lim] [
        step: min dash (pos - lim)
        append cmds compose [line (as-pair pos y2) (as-pair (pos - step) y2)]
        pos: pos - dash - gap
    ]
    pos: y2  lim: y1
    while [pos > lim] [
        step: min dash (pos - lim)
        append cmds compose [line (as-pair x1 pos) (as-pair x1 (pos - step))]
        pos: pos - dash - gap
    ]
    cmds
]

; ══════════════════════════════════════════════════════════
; RENDER WAVEFORM — Draw signal plot
; ══════════════════════════════════════════════════════════

render-waveform: func [item selected? /local cmds w h values min-y max-y y-range x-scale y-scale pts i v px py] [
    ; Dimensiones del área de trazado
    w: fp-chart-width
    h: fp-chart-height
    cmds: copy []

    ; Fondo negro (plot area estilo osciloscopio)
    append cmds compose [
        pen 60.60.60  line-width 1  fill-pen 15.15.15
        box (as-pair item/offset/x item/offset/y)
           (as-pair (item/offset/x + w) (item/offset/y + h)) 3
    ]

    ; Grid opcional: líneas grises cada 20% del área
    append cmds [pen 40.40.40  line-width 1]
    ; Líneas verticales
    repeat i 4 [
        px: item/offset/x + (w * i / 5)
        append cmds compose [line (as-pair px item/offset/y) (as-pair px (item/offset/y + h))]
    ]
    ; Líneas horizontales
    repeat i 4 [
        py: item/offset/y + (h * i / 5)
        append cmds compose [line (as-pair item/offset/x py) (as-pair (item/offset/x + w) py)]
    ]

    ; Línea de señal (verde estilo osciloscopio)
    values: any [item/value  copy []]
    ; Debug: verificar que values es un block
    unless block? values [values: copy []]
    ; Filtrar solo valores numéricos
    values: copy values
    remove-each v values [not number? v]

    if not empty? values [
        ; Calcular escala automática
        ; Compute min and max manually (Red 0.6.6 lacks min-of/max-of)
        min-y: first values
        foreach v values [if v < min-y [min-y: v]]
        max-y: first values
        foreach v values [if v > max-y [max-y: v]]

        ; Evitar división por cero y dar margen
        y-range: max-y - min-y
        if y-range = 0 [y-range: 1]
        ; Margen 10% arriba y abajo
        min-y: min-y - (y-range * 0.1)
        max-y: max-y + (y-range * 0.1)
        y-range: max-y - min-y

        ; Escalar valores al área (dejando 10px margen)
        y-scale: (h - 20) / y-range
        x-scale: either (length? values) > 1 [
            (w - 20) / ((length? values) - 1)
        ][
            w - 20  ; un solo punto: centrar
        ]

        ; Generar puntos de la línea
        pts: copy []
        i: 0
        foreach v values [
            px: item/offset/x + 10 + to-integer (i * x-scale)
            py: item/offset/y + h - 10 - to-integer ((v - min-y) * y-scale)
            append pts as-pair px py
            i: i + 1
        ]

        ; Dibujar línea verde (line necesita >= 2 puntos en Draw)
        either (length? pts) >= 2 [
            append cmds [pen 0.200.0  line-width 1]
            line-cmd: copy [line]
            append line-cmd pts
            append cmds line-cmd
        ][
            ; Un solo punto: dibujar círculo pequeño
            append cmds compose [pen 0.200.0  fill-pen 0.200.0  circle (first pts) 2]
        ]
    ]

    ; Label del tipo (esquina superior izquierda)
    type-lbl: fp-type-label? item/type
    append cmds compose [
        pen 150.150.150
        text (as-pair (item/offset/x + 4) (item/offset/y + 4 + fp-text-dy)) (type-lbl)
    ]

    ; Número de puntos (esquina superior derecha)
    append cmds compose [
        pen 150.150.150
        text (as-pair (item/offset/x + w - 40) (item/offset/y + 4 + fp-text-dy))
             (rejoin ["n=" length? any [item/value  copy []]])
    ]

    ; Selección: marco rallado
    if selected? [
        append cmds compose [
            pen (fp-selected-color)
            line-width 2
            fill-pen off
        ]
        append cmds dashed-box
            (item/offset/x - 3) (item/offset/y - 3)
            (item/offset/x + w + 3) (item/offset/y + h + 3)
            6 4
        append cmds [line-width 1]
    ]

    cmds
]

render-fp-item: func [item selected? /local cmds col border-col type-lbl led-col cx cy field-y field-h lx ly lw bh fy fn ft fval fval-str] [
    cmds: copy []
    ; Reset estado Draw — pen 0.0.0 es crítico: evita bleed de color de texto
    append cmds [pen 0.0.0  fill-pen off  line-width 1]

    ; ── Label encima del body (todos los tipos) ───────────────────────────────────────────
    if all [item/label  object? item/label  item/label/visible] [
        lx: item/offset/x
        ly: item/offset/y - fp-label-above
        if pair? item/label/offset [
            lx: lx + item/label/offset/x
            ly: ly + item/label/offset/y
        ]
        append cmds compose [
            text (as-pair lx (ly + fp-text-dy)) (any [item/label/text ""])
        ]
    ]

    ; ── Body ─────────────────────────────────────────────────────────────────────────────
    case [
        item/data-type = 'string [
        ; String: campo blanco a partir de item/offset
        either item/type = 'str-control [
            append cmds compose [
                pen 80.80.80  line-width 1  fill-pen 255.255.255
                box (as-pair item/offset/x item/offset/y)
                   (as-pair (item/offset/x + fp-item-width) (item/offset/y + fp-label-height)) 2
            ]
        ][
            append cmds compose [
                pen 80.80.80  line-width 2  fill-pen 245.245.245
                box (as-pair item/offset/x item/offset/y)
                   (as-pair (item/offset/x + fp-item-width) (item/offset/y + fp-label-height)) 2
            ]
        ]
        append cmds compose [
            pen 20.20.20  fill-pen off
            text (as-pair (item/offset/x + 4) (item/offset/y + 4 + fp-text-dy)) (fp-value-text item)
        ]
    ]
        item/data-type = 'cluster [
        ; Cluster: caja marrón con campos internos
        border-col: 100.50.10
        col: either item/type = 'cluster-control [159.89.39] [139.69.19]
        bh: fp-cluster-height item
        append cmds compose [
            pen (border-col)  line-width 2  fill-pen (col)
            box (as-pair item/offset/x item/offset/y)
               (as-pair (item/offset/x + fp-item-width) (item/offset/y + bh)) 3
            pen 220.190.160  fill-pen off
            text (as-pair (item/offset/x + 4) (item/offset/y + 4 + fp-text-dy)) "CLU"
        ]
        fy: item/offset/y + 20
        foreach [fn ft] fp-cluster-fields item [
            fval: select any [item/value  copy []] fn
            fval-str: either none? fval [""] [form fval]
            append cmds compose [
                pen 240.220.200  fill-pen off
                text (as-pair (item/offset/x + 4) (fy + fp-text-dy)) (rejoin [form fn ": " fval-str])
            ]
            fy: fy + 20
        ]
    ]
        item/data-type = 'array [
        ; Array: caja de color con borde doble + valor como texto
        col: fp-color? item/type
        border-col: fp-border-color? item/type
        ; Borde exterior
        append cmds compose [
            pen (border-col)  line-width 3  fill-pen (col)
            box (as-pair item/offset/x item/offset/y)
               (as-pair (item/offset/x + fp-item-width) (item/offset/y + fp-item-height)) 4
        ]
        ; Borde interior (doble)
        append cmds compose [
            pen (col + 20.20.20)  line-width 1  fill-pen off
            box (as-pair (item/offset/x + 4) (item/offset/y + 4))
               (as-pair (item/offset/x + fp-item-width - 4) (item/offset/y + fp-item-height - 4)) 3
        ]
        append cmds compose [
            pen 220.230.240  fill-pen off
            text (as-pair (item/offset/x + 4) (item/offset/y + 5 + fp-text-dy)) "ARR"
        ]
        append cmds compose [
            pen 255.255.255  fill-pen off
            text (as-pair (item/offset/x + 4) (item/offset/y + fp-item-height - 14 + fp-text-dy))
                 (fp-value-text item)
        ]
    ]
        item/data-type = 'waveform [
        ; Waveform: renderiza gráfico estilo osciloscopio
        append cmds render-waveform item selected?
    ]
        true [
        ; Numeric / Boolean: caja de color
        col: fp-color? item/type
        border-col: fp-border-color? item/type
        append cmds compose [
            pen (border-col)  line-width 1  fill-pen (col)
            box (as-pair item/offset/x item/offset/y)
               (as-pair (item/offset/x + fp-item-width) (item/offset/y + fp-item-height)) 4
        ]
        type-lbl: fp-type-label? item/type
        append cmds compose [
            pen 220.230.240  fill-pen off
            text (as-pair (item/offset/x + 4) (item/offset/y + 5 + fp-text-dy)) (type-lbl)
        ]
        either item/data-type = 'boolean [
            led-col: either item/value [0.180.0] [180.0.0]
            cx: item/offset/x + fp-item-width - 20
            cy: item/offset/y + (fp-item-height / 2)
            append cmds compose [
                pen (led-col - 40.40.40)  line-width 1  fill-pen (led-col)
                circle (as-pair cx cy) 10
            ]
        ][
            append cmds compose [
                pen 255.255.255  fill-pen off
                text (as-pair (item/offset/x + 4) (item/offset/y + fp-item-height - 14 + fp-text-dy))
                     (fp-value-text item)
            ]
        ]
    ]
    ]  ; end case

    ; ── Selección: marcos rallados en body y label ────────────────────────────────────────
    bh: case [
        item/data-type = 'string   [fp-label-height]
        item/data-type = 'cluster  [fp-cluster-height item]
        item/data-type = 'waveform [fp-chart-height]
        true                       [fp-item-height]
    ]
    if selected? [
        append cmds compose [pen (fp-selected-color)  line-width 2  fill-pen off]
        append cmds dashed-box
            (item/offset/x - 3) (item/offset/y - 3)
            (item/offset/x + fp-item-width + 3) (item/offset/y + bh + 3)
            6 4
        if all [item/label  object? item/label  item/label/visible] [
            lx: item/offset/x
            ly: item/offset/y - fp-label-above
            if pair? item/label/offset [
                lx: lx + item/label/offset/x
                ly: ly + item/label/offset/y
            ]
            lw: max 30 (7 * length? any [item/label/text ""])
            append cmds compose [pen (fp-selected-color)  line-width 1  fill-pen off]
            append cmds dashed-box (lx - 2) (ly - 2) (lx + lw + 2) (ly + 15) 4 3
        ]
        append cmds [line-width 1]
    ]
    cmds
]

fp-content-bounds: func [model /local cy] [
    cy: 400
    foreach _item model/front-panel [
        cy: max cy (_item/offset/y + fp-item-height + fp-label-above + 20)
    ]
    as-pair 0 cy   ; FP solo tiene scroll vertical por ahora
]

render-fp-panel: func [model w h /local cmds item selected? sx sy sb-w _cy _th _ty] [
    cmds: copy []

    sx: any [model/fp-scroll-x  0]
    sy: any [model/fp-scroll-y  0]

    ; Viewport: translate por scroll — Red/View clipea automáticamente a los bounds del face
    append cmds compose [translate (as-pair (negate sx) (negate sy))]

    append cmds render-fp-grid (sx + w + 20) (sy + h + 20)

    foreach item model/front-panel [
        selected?: either model/selected-fp [same? item model/selected-fp] [false]
        append cmds render-fp-item item selected?
    ]

    ; Volver a coords de pantalla para scrollbars
    append cmds [reset-matrix]

    ; Bounding-box del contenido FP
    _cy: h
    foreach _item model/front-panel [
        _cy: max _cy (_item/offset/y + fp-item-height + fp-label-above + 20)
    ]
    sb-w: 8
    if _cy > h [
        _th: max 20 to-integer (h * h / _cy)
        _ty: to-integer (sy * (h - _th - sb-w) / (_cy - h))
        append cmds compose [
            fill-pen 210.212.218  pen off
            box (as-pair (w - sb-w) 0) (as-pair w (h - sb-w))
            fill-pen 150.152.162  pen off
            box (as-pair (w - sb-w) (_ty)) (as-pair w (_ty + _th))
        ]
    ]

    cmds
]

