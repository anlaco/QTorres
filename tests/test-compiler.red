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

; Regresión: bind-emit debe sustituir false (logic!) — no confundirlo con "no encontrado"
; Nota: bindings debe ser reduce [flag false] ya que false en bloque literal es word!, no logic!
be-false: bind-emit [x: flag] reduce [quote flag  false]
assert "bind-emit sustituye false correctamente"  (false = be-false/2)

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

; ── Tests compile-body con bloques booleanos ────────────────────────
suite "compile-body — booleanos"

; bool_A(false) ──┐
;                  ├──→ and_1 ──→ (result)
; bool_B(true)  ──┘
tb: make-diagram "test-bool-vi"
tbn1: make-node [id: 10  type: 'bool-const  name: "bool_A"  x: 0  y: 0]
tbn2: make-node [id: 11  type: 'bool-const  name: "bool_B"  x: 0  y: 60]
tbn3: make-node [id: 12  type: 'and-op      name: "and_1"   x: 200 y: 30]
tbn1/config: [default false]
tbn2/config: [default true]
append tb/nodes tbn1  append tb/nodes tbn2  append tb/nodes tbn3
append tb/wires make-wire [from: 10  from-port: 'result  to: 12  to-port: 'a]
append tb/wires make-wire [from: 11  from-port: 'result  to: 12  to-port: 'b]

bool-body: compile-body tb
assert "compile-body booleano no está vacío"          (not empty? bool-body)
assert "contiene variable bool_A_result"              (not none? find bool-body 'bool_A_result)
assert "contiene variable bool_B_result"              (not none? find bool-body 'bool_B_result)
assert "contiene variable and_1_result"               (not none? find bool-body 'and_1_result)
; Verificar que el body se puede ejecutar y produce los valores correctos
do bool-body
assert "bool_A_result es false tras execute"          (false = bool_A_result)
assert "bool_B_result es true tras execute"           (true  = bool_B_result)
assert "and_1_result es false AND true = false"       (false = and_1_result)

; node-boolean-input?: chequea si el primer output del bloque es boolean
; Solo relevante para nodos de categoría 'input
tc-num: make-node [id: 20  type: 'control  name: "ctrl_x"  x: 0  y: 0]
assert "bool-const es boolean input"               (node-boolean-input? tbn1)
assert "bool-const (bool_B) es boolean"            (node-boolean-input? tbn2)
assert "control numérico NO es boolean input"      (not node-boolean-input? tc-num)

; ── Tests compile-body con bloques string ────────────────────────────
suite "compile-body — string"

; str_A("hola") ──┐
; str_B(" mundo") ─┘── concat ── result
ts-diag: make-diagram "test-str-vi"
tsn1: make-node [id: 30  type: 'str-const  name: "str_A"  x: 0   y: 0]
tsn1/config: [default "hola"]
tsn2: make-node [id: 31  type: 'str-const  name: "str_B"  x: 0   y: 60]
tsn2/config: [default " mundo"]
tsn3: make-node [id: 32  type: 'concat     name: "cat_1"  x: 200 y: 30]
tsn4: make-node [id: 33  type: 'str-indicator  name: "ind_s"  x: 300 y: 30]
append ts-diag/nodes tsn1
append ts-diag/nodes tsn2
append ts-diag/nodes tsn3
append ts-diag/nodes tsn4
append ts-diag/wires make-wire [from: 30  from-port: 'result  to: 32  to-port: 'a]
append ts-diag/wires make-wire [from: 31  from-port: 'result  to: 32  to-port: 'b]

str-body: compile-body ts-diag
assert "compile-body string no está vacío"         (not empty? str-body)
assert "contiene variable str_A_result"            (not none? find str-body 'str_A_result)
assert "contiene variable str_B_result"            (not none? find str-body 'str_B_result)
assert "contiene variable cat_1_result"            (not none? find str-body 'cat_1_result)

do str-body
assert "str_A_result es 'hola' tras execute"       ("hola"       = str_A_result)
assert "str_B_result es ' mundo' tras execute"     (" mundo"     = str_B_result)
assert "cat_1_result es 'hola mundo' tras execute" ("hola mundo" = cat_1_result)

; node-string-input?: chequea si el primer output del bloque es string
tc-str: make-node [id: 34  type: 'str-control  name: "ctrl_s"  x: 0  y: 0]
assert "str-const es string input"                 (node-string-input? tsn1)
assert "str-control es string input"               (node-string-input? tc-str)
assert "control numérico NO es string input"       (not node-string-input? tc-num)
assert "bool-const NO es string input"             (not node-string-input? tbn1)

; str-length: número de caracteres
tsn-len: make-node [id: 35  type: 'str-length  name: "len_1"  x: 0  y: 0]
tsl-diag: make-diagram "test-len-vi"
append tsl-diag/nodes tsn1
append tsl-diag/nodes tsn-len
append tsl-diag/wires make-wire [from: 30  from-port: 'result  to: 35  to-port: 'a]
len-body: compile-body tsl-diag
do len-body
assert "str-length de 'hola' es 4.0"               (4.0 = len_1_result)

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

; ── Independencia de valores entre str-control y str-indicator ────────
suite "FP items — string independence"

sc-a: make-fp-item [id: 10  type: 'str-control   name: "sc_a"  label: [text: "A" visible: true]  offset: 20x40]
sc-b: make-fp-item [id: 11  type: 'str-indicator  name: "si_b"  label: [text: "B" visible: true]  offset: 20x80]

assert "str-control valor inicial vacío"        ("" = sc-a/value)
assert "str-indicator valor inicial vacío"      ("" = sc-b/value)
assert "valores iniciales son objetos distintos" (not same? sc-a/value sc-b/value)

sc-a/value: "hello"
assert "cambiar control no afecta indicador"    ("" = sc-b/value)
assert "control tiene nuevo valor"              ("hello" = sc-a/value)

; ── Tests compile-structure (while-loop) ────────────────────────────
suite "compile-structure — estructura vacía sin condición"

reset-name-counters
wl-empty: make-structure []
wl-code: compile-structure wl-empty

assert "código generado no está vacío"             (not empty? wl-code)
assert "primer elemento es set-word! (init _i)"    (set-word? first wl-code)
assert "variable _i inicializada a 0"              (0 = wl-code/2)
assert "contiene 'until'"                          (not none? find wl-code 'until)

wl-until-idx: index? find wl-code 'until
wl-until-body: wl-code/(wl-until-idx + 1)
assert "cuerpo del until es un bloque"             (block? wl-until-body)
; Condición sin wire: último elemento es logic! true
assert "condición no conectada produce logic!"     (logic? last wl-until-body)

suite "compile-structure — ejecutar loop básico (cond: bool-const true)"

reset-name-counters
wl-st1: make-structure [id: 50  name: "while_1"  x: 100  y: 100]
; Nodo interno: bool-const true (condición = true → 1 iteración)
wl-nd1: make-node [id: 51  type: 'bool-const  name: "cond_node"  x: 110  y: 120]
wl-nd1/config: reduce ['default true]
append wl-st1/nodes wl-nd1
; Conectar terminal condición
wl-st1/cond-wire: make object! [from: 51  port: 'result]

wl-code1: compile-structure wl-st1
assert "código con condición no está vacío"        (not empty? wl-code1)
; Ejecutar y verificar que corrió 1 vez
do wl-code1
assert "counter _while_1_i vale 1 tras 1 vuelta"  (1 = _while_1_i)
assert "cond_node_result es true (bool-const)"     (logic? cond_node_result)

suite "compile-structure — while-loop en compile-body (diagrama completo)"

reset-name-counters
wl-diag2: make-diagram "while-test-vi"
; Estructura con add interno: suma _i + 0.0 en cada iteración
wl-st2: make-structure [id: 60  name: "while_2"  x: 50  y: 50]
wl-add: make-node [id: 61  type: 'add  name: "iadd_1"  x: 70  y: 70]
wl-gt:  make-node [id: 62  type: 'gt-op  name: "igt_1"  x: 130  y: 70]
; Constante 3.0 (límite)
wl-lim: make-node [id: 63  type: 'const  name: "ilim_1"  x: 70  y: 130]
wl-lim/config: reduce ['default 3.0]
append wl-st2/nodes wl-add
append wl-st2/nodes wl-gt
append wl-st2/nodes wl-lim
; Wire: ilim_1/result → igt_1/a y igt_1/b (comparación simple: 3.0 > 3.0 = false → varias vueltas)
; En realidad usamos: gt(_i+0, 3.0) como condición
; Wire: ilim_1 → iadd_1/a  (a = 3.0 constante)
append wl-st2/wires make-wire [from: 63  from-port: 'result  to: 61  to-port: 'a]
append wl-st2/wires make-wire [from: 63  from-port: 'result  to: 61  to-port: 'b]
; Condición: bool-const = false → loop corre para siempre  → usar true
wl-cond2: make-node [id: 64  type: 'bool-const  name: "wcond"  x: 150  y: 120]
wl-cond2/config: reduce ['default true]
append wl-st2/nodes wl-cond2
wl-st2/cond-wire: make object! [from: 64  port: 'result]
append wl-diag2/structures wl-st2

wl-body2: compile-body wl-diag2
assert "compile-body con estructura no está vacío"  (not empty? wl-body2)
assert "código contiene 'until'"                    (not none? find wl-body2 'until)

suite "compile-structure — condición no conectada produce true"

reset-name-counters
wl-nocond: make-structure [id: 70  name: "while_3"]
; Sin nodes, sin cond-wire
wl-nc-code: compile-structure wl-nocond
wl-nc-until-idx: index? find wl-nc-code 'until
wl-nc-body: wl-nc-code/(wl-nc-until-idx + 1)
assert "cond no conectada: body termina en logic!"   (logic? last wl-nc-body)
do wl-nc-code
assert "_while_3_i es 1 (1 vuelta con cond=true)"   (1 = _while_3_i)

; ── Tests file-io round-trip con structures ──────────────────────
suite "file-io — round-trip while-loop"

reset-name-counters
wl-rt-diag: make-diagram "while-rt-vi"
; Estructura simple con un nodo interno
wl-rt-st: make-structure [id: 80  name: "while_rt"  x: 50  y: 50  w: 280  h: 160]
wl-rt-nd: make-node [id: 81  type: 'bool-const  name: "bcrt"  x: 80  y: 90]
wl-rt-nd/config: reduce ['default true]
append wl-rt-st/nodes wl-rt-nd
wl-rt-st/cond-wire: make object! [from: 81  port: 'result]
append wl-rt-diag/structures wl-rt-st

; Serializar
wl-rt-qd: serialize-diagram wl-rt-diag
bd-rt: select wl-rt-qd to-set-word 'block-diagram
assert "block-diagram tiene campo structures"   (block? select bd-rt to-set-word 'structures)
structs-rt: select bd-rt to-set-word 'structures
assert "structures no está vacío"               (not empty? structs-rt)
assert "primer elemento es while-loop"          ('while-loop = first structs-rt)

; Round-trip save/load
wl-rt-file: %/tmp/qtorres-while-rt.qvi
save-vi wl-rt-file wl-rt-diag
assert "save-vi crea fichero con structures"    (exists? wl-rt-file)

wl-loaded: load-vi wl-rt-file
if exists? wl-rt-file [delete wl-rt-file]

assert "load-vi devuelve objeto"                (object? wl-loaded)
assert "structures cargadas: 1"                 (1 = length? wl-loaded/structures)
wl-ls: first wl-loaded/structures
assert "estructura cargada: nombre correcto"    ("while_rt" = wl-ls/name)
assert "estructura cargada: x correcto"         (50 = wl-ls/x)
assert "estructura cargada: w correcto"         (280 = wl-ls/w)
assert "estructura cargada: 1 nodo interno"     (1 = length? wl-ls/nodes)
assert "nodo interno: coords absolutas x"       (80 = wl-ls/nodes/1/x)
assert "nodo interno: coords absolutas y"       (90 = wl-ls/nodes/1/y)
assert "cond-wire cargado"                      (object? wl-ls/cond-wire)
assert "cond-wire: from correcto"               (81 = wl-ls/cond-wire/from)
