Red [
    Title:   "QTorres — Registro de bloques"
    Purpose: "Definición de los tipos de bloques disponibles"
]

; === Registro de bloques ===
; Cada bloque define sus puertos, su plantilla de código Red y su aspecto visual.

block-registry: []

; Bloque: Constante numérica
append block-registry [
    const [
        label:    "Constante"
        category: 'input
        ports: [
            out [name: "out" direction: 'out data-type: 'number]
        ]
        code-template: {~label~: ~value~}
        default-config: [value: 0.0]
    ]
]

; Bloque: Suma
append block-registry [
    add [
        label:    "Suma"
        category: 'math
        ports: [
            a [name: "a" direction: 'in data-type: 'number]
            b [name: "b" direction: 'in data-type: 'number]
            out [name: "out" direction: 'out data-type: 'number]
        ]
        code-template: {~label~: ~a~ + ~b~}
    ]
]

; Bloque: Resta
append block-registry [
    sub [
        label:    "Resta"
        category: 'math
        ports: [
            a [name: "a" direction: 'in data-type: 'number]
            b [name: "b" direction: 'in data-type: 'number]
            out [name: "out" direction: 'out data-type: 'number]
        ]
        code-template: {~label~: ~a~ - ~b~}
    ]
]

; Bloque: Multiplicación
append block-registry [
    mul [
        label:    "Multiplicación"
        category: 'math
        ports: [
            a [name: "a" direction: 'in data-type: 'number]
            b [name: "b" direction: 'in data-type: 'number]
            out [name: "out" direction: 'out data-type: 'number]
        ]
        code-template: {~label~: ~a~ * ~b~}
    ]
]

; Bloque: Display (print)
append block-registry [
    display [
        label:    "Display"
        category: 'output
        ports: [
            in [name: "in" direction: 'in data-type: 'number]
        ]
        code-template: {print ~in~}
    ]
]
