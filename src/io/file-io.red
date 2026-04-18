Red [
    Title:   "QTorres — File I/O (orquestador)"
    Purpose: "Guardar y cargar VIs (.qvi), proyectos (.qproj) y otros tipos de fichero QTorres"
]

; Módulos de I/O (orden importa por dependencias):
;   serialize — serialize-nodes/wires/diagram, format-qvi
;   load      — load-vi, load-node-list, load-wire-list, norm-spec, load-panel-from-diagram
;   save      — save-vi, save-panel-to-diagram (usa serialize + compile-diagram)
;   qlib      — load-qlib, find-qlibs

#include %file-io-serialize.red
#include %file-io-load.red
#include %file-io-save.red
#include %file-io-qlib.red

#include %../ui/diagram/canvas.red
