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
fp-str-height:       24             ; altura del campo string (solo el body, sin label)
fp-label-above:      18             ; píxeles que el label va por encima del body
fp-run-button-height: 30

fp-color?: func [item-type] [
    either find [control bool-control str-control] item-type [fp-control-color] [fp-indicator-color]
]

fp-border-color?: func [item-type] [
    either find [control bool-control str-control] item-type [fp-control-color - 20.20.20] [fp-indicator-color - 20.20.20]
]

fp-type-label?: func [item-type] [
    case [
        item-type = 'control        ["DBL"]
        item-type = 'indicator      ["DBL"]
        item-type = 'bool-control   ["TF"]
        item-type = 'bool-indicator ["TF"]
        item-type = 'str-control    ["STR"]
        item-type = 'str-indicator  ["STR"]
        true                        [uppercase form item-type]
    ]
]

; ══════════════════════════════════════════════════════════
; FP-ITEM — Constructor following DT-022/023 pattern
; ══════════════════════════════════════════════════════════
fp-default-label: func [item-type] [
    case [
        item-type = 'bool-control   ["Boolean"]
        item-type = 'bool-indicator ["Boolean"]
        item-type = 'str-control    ["String"]
        item-type = 'str-indicator  ["String"]
        true                        ["Numeric"]
    ]
]

make-fp-item: func [
    "Crea un item del Front Panel (control o indicator)"
    spec [block!]
    /local item lbl-spec raw-type
][
    raw-type: any [select spec 'type  'control]
    item: make object! [
        id:        any [select spec 'id        0]
        type:      either find [bool-control bool-indicator] raw-type ['control] [raw-type]
        data-type: case [
            find [bool-control bool-indicator] raw-type ['boolean]
            find [str-control  str-indicator]  raw-type ['string]
            true                               ['numeric]
        ]
        name:      any [select spec 'name      ""]
        label:     none
        default:   case [
            find [bool-control bool-indicator] raw-type [
                any [select spec 'default  false]
            ]
            find [str-control str-indicator] raw-type [
                ; copy siempre: las literales "" en Red son constantes compartidas
                copy any [select spec 'default  ""]
            ]
            true [
                any [select spec 'default  0.0]
            ]
        ]
        value:     none
        offset:    any [select spec 'offset    0x0]
    ]
    item/type: raw-type
    ; copy para strings: garantiza que control e indicador son objetos independientes
    item/value: case [
        find [str-control str-indicator] raw-type [
            copy any [select spec 'value  item/default]
        ]
        true [
            any [select spec 'value  item/default]
        ]
    ]

    ; Name: usar explícito, o generar automáticamente
    item/name: any [select spec 'name  rejoin [form item/type "_" item/id]]

    ; Offset: usar explícito o default
    item/offset: any [select spec 'offset  0x0]

    ; Label: acepta bloque [text: "..." ...] o string
    ; label/offset = DELTA desde la posición por defecto.
    ; Por defecto 0x0: label aparece fp-label-above px encima del body.
    ; La posición real se calcula en render: (item/offset/x + delta/x, item/offset/y - fp-label-above + delta/y)
    lbl-spec: select spec 'label
    item/label: case [
        block? lbl-spec [
            lbl-spec: copy lbl-spec
            if none? select lbl-spec 'text [
                append lbl-spec compose [text: (fp-default-label item/type)]
            ]
            if none? select lbl-spec 'visible [
                append lbl-spec compose [visible: true]
            ]
            make object! [
                text:    any [select lbl-spec 'text    ""]
                visible: any [select lbl-spec 'visible true]
                offset:  any [select lbl-spec 'offset  0x0]
            ]
        ]
        string? lbl-spec [
            make object! [
                text:    lbl-spec
                visible: true
                offset:  0x0
            ]
        ]
        true [
            make object! [
                text:    fp-default-label item/type
                visible: true
                offset:  0x0
            ]
        ]
    ]

    item
]

fp-value-text: func [item] [
    form item/value
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

render-fp-item: func [item selected? /local cmds col border-col type-lbl led-col cx cy lx ly bh] [
    cmds: copy []

    ; ── Label externa ────────────────────────────────────────────────────────────────────
    ; Posición = item/offset + delta - fp-label-above en Y. Cálculo explícito de enteros.
    if all [item/label  object? item/label  item/label/visible] [
        lx: item/offset/x + item/label/offset/x
        ly: item/offset/y + item/label/offset/y - fp-label-above
        append cmds compose [
            pen off  fill-pen 30.30.30
            text (as-pair lx ly) (item/label/text)
        ]
    ]

    ; ── Body ────────────────────────────────────────────────────────────────────────────
    either item/data-type = 'string [
        ; String: campo blanco a partir de item/offset
        either item/type = 'str-control [
            append cmds compose [
                pen 80.80.80  line-width 1  fill-pen 255.255.255
                box (as-pair item/offset/x item/offset/y)
                   (as-pair (item/offset/x + fp-item-width) (item/offset/y + fp-str-height)) 2
            ]
        ][
            append cmds compose [
                pen 80.80.80  line-width 2  fill-pen 245.245.245
                box (as-pair item/offset/x item/offset/y)
                   (as-pair (item/offset/x + fp-item-width) (item/offset/y + fp-str-height)) 2
            ]
        ]
        append cmds compose [
            fill-pen 20.20.20  pen off
            text (as-pair (item/offset/x + 4) (item/offset/y + 5)) (fp-value-text item)
        ]
    ][
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
            fill-pen 220.230.240  pen off
            text (as-pair (item/offset/x + 4) (item/offset/y + 5)) (type-lbl)
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
                fill-pen 255.255.255  pen off
                text (as-pair (item/offset/x + 4) (item/offset/y + fp-item-height - 14))
                     (fp-value-text item)
            ]
        ]
    ]

    ; ── Selección: marco alrededor del body ─────────────────────────────────────────────
    bh: either item/data-type = 'string [fp-str-height] [fp-item-height]
    if selected? [
        append cmds compose [
            pen (fp-selected-color)  line-width 2  fill-pen off
            box (as-pair (item/offset/x - 3) (item/offset/y - 3))
               (as-pair (item/offset/x + fp-item-width + 3) (item/offset/y + bh + 3)) 6
            line-width 1
        ]
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
            lx: item/offset/x + item/label/offset/x
            ly: item/offset/y + item/label/offset/y - fp-label-above
            lw: max 30 (7 * length? any [item/label/text ""])
            if all [mx >= lx  mx <= (lx + lw)  my >= (ly - 2)  my <= (ly + 14)] [
                return reduce [item 'label]
            ]
        ]
        ; Zona de body
        bh: either item/data-type = 'string [fp-str-height] [fp-item-height]
        if all [
            mx >= item/offset/x  mx <= (item/offset/x + fp-item-width)
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

fp-palette-add-item: func [item-type /local new-id item model w h _cref nid bd-y] [
    model:  fp-palette-panel/extra
    w:      model/size/x
    h:      model/size/y
    new-id: 1 + length? model/front-panel
    item: make-fp-item compose/deep [
        id:      (new-id)
        type:    (item-type)
        name:    (rejoin [form item-type "_" new-id])
        label:   [text: (fp-default-label item-type) visible: true]
        default: (case [
            find [bool-control bool-indicator] item-type [false]
            find [str-control  str-indicator]  item-type [copy ""]
            true                               [0.0]
        ])
        offset:  (as-pair fp-palette-x fp-palette-y)
    ]
    append model/front-panel item
    fp-palette-panel/draw: render-fp-panel model w h
    show fp-palette-panel
    ; Sync BD: crear nodo correspondiente
    _cref: select model 'canvas-ref
    if _cref [
        nid:  gen-node-id model
        bd-y: 20 + ((length? model/nodes) * 75)
        append model/nodes make-node compose [
            id:   (nid)
            type: (item-type)
            name: (item/name)
            x:    20
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
        button      "Cancelar"      [unview]
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

            on-down: func [face event /local mx my zone item w h] [
                mx: event/offset/x
                my: event/offset/y
                w: face/extra/size/x
                h: face/extra/size/y
                zone: hit-fp-zone face/extra mx my

                either zone [
                    item: zone/1
                    face/extra/selected-fp: item
                    face/extra/drag-fp:     item
                    either zone/2 = 'label [
                        ; Arrastrar solo la label
                        ; drag-off = distancia del ratón a la posición absoluta del label
                        face/extra/drag-is-label: true
                        face/extra/drag-off: as-pair
                            (mx - item/offset/x - item/label/offset/x)
                            (my - item/offset/y - item/label/offset/y + fp-label-above)
                    ][
                        ; Arrastrar el body — label sigue automáticamente (recalcula en render)
                        face/extra/drag-is-label: false
                        face/extra/drag-off: as-pair (mx - item/offset/x) (my - item/offset/y)
                    ]
                    face/draw: render-fp-panel face/extra w h
                ][
                    face/extra/selected-fp: none
                    face/draw: render-fp-panel face/extra w h
                ]
            ]

            on-over: func [face event /local mx my w h item] [
                mx: event/offset/x
                my: event/offset/y
                w: face/extra/size/x
                h: face/extra/size/y

                if all [face/extra/drag-fp  face/extra/drag-off  event/down?] [
                    item: face/extra/drag-fp
                    either face/extra/drag-is-label [
                        ; Solo mueve el label: recalcula el delta respecto al body
                        item/label/offset: as-pair
                            (mx - face/extra/drag-off/x - item/offset/x)
                            (my - face/extra/drag-off/y - item/offset/y + fp-label-above)
                    ][
                        ; Mueve el body — label sigue automáticamente en render
                        item/offset: as-pair
                            (mx - face/extra/drag-off/x)
                            (my - face/extra/drag-off/y)
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
                    all [hit  hit/type = 'bool-control]  [
                        hit/value: not hit/value
                        face/draw: render-fp-panel face/extra face/extra/size/x face/extra/size/y
                    ]
                    all [hit  hit/type = 'str-control]   [open-str-fp-edit-dialog hit face face/extra]
                    all [hit  hit/type = 'control]        [open-edit-dialog hit face face/extra]
                    none? hit                              [open-fp-palette face mouse-x mouse-y]
                    ; indicador: no hacer nada
                ]
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
load-panel-from-diagram: func [diagram-block /local fp-block fp-item-spec result item offset-y kw] [
    result: copy []
    fp-block: select diagram-block 'front-panel

    unless none? fp-block [
        offset-y: 20
        parse fp-block [
            any [
                set kw ['control | 'indicator | 'bool-control | 'bool-indicator | 'str-control | 'str-indicator]
                set fp-item-spec block! (
                    item: make-fp-item fp-item-spec
                    item/type:      kw
                    item/data-type: case [
                        find [bool-control bool-indicator] kw ['boolean]
                        find [str-control  str-indicator]  kw ['string]
                        true                               ['numeric]
                    ]
                    if all [zero? item/offset/x  zero? item/offset/y] [
                        item/offset: as-pair 20 offset-y
                        offset-y: offset-y + fp-item-height + 10
                    ]
                    append result item
                )
            ]
        ]
    ]
    result
]

; ══════════════════════════════════════════════════════════
; PERSISTENCE — save front-panel to qvi-diagram format (Phase 4)
; ══════════════════════════════════════════════════════════
save-panel-to-diagram: func [front-panel-items /local items item kw spec] [
    ; Todos los items van en UN único bloque: [front-panel: [control [...] indicator [...]]]
    ; Si se generan bloques separados, select solo devuelve el primero al cargar.
    items: copy []
    foreach item front-panel-items [
        kw:   case [
            item/type = 'control        ['control]
            item/type = 'bool-control   ['bool-control]
            item/type = 'bool-indicator ['bool-indicator]
            item/type = 'str-control    ['str-control]
            item/type = 'str-indicator  ['str-indicator]
            true                        ['indicator]
        ]
        spec: compose/deep [
            id: (item/id)
            type: (item/type)
            name: (item/name)
            label: [text: (item/label/text) visible: (item/label/visible) offset: (item/label/offset)]
            default: (item/default)
            offset: (item/offset)
        ]
        append items kw
        append/only items spec
    ]
    reduce [to-set-word 'front-panel  items]
]

; ══════════════════════════════════════════════════════════
; COMPILE PANEL — generate VID layout for .qvi executable (Phase 5)
; ══════════════════════════════════════════════════════════
gen-panel-var-name: func [item /local s fc] [
    s: copy item/name
    if not empty? s [
        fc: uppercase copy/part s 1
        s: rejoin [fc  skip s 1]
    ]
    to-word rejoin ["f" s]
]

gen-indicator-var-name: func [item /local s fc] [
    s: copy item/name
    if not empty? s [
        fc: uppercase copy/part s 1
        s: rejoin [fc  skip s 1]
    ]
    to-word rejoin ["l" s]
]

compile-panel: func [model /local cmds item ctrl-field-name ind-var-name] [
    cmds: copy []

    foreach item model/front-panel [
        case [
            find [control str-control] item/type [
                ctrl-field-name: gen-panel-var-name item
                append cmds compose [
                    label (item/label/text)
                    (to-set-word ctrl-field-name) field 120 (form item/default)
                    return
                ]
            ]
            item/type = 'bool-control [
                ctrl-field-name: gen-panel-var-name item
                append cmds compose [
                    label (item/label/text)
                    (to-set-word ctrl-field-name) check (item/label/text) (item/default)
                    return
                ]
            ]
            true [  ; indicator, bool-indicator, str-indicator
                ind-var-name: gen-indicator-var-name item
                append cmds compose [
                    label (item/label/text)
                    (to-set-word ind-var-name) text 120 (form item/default)
                    return
                ]
            ]
        ]
    ]

    append cmds compose [button "Run" []]
    cmds
]

; ══════════════════════════════════════════════════════════
; DEMO — standalone test
; ══════════════════════════════════════════════════════════
make-demo-model: func [] [
    make object! [
        front-panel:  copy []
        selected-fp:  none
        drag-fp:      none
        drag-off:     none
        drag-is-label: false
        size:         400x300
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

gen-standalone-code: func [model /local vid-code] [
    vid-code: compile-panel model
    rejoin [
        "Red [title: {QTorres Panel Demo} Needs: 'View]" newline
        "qvi-diagram: []" newline
        "view layout [" newline
        "    " mold vid-code newline
        "]"
    ]
]

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
                draw: [pen 60.70.90  text 5x15 "Drag items | dbl-click = edit value | Delete = remove"]
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