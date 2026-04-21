Red [Title: "Telekino — Tests Array 1D"]

do %../src/graph/blocks.red

; ── Registro de bloques ───────────────────────────────────────────────────

suite "array — registro de bloques"

assert "arr-const registrado"     (not none? find-block 'arr-const)
assert "arr-control registrado"   (not none? find-block 'arr-control)
assert "arr-indicator registrado" (not none? find-block 'arr-indicator)
assert "build-array registrado"   (not none? find-block 'build-array)
assert "index-array registrado"   (not none? find-block 'index-array)
assert "array-size registrado"    (not none? find-block 'array-size)
assert "array-subset registrado"  (not none? find-block 'array-subset)

suite "array — puertos"

b-arr-ctrl: find-block 'arr-control
assert "arr-control tiene 1 salida"         (1 = length? b-arr-ctrl/outputs)
assert "arr-control output es 'array"       ('array = b-arr-ctrl/outputs/1/type)
assert "arr-control tiene config default"   (1 = length? b-arr-ctrl/configs)

b-arr-ind: find-block 'arr-indicator
assert "arr-indicator tiene 1 entrada"      (1 = length? b-arr-ind/inputs)
assert "arr-indicator input es 'array"      ('array = b-arr-ind/inputs/1/type)

b-build: find-block 'build-array
assert "build-array tiene 2 entradas"       (2 = length? b-build/inputs)
assert "build-array tiene 1 salida 'array"  ('array = b-build/outputs/1/type)

b-idx: find-block 'index-array
assert "index-array tiene 2 entradas"       (2 = length? b-idx/inputs)
assert "index-array output es 'number"      ('number = b-idx/outputs/1/type)

b-size: find-block 'array-size
assert "array-size tiene 1 entrada 'array"  ('array = b-size/inputs/1/type)
assert "array-size output es 'number"       ('number = b-size/outputs/1/type)

b-sub: find-block 'array-subset
assert "array-subset tiene 3 entradas"      (3 = length? b-sub/inputs)
assert "array-subset output es 'array"      ('array = b-sub/outputs/1/type)

; ── bind-emit con block values ────────────────────────────────────────────

suite "array — bind-emit con block values"

test-emit: [result: copy default]
test-bindings: copy []
append test-bindings 'result
append test-bindings 'myarr_result
append test-bindings 'default
append/only test-bindings [1.0 2.0 3.0]

result-emit: bind-emit test-emit test-bindings
assert "bind-emit preserva block value (3 elementos)"  (3 = length? result-emit)
assert "bind-emit: set-word correcto"    (result-emit/1 = to-set-word 'myarr_result)
assert "bind-emit: copy intacto"         (result-emit/2 = 'copy)
assert "bind-emit: block value preservado" (block? result-emit/3)
assert "bind-emit: block value correcto"   (result-emit/3 = [1.0 2.0 3.0])

; ── compile-body con arr-const ───────────────────────────────────────────

suite "array — compile-body arr-const"

; Usar nombres explícitos para evitar guiones en identificadores Red
d-arr: make-diagram "test-array"
n-ac: make-node [id: 1  type: 'arr-const  name: "ac1"  x: 50  y: 50]
n-ac/config: copy [default [1.0 2.0 3.0]]
n-sz: make-node [id: 2  type: 'array-size  name: "sz1"  x: 200  y: 50]
n-ind: make-node [id: 3  type: 'indicator  name: "ind1"  x: 350  y: 50]

append d-arr/nodes n-ac
append d-arr/nodes n-sz
append d-arr/nodes n-ind

append d-arr/wires make-wire [from: 1  from-port: 'result  to: 2  to-port: 'arr]
append d-arr/wires make-wire [from: 2  from-port: 'result  to: 3  to-port: 'value]

body: compile-body d-arr
do body

assert "arr-const produce array correcto"   ([1.0 2.0 3.0] = ac1_result)
assert "array-size devuelve longitud 3.0"   (3.0 = sz1_result)

; ── index-array ──────────────────────────────────────────────────────────

suite "array — index-array"

d-idx: make-diagram "test-index"
n-src: make-node [id: 1  type: 'arr-const  name: "src2"  x: 50  y: 50]
n-src/config: copy [default [10.0 20.0 30.0]]
n-i: make-node [id: 2  type: 'const  name: "idx2"  x: 200  y: 50]
n-i/config: copy [default 1.0]   ; índice 1 (0-based) → segundo elemento
n-ix: make-node [id: 3  type: 'index-array  name: "ix2"  x: 350  y: 50]
n-o: make-node [id: 4  type: 'indicator  name: "out2"  x: 500  y: 50]

append d-idx/nodes n-src
append d-idx/nodes n-i
append d-idx/nodes n-ix
append d-idx/nodes n-o

append d-idx/wires make-wire [from: 1  from-port: 'result  to: 3  to-port: 'arr]
append d-idx/wires make-wire [from: 2  from-port: 'result  to: 3  to-port: 'index]
append d-idx/wires make-wire [from: 3  from-port: 'result  to: 4  to-port: 'value]

body-idx: compile-body d-idx
do body-idx

; índice 1.0 → to-integer(1.0) + 1 = 2 → pick [10.0 20.0 30.0] 2 = 20.0
assert "index-array índice 1 → 20.0"  (20.0 = ix2_result)

; ── build-array ──────────────────────────────────────────────────────────

suite "array — build-array"

d-build: make-diagram "test-build"
n-c1: make-node [id: 1  type: 'const  name: "c1"  x: 50  y: 50]
n-c1/config: copy [default 5.0]
n-c2: make-node [id: 2  type: 'const  name: "c2"  x: 50  y: 120]
n-c2/config: copy [default 7.0]
n-ba: make-node [id: 3  type: 'build-array  name: "ba1"  x: 200  y: 80]
n-bo: make-node [id: 4  type: 'arr-indicator  name: "bo1"  x: 350  y: 80]

append d-build/nodes n-c1
append d-build/nodes n-c2
append d-build/nodes n-ba
append d-build/nodes n-bo

append d-build/wires make-wire [from: 1  from-port: 'result  to: 3  to-port: 'a]
append d-build/wires make-wire [from: 2  from-port: 'result  to: 3  to-port: 'b]
append d-build/wires make-wire [from: 3  from-port: 'result  to: 4  to-port: 'value]

body-build: compile-body d-build
do body-build

assert "build-array produce [5.0 7.0]"  ([5.0 7.0] = ba1_result)

; ── array-subset ─────────────────────────────────────────────────────────

suite "array — array-subset"

d-ss: make-diagram "test-subset"
n-ss-src: make-node [id: 1  type: 'arr-const  name: "ss-src"  x: 50  y: 50]
n-ss-src/config: copy [default [1.0 2.0 3.0 4.0 5.0]]
n-ss-st: make-node [id: 2  type: 'const  name: "ss-st"  x: 50  y: 120]
n-ss-st/config: copy [default 1.0]   ; start=1
n-ss-ln: make-node [id: 3  type: 'const  name: "ss-ln"  x: 50  y: 190]
n-ss-ln/config: copy [default 3.0]   ; length=3
n-ss: make-node [id: 4  type: 'array-subset  name: "ss1"  x: 250  y: 100]
n-ss-o: make-node [id: 5  type: 'arr-indicator  name: "ss-o"  x: 400  y: 100]

append d-ss/nodes n-ss-src
append d-ss/nodes n-ss-st
append d-ss/nodes n-ss-ln
append d-ss/nodes n-ss
append d-ss/nodes n-ss-o

append d-ss/wires make-wire [from: 1  from-port: 'result  to: 4  to-port: 'arr]
append d-ss/wires make-wire [from: 2  from-port: 'result  to: 4  to-port: 'start]
append d-ss/wires make-wire [from: 3  from-port: 'result  to: 4  to-port: 'length]
append d-ss/wires make-wire [from: 4  from-port: 'result  to: 5  to-port: 'value]

body-ss: compile-body d-ss
do body-ss

; skip [1 2 3 4 5] 1 → [2 3 4 5], copy/part 3 → [2 3 4] = [2.0 3.0 4.0]
assert "array-subset start=1 length=3 → [2.0 3.0 4.0]"  ([2.0 3.0 4.0] = ss1_result)
