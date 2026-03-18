Red [Title: "QTorres — Tests compiler, file-io y runner"]

do %../src/graph/model.red
do %../src/graph/blocks.red
do %../src/compiler/compiler.red
do %../src/io/file-io.red
do %../src/runner/runner.red

; Resetear contadores para tests predecibles
reset-name-counters

; ── Diagrama de prueba compartido ────────────────────────────────────
; const_A(5.0) ──┐
;                ├──→ add_1 ──→ display_1
; const_B(3.0) ──┘
;
; name es el identificador del compilador (DT-024)
; label es el texto visual (libre)

td: make-diagram "test-vi"
tn1: make-node [id: 1  type: 'const    name: "const_A"    label: "Const A"    x: 0    y: 0]
tn2: make-node [id: 2  type: 'const    name: "const_B"    label: "Const B"    x: 0    y: 60]
tn3: make-node [id: 3  type: 'add      name: "add_1"      label: "Add"        x: 200  y: 30]
tn4: make-node [id: 4  type: 'display  name: "display_1"  label: "Display"    x: 400  y: 30]
tn1/config: [default 5.0]
tn2/config: [default 3.0]
append td/nodes tn1  append td/nodes tn2
append td/nodes tn3  append td/nodes tn4
append td/wires make-wire [from: 1  from-port: 'result  to: 3  to-port: 'a]
append td/wires make-wire [from: 2  from-port: 'result  to: 3  to-port: 'b]
append td/wires make-wire [from: 3  from-port: 'result  to: 4  to-port: 'value]

; ── Tests bind-emit ───────────────────────────────────────────────────
suite "bind-emit"

be-result: bind-emit [result: a + b] [result Suma  a X  b Y]
be-first:  first be-result
be-sw:     to-set-word 'Suma

assert "sustituye word! de entrada a"         ('X = be-result/2)
assert "sustituye word! de entrada b"         ('Y = be-result/4)
assert "result: se convierte en set-word!"    (set-word? be-first)
assert "set-word resultante es Suma:"         (be-sw = be-first)
assert "bloque sin bindings pasa sin cambio"  ([a + b] = bind-emit [a + b] [])
be-nested: bind-emit [[a]] [a X]
assert "sustituye en bloques anidados"        (block? first be-nested)
ne-first: first first be-nested
assert "valor anidado sustituido"             ('X = ne-first)

; ── Tests compile-body ────────────────────────────────────────────────
suite "compile-body"

body: compile-body td

; Variables se derivan de name (DT-024), no de label/text
assert "compile-body no está vacío"             (not empty? body)
assert "contiene variable const_A_result"       (not none? find body 'const_A_result)
assert "contiene variable const_B_result"       (not none? find body 'const_B_result)
assert "contiene variable add_1_result"         (not none? find body 'add_1_result)
assert "usa config 5.0 de const_A"             (not none? find body 5.0)
assert "usa config 3.0 de const_B"             (not none? find body 3.0)

; ── Tests save-vi / load-vi ──────────────────────────────────────────
suite "save-vi / load-vi"

test-file: %/tmp/qtorres-test.qvi
save-vi test-file td

assert "save-vi crea el fichero"   (exists? test-file)

loaded: load-vi test-file

assert "load-vi devuelve un objeto"         (object? loaded)
assert "load-vi carga 4 nodos"             (4 = length? loaded/nodes)
assert "load-vi carga 3 wires"             (3 = length? loaded/wires)

lnode1: first loaded/nodes
lnode3: loaded/nodes/3
lwire1: first loaded/wires
lwire3: loaded/wires/3

assert "nodo 1: id correcto"               (1 = lnode1/id)
assert "nodo 1: tipo correcto"             ('const = lnode1/type)
assert "nodo 1: name correcto"             ("const_A" = lnode1/name)
assert "nodo 1: label es objeto"           (object? lnode1/label)
assert "nodo 1: label/text correcto"       ("Const A" = lnode1/label/text)
assert "nodo 3: tipo add"                  ('add = lnode3/type)
assert "wire 1: from-node correcto"        (1 = lwire1/from-node)
assert "wire 1: to-node correcto"          (3 = lwire1/to-node)
assert "wire 3: from-node correcto"        (3 = lwire3/from-node)
assert "wire 3: to-node correcto"          (4 = lwire3/to-node)

; ── Tests runner ─────────────────────────────────────────────────────
suite "runner"

; Resetear contadores para este diagrama
reset-name-counters

; Diagrama mínimo propio para no depender del estado previo de td
rd: make-diagram "run-test"
rn1: make-node [id: 10  type: 'const    name: "rc1"  label: "RC1"  x: 0    y: 0]
rn2: make-node [id: 11  type: 'const    name: "rc2"  label: "RC2"  x: 0    y: 60]
rn3: make-node [id: 12  type: 'add      name: "ra1"  label: "RA1"  x: 200  y: 30]
rn4: make-node [id: 13  type: 'display  name: "rd1"  label: "RD1"  x: 400  y: 30]
rn1/config: [default 7.0]
rn2/config: [default 3.0]
append rd/nodes rn1  append rd/nodes rn2
append rd/nodes rn3  append rd/nodes rn4
append rd/wires make-wire [from: 10  from-port: 'result  to: 12  to-port: 'a]
append rd/wires make-wire [from: 11  from-port: 'result  to: 12  to-port: 'b]
append rd/wires make-wire [from: 12  from-port: 'result  to: 13  to-port: 'value]

dbg-body: compile-body rd
print rejoin ["  [DBG] code: " mold dbg-body]
run-err: try [run rd]
if error? run-err [print rejoin ["  Error en runner: " run-err/arg1]]
assert "runner ejecuta sin error"   (not error? run-err)
assert "qtorres-runtime se resetea" (false = qtorres-runtime)
