Red [
    Title:   "QTorres — Modelo del grafo"
    Purpose: "Modelo de datos en memoria + constructores (DT-022, DT-023, DT-024)"
]

; ══════════════════════════════════════════════════
; DIALECTO: qvi-diagram
; ══════════════════════════════════════════════════
; Describe la estructura completa de un VI.
; Se usa como cabecera gráfica del .qvi y como formato de carga.
;
; Sintaxis (formato nuevo — DT-022/DT-024):
;   front-panel [
;       control   [id: <int>  type: <lit-word>  name: <string>  label: [text: <string>]  default: <value>]
;       indicator [id: <int>  type: <lit-word>  name: <string>  label: [text: <string>]]
;   ]
;   block-diagram [
;       nodes [
;           node [id: <int>  type: <lit-word>  x: <int>  y: <int>  name: <string>  label: [text: <string>  visible: <logic>]]
;       ]
;       wires [
;           wire [from: <int>  port: <lit-word>  to: <int>  port: <lit-word>]
;       ]
;   ]
;   connector [                    ; solo si el VI se usa como sub-VI
;       input  [id: <int>  name: <string>  label: [text: <string>]]
;       output [id: <int>  name: <string>  label: [text: <string>]]
;   ]
;
; Retrocompatibilidad: label: <string> (formato antiguo) se acepta y convierte
; automáticamente a label: [text: <string>] con visibilidad por defecto del tipo.
;
; Reglas de parse:
;   qvi-rule:     [opt connector-rule front-panel-rule block-diagram-rule]
;   control-rule: ['control block!]
;   node-rule:    ['node block!]
;   wire-rule:    ['wire block!]
;
; El procesador del dialecto (load-qvi) recorre el bloque con parse
; y construye el modelo en memoria (listas de nodos, puertos, wires).

; ══════════════════════════════════════════════════
; LABEL — Objeto propio (DT-022)
; ══════════════════════════════════════════════════
; La label es una sub-entidad con estado y comportamiento.
; Se compone dentro de nodos, wires y fp-items.
; Tiene texto, visibilidad y posición relativa al padre.

make-label: func [
    "Crea un objeto label a partir de un bloque de especificación"
    spec [block!]
][
    make object! [
        text:    any [select spec 'text     ""]
        visible: either none? select spec 'visible [true] [select spec 'visible]
        offset:  any [select spec 'offset   0x-15]
    ]
]

; ══════════════════════════════════════════════════
; NAME — Generador de identificadores estáticos (DT-024)
; ══════════════════════════════════════════════════
; Cada nodo recibe un name único e inmutable: tipo_contador.
; El name es el identificador para el compilador.
; La label/text es el texto visual libre (puede tener duplicados).

name-counters: make map! []

gen-name: func [
    "Genera un name único para un tipo de elemento: tipo_N"
    type [word!]
    /local n
][
    n: any [select name-counters type  0]
    n: n + 1
    put name-counters type n
    rejoin [form type "_" n]
]

reset-name-counters: func ["Reinicia todos los contadores de nombres"] [
    clear name-counters
]

sync-name-counters: func [
    "Reconstruye contadores desde una lista de names existentes (al cargar .qvi)"
    names [block!]
    /local parts type-str num-str num cur
][
    reset-name-counters
    foreach nm names [
        if string? nm [
            parts: split nm "_"
            if (length? parts) >= 2 [
                type-str: copy ""
                repeat i ((length? parts) - 1) [
                    if i > 1 [append type-str "_"]
                    append type-str parts/:i
                ]
                num-str: parts/(length? parts)
                num: attempt [to-integer num-str]
                if num [
                    cur: any [select name-counters to-word type-str  0]
                    if num > cur [
                        put name-counters to-word type-str num
                    ]
                ]
            ]
        ]
    ]
]

; ══════════════════════════════════════════════════
; DEFAULTS — Label y visibilidad por tipo
; ══════════════════════════════════════════════════

default-label-text: func [
    "Devuelve el texto de label por defecto para un tipo de nodo"
    type [word! lit-word!]
][
    switch to-word type [
        control   ["Numeric"]
        indicator ["Numeric"]
        add       ["Add"]
        sub       ["Sub"]
        subvi     ["SubVI"]
    ]
]

default-label-visible?: func [
    "Devuelve si la label debe ser visible por defecto para un tipo"
    type [word! lit-word!]
][
    to-logic find [control indicator] to-word type
]

; ══════════════════════════════════════════════════
; PROTOTIPO BASE (DT-023)
; ══════════════════════════════════════════════════
; Campos comunes a todos los elementos del diagrama.
; Los constructores lo extienden con `make`.

base-element: context [
    id:    0
    name:  ""
    label: none
    x:     0
    y:     0
]

; ══════════════════════════════════════════════════
; CONSTRUCTORES
; ══════════════════════════════════════════════════

make-node: func [
    "Crea un nodo del Block Diagram (DT-022/023/024)"
    spec [block!]
    /local n lbl-spec lbl-text lbl-vis
][
    n: make base-element [
        type:   any [select spec 'type  'add]
        ports:  copy []
        config: copy []
    ]
    n/id: any [select spec 'id  0]
    n/x:  any [select spec 'x   0]
    n/y:  any [select spec 'y   0]

    ; Name: usar explícito, o generar automáticamente
    n/name: any [select spec 'name  gen-name to-word n/type]

    ; Label: acepta bloque [text: "..." ...] o string (retrocompatibilidad)
    lbl-spec: select spec 'label
    n/label: case [
        block? lbl-spec [
            lbl-spec: copy lbl-spec
            if none? select lbl-spec 'visible [
                append lbl-spec compose [visible: (default-label-visible? n/type)]
            ]
            make-label lbl-spec
        ]
        string? lbl-spec [
            ; Retrocompatibilidad: label: "Suma"
            make-label compose [
                text: (lbl-spec)
                visible: (default-label-visible? n/type)
            ]
        ]
        true [
            ; Sin label: usar defaults del tipo
            make-label compose [
                text: (default-label-text n/type)
                visible: (default-label-visible? n/type)
            ]
        ]
    ]
    n
]

make-port: func [
    "Crea un puerto de un nodo"
    spec [block!]
][
    make object! [
        id:        any [select spec 'id  0]
        name:      any [select spec 'name  ""]
        direction: any [select spec 'direction  'in]
        data-type: any [select spec 'type  'number]
        value:     select spec 'value
    ]
]

make-wire: func [
    "Crea un wire entre dos puertos"
    spec [block!]
    /local w lbl-spec
][
    w: make object! [
        from-node: select spec 'from
        from-port: to-word any [select spec 'from-port  'none]
        to-node:   select spec 'to
        to-port:   to-word any [select spec 'to-port    'none]
        label:     none
    ]
    lbl-spec: select spec 'label
    w/label: either lbl-spec [
        make-label lbl-spec
    ][
        make-label [visible: false]
    ]
    w
]

make-diagram: func [
    "Crea un diagrama (contenedor de nodos y wires)"
    title [string!]
][
    make object! [
        name:        title
        connector:   none
        nodes:       copy []
        wires:       copy []
        controls:    copy []
        indicators:  copy []
        front-panel: copy []
    ]
]

; ══════════════════════════════════════════════════
; FRONT PANEL ITEM (DT-022/023)
; ══════════════════════════════════════════════════
; fp-item = control o indicator del Front Panel.
; Compartilha make-label com nodos y wires (DT-022).
; Se arrastra en el canvas del panel para reposition.

fp-default-width:  100
fp-default-height:  30
fp-control-color:   50.100.180
fp-indicator-color: 175.125.20
fp-text-color:      240.245.250

fp-color: func [item-type] [
    either item-type = 'control [fp-control-color] [fp-indicator-color]
]

make-fp-item: func [
    "Crea un item del Front Panel (control o indicator)"
    spec [block!]
    /local item lbl-spec
][
    item: make object! [
        id:      any [select spec 'id      0]
        type:    any [select spec 'type    'control]
        name:    any [select spec 'name    ""]
        label:   none
        default: any [select spec 'default  0.0]
        value:   any [select spec 'value   any [select spec 'default  0.0]]
        offset:  any [select spec 'offset  0x0]
    ]

    ; Name: usar explícito, o generar automáticamente
    item/name: any [select spec 'name  gen-name to-word item/type]

    ; Label: acepta bloque [text: "..." ...] o string
    lbl-spec: select spec 'label
    item/label: case [
        block? lbl-spec [
            lbl-spec: copy lbl-spec
            if none? select lbl-spec 'visible [
                append lbl-spec compose [visible: true]
            ]
            make-label lbl-spec
        ]
        string? lbl-spec [
            make-label compose [text: (lbl-spec) visible: true]
        ]
        true [
            make-label compose [
                text: (default-label-text item/type)
                visible: true
            ]
        ]
    ]

    ; Offset: usar explícito o auto-layout (sequential vertical)
    either none? select spec 'offset [
        item/offset: 0x0
    ][
        item/offset: select spec 'offset
    ]

    item
]

; Helper: calcula position visual del item (x/y + dimensions)
fp-item-rect: func [item /local w h] [
    w: fp-default-width
    h: fp-default-height
    compose [
        x: (item/offset/x) y: (item/offset/y)
        w: (w) h: (h)
    ]
]

fp-value-text: func [item] [
    form item/value
]
