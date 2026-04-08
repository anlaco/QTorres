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

    ; Config: cargar desde spec si está presente (permite round-trip de valores)
    if select spec 'config [n/config: copy select spec 'config]

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

wire-port-in-used?: func [
    "Devuelve true si algún wire ya conecta al puerto 'in' to-node/to-port (QA-018)"
    wires-block [block!] to-node [integer!] to-port [word!]
    /local w
][
    foreach w wires-block [
        if all [w/to-node = to-node  w/to-port = to-port] [return true]
    ]
    false
]

make-shift-register: func [
    "Crea un shift register (par de terminales ▲/▼) para un while-loop"
    spec [block!]
    /local sr dt
][
    dt: any [select spec 'data-type  'number]
    sr: make object! [
        id:         0
        name:       ""
        data-type:  'number
        init-value: 0.0
        y-offset:   40
    ]
    sr/id:         any [select spec 'id          0]
    sr/data-type:  dt
    sr/init-value: either none? select spec 'init-value [
        case [dt = 'string [""]  dt = 'boolean [false]  dt = 'array [copy []]  true [0.0]]
    ][
        select spec 'init-value
    ]
    sr/y-offset:   any [select spec 'y-offset    40]
    sr/name:       any [select spec 'name        gen-name 'sr]
    sr
]

make-frame: func [
    "Crea un frame para una Case Structure (contiene nodos y wires propios)"
    spec [block!]
    /local f
][
    f: make object! [
        id:        0
        label:     "0"
        nodes:     copy []
        wires:     copy []
    ]
    f/id:    any [select spec 'id    0]
    f/label: any [select spec 'label "0"]
    f
]

make-structure: func [
    "Crea una estructura contenedora (while-loop, for-loop, case-structure) del Block Diagram"
    spec [block!]
    /local s lbl-spec frames-spec fr
][
    s: make object! [
        id:           0
        type:         'while-loop
        name:         ""
        label:        none
        x:            0
        y:            0
        w:            300
        h:            200
        nodes:        copy []
        wires:        copy []
        cond-wire:    none
        shift-regs:   copy []
        frames:       copy []
        active-frame: 0
        selector-wire: none
    ]
    s/id:   any [select spec 'id    0]
    s/type: any [select spec 'type  'while-loop]
    s/x:    any [select spec 'x     0]
    s/y:    any [select spec 'y     0]
    s/w:    any [select spec 'w     300]
    s/h:    any [select spec 'h     200]
    s/name: any [select spec 'name  gen-name to-word s/type]
    lbl-spec: select spec 'label
    s/label: case [
        block? lbl-spec  [make-label lbl-spec]
        string? lbl-spec [make-label compose [text: (lbl-spec) visible: (true)]]
        s/type = 'for-loop [make-label compose [text: "For Loop"  visible: (true) offset: 0x-15]]
        s/type = 'case-structure [make-label compose [text: "Case Structure" visible: (true) offset: 0x-15]]
        true               [make-label compose [text: "While Loop" visible: (true) offset: 0x-15]]
    ]
    s/active-frame: any [select spec 'active-frame 0]
    frames-spec: select spec 'frames
    if frames-spec [
        parse frames-spec [
            any [
                'frame set fr block! (append s/frames make-frame fr)
                | skip
            ]
        ]
    ]
    s
]

make-diagram: func [
    "Crea un diagrama (contenedor de nodos, wires y estructuras)"
    title [string!]
][
    make object! [
        name:        title
        connector:   none
        nodes:       copy []
        wires:       copy []
        structures:  copy []
        controls:    copy []
        indicators:  copy []
        front-panel: copy []
    ]
]

; ══════════════════════════════════════════════════
; CLUSTER — Helpers para puertos dinámicos
; ══════════════════════════════════════════════════
; bundle/unbundle tienen puertos que dependen de los campos
; definidos por el usuario en node/config/fields.
;
; Formato de config/fields:
;   [nombre 'string  voltaje 'number  activo 'boolean ...]
;   (pares word! + lit-word!, uno por campo)

cluster-fields: func [
    "Devuelve la lista de campos del cluster [nombre 'tipo ...] desde node/config/fields"
    node [object!]
    /local fields
][
    fields: select node/config 'fields
    either fields [fields] [copy []]
]

cluster-in-ports: func [
    "Devuelve los nombres de puertos de entrada dinámicos de bundle y cluster-indicator (uno por campo)"
    "Para otros tipos devuelve [] — sus entradas son estáticas"
    node [object!]
    /local result
][
    unless find [bundle cluster-indicator] node/type [return copy []]
    result: copy []
    foreach [field-name field-type] cluster-fields node [
        append result field-name
    ]
    result
]

cluster-out-ports: func [
    "Devuelve los nombres de puertos de salida dinámicos de unbundle y cluster-control (uno por campo)"
    "Para otros tipos devuelve [] — sus salidas son estáticas"
    node [object!]
    /local result
][
    unless find [unbundle cluster-control] node/type [return copy []]
    result: copy []
    foreach [field-name field-type] cluster-fields node [
        append result field-name
    ]
    result
]

cluster-field-type: func [
    "Devuelve el tipo de un campo concreto del cluster ('number, 'boolean, 'string)"
    node [object!]  field [word!]
    /local fields i
][
    fields: cluster-fields node
    i: 1
    while [i <= (length? fields)] [
        if fields/:i = field [return fields/(i + 1)]
        i: i + 2
    ]
    'number
]

; ══════════════════════════════════════════════════
; HELPERS DE BÚSQUEDA
; ══════════════════════════════════════════════════

find-node-by-id: func [nodes id /local node] [
    foreach node nodes [
        if node/id = id [return node]
    ]
    none
]

; Actualiza o añade una clave en node/config (4B — evita duplicar el patrón either/find).
set-config: func [node key value /local pos] [
    either pos: find node/config key [pos/2: value][append node/config reduce [key value]]
]

; Crea el modelo de datos del diagrama (movido de canvas.red — 4A).
make-diagram-model: func [] [
    make object! [
        nodes:          copy []
        wires:          copy []
        structures:     copy []
        front-panel:    copy []
        next-id:        1
        selected-node:  none
        selected-wire:  none
        selected-fp:    none
        selected-struct: none
        drag-node:      none
        drag-fp:        none
        drag-struct:    none
        drag-struct-off: none
        resize-struct:  none
        drag-off:       none
        drag-is-label:  false
        wire-src:        none
        wire-port:       none
        wire-src-struct: none
        wire-src-sr:     none
        selected-sr:     none
        mouse-pos:       none
        broken-wire:     none
        canvas-ref:      none
        size:            0x0
    ]
]

; make-fp-item y fp-value-text viven en src/ui/panel/panel.red (canónico).
; model.red no duplica lógica de Front Panel.

; ══════════════════════════════════════════════════
; WIRE PROTECTION — QA-018: Prevent multiple wires to same input port
; ══════════════════════════════════════════════════

wire-port-in-used?: func [
    "Check if a destination port already has a wire connected to it"
    wires [block!]
    to-node-id [integer!]
    to-port [word! string!]
    /local w target-port
][
    target-port: to-word to-port
    foreach w wires [
        if all [
            w/to-node = to-node-id
            (to-word w/to-port) = target-port
        ] [
            return true
        ]
    ]
    false
]

#include %blocks.red
