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

; ── make-frame — tests básicos ────────────────────────────────────────

suite "make-frame — defaults"

f: make-frame []

assert "frame id por defecto 0"                  (f/id = 0)
assert "frame label por defecto '0'"            (f/label = "0")
assert "frame nodes vacío"                      (empty? f/nodes)
assert "frame wires vacío"                       (empty? f/wires)

suite "make-frame — spec explícito"

f2: make-frame [id: 5  label: "Default"]

assert "frame id correcto"                      (f2/id = 5)
assert "frame label correcto"                   (f2/label = "Default")

suite "make-frame — independencia entre instancias"

f3: make-frame [id: 0  label: "0"]
f4: make-frame [id: 1  label: "1"]
append f3/nodes "nodo-test"

assert "frames independientes — nodes"          (empty? f4/nodes)
assert "frame id correcto f3"                   (f3/id = 0)
assert "frame id correcto f4"                   (f4/id = 1)

; ── make-structure — case-structure ────────────────────────────────────

suite "make-structure — case-structure defaults"

reset-name-counters
sc: make-structure [type: 'case-structure]

assert "case-structure tipo correcto"           (sc/type = 'case-structure)
assert "case-structure name generado"           (sc/name = "case-structure_1")
assert "case-structure label texto"             (sc/label/text = "Case Structure")
assert "case-structure frames vacío"             (block? sc/frames)
assert "case-structure active-frame 0"          (sc/active-frame = 0)
assert "case-structure selector-wire none"      (none? sc/selector-wire)
assert "case-structure cond-wire none"           (none? sc/cond-wire)
assert "case-structure shift-regs vacío"         (empty? sc/shift-regs)

suite "make-structure — case-structure con frames"

reset-name-counters
sc2: make-structure [
    type: 'case-structure
    id: 20
    frames: [
        frame [id: 0  label: "0"]
        frame [id: 1  label: "1"]
        frame [id: 2  label: "Default"]
    ]
]

assert "case-structure id correcto"             (sc2/id = 20)
assert "case-structure tiene 3 frames"          (3 = length? sc2/frames)
assert "frame 0 id correcto"                    (sc2/frames/1/id = 0)
assert "frame 0 label correcto"                 (sc2/frames/1/label = "0")
assert "frame 1 label correcto"                 (sc2/frames/2/label = "1")
assert "frame 2 label Default"                  (sc2/frames/3/label = "Default")

suite "make-structure — case-structure frames independientes"

reset-name-counters
sc3: make-structure [type: 'case-structure]
sc4: make-structure [type: 'case-structure]

append sc3/frames make-frame [id: 0  label: "X"]
assert "frames independientes entre instancias" (empty? sc4/frames)

suite "blocks — case-structure registrado"

assert "case-structure en el registro"          (not none? find-block 'case-structure)
assert "categoría es structure"                 ('structure = block-category 'case-structure)

; ── cluster-fields / cluster-in-ports / cluster-out-ports ───────────────

suite "cluster-helpers — nodo sin fields"

reset-name-counters
cn-empty: make-node [type: 'bundle]

assert "cluster-fields sin config devuelve bloque vacío"   ([] = cluster-fields cn-empty)
assert "cluster-in-ports sin fields devuelve []"           ([] = cluster-in-ports cn-empty)
assert "cluster-out-ports sin fields devuelve []"          ([] = cluster-out-ports cn-empty)

suite "cluster-helpers — bundle con 3 campos"

reset-name-counters
cn-b: make-node [
    type: 'bundle
    config: [fields [nombre 'string  voltaje 'number  activo 'boolean]]
]

assert "cluster-fields devuelve 6 elementos"                (6 = length? cluster-fields cn-b)
assert "cluster-in-ports bundle devuelve 3 nombres"         (3 = length? cluster-in-ports cn-b)
assert "cluster-in-ports incluye nombre"                    (not none? find cluster-in-ports cn-b 'nombre)
assert "cluster-in-ports incluye voltaje"                   (not none? find cluster-in-ports cn-b 'voltaje)
assert "cluster-in-ports incluye activo"                    (not none? find cluster-in-ports cn-b 'activo)
assert "cluster-out-ports bundle devuelve [] (no salidas de campo)" ([] = cluster-out-ports cn-b)

suite "cluster-helpers — unbundle con 3 campos"

reset-name-counters
cn-u: make-node [
    type: 'unbundle
    config: [fields [nombre 'string  voltaje 'number  activo 'boolean]]
]

assert "cluster-out-ports unbundle devuelve 3 nombres"      (3 = length? cluster-out-ports cn-u)
assert "cluster-out-ports incluye nombre"                   (not none? find cluster-out-ports cn-u 'nombre)
assert "cluster-out-ports incluye voltaje"                  (not none? find cluster-out-ports cn-u 'voltaje)
assert "cluster-out-ports incluye activo"                   (not none? find cluster-out-ports cn-u 'activo)
assert "cluster-in-ports unbundle devuelve [] (no entradas de campo)" ([] = cluster-in-ports cn-u)

suite "cluster-helpers — cluster-field-type"

reset-name-counters
cn-t: make-node [
    type: 'bundle
    config: [fields [nombre 'string  voltaje 'number  activo 'boolean]]
]

assert "cluster-field-type nombre → string"    ('string  = cluster-field-type cn-t 'nombre)
assert "cluster-field-type voltaje → number"   ('number  = cluster-field-type cn-t 'voltaje)
assert "cluster-field-type activo → boolean"   ('boolean = cluster-field-type cn-t 'activo)
assert "cluster-field-type campo inexistente → number (default)" ('number = cluster-field-type cn-t 'noexiste)

suite "cluster-helpers — gen-name"

reset-name-counters
nb1: make-node [type: 'bundle]
nb2: make-node [type: 'bundle]
nu1: make-node [type: 'unbundle]

assert "bundle gen-name bundle_1"    (nb1/name = "bundle_1")
assert "bundle gen-name bundle_2"    (nb2/name = "bundle_2")
assert "unbundle gen-name unbundle_1" (nu1/name = "unbundle_1")

; ── tests de regresión para bug #54 ─────────────────────────────────────

suite "cluster-fields — regresión bug #54"

reset-name-counters
n1: make-node [type: 'bundle]

assert "cluster-fields devuelve [] cuando no hay config/fields" ([] = cluster-fields n1)

reset-name-counters
n2: make-node [
    type: 'bundle
    config: [fields [nombre 'string  voltaje 'number]]
]

assert "cluster-fields devuelve campos cuando existen en config" (
    4 = length? cluster-fields n2
)
assert "cluster-fields devuelve nombres y tipos correctos" (
    (cluster-fields n2) = [nombre 'string voltaje 'number]
)

reset-name-counters
n3: make-node [type: 'bundle]

; Simular añadir fields con el patrón usado en el código
either pos: find n3/config 'fields [
    pos/2: [nombre 'string  voltaje 'number]
][
    append n3/config reduce ['fields [nombre 'string voltaje 'number]]
]

assert "cluster-fields devuelve campos añadidos dinámicamente" (
    4 = length? cluster-fields n3
)
assert "cluster-fields devuelve nombres y tipos correctos tras añadir" (
    (cluster-fields n3) = [nombre 'string voltaje 'number]
)

reset-name-counters
c1: make-node [
    type: 'bundle
    config: [fields [x 'number  y 'number]]
]
c2: make-node [
    type: 'bundle
    config: [fields [nombre 'string]]
]

assert "cluster-control puede tener fields distintos al indicator" (
    (cluster-fields c1) = [x 'number y 'number]
)
assert "cluster-indicator puede tener fields distintos al control" (
    (cluster-fields c2) = [nombre 'string]
)

print "--- tests finalizados ---"
