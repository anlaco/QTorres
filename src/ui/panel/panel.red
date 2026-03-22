Red [
    Title:   "QTorres — Front Panel"
    Purpose: "Panel de controles e indicadores (Issue #7 + #10)"
    Needs:   'View
]

; ══════════════════════════════════════════════════════════
; CONSTANTS — visual configuration
; ══════════════════════════════════════════════════════════
fp-canvas-color:      225.228.235
fp-control-color:     50.100.180
fp-indicator-color:   175.125.20
fp-text-color:        240.245.250
fp-selected-color:    0.120.200     ; azul discontinuo (selección LabVIEW)
fp-border-color:      30.60.120
fp-item-width:        120
fp-item-height:       40
fp-label-height:      16            ; altura de la zona label encima del field
fp-run-button-height: 30

; String-specific
fp-str-default-width:  160
fp-str-field-height:   40           ; altura del field (sin label)
fp-handle-size:        5            ; half-size de los cuadrados de resize (radio)
fp-str-min-width:      60
fp-str-min-field-h:    20

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
        default:   any [select spec 'default   either find [bool-control bool-indicator] raw-type [false] [0.0]]
        value:     none
        offset:    any [select spec 'offset    0x0]
        size:      as-pair fp-item-width fp-item-height
    ]
    item/type: raw-type
    item/value: any [select spec 'value  item/default]

    ; String: tamaño, default y value como string copiado
    if find [str-control str-indicator] raw-type [
        item/size:    as-pair fp-str-default-width (fp-label-height + fp-str-field-height)
        item/default: copy any [select spec 'default  ""]
        item/value:   copy any [select spec 'value    item/default]
    ]

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

    ; Size desde spec (persistencia): solo si viene explícito
    if select spec 'size [item/size: select spec 'size]

    item
]

fp-value-text: func [item] [
    form item/value
]

; ══════════════════════════════════════════════════════════
; HELPERS — wrap-text, draw-dashed-rect, handles
; ══════════════════════════════════════════════════════════

; Divide un string en líneas que caben en max-width píxeles (~7px/char)
wrap-text: func [txt [string!] max-width [integer!] /local char-w cpl lines i] [
    char-w: 7
    cpl: max 1 (max-width - 8) / char-w
    lines: copy []
    i: 1
    while [i <= length? txt] [
        append lines copy/part (skip txt i - 1) cpl
        i: i + cpl
    ]
    if empty? lines [append lines copy ""]
    lines
]

; Rectángulo discontinuo: 4 lados como segmentos dashed
draw-dashed-rect: func [x1 y1 x2 y2 /local cmds dash gap x y] [
    cmds: copy []
    dash: 5  gap: 3
    ; lado superior
    x: x1
    while [x < x2] [
        append cmds compose [line (as-pair x y1) (as-pair (min x2 x + dash) y1)]
        x: x + dash + gap
    ]
    ; lado inferior
    x: x1
    while [x < x2] [
        append cmds compose [line (as-pair x y2) (as-pair (min x2 x + dash) y2)]
        x: x + dash + gap
    ]
    ; lado izquierdo
    y: y1
    while [y < y2] [
        append cmds compose [line (as-pair x1 y) (as-pair x1 (min y2 y + dash))]
        y: y + dash + gap
    ]
    ; lado derecho
    y: y1
    while [y < y2] [
        append cmds compose [line (as-pair x2 y) (as-pair x2 (min y2 y + dash))]
        y: y + dash + gap
    ]
    cmds
]

; Devuelve las 8 posiciones de handles para el rectángulo del field
; Cada handle: [nombre center-pair]
handle-positions: func [fx fy fw fh /local mx my] [
    mx: fx + (fw / 2)
    my: fy + (fh / 2)
    reduce [
        'nw as-pair fx      fy
        'n  as-pair mx      fy
        'ne as-pair fx + fw fy
        'e  as-pair fx + fw my
        'se as-pair fx + fw fy + fh
        's  as-pair mx      fy + fh
        'sw as-pair fx      fy + fh
        'w  as-pair fx      my
    ]
]

; Comprueba si (px py) está cerca de un handle. Devuelve nombre o none.
; Radio de hit = fp-handle-size + 4 para facilitar la selección
hit-handle: func [handles px py /local i name pos radius] [
    radius: fp-handle-size + 4
    i: 1
    while [i <= length? handles] [
        name: handles/:i
        pos:  handles/(i + 1)
        if all [
            (absolute px - pos/x) <= radius
            (absolute py - pos/y) <= radius
        ] [return name]
        i: i + 2
    ]
    none
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

render-fp-item: func [item selected? hover? /local cmds col border-col type-lbl text-x text-y led-col cx cy fx fy fw fh lx ly lbl-text lines line-y line-h max-lines handles] [
    cmds: copy []

    either item/data-type = 'string [
        ; ── String control / indicator: label flotante + field blanco ──
        lbl-text: either all [item/label  object? item/label  item/label/visible] [
            any [item/label/text ""]
        ] [""]

        ; Posición de la label (relativa al item/offset + label/offset)
        lx: item/offset/x + item/label/offset/x
        ly: item/offset/y + item/label/offset/y

        ; Field: justo debajo de la zona label
        fx: item/offset/x
        fy: item/offset/y + fp-label-height
        fw: item/size/x
        fh: item/size/y - fp-label-height

        ; Label (texto flotante, sin fondo)
        append cmds compose [
            pen off  fill-pen 30.30.30
            text (as-pair lx (ly + 2)) (lbl-text)
        ]

        ; Field
        either item/type = 'str-control [
            append cmds compose [
                pen 80.80.80  line-width 1  fill-pen 255.255.255
                box (as-pair fx fy) (as-pair fx + fw fy + fh) 2
            ]
        ][
            ; str-indicator: borde más grueso, fondo ligeramente gris
            append cmds compose [
                pen 80.80.80  line-width 2  fill-pen 245.245.245
                box (as-pair fx fy) (as-pair fx + fw fy + fh) 2
            ]
        ]

        ; Texto con wrap (bottom-anchored si overflow)
        lines: wrap-text form item/value fw
        line-h: 14
        max-lines: max 1 (fh - 4) / line-h
        if (length? lines) > max-lines [
            lines: skip lines ((length? lines) - max-lines)
        ]
        line-y: fy + 4
        append cmds [pen off  fill-pen 20.20.20]
        foreach ln lines [
            append cmds compose [text (as-pair fx + 4 line-y) (ln)]
            line-y: line-y + line-h
        ]

        ; Handles de resize (si hover o seleccionado)
        if any [hover?  selected?] [
            handles: handle-positions fx fy fw fh
            append cmds compose [pen 80.80.80  line-width 1  fill-pen 255.255.255]
            ; handles es bloque plano [word pair word pair ...]
            loop (length? handles) / 2 [
                handles: next handles   ; skip word → apunta al pair
                append cmds compose [
                    box (as-pair (handles/1/x - fp-handle-size) (handles/1/y - fp-handle-size))
                       (as-pair (handles/1/x + fp-handle-size) (handles/1/y + fp-handle-size)) 0
                ]
                handles: next handles   ; skip pair → apunta al siguiente word
            ]
            handles: head handles
        ]

        ; Selección: dos marcos discontinuos independientes (LabVIEW-style)
        if selected? [
            append cmds compose [pen (fp-selected-color)  line-width 1  fill-pen off]
            ; Marco del field
            append cmds draw-dashed-rect fx - 2 fy - 2 (fx + fw) + 2 (fy + fh) + 2
            ; Marco de la label (zona aproximada)
            append cmds draw-dashed-rect lx - 2 ly - 2 (lx + 80) + 2 (ly + fp-label-height) + 2
        ]

    ][
        ; ── Numeric / Boolean: caja de color con label interior (comportamiento actual) ──
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
            led-col: either item/value [0.180.0] [180.0.0]
            cx: item/offset/x + fp-item-width - 20
            cy: item/offset/y + (fp-item-height / 2)
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
    ]

    cmds
]

render-fp-panel: func [model w h /local cmds item selected? hover?] [
    cmds: copy []

    append cmds render-fp-grid w h

    foreach item model/front-panel [
        selected?: either model/selected-fp [same? item model/selected-fp] [false]
        hover?:    either model/fp-hover-item [same? item model/fp-hover-item] [false]
        append cmds render-fp-item item selected? hover?
    ]

    cmds
]

; ══════════════════════════════════════════════════════════
; HIT TESTING
; ══════════════════════════════════════════════════════════
hit-fp-item: func [model mouse-x mouse-y /local found item] [
    found: none
    foreach item model/front-panel [
        either item/data-type = 'string [
            ; bounding box: desde offset hasta offset + size
            if all [
                mouse-x >= item/offset/x
                mouse-x <= (item/offset/x + item/size/x)
                mouse-y >= item/offset/y
                mouse-y <= (item/offset/y + item/size/y)
            ] [found: item]
        ][
            if all [
                mouse-x >= item/offset/x
                mouse-x <= (item/offset/x + fp-item-width)
                mouse-y >= item/offset/y
                mouse-y <= (item/offset/y + fp-item-height)
            ] [found: item]
        ]
    ]
    found
]

; Devuelve bloque [item zone] o none.
; zone: 'handle-nw 'handle-n ... | 'label | 'field | 'body
hit-fp-zone: func [model mx my /local item fx fy fw fh lx ly handles hname] [
    ; Iterar al revés para que el último dibujado (encima) tenga prioridad
    foreach item (reverse copy model/front-panel) [
        either item/data-type = 'string [
            fx: item/offset/x
            fy: item/offset/y + fp-label-height
            fw: item/size/x
            fh: item/size/y - fp-label-height
            lx: item/offset/x + item/label/offset/x
            ly: item/offset/y + item/label/offset/y

            ; 1. Handles (prioridad máxima)
            handles: handle-positions fx fy fw fh
            hname: hit-handle handles mx my
            if hname [return reduce [item to-word rejoin ["handle-" form hname]]]

            ; 2. Label (zona aproximada: lx..lx+100, ly..ly+fp-label-height)
            if all [
                mx >= lx  mx <= (lx + 100)
                my >= ly  my <= (ly + fp-label-height)
            ] [return reduce [item 'label]]

            ; 3. Field
            if all [
                mx >= fx  mx <= (fx + fw)
                my >= fy  my <= (fy + fh)
            ] [return reduce [item 'field]]
        ][
            ; Non-string: zona body fija
            if all [
                mx >= item/offset/x  mx <= (item/offset/x + fp-item-width)
                my >= item/offset/y  my <= (item/offset/y + fp-item-height)
            ] [return reduce [item 'body]]
        ]
    ]
    none
]

; ══════════════════════════════════════════════════════════
; INLINE EDITING — usa variables de módulo para cruzar la
; barrera async (Red no tiene closures en func)
; ══════════════════════════════════════════════════════════
inline-item:    none    ; fp-item que se está editando
inline-panel:   none    ; face del panel
inline-model:   none    ; model
inline-label?:  false   ; true = editando label, false = editando valor
inline-fld:     none    ; field de edición
inline-fld-lbl: none    ; label de referencia en el diálogo

confirm-inline-edit: does [
    ; Lee el valor del field y lo aplica al item
    if all [inline-item  inline-fld] [
        either inline-label? [
            inline-item/label/text: copy inline-fld/text
        ][
            inline-item/value: copy inline-fld/text
        ]
    ]
    inline-model/fp-mode: 'idle
    inline-panel/draw: render-fp-panel inline-model inline-model/size/x inline-model/size/y
    show inline-panel
    unview
]

cancel-inline-edit: does [
    inline-model/fp-mode: 'idle
    unview
]

open-inline-edit: func [panel-face item model is-label /local fx fy fw fh lx ly cur-text win-x win-y] [
    inline-item:   item
    inline-panel:  panel-face
    inline-model:  model
    inline-label?: is-label

    model/fp-mode: 'editing

    either is-label [
        lx: item/offset/x + item/label/offset/x
        ly: item/offset/y + item/label/offset/y
        cur-text: any [item/label/text ""]
        view/no-wait compose/deep [
            title ""
            inline-fld: field 160 (cur-text)
            on-key [
                if event/key = 'return  [confirm-inline-edit]
                if event/key = 'escape  [cancel-inline-edit]
            ]
            button 40 "OK"  [confirm-inline-edit]
        ]
    ][
        fx: item/offset/x
        fy: item/offset/y + fp-label-height
        fw: item/size/x
        fh: item/size/y - fp-label-height
        cur-text: form item/value
        view/no-wait compose/deep [
            title (any [item/label/text "Editar string"])
            inline-fld: field (max 160 fw) (cur-text)
            on-key [
                if event/key = 'return  [confirm-inline-edit]
                if event/key = 'escape  [cancel-inline-edit]
            ]
            return
            button "OK"      [confirm-inline-edit]
            button "Cancelar" [cancel-inline-edit]
        ]
    ]
]

; ══════════════════════════════════════════════════════════
; EDITING — inline field for numeric editing (legacy)
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

fp-palette-add-item: func [item-type /local new-id item model w h _cref nid bd-y def-val] [
    model:  fp-palette-panel/extra
    w:      model/size/x
    h:      model/size/y
    new-id: 1 + length? model/front-panel
    def-val: case [
        find [bool-control bool-indicator] item-type [false]
        find [str-control  str-indicator]  item-type [copy ""]
        true [0.0]
    ]
    item: make-fp-item compose/deep [
        id:      (new-id)
        type:    (item-type)
        name:    (rejoin [form item-type "_" new-id])
        label:   [text: (fp-default-label item-type) visible: true]
        default: (def-val)
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
; Model stored in face/extra includes:
;   front-panel, selected-fp, drag-fp, drag-off, size
;   fp-mode, fp-resize-handle, fp-hover-item, fp-edit-face
;   fp-drag-start-size, fp-drag-start-offset

render-panel: func [model panel-width panel-height /local panel-face] [
    model/size: as-pair panel-width panel-height

    ; Inicializar campos de estado si no existen
    if none? select model 'fp-mode           [model/fp-mode:           'idle]
    if none? select model 'fp-resize-handle  [model/fp-resize-handle:  none]
    if none? select model 'fp-hover-item     [model/fp-hover-item:     none]
    if none? select model 'fp-edit-face      [model/fp-edit-face:      none]
    if none? select model 'fp-drag-start-sz  [model/fp-drag-start-sz:  none]
    if none? select model 'fp-drag-start-off [model/fp-drag-start-off: none]
    if none? select model 'fp-drag-mouse-0   [model/fp-drag-mouse-0:   none]

    panel-face: make face! [
        type:    'base
        size:    as-pair panel-width panel-height
        offset:  0x0
        color:   fp-canvas-color
        flags:   [all-over]
        pane:    copy []
        extra:   model
        draw:    render-fp-panel model panel-width panel-height
        actors:  make object! [

            on-down: func [face event /local mx my w h zone item zone-type hname] [
                mx: event/offset/x
                my: event/offset/y
                w:  face/extra/size/x
                h:  face/extra/size/y

                ; Si hay edición inline activa, no interferir
                if face/extra/fp-mode = 'editing [exit]

                zone: hit-fp-zone face/extra mx my

                either zone [
                    item:      zone/1
                    zone-type: zone/2

                    face/extra/selected-fp: item

                    case [
                        ; Handle de resize (str-control/indicator)
                        ; zone-type es 'handle-se, 'handle-nw, etc.
                        "handle-" = copy/part form zone-type 7 [
                            hname: to-word skip form zone-type 7
                            face/extra/fp-mode:          'resize
                            face/extra/fp-resize-handle: hname
                            face/extra/fp-drag-start-sz:  copy item/size
                            face/extra/fp-drag-start-off: copy item/offset
                            face/extra/fp-drag-mouse-0:   as-pair mx my
                        ]

                        ; Label de un string control
                        zone-type = 'label [
                            face/extra/fp-mode:  'drag-label
                            face/extra/drag-fp:  item
                            face/extra/drag-off: as-pair (mx - item/offset/x - item/label/offset/x)
                                                          (my - item/offset/y - item/label/offset/y)
                        ]

                        ; Field o body normal
                        true [
                            face/extra/fp-mode:  'drag-item
                            face/extra/drag-fp:  item
                            face/extra/drag-off: as-pair (mx - item/offset/x) (my - item/offset/y)
                        ]
                    ]
                ][
                    face/extra/selected-fp: none
                    face/extra/fp-mode:     'idle
                ]

                face/draw: render-fp-panel face/extra w h
            ]

            on-over: func [face event /local mx my w h item new-x new-y dsz doff dm0 dx dy new-w new-h new-ox new-oy prev-hover] [
                mx: event/offset/x
                my: event/offset/y
                w:  face/extra/size/x
                h:  face/extra/size/y

                if face/extra/fp-mode = 'editing [exit]

                case [
                    ; ── Mover item completo ──────────────────────
                    all [face/extra/fp-mode = 'drag-item  face/extra/drag-fp  event/down?] [
                        item:  face/extra/drag-fp
                        new-x: mx - face/extra/drag-off/x
                        new-y: my - face/extra/drag-off/y
                        item/offset: as-pair (max 0 new-x) (max 0 new-y)
                        face/draw: render-fp-panel face/extra w h
                    ]

                    ; ── Mover label independiente ─────────────────
                    all [face/extra/fp-mode = 'drag-label  face/extra/drag-fp  event/down?] [
                        item: face/extra/drag-fp
                        item/label/offset: as-pair (mx - item/offset/x - face/extra/drag-off/x)
                                                    (my - item/offset/y - face/extra/drag-off/y)
                        face/draw: render-fp-panel face/extra w h
                    ]

                    ; ── Resize ───────────────────────────────────
                    all [face/extra/fp-mode = 'resize  face/extra/selected-fp  event/down?] [
                        item:  face/extra/selected-fp
                        dsz:   face/extra/fp-drag-start-sz
                        doff:  face/extra/fp-drag-start-off
                        dm0:   face/extra/fp-drag-mouse-0
                        dx: mx - dm0/x
                        dy: my - dm0/y

                        new-w:  dsz/x
                        new-h:  dsz/y
                        new-ox: doff/x
                        new-oy: doff/y

                        switch face/extra/fp-resize-handle [
                            se [new-w: max fp-str-min-width dsz/x + dx
                                new-h: max (fp-label-height + fp-str-min-field-h) dsz/y + dy]
                            s  [new-h: max (fp-label-height + fp-str-min-field-h) dsz/y + dy]
                            e  [new-w: max fp-str-min-width dsz/x + dx]
                            sw [new-w: max fp-str-min-width dsz/x - dx
                                new-h: max (fp-label-height + fp-str-min-field-h) dsz/y + dy
                                new-ox: doff/x + (dsz/x - new-w)]
                            w  [new-w: max fp-str-min-width dsz/x - dx
                                new-ox: doff/x + (dsz/x - new-w)]
                            ne [new-w: max fp-str-min-width dsz/x + dx
                                new-h: max (fp-label-height + fp-str-min-field-h) dsz/y - dy
                                new-oy: doff/y + (dsz/y - new-h)]
                            n  [new-h: max (fp-label-height + fp-str-min-field-h) dsz/y - dy
                                new-oy: doff/y + (dsz/y - new-h)]
                            nw [new-w: max fp-str-min-width dsz/x - dx
                                new-h: max (fp-label-height + fp-str-min-field-h) dsz/y - dy
                                new-ox: doff/x + (dsz/x - new-w)
                                new-oy: doff/y + (dsz/y - new-h)]
                        ]

                        item/size:   as-pair new-w new-h
                        item/offset: as-pair new-ox new-oy
                        face/draw: render-fp-panel face/extra w h
                    ]

                    ; ── Idle: actualizar hover para mostrar handles ──
                    face/extra/fp-mode = 'idle [
                        prev-hover: face/extra/fp-hover-item
                        face/extra/fp-hover-item: hit-fp-item face/extra mx my
                        ; Solo re-render si cambió el hover
                        if not same? prev-hover face/extra/fp-hover-item [
                            face/draw: render-fp-panel face/extra w h
                        ]
                    ]
                ]
            ]

            on-up: func [face event] [
                if not (face/extra/fp-mode = 'editing) [
                    face/extra/fp-mode:          'idle
                    face/extra/drag-fp:          none
                    face/extra/drag-off:         none
                    face/extra/fp-resize-handle: none
                    face/extra/fp-drag-start-sz: none
                    face/extra/fp-drag-start-off: none
                    face/extra/fp-drag-mouse-0:   none
                ]
            ]

            on-click: func [face event /local mx my w h zone item] [
                mx: event/offset/x
                my: event/offset/y
                w:  face/extra/size/x
                h:  face/extra/size/y

                if face/extra/fp-mode = 'editing [exit]

                zone: hit-fp-zone face/extra mx my
                if none? zone [exit]
                item: zone/1

                case [
                    ; Clic en field de str-control → edición inline del valor
                    all [zone/2 = 'field  item/type = 'str-control] [
                        open-inline-edit face item face/extra false
                    ]
                    ; Toggle booleano
                    item/type = 'bool-control [
                        item/value: not item/value
                        face/draw: render-fp-panel face/extra w h
                    ]
                    ; Edit numérico
                    item/type = 'control [
                        open-edit-dialog item face face/extra
                    ]
                ]
            ]

            on-dbl-click: func [face event /local mx my zone item] [
                mx: event/offset/x
                my: event/offset/y

                if face/extra/fp-mode = 'editing [exit]

                zone: hit-fp-zone face/extra mx my

                case [
                    ; Doble-clic en label de string → editar label
                    all [zone  zone/2 = 'label  find [str-control str-indicator] zone/1/type] [
                        open-inline-edit face zone/1 face/extra true
                    ]
                    ; Doble-clic en field de string → editar valor
                    all [zone  zone/2 = 'field  zone/1/type = 'str-control] [
                        open-inline-edit face zone/1 face/extra false
                    ]
                    ; Boolean toggle
                    all [zone  zone/1/type = 'bool-control] [
                        zone/1/value: not zone/1/value
                        face/draw: render-fp-panel face/extra face/extra/size/x face/extra/size/y
                    ]
                    ; Numeric edit
                    all [zone  zone/1/type = 'control] [
                        open-edit-dialog zone/1 face face/extra
                    ]
                    ; Espacio vacío → paleta
                    none? zone [open-fp-palette face mx my]
                ]
            ]

            on-key: func [face event /local model hit w h _cref bd-node] [
                model: face/extra

                ; Si hay edición inline, ignorar Delete (el field la gestiona)
                if model/fp-mode = 'editing [exit]

                hit: model/selected-fp
                w: model/size/x
                h: model/size/y

                if all [hit  any [find [delete backspace] event/key  find [#"^(7F)" #"^H"] event/key]] [
                    _cref: select model 'canvas-ref
                    if _cref [
                        bd-node: none
                        foreach n model/nodes [if n/name = hit/name [bd-node: n]]
                        if bd-node [
                            remove-each wire model/wires [any [wire/from-node = bd-node/id  wire/to-node = bd-node/id]]
                            remove-each n model/nodes    [n/name = hit/name]
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
; PARSER — load front-panel from qvi-diagram
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
                    item/type: kw
                    item/data-type: case [
                        find [bool-control bool-indicator] kw ['boolean]
                        find [str-control  str-indicator]  kw ['string]
                        true                               ['numeric]
                    ]
                    if all [zero? item/offset/x  zero? item/offset/y] [
                        item/offset: as-pair 20 offset-y
                        offset-y: offset-y + item/size/y + 10
                    ]
                    append result item
                )
            ]
        ]
    ]
    result
]

; ══════════════════════════════════════════════════════════
; PERSISTENCE — save front-panel to qvi-diagram format
; ══════════════════════════════════════════════════════════
save-panel-to-diagram: func [front-panel-items /local items item kw spec] [
    items: copy []
    foreach item front-panel-items [
        kw: case [
            item/type = 'control        ['control]
            item/type = 'bool-control   ['bool-control]
            item/type = 'bool-indicator ['bool-indicator]
            item/type = 'str-control    ['str-control]
            item/type = 'str-indicator  ['str-indicator]
            true                        ['indicator]
        ]
        spec: compose/deep [
            id:     (item/id)
            type:   (item/type)
            name:   (item/name)
            label:  [text: (item/label/text) visible: (item/label/visible) offset: (item/label/offset)]
            default: (item/default)
            offset: (item/offset)
            size:   (item/size)
        ]
        append items kw
        append/only items spec
    ]
    reduce [to-set-word 'front-panel  items]
]

; ══════════════════════════════════════════════════════════
; COMPILE PANEL — generate VID layout for .qvi executable
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
        case [
            item/type = 'control [
                ctrl-field-name: gen-panel-var-name item
                append cmds compose [
                    label (item/label/text)
                    (to-set-word ctrl-field-name) field 120 (form item/default)
                ]
            ]
            item/type = 'str-control [
                ctrl-field-name: gen-panel-var-name item
                append cmds compose [
                    label (item/label/text)
                    (to-set-word ctrl-field-name) field 200 (item/default)
                ]
            ]
            item/type = 'str-indicator [
                ind-var-name: gen-indicator-var-name item
                append cmds compose [
                    label (item/label/text)
                    (to-set-word ind-var-name) text 200 (item/default)
                ]
            ]
            true [
                ind-var-name: gen-indicator-var-name item
                append cmds compose [
                    label (item/label/text)
                    (to-set-word ind-var-name) text 120 (form item/default)
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
        front-panel:         copy []
        selected-fp:         none
        drag-fp:             none
        drag-off:            none
        size:                400x300
        fp-mode:             'idle
        fp-resize-handle:    none
        fp-hover-item:       none
        fp-edit-face:        none
        fp-drag-start-sz:    none
        fp-drag-start-off:   none
        fp-drag-mouse-0:     none
    ]
]

add-demo-items: func [model /local ctrl1 ctrl2 ind1 str1] [
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
        offset: 20x80
    ]
    ind1: make-fp-item compose [
        id: 3  type: 'indicator  name: "ind_1"
        label: [text: "Resultado" visible: true]
        default: 0.0
        offset: 20x140
    ]
    str1: make-fp-item compose [
        id: 4  type: 'str-control  name: "str_1"
        label: [text: "Mensaje" visible: true]
        default: ""
        offset: 200x20
    ]
    append model/front-panel ctrl1
    append model/front-panel ctrl2
    append model/front-panel ind1
    append model/front-panel str1
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
    demo-model: make-demo-model
    add-demo-items demo-model

    panel: render-panel demo-model 400 300
    panel/offset: 10x38

    view make face! [
        type:   'window
        text:   "QTorres — Front Panel (Issue #10 String)"
        size:   420x360
        offset: 80x60
        pane:   reduce [
            make face! [
                type: 'base  offset: 10x8  size: 400x25  color: 200.203.212
                draw: [pen 60.70.90  text 5x15 "Str: clic=editar valor | dbl-clic label=editar label | handles=resize | Delete=borrar"]
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
