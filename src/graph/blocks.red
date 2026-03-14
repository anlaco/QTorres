Red [
    Title:   "QTorres — Registro de bloques"
    Purpose: "Definición de los tipos de bloques usando el dialecto block-def"
]

; ══════════════════════════════════════════════════
; DIALECTO: block-def
; ══════════════════════════════════════════════════
; Define tipos de bloques de forma declarativa.
; Cada bloque especifica su categoría, puertos y semántica de compilación.
;
; Sintaxis:
;   block <nombre> <categoría> [
;       in <nombre-puerto> <tipo>        ; puerto de entrada
;       out <nombre-puerto> <tipo>       ; puerto de salida
;       emit [<código Red con palabras de los puertos>]
;   ]
;
; Dentro de `emit`, los nombres de los puertos se sustituyen por los
; valores reales que vienen de los wires. El resultado es código Red
; generado por manipulación de bloques — no interpolación de strings.
;
; Reglas de parse del dialecto:
;   port-rule:  ['in | 'out] word! lit-word!
;   emit-rule:  'emit block!
;   block-rule: 'block word! lit-word! block!

block-registry: []

; === Bloques primitivos del MVP ===

block const 'input [
    out result 'number
    config default 'number 0.0
    emit [result: (default)]
]

block add 'math [
    in a 'number
    in b 'number
    out result 'number
    emit [result: a + b]
]

block sub 'math [
    in a 'number
    in b 'number
    out result 'number
    emit [result: a - b]
]

block mul 'math [
    in a 'number
    in b 'number
    out result 'number
    emit [result: a * b]
]

block display 'output [
    in value 'number
    emit [print value]
]
