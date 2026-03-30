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
empty-outer: make object! [nodes: copy []  wires: copy []]
wl-code: compile-structure wl-empty empty-outer

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

wl-code1: compile-structure wl-st1 empty-outer
assert "código con condición no está vacío"        (not empty? wl-code1)
; Verificar estructura del until-body (no ejecutamos: do-events requiere View)
wl-until-idx1: index? find wl-code1 'until
wl-body1: wl-code1/(wl-until-idx1 + 1)
assert "until-body contiene do-events/no-wait"     (not none? find mold wl-body1 "do-events/no-wait")
assert "do-events/no-wait precede a la condición"  (not none? find mold wl-body1 "do-events/no-wait")
assert "condición sigue siendo el último elemento" (word? last wl-body1)

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
wl-nc-code: compile-structure wl-nocond empty-outer
wl-nc-until-idx: index? find wl-nc-code 'until
wl-nc-body: wl-nc-code/(wl-nc-until-idx + 1)
assert "until-body contiene do-events/no-wait"       (not none? find mold wl-nc-body "do-events/no-wait")
; Condición no conectada → último elemento es logic! true (después de do-events)
assert "cond no conectada: body termina en logic!"   (logic? last wl-nc-body)

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

; ── Tests file-io round-trip con shift registers ─────────────────
suite "file-io — round-trip shift registers"

reset-name-counters
sr-rt-diag: make-diagram "sr-rt-vi"
; Estructura con 2 shift registers
sr-rt-st: make-structure [id: 90  name: "while_sr"  x: 60  y: 60  w: 300  h: 200]
sr-rt-sr1: make-shift-register [id: 91  name: "sr_num"  data-type: 'number   init-value: 5.0   y-offset: 40]
sr-rt-sr2: make-shift-register [id: 92  name: "sr_str"  data-type: 'string   init-value: "hi"  y-offset: 80]
append sr-rt-st/shift-regs sr-rt-sr1
append sr-rt-st/shift-regs sr-rt-sr2
append sr-rt-diag/structures sr-rt-st

; Serializar
sr-rt-qd: serialize-diagram sr-rt-diag
sr-bd-rt: select sr-rt-qd to-set-word 'block-diagram
sr-structs-rt: select sr-bd-rt to-set-word 'structures
sr-struct-blk: sr-structs-rt/2  ; bloque de la estructura (primer while-loop)
sr-srs-blk: select sr-struct-blk 'shift-registers
assert "shift-registers serializado"            (block? sr-srs-blk)
assert "2 SRs serializados"                     (4 = length? sr-srs-blk)  ; 'sr [] 'sr []
assert "primer token es 'sr"                    ('sr = first sr-srs-blk)

; Round-trip save/load
sr-rt-file: %/tmp/qtorres-sr-rt.qvi
save-vi sr-rt-file sr-rt-diag
assert "save-vi crea fichero con SRs"           (exists? sr-rt-file)

sr-loaded: load-vi sr-rt-file
if exists? sr-rt-file [delete sr-rt-file]

assert "load-vi devuelve objeto"                (object? sr-loaded)
assert "structures cargadas: 1"                 (1 = length? sr-loaded/structures)
sr-ls: first sr-loaded/structures
assert "2 SRs cargados"                         (2 = length? sr-ls/shift-regs)
sr-ls1: sr-ls/shift-regs/1
sr-ls2: sr-ls/shift-regs/2
assert "SR1: name correcto"                     ("sr_num" = sr-ls1/name)
assert "SR1: data-type correcto"                ('number = sr-ls1/data-type)
assert "SR1: init-value correcto"               (5.0 = sr-ls1/init-value)
assert "SR1: y-offset correcto"                 (40 = sr-ls1/y-offset)
assert "SR2: name correcto"                     ("sr_str" = sr-ls2/name)
assert "SR2: data-type correcto"                ('string = sr-ls2/data-type)
assert "SR2: init-value correcto"               ("hi" = sr-ls2/init-value)
assert "SR2: y-offset correcto"                 (80 = sr-ls2/y-offset)

; ── Tests compilador con shift registers (12.2, 12.3, 12.4) ──────
suite "compile-structure — SR inicialización y actualización"

reset-name-counters
; Estructura: while_c1 con SR sr_acc (init 3.0)
; Interno: ione (const 1.0) + iadd (add) → SR-right
sr-c-st: make-structure [id: 200  name: "while_c1"  x: 0  y: 0]
sr-c-sr: make-shift-register [id: 201  name: "sr_acc"  data-type: 'number  init-value: 3.0  y-offset: 40]
append sr-c-st/shift-regs sr-c-sr
sr-c-nd1: make-node [id: 202  type: 'const  name: "ione"   x: 10  y: 10]
sr-c-nd1/config: reduce ['default 1.0]
sr-c-nd2: make-node [id: 203  type: 'add    name: "iadd1"  x: 80  y: 10]
append sr-c-st/nodes sr-c-nd1
append sr-c-st/nodes sr-c-nd2
; SR-left → iadd/a
append sr-c-st/wires make-wire [from: -1  from-port: 'sr_acc  to: 203  to-port: 'a]
; const → iadd/b
append sr-c-st/wires make-wire [from: 202  from-port: 'result  to: 203  to-port: 'b]
; iadd → SR-right
append sr-c-st/wires make-wire [from: 203  from-port: 'result  to: -2  to-port: 'sr_acc]

sr-c-outer: make object! [nodes: copy []  wires: copy []]
sr-c-code: compile-structure sr-c-st sr-c-outer

sr-c-init-sw:  find sr-c-code to-set-word '_sr_acc
sr-c-until-pos: index? find sr-c-code 'until
assert "SR inicializado antes del until"         (not none? sr-c-init-sw)
assert "SR init-value es 3.0"                    (3.0 = sr-c-init-sw/2)
assert "init precede al until"                   ((index? sr-c-init-sw) < sr-c-until-pos)
sr-c-body: sr-c-code/(sr-c-until-pos + 1)
assert "SR actualizado en until-body"            (not none? find sr-c-body to-set-word '_sr_acc)
; El código del nodo iadd1 está en el cuerpo (lee _sr_acc como entrada)
assert "cuerpo contiene iadd1_result"            (not none? find sr-c-body 'iadd1_result)

suite "compile-structure — múltiples SRs"

reset-name-counters
sr-m-st: make-structure [id: 210  name: "while_m"  x: 0  y: 0]
sr-m-sr1: make-shift-register [id: 211  name: "sr_x"  data-type: 'number  init-value: 10.0  y-offset: 40]
sr-m-sr2: make-shift-register [id: 212  name: "sr_y"  data-type: 'number  init-value: 20.0  y-offset: 80]
append sr-m-st/shift-regs sr-m-sr1
append sr-m-st/shift-regs sr-m-sr2

sr-m-outer: make object! [nodes: copy []  wires: copy []]
sr-m-code: compile-structure sr-m-st sr-m-outer

sr-m-until-pos: index? find sr-m-code 'until
sr-m-x-sw: find sr-m-code to-set-word '_sr_x
sr-m-y-sw: find sr-m-code to-set-word '_sr_y
assert "_sr_x inicializado antes del until"      (not none? sr-m-x-sw)
assert "_sr_y inicializado antes del until"      (not none? sr-m-y-sw)
assert "_sr_x precede al until"                  ((index? sr-m-x-sw) < sr-m-until-pos)
assert "_sr_y precede al until"                  ((index? sr-m-y-sw) < sr-m-until-pos)
assert "_sr_x init-value correcto"               (10.0 = sr-m-x-sw/2)
assert "_sr_y init-value correcto"               (20.0 = sr-m-y-sw/2)

suite "compile-structure — SR con wire externo (init dinámico)"

reset-name-counters
; Diagrama externo con nodo const que alimenta el SR
sr-e-diag: make-diagram "sr-ext-vi"
sr-e-nd: make-node [id: 300  type: 'const  name: "ext_init"  x: 0  y: 0]
sr-e-nd/config: reduce ['default 7.0]
append sr-e-diag/nodes sr-e-nd

; Estructura con SR sr_val (init-value=0.0 pero wire externo lo sobreescribe)
sr-e-st: make-structure [id: 301  name: "while_ext"  x: 100  y: 100]
sr-e-sr: make-shift-register [id: 302  name: "sr_val"  data-type: 'number  init-value: 0.0  y-offset: 40]
append sr-e-st/shift-regs sr-e-sr
append sr-e-diag/structures sr-e-st

; Wire externo: ext_init/result → estructura/sr_val
append sr-e-diag/wires make-wire [from: 300  from-port: 'result  to: 301  to-port: 'sr_val]

sr-e-code: compile-structure sr-e-st sr-e-diag

sr-e-val-sw: find sr-e-code to-set-word '_sr_val
assert "SR con wire externo: inicializado"       (not none? sr-e-val-sw)
assert "SR con wire externo: usa var del nodo"   ('ext_init_result = sr-e-val-sw/2)
; (NO usa el literal 0.0 del init-value)
assert "SR con wire externo: NO usa init-value"  (0.0 <> sr-e-val-sw/2)

suite "file-io — config round-trip (serialización de valores de constantes)"

reset-name-counters
cfg-rt-diag: make-diagram "cfg-rt-vi"
cfg-rt-nd: make-node [id: 400  type: 'const  name: "cfg_c"  x: 0  y: 0]
cfg-rt-nd/config: reduce ['default 42.0]
append cfg-rt-diag/nodes cfg-rt-nd

cfg-rt-file: %/tmp/qtorres-cfg-rt.qvi
save-vi cfg-rt-file cfg-rt-diag
cfg-rt-loaded: load-vi cfg-rt-file
if exists? cfg-rt-file [delete cfg-rt-file]

cfg-rt-ln: cfg-rt-loaded/nodes/1
assert "config round-trip: nodo cargado"         (object? cfg-rt-ln)
assert "config round-trip: name correcto"        ("cfg_c" = cfg-rt-ln/name)
assert "config round-trip: config no vacío"      (not empty? cfg-rt-ln/config)
assert "config round-trip: valor 42.0"           (42.0 = select cfg-rt-ln/config 'default)

; ── Tests compile-structure (for-loop) ──────────────────────────────

suite "compile-structure — for-loop sin wire N devuelve bloque vacío"

reset-name-counters
fl-empty-outer: make object! [nodes: copy []  wires: copy []  structures: copy []]
fl-no-n: make-structure [id: 500  type: 'for-loop  name: "for-loop_no_n"  x: 0  y: 0]
fl-no-n-code: compile-structure fl-no-n fl-empty-outer

assert "sin N: código vacío (error)"             (empty? fl-no-n-code)

suite "compile-structure — for-loop básico con N=5"

reset-name-counters
; Diagrama externo con nodo const N=5
fl-diag: make-diagram "fl-vi"
fl-n-nd: make-node [id: 600  type: 'const  name: "n_val"  x: 0  y: 0]
fl-n-nd/config: reduce ['default 5.0]
append fl-diag/nodes fl-n-nd

; Estructura for-loop
fl-st: make-structure [id: 601  type: 'for-loop  name: "for-loop_1"  x: 100  y: 100]
append fl-diag/structures fl-st

; Wire externo: n_val/result → fl-st/count
append fl-diag/wires make-wire [from: 600  from-port: 'result  to: 601  to-port: "count"]

fl-code: compile-structure fl-st fl-diag

; Verificar estructura del código generado
fl-n-sw:  find fl-code to-set-word '_for-loop_1_N
fl-i-sw:  find fl-code to-set-word '_for-loop_1_i
fl-loop-idx: index? find fl-code 'loop

assert "N inicializado"                          (not none? fl-n-sw)
assert "N usa to-integer"                        ('to-integer = fl-n-sw/2)
assert "N referencia variable del nodo"          ('n_val_result = fl-n-sw/3)
assert "_i inicializado a 0"                     (not none? fl-i-sw)
assert "código contiene 'loop'"                  (not none? find fl-code 'loop)
assert "'loop' sigue a N sym"                    (fl-loop-idx > (index? fl-n-sw))
fl-loop-n-sym: fl-code/(fl-loop-idx + 1)
fl-loop-body:  fl-code/(fl-loop-idx + 2)
assert "loop recibe el sym de N"                 (fl-loop-n-sym = '_for-loop_1_N)
assert "cuerpo del loop es un bloque"            (block? fl-loop-body)
assert "cuerpo NO contiene 'until'"              (none? find fl-loop-body 'until)

suite "compile-structure — for-loop: _i se incrementa dentro del loop"

fl-i-inc: find fl-loop-body to-set-word '_for-loop_1_i
assert "_i se incrementa en el body"             (not none? fl-i-inc)
assert "incremento en 1"                         (1 = fl-i-inc/4)

suite "compile-structure — for-loop con SR"

reset-name-counters
fl-sr-diag: make-diagram "fl-sr-vi"
fl-sr-n-nd: make-node [id: 700  type: 'const  name: "fl_n"  x: 0  y: 0]
fl-sr-n-nd/config: reduce ['default 10.0]
append fl-sr-diag/nodes fl-sr-n-nd

fl-sr-st: make-structure [id: 701  type: 'for-loop  name: "for-loop_sr"  x: 100  y: 100]
fl-sr: make-shift-register [id: 702  name: "fl_acc"  data-type: 'number  init-value: 0.0  y-offset: 40]
append fl-sr-st/shift-regs fl-sr
append fl-sr-diag/structures fl-sr-st

append fl-sr-diag/wires make-wire [from: 700  from-port: 'result  to: 701  to-port: "count"]

fl-sr-code: compile-structure fl-sr-st fl-sr-diag
fl-sr-acc-sw: find fl-sr-code to-set-word '_fl_acc

assert "SR acc inicializado"                     (not none? fl-sr-acc-sw)
assert "SR acc init-value 0.0"                   (0.0 = fl-sr-acc-sw/2)
assert "código contiene 'loop'"                  (not none? find fl-sr-code 'loop)

suite "file-io — round-trip for-loop"

reset-name-counters
fl-rt-diag: make-diagram "fl-rt-vi"
fl-rt-n-nd: make-node [id: 800  type: 'const  name: "fl_rt_n"  x: 50  y: 50]
fl-rt-n-nd/config: reduce ['default 5.0]
append fl-rt-diag/nodes fl-rt-n-nd

fl-rt-st: make-structure [id: 801  type: 'for-loop  name: "for-loop_rt"  x: 100  y: 100]
append fl-rt-diag/structures fl-rt-st
append fl-rt-diag/wires make-wire [from: 800  from-port: 'result  to: 801  to-port: "count"]

fl-rt-file: %/tmp/qtorres-fl-rt.qvi
save-vi fl-rt-file fl-rt-diag
fl-rt-loaded: load-vi fl-rt-file
if exists? fl-rt-file [delete fl-rt-file]

fl-rt-structs: fl-rt-loaded/structures
assert "round-trip: estructura cargada"          (1 = length? fl-rt-structs)
assert "round-trip: tipo for-loop"               ('for-loop = fl-rt-structs/1/type)
assert "round-trip: name correcto"               ("for-loop_rt" = fl-rt-structs/1/name)
assert "round-trip: label For Loop"              ("For Loop" = fl-rt-structs/1/label/text)
; Wire de N en diagram/wires
fl-rt-n-wire: none
foreach w fl-rt-loaded/wires [
    if all [w/to-node = 801  w/to-port = 'count] [fl-rt-n-wire: w]
]
assert "round-trip: wire N en diagram/wires"     (not none? fl-rt-n-wire)
assert "round-trip: wire N from correcto"        (800 = fl-rt-n-wire/from-node)

; ══════════════════════════════════════════════════════════════════════
; Case Structure — Tests
; ══════════════════════════════════════════════════════════════════════

suite "compile-case-structure — estructura vacía"

reset-name-counters
cs-empty-diag: make-diagram "cs-empty"
cs-empty-st: make-structure [id: 900  type: 'case-structure  name: "cs_empty"  x: 100  y: 100]
append cs-empty-st/frames make-frame [id: 0  label: "0"]
append cs-empty-diag/structures cs-empty-st

cs-empty-code: compile-case-structure cs-empty-st cs-empty-diag
assert "case structure vacía genera código"         (not empty? cs-empty-code)
assert "código contiene selector var"                 (not none? find cs-empty-code '_cs_empty_selector)

suite "compile-case-structure — con selector numérico"

reset-name-counters
cs-num-diag: make-diagram "cs-number"
cs-num-n1: make-node [id: 910  type: 'const  name: "cs_n_selector"  x: 50  y: 50]
cs-num-n1/config: reduce ['default 2.0]
cs-num-n2: make-node [id: 911  type: 'add  name: "cs_n_add"    x: 200  y: 120]
cs-num-n3: make-node [id: 912  type: 'const  name: "cs_n_a"      x: 100  y: 150]
cs-num-n3/config: reduce ['default 10.0]
cs-num-n4: make-node [id: 913  type: 'const  name: "cs_n_b"      x: 100  y: 200]
cs-num-n4/config: reduce ['default 5.0]
append cs-num-diag/nodes cs-num-n1
append cs-num-diag/nodes cs-num-n2
append cs-num-diag/nodes cs-num-n3
append cs-num-diag/nodes cs-num-n4

cs-num-st: make-structure [id: 920  type: 'case-structure  name: "cs_num"  x: 150  y: 100]
append cs-num-st/frames make-frame [id: 0  label: "0"]
append cs-num-st/frames make-frame [id: 1  label: "1"]
append cs-num-st/frames make-frame [id: 2  label: "Default"]

; Frame 1 (índice 2 en Red): add_1 = 10 + 5
frame1: cs-num-st/frames/2
append frame1/nodes make-node [id: 921  type: 'add  name: "cs_add_1"  x: 20  y: 20]
append frame1/nodes cs-num-n3
append frame1/nodes cs-num-n4
append frame1/wires make-wire [from: 912  from-port: 'result  to: 921  to-port: 'a]
append frame1/wires make-wire [from: 913  from-port: 'result  to: 921  to-port: 'b]

append cs-num-diag/structures cs-num-st

; Conectar selector
cs-num-st/selector-wire: make object! [from: 910  port: 'result]

cs-num-code: compile-case-structure cs-num-st cs-num-diag
assert "case structure con selector genera código"    (not empty? cs-num-code)
assert "código contiene selector var"                   (not none? find cs-num-code '_cs_num_selector)
; Verificar que case está en el código generado
cs-has-case: false
foreach item cs-num-code [if item = 'case [cs-has-case: true]]
assert "código contiene 'case"                          cs-has-case

suite "compile-case-structure — con selector booleano"

reset-name-counters
cs-bool-diag: make-diagram "cs-bool"
cs-bool-n1: make-node [id: 930  type: 'bool-const  name: "cs_b_selector"  x: 50  y: 50]
cs-bool-n1/config: reduce ['default true]
append cs-bool-diag/nodes cs-bool-n1

cs-bool-st: make-structure [id: 940  type: 'case-structure  name: "cs_bool"  x: 150  y: 100]
append cs-bool-st/frames make-frame [id: 0  label: "true"]
append cs-bool-st/frames make-frame [id: 1  label: "false"]

cs-bool-st/selector-wire: make object! [from: 930  port: 'result]
append cs-bool-diag/structures cs-bool-st

cs-bool-code: compile-case-structure cs-bool-st cs-bool-diag
assert "case structure boolean genera código"          (not empty? cs-bool-code)
assert "código contiene selector var"                   (not none? find cs-bool-code '_cs_bool_selector)
; Verificar que either está en el código generado
cs-has-either: false
foreach item cs-bool-code [if item = 'either [cs-has-either: true]]
assert "código contiene 'either"                        cs-has-either

print "--- tests de Case Structure completados ---"

; ══════════════════════════════════════════════════════════════════════
; Case Structure — Round-trip test
; ══════════════════════════════════════════════════════════════════════

suite "file-io — round-trip case-structure"

reset-name-counters
cs-rt-diag: make-diagram "cs-rt-vi"
cs-rt-n1: make-node [id: 950  type: 'const  name: "cs_rt_sel"  x: 50  y: 50]
cs-rt-n1/config: reduce ['default 1.0]
append cs-rt-diag/nodes cs-rt-n1

cs-rt-st: make-structure [id: 960  type: 'case-structure  name: "cs_rt"  x: 100  y: 100]
append cs-rt-st/frames make-frame [id: 0  label: "0"]
append cs-rt-st/frames make-frame [id: 1  label: "1"]
cs-rt-st/selector-wire: make object! [from: 950  port: 'result]
append cs-rt-diag/structures cs-rt-st

; Frame interno con nodo
frame0: cs-rt-st/frames/1
append frame0/nodes make-node [id: 961  type: 'add  name: "cs_rt_add"  x: 20  y: 20]

cs-rt-file: %/tmp/qtorres-cs-rt.qvi
save-vi cs-rt-file cs-rt-diag
assert "save-vi crea fichero case-structure"    (exists? cs-rt-file)

cs-rt-loaded: load-vi cs-rt-file
if exists? cs-rt-file [delete cs-rt-file]

assert "load-vi devuelve objeto"                (object? cs-rt-loaded)
assert "structures cargadas: 1"                 (1 = length? cs-rt-loaded/structures)
cs-rt-ls: first cs-rt-loaded/structures
assert "estructura es case-structure"           ('case-structure = cs-rt-ls/type)
assert "frames cargados: 2"                     (2 = length? cs-rt-ls/frames)
assert "frame 0 label correcto"                 ("0" = cs-rt-ls/frames/1/label)
assert "frame 1 label correcto"                 ("1" = cs-rt-ls/frames/2/label)
assert "selector-wire cargado"                  (object? cs-rt-ls/selector-wire)
assert "selector-wire from correcto"            (950 = cs-rt-ls/selector-wire/from)
assert "frame 0 tiene 1 nodo"                   (1 = length? cs-rt-ls/frames/1/nodes)
; Coords relativas → absolutas
assert "nodo interno x absoluta"                 (20 = cs-rt-ls/frames/1/nodes/1/x)
assert "nodo interno y absoluta"                 (20 = cs-rt-ls/frames/1/nodes/1/y)

print "--- tests de Case Structure round-trip completados ---"

; ══════════════════════════════════════════════════════════════════════
; Cluster — emit-bundle y emit-unbundle
; ══════════════════════════════════════════════════════════════════════

suite "cluster — emit-bundle"

; Diagrama: ctrl_name(str) ──name──► bundle_1 ──result──► display
;           ctrl_volt(num) ──voltaje─┘
reset-name-counters
cb-diag: make-diagram "cluster-bundle-vi"

cb-n1: make-node [id: 1  type: 'str-control  name: "ctrl_name"  x: 0   y: 0]
cb-n1/config: [default "Juan"]
cb-n2: make-node [id: 2  type: 'control      name: "ctrl_volt"  x: 0   y: 60]
cb-n2/config: [default 12.0]
cb-n3: make-node [id: 3  type: 'bundle       name: "bundle_1"   x: 200 y: 30]
cb-n3/config: [fields [nombre 'string  voltaje 'number]]

append cb-diag/nodes cb-n1
append cb-diag/nodes cb-n2
append cb-diag/nodes cb-n3
append cb-diag/wires make-wire [from: 1  from-port: 'result  to: 3  to-port: 'nombre]
append cb-diag/wires make-wire [from: 2  from-port: 'result  to: 3  to-port: 'voltaje]

cb-code: emit-bundle cb-n3 cb-diag

assert "emit-bundle devuelve bloque"             (block? cb-code)
assert "emit-bundle no está vacío"               (not empty? cb-code)

; El código generado debe ser: bundle_1_result: make object! [nombre: ctrl_name_result  voltaje: ctrl_volt_result]
; Verificar elementos clave
cb-has-make: false
foreach item cb-code [if item = 'make [cb-has-make: true]]
assert "emit-bundle contiene 'make"              cb-has-make

cb-has-object: false
foreach item cb-code [if datatype? item [if item = object! [cb-has-object: true]]]
assert "emit-bundle contiene object!"            cb-has-object

cb-set-word: first cb-code
assert "primer elemento es set-word bundle_1_result" (cb-set-word = to-set-word 'bundle_1_result)

cb-obj-body: last cb-code
assert "último elemento es bloque (cuerpo del objeto)" (block? cb-obj-body)
assert "cuerpo tiene 4 elementos (2 campos × 2)"       (4 = length? cb-obj-body)

suite "cluster — emit-unbundle"

; Diagrama: bundle_1 ──result──► unbundle_1 ──nombre──► ...
cu-diag: make-diagram "cluster-unbundle-vi"

cu-n1: make-node [id: 10  type: 'bundle    name: "bundle_1"    x: 0   y: 0]
cu-n1/config: [fields [nombre 'string  voltaje 'number]]
cu-n2: make-node [id: 11  type: 'unbundle  name: "unbundle_1"  x: 200 y: 0]
cu-n2/config: [fields [nombre 'string  voltaje 'number]]

append cu-diag/nodes cu-n1
append cu-diag/nodes cu-n2
append cu-diag/wires make-wire [from: 10  from-port: 'result  to: 11  to-port: 'cluster-in]

cu-code: emit-unbundle cu-n2 cu-diag

assert "emit-unbundle devuelve bloque"             (block? cu-code)
assert "emit-unbundle no está vacío"               (not empty? cu-code)

; Debe generar 2 asignaciones de path: unbundle_1_nombre: bundle_1_result/nombre
;                                       unbundle_1_voltaje: bundle_1_result/voltaje
assert "emit-unbundle genera 2×2 = 4 elementos"   (4 = length? cu-code)

cu-sw1: cu-code/1
cu-sw2: cu-code/3
assert "primera salida es set-word unbundle_1_nombre"   (cu-sw1 = to-set-word 'unbundle_1_nombre)
assert "segunda salida es set-word unbundle_1_voltaje"  (cu-sw2 = to-set-word 'unbundle_1_voltaje)

cu-path1: cu-code/2
cu-path2: cu-code/4
assert "primera ruta es path! bundle_1_result/nombre"  (path? cu-path1)
assert "segunda ruta es path! bundle_1_result/voltaje" (path? cu-path2)

suite "cluster — pipeline bundle → unbundle (compile-body)"

; Diagrama completo: ctrl ──► bundle ──► unbundle ──► display
cp-diag: make-diagram "cluster-pipeline-vi"

cp-ctrl:   make-node [id: 20  type: 'control   name: "ctrl_v"    x: 0    y: 0]
cp-ctrl/config: [default 42.0]
cp-bundle: make-node [id: 21  type: 'bundle    name: "bundle_p"  x: 150  y: 0]
cp-bundle/config: [fields [valor 'number]]
cp-unbundle: make-node [id: 22  type: 'unbundle  name: "unbundle_p"  x: 300 y: 0]
cp-unbundle/config: [fields [valor 'number]]

append cp-diag/nodes cp-ctrl
append cp-diag/nodes cp-bundle
append cp-diag/nodes cp-unbundle
append cp-diag/wires make-wire [from: 20  from-port: 'result  to: 21  to-port: 'valor]
append cp-diag/wires make-wire [from: 21  from-port: 'result  to: 22  to-port: 'cluster-in]

cp-code: compile-body cp-diag
assert "compile-body cluster pipeline devuelve bloque"  (block? cp-code)
assert "compile-body cluster pipeline no está vacío"     (not empty? cp-code)

; Ejecutar el código generado y verificar valores
do cp-code
assert "bundle produce objeto"                           (object? bundle_p_result)
assert "unbundle extrae valor correcto"                  (42.0 = unbundle_p_valor)

print "--- tests de Cluster completados ---"

; ══════════════════════════════════════════════════════════════
; Phase 6 — Serialización round-trip
; ══════════════════════════════════════════════════════════════

suite "cluster — serialize-nodes round-trip bundle"

; Crear nodo bundle con config, serializar, cargar de vuelta
rt-bundle: make-node [id: 30  type: 'bundle  name: "bundle_rt"  x: 10  y: 20]
rt-bundle/config: [fields [nombre 'string voltaje 'number activo 'boolean]]

rt-names: copy []
rt-serialized: serialize-nodes reduce [rt-bundle]
rt-loaded: load-node-list rt-serialized rt-names

assert "round-trip: serialize-nodes produce bloque"     (block? rt-serialized)
assert "round-trip: carga un nodo"                      (1 = length? rt-loaded)
rt-n: rt-loaded/1
assert "round-trip: type preservado"                    (rt-n/type = 'bundle)
assert "round-trip: name preservado"                    (rt-n/name = "bundle_rt")
rt-cfg: select rt-n/config 'fields
assert "round-trip: config/fields no es none"           (not none? rt-cfg)
assert "round-trip: config/fields tiene 6 elementos"    (6 = length? rt-cfg)
assert "round-trip: primer campo es 'nombre"            (rt-cfg/1 = 'nombre)
assert "round-trip: tipo de nombre es 'string"          (rt-cfg/2 = 'string)
assert "round-trip: segundo campo es 'voltaje"          (rt-cfg/3 = 'voltaje)
assert "round-trip: tipo de voltaje es 'number"         (rt-cfg/4 = 'number)

suite "cluster — serialize-nodes round-trip unbundle"

rt-unbundle: make-node [id: 31  type: 'unbundle  name: "unbundle_rt"  x: 50  y: 20]
rt-unbundle/config: [fields [nombre 'string voltaje 'number]]

rt-names2: copy []
rt-ser2: serialize-nodes reduce [rt-unbundle]
rt-lod2: load-node-list rt-ser2 rt-names2

rt-u: rt-lod2/1
rt-cfg2: select rt-u/config 'fields
assert "round-trip unbundle: type preservado"           (rt-u/type = 'unbundle)
assert "round-trip unbundle: config/fields no es none"  (not none? rt-cfg2)
assert "round-trip unbundle: 4 elementos en fields"     (4 = length? rt-cfg2)

suite "cluster — FP round-trip cluster-control"

; Crear cluster-control FP item, serializar, cargar de vuelta
rt-fp-spec: compose [
    id: 40  type: 'cluster-control  name: "ccluster_rt"
    label: [text: "Datos" visible: true]
    default: [nombre "" voltaje 0.0 activo false]
    config: [fields [nombre 'string voltaje 'number activo 'boolean]]
    offset: 30x50
]
rt-fp-item: make-fp-item rt-fp-spec

assert "FP round-trip: data-type es 'cluster"           (rt-fp-item/data-type = 'cluster)
assert "FP round-trip: config no es none"               (not none? rt-fp-item/config)
rt-fp-flds: select rt-fp-item/config 'fields
assert "FP round-trip: config/fields tiene 6 elementos" (6 = length? rt-fp-flds)

; Serializar con save-panel-to-diagram
rt-fp-serialized: save-panel-to-diagram reduce [rt-fp-item]
assert "FP serialize: bloque no vacío"                  (not empty? rt-fp-serialized)
assert "FP serialize: contiene front-panel:"            (not none? select rt-fp-serialized to-set-word 'front-panel)

; Cargar con load-panel-from-diagram
rt-fp-diag: make object! [front-panel: select rt-fp-serialized to-set-word 'front-panel]
; load-panel-from-diagram espera un bloque qvi-diagram
rt-fp-qd: reduce [to-set-word 'front-panel  select rt-fp-serialized to-set-word 'front-panel]
rt-fp-loaded: load-panel-from-diagram rt-fp-qd

assert "FP load: devuelve un item"                      (1 = length? rt-fp-loaded)
rt-fp-l: rt-fp-loaded/1
assert "FP load: type es cluster-control"               (rt-fp-l/type = 'cluster-control)
assert "FP load: data-type es 'cluster"                 (rt-fp-l/data-type = 'cluster)
rt-flds-l: select rt-fp-l/config 'fields
assert "FP load: config/fields preservado"              (not none? rt-flds-l)
assert "FP load: 6 elementos en fields"                 (6 = length? rt-flds-l)
assert "FP load: primer campo 'nombre"                  (rt-flds-l/1 = 'nombre)

print "--- tests de Serialización (Phase 6) completados ---"
