Red [
    Title:   "QTorres MVP"
    Author:  "QTorres contributors"
    Version: 0.1.0
    Purpose: "MVP: editor visual -> .qvi ejecutable"
    Needs:   'View
]

; ==================================================================================================
; QTorres-v2.red — Documento de código con documentación extensa
;
; Este archivo implementa una versión mínima viable (MVP) de un editor visual
; similar a LabVIEW para el lenguaje Red. El objetivo del programa es permitir
; crear mediante una interfaz gráfica (Front Panel + Block Diagram) una
; representación visual de un pequeño diagrama de datos y operaciones, y a
; partir de él generar un fichero ejecutable en formato `.qvi` (un artefacto
; textual usable por Red) o ejecutar el diagrama de forma inmediata.
;
; El contenido del archivo está organizado en secciones claramente señaladas
; (estado global, configuración, funciones utilitarias, renderizado, tests de
; colisión (hit-tests), compilador a .qvi y construcción de ventanas). A lo
; largo del código se usan objetos simples para representar los elementos
; principales: controles/indicadores del Front Panel (`fp-items`), nodos del
; Block Diagram (`bd-nodes`) y cables/ conexiones (`bd-wires`).
;
; Notas de diseño y estructura de datos:
; - `fp-items` : lista (block) de objetos de tipo control o indicator.
;    Cada `item` tiene propiedades: `id`, `kind` (control|indicator), `label`,
;    `x`,`y` (posición sobre el panel) y `default` (valor numérico para
;    controles/indicadores).
; - `bd-nodes` : lista de nodos del diagrama con propiedades: `id`, `type`
;    (ej. 'add, 'sub, 'control, 'indicator), `label`, `x`,`y`.
; - `bd-wires` : lista de conexiones. Cada `wire` contiene `from-id`, `from-p`
;    (nombre de puerto de salida en el nodo origen), `to-id`, `to-p` (puerto de
;    entrada en el nodo destino).
; - `next-id` y `gen-id` : sencillo generador de identificadores enteros
;    secuenciales para asignar IDs únicos a controles/nodos.
;
; Flujo de ejecución principal (resumido):
; 1) Usuario abre la ventana principal `main-win`.
; 2) Desde ahí puede abrir Front Panel y Block Diagram o generar/guardar
;    un `.qvi` o ejecutar en memoria el diagrama.
; 3) El Front Panel permite crear controles/indicadores y posicionarlos.
; 4) El Block Diagram permite crear nodos (suma/resta) y conectar puertos
;    mediante wires (clic en salida rojo -> clic en entrada azul).
; 5) `compile-to-qvi` recorre las estructuras y produce un fichero con dos
;    secciones: `qvi-diagram:` (mold del diagrama) y `-- CODIGO GENERADO --`
;    (líneas de código ejecutable simple representando la lógica del diagrama).
;
; Comentarios en el código: he añadido bloques explicativos en cada sección y
; antes de funciones clave para facilitar entender parámetros, efectos
; secundarios y formato de retorno. Las funciones mantienen exactamente el
; comportamiento original; solo se añaden comentarios aclaratorios.
; ==================================================================================================

; ==============================================================================
; Estado global
; Descripción amplia:
; Este bloque declara las variables globales que representan el estado de la
; aplicación mientras el usuario edita diagramas y paneles. Son objetos
; mutables y listas que mantienen la representación en memoria del proyecto.
; ==============================================================================

next-id: 1
gen-id: does [n: next-id  next-id: next-id + 1  n]

; Front Panel items
fp-items: copy []

; Block Diagram nodes y wires
bd-nodes: copy []
bd-wires: copy []

; Drag state (BD)
bd-drag-node: none
bd-drag-off:  none

; Drag state (FP)
fp-drag-item: none
fp-drag-off:  none

; Wire state
wire-src:  none
wire-port: none
mouse-pos: none

; Window refs
fp-win: none
bd-win: none
fp-canvas: none
bd-canvas: none

; Ultimo fichero guardado
last-saved: none

; ==============================================================================
; Config
;
; Variables de configuración visual y de espaciamiento usadas por el render:
; - `bw` (box width): ancho por defecto de cada nodo en el Block Diagram.
; - `bh` (box height): alto por defecto de cada nodo.
; - `pr` (port radius / padding): radio/espaciado empleado para dibujar los
;   círculos de los puertos y para calcular offsets.
; Estas constantes controlan el layout visual y se usan en `port-xy`, en los
; bucles de dibujo (`render-bd`, `render-fp`) y en las pruebas de colisión.
; ==============================================================================

bw: 120
bh: 50
pr: 8

; ==============================================================================
; Puertos por tipo
;
; Las siguientes funciones describen, para cada tipo de nodo, el conjunto de
; nombres de puertos de entrada (`in-ports`) y puertos de salida (`out-ports`).
; Estas listas son pequeñas y explícitas: por ejemplo, un nodo `add` tiene
; puertos de entrada `a` y `b`, y un puerto de salida `result`.
; Estas funciones no realizan efectos secundarios: devuelven listas que son
; consultadas por `port-xy` para ubicar gráficamente los círculos de conexión
; y por las rutinas de ejecución/compilación para conectar valores.
; ==============================================================================

in-ports: func [n] [
    switch n/type [
        control   [[]]
        indicator [[in]]
        add       [[a b]]
        sub       [[a b]]
    ]
]

out-ports: func [n] [
    switch n/type [
        control   [[out]]
        indicator [[]]
        add       [[result]]
        sub       [[result]]
    ]
]

port-xy: func [n pname dir] [
    either dir = 'in [
        ps: in-ports n
        i: index? find ps pname
        as-pair (n/x - pr) (n/y + 12 + ((i - 1) * 20))
    ][
        ps: out-ports n
        i: index? find ps pname
        as-pair (n/x + bw + pr) (n/y + 12 + ((i - 1) * 20))
    ]
]

ncolor: func [t] [
    switch t [
        control   [135.190.240]
        indicator [240.220.100]
        add       [120.200.120]
        sub       [255.150.100]
    ]
]

; ==============================================================================
; Sincronizacion FP -> BD
;
; Un control o indicador mostrado en el Front Panel debe existir también como
; nodo en el Block Diagram para que el usuario pueda conectar cables. La
; función `sync-fp-to-bd` realiza esa sincronización: si no existe un nodo con
; el mismo `id` que el `item` del Front Panel, crea un nodo con tipo igual a
; `item/kind` (control|indicator) y posición por defecto. Esta operación
; garantiza que al crear elementos en el panel el diagrama de bloques refleje
; los elementos disponibles.
; ==============================================================================

sync-fp-to-bd: func [item] [
    exists: false
    foreach n bd-nodes [if n/id = item/id [exists: true]]
    if not exists [
        append bd-nodes make object! [
            id:    item/id
            type:  item/kind
            label: item/label
            x:     50
            y:     30 + ((length? bd-nodes) * 70)
        ]
    ]
]

; ==============================================================================
; Render Front Panel
;
; `render-fp` devuelve una block de primitivas que describe visualmente cada
; control e indicador: un rectángulo con etiqueta, valor y color según su
; tipo. La función no dibuja directamente: su retorno es pasado al sistema de
; GUI (propiedad `draw` de una face) que interpreta la lista de primitivas y
; las pinta en pantalla cuando sea necesario.
; ==============================================================================

render-fp: func [] [
    d: copy []
    foreach item fp-items [
        clr: either item/kind = 'control [135.190.240] [240.220.100]
        val-text: either item/kind = 'control [
            rejoin ["Val: " item/default]
        ][
            either item/default = 0.0 ["---"] [rejoin ["= " item/default]]
        ]
        append d compose [
            pen black  line-width 1  fill-pen (clr)
            box (as-pair item/x item/y) (as-pair (item/x + 140) (item/y + 40)) 5
            fill-pen black
            text (as-pair (item/x + 5) (item/y + 13)) (item/label)
            text (as-pair (item/x + 5) (item/y + 27)) (val-text)
        ]
    ]
    d
]

; ==============================================================================
; Render Block Diagram
;
; `render-bd` construye las primitivas del Block Diagram: cada wire, un posible
; wire temporal (mientras el usuario arrastra), y cada nodo con sus puertos de
; entrada y salida. Para mejorar la legibilidad de las conexiones, las líneas
; de los wires se dibujan en forma de esquinas usando un punto medio `mx`.
; ==============================================================================

render-bd: func [] [
    ; Inicializa la lista de primitivas gráficas que devolveremos.
    d: copy []

    ; ==================================================================
    ; Dibujo de wires (conexiones permanentes)
    ; Recorremos `bd-wires` y, para cada wire, buscamos los nodos origen y
    ; destino (sn = source node, dn = destination node). Si ambos existen,
    ; calculamos las posiciones físicas de los puertos con `port-xy` y
    ; trazamos una línea compuesta que pasa por un punto medio `mx` para
    ; generar un trazado con esquina (mejor legibilidad que una línea recta).
    ; ==================================================================
    foreach w bd-wires [
        ; sn y dn serán asignados a los objetos de nodo correspondientes
        sn: none  dn: none
        foreach n bd-nodes [
            if n/id = w/from-id [sn: n]
            if n/id = w/to-id   [dn: n]
        ]
        ; Solo dibujamos si encontramos ambos extremos del wire
        if all [sn dn] [
            ; Obtener coordenadas del puerto de salida del nodo fuente
            p1: port-xy sn w/from-p 'out
            ; Obtener coordenadas del puerto de entrada del nodo destino
            p2: port-xy dn w/to-p   'in
            ; Calcular punto medio X para formar la esquina central
            mx: to-integer (p1/x + p2/x) / 2
            ; Determinar color del wire según el tipo del nodo origen
            ; Si el nodo origen es un control, indicador u operación (numérico)
            ; pintamos la conexión en naranja, en caso contrario usamos gris.
            wire-color: either any [sn/type = 'control sn/type = 'add sn/type = 'sub sn/type = 'indicator] [orange] [80.80.80]
            append d compose [
                pen (wire-color)  line-width 2
                line (p1) (as-pair mx p1/y) (as-pair mx p2/y) (p2)
            ]
        ]
    ]

    ; ==================================================================
    ; Wire temporal (mientras el usuario está arrastrando para crear una
    ; conexión). Se dibuja desde el puerto de salida seleccionado hasta la
    ; posición actual del ratón (`mouse-pos`).
    ; ==================================================================
    if all [wire-src mouse-pos] [
        sp: port-xy wire-src wire-port 'out
        append d compose [
            pen orange  line-width 2
            line (sp) (mouse-pos)
        ]
    ]

    ; ==================================================================
    ; Dibujo de nodos: cada nodo se representa como un rectángulo con
    ; etiqueta, una línea de texto adicional que indica el tipo y círculos
    ; para puertos de entrada (izquierda) y salida (derecha).
    ; ==================================================================
    foreach n bd-nodes [
        ; Color de relleno según tipo (ncolor devuelve una tripleta RGB)
        c: ncolor n/type
        ; Caja principal: rectángulo con borde negro y relleno `c`
        append d compose [
            pen black  line-width 1  fill-pen (c)
            box (as-pair n/x n/y) (as-pair (n/x + bw) (n/y + bh)) 6
            fill-pen black
            text (as-pair (n/x + 10) (n/y + 13)) (n/label)
        ]
        ; Texto pequeño que muestra tipo abreviado (CTRL/IND/ADD/SUB)
        tl: switch n/type [control ["CTRL"] indicator ["IND"] add ["ADD +"] sub ["SUB -"]]
        append d compose [text (as-pair (n/x + 10) (n/y + 28)) (tl)]

        ; -----------------------
        ; Puertos de entrada (izquierda)
        ; - `in-ports` devuelve una lista de nombres de puertos.
        ; - A cada puerto le asignamos una posición vertical incremental.
        ; -----------------------
        ps: in-ports n
        iy: n/y + 12
        foreach p ps [
            append d compose [
                pen black  fill-pen 50.100.220
                circle (as-pair (n/x - pr) iy) (pr)
                fill-pen black
                text (as-pair (n/x - pr - 22) (iy - 7)) (form p)
            ]
            iy: iy + 20
        ]

        ; -----------------------
        ; Puertos de salida (derecha)
        ; -----------------------
        ps: out-ports n
        oy: n/y + 12
        foreach p ps [
            append d compose [
                pen black  fill-pen 220.60.60
                circle (as-pair (n/x + bw + pr) oy) (pr)
                fill-pen black
                text (as-pair (n/x + bw + pr + 12) (oy - 7)) (form p)
            ]
            oy: oy + 20
        ]
    ]
    ; Devolver la lista de primitivas al sistema de dibujo
    d
]

; ==============================================================================
; Hit tests (BD) — mismo patron que prueba-bd.red
;
; Las funciones de hit-test permiten mapear coordenadas del ratón a elementos
; del diagrama: puertos (`hit-port`), nodos (`hit-node`) o elementos del
; Front Panel (`hit-fp-item`). Estas rutinas se utilizan por los handlers de
; eventos (`on-down`, `on-over`) para iniciar arrastres, conectar wires o
; seleccionar elementos.
; ==============================================================================

hit-port: func [px py] [
    foreach n bd-nodes [
        ; Salida (derecha)
        ps: out-ports n
        oy: n/y + 12
        foreach p ps [
            cx: n/x + bw + pr
            cy: oy
            if all [(absolute (px - cx)) < 16  (absolute (py - cy)) < 16] [
                return reduce [n p 'out]
            ]
            oy: oy + 20
        ]
        ; Entrada (izquierda)
        ps: in-ports n
        iy: n/y + 12
        foreach p ps [
            cx: n/x - pr
            cy: iy
            if all [(absolute (px - cx)) < 16  (absolute (py - cy)) < 16] [
                return reduce [n p 'in]
            ]
            iy: iy + 20
        ]
    ]
    none
]

hit-node: func [px py] [
    found: none
    foreach n bd-nodes [
        if all [px >= n/x  px <= (n/x + bw)  py >= n/y  py <= (n/y + bh)] [
            found: n
        ]
    ]
    found
]

; Hit test FP
hit-fp-item: func [px py] [
    found: none
    foreach item fp-items [
        if all [px >= item/x  px <= (item/x + 140)  py >= item/y  py <= (item/y + 40)] [
            found: item
        ]
    ]
    found
]

; ==============================================================================
; Compilador: modelo -> .qvi
;
; `compile-to-qvi` serializa el modelo actual en dos partes:
;  - una estructura `qvi-diagram` (usando `mold`) que contiene la descripción
;    completa del Front Panel y del Block Diagram (nodos + wires), útil para
;    reconstruir la vista cuando se abra el `.qvi`.
;  - una sección de `-- CODIGO GENERADO --` que contiene líneas simples de
;    asignación y operaciones derivadas del diagrama. El formato generado es
;    intencionalmente simple y está pensado para ser ejecutado directamente
;    por Red o por herramientas del proyecto.
; ==============================================================================

compile-to-qvi: func [filename] [
    ; === Cabecera: serializar controles/indicadores para la sección gráfica ===
    ; `fp-block` será una lista que describe cada elemento del Front Panel
    fp-block: copy []
    foreach item fp-items [
        ; Si es un control incluimos su valor por defecto en la descripción
        either item/kind = 'control [
            append fp-block compose/deep [
                control [id: (item/id) type: 'numeric label: (item/label) default: (item/default)]
            ]
        ][
            ; Si es indicador solo registramos id, tipo y etiqueta
            append fp-block compose/deep [
                indicator [id: (item/id) type: 'numeric label: (item/label)]
            ]
        ]
    ]

    ; === Nodos: serializar nodos del block-diagram ===
    nd-block: copy []
    foreach n bd-nodes [
        ; `to-lit-word form n/type` convierte el tipo simbólico a literal
        append nd-block compose/deep [
            node [id: (n/id) type: (to-lit-word form n/type) x: (n/x) y: (n/y) label: (n/label)]
        ]
    ]

    ; === Wires: serializar conexiones entre nodos ===
    wr-block: copy []
    foreach w bd-wires [
        ; Guardamos identificador de origen, puerto origen, id destino y puerto
        append wr-block compose/deep [
            wire [from: (w/from-id) port: (to-lit-word form w/from-p) to: (w/to-id) port: (to-lit-word form w/to-p)]
        ]
    ]

    ; === Bloque de diagrama completo (para reconstruir GUI si se abre el qvi) ===
    diagram-block: compose/deep [
        front-panel: [(fp-block)]
        block-diagram: [
            nodes: [(nd-block)]
            wires: [(wr-block)]
        ]
    ]

    ; === Código ejecutable: generaremos líneas simples que representan
    ; inicializaciones y operaciones derivadas del diagrama ===
    code-lines: copy []

    ; 1) Defaults de controles: por cada control añadimos `label: value` (texto)
    foreach item fp-items [
        if item/kind = 'control [
            append code-lines rejoin [item/label ": " item/default newline]
        ]
    ]

    ; 2) Nodos de operación: filtramos nodos tipo add/sub
    op-nodes: copy []
    foreach n bd-nodes [
        if any [n/type = 'add  n/type = 'sub] [append op-nodes n]
    ]

    ; Para cada nodo de operación buscamos sus entradas conectadas y
    ; generamos una expresión usando las etiquetas de las fuentes.
    foreach n op-nodes [
        ; Inicializamos operandos como constantes si no hay conexión
        input-a: "0.0"
        input-b: "0.0"
        foreach w bd-wires [
            if w/to-id = n/id [
                foreach src bd-nodes [
                    if src/id = w/from-id [
                        ; Dependiendo de si el puerto destino es 'a o 'b
                        either w/to-p = 'a [input-a: src/label] [input-b: src/label]
                    ]
                ]
            ]
        ]
        ; Operador textual: " + " o " - "
        op: either n/type = 'add [" + "] [" - "]
        append code-lines rejoin [n/label ": " input-a op input-b newline]
    ]

    ; 3) Indicadores: para cada indicador buscamos su fuente y generamos una
    ; asignación que asocia la etiqueta del indicador a la etiqueta de la fuente
    foreach item fp-items [
        if item/kind = 'indicator [
            foreach w bd-wires [
                if w/to-id = item/id [
                    foreach src bd-nodes [
                        if src/id = w/from-id [
                            append code-lines rejoin [item/label ": " src/label newline]
                        ]
                    ]
                ]
            ]
        ]
    ]

    ; 4) Añadir instrucciones para imprimir indicadores al final
    foreach item fp-items [
        if item/kind = 'indicator [
            append code-lines rejoin ["print " item/label newline]
        ]
    ]

    ; === Composición final del archivo .qvi ===
    out: copy {Red [title: "QTorres VI"]^/^/}
    append out "; -- CABECERA GRAFICA --^/"
    append out "; QTorres lee esta seccion para reconstruir la vista.^/"
    append out "; Para Red es solo una asignacion sin efectos.^/^/"
    append out "qvi-diagram: "
    append out mold diagram-block
    append out "^/^/"
    append out "; -- CODIGO GENERADO --^/"
    append out "; Generado por QTorres al guardar. Ejecutable con Red directamente.^/^/"
    foreach line code-lines [append out line]

    ; Escribir a disco y devolver el nombre de fichero
    write filename out
    filename
]

; ==============================================================================
; Ejecutar diagrama
;
; `run-diagram` evalúa el diagrama en memoria: toma los valores de los
; controles, propaga a través de los nodos de operación siguiendo los wires,
; y actualiza los indicadores con los resultados. Es llamada desde los botones
; ▶ del Front Panel, Block Diagram y ventana principal.
; ==============================================================================

run-diagram: does [
    if empty? bd-nodes [
        print "No hay diagrama para ejecutar."
        return none
    ]
    print "Ejecutando diagrama..."
    print "-----------------------------"

    vals: copy []
    foreach item fp-items [
        if item/kind = 'control [
            append vals item/id
            append vals item/default
        ]
    ]

    foreach n bd-nodes [
        if any [n/type = 'add  n/type = 'sub] [
            va: 0.0  vb: 0.0
            foreach w bd-wires [
                if w/to-id = n/id [
                    src-val: select vals w/from-id
                    if src-val [
                        either w/to-p = 'a [va: src-val] [vb: src-val]
                    ]
                ]
            ]
            res: either n/type = 'add [va + vb] [va - vb]
            pos: find vals n/id
            either pos [poke vals (1 + index? pos) res] [
                append vals n/id
                append vals res
            ]
            print rejoin [n/label ": " res]
        ]
    ]

    foreach item fp-items [
        if item/kind = 'indicator [
            foreach w bd-wires [
                if w/to-id = item/id [
                    src-val: select vals w/from-id
                    if src-val [
                        item/default: src-val
                        print rejoin [item/label ": " src-val]
                    ]
                ]
            ]
        ]
    ]

    print "-----------------------------"
    print "Ejecucion completada."
    if fp-canvas [fp-canvas/draw: render-fp]
]

; ==============================================================================
; Abrir Front Panel
;
; `open-front-panel` construye y muestra la ventana del Front Panel. Además de
; la construcción visual, registra actores (handlers) para eventos clave:
; - `on-down` detecta inicio de arrastre y selección de items.
; - `on-over` actualiza la posición del item mientras se arrastra.
; - `on-dbl-click` abre un diálogo para editar el valor de un control.
; La función también crea botones en la paleta para añadir controles e
; indicadores; al añadirlos se sincronizan con el Block Diagram mediante
; `sync-fp-to-bd`.
; ==============================================================================

open-front-panel: does [
    if fp-win [show fp-win  exit]

    fp-canvas: make face! [
        type: 'base
        size: 580x480
        offset: 155x25
        color: white
        flags: [all-over]
        draw: render-fp
        actors: make object! [
            on-down: func [face event] [
                ; Capturar posición relativa del ratón dentro del lienzo
                px: event/offset/x  py: event/offset/y
                ; Buscar si hemos clicado sobre un item del Front Panel
                item: hit-fp-item px py
                if item [
                    ; Si hay item, iniciamos arrastre guardando la referencia y
                    ; el desplazamiento (offset) entre la posición del ratón y
                    ; la esquina superior izquierda del objeto.
                    fp-drag-item: item
                    fp-drag-off: as-pair (px - item/x) (py - item/y)
                    return none
                ]
                ; Si no se ha pulsado sobre un item, limpiamos estado de drag
                fp-drag-item: none
            ]
            on-over: func [face event] [
                ; Mientras el botón del ratón esté pulsado y tengamos un item
                ; en dragging, actualizamos su posición relativa usando el
                ; offset guardado y forzamos el redraw del lienzo.
                if all [fp-drag-item fp-drag-off event/down?] [
                    fp-drag-item/x: event/offset/x - fp-drag-off/x
                    fp-drag-item/y: event/offset/y - fp-drag-off/y
                    face/draw: render-fp
                ]
            ]
            on-up: func [face event] [
                ; Al soltar limpiamos el estado de arrastre
                fp-drag-item: none
                fp-drag-off: none
            ]
            on-dbl-click: func [face event] [
                ; Doble clic: abrir diálogo de edición para controles numéricos
                px: event/offset/x  py: event/offset/y
                item: hit-fp-item px py
                if all [item  item/kind = 'control] [
                    ; Preparamos variables para comunicación con el diálogo
                    edit-item: item
                    edit-val: none
                    ; Construcción de una ventana modal simple (campo + botón)
                    edit-dlg: make face! [
                        type: 'window
                        text: rejoin ["Valor de " item/label]
                        size: 300x100
                        offset: 350x350
                        pane: reduce [
                            make face! [
                                type: 'text  text: "Valor numerico:"
                                offset: 10x10  size: 280x20
                            ]
                            make face! [
                                type: 'field  text: form item/default
                                offset: 10x35  size: 200x28
                                actors: make object! [
                                    on-enter: func [face event] [
                                        ; Cuando el usuario presiona Enter guardamos
                                        edit-val: face/text
                                        unview/only edit-dlg
                                    ]
                                ]
                            ]
                            make face! [
                                type: 'button  text: "OK"
                                offset: 220x35  size: 60x28
                                actors: make object! [
                                    on-click: func [face event] [
                                        ; Al pulsar OK leemos el campo y cerramos
                                        fld: edit-dlg/pane/2
                                        edit-val: fld/text
                                        unview/only edit-dlg
                                    ]
                                ]
                            ]
                        ]
                    ]
                    ; Mostramos el diálogo y procesamos eventos hasta cerrarlo
                    view/no-wait edit-dlg
                    do-events
                    ; Si el usuario introdujo un valor intentamos convertirlo a float
                    if edit-val [
                        v: attempt [to-float edit-val]
                        if v [edit-item/default: v]
                    ]
                    ; Forzar redibujado del panel para mostrar el nuevo valor
                    face/draw: render-fp
                ]
            ]
        ]
    ]

    btn-ctrl: make face! [
        type: 'button  text: "Control Num."
        offset: 15x25  size: 120x35
        actors: make object! [
            on-click: func [face event] [
                new-id: gen-id
                item: make object! [
                    id: new-id
                    kind: 'control
                    label: rejoin ["Ctrl_" new-id]
                    x: 20
                    y: 20 + ((length? fp-items) * 55)
                    default: 0.0
                ]
                append fp-items item
                sync-fp-to-bd item
                fp-canvas/draw: render-fp
                if bd-canvas [bd-canvas/draw: render-bd]
            ]
        ]
    ]

    btn-ind: make face! [
        type: 'button  text: "Indicador Num."
        offset: 15x65  size: 120x35
        actors: make object! [
            on-click: func [face event] [
                new-id: gen-id
                item: make object! [
                    id: new-id
                    kind: 'indicator
                    label: rejoin ["Ind_" new-id]
                    x: 20
                    y: 20 + ((length? fp-items) * 55)
                    default: 0.0
                ]
                append fp-items item
                sync-fp-to-bd item
                fp-canvas/draw: render-fp
                if bd-canvas [bd-canvas/draw: render-bd]
            ]
        ]
    ]

    palette-box: make face! [
        type: 'base  offset: 5x37  size: 145x110  color: 225.225.225
        draw: [pen gray box 0x0 144x109 4  pen black text 10x10 "Paleta"]
        pane: reduce [btn-ctrl btn-ind]
    ]

    lbl: make face! [
        type: 'base  offset: 155x37  size: 580x18  color: 240.240.240
        draw: [pen gray text 5x10 "Arrastra controles/indicadores"]
    ]

    fp-canvas/offset: 155x57
    fp-canvas/size:   580x448

    run-btn-fp: make face! [
        type: 'base
        size: 30x28
        offset: 4x2
        color: 210.210.210
        draw: [
            pen 70.70.70  line-width 1  fill-pen 235.235.235
            polygon 3x9 17x9 17x4 27x14 17x23 17x18 3x18
        ]
        actors: make object! [
            on-down: func [face event] [run-diagram]
        ]
    ]

    fp-toolbar: make face! [
        type: 'base
        size: 740x32
        offset: 0x0
        color: 210.210.210
        draw: [pen 170.170.170  line-width 1  line 0x31 740x31]
        pane: reduce [run-btn-fp]
    ]

    fp-win: make face! [
        type: 'window
        text: "QTorres - Front Panel"
        size: 740x510
        offset: 30x50
        pane: reduce [fp-toolbar palette-box lbl fp-canvas]
    ]

    view/no-wait fp-win
]

; ==============================================================================
; Abrir Block Diagram
;
; `open-block-diagram` crea la ventana del Block Diagram con su lienzo y
; paleta de bloques (Suma, Resta). Los actores registrados permiten:
; - comenzar y finalizar la creación de wires entre puertos (`on-down`),
; - arrastrar nodos para reubicarlos (`on-down` + `on-over` mientras se pulsa),
; - dibujar un wire temporal mientras se elige el destino.
; ==============================================================================

open-block-diagram: does [
    if bd-win [show bd-win  exit]

    bd-canvas: make face! [
        type: 'base
        size: 680x480
        offset: 155x25
        color: 245.245.240
        flags: [all-over]
        draw: render-bd
        actors: make object! [
            on-down: func [face event] [
                px: event/offset/x
                py: event/offset/y

                ; 1. Puerto?
                h: hit-port px py
                if h [
                    hn: h/1  hp: h/2  hd: h/3
                    either wire-src = none [
                        if hd = 'out [
                            wire-src: hn
                            wire-port: hp
                            mouse-pos: event/offset
                            face/draw: render-bd
                        ]
                    ][
                        if all [hd = 'in  wire-src/id <> hn/id] [
                            append bd-wires make object! [
                                from-id: wire-src/id
                                from-p:  wire-port
                                to-id:   hn/id
                                to-p:    hp
                            ]
                        ]
                        wire-src: none
                        wire-port: none
                        mouse-pos: none
                        face/draw: render-bd
                    ]
                    return none
                ]

                ; 2. Nodo?
                n: hit-node px py
                if n [
                    wire-src: none  wire-port: none  mouse-pos: none
                    bd-drag-node: n
                    bd-drag-off: as-pair (px - n/x) (py - n/y)
                    return none
                ]

                ; 3. Vacio
                wire-src: none  wire-port: none  mouse-pos: none
                bd-drag-node: none
                face/draw: render-bd
            ]

            on-over: func [face event] [
                px: event/offset/x
                py: event/offset/y
                if all [bd-drag-node bd-drag-off event/down?] [
                    bd-drag-node/x: px - bd-drag-off/x
                    bd-drag-node/y: py - bd-drag-off/y
                    face/draw: render-bd
                    return none
                ]
                if wire-src [
                    mouse-pos: as-pair px py
                    face/draw: render-bd
                ]
            ]

            on-up: func [face event] [
                bd-drag-node: none
                bd-drag-off: none
            ]
        ]
    ]

    btn-add: make face! [
        type: 'button  text: "Suma (+)"
        offset: 15x25  size: 120x35
        actors: make object! [
            on-click: func [face event] [
                new-id: gen-id
                append bd-nodes make object! [
                    id: new-id
                    type: 'add
                    label: rejoin ["Add_" new-id]
                    x: 200 + (random 150)
                    y: 50 + (random 300)
                ]
                bd-canvas/draw: render-bd
            ]
        ]
    ]

    btn-sub: make face! [
        type: 'button  text: "Resta (-)"
        offset: 15x65  size: 120x35
        actors: make object! [
            on-click: func [face event] [
                new-id: gen-id
                append bd-nodes make object! [
                    id: new-id
                    type: 'sub
                    label: rejoin ["Sub_" new-id]
                    x: 200 + (random 150)
                    y: 50 + (random 300)
                ]
                bd-canvas/draw: render-bd
            ]
        ]
    ]

    palette-box: make face! [
        type: 'base  offset: 5x37  size: 145x110  color: 225.225.225
        draw: [pen gray box 0x0 144x109 4  pen black text 10x10 "Bloques"]
        pane: reduce [btn-add btn-sub]
    ]

    lbl: make face! [
        type: 'base  offset: 155x37  size: 680x18  color: 240.240.240
        draw: [pen gray text 5x10 "Clic rojo(salida) -> clic azul(entrada) para wire | Arrastra nodos"]
    ]

    bd-canvas/offset: 155x57
    bd-canvas/size:   680x448

    run-btn-bd: make face! [
        type: 'base
        size: 30x28
        offset: 4x2
        color: 210.210.210
        draw: [
            pen 70.70.70  line-width 1  fill-pen 235.235.235
            polygon 3x9 17x9 17x4 27x14 17x23 17x18 3x18
        ]
        actors: make object! [
            on-down: func [face event] [run-diagram]
        ]
    ]

    bd-toolbar: make face! [
        type: 'base
        size: 840x32
        offset: 0x0
        color: 210.210.210
        draw: [pen 170.170.170  line-width 1  line 0x31 840x31]
        pane: reduce [run-btn-bd]
    ]

    bd-win: make face! [
        type: 'window
        text: "QTorres - Block Diagram"
        size: 840x510
        offset: 180x100
        pane: reduce [bd-toolbar palette-box lbl bd-canvas]
    ]

    view/no-wait bd-win
]

; ==============================================================================
; Ventana principal
;
; `main-win` es la ventana de lanzamiento de la aplicación. Desde aquí se puede
; generar el editor (abrir FP + BD), guardar el estado actual en un `.qvi` y
; ejecutar el diagrama in-memory para ver resultados inmediatos en los
; indicadores. El botón "Generar .qvi" reinicia el estado de la sesión y
; abre las ventanas de edición.
; ==============================================================================

main-win: make face! [
    type: 'window
    text: "QTorres MVP v0.1"
    size: 500x180
    offset: 100x200
    color: 240.240.240
    pane: reduce [
        make face! [
            type: 'base  offset: 20x10  size: 300x28  color: 240.240.240
            draw: [pen navy text 0x0 "QTorres - Programacion Visual"]
        ]
        make face! [
            type: 'base  offset: 20x38  size: 300x18  color: 240.240.240
            draw: [pen gray text 0x0 "Entorno visual tipo LabVIEW sobre Red-Lang"]
        ]
        make face! [
            type: 'button  text: "Generar .qvi"
            offset: 20x70  size: 140x40
            actors: make object! [
                on-click: func [face event] [
                    next-id: 1
                    clear fp-items
                    clear bd-nodes
                    clear bd-wires
                    wire-src: none  wire-port: none  mouse-pos: none
                    bd-drag-node: none  bd-drag-off: none
                    fp-drag-item: none  fp-drag-off: none
                    if fp-win [unview/only fp-win  fp-win: none]
                    if bd-win [unview/only bd-win  bd-win: none]
                    open-front-panel
                    open-block-diagram
                ]
            ]
        ]
        make face! [
            type: 'button  text: "Guardar"
            offset: 180x70  size: 140x40
            actors: make object! [
                on-click: func [face event] [
                    either empty? fp-items [
                        print "Nada que guardar."
                    ][
                        ; Dialogo simple para nombre de fichero
                        save-name: none
                        save-dlg: make face! [
                            type: 'window
                            text: "Guardar como..."
                            size: 400x120
                            offset: 300x300
                            pane: reduce [
                                make face! [
                                    type: 'text  text: "Nombre del fichero (.qvi):"
                                    offset: 10x10  size: 380x20
                                ]
                                make face! [
                                    type: 'field  text: "mi-programa.qvi"
                                    offset: 10x35  size: 380x28
                                    actors: make object! [
                                        on-enter: func [face event] [
                                            save-name: face/text
                                            unview/only save-dlg
                                        ]
                                    ]
                                ]
                                make face! [
                                    type: 'button  text: "Guardar"
                                    offset: 150x75  size: 100x35
                                    actors: make object! [
                                        on-click: func [face event] [
                                            fld: save-dlg/pane/2
                                            save-name: fld/text
                                            unview/only save-dlg
                                        ]
                                    ]
                                ]
                            ]
                        ]
                        view/no-wait save-dlg
                        do-events
                        if save-name [
                            unless find save-name ".qvi" [
                                save-name: rejoin [save-name ".qvi"]
                            ]
                            fname: to-file save-name
                            result: compile-to-qvi fname
                            last-saved: fname
                            print rejoin ["Guardado: " result]
                        ]
                    ]
                ]
            ]
        ]
        make face! [
            type: 'base  offset: 40x115  size: 400x45  color: 240.240.240
            draw: [
                pen black
                fill-pen 255.220.60
                box 0x0 400x45 4
                pen gray
                text 0x10  "1) Pulsa 'Generar .qvi' para abrir el editor"
                text 0x25 "2) Controles, indicadores, bloques y wires"
                text 0x40 "3) Guardar y luego Ejecutar"
            ]
        ]
        make face! [
            type: 'button  text: "▶ Ejecutar .qvi"
            offset: 340x70  size: 140x40
            color: 80.180.80
            actors: make object! [
                on-click: func [face event] [run-diagram]
            ]
        ]
    ]
]

view main-win
