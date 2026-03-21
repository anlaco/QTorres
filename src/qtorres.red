Red [
    Title:   "QTorres"
    Author:  "QTorres contributors"
    Version: 0.0.1
    Purpose: "Entorno de programación visual tipo LabVIEW sobre Red-Lang"
    Needs:   'View
]

; ── Módulos — orden de dependencia ───────────────────────────────
; #include embebe el código en compile-time → binario standalone con encap.
; Cada Red[] en un módulo incluido desplaza el contexto de directorio al
; directorio de ese módulo — las rutas siguientes son relativas al último
; módulo incluido, no al CWD. Ver docs/encap-compilation.md.
;
;   ctx src/          → #include %graph/model.red
;   ctx src/graph/    → #include %blocks.red
;   ctx src/graph/    → #include %../compiler/compiler.red
;   ctx src/compiler/ → #include %../runner/runner.red
;   ctx src/runner/   → #include %../io/file-io.red
;   ctx src/io/       → #include %../ui/diagram/canvas.red
;   ctx src/ui/diagram/ → #include %../panel/panel.red
#include %graph/model.red
#include %blocks.red
#include %../compiler/compiler.red
#include %../runner/runner.red
#include %../io/file-io.red
#include %../ui/diagram/canvas.red
#include %../panel/panel.red

; ── Mapa de resultados de ejecución (global, accesible desde do code) ───
_run-results: make map! []

; ── Diálogo de guardado (GTK-008 workaround: request-file/save no funciona) ──
; GTK ignora el flag /save y siempre abre un diálogo "Open".
; Se usa un diálogo VID propio con view/no-wait (patrón GTK-007).
; GTK-008: request-file/save no funciona en Linux — diálogo VID propio.
; view/no-wait retorna antes de que el usuario pulse, así que save-vi-full
; se llama desde dentro del botón del diálogo, no desde el caller.
_save-field: none   ; módulo para que el actor lo vea tras view/no-wait
_save-model: none   ; ídem para el modelo

show-save-dialog: func [model [object!] /local dlg default-name] [
    _save-model: model
    default-name: rejoin [model/name ".qvi"]
    dlg: layout [
        text "Guardar VI como (.qvi):"
        _save-field: field 360 default-name
        across
        button "Guardar" [
            save-vi-full to-file _save-field/text _save-model
            unview
        ]
        button "Cancelar" [unview]
    ]
    view/no-wait dlg
]

; ── Modelo unificado BD + FP ─────────────────────────────────────
app-model: make-diagram-model
app-model: make app-model [
    name:       "untitled"
    size:       380x490
    canvas-ref: none        ; face del BD — para refrescar desde panel.red
    panel-ref:  none        ; face del FP — para refrescar desde canvas.red
]

; ── save-vi-full: serializa BD + FP juntos ───────────────────────
save-vi-full: func [path model /local compiled qd] [
    compiled: compile-diagram model
    qd: serialize-diagram model
    append qd save-panel-to-diagram model/front-panel
    write path format-qvi model/name qd compiled
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
        on-down: func [face event /local model n bdef wire src code result-var _pref] [
            model: face/extra

            ; 1. Sincronizar valores de controles FP → config del nodo BD
            foreach n model/nodes [
                bdef: find-block n/type
                if all [bdef  bdef/category = 'input] [
                    foreach item model/front-panel [
                        if item/name = n/name [
                            n/config: reduce ['default item/value]
                        ]
                    ]
                ]
            ]

            ; 2. Compilar código headless
            code: attempt [compile-body model]
            unless block? code [exit]

            ; 3. Añadir capturas de resultados al bloque de código:
            ;    put _run-results "indicator_1" <var-resultado>
            ;    _run-results es global → accesible desde do
            clear _run-results
            foreach n model/nodes [
                bdef: find-block n/type
                if all [bdef  bdef/category = 'output] [
                    foreach wire model/wires [
                        if wire/to-node = n/id [
                            foreach src model/nodes [
                                if src/id = wire/from-node [
                                    result-var: port-var src to-word wire/from-port
                                    append code compose [
                                        put _run-results (n/name) (result-var)
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]

            ; 4. Ejecutar
            attempt [do code]

            ; 5. Leer _run-results → actualizar indicadores FP
            foreach item model/front-panel [
                if item/type = 'indicator [
                    if val: select _run-results item/name [
                        item/value: val
                    ]
                ]
            ]

            ; 6. Refrescar Front Panel
            _pref: select model 'panel-ref
            if _pref [
                _pref/draw: render-fp-panel model model/size/x model/size/y
                show _pref
            ]
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
        on-down: func [face event] [
            ; GTK-008: request-file/save no funciona en Linux (ver docs/GTK_ISSUES.md)
            show-save-dialog face/extra
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
            ; GTK: %.qvi en /filter no muestra archivos — usar %*.* como workaround
            path: request-file/title/filter "Abrir VI (.qvi)..." ["Todos" %*.*]
            if path [
                loaded: attempt [load-vi path]
                if loaded [
                    app-model/nodes:         loaded/nodes
                    app-model/wires:         loaded/wires
                    app-model/name:          loaded/name
                    app-model/front-panel:   loaded/front-panel
                    app-model/selected-node: none
                    app-model/selected-wire: none
                    app-model/selected-fp:   none
                    canvas-face/draw: render-bd app-model
                    show canvas-face
                    panel-face/draw: render-fp-panel app-model panel-face/size/x panel-face/size/y
                    show panel-face
                ]
            ]
        ]
    ]
]

; ── Faces principales ─────────────────────────────────────────────
canvas-face: render-diagram app-model 880 490
canvas-face/offset: 5x38
app-model/canvas-ref: canvas-face

panel-face: render-panel app-model 380 350
panel-face/offset: 5x5
app-model/panel-ref: panel-face

; ── Ventana Front Panel (no-wait — coexiste con BD) ──────────────
view/no-wait make face! [
    type:   'window
    text:   "Front Panel — untitled"
    size:   400x375
    offset: 960x60
    pane:   reduce [panel-face]
]

; ── Ventana Block Diagram (blocking — mantiene el event loop) ────
view make face! [
    type:   'window
    text:   "Block Diagram — untitled"
    size:   900x545
    offset: 60x60
    pane:   reduce [btn-run btn-save btn-load canvas-face]
    actors: make object! [
        on-key: func [face event] [
            if any [
                find [delete backspace] event/key
                find [#"^(7F)" #"^H"] event/key
            ][
                canvas-delete-selected canvas-face
            ]
        ]
    ]
]
