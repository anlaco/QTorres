# Referencia de formatos QTorres para agentes de IA

Este documento es una referencia de consumo para agentes de IA que necesiten generar ficheros del ecosistema QTorres. No es documentación interna del proyecto — es el contrato entre QTorres y cualquier modelo que genere ficheros para él.

**Versión:** 1.0 — MVP (solo `.qvi` con tipos numéricos)
**Decisiones relacionadas:** DT-020, DT-021

---

## Principio fundamental

Todo fichero QTorres tiene dos secciones:

1. **Fuente de verdad** — un dialecto Red que describe la estructura gráfica y funcional. Es la única sección que se genera o edita.
2. **Código generado** — código Red ejecutable generado automáticamente por QTorres al guardar. **No se genera por IA.** QTorres lo produce a partir de la sección 1.

Un agente de IA solo trabaja con la sección 1. Nunca genera la sección 2.

---

## Formato `.qvi` — Virtual Instrument

### Estructura mínima

```red
Red [title: "Nombre del VI"]

qvi-diagram: [
    front-panel: [
        ; controles e indicadores
    ]
    block-diagram: [
        nodes: [
            ; nodos del diagrama
        ]
        wires: [
            ; conexiones entre nodos
        ]
    ]
]
```

### Estructura completa

```red
Red [title: "Nombre del VI" Needs: 'View]

qvi-diagram: [
    meta: [
        description: "Descripción en lenguaje natural"
        version:     1
        author:      "nombre"
        tags:        [palabra1 palabra2]
    ]

    icon: [
        ; Draw dialect — 32x32 px
    ]

    connector: [
        ; Solo si el VI puede usarse como sub-VI
        in  [id: 1  name: 'A       type: 'number  pos: 0x10]
        in  [id: 2  name: 'B       type: 'number  pos: 0x22]
        out [id: 3  name: 'Result  type: 'number  pos: 32x16]
    ]

    front-panel: [
        control   [id: 1  type: 'numeric  label: "A"         default: 5.0]
        control   [id: 2  type: 'numeric  label: "B"         default: 3.0]
        indicator [id: 3  type: 'numeric  label: "Resultado"]
    ]

    block-diagram: [
        nodes: [
            node [id: 1  type: 'control    x: 40   y: 80   label: "A"]
            node [id: 2  type: 'control    x: 40   y: 160  label: "B"]
            node [id: 3  type: 'add        x: 200  y: 120]
            node [id: 4  type: 'indicator  x: 360  y: 120  label: "Resultado"]
        ]
        wires: [
            wire [from: 1  port: 'out     to: 3  port: 'a]
            wire [from: 2  port: 'out     to: 3  port: 'b]
            wire [from: 3  port: 'result  to: 4  port: 'in]
        ]
    ]
]
```

### Secciones del qvi-diagram

| Sección | Obligatoria | Descripción |
|---------|-------------|-------------|
| `meta` | No | Metadatos descriptivos del VI |
| `icon` | No | Icono 32x32 en Draw dialect |
| `connector` | No | Si presente, habilita uso como sub-VI |
| `front-panel` | Sí | Controles (entradas) e indicadores (salidas) |
| `block-diagram` | Sí | Nodos y wires del diagrama |

### Front Panel

Dos tipos de elemento:

```red
control   [id: <int>  type: '<tipo>  label: "<nombre>"  default: <valor>]
indicator [id: <int>  type: '<tipo>  label: "<nombre>"]
```

- `control` = entrada del usuario (campo editable)
- `indicator` = salida del programa (solo lectura)
- El `id` debe coincidir con el `id` del nodo correspondiente en `block-diagram`

**Tipos disponibles (MVP):** `'numeric`

### Block Diagram — Nodos

```red
node [id: <int>  type: '<tipo>  x: <int>  y: <int>  label: "<nombre>"]
```

**Tipos de nodo:**

| Tipo | Categoría | Puerto de salida | Descripción |
|------|-----------|-----------------|-------------|
| `'control` | entrada | `'out` | Conecta con un control del Front Panel |
| `'indicator` | salida | `'in` (entrada) | Conecta con un indicador del Front Panel |
| `'const` | entrada | `'result` | Valor constante configurable |
| `'add` | math | entradas: `'a`, `'b` — salida: `'result` | Suma |
| `'sub` | math | entradas: `'a`, `'b` — salida: `'result` | Resta |
| `'mul` | math | entradas: `'a`, `'b` — salida: `'result` | Multiplicación |
| `'div` | math | entradas: `'a`, `'b` — salida: `'result` | División |
| `'display` | salida | entrada: `'value` | Muestra un valor por consola |
| `'subvi` | subvi | (según connector del sub-VI) | Referencia a otro .qvi |

**Nodo sub-VI:** requiere campo `file:` con la ruta relativa al fichero:
```red
node [id: 10  type: 'subvi  x: 200  y: 120  file: %ruta/al-subvi.qvi]
```

### Block Diagram — Wires

```red
wire [from: <id-nodo-origen>  port: '<puerto-salida>  to: <id-nodo-destino>  port: '<puerto-entrada>]
```

**Reglas de conexión:**
- Un puerto de salida puede conectarse a múltiples entradas (fan-out)
- Un puerto de entrada solo puede recibir un wire (una sola fuente de datos)
- Los tipos deben ser compatibles (en el MVP todo es `'number`)
- No se permiten ciclos en el grafo

### Connector (para sub-VIs)

Si el VI tiene sección `connector`, puede usarse como bloque dentro de otro VI:

```red
connector: [
    in  [id: <int>  name: '<nombre>  type: '<tipo>  pos: <pair!>]
    out [id: <int>  name: '<nombre>  type: '<tipo>  pos: <pair!>]
]
```

- `id` debe coincidir con el control/indicador correspondiente del Front Panel
- `name` es el nombre del puerto que verán otros VIs al usar este como bloque
- `pos` es la posición del terminal en el icono (par de coordenadas dentro de 32x32)

---

## Formato `.qprim` — Primitiva

Una primitiva es un bloque con lógica Red pura e icono libre. Se incrusta en tiempo de compilación.

```red
Red [title: "Add" type: 'primitive]

qprim: [
    meta: [
        description: "Suma dos valores numéricos"
        category:    'math
        version:     1
    ]

    ports: [
        in  [id: 1  name: 'a       type: 'number  x: 0   y: 10]
        in  [id: 2  name: 'b       type: 'number  x: 0   y: 22]
        out [id: 3  name: 'result  type: 'number  x: 32  y: 16]
    ]

    icon: [
        ; Draw dialect — diseño libre dentro de 32x32
        pen 2
        line 4x16 28x16
        line 16x4 16x28
    ]

    code: [
        result: a + b
    ]
]
```

---

## Formato `.qproj` — Proyecto

```red
qproj [
    version: 1
    title:   "Nombre del proyecto"

    files: [
        %main.qvi
        %utils/suma.qvi
    ]

    libraries: [
        %libs/mi-libreria.qlib
    ]

    build: [
        target: 'executable
        entry:  %main.qvi
    ]
]
```

---

## Formato `.qlib` — Librería

```red
qlib [
    version: 1
    name:    "math"

    members: [
        %add.qprim
        %subtract.qprim
        %interpolate.qvi
    ]
]
```

---

## Formato `.qctl` — Type definition

```red
qctl [
    version: 1
    name:    "config-datos"

    fields: [
        campo [name: "sampling-rate"  type: 'number  default: 1000.0]
        campo [name: "canal"          type: 'string  default: "AI0"]
        campo [name: "activo"         type: 'logic   default: true]
    ]
]
```

---

## Ejemplos completos funcionales

### Ejemplo 1 — Suma básica (VI standalone)

```red
Red [title: "Suma básica"]

qvi-diagram: [
    front-panel: [
        control   [id: 1  type: 'numeric  label: "A"         default: 5.0]
        control   [id: 2  type: 'numeric  label: "B"         default: 3.0]
        indicator [id: 3  type: 'numeric  label: "Resultado"]
    ]
    block-diagram: [
        nodes: [
            node [id: 1  type: 'control    x: 40   y: 80   label: "A"]
            node [id: 2  type: 'control    x: 40   y: 160  label: "B"]
            node [id: 3  type: 'add        x: 200  y: 120  label: "Suma"]
            node [id: 4  type: 'indicator  x: 360  y: 120  label: "Resultado"]
        ]
        wires: [
            wire [from: 1  port: 'out  to: 3  port: 'a]
            wire [from: 2  port: 'out  to: 3  port: 'b]
            wire [from: 3  port: 'out  to: 4  port: 'in]
        ]
    ]
]
```

### Ejemplo 2 — Sub-VI con connector

```red
Red [title: "suma"]

qvi-diagram: [
    connector: [
        input  [id: 1  label: "A"]
        input  [id: 2  label: "B"]
        output [id: 3  label: "Resultado"]
    ]
    front-panel: [
        control   [id: 1  type: 'numeric  label: "A"         default: 0.0]
        control   [id: 2  type: 'numeric  label: "B"         default: 0.0]
        indicator [id: 3  type: 'numeric  label: "Resultado"]
    ]
    block-diagram: [
        nodes: [
            node [id: 1  type: 'control    x: 40   y: 80   label: "A"]
            node [id: 2  type: 'control    x: 40   y: 160  label: "B"]
            node [id: 3  type: 'add        x: 200  y: 120  label: "Suma"]
            node [id: 4  type: 'indicator  x: 360  y: 120  label: "Resultado"]
        ]
        wires: [
            wire [from: 1  port: 'out  to: 3  port: 'a]
            wire [from: 2  port: 'out  to: 3  port: 'b]
            wire [from: 3  port: 'out  to: 4  port: 'in]
        ]
    ]
]
```

### Ejemplo 3 — Programa que usa un sub-VI

```red
Red [title: "Programa con sub-VI"]

qvi-diagram: [
    front-panel: [
        control   [id: 1  type: 'numeric  label: "X"       default: 10.0]
        control   [id: 2  type: 'numeric  label: "Y"       default: 4.0]
        indicator [id: 3  type: 'numeric  label: "Total"]
    ]
    block-diagram: [
        nodes: [
            node [id: 1   type: 'control    x: 40   y: 80   label: "X"]
            node [id: 2   type: 'control    x: 40   y: 160  label: "Y"]
            node [id: 10  type: 'subvi      x: 200  y: 120  file: %suma-subvi.qvi]
            node [id: 3   type: 'indicator  x: 360  y: 120  label: "Total"]
        ]
        wires: [
            wire [from: 1   port: 'out        to: 10  port: 'A]
            wire [from: 2   port: 'out        to: 10  port: 'B]
            wire [from: 10  port: 'Resultado  to: 3   port: 'in]
        ]
    ]
]
```

---

## Errores comunes a evitar

1. **No generar la sección 2 (código ejecutable).** QTorres la genera. El agente solo produce `qvi-diagram`.
2. **No inventar tipos de nodo.** Usar solo los tipos listados en la tabla de nodos.
3. **Respetar los nombres de puerto exactos.** `'a` y `'b` para bloques math, `'out` para controles, `'in` para indicadores.
4. **Los IDs deben ser únicos** dentro de un mismo `block-diagram`.
5. **Los IDs de control/indicator en front-panel deben coincidir** con los IDs de los nodos correspondientes en block-diagram.
6. **No crear ciclos** en el grafo de conexiones.
7. **Un puerto de entrada solo recibe un wire.** Si necesitas el mismo valor en dos sitios, usa fan-out desde la salida.

---

## Nota sobre evolución

Este documento refleja el estado del MVP (solo tipos numéricos). Conforme QTorres evolucione, se añadirán tipos de datos (`'boolean`, `'string`, `'array`), estructuras de control (loops, case), protocolos de hardware (Modbus, SCPI, MQTT), y nuevos bloques primitivos. La estructura del formato se mantiene — solo crece el vocabulario.
