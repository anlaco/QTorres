Red [
    Title:   "QTorres — Compilador (emit dialect)"
    Purpose: "Sustitución de puertos por variables y emisión de código para bundle/unbundle/cluster"
]

; ══════════════════════════════════════════════════
; DIALECTO: emit
; ══════════════════════════════════════════════════
; El compilador no usa interpolación de strings.
; Cada bloque registrado define un bloque `emit` que es código Red
; con palabras que hacen referencia a los puertos del bloque.
;
; Ejemplo:
;   El bloque 'add tiene: emit [result: a + b]
;   El nodo "Suma" recibe wire de "A" en puerto 'a y de "B" en puerto 'b
;   El compilador sustituye: a → A, b → B, result → Suma
;   Resultado: [Suma: A + B]

; ══════════════════════════════════════════════════
; BIND-EMIT
; ══════════════════════════════════════════════════
;
; Sustituye los nombres de puertos en un bloque emit por variables reales.
;
; emit-block: bloque con palabras que corresponden a puertos
; bindings:   bloque plano de pares [puerto valor ...]

bind-emit: func [
    emit-block [block!]
    bindings   [block!]
    /local result item k v
][
    result: copy []
    foreach item emit-block [
        case [
            word? item [
                v: select bindings item
                either none? v [
                    append result item
                ][
                    either block? v [append/only result v] [append result v]
                ]
            ]
            set-word? item [
                k: to-word item
                v: select bindings k
                append result either all [v  any [word? v  lit-word? v]] [to-set-word v] [item]
            ]
            block? item [
                append/only result bind-emit item bindings
            ]
            true [append/only result item]
        ]
    ]
    result
]

; ══════════════════════════════════════════════════
; HELPERS
; ══════════════════════════════════════════════════

; Nombre de variable para el puerto de salida de un nodo.
; Convenio: name_portname  (ej: add_1_result)
; Usa node/name (DT-024), nunca node/label/text.
port-var: func [node [object!] port-name [word! lit-word!]] [
    to-word rejoin [node/name "_" to-word port-name]
]

; Construye los bindings [puerto var ...] para un nodo concreto del diagrama:
;   - puertos de salida: variable propia (label_portname)
;   - puertos de entrada: variable del nodo fuente conectado por wire
;   - configs: valor del nodo o el default de la definición
build-bindings: func [
    node    [object!]
    diagram [object!]
    bdef    [object!]
    /local bindings p w src cfg-val found _var
][
    bindings: copy []

    foreach p bdef/outputs [
        append bindings p/name
        append bindings port-var node p/name
    ]

    foreach p bdef/inputs [
        found: false
        foreach w diagram/wires [
            if all [w/to-node = node/id  (to-word w/to-port) = p/name] [
                found: true
                case [
                    w/from-node < 0 [
                        _var: either w/from-node = -1 [
                            to-word rejoin ["_" form w/from-port]
                        ][
                            w/from-port
                        ]
                        append bindings p/name
                        append bindings _var
                    ]
                    true [
                        src: find-node-by-id diagram/nodes w/from-node
                        either src [
                            append bindings p/name
                            append bindings port-var src w/from-port
                        ][
                            if all [in diagram 'structures  block? diagram/structures] [
                                foreach st diagram/structures [
                                    if st/id = w/from-node [
                                        append bindings p/name
                                        append bindings to-word rejoin ["_" form w/from-port]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        if all [not found  not none? p/default] [
            append bindings p/name
            append/only bindings p/default
        ]
    ]

    foreach cfg bdef/configs [
        cfg-val: either none? select node/config cfg/name [cfg/default] [select node/config cfg/name]
        append bindings cfg/name
        append/only bindings cfg-val
    ]

    bindings
]

; Devuelve true si el primer output del bloque es de tipo array.
node-array-input?: func [node /local bdef] [
    bdef: find-block to-word node/type
    if all [bdef  not empty? bdef/outputs] [
        return bdef/outputs/1/type = 'array
    ]
    false
]

; Devuelve true si el primer output del bloque es de tipo booleano.
node-boolean-input?: func [node /local bdef] [
    bdef: find-block to-word node/type
    if all [bdef  not empty? bdef/outputs] [
        return bdef/outputs/1/type = 'boolean
    ]
    false
]

; Devuelve true si el primer output del bloque es de tipo string.
node-string-input?: func [node /local bdef] [
    bdef: find-block to-word node/type
    if all [bdef  not empty? bdef/outputs] [
        return bdef/outputs/1/type = 'string
    ]
    false
]

; ══════════════════════════════════════════════════
; EMIT-BUNDLE / EMIT-UNBUNDLE
; ══════════════════════════════════════════════════
;
; Los nodos bundle/unbundle tienen puertos dinámicos (config/fields),
; por lo que no pueden usar el flujo estándar bind-emit + build-bindings.
; Generan código directamente manipulando bloques Red.

; Genera código para un nodo bundle:
;   bundle_1_result: make object! [campo1: var1  campo2: var2 ...]
emit-bundle: func [
    node   [object!]
    diagram [object!]
    /local result-var fields obj-body fn ft w src-nd field-var code
][
    result-var: port-var node 'result
    fields: cluster-fields node
    obj-body: copy []

    foreach [fn ft] fields [
        field-var: fn
        foreach w diagram/wires [
            if all [w/to-node = node/id  (to-word w/to-port) = fn] [
                src-nd: find-node-by-id diagram/nodes w/from-node
                if src-nd [field-var: port-var src-nd to-word w/from-port]
            ]
        ]
        append obj-body to-set-word fn
        append obj-body field-var
    ]

    code: copy []
    append code to-set-word result-var
    append code 'make
    append code object!
    append/only code obj-body
    code
]

; Genera código para un nodo unbundle:
;   unbundle_1_campo1: cluster_var/campo1
;   unbundle_1_campo2: cluster_var/campo2  ...
emit-unbundle: func [
    node   [object!]
    diagram [object!]
    /local fields cluster-var fn ft w src-nd out-var code
][
    fields: cluster-fields node
    cluster-var: none

    foreach w diagram/wires [
        if all [w/to-node = node/id  (to-word w/to-port) = 'cluster-in] [
            src-nd: find-node-by-id diagram/nodes w/from-node
            if src-nd [cluster-var: port-var src-nd to-word w/from-port]
        ]
    ]
    if none? cluster-var [
        print rejoin ["WARNING: Unbundle '" node/name "' — cluster-in no conectado"]
        return copy []
    ]

    code: copy []
    foreach [fn ft] fields [
        out-var: port-var node fn
        append code to-set-word out-var
        append/only code to-path reduce [cluster-var fn]
    ]
    code
]

; Genera código para un nodo cluster-control:
;   ctrl_1_out: make object! [campo1: to-float ctrl_1_campo1_fld/text  ...]
emit-cluster-control: func [
    node    [object!]
    diagram [object!]
    /local out-var fp-item fields fn ft fld-name obj-body code
][
    out-var: port-var node 'out
    fp-item: none
    foreach it diagram/front-panel [
        if it/name = node/name [fp-item: it  break]
    ]
    fields: either fp-item [fp-cluster-fields fp-item] [copy []]
    obj-body: copy []
    foreach [fn ft] fields [
        fld-name: to-word rejoin [form node/name "_" form fn "_fld"]
        append obj-body to-set-word fn
        append obj-body compose [
            (switch ft [
                boolean [compose [any [attempt [to-logic (to-path reduce [fld-name 'data])]  false]]]
                string  [to-path reduce [fld-name 'text]]
            ])
        ]
        if not find [boolean string] ft [
            clear back tail obj-body
            append/only obj-body to-path reduce [fld-name 'text]
            last-val: last obj-body
            remove back tail obj-body
            append obj-body 'to-float
            append obj-body last-val
        ]
    ]
    code: copy []
    append code to-set-word out-var
    append code 'make
    append code object!
    append/only code obj-body
    code
]

; Genera código para un nodo cluster-indicator:
emit-cluster-indicator: func [
    node    [object!]
    diagram [object!]
    /local fields in-var w src-nd fp-item fn ft fld-name code
][
    in-var: none
    foreach w diagram/wires [
        if all [w/to-node = node/id  (to-word w/to-port) = 'in] [
            src-nd: find-node-by-id diagram/nodes w/from-node
            if src-nd [in-var: port-var src-nd to-word w/from-port]
        ]
    ]
    if none? in-var [return copy []]
    fp-item: none
    foreach it diagram/front-panel [
        if it/name = node/name [fp-item: it  break]
    ]
    fields: either fp-item [fp-cluster-fields fp-item] [copy []]
    code: copy []
    foreach [fn ft] fields [
        fld-name: to-word rejoin [form node/name "_" form fn "_ind"]
        append code to-set-path reduce [fld-name 'text]
        append/only code to-path reduce [in-var fn]
    ]
    code
]

; Versión headless de emit-cluster-control: usa config 'default en lugar de faces del FP.
emit-cluster-control-headless: func [
    node    [object!]
    diagram [object!]
    /local out-var fp-item fields defaults fn ft fval obj-body code
][
    out-var: port-var node 'out
    fp-item: none
    foreach it diagram/front-panel [if it/name = node/name [fp-item: it  break]]
    fields:   either fp-item [fp-cluster-fields fp-item] [copy []]
    defaults: either fp-item [select fp-item/config 'default] [none]
    obj-body: copy []
    foreach [fn ft] fields [
        fval: either defaults [select defaults fn] [none]
        append obj-body to-set-word fn
        case [
            ft = 'boolean [append obj-body any [all [logic? fval fval]  false]]
            ft = 'string  [append obj-body any [all [string? fval fval] ""]]
            true          [append obj-body any [fval 0.0]]
        ]
    ]
    code: copy []
    append code to-set-word out-var
    append code 'make
    append code object!
    append/only code obj-body
    code
]

; Versión headless de emit-cluster-indicator: imprime cada campo del cluster.
emit-cluster-indicator-headless: func [
    node    [object!]
    diagram [object!]
    /local fp-item fields in-var w src-nd fn ft lbl code
][
    in-var: none
    foreach w diagram/wires [
        if all [w/to-node = node/id  (to-word w/to-port) = 'in] [
            src-nd: find-node-by-id diagram/nodes w/from-node
            if src-nd [in-var: port-var src-nd to-word w/from-port]
        ]
    ]
    if none? in-var [return copy []]
    fp-item: none
    foreach it diagram/front-panel [if it/name = node/name [fp-item: it  break]]
    fields: either fp-item [fp-cluster-fields fp-item] [copy []]
    lbl: either all [node/label  object? node/label] [node/label/text] [any [node/name ""]]
    code: copy []
    foreach [fn ft] fields [
        append code compose [
            print rejoin [(rejoin [lbl " — " form fn]) ": " form (to-path reduce [in-var fn])]
        ]
    ]
    code
]
