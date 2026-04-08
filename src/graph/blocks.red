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

; ── Bloques string ────────────────────────────────────────

block 'str-const 'input [
    out result 'string
    config default 'string ""
    emit [result: default]
]

block 'str-control 'input [
    out result 'string
    config default 'string ""
    emit [result: default]
]

block 'str-indicator 'output [
    in value 'string
]

block 'concat 'string [
    in a 'string
    in b 'string
    out result 'string
    emit [result: rejoin [a b]]
]

block 'str-length 'string [
    in a 'string
    out result 'number
    emit [result: to-float length? a]
]

block 'to-string 'string [
    in a 'number
    out result 'string
    emit [result: form a]
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


; ── Estructuras ───────────────────────────────────────────
; Las estructuras son contenedores, no tienen puertos externos en 14a
; (sin shift registers, sin wires cruzando bordes).
; La lógica de compilación se implementa en compile-structure.

block 'while-loop 'structure [
    ; Terminales internos virtuales (no son puertos normales):
    ;   i        — iteración, salida 'number hacia nodos internos
    ;   cond     — condición, entrada 'boolean desde nodo interno
]

block 'for-loop 'structure [
    ; Terminales:
    ;   N    — cuenta de iteraciones, entrada 'number desde nodo EXTERNO (obligatorio)
    ;   i    — iteración 0-based, salida 'number hacia nodos internos
]

block 'case-structure 'structure [
    ; Terminales:
    ;   selector — entrada 'number o 'boolean desde nodo EXTERNO (obligatorio)
    ; Frames: cada frame tiene sus propios nodes y wires
    ;   frames[0], frames[1], ..., frames[n] — uno activo según valor de selector
]

; Terminal de iteración como bloque virtual (para type-check al cablear)
block 'iter 'structure-virtual [
    out i 'number
    ; sin emit: la variable _X_N_i ya la genera compile-structure
]

; ── Array helpers ─────────────────────────────────────────
; bind-emit no maneja path! con refinements (copy/part) — se encapsula en función
arr-subset-helper: func [arr st ln] [copy/part skip arr to-integer st to-integer ln]

; ── Array ─────────────────────────────────────────────────

block 'arr-const 'input [
    out result 'array
    config default 'array []
    emit [result: copy default]
]

block 'arr-control 'input [
    out result 'array
    config default 'array []
    emit [result: copy default]
]

block 'arr-indicator 'output [
    in value 'array
]

block 'build-array 'array [
    in a 'number
    in b 'number
    out result 'array
    emit [result: reduce [a b]]
]

block 'index-array 'array [
    in arr 'array
    in index 'number
    out result 'number
    emit [result: pick arr to-integer index + 1]
]

block 'array-size 'array [
    in arr 'array
    out result 'number
    emit [result: to-float length? arr]
]

block 'array-subset 'array [
    in arr 'array
    in start 'number
    in length 'number
    out result 'array
    emit [result: arr-subset-helper arr start length]
]

; ── Cluster ────────────────────────────────────────────────
; bundle/unbundle tienen puertos dinámicos según node/config/fields.
; cluster-control/indicator tienen 1 solo puerto estático de tipo 'cluster.

block 'bundle 'cluster [
    ; Entradas dinámicas: una por campo (ver cluster-in-ports)
    out result 'cluster
    emit []  ; generado dinámicamente por emit-bundle en compiler.red
]

block 'unbundle 'cluster [
    in cluster-in 'cluster
    ; Salidas dinámicas: una por campo (ver cluster-out-ports)
    emit []  ; generado dinámicamente por emit-unbundle en compiler.red
]

block 'cluster-control 'cluster [
    ; 1 solo wire de salida: el cluster completo
    out out 'cluster
    emit []  ; generado dinámicamente por emit-cluster-control en compiler.red
]

block 'cluster-indicator 'cluster [
    ; 1 solo wire de entrada: el cluster completo
    in in 'cluster
    emit []  ; generado dinámicamente por emit-cluster-indicator en compiler.red
]

; ── Waveform ─────────────────────────────────────────────────────────────────
; Waveform Chart: acumula valores en buffer circular (history)
; Muestra señal estilo osciloscopio, actualización punto a punto

block 'waveform-chart 'output [
    in value 'number
    ; Sin puertos de salida — es un indicador
    ; Config: history-size (default 1024 puntos)
    ; El emit se maneja en compile-panel porque actualiza el buffer del chart
    ; en runtime, no genera código Red estático
]

; Waveform Graph: muestra array completo de una vez
; Sin buffer interno, actualización batch

block 'waveform-graph 'output [
    in array 'array
    ; Sin puertos de salida — es un indicador
    ; El emit se maneja en compile-panel
]

#include %../compiler/compiler.red
