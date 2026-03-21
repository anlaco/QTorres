Red [Title: "QTorres — Tests compiler, file-io y runner"]

do %../src/graph/model.red
do %../src/graph/blocks.red
do %../src/compiler/compiler.red
do %../src/io/file-io.red
do %../src/runner/runner.red
do %../src/ui/panel/panel.red

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

; Cleanup del fichero temporal
if exists? test-file [delete test-file]

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

run-err: try [run rd]
if error? run-err [print rejoin ["  Error en runner: " run-err/arg1]]
assert "runner ejecuta sin error"   (not error? run-err)
assert "qtorres-runtime se resetea" (false = qtorres-runtime)

; ── Tests FP round-trip ───────────────────────────────────────────────
suite "FP round-trip (save-vi → load-vi)"

; Diagrama con 2 controles + 1 indicador en FP
reset-name-counters
fp-td: make-diagram "fp-test"
fp-n1: make-node [id: 20  type: 'control    name: "ctrl_1"  label: [text: "A" visible: true]   x: 20  y: 20]
fp-n2: make-node [id: 21  type: 'control    name: "ctrl_2"  label: [text: "B" visible: true]   x: 20  y: 100]
fp-n3: make-node [id: 22  type: 'add        name: "add_1"   label: [text: "Add" visible: false] x: 200 y: 60]
fp-n4: make-node [id: 23  type: 'indicator  name: "ind_1"   label: [text: "R" visible: true]   x: 400 y: 60]
append fp-td/nodes fp-n1  append fp-td/nodes fp-n2
append fp-td/nodes fp-n3  append fp-td/nodes fp-n4

; FP items con offsets conocidos
fp-c1: make-fp-item [id: 1  type: 'control    name: "ctrl_1"  label: [text: "A" visible: true]  default: 5.0  offset: 20x30]
fp-c2: make-fp-item [id: 2  type: 'control    name: "ctrl_2"  label: [text: "B" visible: true]  default: 3.0  offset: 20x100]
fp-i1: make-fp-item [id: 3  type: 'indicator  name: "ind_1"   label: [text: "R" visible: true]  default: 0.0  offset: 20x170]
append fp-td/front-panel fp-c1
append fp-td/front-panel fp-c2
append fp-td/front-panel fp-i1

fp-test-file: %/tmp/qtorres-fp-test.qvi
save-vi fp-test-file fp-td
assert "save-vi FP crea el fichero"  (exists? fp-test-file)

fp-loaded: load-vi fp-test-file
if exists? fp-test-file [delete fp-test-file]

assert "load-vi FP devuelve objeto"           (object? fp-loaded)
assert "front-panel tiene 3 items"            (3 = length? fp-loaded/front-panel)

fp-lc1: fp-loaded/front-panel/1
fp-lc2: fp-loaded/front-panel/2
fp-li1: fp-loaded/front-panel/3

assert "item 1: id correcto"                  (1 = fp-lc1/id)
assert "item 1: type control"                 ('control = fp-lc1/type)
assert "item 1: name correcto"                ("ctrl_1" = fp-lc1/name)
assert "item 1: label es objeto"              (object? fp-lc1/label)
assert "item 1: label/text correcto"          ("A" = fp-lc1/label/text)
assert "item 1: offset/x correcto"            (20 = fp-lc1/offset/x)
assert "item 1: offset/y correcto"            (30 = fp-lc1/offset/y)

assert "item 2: type control"                 ('control = fp-lc2/type)
assert "item 2: name correcto"                ("ctrl_2" = fp-lc2/name)
assert "item 2: offset/y correcto"            (100 = fp-lc2/offset/y)

assert "item 3: type indicator"               ('indicator = fp-li1/type)
assert "item 3: name correcto"                ("ind_1" = fp-li1/name)
assert "item 3: label/text correcto"          ("R" = fp-li1/label/text)
assert "item 3: offset/y correcto"            (170 = fp-li1/offset/y)
