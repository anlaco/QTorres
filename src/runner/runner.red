Red [
    Title:   "QTorres — Runner"
    Purpose: "Ejecuta un .qvi en memoria desde QTorres"
]

; === Runner ===
; 1. Define qtorres-runtime: true (para que sub-VIs no se auto-ejecuten)
; 2. Compila el diagrama actual a código Red en memoria
; 3. Ejecuta con do
; 4. Captura la salida y la escribe en los indicadores del Front Panel
;
; Por implementar:
;   run-diagram: función diagram → resultados
