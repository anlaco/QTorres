Red [
    Title:   "QTorres — Compilador"
    Purpose: "Transforma un diagrama (modelo de grafo) en código Red dentro del .qvi"
]

; === Compilador ===
; Recorre el grafo en orden topológico y genera código Red.
; El resultado se escribe como la sección de código del .qvi.
;
; Responsabilidades:
;   - Sort topológico del grafo
;   - Instanciar plantilla de código por tipo de nodo
;   - Si el VI tiene connector pane → envolver en func
;   - Si el VI contiene sub-VIs → emitir do %sub-vi.qvi al inicio
;   - Generar guarda if not value? 'qtorres-runtime para ejecución standalone
;
; Por implementar:
;   compile-diagram: función diagram → string (código Red)
;   topological-sort: función diagram → lista ordenada de nodos
;   instantiate-template: función nodo, entradas → string
;   wrap-as-function: función connector, body → string (func Red)
;   emit-subvi-loads: función diagram → string (do %subvi.qvi ...)
