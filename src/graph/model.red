Red [
    Title:   "Telekino — Modelo del grafo"
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
        file:   none
    ]
    n/id: any [select spec 'id  0]
    n/x:  any [select spec 'x   0]
    n/y:  any [select spec 'y   0]

    ; Name: usar explícito, o generar automáticamente
    n/name: any [select spec 'name  gen-name to-word n/type]

    ; Config: cargar desde spec si está presente (permite round-trip de valores)
    if select spec 'config [n/config: copy select spec 'config]

    ; File: cargar desde spec si está presente (para nodos subvi, Fase 3)
    if select spec 'file [n/file: select spec 'file]

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
    "Devuelve los nombres de puertos de entrada dinámicos de bundle (uno por campo)"
    "Para otros tipos devuelve [] — sus entradas son estáticas"
    node [object!]
    /local result
][
    unless node/type = 'bundle [return copy []]
    result: copy []
    foreach [field-name field-type] cluster-fields node [
        append result field-name
    ]
    result
]

cluster-out-ports: func [
    "Devuelve los nombres de puertos de salida dinámicos de unbundle (uno por campo)"
    "Para otros tipos devuelve [] — sus salidas son estáticas"
    node [object!]
    /local result
][
    unless node/type = 'unbundle [return copy []]
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
; SUBVI HELPERS
; ══════════════════════════════════════════════════
; Para nodos 'subvi: cargan su connector desde el fichero .qvi referenciado.

load-subvi-connector: func [
    "Carga el connector de un .qvi y devuelve bloque con inputs, outputs y func-name"
    path [file!]
    /local src qd conn inputs outputs func-name title-meta pos blk pin-val
][
    if not exists? path [
        return reduce ['inputs copy [] 'outputs copy [] 'func-name ""]
    ]

    src: load path
    pos: find src to-set-word 'qvi-diagram
    if none? pos [
        return reduce ['inputs copy [] 'outputs copy [] 'func-name ""]
    ]

    qd: norm-spec pos/2
    conn: select qd 'connector

    inputs: copy []
    outputs: copy []
    func-name: ""

    if block? conn [
        parse conn [
            any [
                'input set blk block! (
                    pin-val: any [select blk 'pin 0]
                    append inputs reduce [
                        pin-val
                        any [select blk 'label ""]
                        any [select blk 'id 0]
                    ]
                )
                | 'output set blk block! (
                    pin-val: any [select blk 'pin 0]
                    append outputs reduce [
                        pin-val
                        any [select blk 'label ""]
                        any [select blk 'id 0]
                    ]
                )
                | skip
            ]
        ]
    ]

    ; Obtener título del Red header (Red [title: "suma"])
    if all [not empty? src  src/1 = 'Red  block? src/2] [
        func-name: any [select src/2 'title  ""]
    ]

    ; Fallback: nombre del fichero sin extensión
    if empty? func-name [
        func-name: to-string first split last split-path path "."
    ]

    reduce ['inputs inputs 'outputs outputs 'func-name func-name]
]

make-subvi-node: func [
    "Crea un nodo subvi cargando su connector desde el fichero referenciado"
    spec [block!]
    /local n conn-data file-path
][
    n: make-node spec

    file-path: select spec 'file
    if file? file-path [
        n/file: file-path
        conn-data: load-subvi-connector file-path

        ; Almacenar connector y func-name en config
        set-config n 'connector reduce [
            'inputs conn-data/inputs
            'outputs conn-data/outputs
        ]
        set-config n 'func-name conn-data/func-name
    ]

    n
]

; Convierte set-words a words en un bloque (recursivo para sub-bloques).
; Usado para normalizar especificaciones de qvi-diagram.
norm-spec: func [spec [block!] /local result item] [
    result: copy []
    foreach item spec [
        case [
            set-word? item [append result to-word item]
            block?    item [append/only result norm-spec item]
            true           [append result item]
        ]
    ]
    result
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
        scroll-x:        0       ; BD scroll horizontal (píxeles de contenido)
        scroll-y:        0       ; BD scroll vertical
        fp-scroll-x:     0       ; FP scroll horizontal
        fp-scroll-y:     0       ; FP scroll vertical
    ]
]

; ══════════════════════════════════════════════════
; FP-ITEM MODEL (movido desde panel.red — 4A refactor)
; ══════════════════════════════════════════════════

fp-cluster-fields: func [
    "Devuelve la lista de campos del cluster FP item [nombre tipo ...]"
    item [object!]
    /local cfg flds
][
    cfg: any [item/config  copy []]
    flds: select cfg 'fields
    either flds [flds] [copy []]
]

fp-default-label: func [item-type] [
    case [
        item-type = 'bool-control   ["Boolean"]
        item-type = 'bool-indicator ["Boolean"]
        item-type = 'str-control    ["String"]
        item-type = 'str-indicator  ["String"]
        item-type = 'arr-control      ["Array"]
        item-type = 'arr-indicator    ["Array"]
        item-type = 'cluster-control  ["Cluster"]
        item-type = 'cluster-indicator ["Cluster"]
        item-type = 'waveform-chart   ["Chart"]
        item-type = 'waveform-graph   ["Graph"]
        true                          ["Numeric"]
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
            find [bool-control bool-indicator]     raw-type ['boolean]
            find [str-control  str-indicator]      raw-type ['string]
            find [arr-control  arr-indicator]      raw-type ['array]
            find [cluster-control cluster-indicator] raw-type ['cluster]
            find [waveform-chart waveform-graph]   raw-type ['waveform]
            true                                   ['numeric]
        ]
        name:      any [select spec 'name      ""]
        label:     none
        config:    copy any [select spec 'config  copy []]
        default:   case [
            find [bool-control bool-indicator] raw-type [
                any [select spec 'default  false]
            ]
            find [str-control str-indicator] raw-type [
                ; copy siempre: las literales "" en Red son constantes compartidas
                copy any [select spec 'default  ""]
            ]
            find [arr-control arr-indicator] raw-type [
                ; copy siempre: los bloques [] son constantes compartidas en Red
                copy any [select spec 'default  copy []]
            ]
            find [cluster-control cluster-indicator] raw-type [
                ; block de pares word/valor: [name "" voltage 0.0 active false]
                copy any [select spec 'default  copy []]
            ]
            find [waveform-chart waveform-graph] raw-type [
                ; waveform: buffer de valores (array vacío inicialmente)
                copy any [select spec 'default  copy []]
            ]
            true [
                any [select spec 'default  0.0]
            ]
        ]
        value:     none
        offset:    any [select spec 'offset    0x0]
    ]
    item/type: raw-type
    ; copy para strings y arrays: garantiza que control e indicador son objetos independientes
    item/value: case [
        find [str-control str-indicator] raw-type [
            copy any [select spec 'value  item/default]
        ]
        find [arr-control arr-indicator] raw-type [
            copy any [select spec 'value  item/default]
        ]
        find [cluster-control cluster-indicator] raw-type [
            copy any [select spec 'value  copy item/default]
        ]
        find [waveform-chart waveform-graph] raw-type [
            ; waveform: buffer de valores (array)
            copy any [select spec 'value  item/default]
            ; Asegurar que value es un array
            if none? item/value [item/value: copy []]
            item/value
        ]
        true [
            any [select spec 'value  item/default]
        ]
    ]
    ; Asegurar que value nunca es none
    if none? item/value [
        item/value: either find [waveform-chart waveform-graph] raw-type [copy []] [0.0]
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
