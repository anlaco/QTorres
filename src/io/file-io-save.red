Red [
    Title:   "Telekino — File I/O (guardado de .qvi y Front Panel)"
    Purpose: "save-vi + save-panel-to-diagram"
]

; ══════════════════════════════════════════════════
; SAVE-VI
; ══════════════════════════════════════════════════
;
; Escribe el fichero .qvi completo:
;   1. Cabecera Red con Needs: 'View
;   2. qvi-diagram: [...] — fuente de verdad (DT-011)
;   3. Código generado: modo dual UI/headless (DT-009, DT-012)
;
; Run NO llama a save-vi. Son operaciones independientes (DT-010).

save-vi: func [
    path    [file!]
    diagram [object!]
    /local compiled qd content fp-items
][
    compiled: compile-diagram diagram
    qd: serialize-diagram diagram
    ; Incluir front-panel si está disponible (requiere panel.red cargado)
    fp-items: select diagram 'front-panel
    if all [
        value? 'save-panel-to-diagram
        block? fp-items
        not empty? fp-items
    ][
        append qd save-panel-to-diagram fp-items
    ]
    ; Detectar si es un Sub-VI (tiene connector definido)
    either all [in diagram 'connector  block? diagram/connector  not empty? diagram/connector] [
        content: format-qvi/subvi diagram/name qd compiled
    ][
        content: format-qvi diagram/name qd compiled
    ]
    write path content
    path
]

; ══════════════════════════════════════════════════════════
; SAVE-PANEL-TO-DIAGRAM (movido desde panel.red — 4A refactor)
; ══════════════════════════════════════════════════════════

save-panel-to-diagram: func [front-panel-items /local items item kw spec] [
    items: copy []
    foreach item front-panel-items [
        kw: case [
            item/type = 'control           ['control]
            item/type = 'bool-control      ['bool-control]
            item/type = 'bool-indicator    ['bool-indicator]
            item/type = 'str-control       ['str-control]
            item/type = 'str-indicator     ['str-indicator]
            item/type = 'arr-control       ['arr-control]
            item/type = 'arr-indicator     ['arr-indicator]
            item/type = 'cluster-control   ['cluster-control]
            item/type = 'cluster-indicator ['cluster-indicator]
            item/type = 'waveform-chart    ['waveform-chart]
            item/type = 'waveform-graph    ['waveform-graph]
            true                           ['indicator]
        ]
        spec: copy []
        repend spec [to-set-word 'id  item/id  to-set-word 'type  item/type  to-set-word 'name  item/name]
        append spec to-set-word 'label
        append/only spec compose/deep [text: (item/label/text) visible: (item/label/visible) offset: (item/label/offset)]
        append spec to-set-word 'default
        either block? item/value [append/only spec copy item/value] [append spec item/value]
        if item/data-type = 'cluster [
            append spec to-set-word 'config
            append/only spec copy any [item/config  copy []]
        ]
        repend spec [to-set-word 'offset  item/offset]
        append items kw
        append/only items spec
    ]
    reduce [to-set-word 'front-panel  items]
]
