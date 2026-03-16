# QTorres

**LabVIEW open source construido sobre Red-Lang.**  
Si sabes programar en LabVIEW, sabes programar en QTorres.

## Qué es

QTorres es un entorno de programación visual donde el programador trabaja con bloques, wires, Front Panel y Block Diagram — exactamente como en LabVIEW. La diferencia: cada diagrama compila a código Red-Lang puro, legible y ejecutable sin QTorres instalado.

### Modelo de ejecución: dataflow

QTorres usa el mismo modelo de ejecución que LabVIEW — **dataflow**:

- Un nodo ejecuta automáticamente cuando todos sus inputs tienen datos disponibles.
- El orden de ejecución lo deduce el sistema del grafo de conexiones, no el programador.
- QTorres compila el grafo dataflow a código Red secuencial ordenado topológicamente.
- La ejecución es **continua en loop** (no single-shot).
- **Paralelismo automático** planificado para cuando Red tenga concurrencia madura — mismo `.qvi`, sin cambios para el usuario.

### El archivo .qvi es un programa completo

Un `.qvi` es un **programa Red válido y directamente ejecutable** con el toolchain estándar de Red, sin dependencias adicionales. Contiene en un único archivo:

- Front Panel (interfaz de usuario)
- Block Diagram (lógica visual)
- Código Red ejecutable generado automáticamente

```bash
red mi-programa.qvi   # abre la ventana del Front Panel directamente
```

### Flujos de trabajo en QTorres

**Al pulsar Run:**
1. QTorres serializa el estado en memoria al `.qvi` en disco
2. Ejecuta el `.qvi` con Red directamente → aparece el Front Panel

**Al pulsar Save:**
- Serializa el estado actual en memoria al `.qvi` asociado

## Tipos de fichero

La estructura de ficheros replica las convenciones de LabVIEW. Donde LabVIEW guarda binarios, QTorres guarda Red en texto plano.

| LabVIEW | QTorres | Descripción |
|---------|---------|-------------|
| `.lvproj` | `.qproj` | Proyecto |
| `.vi` | `.qvi` | Virtual Instrument (front panel + block diagram) |
| `.lvlib` | `.qlib` | Librería |
| `.lvclass` | `.qclass` | Clase |
| `.ctl` | `.qctl` | Type definition |

## Estado

**En desarrollo inicial.** El proyecto está en fase de diseño y prototipado.

## Estructura del proyecto

```
QTorres/
├── docs/                    # Documentación del proyecto
│   ├── plan.md              # Plan de desarrollo por fases
│   ├── retos.md             # Retos, riesgos y dificultades
│   ├── arquitectura.md      # Arquitectura de módulos
│   ├── decisiones.md        # Registro de decisiones técnicas
│   └── tipos-de-fichero.md  # Sistema de ficheros (mapeo LabVIEW → QTorres)
├── src/                     # Código fuente
│   ├── qtorres.red          # Punto de entrada principal
│   ├── graph/               # Modelo del grafo (nodos, wires)
│   │   ├── model.red        # Estructuras de datos
│   │   └── blocks.red       # Registro de tipos de bloques
│   ├── compiler/            # Diagrama → código Red
│   │   └── compiler.red
│   ├── runner/              # Ejecución en memoria
│   │   └── runner.red
│   ├── io/                  # Guardar/cargar .qvi, .qproj
│   │   └── file-io.red
│   └── ui/                  # Interfaz gráfica
│       ├── diagram/         # Block Diagram (canvas)
│       │   └── canvas.red
│       └── panel/           # Front Panel
│           └── panel.red
├── examples/                # Ejemplos
│   ├── ejemplo.qproj        # Proyecto de ejemplo
│   ├── suma-basica.qvi      # VI standalone
│   ├── suma-subvi.qvi       # VI con connector (sub-VI)
│   └── programa-con-subvi.qvi  # VI que usa un sub-VI
├── QTorres.md               # Filosofía y visión del proyecto
└── README.md
```

## Stack

| Capa | Tecnología |
|------|-----------|
| Lenguaje | Red-Lang (100%) |
| UI del diagrama | Red/View + Draw |
| UI del panel | Red/View |
| Compilador | Red puro |
| Formato de fichero | Sintaxis Red nativa |
| Backend Linux | GTK3 (rama `GTK` del repo red/red) |
| Backend Windows | Win32 API nativo |

Sin dependencias externas. Un solo binario.

> **Estado de Red-Lang:** Red está actualmente en alpha stage y es 32-bit. El backend GTK de Linux tiene bugs conocidos que afectan al canvas visual. Ver [`docs/GTK_ISSUES.md`](docs/GTK_ISSUES.md) para el detalle. La estrategia es contribuir los fixes directamente al repo `red/red`, no workarounds locales.

## Nombre

QTorres — por Torres Quevedo.

## Licencia

Por definir.
