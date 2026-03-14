# Tipos de fichero — QTorres

QTorres replica la estructura de ficheros de LabVIEW. Un usuario de LabVIEW reconoce la organización al instante. La diferencia: donde LabVIEW guarda binarios opacos, QTorres guarda Red en texto plano.

## Mapeo LabVIEW → QTorres

| LabVIEW | QTorres | Descripción |
|---------|---------|-------------|
| `.lvproj` | `.qproj` | Proyecto — referencias a ficheros, configuración de build, targets |
| `.vi` | `.qvi` | Virtual Instrument — front panel + block diagram (la unidad fundamental) |
| `.lvlib` | `.qlib` | Librería — colección de VIs agrupados bajo un namespace |
| `.lvclass` | `.qclass` | Clase — datos + métodos (VIs miembro) |
| `.ctl` | `.qctl` | Type definition — control/indicador personalizado reutilizable |

## Principio fundamental

**Todo fichero `.qvi` es código Red ejecutable.** Contiene dos secciones:

1. **Cabecera gráfica** (`qvi-diagram: [...]`): la representación completa del Front Panel y Block Diagram. QTorres la lee para reconstruir la vista visual. Para Red es una simple asignación sin efectos secundarios.
2. **Código generado**: código Red puro, generado automáticamente por QTorres al guardar. Es el resultado de compilar el diagrama.

Un `.qvi` se puede ejecutar de dos formas:
- **Con QTorres:** abre la UI, muestra Front Panel y Block Diagram, permite editar y ejecutar interactivamente.
- **Con Red directamente:** `red mi-vi.qvi` ejecuta el código generado como un script. La cabecera se ignora (es solo una asignación a una variable).

No hay formatos binarios, no hay parsers especiales. Todo es Red.

## Estructura de un proyecto típico

```
mi-proyecto/
├── mi-proyecto.qproj        # Proyecto
├── main.qvi                  # VI principal
├── utilidades.qlib           # Librería
│   ├── escalar.qvi           # VI dentro de la librería
│   └── filtro.qvi
├── sensor.qclass             # Clase
│   ├── sensor.qctl           # Type definition de la clase
│   ├── init.qvi              # Constructor
│   ├── leer.qvi              # Método
│   └── cerrar.qvi            # Método
└── tipos/
    └── config-datos.qctl     # Type definition independiente
```

Esto es exactamente lo que un usuarios de LabVIEW espera ver en el Project Explorer.

## Formato interno de cada tipo

### `.qvi` — Virtual Instrument

Un `.qvi` standalone (VI principal o sin sub-VIs):

```red
Red [title: "Suma básica"]

; ── CABECERA GRÁFICA ─────────────────────────────
; QTorres lee esta sección para reconstruir la vista.
; Para Red es solo una asignación sin efectos.

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

; ── CÓDIGO GENERADO ──────────────────────────────
; Generado por QTorres al guardar. Ejecutable con Red directamente.

A: 5.0
B: 3.0
Resultado: A + B
print Resultado
```

Un `.qvi` con **connector pane** (usado como sub-VI dentro de otros VIs):

```red
Red [title: "suma"]

qvi-diagram: [
    connector: [
        input  [id: 1  label: "A"]
        input  [id: 2  label: "B"]
        output [id: 3  label: "Resultado"]
    ]
    front-panel: [
        control   [id: 1  type: 'numeric  label: "A"         default: 5.0]
        control   [id: 2  type: 'numeric  label: "B"         default: 3.0]
        indicator [id: 3  type: 'numeric  label: "Resultado"]
    ]
    block-diagram: [...]
]

; ── CÓDIGO GENERADO ──────────────────────────────
; El connector convierte el VI en una función Red.

suma: func [A [float!] B [float!]] [
    Resultado: A + B
    Resultado
]

; Ejecución standalone — solo cuando se ejecuta directamente con Red
if not value? 'qtorres-runtime [
    A: 5.0
    B: 3.0
    print suma A B
]
```

**La diferencia clave:** cuando un VI tiene connector, el código generado se envuelve en una función Red. Esto permite que otro VI lo llame con `do %suma.qvi` y luego use `suma X Y`. La variable `qtorres-runtime` distingue entre ejecución directa (`red suma.qvi` → corre como script) y carga como sub-VI (`do %suma.qvi` dentro de QTorres → solo define la función).

### `.qvi` como sub-VI (dentro de otro VI)

```red
Red [title: "mi-programa"]

qvi-diagram: [
    front-panel: [
        control   [id: 1  type: 'numeric  label: "X"       default: 10.0]
        control   [id: 2  type: 'numeric  label: "Y"       default: 4.0]
        indicator [id: 3  type: 'numeric  label: "Total"]
    ]
    block-diagram: [
        nodes: [
            node [id: 1   type: 'control    label: "X"]
            node [id: 2   type: 'control    label: "Y"]
            node [id: 10  type: 'subvi      file: %suma.qvi]
            node [id: 3   type: 'indicator  label: "Total"]
        ]
        wires: [
            wire [from: 1   port: 'out        to: 10  port: 'A]
            wire [from: 2   port: 'out        to: 10  port: 'B]
            wire [from: 10  port: 'Resultado  to: 3   port: 'in]
        ]
    ]
]

; ── CÓDIGO GENERADO ──────────────────────────────
do %suma.qvi           ; carga y define la función `suma`

X: 10.0
Y: 4.0
Total: suma X Y        ; el sub-VI es una llamada a función Red
print Total
```

### `.qproj` — Proyecto

```red
qproj [
    version: 1
    title: "Mi proyecto"
    
    files: [
        %main.qvi
        %utilidades.qlib
        %sensor.qclass
    ]

    build: [
        target: 'executable
        entry: %main.qvi
    ]
]
```

### `.qlib` — Librería

La librería agrupa VIs bajo un namespace. El código generado usa `context` de Red para aislar los nombres. Esto evita colisiones: `utilidades/suma` y `matematica/suma` coexisten sin problema.

En LabVIEW un VI en una librería se ve como `Utilidades.lvlib » Suma.vi`. En QTorres se accede como `utilidades/suma`.

```red
qlib [
    version: 1
    name: "utilidades"
    
    members: [
        %escalar.qvi
        %filtro.qvi
    ]
]
```

Código generado al cargar la librería:

```red
utilidades: context [
    do %utilidades/escalar.qvi    ; define escalar dentro del context
    do %utilidades/filtro.qvi     ; define filtro dentro del context
]

; Uso desde otro VI:
utilidades/escalar valor factor
utilidades/filtro señal frecuencia
```

### `.qclass` — Clase

```red
qclass [
    version: 1
    name: "sensor"
    
    data: %sensor.qctl
    
    members: [
        %init.qvi        ; constructor
        %leer.qvi         ; método público
        %cerrar.qvi       ; método público
    ]
]
```

### `.qctl` — Type definition

```red
qctl [
    version: 1
    name: "config-datos"
    
    fields: [
        campo [name: "sampling-rate"  type: 'number  default: 1000.0]
        campo [name: "canal"          type: 'string  default: "AI0"]
        campo [name: "activo"         type: 'logic   default: true]
    ]
]
```

## MVP

El MVP solo implementa `.qvi` y `.qproj`. Los demás tipos (`.qlib`, `.qclass`, `.qctl`) se añaden en fases posteriores, pero el formato está definido desde el inicio para que la estructura sea consistente.
