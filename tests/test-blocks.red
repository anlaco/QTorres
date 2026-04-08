Red [Title: "QTorres — Tests blocks"]

do %../src/graph/model.red  ; model.red incluye blocks.red y ahora también make-fp-item (4A)

suite "blocks — registro"

assert "registra 38 bloques (34 anteriores + bundle + unbundle + waveform-chart + waveform-graph)" (38 = length? block-registry)
assert "const está en el registro"     (not none? find-block 'const)
assert "add está en el registro"       (not none? find-block 'add)
assert "find-block devuelve none para bloques inexistentes" (none? find-block 'nonexistent)

suite "blocks — puertos"

b-add: find-block 'add
assert "add tiene 2 entradas"              (2 = length? b-add/inputs)
assert "add tiene 1 salida"               (1 = length? b-add/outputs)
assert "block-in-ports 'add devuelve [a b]"      ([a b] = block-in-ports 'add)
assert "block-out-ports 'add devuelve [result]"  ([result] = block-out-ports 'add)

b-display: find-block 'display
assert "display no tiene salidas"  (0 = length? b-display/outputs)

b-const: find-block 'const
assert "const no tiene entradas"   (0 = length? b-const/inputs)

suite "blocks — config"

assert "const tiene 1 config (default)"    (1 = length? b-const/configs)
cfg1: first b-const/configs
assert "config de const se llama default"  ('default = cfg1/name)

suite "blocks — emit"

assert "add tiene emit definido"          (not none? b-add/emit)
assert "emit de add es [result: a + b]"   ([result: a + b] = b-add/emit)

suite "blocks — booleanos: registro"

assert "bool-const está en el registro"     (not none? find-block 'bool-const)
assert "bool-control está en el registro"   (not none? find-block 'bool-control)
assert "bool-indicator está en el registro" (not none? find-block 'bool-indicator)
assert "and-op está en el registro"         (not none? find-block 'and-op)
assert "or-op está en el registro"          (not none? find-block 'or-op)
assert "not-op está en el registro"         (not none? find-block 'not-op)
assert "gt-op está en el registro"          (not none? find-block 'gt-op)
assert "lt-op está en el registro"          (not none? find-block 'lt-op)
assert "eq-op está en el registro"          (not none? find-block 'eq-op)

suite "blocks — booleanos: tipos de puertos"

b-and: find-block 'and-op
b-not: find-block 'not-op
b-gt:  find-block 'gt-op
b-bc:  find-block 'bool-const

and-out1: first b-and/outputs
and-in1:  first b-and/inputs
not-in1:  first b-not/inputs
not-out1: first b-not/outputs
gt-in1:   first b-gt/inputs
gt-out1:  first b-gt/outputs
bc-out1:  first b-bc/outputs

assert "and-op: output es tipo boolean"     ('boolean = and-out1/type)
assert "and-op: input a es tipo boolean"    ('boolean = and-in1/type)
assert "not-op: input es tipo boolean"      ('boolean = not-in1/type)
assert "not-op: output es tipo boolean"     ('boolean = not-out1/type)
assert "gt-op: inputs son tipo number"      ('number  = gt-in1/type)
assert "gt-op: output es tipo boolean"      ('boolean = gt-out1/type)
assert "bool-const: output es tipo boolean" ('boolean = bc-out1/type)

suite "blocks — booleanos: emit"

assert "and-op emit es [result: a and b]"  ([result: a and b] = b-and/emit)
assert "not-op emit es [result: not a]"    ([result: not a]   = b-not/emit)

suite "blocks — string: registro"

assert "str-const está en el registro"     (not none? find-block 'str-const)
assert "str-control está en el registro"   (not none? find-block 'str-control)
assert "str-indicator está en el registro" (not none? find-block 'str-indicator)
assert "concat está en el registro"        (not none? find-block 'concat)
assert "str-length está en el registro"    (not none? find-block 'str-length)
assert "to-string está en el registro"     (not none? find-block 'to-string)

suite "blocks — string: tipos de puertos"

b-sc:  find-block 'str-const
b-cat: find-block 'concat
b-len: find-block 'str-length
b-ts:  find-block 'to-string

sc-out1:  first b-sc/outputs
cat-in1:  first b-cat/inputs
cat-out1: first b-cat/outputs
len-in1:  first b-len/inputs
len-out1: first b-len/outputs
ts-in1:   first b-ts/inputs
ts-out1:  first b-ts/outputs

assert "str-const: output es tipo string"   ('string = sc-out1/type)
assert "concat: input a es tipo string"     ('string = cat-in1/type)
assert "concat: output es tipo string"      ('string = cat-out1/type)
assert "str-length: input es tipo string"   ('string = len-in1/type)
assert "str-length: output es tipo number"  ('number = len-out1/type)
assert "to-string: input es tipo number"    ('number = ts-in1/type)
assert "to-string: output es tipo string"   ('string = ts-out1/type)

suite "blocks — string: emit"

assert "concat emit es [result: rejoin [a b]]"             ([result: rejoin [a b]]        = b-cat/emit)
assert "str-length emit es [result: to-float length? a]"   ([result: to-float length? a]  = b-len/emit)
assert "to-string emit es [result: form a]"                ([result: form a]              = b-ts/emit)

suite "blocks — cluster: registro"

assert "registra 38 bloques (34 anteriores + bundle + unbundle + waveform-chart + waveform-graph)" (38 = length? block-registry)
assert "bundle está en el registro"   (not none? find-block 'bundle)
assert "unbundle está en el registro" (not none? find-block 'unbundle)

b-bundle:   find-block 'bundle
b-unbundle: find-block 'unbundle

assert "bundle categoría es cluster"   ('cluster = b-bundle/category)
assert "unbundle categoría es cluster" ('cluster = b-unbundle/category)

suite "blocks — cluster: puertos fijos"

bundle-out1:   first b-bundle/outputs
unbundle-in1:  first b-unbundle/inputs

assert "bundle no tiene entradas fijas"              (0 = length? b-bundle/inputs)
assert "bundle tiene 1 salida fija (result)"         (1 = length? b-bundle/outputs)
assert "bundle salida es tipo cluster"               ('cluster = bundle-out1/type)
assert "bundle salida se llama result"               ('result  = bundle-out1/name)

assert "unbundle tiene 1 entrada fija (cluster-in)"  (1 = length? b-unbundle/inputs)
assert "unbundle no tiene salidas fijas"             (0 = length? b-unbundle/outputs)
assert "unbundle entrada es tipo cluster"            ('cluster = unbundle-in1/type)
assert "unbundle entrada se llama cluster-in"        ('cluster-in = unbundle-in1/name)

suite "blocks — waveform: registro"

assert "waveform-chart está en el registro"   (not none? find-block 'waveform-chart)
assert "waveform-graph está en el registro"  (not none? find-block 'waveform-graph)

b-chart: find-block 'waveform-chart
b-graph: find-block 'waveform-graph

assert "waveform-chart categoría es output"  ('output = b-chart/category)
assert "waveform-graph categoría es output"   ('output = b-graph/category)

suite "blocks — waveform: puertos"

chart-in1: first b-chart/inputs
graph-in1:  first b-graph/inputs

assert "waveform-chart tiene 1 entrada"     (1 = length? b-chart/inputs)
assert "waveform-chart tiene 0 salidas"     (0 = length? b-chart/outputs)
assert "waveform-chart input es tipo number" ('number = chart-in1/type)
assert "waveform-chart input se llama value" ('value  = chart-in1/name)

assert "waveform-graph tiene 1 entrada"     (1 = length? b-graph/inputs)
assert "waveform-graph tiene 0 salidas"      (0 = length? b-graph/outputs)
assert "waveform-graph input es tipo array"  ('array  = graph-in1/type)
assert "waveform-graph input se llama array" ('array   = graph-in1/name)

suite "blocks — waveform: emit"

assert "waveform-chart no tiene emit (se maneja en compile-panel)" (none? b-chart/emit)
assert "waveform-graph no tiene emit (se maneja en compile-panel)" (none? b-graph/emit)

suite "blocks — waveform: FP item"

; make-fp-item movida a model.red (4A) — ya cargado al inicio del test
; (antes: do %../src/ui/panel/panel.red)

wc: make-fp-item [id: 100  type: 'waveform-chart  name: "chart_1"  label: [text: "Señal" visible: true]  offset: 50x50]
wg: make-fp-item [id: 101  type: 'waveform-graph  name: "graph_1"  label: [text: "Array" visible: true]  offset: 50x250]

assert "waveform-chart type correcto"      ('waveform-chart = wc/type)
assert "waveform-chart data-type es waveform" ('waveform = wc/data-type)
assert "waveform-chart name correcto"       ("chart_1" = wc/name)
assert "waveform-chart label/text correcto" ("Señal" = wc/label/text)
assert "waveform-chart value es block"      (block? wc/value)
assert "waveform-chart value vacío inicial" (empty? wc/value)
assert "waveform-chart config es block"     (block? any [wc/config copy []])

assert "waveform-graph type correcto"       ('waveform-graph = wg/type)
assert "waveform-graph data-type es waveform" ('waveform = wg/data-type)
assert "waveform-graph name correcto"       ("graph_1" = wg/name)
assert "waveform-graph label/text correcto" ("Array" = wg/label/text)
assert "waveform-graph value es block"      (block? wg/value)
assert "waveform-graph value vacío inicial"  (empty? wg/value)
