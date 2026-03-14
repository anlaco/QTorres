Red [
    Title:   "QTorres — Modelo del grafo"
    Purpose: "Estructuras de datos para nodos, puertos, wires y diagramas"
]

; === Modelo del Grafo ===
; Estructura central sobre la que operan el canvas, el compilador y el file I/O.

; Plantilla de un nodo
node-template: [
    id:     0
    type:   'none
    label:  ""
    x:      0
    y:      0
    ports:  []       ; lista de puertos
    config: []       ; configuración específica del tipo
]

; Plantilla de un puerto
port-template: [
    id:        0
    name:      ""
    direction: 'in    ; 'in o 'out
    data-type: 'number ; tipo de dato del wire
    value:     none
]

; Plantilla de un wire
wire-template: [
    id:       0
    from-node: 0
    from-port: 0
    to-node:   0
    to-port:   0
]

; Plantilla de un diagrama completo
diagram-template: [
    version: 1
    title:   ""
    nodes:   []
    wires:   []
]
