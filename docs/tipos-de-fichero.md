# Tipos de fichero — QTorres

QTorres replica la estructura de ficheros de LabVIEW. Un usuario de LabVIEW reconoce la organización al instante. La diferencia: donde LabVIEW guarda binarios opacos, QTorres guarda Red en texto plano.

## Mapeo LabVIEW → QTorres

| LabVIEW | QTorres | Descripción |
|---------|---------|-------------|
| `.lvproj` | `.qproj` | Proyecto — referencias a ficheros, configuración de build, targets |
| `.vi` | `.qvi` | Virtual Instrument — front panel + block diagram (la unidad fundamental) |
| `.lvlib` | `.qlib` | Librería — colección de VIs y primitivas agrupados bajo un namespace |
| `.lvclass` | `.qclass` | Clase — datos + métodos (VIs miembro) — Fase futura |
| `.ctl` | `.qctl` | Type definition — control/indicador personalizado reutilizable |
| *(primitiva C++)* | `.qprim` | Primitiva — bloque con lógica Red pura e icono de dibujo libre |

## Principios fundamentales

**Todo fichero `.qvi` es código Red ejecutable.** Contiene dos secciones:

1. **Fuente de verdad** (`qvi-diagram: [...]`): el diagrama completo — Front Panel, Block Diagram, icono, conector. QTorres la lee para reconstruir la vista visual. Para Red es una simple asignación sin efectos secundarios. Es la única sección que se edita (a mano, con QTorres, o con IA).

2. **Código generado**: código Red/View puro, generado automáticamente por QTorres al guardar. No se edita manualmente — se sobreescribe en cada Save. Existe para que el fichero sea ejecutable directamente con Red sin QTorres instalado.

Un `.qvi` se puede ejecutar de dos formas:
- **Con QTorres:** abre la UI, muestra Front Panel y Block Diagram, permite editar y ejecutar interactivamente.
- **Con Red directamente:** `red mi-vi.qvi` ejecuta el código generado. Sin argumentos abre el Front Panel; con argumentos ejecuta en modo headless.

Un `.qvi` con solo la sección `qvi-diagram` (sin código generado) es válido — QTorres lo abrirá y generará el código al guardar.

## Estructura de un proyecto típico

```
mi-proyecto/
├── mi-proyecto.qproj        # Proyecto
├── main.qvi                  # VI principal
├── utils/
│   ├── filtro.qvi            # Sub-VI reutilizable
│   └── escalar.qvi
├── primitivas/
│   ├── add.qprim             # Primitiva: lógica Red + icono libre
│   └── interpolate.qprim
└── tipos/
    └── config-datos.qctl     # Type definition
```

## Formato interno de cada tipo

### `.qvi` — VI standalone (sin conector)

Un VI sin conector solo puede ejecutarse standalone. No puede usarse como sub-VI de otro diagrama.

```red
Red [title: "Suma básica" Needs: 'View]

; ═══════════════════════════════════════════════════════════
; FUENTE DE VERDAD — editar con QTorres, a mano, o con IA
; ═══════════════════════════════════════════════════════════

qvi-diagram: [

    meta: [
        description: "Suma dos valores numéricos A y B"
        version:     1
        author:      "alaforga"
        tags:        [math]
    ]

    icon: [
        ; Draw dialect — 32x32 px — cómo se ve en el diagrama padre
        ; (si en el futuro se usa como sub-VI, QTorres usa este icono)
        pen 2
        line 4x16 28x16
        line 16x4 16x28
    ]

    front-panel: [
        control   [id: 1  type: 'numeric  label: "A"          default: 5.0]
        control   [id: 2  type: 'numeric  label: "B"          default: 3.0]
        indicator [id: 3  type: 'numeric  label: "Resultado"]
    ]

    block-diagram: [
        nodes: [
            node [id: 1  type: 'control    x: 40   y: 80   label: "A"]
            node [id: 2  type: 'control    x: 40   y: 160  label: "B"]
            node [id: 3  type: 'math/add   x: 200  y: 120]
            node [id: 4  type: 'indicator  x: 360  y: 120  label: "Resultado"]
        ]
        wires: [
            wire [from: 1  port: 'out     to: 3  port: 'a]
            wire [from: 2  port: 'out     to: 3  port: 'b]
            wire [from: 3  port: 'result  to: 4  port: 'in]
        ]
    ]
]

; ═══════════════════════════════════════════════════════════
; CÓDIGO GENERADO — no editar, se regenera al guardar en QTorres
; ═══════════════════════════════════════════════════════════

context [
    either empty? system/options/args [
        view layout [
            label "A"    fA: field "5.0"
            label "B"    fB: field "3.0"
            button "Run" [
                A: to-float fA/text
                B: to-float fB/text
                lResultado/text: form (A + B)
            ]
            label "Resultado:"  lResultado: text "---"
        ]
    ][
        A: to-float select system/options/args "A"
        B: to-float select system/options/args "B"
        print form (A + B)
    ]
]
```

### `.qvi` — VI con conector (puede usarse como sub-VI)

La presencia de `connector` en `qvi-diagram` indica que este VI puede usarse como bloque en otro diagrama. También puede ejecutarse standalone para pruebas.

```red
Red [title: "suma" Needs: 'View]

; ═══════════════════════════════════════════════════════════
; FUENTE DE VERDAD
; ═══════════════════════════════════════════════════════════

qvi-diagram: [

    meta: [
        description: "Suma dos valores numéricos y devuelve el resultado"
        version:     1
        tags:        [math arithmetic]
    ]

    icon: [
        pen 2
        line 4x16 28x16
        line 16x4 16x28
    ]

    connector: [
        ; Su presencia habilita el uso de este VI como sub-VI
        in  [id: 1  name: 'A       type: 'number  pos: 0x10]
        in  [id: 2  name: 'B       type: 'number  pos: 0x22]
        out [id: 3  name: 'Result  type: 'number  pos: 32x16]
    ]

    front-panel: [
        control   [id: 1  type: 'numeric  label: "A"          default: 5.0]
        control   [id: 2  type: 'numeric  label: "B"          default: 3.0]
        indicator [id: 3  type: 'numeric  label: "Resultado"]
    ]

    block-diagram: [
        nodes: [
            node [id: 1  type: 'control    x: 40   y: 80   label: "A"]
            node [id: 2  type: 'control    x: 40   y: 160  label: "B"]
            node [id: 3  type: 'math/add   x: 200  y: 120]
            node [id: 4  type: 'indicator  x: 360  y: 120  label: "Resultado"]
        ]
        wires: [
            wire [from: 1  port: 'out     to: 3  port: 'a]
            wire [from: 2  port: 'out     to: 3  port: 'b]
            wire [from: 3  port: 'result  to: 4  port: 'in]
        ]
    ]
]

; ═══════════════════════════════════════════════════════════
; CÓDIGO GENERADO — no editar, se regenera al guardar en QTorres
; ═══════════════════════════════════════════════════════════

; Función expuesta — disponible cuando otro VI hace do %suma.qvi
suma: func [A [float!] B [float!] /local Resultado] [
    Resultado: A + B
    Resultado
]

; Ejecución standalone — solo cuando se lanza directamente con Red
if not value? 'qtorres-runtime [
    context [
        either empty? system/options/args [
            view layout [
                label "A"    fA: field "5.0"
                label "B"    fB: field "3.0"
                button "Run" [
                    lResult/text: form suma to-float fA/text to-float fB/text
                ]
                label "Resultado:"  lResult: text "---"
            ]
        ][
            print form suma
                to-float select system/options/args "A"
                to-float select system/options/args "B"
        ]
    ]
]
```

### `.qvi` usando otro VI como sub-VI

Cuando un VI usa `suma.qvi` como bloque en su diagrama:

```red
Red [title: "mi-programa" Needs: 'View]

qvi-diagram: [

    meta: [
        description: "Programa principal que usa suma como sub-VI"
        version:     1
    ]

    icon: [...]

    front-panel: [
        control   [id: 1  type: 'numeric  label: "X"      default: 10.0]
        control   [id: 2  type: 'numeric  label: "Y"      default: 4.0]
        indicator [id: 3  type: 'numeric  label: "Total"]
    ]

    block-diagram: [
        nodes: [
            node [id: 1   type: 'control    label: "X"]
            node [id: 2   type: 'control    label: "Y"]
            node [id: 10  type: 'subvi      file: %utils/suma.qvi]
            node [id: 3   type: 'indicator  label: "Total"]
        ]
        wires: [
            wire [from: 1   port: 'out      to: 10  port: 'A]
            wire [from: 2   port: 'out      to: 10  port: 'B]
            wire [from: 10  port: 'Result   to: 3   port: 'in]
        ]
    ]
]

; ═══════════════════════════════════════════════════════════
; CÓDIGO GENERADO
; ═══════════════════════════════════════════════════════════

do %utils/suma.qvi     ; carga y define utils/suma

context [
    either empty? system/options/args [
        view layout [
            label "X"    fX: field "10.0"
            label "Y"    fY: field "4.0"
            button "Run" [
                lTotal/text: form utils/suma to-float fX/text to-float fY/text
            ]
            label "Total:"  lTotal: text "---"
        ]
    ][
        print form utils/suma
            to-float select system/options/args "X"
            to-float select system/options/args "Y"
    ]
]
```

### `.qprim` — Primitiva

Una primitiva es lógica Red pura con un icono de dibujo libre. Se abre en QTorres con editor de código + paleta de dibujo. Su código se **incrusta en tiempo de compilación** — no hay dependencia en tiempo de ejecución.

```red
Red [title: "Add" type: 'primitive]

qprim: [

    meta: [
        description: "Suma dos valores numéricos"
        category:    'math
        version:     1
    ]

    ports: [
        ; Posición libre dentro de 32x32 px
        in  [id: 1  name: 'a       type: 'number  x: 0   y: 10]
        in  [id: 2  name: 'b       type: 'number  x: 0   y: 22]
        out [id: 3  name: 'result  type: 'number  x: 32  y: 16]
    ]

    icon: [
        ; Draw dialect — diseño completamente libre dentro de 32x32
        pen 2
        line 4x16 28x16
        line 16x4 16x28
    ]

    code: [
        result: a + b
    ]
]
```

### `.qproj` — Proyecto

```red
qproj [
    version: 1
    title:   "Mi proyecto"

    files: [
        %main.qvi
        %utils/suma.qvi
        %utils/filtro.qvi
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

### `.qlib` — Librería

Una librería agrupa VIs y primitivas bajo un namespace. Puede contener tanto `.qvi` como `.qprim`.

```red
qlib [
    version: 1
    name:    "math"

    members: [
        %add.qprim
        %subtract.qprim
        %interpolate.qvi
        %fft.qvi
    ]
]
```

Código generado al cargar la librería:

```red
math: context [
    do %math/add.qprim       ; incrusta código de la primitiva
    do %math/subtract.qprim
    do %math/interpolate.qvi  ; define math/interpolate
    do %math/fft.qvi          ; define math/fft
]

; Uso desde otro VI:
math/interpolate datos frecuencia
math/fft señal
```

### `.qctl` — Type definition

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

## MVP

El MVP solo implementa `.qvi` y `.qproj`. Los demás tipos (`.qlib`, `.qprim`, `.qctl`) se añaden en fases posteriores, pero el formato está definido desde el inicio para que la estructura sea consistente.
