Red [
    Title:   "QTorres — Test font/fill-pen color bleed en Draw dialect"
    Purpose: {
        Verifica cómo se colorea texto en Draw y si hay bleed entre items.

        SECCIÓN A: font! color  → ¿funciona para colorear texto?
        SECCIÓN B: fill-pen     → ¿funciona para colorear texto? (método de canvas.red)
        SECCIÓN C: pen          → ¿funciona para colorear texto?
        SECCIÓN D: bleed real   → simula render-fp-item: item rojo seguido de items
                                   sin reset, con reset fill-pen off, con reset fill-pen negro
    }
    Needs: 'View
]

colors: [
    [220.0.0    "Rojo"  ]
    [0.180.0    "Verde" ]
    [0.0.220    "Azul"  ]
    [230.120.0  "Naranja"]
    [150.0.200  "Morado"]
    [0.180.180  "Cyan"  ]
]

header-font: make font! [size: 10]

draw-header: func [x y txt] [
    compose [pen off fill-pen 30.30.30  font (header-font)  text (as-pair x y) (txt)]
]

draw-box: func [x y] [
    compose [
        pen 80.80.80  line-width 1  fill-pen 235.235.235
        box (as-pair x y) (as-pair (x + 115) (y + 22))
        pen off  fill-pen off
    ]
]

d: copy []

; ════ SECCIÓN A: font! color ══════════════════════════════════════════
append d draw-header 10 8 "A) font! color"

y: 25
foreach item colors [
    col: item/1  lbl: item/2
    append d draw-box 10 y
    append d compose [
        font (make font! [color: (col) size: 11])
        text (as-pair 15 (y + 5)) (lbl)
    ]
    y: y + 28
]

; ════ SECCIÓN B: fill-pen (método canvas.red) ════════════════════════
append d draw-header 140 8 "B) fill-pen (canvas.red)"

y: 25
foreach item colors [
    col: item/1  lbl: item/2
    append d draw-box 140 y
    append d compose [
        fill-pen (col)
        text (as-pair 145 (y + 5)) (lbl)
    ]
    y: y + 28
]

; ════ SECCIÓN C: pen ══════════════════════════════════════════════════
append d draw-header 270 8 "C) pen"

y: 25
foreach item colors [
    col: item/1  lbl: item/2
    append d draw-box 270 y
    append d compose [
        pen (col)
        text (as-pair 275 (y + 5)) (lbl)
    ]
    y: y + 28
]

; ════ SECCIÓN D: bleed real ═══════════════════════════════════════════
; Simula render-fp-item: item 1 pone fill-pen naranja (como un indicador)
; luego items siguientes con distintos niveles de reset

append d draw-header 400 8 "D) Bleed real — tras fill-pen naranja"

; sub-cabeceras
append d compose [
    fill-pen 30.30.30
    text 400x20 "d1:sin reset"
    text 470x20 "d2:fill-pen off"
    text 545x20 "d3:fill-pen negro"
]

; Item 0 — pone fill-pen naranja (item anterior "contaminante")
append d compose [
    pen 80.80.80  line-width 1  fill-pen 230.120.0
    box 400x36 610x58
    fill-pen 230.120.0
    text 410x42 "Item anterior — fill-pen naranja (230.120.0)"
]

; Fila 1: texto negro esperado
append d draw-box 400 65
append d draw-box 470 65
append d draw-box 545 65

; d1: sin reset — ¿hereda naranja?
append d compose [text 405x71 "Negro?"]

; d2: reset fill-pen off — ¿qué color queda?
append d compose [fill-pen off  text 475x71 "Negro?"]

; d3: reset fill-pen negro explícito
append d compose [fill-pen 0.0.0  text 550x71 "Negro?"]

; Fila 2: segunda fila para ver si persiste
append d draw-box 400 95
append d draw-box 470 95
append d draw-box 545 95

append d compose [text 405x101 "Negro?"]
append d compose [fill-pen off  text 475x101 "Negro?"]
append d compose [fill-pen 0.0.0  text 550x101 "Negro?"]

; ── Consola ───────────────────────────────────────────────────────────
print "^/=== test-font-bleed (completo) ==="
print "A) font! color    -> ¿cada texto en su color?"
print "B) fill-pen       -> ¿cada texto en su color? (método canvas.red)"
print "C) pen            -> ¿cada texto en su color?"
print "D) bleed real     -> tras fill-pen naranja, d1/d2/d3 ¿qué color tienen?"
print ""

; ── Ventana ───────────────────────────────────────────────────────────
view/no-wait layout [
    title "test-font-bleed completo — QTorres"
    backdrop 210.213.220
    base 640x200 draw d
    button "Cerrar" [quit]
]
do-events
