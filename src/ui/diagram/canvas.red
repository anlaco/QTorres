Red [
    Title:   "Telekino — Block Diagram Canvas"
    Purpose: "Canvas modular: render-diagram recibe modelo explícito (Issue #11)"
    Needs:   'View
]

; ══════════════════════════════════════════════════════════
; CONFIG — constantes visuales, sin estado mutable

#include %canvas-render.red


; ══════════════════════════════════════════════════════════
; HIT-TEST — funciones puras, reciben modelo y coordenadas
; ══════════════════════════════════════════════════════════

; Devuelve la estructura que contiene el nodo, o none si es externo.
; Para case-structure, busca en el frame activo.
node-structure: func [model node /local st nd frame] [
    foreach st model/structures [
        ; While/For loop: buscar en st/nodes
        if find [while-loop for-loop] st/type [
            nd: find-node-by-id st/nodes node/id
            if nd [return st]
        ]
        ; Case structure: buscar en frame activo
        if st/type = 'case-structure [
            if all [block? st/frames  st/active-frame < length? st/frames] [
                frame: st/frames/(st/active-frame + 1)
                foreach nd frame/nodes [
                    if nd/id = node/id [return st]
                ]
            ]
        ]
    ]
    none
]

; Devuelve la estructura que contiene el punto, o none.
point-in-structure?: func [model mouse-x mouse-y /local st] [
    foreach st model/structures [
        if all [
            mouse-x >= st/x  mouse-x <= (st/x + st/w)
            mouse-y >= st/y  mouse-y <= (st/y + st/h)
        ] [return st]
    ]
    none
]

; Devuelve [struct node] si el punto cae sobre un nodo interno, o none.
; Para case-structure, busca en el frame activo.
hit-structure-node: func [model mouse-x mouse-y /local st node frame] [
    foreach st model/structures [
        ; Case Structure: buscar en frame activo
        if st/type = 'case-structure [
            if all [block? st/frames  st/active-frame < length? st/frames] [
                frame: st/frames/(st/active-frame + 1)
                foreach node frame/nodes [
                    if all [
                        mouse-x >= node/x  mouse-x <= (node/x + block-width)
                        mouse-y >= node/y  mouse-y <= (node/y + block-height)
                    ] [return reduce [st node]]
                ]
            ]
        ]
        ; While/For Loop: buscar en st/nodes
        if find [while-loop for-loop] st/type [
            foreach node st/nodes [
                if all [
                    mouse-x >= node/x  mouse-x <= (node/x + block-width)
                    mouse-y >= node/y  mouse-y <= (node/y + block-height)
                ] [return reduce [st node]]
            ]
        ]
    ]
    none
]

; Devuelve [struct 'cond|'iter|'count|'selector] si el punto cae sobre un terminal, o none.
; 'iter = terminal iteración [i] abajo-izquierda (while/for)
; 'cond = terminal condición [●] abajo-derecha (while)
; 'count = terminal count [N] arriba-izquierda (for)
; 'selector = terminal selector [?] arriba-izquierda (case)
hit-structure-terminal: func [model mouse-x mouse-y /local st bx by by2 bx2 tx tol nav-h] [
    tol: 8
    nav-h: case-nav-height
    foreach st model/structures [
        bx: st/x  by: st/y  by2: st/y + st/h  bx2: st/x + st/w
        tx: struct-terminal-size
        ; Case Structure: terminal selector arriba-izquierda debajo de la barra de navegación
        if st/type = 'case-structure [
            if all [
                mouse-x >= (bx + 8 - tol)  mouse-x <= (bx + 22 + tol)
                mouse-y >= (by + nav-h + 4 - tol)  mouse-y <= (by + nav-h + 18 + tol)
            ] [return reduce [st 'selector]]
        ]
        ; While/For Loop: terminal iteración [i] abajo-izquierda
        if find [while-loop for-loop] st/type [
            if all [
                mouse-x >= (bx + 8 - tol)  mouse-x <= (bx + 8 + tx + tol)
                mouse-y >= (by2 - tx - 8 - tol)  mouse-y <= (by2 - 8 + tol)
            ] [return reduce [st 'iter]]
        ]
        ; Terminal condición [●]: círculo en (bx2-24, by2-24) radio 8 — solo while-loop
        if st/type = 'while-loop [
            if all [
                (absolute (mouse-x - (bx2 - 24))) <= (8 + tol)
                (absolute (mouse-y - (by2 - 24))) <= (8 + tol)
            ] [return reduce [st 'cond]]
        ]
        ; Terminal count [N]: cuadrado (bx+8, by+8) → (bx+8+tx, by+8+tx) — solo for-loop
        if st/type = 'for-loop [
            if all [
                mouse-x >= (bx + 8 - tol)  mouse-x <= (bx + 8 + tx + tol)
                mouse-y >= (by + 8 - tol)   mouse-y <= (by + 8 + tx + tol)
            ] [return reduce [st 'count]]
        ]
    ]
    none
]

; Devuelve la estructura si el punto cae sobre el handle de resize, o none.
; Handle: esquina inferior-derecha 10x10px
hit-structure-resize: func [model mouse-x mouse-y /local st bx2 by2] [
    foreach st model/structures [
        bx2: st/x + st/w  by2: st/y + st/h
        if all [
            mouse-x >= (bx2 - 16)  mouse-x <= (bx2 + 2)
            mouse-y >= (by2 - 16)  mouse-y <= (by2 + 2)
        ] [return st]
    ]
    none
]

; Devuelve la estructura si el punto cae sobre el borde (~10px de margen), o none.
; El borde excluye esquina resize (ya detectada antes) y terminales.
hit-structure-border: func [model mouse-x mouse-y /local st bx by bx2 by2 bw] [
    bw: 10
    foreach st model/structures [
        bx: st/x  by: st/y  bx2: st/x + st/w  by2: st/y + st/h
        if all [
            mouse-x >= bx  mouse-x <= bx2
            mouse-y >= by  mouse-y <= by2
            any [
                mouse-x <= (bx + bw)
                mouse-x >= (bx2 - bw)
                mouse-y <= (by + bw)
                mouse-y >= (by2 - bw)
            ]
        ] [return st]
    ]
    none
]

; Devuelve [struct sr 'left|'right] si el punto cae sobre un terminal SR, o none.
; ▲ = borde izquierdo (lectura), ▼ = borde derecho (escritura)
hit-structure-sr: func [model mouse-x mouse-y /local st sr cy bx bx2 tol] [
    tol: sr-terminal-half + 4
    foreach st model/structures [
        bx: st/x  bx2: st/x + st/w
        if block? st/shift-regs [
            foreach sr head st/shift-regs [
                cy: to-integer st/y + sr/y-offset
                if all [
                    (absolute (mouse-x - bx)) <= tol
                    (absolute (mouse-y - cy)) <= tol
                ] [return reduce [st sr 'left]]
                if all [
                    (absolute (mouse-x - bx2)) <= tol
                    (absolute (mouse-y - cy)) <= tol
                ] [return reduce [st sr 'right]]
            ]
        ]
    ]
    none
]

; ══════════════════════════════════════════════════════════
; HIT-TEST — Case Structure
; ══════════════════════════════════════════════════════════

; Devuelve [struct 'prev|'next|'add|'remove] si el punto cae sobre botones de navegación.
hit-case-nav-buttons: func [model mouse-x mouse-y /local st bx by bx2 btn-h tol] [
    btn-h: case-btn-size
    tol: 4
    foreach st model/structures [
        if st/type = 'case-structure [
            bx: st/x  by: st/y  bx2: st/x + st/w
            ; Solo verificar si está en la barra de navegación
            if all [mouse-y >= (by + tol)  mouse-y <= (by + case-nav-height - tol)] [
                ; ◀ (prev) en x: bx+8 a bx+26
                if all [mouse-x >= (bx + 8 - tol)  mouse-x <= (bx + 26 + tol)] [
                    return reduce [st 'prev]
                ]
                ; ▶ (next) en x: bx+28 a bx+46
                if all [mouse-x >= (bx + 28 - tol)  mouse-x <= (bx + 46 + tol)] [
                    return reduce [st 'next]
                ]
                ; [+] (add) en x: bx2-48 a bx2-30
                if all [mouse-x >= (bx2 - 48 - tol)  mouse-x <= (bx2 - 30 + tol)] [
                    return reduce [st 'add]
                ]
                ; [-] (remove) en x: bx2-26 a bx2-8
                if all [mouse-x >= (bx2 - 26 - tol)  mouse-x <= (bx2 - 8 + tol)] [
                    return reduce [st 'remove]
                ]
            ]
        ]
    ]
    none
]

; Devuelve [struct 'selector] si el punto cae sobre el terminal selector [?].
hit-case-terminal: func [model mouse-x mouse-y /local st bx by tol nav-h] [
    tol: 8
    nav-h: case-nav-height
    foreach st model/structures [
        if st/type = 'case-structure [
            bx: st/x  by: st/y
            ; Terminal selector: cuadrado en (bx+8, by+nav-h+4) → (bx+22, by+nav_h+18)
            if all [
                mouse-x >= (bx + 8 - tol)  mouse-x <= (bx + 22 + tol)
                mouse-y >= (by + nav-h + 4 - tol)  mouse-y <= (by + nav-h + 18 + tol)
            ] [return reduce [st 'selector]]
        ]
    ]
    none
]

; Devuelve [struct node] si el punto cae sobre un nodo interno del frame activo.
; Para case-structure, solo busca en el frame activo.
hit-case-frame-node: func [model mouse-x mouse-y /local st frame node] [
    foreach st model/structures [
        if st/type = 'case-structure [
            if all [block? st/frames  st/active-frame < length? st/frames] [
                frame: st/frames/(st/active-frame + 1)
                foreach node frame/nodes [
                    if all [
                        mouse-x >= node/x  mouse-x <= (node/x + block-width)
                        mouse-y >= node/y  mouse-y <= (node/y + block-height)
                    ] [return reduce [st node]]
                ]
            ]
        ]
    ]
    none
]

hit-port: func [model mouse-x mouse-y /local ports out-y center-x center-y in-y node port all-nodes st frame] [
    ; Reúne todos los nodos: normales + internos de estructuras (while/for + case frames activos)
    all-nodes: copy model/nodes
    if block? model/structures [
        foreach st model/structures [
            if find [while-loop for-loop] st/type [
                foreach node st/nodes [append all-nodes node]
            ]
            if st/type = 'case-structure [
                if all [block? st/frames  st/active-frame < length? st/frames] [
                    frame: st/frames/(st/active-frame + 1)
                    foreach node frame/nodes [append all-nodes node]
                ]
            ]
        ]
    ]
    foreach node all-nodes [
        ports: out-ports node
        out-y: node/y + 12
        foreach port ports [
            center-x: node/x + block-width + port-radius
            center-y: out-y
            if all [(absolute (mouse-x - center-x)) < 16  (absolute (mouse-y - center-y)) < 16] [
                return reduce [node port 'out]
            ]
            out-y: out-y + 20
        ]
        ports: in-ports node
        in-y: node/y + 12
        foreach port ports [
            center-x: node/x - port-radius
            center-y: in-y
            if all [(absolute (mouse-x - center-x)) < 16  (absolute (mouse-y - center-y)) < 16] [
                return reduce [node port 'in]
            ]
            in-y: in-y + 20
        ]
    ]
    none
]

hit-node: func [model mouse-x mouse-y /local found-node node h] [
    found-node: none
    foreach node model/nodes [
        h: node-height node
        if all [
            mouse-x >= node/x  mouse-x <= (node/x + block-width)
            mouse-y >= node/y  mouse-y <= (node/y + h)
        ] [found-node: node]
    ]
    found-node
]

hit-node-label: func [model mouse-x mouse-y /local node lx ly lw lbl-dx lbl-dy] [
    foreach node model/nodes [
        if all [node/label  object? node/label  node/label/visible] [
            lbl-dx: either pair? node/label/offset [node/label/offset/x] [0]
            lbl-dy: either pair? node/label/offset [node/label/offset/y] [0]
            lx: node/x + lbl-dx
            ly: node/y - bd-label-above + lbl-dy
            lw: max 30 (7 * length? any [node/label/text ""])
            if all [
                mouse-x >= (lx - 2)  mouse-x <= (lx + lw + 2)
                mouse-y >= (ly - 2)   mouse-y <= (ly + 14)
            ] [return reduce [node 'label]]
        ]
    ]
    none
]

; Comprueba si el punto (mx my) está sobre algún wire de la lista dada.
hit-wire-in-list: func [wires nodes mouse-x mouse-y /local tolerance src-node dst-node out-xy in-xy mid-x wire node] [
    tolerance: 8
    foreach wire wires [
        src-node: find-node-by-id nodes wire/from-node
        dst-node: find-node-by-id nodes wire/to-node
        if all [src-node dst-node] [
            out-xy: port-xy src-node wire/from-port 'out
            in-xy:  port-xy dst-node wire/to-port   'in
            mid-x:  to-integer (out-xy/x + in-xy/x) / 2
            if all [
                (absolute (mouse-y - out-xy/y)) < tolerance
                mouse-x >= (min out-xy/x mid-x)  mouse-x <= (max out-xy/x mid-x)
            ] [return wire]
            if all [
                (absolute (mouse-x - mid-x)) < tolerance
                mouse-y >= (min out-xy/y in-xy/y)  mouse-y <= (max out-xy/y in-xy/y)
            ] [return wire]
            if all [
                (absolute (mouse-y - in-xy/y)) < tolerance
                mouse-x >= (min mid-x in-xy/x)  mouse-x <= (max mid-x in-xy/x)
            ] [return wire]
        ]
    ]
    none
]

hit-wire: func [model mouse-x mouse-y /local w st frame] [
    ; Wires normales
    w: hit-wire-in-list model/wires model/nodes mouse-x mouse-y
    if w [return w]
    ; Wires internos de estructuras
    if block? model/structures [
        foreach st model/structures [
            ; While/For loop: st/wires
            if find [while-loop for-loop] st/type [
                w: hit-wire-in-list st/wires st/nodes mouse-x mouse-y
                if w [return w]
            ]
            ; Case structure: frame activo
            if all [st/type = 'case-structure  block? st/frames  st/active-frame < length? st/frames] [
                frame: st/frames/(st/active-frame + 1)
                w: hit-wire-in-list frame/wires frame/nodes mouse-x mouse-y
                if w [return w]
            ]
        ]
    ]
    none
]

; ══════════════════════════════════════════════════════════
; CANVAS FACTORY — render-diagram devuelve una face funcional
;   El modelo se almacena en face/extra para que los actores
;   puedan acceder sin depender de variables globales.
; ══════════════════════════════════════════════════════════

; Alterna el valor booleano de un nodo bool-const.
; node/config es un bloque de pares [clave valor ...].

#include %canvas-dialogs.red

canvas-delete-selected: func [canvas /local model node-id node-name node-type st found _pref _sst _ssr _frame] [
    model: canvas/extra

    ; SR seleccionado: borrar de la estructura + limpiar wires asociados
    if model/selected-sr [
        _sst: model/selected-sr/1
        _ssr: model/selected-sr/2
        ; Borrar wires internos que usen este SR (from: -1 o to: -2 con from-port/to-port = sr/name)
        remove-each w _sst/wires [
            any [
                all [w/from-node = -1  w/from-port = to-word _ssr/name]
                all [w/to-node   = -2  w/to-port   = to-word _ssr/name]
            ]
        ]
        ; Borrar wires externos (to-node = st/id  to-port = sr/name, o from-node = st/id from-port = sr/name)
        remove-each w model/wires [
            any [
                all [w/to-node   = _sst/id  w/to-port   = to-word _ssr/name]
                all [w/from-node = _sst/id  w/from-port = to-word _ssr/name]
            ]
        ]
        remove-each sr _sst/shift-regs [same? sr _ssr]
        model/selected-sr:     none
        model/selected-struct: none
        canvas/draw: render-bd model
        exit
    ]

    ; Wire seleccionado: buscar en model/wires y en wires internos
    if model/selected-wire [
        found: find model/wires model/selected-wire
        if found [remove found]
        if block? model/structures [
            foreach st model/structures [
                ; While/For loop: st/wires
                found: find st/wires model/selected-wire
                if found [remove found]
                ; Case structure: st/frames/*/wires
                if all [st/type = 'case-structure  block? st/frames] [
                    foreach _frame st/frames [
                        found: find _frame/wires model/selected-wire
                        if found [remove found]
                    ]
                ]
            ]
        ]
        if model/selected-struct [
            st: model/selected-struct
            if all [st/type = 'case-structure  block? st/frames  st/active-frame < length? st/frames] [
                _frame: st/frames/(st/active-frame + 1)
                found: find _frame/wires model/selected-wire
                if found [remove found]
            ]
        ]
        model/selected-wire: none
        canvas/draw: render-bd model
        exit
    ]

    ; Nodo interno seleccionado (tanto selected-node como selected-struct están activos)
    if model/selected-node [
        if model/selected-struct [
            node-id: model/selected-node/id
            st: model/selected-struct
            ; Case structure: buscar en frame activo
            if all [st/type = 'case-structure  block? st/frames  st/active-frame < length? st/frames] [
                _frame: st/frames/(st/active-frame + 1)
                remove-each wire _frame/wires [any [wire/from-node = node-id  wire/to-node = node-id]]
                remove-each nd _frame/nodes [nd/id = node-id]
            ]
            ; While/For loop: buscar en st/nodes
            if find [while-loop for-loop] st/type [
                remove-each wire st/wires [any [wire/from-node = node-id  wire/to-node = node-id]]
                remove-each nd st/nodes [nd/id = node-id]
            ]
            model/selected-node: none
            model/selected-struct: none   ; limpiar para que el 2º evento key no borre la estructura
            model/drag-node: none
            canvas/draw: render-bd model
            exit
        ]
        ; Nodo externo seleccionado
        node-id:   model/selected-node/id
        node-name: model/selected-node/name
        node-type: model/selected-node/type
        remove-each wire model/wires [any [wire/from-node = node-id  wire/to-node = node-id]]
        remove-each node model/nodes  [node/id = node-id]
        model/selected-node: none
        model/drag-node:     none
        ; Sync FP: borrar item correspondiente si es control/indicator
        _pref: select model 'panel-ref
        if all [
            find [control indicator bool-control bool-indicator str-control str-indicator arr-control arr-indicator cluster-control cluster-indicator waveform-chart waveform-graph] node-type
            _pref
        ][
            remove-each item model/front-panel [item/name = node-name]
            _pref/draw: render-fp-panel model model/size/x model/size/y
            show _pref
        ]
        canvas/draw: render-bd model
        exit
    ]

    ; Estructura completa seleccionada (borde, sin nodo seleccionado)
    if model/selected-struct [
        st: model/selected-struct
        ; Limpiar wire de N si es for-loop
        if st/type = 'for-loop [
            remove-each w model/wires [
                all [w/to-node = st/id  w/to-port = 'count]
            ]
        ]
        ; Limpiar selector-wire si es case-structure
        if st/type = 'case-structure [
            st/selector-wire: none
        ]
        remove-each s model/structures [same? s st]
        model/selected-struct: none
        canvas/draw: render-bd model
    ]
]

; render-diagram model canvas-width canvas-height → face
; Crea una face base con bloques arrastrables, creación de wires,
; hit-testing y renombrado por doble clic.
render-diagram: func [model canvas-width canvas-height /local canvas-face] [
    canvas-face: make face! [
        type:  'base
        size:  as-pair canvas-width canvas-height
        flags: [all-over]
        extra: model                    ; modelo accesible desde actores via face/extra
        actors: make object! [

            on-down: func [face event /local mouse-x mouse-y model hit-result hit-nd hit-port-name hit-dir hit-ref _sx _sy _w _h _b _sb] [
                model: face/extra
                _sx: event/offset/x  _sy: event/offset/y
                _w: face/size/x      _h: face/size/y
                _sb: 8
                ; ── Click en scrollbar (coords de pantalla, antes del translate) ──
                _b: bd-content-bounds model
                if all [_b/y > _h  _sx >= (_w - _sb)  _sy < (_h - _sb)] [
                    ; Scrollbar vertical — calcular nueva posición de scroll
                    model/scroll-y: max 0 to-integer (_sy * (_b/y - _h) / (_h - _sb))
                    face/draw: render-bd model
                    exit
                ]
                if all [_b/x > _w  _sy >= (_h - _sb)  _sx < (_w - _sb)] [
                    ; Scrollbar horizontal
                    model/scroll-x: max 0 to-integer (_sx * (_b/x - _w) / (_w - _sb))
                    face/draw: render-bd model
                    exit
                ]
                ; ── Hit-test normal (coords de contenido, con compensación de scroll) ──
                mouse-x: event/offset/x + model/scroll-x
                mouse-y: event/offset/y + model/scroll-y

                ; 1) Puerto? (incluye nodos internos de estructuras)
                hit-result: hit-port model mouse-x mouse-y
                if hit-result [
                    hit-nd:        hit-result/1
                    hit-port-name: hit-result/2
                    hit-dir:       hit-result/3
                    either model/wire-src = none [
                        if hit-dir = 'out [
                            model/broken-wire: none
                            model/wire-src:  hit-nd
                            model/wire-port: hit-port-name
                            model/mouse-pos: as-pair mouse-x mouse-y
                            face/draw: render-bd model
                        ]
                    ][
                        ; Completar wire — manejo SR-aware
                        do [
                            _hit-ok: false
                            if all [hit-dir = 'in  model/wire-src/id <> hit-nd/id] [
                                _out-t: port-out-type model/wire-src model/wire-port
                                if model/wire-src-sr [_out-t: model/wire-src-sr/data-type]
                                if model/wire-src/id = -3 [_out-t: 'number]
                                _hit-ok: _out-t = port-in-type hit-nd hit-port-name
                            ]
                            either _hit-ok [
                                model/broken-wire: none
                                src-st: any [model/wire-src-struct  node-structure model model/wire-src]
                                dst-st: node-structure model hit-nd
                                ; SR-left (-1): solo conecta a nodo INTERNO de la misma estructura
                                _sr-ok: true
                                if model/wire-src/id = -1 [
                                    if not all [dst-st  same? dst-st src-st] [_sr-ok: false]
                                ]
                                ; SR-right (-2): solo conecta a nodo EXTERNO
                                if model/wire-src/id = -2 [
                                    if dst-st [_sr-ok: false]
                                ]
                                if _sr-ok [
                                    wire-list: either all [src-st  dst-st  same? src-st dst-st] [
                                        src-st/wires
                                    ] [
                                        model/wires
                                    ]
                                    actual-from-node: model/wire-src/id
                                    actual-from-port: model/wire-port
                                    ; Iter (-3): from-port = nombre var iter
                                    if model/wire-src/id = -3 [
                                        actual-from-port: to-word rejoin ["_" model/wire-src-struct/name "_i"]
                                    ]
                                    ; SR (-1 o -2): from-port = sr/name; SR-right usa struct ID como from-node
                                    if model/wire-src-sr [
                                        actual-from-port: to-word model/wire-src-sr/name
                                        if model/wire-src/id = -2 [
                                            actual-from-node: model/wire-src-struct/id
                                        ]
                                    ]
                                    ; QA-018: no permitir 2 wires al mismo puerto de entrada
                                    if wire-port-in-used? wire-list hit-nd/id hit-port-name [
                                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none
                                        model/wire-src-struct: none  model/wire-src-sr: none
                                        face/draw: render-bd model
                                        exit
                                    ]
                                    append wire-list make-wire compose [
                                        from: (actual-from-node)
                                        from-port: (actual-from-port)
                                        to: (hit-nd/id)
                                        to-port: (hit-port-name)
                                    ]
                                ]
                            ][
                                ; Tipos incompatibles: wire roto rojo
                                if all [hit-dir = 'in  model/wire-src/id <> hit-nd/id] [
                                    _bw-src: either model/wire-src-sr [
                                        either model/wire-src/id = -1 [
                                            sr-xy model/wire-src-struct model/wire-src-sr 'left
                                        ][
                                            sr-xy model/wire-src-struct model/wire-src-sr 'right
                                        ]
                                    ][
                                        port-xy model/wire-src model/wire-port 'out
                                    ]
                                    model/broken-wire: reduce [_bw-src  port-xy hit-nd hit-port-name 'in]
                                ]
                            ]
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none
                        model/wire-src-struct: none  model/wire-src-sr: none
                        face/draw: render-bd model
                    ]
                    return none
                ]

                ; 2) Nodo interno de estructura? (antes que borde/nodo normal)
                hit-result: hit-structure-node model mouse-x mouse-y
                if hit-result [
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                    model/broken-wire: none
                    model/selected-wire: none
                    model/selected-sr: none
                    model/selected-struct: hit-result/1
                    model/selected-node: hit-result/2
                    model/drag-node: hit-result/2
                    model/drag-off: as-pair (mouse-x - hit-result/2/x) (mouse-y - hit-result/2/y)
                    if hit-result/2/type = 'bool-const [toggle-bool-const hit-result/2]
                    face/draw: render-bd model
                    return none
                ]

                ; 2.5) Terminal SR (▲ izquierdo o ▼ derecho)?
                hit-result: hit-structure-sr model mouse-x mouse-y
                if hit-result [
                    do [
                        _st:   hit-result/1
                        _sr:   hit-result/2
                        _side: hit-result/3
                        either model/wire-src [
                            ; Hay wire activo — intentar completar conexión en SR terminal
                            _completed: false
                            if _side = 'left [
                                ; External → SR-left: wire-src debe ser nodo EXTERNO
                                if all [model/wire-src/id > 0  none? node-structure model model/wire-src] [
                                    _out-t: port-out-type model/wire-src model/wire-port
                                    either _out-t = _sr/data-type [
                                        model/broken-wire: none
                                        ; QA-018: Prevent multiple wires to same input port
                                        if wire-port-in-used? model/wires _st/id (to-word _sr/name) [exit]
                                        append model/wires make-wire compose [
                                            from: (model/wire-src/id)  from-port: (model/wire-port)
                                            to: (_st/id)  to-port: (to-word _sr/name)
                                        ]
                                    ][
                                        model/broken-wire: reduce [
                                            port-xy model/wire-src model/wire-port 'out
                                            sr-xy _st _sr 'left
                                        ]
                                    ]
                                    _completed: true
                                ]
                            ]
                            if _side = 'right [
                                ; Internal → SR-right: wire-src debe ser nodo INTERNO de esta estructura
                                _src-st: node-structure model model/wire-src
                                if all [_src-st  same? _src-st _st] [
                                    _out-t: port-out-type model/wire-src model/wire-port
                                    either _out-t = _sr/data-type [
                                        model/broken-wire: none
                                        ; QA-018: Prevent multiple wires to same input port
                                        if wire-port-in-used? _st/wires -2 (to-word _sr/name) [exit]
                                        append _st/wires make-wire compose [
                                            from: (model/wire-src/id)  from-port: (model/wire-port)
                                            to: -2  to-port: (to-word _sr/name)
                                        ]
                                    ][
                                        model/broken-wire: reduce [
                                            port-xy model/wire-src model/wire-port 'out
                                            sr-xy _st _sr 'right
                                        ]
                                    ]
                                    _completed: true
                                ]
                            ]
                            model/wire-src: none  model/wire-port: none
                            model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                            face/draw: render-bd model
                            return none
                        ][
                            ; Sin wire activo: seleccionar SR e iniciar wire
                            model/selected-sr:     reduce [_st _sr]
                            model/selected-struct: none
                            model/selected-node:   none
                            model/selected-wire:   none
                            model/broken-wire:     none
                            _sr-nd: make object! [
                                id: either _side = 'left [-1] [-2]
                                type: either _side = 'left ['sr-left] ['sr-right]
                                name: to-word _sr/name
                                ports: []  config: []  label: none  x: 0  y: 0
                            ]
                            model/wire-src:        _sr-nd
                            model/wire-port:       to-word _sr/name
                            model/wire-src-struct: _st
                            model/wire-src-sr:     _sr
                            model/mouse-pos:       event/offset
                            face/draw: render-bd model
                            return none
                        ]
                    ]
                ]

                ; 3) Botones de navegación de Case Structure (◀ ▶ [+][-])?
                hit-result: hit-case-nav-buttons model mouse-x mouse-y
                if hit-result [
                    _cst: hit-result/1
                    _act: hit-result/2
                    switch _act [
                        prev [
                            if all [_cst/frames  _cst/active-frame > 0] [
                                _cst/active-frame: _cst/active-frame - 1
                            ]
                        ]
                        next [
                            if all [_cst/frames  _cst/active-frame < ((length? _cst/frames) - 1)] [
                                _cst/active-frame: _cst/active-frame + 1
                            ]
                        ]
                        add [
                            append _cst/frames make-frame compose [
                                id: (length? _cst/frames)
                                label: (form length? _cst/frames)
                            ]
                            _cst/active-frame: (length? _cst/frames) - 1
                        ]
                        remove [
                            if all [_cst/frames  (length? _cst/frames) > 1] [
                                remove at _cst/frames (_cst/active-frame + 1)
                                if _cst/active-frame >= length? _cst/frames [
                                    _cst/active-frame: (length? _cst/frames) - 1
                                ]
                            ]
                        ]
                    ]
                    model/selected-struct: _cst
                    model/selected-node: none
                    model/selected-wire: none
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none
                    face/draw: render-bd model
                    return none
                ]

                ; 3.5) Terminal selector de Case Structure?
                hit-result: hit-case-terminal model mouse-x mouse-y
                if hit-result [
                    _cst: hit-result/1
                    either model/wire-src [
                        ; Completar wire al selector
                        do [
                            _sel-ok: false
                            _out-t: either model/wire-src-sr [model/wire-src-sr/data-type] [
                                either model/wire-src/id = -3 ['number] [
                                    port-out-type model/wire-src model/wire-port
                                ]
                            ]
                            ; Selector acepta number o boolean
                            if find [number boolean] _out-t [_sel-ok: true]
                            either _sel-ok [
                                _cst/selector-wire: make object! [
                                    from: model/wire-src/id
                                    port: model/wire-port
                                ]
                                model/broken-wire: none
                            ][
                                _nav-h: case-nav-height
                                _sel-xy: as-pair (_cst/x + 15) (_cst/y + _nav-h + 11)
                                model/broken-wire: reduce [port-xy model/wire-src model/wire-port 'out  _sel-xy]
                            ]
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none
                        model/wire-src-struct: none  model/wire-src-sr: none
                    ][
                        ; Sin wire activo: seleccionar estructura
                        model/selected-struct: _cst
                        model/selected-node: none
                        model/selected-wire: none
                    ]
                    face/draw: render-bd model
                    return none
                ]

                ; 4) Handle de resize de estructura? — antes que terminal para evitar conflicto
                ;    con el círculo condición del while-loop en la esquina inferior-derecha
                hit-result: hit-structure-resize model mouse-x mouse-y
                if hit-result [
                    model/selected-struct: hit-result
                    model/resize-struct: hit-result
                    model/selected-node: none
                    model/selected-wire: none
                    face/draw: render-bd model
                    return none
                ]

                ; 5) Terminal de estructura (condición/iteración)?
                hit-result: hit-structure-terminal model mouse-x mouse-y
                if hit-result [
                    ; Terminal [i]: si no hay wire activo, iniciar wire desde iteración
                    if all [hit-result/2 = 'iter  none? model/wire-src] [
                        do [
                            _st: hit-result/1
                            iter-nd: make object! [
                                id: -3  type: 'iter  name: _st/name
                                ports: []  config: []  label: none  x: 0  y: 0
                            ]
                            model/wire-src:        iter-nd
                            model/wire-port:       'i
                            model/wire-src-struct: _st
                            model/mouse-pos:       event/offset
                        ]
                        face/draw: render-bd model
                        return none
                    ]

                    ; Si hay wire-src activo + terminal condición → conectar (while-loop)
                    if all [model/wire-src  hit-result/2 = 'cond] [
                        either (port-out-type model/wire-src model/wire-port) = 'boolean [
                            ; Guardar cond-wire en la estructura
                            hit-result/1/cond-wire: make object! [
                                from: model/wire-src/id
                                port: model/wire-port
                            ]
                            model/broken-wire: none
                        ][
                            ; Tipo incompatible: mostrar error
                            model/broken-wire: reduce [
                                port-xy model/wire-src model/wire-port 'out
                                as-pair (hit-result/1/x + hit-result/1/w - 16)
                                        (hit-result/1/y + hit-result/1/h - 16)
                            ]
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                        face/draw: render-bd model
                        return none
                    ]
                    ; Si hay wire-src activo + terminal [N] → conectar (for-loop, externo)
                    if all [model/wire-src  hit-result/2 = 'count] [
                        do [
                            _fst: hit-result/1
                            _htx: to-integer (struct-terminal-size / 2)
                            _ndst: as-pair (to-integer _fst/x + 8 + _htx)
                                           (to-integer _fst/y + 8 + _htx)
                            either (port-out-type model/wire-src model/wire-port) = 'number [
                                ; Eliminar wire previo de N si existía
                                remove-each _w model/wires [
                                    all [_w/to-node = _fst/id  _w/to-port = 'count]
                                ]
                                append model/wires make-wire compose [
                                    from: (model/wire-src/id)  from-port: (model/wire-port)
                                    to: (_fst/id)  to-port: "count"
                                ]
                                model/broken-wire: none
                            ][
                                model/broken-wire: reduce [
                                    port-xy model/wire-src model/wire-port 'out
                                    _ndst
                                ]
                            ]
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                        face/draw: render-bd model
                        return none
                    ]
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                    model/broken-wire: none
                    model/selected-struct: hit-result/1
                    model/selected-node: none
                    model/selected-wire: none
                    face/draw: render-bd model
                    return none
                ]

                ; 5) Borde de estructura (drag)?
                hit-result: hit-structure-border model mouse-x mouse-y
                if hit-result [
                    model/selected-struct: hit-result
                    model/drag-struct: hit-result
                    model/drag-struct-off: as-pair (mouse-x - hit-result/x) (mouse-y - hit-result/y)
                    model/selected-node: none
                    model/selected-wire: none
                    face/draw: render-bd model
                    return none
                ]

                ; 6) Label de nodo? — antes que el body del nodo
                hit-ref: hit-node-label model mouse-x mouse-y
                if hit-ref [
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                    model/broken-wire: none
                    model/selected-wire: none
                    model/selected-struct: none
                    model/selected-sr: none
                    model/selected-node: hit-ref/1
                    model/drag-node: hit-ref/1
                    model/drag-is-label: true
                    lbl-dx: either pair? hit-ref/1/label/offset [hit-ref/1/label/offset/x] [0]
                    lbl-dy: either pair? hit-ref/1/label/offset [hit-ref/1/label/offset/y] [0]
                    model/drag-off: as-pair (mouse-x - hit-ref/1/x - lbl-dx) (mouse-y - hit-ref/1/y + bd-label-above - lbl-dy)
                    face/draw: render-bd model
                    return none
                ]

                ; 7) Nodo normal externo? — antes que interior de estructura
                ;    (fix bug #7: nodo arrastrado dentro del while queda accesible)
                hit-ref: hit-node model mouse-x mouse-y
                if hit-ref [
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                    model/wire-src-struct: none
                    model/broken-wire: none
                    model/selected-wire: none
                    model/selected-struct: none
                    model/selected-sr: none
                    model/selected-node: hit-ref
                    model/drag-node: hit-ref
                    model/drag-off: as-pair (mouse-x - hit-ref/x) (mouse-y - hit-ref/y)
                    ; bool-const: clic alterna T/F (igual que LabVIEW)
                    if hit-ref/type = 'bool-const [toggle-bool-const hit-ref]
                    face/draw: render-bd model
                    return none
                ]

                ; 8) Interior de estructura (fondo → seleccionar estructura, paleta interna futura)?
                hit-result: point-in-structure? model mouse-x mouse-y
                if hit-result [
                    model/selected-struct: hit-result
                    model/selected-node: none
                    model/selected-wire: none
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                    model/wire-src-struct: none
                    face/draw: render-bd model
                    return none
                ]

                ; 9) Wire normal?
                hit-ref: hit-wire model mouse-x mouse-y
                if hit-ref [
                    model/selected-wire: hit-ref
                    model/selected-node: none
                    model/selected-struct: none
                    model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                    face/draw: render-bd model
                    return none
                ]

                ; 10) Clic en vacío: cancelar todo
                model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                model/broken-wire: none
                model/drag-node: none  model/selected-wire: none
                model/selected-node: none  model/selected-struct: none
                face/draw: render-bd model
            ]

            on-over: func [face event /local mouse-x mouse-y model dx dy _st _frame _nodes] [
                model: face/extra
                mouse-x: event/offset/x + model/scroll-x
                mouse-y: event/offset/y + model/scroll-y

                ; Drag de nodo (normal o interno) o de label
                if all [model/drag-node model/drag-off event/down?] [
                    either model/drag-is-label [
                        model/drag-node/label/offset: as-pair
                            (mouse-x - model/drag-off/x - model/drag-node/x)
                            (mouse-y - model/drag-off/y - model/drag-node/y + bd-label-above)
                    ][
                        model/drag-node/x: mouse-x - model/drag-off/x
                        model/drag-node/y: mouse-y - model/drag-off/y
                        ; Clamp nodo interno dentro de la estructura (margen 20px)
                        if model/selected-struct [
                            _st: model/selected-struct
                            ; Case Structure: clamp Considerar nav-height para Y
                            _nav-h: either _st/type = 'case-structure [case-nav-height + 4] [22]
                            model/drag-node/x: max (_st/x + 20)
                                               min (_st/x + _st/w - block-width - 20)
                                                   model/drag-node/x
                            model/drag-node/y: max (_st/y + _nav-h)
                                               min (_st/y + _st/h - block-height - 20)
                                                   model/drag-node/y
                        ]
                    ]
                    face/draw: render-bd model
                    return none
                ]

                ; Resize de estructura
                if all [model/resize-struct event/down?] [
                    model/resize-struct/w: max 120 (mouse-x - model/resize-struct/x)
                    model/resize-struct/h: max 80  (mouse-y - model/resize-struct/y)
                    face/draw: render-bd model
                    return none
                ]

                ; Drag de estructura (borde): mover estructura + nodos internos
                if all [model/drag-struct model/drag-struct-off event/down?] [
                    dx: mouse-x - model/drag-struct-off/x - model/drag-struct/x
                    dy: mouse-y - model/drag-struct-off/y - model/drag-struct/y
                    model/drag-struct/x: model/drag-struct/x + dx
                    model/drag-struct/y: model/drag-struct/y + dy
                    ; Mover nodos de todos los frames (case) o nodos internos (while/for)
                    either model/drag-struct/type = 'case-structure [
                        if block? model/drag-struct/frames [
                            foreach _frame model/drag-struct/frames [
                                foreach nd _frame/nodes [
                                    nd/x: nd/x + dx
                                    nd/y: nd/y + dy
                                ]
                                foreach w _frame/wires [
                                    ; Wires internos no necesitan moverse (coords son absolutas en memoria)
                                ]
                            ]
                        ]
                    ][
                        ; While/For Loop
                        foreach nd model/drag-struct/nodes [
                            nd/x: nd/x + dx
                            nd/y: nd/y + dy
                        ]
                    ]
                    face/draw: render-bd model
                    return none
                ]

                if model/wire-src [
                    model/mouse-pos: as-pair mouse-x mouse-y
                    face/draw: render-bd model
                ]
            ]

            on-up: func [face event /local model hit-result] [
                model: face/extra
                ; Completar wire si se suelta sobre un puerto de entrada (drag-to-connect)
                if model/wire-src [
                    hit-result: hit-port model (event/offset/x + model/scroll-x) (event/offset/y + model/scroll-y)
                    if all [
                        hit-result
                        hit-result/3 = 'in
                        model/wire-src/id <> hit-result/1/id
                    ][
                        ; 3.6 Rutar wire: interno (misma estructura) vs normal
                        do [
                            src-st: any [
                                model/wire-src-struct
                                node-structure model model/wire-src
                            ]
                            dst-st: node-structure model hit-result/1
                            wire-list: either all [src-st  dst-st  same? src-st dst-st] [
                                src-st/wires
                            ] [
                                model/wires
                            ]
                            actual-from-node: model/wire-src/id
                            actual-from-port: model/wire-port
                            if model/wire-src/id = -3 [
                                actual-from-port: to-word rejoin ["_" model/wire-src-struct/name "_i"]
                            ]
                            if model/wire-src-sr [
                                actual-from-port: to-word model/wire-src-sr/name
                                if model/wire-src/id = -2 [
                                    actual-from-node: model/wire-src-struct/id
                                ]
                            ]
                            ; QA-018: Prevent multiple wires to same input port
                            if wire-port-in-used? wire-list hit-result/1/id hit-result/2 [exit]
                            append wire-list make-wire compose [
                                from: (actual-from-node)
                                from-port: (actual-from-port)
                                to: (hit-result/1/id)
                                to-port: (hit-result/2)
                            ]
                        ]
                        model/wire-src: none  model/wire-port: none  model/mouse-pos: none  model/wire-src-struct: none  model/wire-src-sr: none
                        face/draw: render-bd model
                    ]
                ]
                model/drag-node: none
                model/drag-off:  none
                model/drag-struct: none
                model/drag-struct-off: none
                model/resize-struct: none
                model/drag-is-label: false
            ]

            on-key: func [face event /local model] [
                model: face/extra
                if any [
                    find [delete backspace] event/key
                    find [#"^(7F)" #"^H"] event/key
                ][
                    canvas-delete-selected face
                ]
            ]

            on-wheel: func [face event /local model step bounds max-sx max-sy] [
                model: face/extra
                step: to-integer event/picked * -40
                bounds: bd-content-bounds model
                max-sx: max 0 (bounds/x - face/size/x)
                max-sy: max 0 (bounds/y - face/size/y)
                either event/shift? [
                    model/scroll-x: max 0 min max-sx (model/scroll-x + step)
                ][
                    model/scroll-y: max 0 min max-sy (model/scroll-y + step)
                ]
                face/draw: render-bd model
            ]

            on-dbl-click: func [face event /local mouse-x mouse-y model node label-text st-hit struct-hit sr-hit] [
                model: face/extra
                mouse-x: event/offset/x + model/scroll-x
                mouse-y: event/offset/y + model/scroll-y

                ; 0) Terminal SR: editar valor inicial
                sr-hit: hit-structure-sr model mouse-x mouse-y
                if sr-hit [
                    open-sr-edit-dialog face sr-hit/2
                    exit
                ]

                ; Primero: nodo interno de estructura
                st-hit: hit-structure-node model mouse-x mouse-y
                if st-hit [
                    node: st-hit/2
                    if node/type = 'const [open-const-edit-dialog node face  exit]
                    if find [str-const str-control] node/type [open-str-edit-dialog node face  exit]
                    if find [arr-const arr-control] node/type [open-arr-edit-dialog node face  exit]
                    if find [bundle unbundle cluster-control cluster-indicator] node/type [open-cluster-edit-dialog node face  exit]
                    rename-dialog-node:   node
                    rename-dialog-canvas: face
                    rename-dialog-field:  none
                    label-text: either all [node/label  object? node/label] [node/label/text] [
                        either string? node/label [node/label] [""]
                    ]
                    view/no-wait compose [
                        title "Renombrar nodo"
                        text "Label:" return
                        rename-dialog-field: field 200 (label-text)
                        on-enter [
                            apply-rename-label rename-dialog-node rename-dialog-field/text
                            rename-dialog-canvas/draw: render-bd rename-dialog-canvas/extra
                            unview
                        ]
                        return
                        button "OK" [
                            apply-rename-label rename-dialog-node rename-dialog-field/text
                            rename-dialog-canvas/draw: render-bd rename-dialog-canvas/extra
                            unview
                        ]
                        button "Cancelar" [unview]
                    ]
                    exit
                ]

                ; Nodo existente: doble clic → editar valor o renombrar label
                node: hit-node model mouse-x mouse-y
                if node [
                    if node/type = 'const [
                        open-const-edit-dialog node face
                        exit
                    ]
                    if find [str-const str-control] node/type [
                        open-str-edit-dialog node face
                        exit
                    ]
                    if find [arr-const arr-control] node/type [
                        open-arr-edit-dialog node face
                        exit
                    ]
                    if find [bundle unbundle cluster-control cluster-indicator] node/type [
                        open-cluster-edit-dialog node face
                        exit
                    ]
                    rename-dialog-node:   node
                    rename-dialog-canvas: face
                    rename-dialog-field:  none
                    label-text: either all [node/label  object? node/label] [node/label/text] [
                        either string? node/label [node/label] [""]
                    ]
                    view/no-wait compose [
                        title "Renombrar nodo"
                        text "Label:" return
                        rename-dialog-field: field 200 (label-text)
                        on-enter [
                            apply-rename-label rename-dialog-node rename-dialog-field/text
                            rename-dialog-canvas/draw: render-bd rename-dialog-canvas/extra
                            unview
                        ]
                        return
                        button "OK" [
                            apply-rename-label rename-dialog-node rename-dialog-field/text
                            rename-dialog-canvas/draw: render-bd rename-dialog-canvas/extra
                            unview
                        ]
                        button "Cancelar" [unview]
                    ]
                ]
            ]
            on-alt-down: func [face event /local mouse-x mouse-y model struct-hit] [
                model: face/extra
                mouse-x: event/offset/x
                mouse-y: event/offset/y
                struct-hit: point-in-structure? model mouse-x mouse-y
                either struct-hit [
                    open-palette/struct face mouse-x mouse-y struct-hit
                ][
                    open-palette face mouse-x mouse-y
                ]
            ]
        ]
    ]
    canvas-face/color: col-canvas
    canvas-face/draw: render-bd model
    canvas-face
]

; ══════════════════════════════════════════════════════════
; DEMO STANDALONE — ejecutar: red src/ui/diagram/canvas.red
; Stress test: 20 nodos / 15 wires (Issue #4)
; ══════════════════════════════════════════════════════════

if find form system/options/script "canvas.red" [
    demo-model: make-diagram-model

    num-cols:    4
    col-spacing: 210
    row-spacing: 90
    start-x:     40
    start-y:     20

    repeat i 20 [
        col-idx:   (i - 1) % num-cols
        row-idx:   (i - 1) / num-cols
        node-type: either odd? i ['add] ['sub]
        label-text: either node-type = 'add ["Add"] ["Sub"]
        node-id: gen-node-id demo-model
        append demo-model/nodes make object! [
            id:    node-id
            type:  node-type
            name:  rejoin [form node-type "_" node-id]
            label: make object! [
                text:    label-text
                visible: false
                offset:  0x-15
            ]
            x:     start-x + (col-idx * col-spacing)
            y:     start-y + (row-idx * row-spacing)
        ]
    ]

    repeat i 15 [
        append demo-model/wires make-wire compose [
            from: (demo-model/nodes/:i/id)
            from-port: 'result
            to: (demo-model/nodes/(i + 1)/id)
            to-port: 'a
        ]
    ]

    canvas: render-diagram demo-model 880 490
    canvas/offset: 10x38

    view make face! [
        type:   'window
        text:   "Telekino — Canvas modular (Issue #11)"
        size:   900x540
        offset: 80x60
        pane:   reduce [
            make face! [
                type: 'base  offset: 10x8  size: 880x25  color: 200.203.212
                draw: [pen 60.70.90  text 5x15 "Arrastra | clic wire/nodo = seleccionar | doble clic = renombrar | Delete = borrar"]
            ]
            canvas
        ]
        actors: make object! [
            on-key: func [face event] [
                if any [
                    find [delete backspace] event/key
                    find [#"^(7F)" #"^H"] event/key
                ][
                    canvas-delete-selected canvas
                ]
            ]
        ]
    ]
]

#include %../panel/panel.red
