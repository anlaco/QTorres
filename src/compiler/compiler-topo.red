Red [
    Title:   "QTorres — Compilador (topological sort)"
    Purpose: "Ordenación topológica de nodos del diagrama (algoritmo de Kahn)"
]

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
        ; Ignorar wires con extremos virtuales (IDs negativos: iter, SR-left, SR-right)
        if all [w/from-node >= 0  w/to-node >= 0] [
            in-degree/(w/to-node): in-degree/(w/to-node) + 1
        ]
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
            if all [w/from-node = nid  w/to-node >= 0] [
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
; BUILD-SORTED-ITEMS
; ══════════════════════════════════════════════════
;
; Extiende topological-sort para incluir estructuras (while-loop)
; junto con los nodos normales en el orden de compilación.
;
; Las estructuras participan como nodos virtuales:
;   - Dependencia entrada: wire externo a SR-left  (to-node = st/id)
;   - Dependencia salida:  wire externo desde SR-right (from-node = st/id)
;
; Devuelve un bloque con objetos (nodo o estructura) en orden topológico.
; Para distinguirlos: los objetos de estructura tienen campo 'shift-regs.

build-sorted-items: func [
    diagram [object!]
    /local all-items in-degree id-to-item queue result nid w item
][
    all-items: copy diagram/nodes
    if all [in diagram 'structures  block? diagram/structures] [
        foreach st diagram/structures [append all-items st]
    ]

    in-degree:  make map! []
    id-to-item: make map! []
    foreach item all-items [
        in-degree/(item/id): 0
        id-to-item/(item/id): item
    ]

    foreach w diagram/wires [
        if w/from-node >= 0 [
            if not none? select in-degree w/to-node [
                in-degree/(w/to-node): in-degree/(w/to-node) + 1
            ]
        ]
    ]

    queue: copy []
    foreach item all-items [
        if in-degree/(item/id) = 0 [append queue item/id]
    ]

    result: copy []
    while [not empty? queue] [
        nid: take queue
        append result id-to-item/:nid
        foreach w diagram/wires [
            if w/from-node = nid [
                if not none? select in-degree w/to-node [
                    in-degree/(w/to-node): in-degree/(w/to-node) - 1
                    if in-degree/(w/to-node) = 0 [append queue w/to-node]
                ]
            ]
        ]
    ]

    result
]
