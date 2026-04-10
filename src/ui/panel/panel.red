Red [
    Title:   "QTorres — Front Panel"
    Purpose: "Panel de controles e indicadores (Issue #7)"
    Needs:   'View
]

#include %panel-render.red

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

; Vars de módulo para el diálogo de definición de cluster desde el FP
cluster-def-item:  none
cluster-def-panel: none
cluster-def-model: none

; Abre diálogo para definir los campos de un cluster-control/indicator desde el FP.
; Edita la definición (nombre:tipo), no los valores.
; Al confirmar sincroniza el nodo BD correspondiente.
open-cluster-fp-edit-dialog: func [item panel-face model /local cur-fields cur-text] [
    cluster-def-item:  item
    cluster-def-panel: panel-face
    cluster-def-model: model
    cur-fields: fp-cluster-fields item
    cur-text: copy ""
    foreach [fn ft] cur-fields [
        append cur-text rejoin [form fn ":" form to-word ft "^/"]
    ]
    view/no-wait compose [
        title "Definir campos del cluster"
        text "Formato: nombre:tipo (uno por línea)" return
        text "Tipos: number  boolean  string" return
        area 260x180 (cur-text) return
        button "OK" [
            foreach pf face/parent/pane [
                if pf/type = 'area [
                    new-fields: parse-cluster-fields-text copy pf/text
                    set-config cluster-def-item 'fields new-fields
                    ; Sincronizar nodo BD correspondiente
                    _cref: select cluster-def-model 'canvas-ref
                    if _cref [
                        foreach nd cluster-def-model/nodes [
                            if nd/name = cluster-def-item/name [
                                set-config nd 'fields new-fields
                                break
                            ]
                        ]
                        _cref/draw: render-bd cluster-def-model
                        show _cref
                    ]
                    cluster-def-panel/draw: render-fp-panel cluster-def-model cluster-def-model/size/x cluster-def-model/size/y
                    show cluster-def-panel
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
            ; Guardar label si el usuario lo modificó
            if all [edit-dialog-item/label  object? edit-dialog-item/label] [
                edit-dialog-item/label/text: copy flabel/text
            ]
            ; Guardar valor numérico
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

            on-down: func [face event /local mouse-x mouse-y zone item w h lbl-dx lbl-dy _sx _sy _sb _cy] [
                w: face/size/x  h: face/size/y
                _sx: event/offset/x  _sy: event/offset/y
                _sb: 8
                ; ── Click en scrollbar vertical del FP ──
                _cy: h
                foreach _it face/extra/front-panel [
                    _cy: max _cy (_it/offset/y + fp-item-height + fp-label-above + 20)
                ]
                if all [_cy > h  _sx >= (w - _sb)  _sy < (h - _sb)] [
                    face/extra/fp-scroll-y: max 0 to-integer (_sy * (_cy - h) / (h - _sb))
                    face/draw: render-fp-panel face/extra w h
                    exit
                ]
                mouse-x: event/offset/x + face/extra/fp-scroll-x
                mouse-y: event/offset/y + face/extra/fp-scroll-y
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
                mouse-x: event/offset/x + face/extra/fp-scroll-x
                mouse-y: event/offset/y + face/extra/fp-scroll-y
                w: face/size/x
                h: face/size/y

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
                mouse-x: event/offset/x + face/extra/fp-scroll-x
                mouse-y: event/offset/y + face/extra/fp-scroll-y
                w: face/size/x
                h: face/size/y
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
                mouse-x: event/offset/x + face/extra/fp-scroll-x
                mouse-y: event/offset/y + face/extra/fp-scroll-y
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
                mouse-x: event/offset/x + face/extra/fp-scroll-x
                mouse-y: event/offset/y + face/extra/fp-scroll-y
                open-fp-palette face mouse-x mouse-y
            ]

            on-wheel: func [face event /local model step] [
                model: face/extra
                step: to-integer event/picked * -40
                either event/shift? [
                    model/fp-scroll-x: max 0 (model/fp-scroll-x + step)
                ][
                    model/fp-scroll-y: max 0 (model/fp-scroll-y + step)
                ]
                face/draw: render-fp-panel model face/size/x face/size/y
            ]

            on-key: func [face event /local model hit w h _cref bd-node] [
                model: face/extra
                hit: model/selected-fp
                w: face/size/x
                h: face/size/y

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