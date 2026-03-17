Red [
    Title:   "QTorres — File I/O"
    Purpose: "Guardar y cargar VIs (.qvi), proyectos (.qproj) y otros tipos de fichero QTorres"
]

; ══════════════════════════════════════════════════
; SERIALIZE-DIAGRAM
; ══════════════════════════════════════════════════
;
; Convierte el objeto diagrama en memoria al formato de bloque qvi-diagram.
; Formato de nodo:  node [id 1  type const  label "A"  x 100  y 100  config []]
; Formato de wire:  wire [from 1  from-port result  to 2  to-port a]

serialize-diagram: func [
    diagram [object!]
    /local nodes-block wires-block n w
][
    nodes-block: copy []
    foreach n diagram/nodes [
        append nodes-block 'node
        append/only nodes-block reduce [
            'id n/id  'type n/type  'label n/label
            'x n/x   'y n/y        'config n/config
        ]
    ]

    wires-block: copy []
    foreach w diagram/wires [
        append wires-block 'wire
        append/only wires-block reduce [
            'from w/from-node  'from-port w/from-port
            'to   w/to-node    'to-port   w/to-port
        ]
    ]

    reduce [
        'meta       [description: "" version: 1 author: "" tags: []]
        'icon       []
        'block-diagram reduce ['nodes nodes-block 'wires wires-block]
    ]
]

; ══════════════════════════════════════════════════
; SAVE-VI
; ══════════════════════════════════════════════════
;
; Escribe el fichero .qvi completo:
;   1. Cabecera Red con Needs: 'View
;   2. qvi-diagram: [...] — fuente de verdad (DT-011)
;   3. Código generado: modo dual UI/headless (DT-009, DT-012)
;
; Run NO llama a save-vi. Son operaciones independientes (DT-010).

save-vi: func [
    path    [file!]
    diagram [object!]
    /local compiled qd content
][
    compiled: compile-diagram diagram
    qd: serialize-diagram diagram

    content: rejoin [
        {Red [Title: } mold diagram/name { Needs: 'View]} "^/"
        "^/"
        "qvi-diagram: " mold qd "^/"
        "^/"
        "; --- CÓDIGO GENERADO — no editar, se regenera al guardar ---^/"
        "either empty? system/options/args [^/"
        "    view layout " mold compiled/ui-layout "^/"
        "][^/"
        "    " mold/only compiled/headless "^/"
        "]^/"
    ]

    write path content
    path
]

; ══════════════════════════════════════════════════
; LOAD-VI
; ══════════════════════════════════════════════════
;
; Lee un fichero .qvi, extrae qvi-diagram y reconstruye el modelo en memoria.
; El código generado se ignora — QTorres recompila desde qvi-diagram (DT-011).
; Un .qvi con solo qvi-diagram (sin código generado) es válido.

load-vi: func [
    path [file!]
    /local src pos qd bd-data nodes-data wires-data d node-spec wire-spec
][
    src: load path

    ; Buscar el set-word qvi-diagram: en el bloque cargado
    pos: find src to-set-word 'qvi-diagram
    if none? pos [
        cause-error 'user 'message ["load-vi: qvi-diagram no encontrado en " mold path]
    ]
    qd: pos/2

    bd-data:    select qd 'block-diagram
    if none? bd-data [
        cause-error 'user 'message ["load-vi: block-diagram no encontrado"]
    ]

    d: make-diagram any [select qd 'name  form path]

    nodes-data: select bd-data 'nodes
    wires-data: select bd-data 'wires

    if nodes-data [
        parse nodes-data [
            any [
                'node set node-spec block! (
                    append d/nodes make-node node-spec
                )
                | skip
            ]
        ]
    ]

    if wires-data [
        parse wires-data [
            any [
                'wire set wire-spec block! (
                    append d/wires make object! [
                        from-node: select wire-spec 'from
                        from-port: select wire-spec 'from-port
                        to-node:   select wire-spec 'to
                        to-port:   select wire-spec 'to-port
                    ]
                )
                | skip
            ]
        ]
    ]

    d
]
