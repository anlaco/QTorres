Red [
    Title:   "QTorres — canvas-dialogs"
    Purpose: "Diálogos de edición de nodos, paleta de bloques y SR helpers."
    Needs:   'View
]

; ── canvas-dialogs.red ────────────────────────────────────────────
; Diálogos de edición de nodos, paleta de bloques y helpers de
; shift registers. Incluido desde canvas.red, tras canvas-render.red
; y las funciones de hit-test.
; Requiere en scope: render-bd, set-config, make-node, gen-node-id,
;   make-structure, make-frame, make-shift-register, cluster-fields.
; ──────────────────────────────────────────────────────────────────

toggle-bool-const: func [node /local cur] [
    cur: any [select node/config 'default  false]
    set-config node 'default not cur
]

; Abre diálogo para editar el valor de una constante numérica.
; Patrón view/no-wait con vars de módulo (igual que rename-dialog).
open-const-edit-dialog: func [node canvas-face /local cur-val] [
    cur-val: any [select node/config 'default  0.0]
    const-dialog-node:   node
    const-dialog-canvas: canvas-face
    const-dialog-field:  none
    view/no-wait compose [
        title "Editar constante"
        text "Valor:" return
        const-dialog-field: field 150 (form cur-val)
        on-enter [
            apply-const-value const-dialog-node const-dialog-field/text
            const-dialog-canvas/draw: render-bd const-dialog-canvas/extra
            unview
        ]
        return
        button "OK" [
            apply-const-value const-dialog-node const-dialog-field/text
            const-dialog-canvas/draw: render-bd const-dialog-canvas/extra
            unview
        ]
        button "Cancelar" [unview]
    ]
]

; Actualiza node/config 'default con el nuevo valor numérico.
apply-const-value: func [node new-text /local val] [
    val: attempt [to-float new-text]
    if none? val [exit]
    set-config node 'default val
]

; Aplica valor string a un nodo y refresca el canvas.
; Función auxiliar para evitar set-path con valor literal en compose/deep.
str-apply-and-refresh: func [nd txt cnv] [
    apply-str-value nd txt
    cnv/draw: render-bd cnv/extra
]

; Abre diálogo para editar el valor de una constante o control string.
; Usa compose/deep para incrustar node y canvas-face directamente en los handlers,
; evitando el bug de variables de módulo compartidas cuando dos diálogos están abiertos.
open-str-edit-dialog: func [node canvas-face /local cur-val] [
    cur-val: copy any [select node/config 'default  ""]
    view/no-wait compose/deep [
        title "Editar string"
        text "Valor:" return
        field 200 (cur-val)
        on-enter [
            ; face = el field (on-enter se dispara en el field)
            str-apply-and-refresh (node) copy face/text (canvas-face)
            unview
        ]
        return
        button "OK" [
            ; Buscar el field en los panes del panel padre
            foreach pf face/parent/pane [
                if pf/type = 'field [
                    str-apply-and-refresh (node) copy pf/text (canvas-face)
                    break
                ]
            ]
            unview
        ]
        button "Cancelar" [unview]
    ]
]

; Actualiza node/config 'default con el nuevo valor string.
apply-str-value: func [node new-text] [
    set-config node 'default new-text
]

; Actualiza node/config 'default con un block! de valores numéricos parseados desde texto.
; El usuario introduce valores separados por espacios, ej: "1.0 2.0 3.0"
apply-arr-value: func [node new-text /local vals tok parsed-block] [
    parsed-block: copy []
    vals: split trim new-text " "
    foreach tok vals [
        tok: trim tok
        if not empty? tok [
            append parsed-block any [attempt [to-float tok]  attempt [to-integer tok]  0.0]
        ]
    ]
    set-config node 'default parsed-block
]

arr-apply-and-refresh: func [nd txt cnv] [
    apply-arr-value nd txt
    cnv/draw: render-bd cnv/extra
]

; Abre diálogo para editar el valor de un array constante.
; El usuario introduce números separados por espacios: "1.0 2.0 3.0"
open-arr-edit-dialog: func [node canvas-face /local cur-val cur-text] [
    cur-val: any [select node/config 'default  copy []]
    cur-text: form cur-val   ; "1.0 2.0 3.0"
    view/no-wait compose/deep [
        title "Editar array"
        text "Valores (separados por espacios):" return
        field 250 (cur-text)
        on-enter [
            arr-apply-and-refresh (node) copy face/text (canvas-face)
            unview
        ]
        return
        button "OK" [
            foreach pf face/parent/pane [
                if pf/type = 'field [
                    arr-apply-and-refresh (node) copy pf/text (canvas-face)
                    break
                ]
            ]
            unview
        ]
        button "Cancelar" [unview]
    ]
]

apply-rename-label: func [node new-text] [
    either empty? new-text [
        if all [node/label  object? node/label] [
            node/label/visible: false
        ]
    ][
        either all [node/label  object? node/label] [
            node/label/text: new-text
            node/label/visible: true
        ][
            node/label: new-text
        ]
    ]
]

; ── Cluster edit dialog ──────────────────────────────────────────────────

; Guarda la lista de campos en node/config/fields.
apply-cluster-fields: func [node fields-block] [
    set-config node 'fields fields-block
]

; Parsea el texto del área de edición ("nombre:tipo" por línea) a [nombre 'tipo ...].
parse-cluster-fields-text: func [text /local result lines parts fname ftype] [
    result: copy []
    foreach line split text "^/" [
        line: trim line
        if not empty? line [
            parts: split line ":"
            if (length? parts) >= 2 [
                fname: to-word trim parts/1
                ftype: to-word trim parts/2
                unless find [number boolean string] ftype [ftype: 'number]
                append result fname
                append result to lit-word! ftype
            ]
        ]
    ]
    result
]

; Aplica campos parseados y refresca el canvas.
; Para cluster-control/cluster-indicator: también sincroniza el item FP correspondiente.
cluster-apply-and-refresh: func [nd txt cnv /local new-fields model _pref fp-item] [
    new-fields: parse-cluster-fields-text txt
    apply-cluster-fields nd new-fields
    if find [cluster-control cluster-indicator] nd/type [
        model: cnv/extra
        _pref: select model 'panel-ref
        if _pref [
            foreach fp-item model/front-panel [
                if fp-item/name = nd/name [
                    set-config fp-item 'fields new-fields
                    break
                ]
            ]
            _pref/draw: render-fp-panel model model/size/x model/size/y
            show _pref
        ]
    ]
    cnv/draw: render-bd cnv/extra
    show cnv
]

; Vars de módulo para el diálogo de edición de cluster (mismo patrón que rename)
cluster-dialog-node:   none
cluster-dialog-canvas: none
cluster-dialog-area:   none

; Abre diálogo para editar los campos de un bundle/unbundle.
; El usuario introduce campos en formato "nombre:tipo", uno por línea.
open-cluster-edit-dialog: func [node canvas-face /local cur-fields cur-text] [
    cluster-dialog-node:   node
    cluster-dialog-canvas: canvas-face
    cluster-dialog-area:   none
    cur-fields: cluster-fields node
    cur-text: copy ""
    foreach [fn ft] cur-fields [
        append cur-text rejoin [form fn ":" form to-word ft "^/"]
    ]
    view/no-wait compose/deep [
        title "Editar campos del cluster"
        text {Formato: nombre:tipo (uno por línea)} return
        text {Tipos: number  boolean  string} return
        cluster-dialog-area: area 260x180 (cur-text)
        return
        button "OK" [
            cluster-apply-and-refresh (node) copy cluster-dialog-area/text (canvas-face)
            unview
        ]
        button "Cancelar" [unview]
    ]
]

; Estado del diálogo de renombrado (view/no-wait requiere vars de módulo
; porque la función retorna antes de que el usuario cierre el diálogo).
rename-dialog-node:   none
rename-dialog-canvas: none
rename-dialog-field:  none

; Estado del diálogo de edición de constante numérica (mismo patrón)
const-dialog-node:    none
const-dialog-canvas:  none
const-dialog-field:   none

; ── Paleta de bloques ────────────────────────────────────────────
; vars de módulo para el diálogo de paleta (mismo patrón que rename)
palette-canvas: none
palette-pos-x:  0
palette-pos-y:  0
palette-struct: none   ; none = añadir a model/nodes, structure = añadir a st/nodes

; Añade un nodo al destino correcto: estructura interna o diagrama principal.
palette-add-node: func [node-type /local n nid model] [
    model: palette-canvas/extra
    nid: gen-node-id model
    n: make-node compose [id: (nid) type: (node-type) x: (palette-pos-x) y: (palette-pos-y)]
    either palette-struct [
        ; Case structure: añadir al frame activo
        if all [palette-struct/type = 'case-structure  block? palette-struct/frames] [
            if palette-struct/active-frame < length? palette-struct/frames [
                append palette-struct/frames/(palette-struct/active-frame + 1)/nodes n
            ]
        ]
        ; While/For loop: añadir a st/nodes
        if find [while-loop for-loop] palette-struct/type [
            append palette-struct/nodes n
        ]
    ][
        append model/nodes n
    ]
    palette-canvas/draw: render-bd model
    show palette-canvas
    unview
]

; Añade un nodo Sub-VI apuntando directamente a un .qvi de librería.
; vi-path es un file! ya resuelto (absoluto o relativo al working dir).
palette-add-qlib-vi: func [vi-path [file!] /local n nid model] [
    model: palette-canvas/extra
    nid: gen-node-id model
    n: make-subvi-node compose [
        id: (nid)
        type: 'subvi
        x: (palette-pos-x)
        y: (palette-pos-y)
        file: (vi-path)
    ]
    either palette-struct [
        if all [palette-struct/type = 'case-structure  block? palette-struct/frames] [
            if palette-struct/active-frame < length? palette-struct/frames [
                append palette-struct/frames/(palette-struct/active-frame + 1)/nodes n
            ]
        ]
        if find [while-loop for-loop] palette-struct/type [
            append palette-struct/nodes n
        ]
    ][
        append model/nodes n
    ]
    palette-canvas/draw: render-bd model
    show palette-canvas
    unview
]

; Añade un nodo Sub-VI con file picker.
palette-add-subvi: func [/local n nid model file-path] [
    model: palette-canvas/extra
    file-path: request-file/title/filter "Seleccionar VI" ["QVI" %*.qvi]
    if none? file-path [unview  return]
    ; request-file devuelve un bloque, tomar el primer elemento
    if block? file-path [file-path: first file-path]
    nid: gen-node-id model
    n: make-subvi-node compose [
        id: (nid)
        type: 'subvi
        x: (palette-pos-x)
        y: (palette-pos-y)
        file: (file-path)
    ]
    either palette-struct [
        ; Case structure: añadir al frame activo
        if all [palette-struct/type = 'case-structure  block? palette-struct/frames] [
            if palette-struct/active-frame < length? palette-struct/frames [
                append palette-struct/frames/(palette-struct/active-frame + 1)/nodes n
            ]
        ]
        ; While/For loop: añadir a st/nodes
        if find [while-loop for-loop] palette-struct/type [
            append palette-struct/nodes n
        ]
    ][
        append model/nodes n
    ]
    palette-canvas/draw: render-bd model
    show palette-canvas
    unview
]

; Crea una nueva estructura while-loop y la añade al diagrama.
palette-add-structure: func [type [word!] /local nid st model] [
    model: palette-canvas/extra
    nid: gen-node-id model
    st: make-structure compose [id: (nid) type: (type) x: (palette-pos-x) y: (palette-pos-y)]
    if type = 'case-structure [append st/frames make-frame [id: 0 label: "0"]]
    append model/structures st
    palette-canvas/draw: render-bd model
    show palette-canvas
    unview
]

open-palette: func [face x y /struct target-struct
    /local qlibs qlib vi-path vi-label vi-short layout-block
][
    palette-canvas: face
    palette-pos-x:  x
    palette-pos-y:  y
    palette-struct: target-struct

    ; ── Parte estática ────────────────────────────────────────────
    layout-block: copy [
        title "Añadir bloque"
        text "Aritmética:"  return
        button 80 "Add +"    [palette-add-node 'add]
        button 80 "Sub -"    [palette-add-node 'sub]
        button 80 "Mul *"    [palette-add-node 'mul]
        button 80 "Div /"    [palette-add-node 'div]    return
        text "Constante / salida:"  return
        button 80 "Const"    [palette-add-node 'const]
        button 80 "Display"  [palette-add-node 'display]  return
        text "Lógica:"  return
        button 80 "AND"      [palette-add-node 'and-op]
        button 80 "OR"       [palette-add-node 'or-op]
        button 80 "NOT"      [palette-add-node 'not-op]
        button 80 "B-Const"  [palette-add-node 'bool-const]  return
        text "Comparadores:"  return
        button 80 ">"        [palette-add-node 'gt-op]
        button 80 "<"        [palette-add-node 'lt-op]
        button 80 "="        [palette-add-node 'eq-op]
        button 80 "!="       [palette-add-node 'neq-op]  return
        text "String:"  return
        button 80 "S-Const"  [palette-add-node 'str-const]
        button 80 "Concat"   [palette-add-node 'concat]
        button 80 "Len"      [palette-add-node 'str-length]
        button 80 "→STR"     [palette-add-node 'to-string]  return
        text "Array:"  return
        button 80 "Arr[]"    [palette-add-node 'arr-const]
        button 80 "Build[]"  [palette-add-node 'build-array]
        button 80 "Index[]"  [palette-add-node 'index-array]  return
        button 80 "Size[]"   [palette-add-node 'array-size]
        button 80 "Subset[]" [palette-add-node 'array-subset]  return
        text "Cluster:"  return
        button 80 "Bundle"   [palette-add-node 'bundle]
        button 80 "Unbundle" [palette-add-node 'unbundle]  return
        text "Estructuras:"  return
        button 80 "While"    [palette-add-structure 'while-loop]
        button 80 "For"      [palette-add-structure 'for-loop]
        button 80 "Case"     [palette-add-structure 'case-structure]
        button 80 "QVI"      [palette-add-subvi]  return
        button 80 "Add SR"   [
            if palette-struct [
                unview
                open-add-sr-dialog palette-canvas palette-struct
            ]
        ]
        return
    ]

    ; ── Sección dinámica: librerías .qlib ────────────────────────
    ; Busca .qlib en el directorio desde donde se lanzó Red (proyecto)
    qlibs: find-qlibs/from system/options/path
    if not empty? qlibs [
        append layout-block [text "Librerías:" return]
        foreach qlib qlibs [
            foreach vi-path qlib/members [
                ; Etiqueta: "nombre-lib/vi" (sin extensión)
                vi-short: form last split-path vi-path
                if find vi-short ".qvi" [
                    vi-short: copy/part vi-short (subtract length? vi-short 4)
                ]
                vi-label: rejoin [qlib/name "/" vi-short]
                ; compose/deep captura vi-path por valor en cada iteración
                append layout-block compose/deep [
                    button 120 (vi-label) [palette-add-qlib-vi (vi-path)]
                ]
            ]
            append layout-block 'return
        ]
    ]

    append layout-block [button "Cancelar" [unview]]

    view/no-wait layout-block
]

; ── Shift Register helpers ──────────────────────────────────────────

; Añade un SR de tipo dado a la estructura, calculando el y-offset automáticamente.
add-sr-to-structure: func [st dtype /local y sr] [
    y: 40 + (50 * length? st/shift-regs)
    sr: make-shift-register compose [data-type: (dtype)  y-offset: (y)]
    append st/shift-regs sr
]

; Vars de módulo para diálogos SR (patrón view/no-wait)
add-sr-canvas: none
add-sr-struct:  none
sr-edit-canvas: none
sr-edit-sr-obj: none

; Abre diálogo para elegir el tipo del nuevo shift register.
open-add-sr-dialog: func [canvas st] [
    add-sr-canvas: canvas
    add-sr-struct:  st
    view/no-wait [
        title "Añadir shift register"
        text "Tipo de dato:"  return
        button 80 "Number"  [add-sr-to-structure add-sr-struct 'number
                              add-sr-canvas/draw: render-bd add-sr-canvas/extra
                              show add-sr-canvas  unview]
        button 80 "Boolean" [add-sr-to-structure add-sr-struct 'boolean
                              add-sr-canvas/draw: render-bd add-sr-canvas/extra
                              show add-sr-canvas  unview]
        button 80 "String"  [add-sr-to-structure add-sr-struct 'string
                              add-sr-canvas/draw: render-bd add-sr-canvas/extra
                              show add-sr-canvas  unview]    return
        button "Cancelar" [unview]
    ]
]

; Actualiza el init-value de un SR desde texto.
apply-sr-init-value: func [sr new-text /local val] [
    val: switch sr/data-type [
        string  [new-text]
        boolean [any [attempt [to-logic new-text]  false]]
    ]
    if none? val [val: any [attempt [to-float new-text]  0.0]]
    sr/init-value: val
]

; Abre diálogo para editar el valor inicial de un SR.
open-sr-edit-dialog: func [canvas sr /local cur] [
    sr-edit-canvas: canvas
    sr-edit-sr-obj: sr
    cur: form sr/init-value
    view/no-wait compose [
        title "Valor inicial SR"
        text (rejoin [sr/name "  [" form sr/data-type "]"]) return
        text "Valor inicial:" return
        sr-edit-fld: field 150 (cur)
        on-enter [
            apply-sr-init-value sr-edit-sr-obj sr-edit-fld/text
            sr-edit-canvas/draw: render-bd sr-edit-canvas/extra
            unview
        ]
        return
        button "OK" [
            apply-sr-init-value sr-edit-sr-obj sr-edit-fld/text
            sr-edit-canvas/draw: render-bd sr-edit-canvas/extra
            unview
        ]
        button "Cancelar" [unview]
    ]
]

; Borra el elemento seleccionado (nodo, wire o estructura completa).
; Llamar desde el on-key del window padre con: canvas-delete-selected canvas
