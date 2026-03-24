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
