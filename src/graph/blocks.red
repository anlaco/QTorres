Red [
    Title:   "QTorres — Registro de bloques"
    Purpose: "Procesador del dialecto block-def y registro de tipos de bloques"
]

; ══════════════════════════════════════════════════════════
; REGISTRO
; ══════════════════════════════════════════════════════════

block-registry: copy []

; ══════════════════════════════════════════════════════════
; PROCESADOR DEL DIALECTO block-def
; ══════════════════════════════════════════════════════════
;
; Sintaxis del dialecto:
;   block 'nombre 'categoria [
;       in  <puerto> '<tipo>
;       out <puerto> '<tipo>
;       config <nombre> '<tipo> <valor-por-defecto>
;       emit [<código Red con nombres de puertos>]
;   ]
;
; El procesador parsea el cuerpo con `parse` y registra la
; entrada en block-registry como un objeto con:
;   name, category, inputs, outputs, configs, emit

block: func [
    name     [word! lit-word!]
    category [word! lit-word!]
    body     [block!]
    /local entry n cat port-name port-type cfg-type cfg-default emit-body
][
    n: to-word name
    cat: to-word category
    entry: context [
        name:     n
        category: cat
        inputs:   copy []
        outputs:  copy []
        configs:  copy []
        emit:     none
    ]
    parse body [
        any [
              ['in  set port-name word!  set port-type lit-word!]
              (append entry/inputs  make object! [name: port-name  type: port-type])
            | ['out set port-name word!  set port-type lit-word!]
              (append entry/outputs make object! [name: port-name  type: port-type])
            | ['config set port-name word!  set cfg-type lit-word!  set cfg-default skip]
              (append entry/configs make object! [name: port-name  type: cfg-type  default: cfg-default])
            | ['emit set emit-body block!]
              (entry/emit: emit-body)
            | skip
        ]
    ]
    append block-registry entry
    name
]

; ── Consulta del registro ────────────────────────────────

; Devuelve la definición completa de un bloque por nombre, o none.
find-block: func [name [word! lit-word!] /local b] [
    name: to-word name
    foreach b block-registry [
        if b/name = name [return b]
    ]
    none
]

; Devuelve los nombres de los puertos de entrada de un bloque.
block-in-ports: func [name [word!] /local b] [
    b: find-block name
    if b [collect [foreach p b/inputs [keep p/name]]]
]

; Devuelve los nombres de los puertos de salida de un bloque.
block-out-ports: func [name [word!] /local b] [
    b: find-block name
    if b [collect [foreach p b/outputs [keep p/name]]]
]

; Devuelve la categoría de un bloque ('input 'output 'math ...), o none.
block-category: func [name [word!] /local b] [
    b: find-block name
    if b [b/category]
]

; ══════════════════════════════════════════════════════════
; DEFINICIONES DE BLOQUES PRIMITIVOS
; ══════════════════════════════════════════════════════════

block 'const 'input [
    out result 'number
    config default 'number 0.0
    emit [result: default]
]

block 'add 'math [
    in a 'number
    in b 'number
    out result 'number
    emit [result: a + b]
]

block 'sub 'math [
    in a 'number
    in b 'number
    out result 'number
    emit [result: a - b]
]

block 'mul 'math [
    in a 'number
    in b 'number
    out result 'number
    emit [result: a * b]
]

block 'div 'math [
    in a 'number
    in b 'number
    out result 'number
    emit [result: a / b]
]

block 'display 'output [
    in value 'number
    emit [print value]
]

block 'control 'input [
    out result 'number
    config default 'number 0.0
    emit [result: default]
]

block 'indicator 'output [
    in value 'number
]

; ── Bloques booleanos ─────────────────────────────────────

block 'bool-const 'input [
    out result 'boolean
    config default 'boolean false
    emit [result: default]
]

block 'bool-control 'input [
    out result 'boolean
    config default 'boolean false
    emit [result: default]
]

block 'bool-indicator 'output [
    in value 'boolean
]

; ── Lógica ────────────────────────────────────────────────

block 'and-op 'logic [
    in a 'boolean
    in b 'boolean
    out result 'boolean
    emit [result: a and b]
]

block 'or-op 'logic [
    in a 'boolean
    in b 'boolean
    out result 'boolean
    emit [result: a or b]
]

block 'not-op 'logic [
    in a 'boolean
    out result 'boolean
    emit [result: not a]
]

; ── Comparadores (number → boolean) ──────────────────────

block 'gt-op 'compare [
    in a 'number
    in b 'number
    out result 'boolean
    emit [result: a > b]
]

block 'lt-op 'compare [
    in a 'number
    in b 'number
    out result 'boolean
    emit [result: a < b]
]

block 'eq-op 'compare [
    in a 'number
    in b 'number
    out result 'boolean
    emit [result: a = b]
]

