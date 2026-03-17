Red [
    Title:   "QTorres — Compilador"
    Purpose: "Transforma un diagrama (modelo de grafo) en código Red dentro del .qvi"
]

; ══════════════════════════════════════════════════
; DIALECTO: emit
; ══════════════════════════════════════════════════
; El compilador no usa interpolación de strings.
; Cada bloque registrado define un bloque `emit` que es código Red
; con palabras que hacen referencia a los puertos del bloque.
;
; El compilador:
;   1. Ordena los nodos topológicamente
;   2. Para cada nodo, busca su definición en el block-registry
;   3. Toma el bloque `emit` y sustituye las palabras de los puertos
;      por los nombres reales de las variables (que vienen de los wires)
;   4. El resultado es código Red generado por manipulación de bloques Red
;
; Ejemplo:
;   El bloque 'add tiene: emit [result: a + b]
;   El nodo "Suma" recibe wire de "A" en puerto 'a y de "B" en puerto 'b
;   El compilador sustituye: a → A, b → B, result → Suma
;   Resultado: [Suma: A + B]
;
; Esto es manipulación de bloques Red, no strings. El código generado
; es un bloque Red que se puede componer, inspeccionar y ejecutar.

; ══════════════════════════════════════════════════
; TOPOLOGICAL-SORT
; ══════════════════════════════════════════════════
;
; Algoritmo de Kahn (BFS).
; Entrada:  un objeto diagrama con /nodes y /wires (make-diagram).
; Salida:   un block! con los nodos en orden de compilación,
;           o un error si se detecta un ciclo.
;
; Un nodo A "precede" a B cuando hay un wire from-node=A/id to-node=B/id.

topological-sort: func [
    diagram [object!]
    /local nodes wires in-degree id-to-node queue result nid neighbors w
][
    nodes:  diagram/nodes
    wires:  diagram/wires

    ; ── Paso 1: inicializar in-degree a 0 para cada nodo ──────────────
    in-degree: make map! []
    id-to-node: make map! []
    foreach n nodes [
        in-degree/(n/id): 0
        id-to-node/(n/id): n
    ]

    ; ── Paso 2: contar entradas reales desde los wires ─────────────────
    foreach w wires [
        in-degree/(w/to-node): in-degree/(w/to-node) + 1
    ]

    ; ── Paso 3: cola inicial — nodos con in-degree 0 ───────────────────
    queue: copy []
    foreach n nodes [
        if in-degree/(n/id) = 0 [append queue n/id]
    ]

    ; ── Paso 4: bucle de Kahn ───────────────────────────────────────────
    result: copy []
    while [not empty? queue] [
        nid: take queue                        ; sacar primero de la cola
        append result id-to-node/:nid          ; añadir nodo al resultado

        ; decrementar in-degree de todos los vecinos (to-node de este nodo)
        foreach w wires [
            if w/from-node = nid [
                in-degree/(w/to-node): in-degree/(w/to-node) - 1
                if in-degree/(w/to-node) = 0 [
                    append queue w/to-node
                ]
            ]
        ]
    ]

    ; ── Paso 5: detección de ciclos ────────────────────────────────────
    if (length? result) <> (length? nodes) [
        cause-error 'user 'message ["topological-sort: ciclo detectado en el diagrama"]
    ]

    result
]

; ══════════════════════════════════════════════════
; Por implementar:
;   bind-emit:        func emit-block, port-bindings → block!
;   compile-diagram:  func diagram → block! (código Red como bloque)
;   wrap-as-function: func connector, body → block!
;   emit-subvi-loads: func diagram → block!
; ══════════════════════════════════════════════════

; ══════════════════════════════════════════════════
; TEST — ejecutar: red src/compiler/compiler.red
; ══════════════════════════════════════════════════
;
; Diagrama:  const_A ──┐
;                      ├──→ add_1 ──→ display_1
;            const_B ──┘
;
; Orden esperado: [const_A, const_B, add_1, display_1]  (A y B intercambiables)

do %../graph/model.red

d: make-diagram "test"

append d/nodes make-node [id: 1  type: 'const  label: "const_A"  x: 0  y: 0]
append d/nodes make-node [id: 2  type: 'const  label: "const_B"  x: 0  y: 60]
append d/nodes make-node [id: 3  type: 'add    label: "add_1"    x: 200 y: 30]
append d/nodes make-node [id: 4  type: 'display label: "display_1" x: 400 y: 30]

append d/wires make-wire [from: 1  port: 'result  to: 3  port: 'a]
append d/wires make-wire [from: 2  port: 'result  to: 3  port: 'b]
append d/wires make-wire [from: 3  port: 'result  to: 4  port: 'value]

print "--- topological-sort ---"
sorted: topological-sort d
foreach n sorted [
    print rejoin ["  " n/id " " n/label]
]
print ""

; Test de ciclo: A → B → A
print "--- detección de ciclo ---"
d2: make-diagram "ciclo"
append d2/nodes make-node [id: 10  type: 'add  label: "X"  x: 0  y: 0]
append d2/nodes make-node [id: 11  type: 'add  label: "Y"  x: 200 y: 0]
append d2/wires make-wire [from: 10  port: 'result  to: 11  port: 'a]
append d2/wires make-wire [from: 11  port: 'result  to: 10  port: 'a]

err: try [topological-sort d2]
either error? err [
    print rejoin ["  Error detectado correctamente: " err/arg1]
][
    print "  ERROR: no se detectó el ciclo"
]
