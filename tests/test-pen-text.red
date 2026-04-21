Red [
    Title:   "Telekino — Test exhaustivo: pen colorea texto en Draw"
    Purpose: {
        Sabemos que pen controla el color del texto en Draw dialect.
        Este test intenta romperlo con todos los casos extremos relevantes
        para panel.red y canvas.red.
    }
    Needs: 'View
]

; ── helpers ──────────────────────────────────────────────────────────

hf: make font! [size: 9]   ; font para cabeceras (sin color — heredará pen)

; Caja de fondo neutro
bg: func [x y w h] [
    compose [
        pen 100.100.100  line-width 1  fill-pen 240.240.240
        box (as-pair x y) (as-pair (x + w) (y + h))
        fill-pen off
    ]
]

; Título de sección
title: func [x y txt] [
    compose [pen 20.20.20  fill-pen off  font (hf)  text (as-pair x y) (txt)]
]

; Separador visual
sep: func [x y w] [
    compose [pen 160.160.160  line-width 1  line (as-pair x y) (as-pair (x + w) y)]
]

d: copy []

; ════════════════════════════════════════════════════════════════════
; BLOQUE 1 — pen básico: ¿cada color aparece distinto?
; ════════════════════════════════════════════════════════════════════
append d title 10 8 "1) pen basico — 6 colores distintos"

colors: [220.0.0 "Rojo" 0.180.0 "Verde" 0.0.220 "Azul" 230.120.0 "Naranja" 150.0.200 "Morado" 0.180.180 "Cyan"]
x: 10
foreach [col lbl] colors [
    append d bg x 22 70 22
    append d compose [pen (col)  fill-pen off  text (as-pair (x + 4) 29) (lbl)]
    x: x + 76
]

; ════════════════════════════════════════════════════════════════════
; BLOQUE 2 — bleed: ¿pen persiste al siguiente text sin reset?
; ════════════════════════════════════════════════════════════════════
append d sep 10 52 580
append d title 10 56 "2) Bleed: tras pen naranja, texto siguiente sin reset — ¿naranja o negro?"

append d bg 10 70 120 22
append d bg 140 70 120 22
append d bg 270 70 120 22
append d compose [
    pen 230.120.0
    text 14x77 "Item 1 — NARANJA"
    text 144x77 "Item 2 — sin reset"
    pen 0.0.0
    text 274x77 "Item 3 — pen 0.0.0"
]

; ════════════════════════════════════════════════════════════════════
; BLOQUE 3 — pen off: ¿qué color tiene el texto con pen off?
; ════════════════════════════════════════════════════════════════════
append d sep 10 100 580
append d title 10 104 "3) pen off antes de text — ¿invisible, negro, gris?"

append d bg 10 118 180 22
append d compose [pen 220.0.0  text 14x125 "Antes: pen rojo"]
append d bg 200 118 180 22
append d compose [pen off  text 204x125 "Despues: pen off — ¿que color?"]

; ════════════════════════════════════════════════════════════════════
; BLOQUE 4 — fill-pen vs pen: ¿fill-pen puede sobreescribir pen para texto?
; ════════════════════════════════════════════════════════════════════
append d sep 10 148 580
append d title 10 152 "4) fill-pen vs pen — ¿cual manda en texto?"

append d bg 10 166 170 22
append d compose [pen 220.0.0  fill-pen 0.0.220  text 14x173 "pen=rojo fill-pen=azul"]
append d bg 190 166 170 22
append d compose [pen 0.0.220  fill-pen 220.0.0  text 194x173 "pen=azul fill-pen=rojo"]
append d bg 370 166 170 22
append d compose [pen off  fill-pen 0.180.0  text 374x173 "pen=off  fill-pen=verde"]

; ════════════════════════════════════════════════════════════════════
; BLOQUE 5 — ¿dibujar formas cambia pen para el texto siguiente?
; ════════════════════════════════════════════════════════════════════
append d sep 10 196 580
append d title 10 200 "5) Dibujar forma con pen azul — ¿texto siguiente hereda azul?"

append d compose [
    pen 0.0.220  line-width 2  fill-pen off
    box 10x214 80x236
]
append d bg 90 214 180 22
append d compose [text 94x221 "Texto sin reset de pen — ¿azul?"]
append d bg 280 214 180 22
append d compose [pen 0.0.0  text 284x221 "Texto con pen 0.0.0 — negro"]

; ════════════════════════════════════════════════════════════════════
; BLOQUE 6 — line-width afecta al texto? (grosor de trazo)
; ════════════════════════════════════════════════════════════════════
append d sep 10 244 580
append d title 10 248 "6) line-width alto — ¿afecta al texto?"

append d bg 10 262 150 22
append d compose [pen 0.0.0  line-width 1  text 14x269 "line-width 1"]
append d bg 170 262 150 22
append d compose [pen 0.0.0  line-width 5  text 174x269 "line-width 5"]
append d bg 330 262 150 22
append d compose [pen 0.0.0  line-width 10  text 334x269 "line-width 10"]

; ════════════════════════════════════════════════════════════════════
; BLOQUE 7 — reset completo tipo panel.red: ¿es suficiente?
; ════════════════════════════════════════════════════════════════════
append d sep 10 292 580
append d title 10 296 "7) Reset tipo panel.red tras contaminacion maxima"

; Contaminamos todo: pen morado, fill-pen naranja, line-width 8
append d compose [
    pen 150.0.200  fill-pen 230.120.0  line-width 8
    box 10x310 200x332
]
append d bg 10 340 560 22
; Reset igual que panel.red
rf: make font! [color: 0.0.0]
append d compose [
    pen 0.0.0  fill-pen off  line-width 1  font (rf)
    text 14x347 "Tras reset panel.red (pen 0.0.0 fill-pen off line-width 1 font negro) — ¿negro limpio?"
]

; ════════════════════════════════════════════════════════════════════
; BLOQUE 8 — texto blanco sobre fondo oscuro con pen
; ════════════════════════════════════════════════════════════════════
append d sep 10 370 580
append d title 10 374 "8) pen blanco sobre fondo oscuro — ¿visible?"

append d compose [
    pen 30.30.30  line-width 1  fill-pen 30.40.60
    box 10x388 280x410
    fill-pen off
    pen 255.255.255
    text 14x395 "pen blanco (255.255.255) sobre fondo oscuro"
]
append d compose [
    pen 30.30.30  line-width 1  fill-pen 30.40.60
    box 290x388 580x410
    fill-pen off
    pen 255.255.0
    text 294x395 "pen amarillo (255.255.0) sobre fondo oscuro"
]

; ── consola ──────────────────────────────────────────────────────────
print "^/=== test-pen-text ==="
print "8 bloques — describe cada resultado para diagnostico completo"
print ""

view/no-wait layout [
    title "test-pen-text — Telekino"
    backdrop 200.203.210
    base 600x425 draw d
    button "Cerrar" [quit]
]
do-events
