Red [
    Title:   "QTorres — File I/O"
    Purpose: "Guardar y cargar VIs (.qvi), proyectos (.qproj) y otros tipos de fichero QTorres"
]

; ══════════════════════════════════════════════════
; DIALECTO: qvi-file (lectura/escritura de .qvi)
; ══════════════════════════════════════════════════
; Al guardar un .qvi, el File I/O genera:
;   1. Cabecera Red [title: ...]
;   2. qvi-diagram: [...] — usando el dialecto qvi-diagram
;   3. Código Red generado — usando el compilador (dialecto emit)
;
; Al cargar un .qvi:
;   1. load lee el fichero completo como bloque Red
;   2. Se busca la palabra qvi-diagram en el bloque
;   3. Se parsea el bloque con las reglas del dialecto qvi-diagram
;   4. Se reconstruye el modelo en memoria
;
; Tipos de fichero soportados:
;   .qvi    — Virtual Instrument (front panel + block diagram)
;   .qproj  — Proyecto (referencias a ficheros, configuración)
;   .qlib   — Librería (colección de VIs con namespace / context)
;   .qclass — Clase (datos + métodos)
;   .qctl   — Type definition (control personalizado)

; Por implementar:
;   save-vi:      función diagram → escribe fichero .qvi (cabecera + código)
;   load-vi:      función filepath → diagram (parsea qvi-diagram)
;   save-project: función project → escribe fichero .qproj
;   load-project: función filepath → project
