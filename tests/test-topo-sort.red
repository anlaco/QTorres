Red [Title: "QTorres — Tests topological-sort"]

do %../src/graph/model.red
do %../src/compiler/compiler.red

suite "topo-sort — cadena lineal"

; const_A → add → display
d: make-diagram "lineal"
append d/nodes make-node [id: 1  type: 'const    label: "const_A"   x: 0    y: 0]
append d/nodes make-node [id: 2  type: 'add      label: "add_1"     x: 200  y: 0]
append d/nodes make-node [id: 3  type: 'display  label: "display_1" x: 400  y: 0]
append d/wires make-wire [from: 1  from-port: 'result  to: 2  to-port: 'a]
append d/wires make-wire [from: 2  from-port: 'result  to: 3  to-port: 'value]

sorted: topological-sort d
n-first: first sorted
n-last:  last sorted
n-mid:   sorted/2

assert "devuelve 3 nodos"       (3 = length? sorted)
assert "const_A es el primero"  (1 = n-first/id)
assert "display_1 es el último" (3 = n-last/id)
assert "add_1 va en el medio"   (2 = n-mid/id)

suite "topo-sort — diamante (dos fuentes, un sumidero)"

; const_A ──┐
;           ├──→ add → display
; const_B ──┘
d2: make-diagram "diamante"
append d2/nodes make-node [id: 1  type: 'const    label: "A"  x: 0    y: 0]
append d2/nodes make-node [id: 2  type: 'const    label: "B"  x: 0    y: 60]
append d2/nodes make-node [id: 3  type: 'add      label: "S"  x: 200  y: 30]
append d2/nodes make-node [id: 4  type: 'display  label: "D"  x: 400  y: 30]
append d2/wires make-wire [from: 1  from-port: 'result  to: 3  to-port: 'a]
append d2/wires make-wire [from: 2  from-port: 'result  to: 3  to-port: 'b]
append d2/wires make-wire [from: 3  from-port: 'result  to: 4  to-port: 'value]

sorted2: topological-sort d2
d2-n3:   sorted2/3
d2-last: last sorted2

assert "devuelve 4 nodos"         (4 = length? sorted2)
assert "add va en la posición 3"  (3 = d2-n3/id)
assert "display va el último"     (4 = d2-last/id)

suite "topo-sort — diagrama vacío"

d3: make-diagram "vacio"
sorted3: topological-sort d3

assert "diagrama vacío devuelve lista vacía" (empty? sorted3)

suite "topo-sort — nodo aislado"

d4: make-diagram "aislado"
append d4/nodes make-node [id: 1  type: 'const  label: "solo"  x: 0  y: 0]
sorted4: topological-sort d4

assert "nodo sin wires se devuelve solo" (1 = length? sorted4)

suite "topo-sort — detección de ciclos"

d5: make-diagram "ciclo"
append d5/nodes make-node [id: 10  type: 'add  label: "X"  x: 0    y: 0]
append d5/nodes make-node [id: 11  type: 'add  label: "Y"  x: 200  y: 0]
append d5/wires make-wire [from: 10  from-port: 'result  to: 11  to-port: 'a]
append d5/wires make-wire [from: 11  from-port: 'result  to: 10  to-port: 'a]

assert-error "ciclo directo lanza error" [topological-sort d5]
