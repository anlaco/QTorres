Red [
    Title:   "QTorres — Runner"
    Purpose: "Ejecuta un diagrama en memoria desde QTorres sin tocar el disco"
]

; ══════════════════════════════════════════════════
; RUN
; ══════════════════════════════════════════════════
;
; Compila el diagrama a código Red en memoria y lo ejecuta con do.
; No escribe ningún fichero al disco (DT-010).
;
; Flujo:
;   1. qtorres-runtime: true  → sub-VIs no se auto-ejecutan al ser cargados
;   2. compile-body genera el bloque de código headless
;   3. do ejecuta el bloque en el contexto actual
;   4. qtorres-runtime: false
;
; El runner reutiliza el mismo compilador que save-vi, pero en lugar de
; escribir el fichero devuelve el resultado de la ejecución.

run: func [
    diagram [object!]
    /local code
][
    qtorres-runtime: true
    code: compile-body diagram
    attempt [do code]
    qtorres-runtime: false
    true
]

#include %../io/file-io.red
