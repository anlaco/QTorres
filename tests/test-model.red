Red [Title: "QTorres — Tests model (make-structure)"]

do %../src/graph/model.red

; ── make-structure — campos y defaults ─────────────────────────────

suite "make-structure — defaults"

reset-name-counters
s: make-structure []

assert "type por defecto es while-loop"       (s/type = 'while-loop)
assert "name generado: while-loop_1"          (s/name = "while-loop_1")
assert "x por defecto 0"                      (s/x = 0)
assert "y por defecto 0"                      (s/y = 0)
assert "w por defecto 300"                    (s/w = 300)
assert "h por defecto 200"                    (s/h = 200)
assert "nodes es un bloque vacío"             (block? s/nodes)
assert "wires es un bloque vacío"             (block? s/wires)
assert "cond-wire por defecto none"           (none? s/cond-wire)
assert "label/text por defecto While Loop"    (s/label/text = "While Loop")
assert "label/visible es logic!"              (logic? s/label/visible)
assert "label/visible vale true"              s/label/visible

suite "make-structure — spec explícito"

reset-name-counters
s2: make-structure [id: 10  type: 'while-loop  name: "while_custom"
                   x: 50  y: 80  w: 400  h: 250
                   label: [text: "Mi Loop" visible: true]]

assert "id correcto"              (s2/id = 10)
assert "name explícito preservado" (s2/name = "while_custom")
assert "x correcto"               (s2/x = 50)
assert "y correcto"               (s2/y = 80)
assert "w correcto"               (s2/w = 400)
assert "h correcto"               (s2/h = 250)
assert "label/text correcto"      (s2/label/text = "Mi Loop")

suite "make-structure — independencia entre instancias"

reset-name-counters
s3: make-structure []
s4: make-structure []
append s3/nodes "nodo-test"
assert "nodes son independientes"  (0 = length? s4/nodes)
assert "names únicos s3"           (s3/name = "while-loop_1")
assert "names únicos s4"           (s4/name = "while-loop_2")

suite "make-diagram — campo structures"

d: make-diagram "mi-vi"
assert "diagram tiene campo structures"         (block? d/structures)
assert "structures vacío inicialmente"          (0 = length? d/structures)
append d/structures s3
assert "se puede añadir estructura al diagrama" (1 = length? d/structures)

suite "blocks — while-loop registrado"

assert "while-loop en el registro"              (not none? find-block 'while-loop)
assert "categoría es structure"                 ('structure = block-category 'while-loop)

; ── make-shift-register — campos y defaults ─────────────────────────

suite "make-shift-register — defaults"

reset-name-counters
sr1: make-shift-register []

assert "sr id por defecto 0"                    (sr1/id = 0)
assert "sr name generado: sr_1"                 (sr1/name = "sr_1")
assert "sr data-type por defecto number"        (sr1/data-type = 'number)
assert "sr init-value por defecto 0.0"          (sr1/init-value = 0.0)
assert "sr y-offset por defecto 40"             (sr1/y-offset = 40)

suite "make-shift-register — spec explícito"

reset-name-counters
sr2: make-shift-register [id: 20  name: "sr_custom"  data-type: 'number
                           init-value: 5.0  y-offset: 80]

assert "sr id correcto"                         (sr2/id = 20)
assert "sr name explícito preservado"           (sr2/name = "sr_custom")
assert "sr data-type correcto"                  (sr2/data-type = 'number)
assert "sr init-value correcto"                 (sr2/init-value = 5.0)
assert "sr y-offset correcto"                   (sr2/y-offset = 80)

suite "make-shift-register — tipo string"

reset-name-counters
sr3: make-shift-register [data-type: 'string]

assert "sr string init-value es cadena vacía"   (sr3/init-value = "")
assert "sr string data-type correcto"           (sr3/data-type = 'string)

suite "make-shift-register — tipo boolean"

reset-name-counters
sr4: make-shift-register [data-type: 'boolean]

assert "sr boolean init-value false"            (sr4/init-value = false)
assert "sr boolean data-type correcto"          (sr4/data-type = 'boolean)

suite "make-shift-register — independencia entre instancias"

reset-name-counters
sr5: make-shift-register []
sr6: make-shift-register []

assert "sr names únicos sr5"                    (sr5/name = "sr_1")
assert "sr names únicos sr6"                    (sr6/name = "sr_2")

suite "make-structure — campo shift-regs"

reset-name-counters
s5: make-structure []

assert "structure tiene campo shift-regs"       (block? s5/shift-regs)
assert "shift-regs vacío inicialmente"          (0 = length? s5/shift-regs)

reset-name-counters
sr7: make-shift-register []
append s5/shift-regs sr7
assert "se puede añadir SR a la estructura"     (1 = length? s5/shift-regs)
assert "SR añadido es el correcto"              (s5/shift-regs/1/name = "sr_1")

suite "make-structure — shift-regs independiente entre instancias"

reset-name-counters
s6: make-structure []
s7: make-structure []
append s6/shift-regs make-shift-register []
assert "shift-regs son independientes"          (0 = length? s7/shift-regs)

; ── make-structure — for-loop ────────────────────────────────────────

suite "make-structure — for-loop defaults"

reset-name-counters
sf: make-structure [type: 'for-loop]

assert "for-loop tipo correcto"                 (sf/type = 'for-loop)
assert "for-loop name generado"                 (sf/name = "for-loop_1")
assert "for-loop label texto"                   (sf/label/text = "For Loop")
assert "for-loop cond-wire none"                (none? sf/cond-wire)
assert "for-loop shift-regs vacio"              (0 = length? sf/shift-regs)
assert "for-loop w default 300"                 (sf/w = 300)
assert "for-loop h default 200"                 (sf/h = 200)

suite "make-structure — for-loop label independiente de while-loop"

reset-name-counters
sw: make-structure []
sf2: make-structure [type: 'for-loop]

assert "while label texto"                      (sw/label/text = "While Loop")
assert "for label texto"                        (sf2/label/text = "For Loop")
