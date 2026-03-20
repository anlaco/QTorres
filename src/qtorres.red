Red [
    Title:   "QTorres"
    Author:  "QTorres contributors"
    Version: 0.0.1
    Purpose: "Entorno de programación visual tipo LabVIEW sobre Red-Lang"
    Needs:   'View
]

; ── Módulos — orden de dependencia ───────────────────────────────
; clean-path resuelve el directorio del script a ruta absoluta,
; evitando la doble-concatenación cuando system/options/script
; devuelve una ruta relativa y change-dir ya está en src/.
; Red CLI cambia el CWD al directorio del script antes de ejecutarlo,
; por lo que what-dir es siempre el directorio de qtorres.red (src/).
_base: what-dir

do append copy _base "graph/model.red"
do append copy _base "graph/blocks.red"
do append copy _base "compiler/compiler.red"
do append copy _base "runner/runner.red"
do append copy _base "io/file-io.red"
do append copy _base "ui/diagram/canvas.red"
do append copy _base "ui/panel/panel.red"

; ── Shim C: registrar control e indicator en el block-registry ───
; compile-diagram falla si encuentra nodos de tipo control/indicator
; sin definición. Se definen aquí tras cargar blocks.red.
block 'control  'input  [
    out result 'number
    config default 'number 0.0
    emit [result: default]
]
block 'indicator 'output [
    in value 'number
    emit [print value]
]

; ── Modelo unificado BD + FP ─────────────────────────────────────
app-model: make-diagram-model
app-model: make app-model [
    name: "untitled"
    size: 380x490
]

; ── save-vi-full: serializa BD + FP juntos ───────────────────────
save-vi-full: func [path model /local compiled qd content] [
    compiled: compile-diagram model
    qd: serialize-diagram model
    append qd save-panel-to-diagram model/front-panel
    content: rejoin [
        "Red [Title: " mold model/name " Needs: 'View]^/^/"
        "qvi-diagram: " mold qd "^/^/"
        "; --- CÓDIGO GENERADO — no editar, se regenera al guardar ---^/"
        "either empty? system/options/args [^/"
        "    view layout " mold compiled/ui-layout "^/"
        "][^/"
        "    " mold/only compiled/headless "^/"
        "]^/"
    ]
    write path content
    path
]

; ── Botones de toolbar ────────────────────────────────────────────
btn-run: make face! [
    type:   'base
    size:   60x24
    offset: 5x3
    color:  55.75.105
    draw:   [fill-pen 240.245.250  text 15x5 "Run"]
    extra:  app-model
    actors: make object! [
        on-down: func [face event /local c] [
            c: attempt [compile-diagram face/extra]
            if c [view/no-wait layout c/ui-layout]
        ]
    ]
]

btn-save: make face! [
    type:   'base
    size:   60x24
    offset: 75x3
    color:  50.100.180
    draw:   [fill-pen 240.245.250  text 12x5 "Save"]
    extra:  app-model
    actors: make object! [
        on-down: func [face event /local path] [
            path: request-file/save/filter ["QTorres VI" %.qvi]
            if path [save-vi-full path face/extra]
        ]
    ]
]

btn-load: make face! [
    type:   'base
    size:   60x24
    offset: 145x3
    color:  50.100.180
    draw:   [fill-pen 240.245.250  text 12x5 "Load"]
    extra:  app-model
    actors: make object! [
        on-down: func [face event /local path loaded] [
            path: request-file/filter ["QTorres VI" %.qvi]
            if path [
                loaded: attempt [load-vi path]
                if loaded [
                    app-model/nodes:         loaded/nodes
                    app-model/wires:         loaded/wires
                    app-model/name:          loaded/name
                    app-model/selected-node: none
                    app-model/selected-wire: none
                    canvas-face/draw: render-bd app-model
                    show canvas-face
                ]
            ]
        ]
    ]
]

; ── Faces principales ─────────────────────────────────────────────
canvas-face: render-diagram app-model 880 490
canvas-face/offset: 10x38

panel-face: render-panel app-model 380 490
panel-face/offset: 900x38

; ── Ventana principal ─────────────────────────────────────────────
view make face! [
    type:   'window
    text:   "QTorres v0.0.1"
    size:   1295x540
    offset: 80x60
    pane:   reduce [btn-run btn-save btn-load canvas-face panel-face]
    actors: make object! [
        on-key: func [face event] [
            if find [delete backspace #"^(7F)" #"^H"] event/key [
                canvas-delete-selected canvas-face
            ]
        ]
    ]
]
