Red [
    Title: "Test overhead — observador pasivo de GTK CSD"
    Needs: 'View
]

; ── Observador pasivo ─────────────────────────────────────────────
; No intenta detectar flips CSD↔cliente ni corregir overhead.
; Mide el overhead inicial una sola vez y lo usa siempre.
;
; Consecuencia: si GTK pasa a modo cliente (alt+tab, o durante un
; maximize/restore), el canvas queda ~98x108 más pequeño de lo que
; podría, con padding visible en el borde derecho/inferior.
; Aceptable: nunca hay overflow ni estado corrompido.
;
; El log pasivo registra cada cambio de face/size para diagnóstico.

_spec-size:     600x400
_csd-overhead:  0x0           ; medido al primer on-time, luego fijo
_last-size:     0x0           ; solo para log de deltas
_focus-set?:    false
_event-log:     copy []
_tick:          0
_log-file:      %/tmp/test-overhead.log

write _log-file ""

canvas: make face! [
    type:   'base
    size:   580x380
    offset: 5x5
    color:  240.240.245
    draw:   []
]

; Sumidero de foco — tiene que ser un field realizado para poder
; recibir set-focus sin que Red peta al navegar con Tab.
tab-sink: make face! [
    type:   'field
    size:   1x1
    offset: -100x-100
]

log-event: func [label extra /local entry] [
    _tick: _tick + 1
    entry: rejoin ["#" _tick " " label " " extra]
    _event-log: head insert _event-log entry
    if (length? _event-log) > 12 [
        _event-log: copy/part _event-log 12
    ]
    write/append _log-file rejoin [entry newline]
]

log-size: func [label sz /local dx dy delta] [
    delta: ""
    if _last-size <> 0x0 [
        dx: sz/x - _last-size/x
        dy: sz/y - _last-size/y
        if any [dx <> 0  dy <> 0] [
            delta: rejoin [" Δ=" dx "x" dy]
        ]
    ]
    log-event label rejoin ["win:" sz delta]
    _last-size: sz
]

render-canvas: func [win /local cw ch _n] [
    cw: win/size/x - _csd-overhead/x - 10
    ch: win/size/y - _csd-overhead/y - 10
    if cw < 50 [cw: 50]
    if ch < 50 [ch: 50]
    canvas/size: as-pair cw ch
    canvas/draw: compose [
        pen red line-width 3
        fill-pen off
        box 1x1 (canvas/size - 2x2)
        pen black
        text 10x8  (rejoin ["canvas/size: " canvas/size])
        text 10x26 (rejoin ["win/size:    " win/size])
        text 10x44 (rejoin ["csd-overhead:" _csd-overhead " (fijo)"])
        text 10x62 (rejoin ["ticks:       " _tick])
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
    text:   "Test overhead — observer"
    size:   _spec-size
    offset: 100x100
    flags:  [resize]
    color:  white
    pane:   reduce [tab-sink canvas]
    rate:   0:0:0.2          ; timer inicial para forzar primer on-time
    actors: make object! [
        on-resize: func [face event] [
            log-size "on-resize" face/size
            face/rate: 0:0:0.05    ; diferir render hasta que GTK se asiente
        ]
        on-time: func [face event] [
            face/rate: none
            log-size "on-time" face/size
            if _csd-overhead = 0x0 [
                _csd-overhead: face/size - _spec-size
                log-event "INIT" rejoin ["csd-ov=" _csd-overhead]
            ]
            render-canvas face
            ; show canvas explícito: GTK3 no siempre propaga shrink
            ; desde show face a los hijos.
            show canvas
            if not _focus-set? [
                _focus-set?: true
                set-focus tab-sink
                log-event "set-focus" ""
            ]
        ]
        on-focus: func [face event] [
            log-size "on-focus" face/size
        ]
        on-unfocus: func [face event] [
            log-size "on-unfocus" face/size
        ]
        on-key: func [face event] [
            ; Consumir Tab — Red/View crashea navegando foco en base faces (GTK-015)
            if event/key = #"^-" [return 'done]
            if event/key = 'tab  [return 'done]
        ]
    ]
]

view win
