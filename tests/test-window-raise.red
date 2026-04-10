Red [
    Title:   "QTorres — Test window raise cross-platform"
    Purpose: "Verificar si show/view/no-wait eleva una ventana al frente en la plataforma actual"
    Needs:   'View
]

; ── TEST: ¿show face eleva una ventana existente al frente? ──────
;
; INSTRUCCIONES:
;   1. Ejecutar:  red-view tests/test-window-raise.red
;   2. Se abren dos ventanas: A (izquierda) y B (derecha).
;   3. Hacer click en la ventana A para que tenga foco.
;   4. Abrir otra aplicación encima de la ventana B (para que quede tapada).
;   5. Pulsar el botón "Traer B al frente" en A.
;
; RESULTADO ESPERADO:
;   - Si B sube al frente: `show face` funciona para elevar → NO es bug GTK (o ya fue corregido)
;   - Si B NO sube:        `show face` no eleva → anotar plataforma en GTK_ISSUES.md
;
; PLATAFORMAS A VERIFICAR:
;   [ ] Linux/GTK  (comportamiento conocido: NO eleva)
;   [ ] Windows
;   [ ] macOS

win-b: none

win-b: make face! [
    type:   'window
    text:   "Ventana B — debe subir al frente"
    size:   300x200
    offset: 700x200
    pane: reduce [
        make face! [
            type: 'text
            text: "Soy la ventana B. ¿Me ves al frente?"
            size: 280x180
            offset: 10x10
        ]
    ]
]
view/no-wait win-b

view make face! [
    type:   'window
    text:   "Ventana A — control"
    size:   300x200
    offset: 100x200
    pane: reduce [
        make face! [
            type:   'base
            size:   240x40
            offset: 30x80
            color:  50.100.180
            draw:   [fill-pen 240.245.250  text 30x12 "Traer B al frente (show)"]
            actors: make object! [
                on-down: func [face event] [
                    if all [win-b  object? win-b] [
                        show win-b
                    ]
                ]
            ]
        ]
    ]
]
