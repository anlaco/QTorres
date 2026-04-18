Red [
    Title:   "QTorres — Compilador (orquestador)"
    Purpose: "Transforma un diagrama (modelo de grafo) en código Red dentro del .qvi"
]

; Módulos del compilador (orden importa por dependencias):
;   topo      — topological-sort, build-sorted-items
;   emit      — bind-emit, port-var, build-bindings, emit-bundle/unbundle/cluster-*
;   structures — compile-structure (while/for), compile-case-structure
;   body      — compile-body, compile-diagram, compile-subvi-call
;   panel     — compile-panel, gen-panel-var-name, gen-indicator-var-name, gen-standalone-code

#include %compiler-topo.red
#include %compiler-emit.red
#include %compiler-structures.red
#include %compiler-body.red
#include %compiler-panel.red
#include %../runner/runner.red
