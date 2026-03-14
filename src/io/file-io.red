Red [
    Title:   "QTorres — File I/O"
    Purpose: "Guardar y cargar VIs (.qvi), proyectos (.qproj) y otros tipos de fichero QTorres"
]

; === File I/O ===
; Todos los ficheros QTorres son bloques Red nativos.
; Guardar = save, Cargar = load.
;
; Tipos de fichero:
;   .qvi    — Virtual Instrument (front panel + block diagram)
;   .qproj  — Proyecto (referencias a ficheros, configuración)
;   .qlib   — Librería (colección de VIs con namespace)
;   .qclass — Clase (datos + métodos)
;   .qctl   — Type definition (control personalizado)

; Por implementar:
;   save-vi:      función vi, filepath → escribe fichero .qvi
;   load-vi:      función filepath → vi
;   save-project: función project, filepath → escribe fichero .qproj
;   load-project: función filepath → project
