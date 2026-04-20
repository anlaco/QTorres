# Red-Lang Skill para QTorres

> Referencia rápida de Red para codificar QTorres. Consultar antes de escribir código Red, especialmente Draw y View.

**Repositorio Red oficial:** https://www.red-lang.org  
**Documentación:** https://doc.red-lang.org  
**Versión:** 0.6.6+  
**QTorres:** Red 100% (DT-001)

---

## Sintaxis core

### Tipos de datos básicos

| Tipo | Ejemplos | Notas |
|------|----------|-------|
| `integer!` | `5` `-42` `0` | Números enteros |
| `float!` | `3.14` `1e-3` | Punto flotante |
| `string!` | `"hola"` `{multi\nlínea}` | Texto |
| `binary!` | `#{48656C6C6F}` | Bytes |
| `logic!` | `true` `false` | Booleano |
| `block!` | `[1 2 3]` `[a: 5 print a]` | Bloque (código/datos) |
| `object!` | `make object! [a: 1 b: 2]` | Diccionario con propiedades |
| `function!` | `func [x][x * 2]` | Función con contexto |
| `routine!` | Rutinas nativas C | (Compiladas, no escribir en Red) |

### Variables y contextos

```red
; Asignar
a: 10
x: "texto"

; Objeto (diccionario)
person: make object! [
    name: "Alice"
    age: 30
    greet: func [][print ["Hola, " name]]
]
person/name         ; acceso
person/greet        ; llamar método

; Contexto (namespace)
make-context: function [][
    value: 42
    func [][value]
]
```

### Control de flujo

```red
; if
if condition [
    ; true
] [
    ; false (opcional)
]

; either (if/else)
either x > 5 [print "grande"] [print "pequeño"]

; loop
loop 10 [print "x"]

; foreach
foreach [k v] [a 1 b 2 c 3] [print [k v]]

; while
while [condition] [; body]

; until
until [condition]

; try/catch
try [dangerous-code] [error-code]
```

### Funciones

```red
; función simple
add: func [a b][a + b]

; con tipo de retorno
increment: func [
    n [integer!]
    return: [integer!]
][
    n + 1
]

; función local (sin contaminar contexto global)
local-func: function [x][ ; function = func + contexto nuevo
    local-var: x * 2
    local-var
]
```

### Manejo de bloques

```red
; map-like (procesar bloque)
process: func [blk][
    result: []
    foreach item blk [
        append result item * 2
    ]
    result
]

; compose (interpolar)
name: "Alice"
msg: compose ["Hola, " (name)]  ; ["Hola, " "Alice"]

; parse (parser simple)
rule: [integer! string! integer!]
parse [5 "hola" 10] rule        ; true si encaja
```

---

## View — UI Imperatva

### Layout básico

```red
view layout [
    text "Etiqueta"
    input: field 200x30
    button "Aceptar" [
        print input/text
    ]
]
```

### Faces (widgets)

| Face | Uso |
|------|-----|
| `text` | Etiqueta estática |
| `field` | Input texto |
| `button` | Botón clickable |
| `check` | Checkbox |
| `radio` | Radio button |
| `slider` | Slider (0-100) |
| `progress` | Barra de progreso |
| `panel` | Contenedor |
| `base` | Canvas base (para Draw) |
| `label` | Etiqueta editable |

### Propiedades comunes

```red
face: field 200x30
face/text: "nuevo valor"
face/visible: true
face/enabled: true
face/offset: 10x20      ; posición (x, y)
face/size: 200x30       ; ancho x alto
face/color: 128.128.128 ; RGB tuple
face/font: make font! [size: 12]
```

### Events (callbacks)

```red
button "Click" [
    ; this = la face que gatilló el evento
    print ["Botón presionado: " this/text]
]

; on-time (timer)
view layout [
    base 300x200 [
        ; ejecutar cada face/rate ticks
        face/rate: 10  ; 10 ticks/segundo
    ] on-time [
        ; lógica del timer
    ]
]
```

### Diálogos

```red
; Open file
file: request-file/title "Selecciona fichero"

; Color picker
color: request-color

; Simple dialog
result: view/new compose [
    text (msg)
    button "OK" [result: true]
]
```

---

## Draw — Gráficos vectoriales

### Semántica

```red
; Draw es un dialecto que genera vectores
; Se usa en `base/draw` o parámetro `draw:` de face

draw-cmds: [
    line 10x10 100x100
    box 50x50 150x150
    circle 75x75 30
    text 10x10 "Hola"
]

view layout [
    base 300x300 draw-cmds
]
```

### Comandos principales

| Comando | Uso |
|---------|-----|
| `line pt1 pt2` | Línea |
| `box pt1 pt2` | Rectángulo relleno |
| `box pt1 pt2 /stroke` | Rectángulo solo borde |
| `circle center radius` | Círculo |
| `circle center radiusX radiusY` | Elipse |
| `polygon [pt1 pt2 pt3...]` | Polígono |
| `text offset string` | Texto |
| `image image-data offset` | Imagen |
| `fill-pen color` | Color de relleno |
| `pen color` | Color de borde |
| `line-width n` | Grosor línea |
| `font font-obj` | Fuente para text |

### Colores

```red
pen 255.0.0           ; RGB rojo
pen 128.128.128       ; Gris
pen red               ; Nombre predefinido
pen #FF0000           ; Hex (con #)

; Transparencia (si soportado)
pen rgba(255 0 0 128) ; 50% transparente
```

### Ejemplo completo

```red
view layout [
    base 300x300 [
        pen 0.0.0       ; negro
        line-width 2
        
        fill-pen 200.200.255
        box 50x50 150x150
        
        fill-pen 255.0.0
        circle 75x75 30
        
        font make font! [size: 14]
        text 10x10 "Ejemplo Draw"
    ]
]
```

---

## Parse — Parsing de bloques

> Dialecto de Red para reconocimiento de patrones.

### Sintaxis básica

```red
; Estructura: parse <entrada> <reglas>

; Regla simple: encaja tipos
parse [1 "hola" 2] [integer! string! integer!]  ; true

; Captura en variable
data: []
parse [1 2 3] [
    set x integer! (append data x)
    set y integer! (append data y)
    set z integer!
]
; data = [1 2]

; Repetición
parse [1 1 1 2] [
    some integer!     ; 1+ números
    integer!          ; último número
]

; Alternación
parse "abc" [
    some ["a" | "b" | "c"]
]

; Opcional
parse [1 2] [
    integer! opt integer! opt integer!
]
```

### Reglas de parse

| Regla | Encaja |
|-------|--------|
| `integer!` | Cualquier entero |
| `"x"` / `'x` | Literal "x" |
| `[a b c]` | Secuencia |
| `[a \| b \| c]` | Alternativa |
| `some rule` | 1+ |
| `any rule` | 0+ |
| `opt rule` | 0-1 |
| `set var rule` | Captura |
| `copy var rule` | Copia bloque |

### Ejemplo: parser de comandos

```red
parse-command: func [cmd-string][
    result: make object! [action: none args: []]
    
    parse cmd-string [
        set result/action word!
        any [set arg word! (append result/args arg)]
    ]
    
    result
]

cmd: parse-command "show point 10 20"
; cmd/action = 'show
; cmd/args = [point 10 20]
```

---

## TCP — Comunicación de red

> API integrada en binarios red-cli/red-view (Fase 4+)

### API rápida

```red
; Conectar
if tcp/connect "192.168.1.100" 5000 [
    ; Enviar petición
    tcp/send "PING^/"

    ; Recibir respuesta
    response: tcp/receive 256

    ; Procesar
    print to string! response

    ; Cerrar
    tcp/close
]
```

### Funciones

| Función | Parámetros | Return |
|---------|-----------|--------|
| `tcp/connect` | `host [string!] port [integer!]` | `[logic!]` |
| `tcp/send` | `data [string! binary!]` | `[logic!]` |
| `tcp/receive` | `size [integer!]` | `[binary! none!]` |
| `tcp/close` | — | `[logic!]` |
| `tcp/connected?` | — | `[logic!]` |
| `tcp/set-timeout` | `ms [integer!]` | `[logic!]` |
| `tcp/readable?` | — | `[logic!]` |
| `tcp/set-nonblocking` | `enable [logic!]` | `[logic!]` |
| `tcp/last-error` | — | `[object!]` |

### Ejemplo con timeout

```red
Red [Needs: 'View]

; Conectar a servidor
if not tcp/connect "192.168.1.100" 5000 [
    print "Error: conexión fallida"
    halt
]

; Enviar petición y leer con timeout
tcp/set-timeout 2000
tcp/send "HELLO^/"

response: tcp/receive 256
if response [
    print ["Respuesta: " to string! response]
]

tcp/close
```

> QTorres no incluye bloques específicos por protocolo. Para enviar comandos de texto
> de instrumentación, Modbus, HTTP, MQTT o similar, basta con poner el string adecuado
> en `tcp/send`. Ver `docs/tcp-api.md` para referencia completa.

---

## Dialects propios de QTorres

### block-def — Definición de bloques

```red
; En src/graph/blocks.red

register-block [
    type: 'add
    label: "Add"
    category: 'math
    inputs: [a b]
    outputs: [out]
    emit: [out: a + b]
]
```

### qvi-diagram — Estructura de VI

```red
qvi-diagram: [
    meta: [description: "..." version: 1]
    connector: [...]        ; opcional
    front-panel: [
        control [id: 1 type: 'numeric name: "ctrl_1" label: [text: "A"]]
    ]
    block-diagram: [
        nodes: [...]
        wires: [...]
    ]
]
```

### emit — Generación de código Red

```red
; Cómo un bloque genera Red al compilar
emit: [
    ; Cuerpo Red que se inserta en el VI compilado
    out: input-a + input-b
]
```

---

## Gotchas y convenciones

### No usar

- ❌ `do` con bloques dinámicos en `.qvi` generado (debe compilarse con `red -c`)
- ❌ `load` de strings → use parse
- ❌ `compose` en runtime del VI generado (OK en compilador de QTorres)
- ❌ Herencia profunda (A → B → C) → usar composición
- ❌ Faces nativas en canvas del editor (usar Draw)
- ❌ Strings intermedios en compilador (manipular bloques Red)

### Usar

- ✅ `make object! [...]` para prototipos y composición
- ✅ `func` para funciones con cierre léxico
- ✅ `function` para contexto limpio (aislado)
- ✅ `view layout [...]` estático en VIs generados
- ✅ `face/rate` + `on-time` para timers/loops
- ✅ Parse para dialects custom
- ✅ Draw para gráficos en editor/panel

### Denominación

- Funciones: `kebab-case` (e.g., `make-node`, `compile-body`)
- Variables locales: `camelCase` (e.g., `isConnected`, `outputPort`)
- Constantes: `SCREAMING_SNAKE_CASE` (e.g., `DEFAULT_WIDTH`)
- Dialectos: `kebab-case` (e.g., `block-def`, `qvi-diagram`)
- Palabras clave de dialecto: sin prefijo (e.g., `emit`, `meta`, `connector`)

---

## Recursos

- **Docs Red oficial:** https://doc.red-lang.org
- **Red/View:** https://doc.red-lang.org/en/view.html
- **Red/Draw:** https://doc.red-lang.org/en/view.html#_draw-dialect
- **Red/Parse:** https://doc.red-lang.org/en/parse.html
- **TCP API:** Ver `docs/tcp-api.md` (específico de QTorres)
- **Skill Red en QTorres:** Este fichero

## Cuándo consultar esta skill

1. **Antes de escribir cualquier código Red** — especialmente Draw y View
2. **Cuando dudes de sintaxis** — tipo de datos, bloques, parse
3. **Para entender patrones idiomáticos** — composición, contextos, funciones
4. **Para TCP** — antes de implementar bloques de hardware (Fase 4)

---

*Última actualización: 2026-04-20*  
*Próxima: Fase 4 — bloques genéricos TCP/IP y USBTMC (sin bloques específicos por protocolo)*
