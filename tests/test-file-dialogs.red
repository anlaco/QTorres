Red [
    Title:  "Test: Diálogos de Abrir y Guardar archivo"
    Needs:  'View
]

;-- ═══════════════════════════════════════════════════════════════
;   BUGS GTK EN LINUX:
;   - GTK-008: request-file/save abre diálogo de carpetas (roto)
;   - request-file/filter no muestra archivos en GTK
;   Solución: usar request-file SIN /filter para abrir,
;             y un diálogo VID propio para guardar.
;-- ═══════════════════════════════════════════════════════════════

;-- Variables de módulo para el diálogo de guardar (view/no-wait)
_save-field:  none
_save-editor: none
_save-status: none

view [
    title "Test File Dialogs"
    below

    text bold "Contenido del archivo:"
    editor: area 400x200 ""

    across
    ;-- ══════════════════════════════════════════════
    ;   ABRIR ARCHIVO  (request-file sin filtros — funciona en GTK)
    ;-- ══════════════════════════════════════════════
    button 140 "Abrir archivo..." [
        path: request-file/title/filter "Abrir archivo" ["Texto" %.txt "Red" %.red "Todos" %*.*]
        if path [
            either exists? path [
                editor/text: read path
                status/text: rejoin ["Abierto: " to-string path]
            ][
                status/text: "Error: archivo no encontrado"
            ]
        ]
    ]

    ;-- ══════════════════════════════════════════════
    ;   GUARDAR con diálogo VID propio (workaround GTK-008)
    ;   Usa view/no-wait + variables de módulo (patrón GTK-007)
    ;-- ══════════════════════════════════════════════
    button 140 "Guardar archivo..." [
        _save-editor: editor
        _save-status: status
        view/no-wait [
            title "Guardar archivo como..."
            below
            text "Ruta del archivo:"
            _save-field: field 350 "mi-archivo.txt"
            across
            button "Guardar" [
                path: to-file _save-field/text
                write path _save-editor/text
                _save-status/text: rejoin ["Guardado en: " to-string path]
                unview
            ]
            button "Cancelar" [unview]
        ]
    ]

    return
    status: text 400 "Sin archivo seleccionado"
]
