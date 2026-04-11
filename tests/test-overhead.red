Red [
    Title: "Test overhead — logging visible"
    Needs: 'View
]

_spec-size:     600x400
_csd-overhead:  0x0           ; overhead completo (shadows + header) — medido al init
_overhead:      0x0           ; overhead efectivo actual (depende del modo)
_last-size:     0x0
_csd-mode?:     true          ; true = face/size incluye shadows CSD; false = sin shadows
_event-log:     copy []
_tick:          0
_log-file:      %/tmp/test-overhead.log

; Resetear fichero de log al arrancar
write _log-file ""

canvas: make face! [
    type:   'base
    size:   580x380
    offset: 5x5
    color:  240.240.245
    draw:   []
]

; Hijo focusable "sumidero" — evita crash de Red/View al pulsar Tab.
; Tiene que ser visible? true para que GTK lo realice (realized widget),
; pero lo colocamos fuera de la ventana para que el usuario no lo vea.
tab-sink: make face! [
    type:   'field
    size:   1x1
    offset: -100x-100
]

log-event: func [label win-size /local entry] [
    _tick: _tick + 1
    entry: rejoin ["#" _tick " " label " win:" win-size]
    ; head insert — insert avanza la posición, hay que volver al head
    _event-log: head insert _event-log entry
    if (length? _event-log) > 12 [
        _event-log: copy/part _event-log 12
    ]
    ; Escribir al fichero para poder copiarlo después
    write/append _log-file rejoin [entry newline]
]

detect-csd-flip: func [new-size /local dx dy] [
    if _last-size = 0x0 [_last-size: new-size  exit]
    dx: new-size/x - _last-size/x
    dy: new-size/y - _last-size/y
    ; Flip CSD→cliente: salto negativo de ~80..150 px en AMBOS ejes simultáneos.
    ; GTK quita las shadows del frame pero la header bar sigue dentro.
    ; El overhead en modo cliente = _csd-overhead - |delta|
    if all [
        _csd-mode?
        dx <= -80  dx >= -150
        dy <= -80  dy >= -150
    ] [
        _csd-mode?: false
        _overhead:  as-pair (_csd-overhead/x + dx) (_csd-overhead/y + dy)
        log-event "FLIP→client ov:" _overhead
    ]
    ; Flip cliente→CSD: salto positivo de ~80..150 px en ambos ejes.
    ; Volvemos al overhead original medido al init.
    if all [
        not _csd-mode?
        dx >= 80  dx <= 150
        dy >= 80  dy <= 150
    ] [
        _csd-mode?: true
        _overhead:  _csd-overhead
        log-event "FLIP→CSD ov:" _overhead
    ]
    _last-size: new-size
]

render-canvas: func [win /local cw ch _n] [
    cw: win/size/x - _overhead/x - 10
    ch: win/size/y - _overhead/y - 10
    if cw < 50 [cw: 50]
    if ch < 50 [ch: 50]
    canvas/size: as-pair cw ch
    canvas/draw: compose [
        ; Marco rojo al borde real del canvas
        pen red line-width 3
        fill-pen off
        box 1x1 (canvas/size - 2x2)
        ; Cabecera
        pen black
        text 10x8  (rejoin ["canvas/size: " canvas/size])
        text 10x26 (rejoin ["win/size:    " win/size])
        text 10x44 (rejoin ["overhead:    " _overhead " csd?: " _csd-mode?])
        text 10x62 (rejoin ["ticks:       " _tick])
        ; Separador
        pen gray
        line 10x82 (as-pair (cw - 10) 82)
        pen blue
        text 10x88 "-- EVENT LOG (más reciente arriba) --"
    ]
    _n: 0
    foreach entry _event-log [
        append canvas/draw compose [
            pen black
            text (as-pair 10 (108 + (_n * 16))) (entry)
        ]
        _n: _n + 1
    ]
]

win: make face! [
    type:   'window
    text:   "Test overhead — LOGGING"
    size:   _spec-size
    offset: 100x100
    flags:  [resize]
    color:  white
    pane:   reduce [tab-sink canvas]
    rate:   0:0:0.2          ; timer inicial para primer render dentro del loop
    actors: make object! [
        on-resize: func [face event] [
            log-event "on-resize" face/size
            detect-csd-flip face/size
            face/rate: 0:0:0.05
        ]
        on-time: func [face event] [
            face/rate: none
            log-event "on-time" face/size
            if _csd-overhead = 0x0 [
                _csd-overhead: face/size - _spec-size
                _overhead:     _csd-overhead
                _last-size:    face/size
                log-event "INIT csd-ov" _csd-overhead
            ]
            detect-csd-flip face/size
            render-canvas face
            show face
        ]
        on-focus: func [face event] [
            log-event "on-focus" face/size
            face/rate: 0:0:0.05
        ]
        on-unfocus: func [face event] [
            log-event "on-unfocus" face/size
        ]
        on-create: func [face event] [
            ; Forzar que tab-sink reciba foco inicial — evita que el foco
            ; esté en la window (cuyo parent es none y peta al navegar con Tab).
            set-focus tab-sink
        ]
        on-key: func [face event] [
            print ["[on-key] key:" mold event/key "flags:" mold event/flags]
            ; Consumir Tab — Red/View crashea navegando foco en base faces
            if event/key = #"^-" [return 'done]
            if event/key = 'tab  [return 'done]
        ]
        on-key-up: func [face event] [
            print ["[on-key-up] key:" mold event/key]
        ]
    ]
]

view win
