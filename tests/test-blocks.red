Red [Title: "QTorres — Tests blocks"]

do %../src/graph/blocks.red

suite "blocks — registro"

assert "registra 6 bloques primitivos" (6 = length? block-registry)
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
