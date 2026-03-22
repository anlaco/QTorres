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
fp-run-button-height: 30

fp-color?: func [item-type] [
    either find [control bool-control] item-type [fp-control-color] [fp-indicator-color]
]

fp-border-color?: func [item-type] [
    either find [control bool-control] item-type [fp-control-color - 20.20.20] [fp-indicator-color - 20.20.20]
]

fp-type-label?: func [item-type] [
    case [
        item-type = 'control        ["CTRL"]
        item-type = 'indicator      ["IND"]
        item-type = 'bool-control   ["B-CTRL"]
        item-type = 'bool-indicator ["B-IND"]
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
        data-type: either find [bool-control bool-indicator] raw-type ['boolean] ['numeric]
        name:      any [select spec 'name      ""]
        label:     none
        default:   any [select spec 'default   either find [bool-control bool-indicator] raw-type [false] [0.0]]
        value:     none
        offset:    any [select spec 'offset    0x0]
    ]
    item/type: raw-type
    item/value: any [select spec 'value  item/default]

    ; Name: usar explícito, o generar automáticamente
    item/name: any [select spec 'name  rejoin [form item/type "_" item/id]]

    ; Label: acepta bloque [text: "..." ...] o string
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

    ; Offset: usar explícito o default
    item/offset: any [select spec 'offset  0x0]

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

render-fp-item: func [item selected? /local cmds col border-col type-lbl text-x text-y led-col cx cy] [
    cmds: copy []
    col: fp-color? item/type
    border-col: fp-border-color? item/type

    append cmds compose [
        pen (border-col)  line-width 1  fill-pen (col)
        box (as-pair item/offset/x item/offset/y)
           (as-pair (item/offset/x + fp-item-width) (item/offset/y + fp-item-height)) 4
    ]

    type-lbl: fp-type-label? item/type
    text-x: item/offset/x + 8
    text-y: item/offset/y + 14

    either all [item/label  object? item/label  item/label/visible] [
        append cmds compose [
            fill-pen 220.230.240
            text (as-pair text-x (text-y - 8)) (any [item/label/text ""])
            fill-pen 180.190.200
            text (as-pair text-x (text-y + 8)) (any [type-lbl ""])
        ]
    ][
        append cmds compose [
            fill-pen 220.230.240
            text (as-pair text-x text-y) (any [type-lbl ""])
        ]
    ]

    either item/data-type = 'boolean [
        ; LED: círculo verde (true) o rojo (false)
        led-col: either item/value [0.180.0] [180.0.0]
        cx: item/offset/x + fp-item-width - 20
        cy: item/offset/y + fp-item-height / 2
        append cmds compose [
            pen (led-col - 40.40.40)  line-width 1  fill-pen (led-col)
            circle (as-pair cx cy) 10
        ]
    ][
        append cmds compose [
            fill-pen 255.255.255
            text (as-pair (item/offset/x + 8) (item/offset/y + fp-item-height - 16))
                 (fp-value-text item)
        ]
    ]

    if selected? [
        append cmds compose [
            pen (fp-selected-color)  line-width 2  fill-pen off
            box (as-pair (item/offset/x - 3) (item/offset/y - 3))
               (as-pair (item/offset/x + fp-item-width + 3) (item/offset/y + fp-item-height + 3)) 6
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
hit-fp-item: func [model mouse-x mouse-y /local found] [
    found: none
    foreach item model/front-panel [
        if all [
            mouse-x >= item/offset/x
            mouse-x <= (item/offset/x + fp-item-width)
            mouse-y >= item/offset/y
            mouse-y <= (item/offset/y + fp-item-height)
        ] [found: item]
    ]
    found
]

; ══════════════════════════════════════════════════════════
; EDITING — inline field for numeric editing
; ══════════════════════════════════════════════════════════
edit-dialog-item:  none
edit-dialog-panel: none
edit-dialog-model: none
edit-dialog-fval:  none

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
        default: 0.0
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
        button      "Cancelar"      [unview]
    ]
]

; ══════════════════════════════════════════════════════════
; CANVAS FACTORY — render-panel returns a functional face
; ══════════════════════════════════════════════════════════
; Model stored in face/extra includes: front-panel, selected-fp, drag-fp, drag-off, size

render-panel: func [model panel-width panel-height /local panel-face] [
    ; Store dimensions in model for actor access
    model/size: as-pair panel-width panel-height

    panel-face: make face! [
        type:    'base
        size:    as-pair panel-width panel-height
        offset:  0x0
        color:   fp-canvas-color
        flags:   [all-over]
        extra:   model
        draw:    render-fp-panel model panel-width panel-height
        actors:  make object! [

            on-down: func [face event /local mouse-x mouse-y hit w h] [
                mouse-x: event/offset/x
                mouse-y: event/offset/y
                w: face/extra/size/x
                h: face/extra/size/y
                hit: hit-fp-item face/extra mouse-x mouse-y

                either hit [
                    face/extra/selected-fp: hit
                    face/extra/drag-fp: hit
                    face/extra/drag-off: as-pair (mouse-x - hit/offset/x) (mouse-y - hit/offset/y)
                    face/draw: render-fp-panel face/extra w h
                ][
                    face/extra/selected-fp: none
                    face/draw: render-fp-panel face/extra w h
                ]
            ]

            on-over: func [face event /local mouse-x mouse-y w h] [
                mouse-x: event/offset/x
                mouse-y: event/offset/y
                w: face/extra/size/x
                h: face/extra/size/y

                if all [face/extra/drag-fp  face/extra/drag-off  event/down?] [
                    face/extra/drag-fp/offset: as-pair (mouse-x - face/extra/drag-off/x)
                                                         (mouse-y - face/extra/drag-off/y)
                    face/draw: render-fp-panel face/extra w h
                ]
            ]

            on-up: func [face event] [
                face/extra/drag-fp: none
                face/extra/drag-off: none
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
                set kw ['control | 'indicator | 'bool-control | 'bool-indicator]
                set fp-item-spec block! (
                    item: make-fp-item fp-item-spec
                    item/type:      kw
                    item/data-type: either find [bool-control bool-indicator] kw ['boolean] ['numeric]
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
            true                        ['indicator]
        ]
        spec: compose/deep [
            id: (item/id)
            type: (item/type)
            name: (item/name)
            label: [text: (item/label/text) visible: (item/label/visible)]
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
gen-panel-var-name: func [item] [
    to-word rejoin ["f" capitalize item/name]
]

gen-indicator-var-name: func [item] [
    to-word rejoin ["l" capitalize item/name]
]

compile-panel: func [model /local cmds item ctrl-field-name ind-var-name] [
    cmds: copy []

    foreach item model/front-panel [
        either item/type = 'control [
            ctrl-field-name: gen-panel-var-name item
            append cmds compose [
                label (item/label/text)
                (to-set-word ctrl-field-name) field 120 (form item/default)
            ]
        ][
            ind-var-name: gen-indicator-var-name item
            append cmds compose [
                label (item/label/text)
                (to-set-word ind-var-name) text 120 (form item/default)
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
        front-panel: copy []
        selected-fp: none
        drag-fp:     none
        drag-off:    none
        size:        400x300
    ]
]

add-demo-items: func [model /local ctrl1 ctrl2 ind1] [
    ctrl1: make-fp-item compose [
        id: 1  type: 'control  name: "ctrl_1"
        label: [text: "A" visible: true]
        default: 5.0
        offset: 20x20
    ]
    ctrl2: make-fp-item compose [
        id: 2  type: 'control  name: "ctrl_2"
        label: [text: "B" visible: true]
        default: 3.0
        offset: 20x90
    ]
    ind1: make-fp-item compose [
        id: 3  type: 'indicator  name: "ind_1"
        label: [text: "Resultado" visible: true]
        default: 0.0
        offset: 20x160
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