Red [Title: "QTorres — Tests blocks"]

do %../src/graph/model.red  ; model.red incluye blocks.red y ahora también make-fp-item (4A)

suite "blocks — registro"

assert "registra 45 bloques (41 + tcp-open + tcp-write + tcp-read + tcp-close)" (45 = length? block-registry)
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

assert "registra 45 bloques (41 + tcp-open + tcp-write + tcp-read + tcp-close)" (45 = length? block-registry)
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

; ══════════════════════════════════════════════════════════════════
; Fase 4 — Issue #19: Bloques TCP estilo LabVIEW (connection refnum)
; ══════════════════════════════════════════════════════════════════

suite "blocks — tcp: registro"

b-tcpo: find-block 'tcp-open
b-tcpw: find-block 'tcp-write
b-tcpr: find-block 'tcp-read
b-tcpx: find-block 'tcp-close

assert "tcp-open está en el registro"  (not none? b-tcpo)
assert "tcp-write está en el registro" (not none? b-tcpw)
assert "tcp-read está en el registro"  (not none? b-tcpr)
assert "tcp-close está en el registro" (not none? b-tcpx)

assert "tcp-open categoría es hardware"  ('hardware = b-tcpo/category)
assert "tcp-write categoría es hardware" ('hardware = b-tcpw/category)
assert "tcp-read categoría es hardware"  ('hardware = b-tcpr/category)
assert "tcp-close categoría es hardware" ('hardware = b-tcpx/category)

suite "blocks — tcp: puertos (estilo LabVIEW)"

; tcp-open: 3 entradas (address, remote-port, timeout-ms) → 1 salida (connection-out)
tcpo-in1:  first  b-tcpo/inputs
tcpo-in2:  second b-tcpo/inputs
tcpo-in3:  third  b-tcpo/inputs
tcpo-out1: first  b-tcpo/outputs

assert "tcp-open tiene 3 entradas"                   (3 = length? b-tcpo/inputs)
assert "tcp-open tiene 1 salida"                     (1 = length? b-tcpo/outputs)
assert "tcp-open in[0] se llama address"             ('address     = tcpo-in1/name)
assert "tcp-open in[0] es string"                    ('string      = tcpo-in1/type)
assert "tcp-open in[0] default es localhost"         ("localhost"   = tcpo-in1/default)
assert "tcp-open in[1] se llama remote-port"         ('remote-port = tcpo-in2/name)
assert "tcp-open in[1] es number"                    ('number      = tcpo-in2/type)
assert "tcp-open in[1] default es 5000"              (5000         = tcpo-in2/default)
assert "tcp-open in[2] se llama timeout-ms"          ('timeout-ms  = tcpo-in3/name)
assert "tcp-open in[2] default es 60000"             (60000        = tcpo-in3/default)
assert "tcp-open salida se llama connection-out"     ('connection-out  = tcpo-out1/name)
assert "tcp-open salida es tcp-connection"           ('tcp-connection  = tcpo-out1/type)
assert "tcp-open no tiene configs"                   (0 = length? b-tcpo/configs)

; tcp-write: connection-in + data → connection-out + bytes-written
tcpw-in1:  first  b-tcpw/inputs
tcpw-in2:  second b-tcpw/inputs
tcpw-out1: first  b-tcpw/outputs
tcpw-out2: second b-tcpw/outputs

assert "tcp-write tiene 2 entradas"                  (2 = length? b-tcpw/inputs)
assert "tcp-write tiene 2 salidas"                   (2 = length? b-tcpw/outputs)
assert "tcp-write in[0] se llama connection-in"      ('connection-in   = tcpw-in1/name)
assert "tcp-write in[0] es tcp-connection"           ('tcp-connection  = tcpw-in1/type)
assert "tcp-write in[1] se llama data"               ('data            = tcpw-in2/name)
assert "tcp-write in[1] es string"                   ('string          = tcpw-in2/type)
assert "tcp-write out[0] se llama connection-out"    ('connection-out  = tcpw-out1/name)
assert "tcp-write out[0] es tcp-connection"          ('tcp-connection  = tcpw-out1/type)
assert "tcp-write out[1] se llama bytes-written"     ('bytes-written   = tcpw-out2/name)
assert "tcp-write out[1] es number"                  ('number          = tcpw-out2/type)
assert "tcp-write no tiene configs"                  (0 = length? b-tcpw/configs)

; tcp-read: connection-in + bytes-to-read + timeout-ms → connection-out + data + bytes-read
tcpr-in1:  first  b-tcpr/inputs
tcpr-in2:  second b-tcpr/inputs
tcpr-in3:  third  b-tcpr/inputs
tcpr-out1: first  b-tcpr/outputs
tcpr-out2: second b-tcpr/outputs
tcpr-out3: third  b-tcpr/outputs

assert "tcp-read tiene 3 entradas"                   (3 = length? b-tcpr/inputs)
assert "tcp-read tiene 3 salidas"                    (3 = length? b-tcpr/outputs)
assert "tcp-read in[0] se llama connection-in"       ('connection-in   = tcpr-in1/name)
assert "tcp-read in[1] se llama bytes-to-read"       ('bytes-to-read   = tcpr-in2/name)
assert "tcp-read in[1] default es 256"               (256              = tcpr-in2/default)
assert "tcp-read in[2] se llama timeout-ms"          ('timeout-ms      = tcpr-in3/name)
assert "tcp-read in[2] default es 60000"             (60000            = tcpr-in3/default)
assert "tcp-read out[0] se llama connection-out"     ('connection-out  = tcpr-out1/name)
assert "tcp-read out[1] se llama data"               ('data            = tcpr-out2/name)
assert "tcp-read out[1] es string"                   ('string          = tcpr-out2/type)
assert "tcp-read out[2] se llama bytes-read"         ('bytes-read      = tcpr-out3/name)
assert "tcp-read no tiene configs"                   (0 = length? b-tcpr/configs)

; tcp-close: connection-in → connection-out
tcpx-in1:  first b-tcpx/inputs
tcpx-out1: first b-tcpx/outputs

assert "tcp-close tiene 1 entrada"                   (1 = length? b-tcpx/inputs)
assert "tcp-close tiene 1 salida"                    (1 = length? b-tcpx/outputs)
assert "tcp-close in[0] se llama connection-in"      ('connection-in   = tcpx-in1/name)
assert "tcp-close in[0] es tcp-connection"           ('tcp-connection  = tcpx-in1/type)
assert "tcp-close out[0] se llama connection-out"    ('connection-out  = tcpx-out1/name)
assert "tcp-close out[0] es tcp-connection"          ('tcp-connection  = tcpx-out1/type)
assert "tcp-close no tiene configs"                  (0 = length? b-tcpx/configs)

suite "blocks — tcp: emit (helpers connection refnum)"

assert "tcp-open tiene emit"   (block? b-tcpo/emit)
assert "tcp-write tiene emit"  (block? b-tcpw/emit)
assert "tcp-read tiene emit"   (block? b-tcpr/emit)
assert "tcp-close tiene emit"  (block? b-tcpx/emit)

assert "tcp-open emit usa _tcp-open-helper"    (not none? find mold b-tcpo/emit "_tcp-open-helper")
assert "tcp-write emit usa _tcp-write-helper"  (not none? find mold b-tcpw/emit "_tcp-write-helper")
assert "tcp-read emit usa _tcp-read-helper"    (not none? find mold b-tcpr/emit "_tcp-read-helper")
assert "tcp-close emit usa _tcp-close-helper"  (not none? find mold b-tcpx/emit "_tcp-close-helper")

assert "tcp-read emit asigna connection-out"   (not none? find mold b-tcpr/emit "connection-out")
assert "tcp-read emit asigna data"             (not none? find mold b-tcpr/emit "data")
assert "tcp-read emit asigna bytes-read"       (not none? find mold b-tcpr/emit "bytes-read")
assert "tcp-write emit asigna bytes-written"   (not none? find mold b-tcpw/emit "bytes-written")

suite "blocks — tcp: helpers runtime definidos"

assert "_make-tcp-connection está definido" (function? :_make-tcp-connection)
assert "_tcp-open-helper está definido"     (function? :_tcp-open-helper)
assert "_tcp-write-helper está definido"    (function? :_tcp-write-helper)
assert "_tcp-read-helper está definido"     (function? :_tcp-read-helper)
assert "_tcp-close-helper está definido"    (function? :_tcp-close-helper)

; _make-tcp-connection construye objeto con los campos correctos
_conn-test: _make-tcp-connection true "localhost" 5000
assert "_make-tcp-connection activa?"   (true       = _conn-test/active?)
assert "_make-tcp-connection host"      ("localhost" = _conn-test/host)
assert "_make-tcp-connection port"      (5000        = _conn-test/port)

; helpers con conexión inactiva son no-op
_conn-off: _make-tcp-connection false "x" 0
_w-noop: _tcp-write-helper _conn-off "ignored"
assert "_tcp-write-helper no-op devuelve bloque"     (block? _w-noop)
assert "_tcp-write-helper no-op bytes-written es 0"  (0 = _w-noop/2)
assert "_tcp-close-helper no-op si inactiva"         (not _conn-off/active?)
_r-noop: _tcp-read-helper _conn-off 64 100
assert "_tcp-read-helper no-op devuelve data vacío"  ("" = _r-noop/2)
assert "_tcp-read-helper no-op bytes-read es 0"      (0  = _r-noop/3)
