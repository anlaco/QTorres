Red [
    Title: "Test foco tras modal"
    Needs: 'View
]

; Contador para verificar que on-key llega
delete-count: 0

; ── VARIANTE 1: modal ──────────────────────────────────
; Descomentar UNA sola variante a la vez.

; do-rename: func [/local fld] [
;     fld: none
;     view/flags compose [
;         title "Renombrar (modal)"
;         fld: field 200 "nombre"
;         button "OK" [unview]
;     ] [modal]
; ]

; ── VARIANTE 2: no-wait ────────────────────────────────
; do-rename: func [/local fld] [
;    fld: none
;    view/no-wait compose [
;        title "Renombrar (no-wait)"
;        fld: field 200 "nombre"
;        button "OK" [unview]
;    ]
; ]

; ── VARIANTE 3: field inline ───────────────────────────
rename-fld: none
do-rename: func [/local fld] [
   fld: make face! [
       type: 'field
       text: "nombre"
       offset: 20x100
       size: 200x28
   ]
   rename-fld: fld
   fld/actors: make object! [
       on-enter: func [f e] [
           remove find win/pane rename-fld
           show win
       ]
       on-key: func [f e] [
           if e/key = 'escape [
               remove find win/pane rename-fld
               show win
           ]
       ]
   ]
   append win/pane fld
   show win
   set-focus fld
]

; ── Ventana ────────────────────────────────────────────
win: make face! [
    type: 'window
    text: "Test foco: pulsa Delete, luego doble-clic, luego Delete otra vez"
    size: 400x200
    offset: 200x200
    pane: reduce [
        make face! [
            type: 'base
            size: 380x160
            offset: 10x30
            color: 225.228.235
            flags: [all-over]
            draw: [
                pen 50.80.120
                text 20x20 "1) Pulsa Delete -> mira consola"
                text 20x50 "2) Doble clic aqui -> cierra dialog"
                text 20x80 "3) Pulsa Delete otra vez -> mira consola"
                text 20x110 "Si sale DELETE ambas veces = OK"
            ]
            actors: make object! [
                on-dbl-click: func [face event] [
                    do-rename
                ]
            ]
        ]
    ]
    actors: make object! [
        on-key: func [face event] [
            if any [
                find [delete backspace] event/key
                find [#"^(7F)" #"^H"] event/key
            ][
                delete-count: delete-count + 1
                print rejoin ["DELETE #" delete-count " recibido"]
            ]
        ]
    ]
]

view win
