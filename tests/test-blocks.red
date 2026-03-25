Red [Title: "QTorres — Tests blocks"]

do %../src/graph/blocks.red

suite "blocks — registro"

assert "registra 25 bloques (8 originales + 9 booleanos + 6 string + 2 estructura+virtual)" (25 = length? block-registry)
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
