Red [
    Title:   "QTorres — Modelo del grafo"
    Purpose: "Dialecto qvi-diagram para describir VIs de forma declarativa"
]

; ══════════════════════════════════════════════════
; DIALECTO: qvi-diagram
; ══════════════════════════════════════════════════
; Describe la estructura completa de un VI.
; Se usa como cabecera gráfica del .qvi y como formato de carga.
;
; Sintaxis:
;   front-panel [
;       control   [id: <int>  type: <lit-word>  label: <string>  default: <value>]
;       indicator [id: <int>  type: <lit-word>  label: <string>]
;   ]
;   block-diagram [
;       nodes [
;           node [id: <int>  type: <lit-word>  x: <int>  y: <int>  label: <string>  ...]
;       ]
;       wires [
;           wire [from: <int>  port: <lit-word>  to: <int>  port: <lit-word>]
;       ]
;   ]
;   connector [                    ; solo si el VI se usa como sub-VI
;       input  [id: <int>  label: <string>]
;       output [id: <int>  label: <string>]
;   ]
;
; Reglas de parse:
;   qvi-rule:     [opt connector-rule front-panel-rule block-diagram-rule]
;   control-rule: ['control block!]
;   node-rule:    ['node block!]
;   wire-rule:    ['wire block!]
;
; El procesador del dialecto (load-qvi) recorre el bloque con parse
; y construye el modelo en memoria (listas de nodos, puertos, wires).

; === Modelo en memoria ===
; Después de parsear un qvi-diagram, el modelo queda como objetos Red:

make-node: func [spec [block!]] [
    make object! [
        id:     select spec 'id
        type:   select spec 'type
        label:  select spec 'label
        x:      select spec 'x
        y:      select spec 'y
        ports:  copy []
        config: copy []
    ]
]

make-port: func [spec [block!]] [
    make object! [
        id:        select spec 'id
        name:      select spec 'name
        direction: select spec 'direction
        data-type: any [select spec 'type  'number]
        value:     select spec 'value
    ]
]

make-wire: func [spec [block!]] [
    make object! [
        from-node: select spec 'from
        from-port: to-word any [select spec 'from-port  'none]
        to-node:   select spec 'to
        to-port:   to-word any [select spec 'to-port    'none]
    ]
]

make-diagram: func [title [string!]] [
    make object! [
        name:      title
        connector: none
        nodes:     copy []
        wires:     copy []
        controls:  copy []
        indicators: copy []
    ]
]
