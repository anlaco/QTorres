Red [
    Title:   "QTorres — Compilador"
    Purpose: "Transforma un diagrama (modelo de grafo) en código Red dentro del .qvi"
]

; ══════════════════════════════════════════════════
; DIALECTO: emit
; ══════════════════════════════════════════════════
; El compilador no usa interpolación de strings.
; Cada bloque registrado define un bloque `emit` que es código Red
; con palabras que hacen referencia a los puertos del bloque.
;
; El compilador:
;   1. Ordena los nodos topológicamente
;   2. Para cada nodo, busca su definición en el block-registry
;   3. Toma el bloque `emit` y sustituye las palabras de los puertos
;      por los nombres reales de las variables (que vienen de los wires)
;   4. El resultado es código Red generado por manipulación de bloques Red
;
; Ejemplo:
;   El bloque 'add tiene: emit [result: a + b]
;   El nodo "Suma" recibe wire de "A" en puerto 'a y de "B" en puerto 'b
;   El compilador sustituye: a → A, b → B, result → Suma
;   Resultado: [Suma: A + B]
;
; Esto es manipulación de bloques Red, no strings. El código generado
; es un bloque Red que se puede componer, inspeccionar y ejecutar.

; ══════════════════════════════════════════════════
; TOPOLOGICAL-SORT
; ══════════════════════════════════════════════════
;
; Algoritmo de Kahn (BFS).
; Entrada:  un objeto diagrama con /nodes y /wires (make-diagram).
; Salida:   un block! con los nodos en orden de compilación,
;           o un error si se detecta un ciclo.

topological-sort: func [
    diagram [object!]
    /local nodes wires in-degree id-to-node queue result nid w
][
    nodes:  diagram/nodes
    wires:  diagram/wires

    in-degree:  make map! []
    id-to-node: make map! []
    foreach n nodes [
        in-degree/(n/id): 0
        id-to-node/(n/id): n
    ]

    foreach w wires [
        in-degree/(w/to-node): in-degree/(w/to-node) + 1
    ]

    queue: copy []
    foreach n nodes [
        if in-degree/(n/id) = 0 [append queue n/id]
    ]

    result: copy []
    while [not empty? queue] [
        nid: take queue
        append result id-to-node/:nid
        foreach w wires [
            if w/from-node = nid [
                in-degree/(w/to-node): in-degree/(w/to-node) - 1
                if in-degree/(w/to-node) = 0 [append queue w/to-node]
            ]
        ]
    ]

    if (length? result) <> (length? nodes) [
        cause-error 'user 'message ["topological-sort: ciclo detectado en el diagrama"]
    ]

    result
]

; ══════════════════════════════════════════════════
; BIND-EMIT
; ══════════════════════════════════════════════════
;
; Sustituye los nombres de puertos en un bloque emit por variables reales.
;
; emit-block: bloque con palabras que corresponden a puertos
;             Ejemplo: [result: a + b]
; bindings:   bloque plano de pares [puerto valor ...]
;             Los valores pueden ser cualquier tipo Red.
;             Ejemplo: [a X  b Y  result Suma]
;
; Maneja word!, set-word! y bloques anidados. El resto pasa sin cambios.

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
                append result either v [v] [item]
            ]
            set-word? item [
                k: to-word item
                v: select bindings k
                append result either all [v  any [word? v  lit-word? v]] [to-set-word v] [item]
            ]
            block? item [
                append/only result bind-emit item bindings
            ]
            true [append result item]
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
    /local bindings p w src cfg-val
][
    bindings: copy []

    foreach p bdef/outputs [
        append bindings p/name
        append bindings port-var node p/name
    ]

    foreach p bdef/inputs [
        foreach w diagram/wires [
            if all [w/to-node = node/id  (to-word w/to-port) = p/name] [
                foreach src diagram/nodes [
                    if src/id = w/from-node [
                        append bindings p/name
                        append bindings port-var src w/from-port
                    ]
                ]
            ]
        ]
    ]

    foreach cfg bdef/configs [
        ; any [none false] = none en Red → usar either/none? explícito
        cfg-val: either none? select node/config cfg/name [cfg/default] [select node/config cfg/name]
        append bindings cfg/name
        append bindings cfg-val
    ]

    bindings
]

; Devuelve true si el primer output del bloque es de tipo booleano.
node-boolean-input?: func [node /local bdef] [
    bdef: find-block to-word node/type
    if all [bdef  not empty? bdef/outputs] [
        return bdef/outputs/1/type = 'boolean
    ]
    false
]

; ══════════════════════════════════════════════════
; COMPILE-BODY
; ══════════════════════════════════════════════════
;
; Genera el bloque de cómputo headless listo para ejecutar con do.
; Incluye todos los nodos: inputs (const), math (add/sub...) y outputs (display).

compile-body: func [
    diagram [object!]
    /local sorted code node bdef
][
    sorted: topological-sort diagram
    code: copy []
    foreach node sorted [
        bdef: find-block node/type
        if all [bdef  bdef/emit] [
            append code bind-emit bdef/emit (build-bindings node diagram bdef)
        ]
    ]
    code
]

; ══════════════════════════════════════════════════
; COMPILE-DIAGRAM
; ══════════════════════════════════════════════════
;
; Genera los componentes de código para un VI completo:
;   /headless:  block! ejecutable con do (usa config defaults)
;   /ui-layout: block! para view layout (controles + botón Run + indicadores)
;
; Para nodos de categoría 'input: el run-body lee de campos de texto del UI.
; Para nodos de categoría 'output: el run-body escribe en etiquetas del UI.
; Para nodos math: usa bind-emit igual que compile-body.

compile-diagram: func [
    diagram [object!]
    /local sorted headless run-body ui-layout node bdef face-n cfg-val w src src-var bindings
][
    sorted: topological-sort diagram
    headless: compile-body diagram

    ; ── Cuerpo del botón Run (modo UI) ────────────────────────
    run-body: copy []
    foreach node sorted [
        bdef: find-block node/type
        if none? bdef [continue]
        case [
            bdef/category = 'input [
                face-sym: to-word rejoin ["f_" node/id]
                either node-boolean-input? node [
                    append run-body compose [(to-set-word port-var node 'result) (to-path reduce [face-sym 'data])]
                ][
                    append run-body compose [(to-set-word port-var node 'result) to-float (to-path reduce [face-sym 'text])]
                ]
            ]
            bdef/category = 'output [
                face-sym: to-word rejoin ["t_" node/id]
                foreach w diagram/wires [
                    if w/to-node = node/id [
                        foreach src diagram/nodes [
                            if src/id = w/from-node [
                                src-var: port-var src to-word w/from-port
                                append run-body compose [(to set-path! reduce [face-sym 'text]) form (src-var)]
                            ]
                        ]
                    ]
                ]
            ]
            true [
                if bdef/emit [
                    bindings: build-bindings node diagram bdef
                    append run-body bind-emit bdef/emit bindings
                ]
            ]
        ]
    ]

    ; ── Layout del Front Panel ────────────────────────────────
    ui-layout: copy []
    foreach node sorted [
        bdef: find-block node/type
        if none? bdef [continue]
        if bdef/category = 'input [
            face-n: to-word rejoin ["f_" node/id]
            ; any [none false] = none en Red (false es falsy) → usar either/none? explícito
            cfg-val: either none? select node/config 'default [
                either node-boolean-input? node [false] [0.0]
            ][
                select node/config 'default
            ]
            node-label: either all [node/label  object? node/label] [node/label/text] [any [node/name ""]]
            append ui-layout 'text
            ; UI layout usa label/text (display) para textos visibles (DT-024)
            append ui-layout node-label
            append ui-layout to-set-word face-n
            either node-boolean-input? node [
                ; Control booleano: check face, lee face/data (logic!)
                append ui-layout 'check
                append ui-layout node-label
                append ui-layout cfg-val
            ][
                append ui-layout 'field
                append ui-layout form cfg-val
            ]
        ]
    ]
    append ui-layout 'button
    append ui-layout "Run"
    append/only ui-layout run-body
    foreach node sorted [
        bdef: find-block node/type
        if none? bdef [continue]
        if bdef/category = 'output [
            face-n: to-word rejoin ["t_" node/id]
            append ui-layout 'text
            ; UI layout usa label/text (display) para textos visibles (DT-024)
            append ui-layout either all [node/label  object? node/label] [node/label/text] [any [node/name ""]]
            append ui-layout to-set-word face-n
            append ui-layout 'text
            append ui-layout "---"
        ]
    ]

    result-map: make map! []
    result-map/headless:  headless
    result-map/ui-layout: ui-layout
    result-map
]
