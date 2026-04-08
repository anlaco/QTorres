Red [
    Title:   "QTorres — Front Panel"
    Purpose: "Panel de controles e indicadores (Issue #7)"
    Needs:   'View
]

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

render-fp-panel: func [model w h /local cmds item selected?] [
    cmds: copy []

    append cmds render-fp-grid w h

    foreach item model/front-panel [
        selected?: either model/selected-fp [same? item model/selected-fp] [false]
        append cmds render-fp-item item selected?
    ]

    cmds
]

; ══════════════════════════════════════════════════════════
; HIT TESTING — pure functions
; ══════════════════════════════════════════════════════════

; Devuelve [item 'label] | [item 'body] | none
; Itera al revés para que el elemento dibujado encima tenga prioridad.
hit-fp-zone: func [model mx my /local item lx ly lw bh] [
    foreach item (reverse copy model/front-panel) [
        ; Zona de label — misma fórmula que render
        if all [item/label  object? item/label  item/label/visible] [
            lx: item/offset/x
            ly: item/offset/y - fp-label-above
            if pair? item/label/offset [
                lx: lx + item/label/offset/x
                ly: ly + item/label/offset/y
            ]
            lw: max 30 (7 * length? any [item/label/text ""])
            if all [mx >= lx  mx <= (lx + lw)  my >= (ly - 2)  my <= (ly + 14)] [
                return reduce [item 'label]
            ]
        ]
        ; Zona de body
        bh: case [
            item/data-type = 'string   [fp-label-height]
            item/data-type = 'cluster  [fp-cluster-height item]
            item/data-type = 'waveform [fp-chart-height]
            true                       [fp-item-height]
        ]
        ; Ancho del body: waveform es más ancho
        bw: either item/data-type = 'waveform [fp-chart-width] [fp-item-width]
        if all [
            mx >= item/offset/x  mx <= (item/offset/x + bw)
            my >= item/offset/y  my <= (item/offset/y + bh)
        ] [return reduce [item 'body]]
    ]
    none
]

hit-fp-item: func [model mx my /local zone] [
    zone: hit-fp-zone model mx my
    either zone [zone/1] [none]
]

; ══════════════════════════════════════════════════════════
; EDITING — inline field for numeric editing
; ══════════════════════════════════════════════════════════
edit-dialog-item:  none
edit-dialog-panel: none
edit-dialog-model: none
edit-dialog-fval:  none

; Aplica valor string a un item del FP y refresca el panel.
fp-str-apply-and-refresh: func [itm txt pnl mdl] [
    itm/value: txt
    pnl/draw: render-fp-panel mdl mdl/size/x mdl/size/y
]

; Abre diálogo para editar el valor de un str-control en el FP.
; Usa compose/deep para capturar item, panel-face y model por valor (sin vars de módulo).
open-str-fp-edit-dialog: func [item panel-face model /local cur-val] [
    cur-val: any [item/value  ""]
    view/no-wait compose/deep [
        title "Editar string"
        text "Valor:" return
        field 200 (cur-val)
        on-enter [
            fp-str-apply-and-refresh (item) copy face/text (panel-face) (model)
            unview
        ]
        return
        button "OK" [
            foreach pf face/parent/pane [
                if pf/type = 'field [
                    fp-str-apply-and-refresh (item) copy pf/text (panel-face) (model)
                    break
                ]
            ]
            unview
        ]
        button "Cancelar" [unview]
    ]
]

; Aplica valor cluster (texto "campo: valor" por línea) a un item del FP y refresca.
fp-cluster-apply-and-refresh: func [itm txt pnl mdl /local lines result line parts k v ft] [
    lines: split txt "^/"
    result: copy []
    foreach line lines [
        line: trim line
        if empty? line [continue]
        parts: split line ":"
        if 2 > length? parts [continue]
        k: to-word trim parts/1
        v: trim parts/2
        ; Buscar tipo del campo en config
        ft: 'number
        foreach [fn ftype] fp-cluster-fields itm [
            if fn = k [ft: ftype]
        ]
        append result k
        append result case [
            ft = 'boolean [any [find [true yes on] to-word v  false]]
            ft = 'string  [v]
            true          [any [attempt [to-float v]  0.0]]
        ]
    ]
    itm/value: result
    pnl/draw: render-fp-panel mdl mdl/size/x mdl/size/y
]

; Construye texto "campo: valor" por línea desde item/value + config
fp-cluster-value-text: func [item /local lines fn ft fval] [
    lines: copy ""
    foreach [fn ft] fp-cluster-fields item [
        fval: select any [item/value  copy []] fn
        fval-str: either none? fval [""] [form fval]
        append lines rejoin [form fn ": " fval-str "^/"]
    ]
    trim lines
]

; Abre diálogo para editar los valores de un cluster-control en el FP.
open-cluster-fp-edit-dialog: func [item panel-face model /local cur-text] [
    cur-text: fp-cluster-value-text item
    view/no-wait compose/deep [
        title "Editar cluster"
        text "Campos (campo: valor por línea):" return
        area 220x120 (cur-text) return
        button "OK" [
            foreach pf face/parent/pane [
                if pf/type = 'area [
                    fp-cluster-apply-and-refresh (item) copy pf/text (panel-face) (model)
                    break
                ]
            ]
            unview
        ]
        button "Cancelar" [unview]
    ]
]

; Aplica valor array (texto separado por espacios) a un item del FP y refresca.
fp-arr-apply-and-refresh: func [itm txt pnl mdl /local parts nums v] [
    parts: split txt " "
    nums: copy []
    foreach p parts [
        v: attempt [to-float p]
        if v [append nums v]
    ]
    itm/value: nums
    pnl/draw: render-fp-panel mdl mdl/size/x mdl/size/y
]

; Abre diálogo para editar el valor de un arr-control en el FP.
open-arr-fp-edit-dialog: func [item panel-face model /local cur-val cur-text] [
    cur-val: any [item/value  copy []]
    cur-text: trim form cur-val
    view/no-wait compose/deep [
        title "Editar array"
        text "Valores (separados por espacios):" return
        field 250 (cur-text)
        on-enter [
            fp-arr-apply-and-refresh (item) copy face/text (panel-face) (model)
            unview
        ]
        return
        button "OK" [
            foreach pf face/parent/pane [
                if pf/type = 'field [
                    fp-arr-apply-and-refresh (item) copy pf/text (panel-face) (model)
                    break
                ]
            ]
            unview
        ]
        button "Cancelar" [unview]
    ]
]

open-edit-dialog: func [item panel-face model /local label-text default-text] [
    edit-dialog-item:  item
    edit-dialog-panel: panel-face
    edit-dialog-model: model
    edit-dialog-fval:  none

    label-text:   either all [item/label  object? item/label] [item/label/text] [form item/value]
    default-text: form item/value

    view/no-wait [
        title "Editar valor"
        text "Label:" return
        flabel: field 200 label-text
        return
        text "Valor:" return
        edit-dialog-fval: field 200 default-text
        return
        button "OK" [
            edit-dialog-item/value: attempt [to-float edit-dialog-fval/text]
            if none? edit-dialog-item/value [edit-dialog-item/value: edit-dialog-item/default]
            edit-dialog-panel/draw: render-fp-panel edit-dialog-model (edit-dialog-model/size/x) (edit-dialog-model/size/y)
            unview
        ]
        button "Cancelar" [unview]
    ]
]

; ══════════════════════════════════════════════════════════
; PALETA DEL FRONT PANEL — doble clic en espacio vacío
; ══════════════════════════════════════════════════════════
fp-palette-panel: none
fp-palette-x:     0
fp-palette-y:     0

fp-palette-add-item: func [item-type /local new-id item model w h _cref nid bd-y def-val spec] [
    model:  fp-palette-panel/extra
    w:      model/size/x
    h:      model/size/y
    new-id: 1 + length? model/front-panel
    def-val: case [
        find [bool-control bool-indicator]       item-type [false]
        find [str-control  str-indicator]        item-type [copy ""]
        find [arr-control  arr-indicator]        item-type [copy []]
        find [cluster-control cluster-indicator] item-type [copy []]
        find [waveform-chart waveform-graph]     item-type [copy []]
        true                                     [0.0]
    ]
    ; Construir spec con append/only para default: evitar splice de block! values
    spec: copy []
    repend spec [to-set-word 'id  new-id  to-set-word 'type  item-type
                 to-set-word 'name  rejoin [form item-type "_" new-id]]
    append spec to-set-word 'label
    append/only spec compose/deep [text: (fp-default-label item-type) visible: true]
    append spec to-set-word 'default
    either block? def-val [append/only spec def-val] [append spec def-val]
    repend spec [to-set-word 'offset  as-pair fp-palette-x fp-palette-y]
    item: make-fp-item spec
    append model/front-panel item
    fp-palette-panel/draw: render-fp-panel model w h
    show fp-palette-panel
    ; Sync BD: crear nodo correspondiente para todos los tipos FP
    _cref: select model 'canvas-ref
    if _cref [
        nid:  gen-node-id model
        bd-y: 20
        foreach _n model/nodes [
            if (_n/y + 80) > bd-y [bd-y: _n/y + 80]
        ]
        append model/nodes make-node compose [
            id:   (nid)
            type: (item-type)
            name: (item/name)
            x:    40
            y:    (bd-y)
        ]
        _cref/draw: render-bd model
        show _cref
    ]
    unview
]

open-fp-palette: func [face x y] [
    fp-palette-panel: face
    fp-palette-x:     x
    fp-palette-y:     y
    view/no-wait [
        title "Añadir al Front Panel"
        button 100 "Control"        [fp-palette-add-item 'control]        return
        button 100 "Indicator"      [fp-palette-add-item 'indicator]      return
        button 100 "Bool Control"   [fp-palette-add-item 'bool-control]   return
        button 100 "Bool Indicator" [fp-palette-add-item 'bool-indicator] return
        button 100 "Str Control"    [fp-palette-add-item 'str-control]    return
        button 100 "Str Indicator"  [fp-palette-add-item 'str-indicator]  return
        button 100 "Arr Control"      [fp-palette-add-item 'arr-control]      return
        button 100 "Arr Indicator"   [fp-palette-add-item 'arr-indicator]    return
        button 100 "Cluster Ctrl"    [fp-palette-add-item 'cluster-control]  return
        button 100 "Cluster Ind"     [fp-palette-add-item 'cluster-indicator] return
        button 100 "Waveform Chart"  [fp-palette-add-item 'waveform-chart]   return
        button 100 "Waveform Graph"  [fp-palette-add-item 'waveform-graph]   return
        button      "Cancelar"       [unview]
    ]
]

; ══════════════════════════════════════════════════════════
; CANVAS FACTORY — render-panel returns a functional face
; ══════════════════════════════════════════════════════════
; Model stored in face/extra includes: front-panel, selected-fp, drag-fp, drag-off, size

render-panel: func [model panel-width panel-height /local panel-face] [
    model/size: as-pair panel-width panel-height
    if none? select model 'drag-is-label [model/drag-is-label: false]

    panel-face: make face! [
        type:    'base
        size:    as-pair panel-width panel-height
        offset:  0x0
        color:   fp-canvas-color
        flags:   [all-over]
        extra:   model
        draw:    render-fp-panel model panel-width panel-height
        actors:  make object! [

            on-down: func [face event /local mouse-x mouse-y zone item w h lbl-dx lbl-dy] [
                mouse-x: event/offset/x
                mouse-y: event/offset/y
                w: face/extra/size/x
                h: face/extra/size/y
                zone: hit-fp-zone face/extra mouse-x mouse-y

                either zone [
                    item: zone/1
                    face/extra/selected-fp: item
                    face/extra/drag-fp:     item
                    either zone/2 = 'label [
                        face/extra/drag-is-label: true
                        lbl-dx: 0
                        lbl-dy: 0
                        if pair? item/label/offset [
                            lbl-dx: item/label/offset/x
                            lbl-dy: item/label/offset/y
                        ]
                        face/extra/drag-off: as-pair
                            (mouse-x - item/offset/x - lbl-dx)
                            (mouse-y - item/offset/y - lbl-dy + fp-label-above)
                    ][
                        face/extra/drag-is-label: false
                        face/extra/drag-off: as-pair (mouse-x - item/offset/x) (mouse-y - item/offset/y)
                    ]
                    face/draw: render-fp-panel face/extra w h
                ][
                    face/extra/selected-fp: none
                    face/draw: render-fp-panel face/extra w h
                ]
            ]

            on-over: func [face event /local mouse-x mouse-y w h item] [
                mouse-x: event/offset/x
                mouse-y: event/offset/y
                w: face/extra/size/x
                h: face/extra/size/y

                if all [face/extra/drag-fp  face/extra/drag-off  event/down?] [
                    item: face/extra/drag-fp
                    either face/extra/drag-is-label [
                        item/label/offset: as-pair
                            (mouse-x - face/extra/drag-off/x - item/offset/x)
                            (mouse-y - face/extra/drag-off/y - item/offset/y + fp-label-above)
                    ][
                        item/offset: as-pair
                            (mouse-x - face/extra/drag-off/x)
                            (mouse-y - face/extra/drag-off/y)
                    ]
                    face/draw: render-fp-panel face/extra w h
                ]
            ]

            on-up: func [face event] [
                face/extra/drag-fp:       none
                face/extra/drag-off:      none
                face/extra/drag-is-label: false
            ]

            on-click: func [face event /local mouse-x mouse-y hit w h] [
                mouse-x: event/offset/x
                mouse-y: event/offset/y
                w: face/extra/size/x
                h: face/extra/size/y
                hit: hit-fp-item face/extra mouse-x mouse-y
                case [
                    all [hit  hit/type = 'bool-control] [
                        ; Toggle booleano directo
                        hit/value: not hit/value
                        face/draw: render-fp-panel face/extra w h
                    ]
                    all [hit  hit/type = 'str-control] [
                        open-str-fp-edit-dialog hit face face/extra
                    ]
                    all [hit  hit/type = 'arr-control] [
                        open-arr-fp-edit-dialog hit face face/extra
                    ]
                    all [hit  find [cluster-control cluster-indicator] hit/type] [
                        open-cluster-fp-edit-dialog hit face face/extra
                    ]
                    all [hit  hit/type = 'control] [
                        open-edit-dialog hit face face/extra
                    ]
                ]
            ]

            on-dbl-click: func [face event /local mouse-x mouse-y hit] [
                mouse-x: event/offset/x
                mouse-y: event/offset/y
                hit: hit-fp-item face/extra mouse-x mouse-y

                case [
                    all [hit  hit/type = 'bool-control]    [
                        hit/value: not hit/value
                        face/draw: render-fp-panel face/extra face/extra/size/x face/extra/size/y
                    ]
                    all [hit  hit/type = 'str-control]     [open-str-fp-edit-dialog hit face face/extra]
                    all [hit  hit/type = 'arr-control]     [open-arr-fp-edit-dialog hit face face/extra]
                    all [hit  find [cluster-control cluster-indicator] hit/type] [open-cluster-fp-edit-dialog hit face face/extra]
                    all [hit  hit/type = 'control]          [open-edit-dialog hit face face/extra]
                    ; indicador: no hacer nada
                ]
            ]

            on-alt-down: func [face event /local mouse-x mouse-y] [
                mouse-x: event/offset/x
                mouse-y: event/offset/y
                open-fp-palette face mouse-x mouse-y
            ]

            on-key: func [face event /local model hit w h _cref bd-node] [
                model: face/extra
                hit: model/selected-fp
                w: model/size/x
                h: model/size/y

                if all [hit  any [find [delete backspace] event/key  find [#"^(7F)" #"^H"] event/key]] [
                    ; Sync BD: borrar nodo y sus wires
                    _cref: select model 'canvas-ref
                    if _cref [
                        bd-node: none
                        foreach n model/nodes [if n/name = hit/name [bd-node: n]]
                        if bd-node [
                            remove-each wire model/wires [any [wire/from-node = bd-node/id  wire/to-node = bd-node/id]]
                            remove-each n model/nodes   [n/name = hit/name]
                        ]
                        _cref/draw: render-bd model
                        show _cref
                    ]
                    remove-each item model/front-panel [item/id = hit/id]
                    model/selected-fp: none
                    face/draw: render-fp-panel model w h
                ]
            ]
        ]
    ]
    panel-face
]

; ══════════════════════════════════════════════════════════
; PARSER — load front-panel from qvi-diagram (Phase 3)
; ══════════════════════════════════════════════════════════
; save/load-panel-to-diagram movidas a file-io.red (4A)


; save-panel-to-diagram → file-io.red (4A)
; gen-panel-var-name, gen-indicator-var-name, compile-panel → compiler.red (4A)

; ══════════════════════════════════════════════════════════
; DEMO — standalone test
; ══════════════════════════════════════════════════════════
make-demo-model: func [] [
    make object! [
        front-panel:   copy []
        selected-fp:   none
        drag-fp:       none
        drag-off:      none
        drag-is-label: false
        size:          400x300
    ]
]

add-demo-items: func [model /local ctrl1 ctrl2 ind1] [
    ctrl1: make-fp-item compose [
        id: 1  type: 'control  name: "ctrl_1"
        label: [text: "A" visible: true]
        default: 5.0
        offset: 20x50
    ]
    ctrl2: make-fp-item compose [
        id: 2  type: 'control  name: "ctrl_2"
        label: [text: "B" visible: true]
        default: 3.0
        offset: 20x120
    ]
    ind1: make-fp-item compose [
        id: 3  type: 'indicator  name: "ind_1"
        label: [text: "Resultado" visible: true]
        default: 0.0
        offset: 20x190
    ]
    append model/front-panel ctrl1
    append model/front-panel ctrl2
    append model/front-panel ind1
    model
]

; gen-standalone-code → compiler.red (4A)

if find form system/options/script "panel.red" [
    ; Use same pattern as canvas.red for demo execution
    demo-model: make-demo-model
    add-demo-items demo-model

    panel: render-panel demo-model 400 300
    panel/offset: 10x38

    view make face! [
        type:   'window
        text:   "QTorres — Front Panel (Issue #7)"
        size:   420x540
        offset: 80x60
        pane:   reduce [
            make face! [
                type: 'base  offset: 10x8  size: 400x25  color: 200.203.212
                draw: compose [pen 60.70.90  text (as-pair 5 (15 + fp-text-dy)) "Drag items | dbl-click = edit value | Delete = remove"]
            ]
            panel
        ]
        actors: make object! [
            on-key: func [face event] [
                if any [
                    find [delete backspace] event/key
                    find [#"^(7F)" #"^H"] event/key
                ][
                    demo-model/selected-fp: none
                    remove-each item demo-model/front-panel [none? item]
                    panel/draw: render-fp-panel demo-model (demo-model/size/x) (demo-model/size/y)
                ]
            ]
        ]
    ]

    print ["Generated VID code:"]
    print mold compile-panel demo-model
]