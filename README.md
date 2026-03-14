# QTorres

**LabVIEW open source construido sobre Red-Lang.**  
Si sabes programar en LabVIEW, sabes programar en QTorres.

## Qué es

QTorres es un entorno de programación visual donde el programador trabaja con bloques, wires, Front Panel y Block Diagram — exactamente como en LabVIEW. La diferencia: cada diagrama compila a código Red-Lang puro, legible y ejecutable sin QTorres instalado.

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

Sin dependencias externas. Un solo binario.

## Nombre

QTorres — por Torres Quevedo.

## Licencia

Por definir.
