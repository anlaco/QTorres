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
    /local code result subvi-node
][
    qtorres-runtime: true

    ; Cargar contextos de sub-VIs referenciados en el diagrama
    foreach subvi-node diagram/nodes [
        if all [subvi-node/type = 'subvi  file? subvi-node/file  exists? subvi-node/file] [
            ; try puede devolver unset! si el fichero termina con print/unset,
            ; añadimos none para forzar retorno tipado
            result: try [do subvi-node/file  none]
            if error? result [
                print rejoin ["[runner] ERROR cargando sub-VI " mold subvi-node/file ": " mold result]
            ]
        ]
    ]

    code: compile-body diagram
    ; try puede devolver unset! si el código termina con print — añadimos none
    result: try [do code  none]
    if error? result [
        print rejoin ["[runner] ERROR ejecutando body: " mold result]
        print rejoin ["[runner] Código: " mold/only code]
    ]

    qtorres-runtime: false
    true
]

#include %../io/file-io.red
