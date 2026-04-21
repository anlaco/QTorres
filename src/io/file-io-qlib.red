Red [
    Title:   "Telekino — File I/O (gestión de librerías .qlib)"
    Purpose: "load-qlib + find-qlibs — librerías de VIs con namespacing"
]

; ══════════════════════════════════════════════════════════
; QLIB — Librería de VIs con namespacing
; ══════════════════════════════════════════════════════════
;
; Una .qlib es un FICHERO de texto con extension .qlib que actua como
; manifiesto. Los .qvi miembros viven junto a el (misma carpeta o subdir).
;
; Formato del fichero .qlib:
;   qlib [
;       name:        "math"
;       version:     1
;       description: "Operaciones matematicas"
;       members:     [%math/add.qvi  %math/subtract.qvi]
;   ]
;
; Estructura tipica:
;   proyecto/
;     math.qlib          <- manifiesto
;     math/
;       add.qvi
;       subtract.qvi

; Carga un fichero .qlib y devuelve un objeto con:
;   name, version, description, dir, members (bloque de file! absolutos)
; Devuelve none si el fichero no es un .qlib valido.
load-qlib: func [
    "Carga el manifiesto de un fichero .qlib"
    qlib-file [file!]
    /local base-dir raw qd name version desc members-raw members m abs-path
][
    if dir? qlib-file [return none]
    if not exists? qlib-file [return none]
    raw: attempt [load qlib-file]
    if not block? raw [return none]
    if any [empty? raw  raw/1 <> 'qlib] [return none]
    qd: raw/2
    if not block? qd [return none]

    ; Directorio base = directorio que contiene el .qlib
    base-dir: first split-path qlib-file

    name:        any [select qd 'name        ""]
    version:     any [select qd 'version     1]
    desc:        any [select qd 'description ""]
    members-raw: any [select qd 'members     copy []]

    ; Resolver rutas de miembros relativas al directorio del .qlib
    members: copy []
    foreach m members-raw [
        if file? m [
            abs-path: to-file rejoin [form base-dir form m]
            if exists? abs-path [append members abs-path]
        ]
    ]

    make object! compose/only [
        name:        (name)
        version:     (version)
        description: (desc)
        dir:         (base-dir)
        members:     (members)
    ]
]

; Busca ficheros .qlib en el directorio dado.
; Uso: find-qlibs/from system/options/path
; Devuelve bloque de objetos qlib (puede estar vacio).
find-qlibs: func [
    "Busca ficheros .qlib en el directorio dado"
    /from project-dir [file!]
    /local search-dirs libs d qlib-file obj
][
    search-dirs: copy []
    if from [append search-dirs clean-path project-dir]

    libs: copy []
    foreach p search-dirs [
        if all [p  exists? p  dir? p] [
            foreach d read p [
                if all [not dir? d  %.qlib = suffix? d] [
                    qlib-file: to-file rejoin [form p form d]
                    obj: load-qlib qlib-file
                    if obj [append libs obj]
                ]
            ]
        ]
    ]
    libs
]
