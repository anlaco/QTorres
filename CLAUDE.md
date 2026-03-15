# QTorres — Contexto para Claude Code

## Qué es este proyecto

QTorres es una alternativa open source a LabVIEW construida íntegramente en Red-Lang. El usuario construye programas arrastrando bloques y conectándolos con wires, igual que en LabVIEW. Al guardar, QTorres genera un fichero `.qvi` con código Red/View completo que al ejecutarse muestra el Front Panel como una ventana, igual que LabVIEW.

**Nombre:** QTorres (por Torres Quevedo)
**Repositorio:** https://github.com/anlaco/QTorres
**Backlog:** https://github.com/users/anlaco/projects/1

## Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Lenguaje | Red-Lang 100% |
| UI del diagrama | Red/View + Draw dialect |
| UI del panel | Red/View |
| Compilador | Red puro (manipulación de bloques) |
| Formato de fichero | Sintaxis Red nativa |

Sin dependencias externas. Un solo binario. Funciona en Linux, Windows y macOS.

## Estructura del proyecto

```
QTorres/
├── CLAUDE.md               # Este fichero
├── README.md
├── docs/
│   ├── arquitectura.md     # Arquitectura de módulos
│   ├── plan.md             # Plan por fases
│   ├── decisiones.md       # Decisiones técnicas (DT-001 a DT-009)
│   ├── retos.md            # Riesgos y dificultades
│   └── tipos-de-fichero.md # Mapeo LabVIEW → QTorres
├── src/
│   ├── qtorres.red         # Punto de entrada (stub)
│   ├── graph/
│   │   ├── model.red       # Estructuras: make-node, make-wire, make-diagram
│   │   └── blocks.red      # Registro de bloques + dialecto block-def (stub)
│   ├── compiler/
│   │   └── compiler.red    # Compilador (stub documentado)
│   ├── runner/
│   │   └── runner.red      # Runner (stub documentado)
│   ├── io/
│   │   └── file-io.red     # File I/O (stub documentado)
│   └── ui/
│       ├── diagram/
│       │   └── canvas.red  # Block Diagram canvas (stub)
│       └── panel/
│           └── panel.red   # Front Panel (stub)
├── MVP/
│   └── QTorres-mvp.red     # MVP monolítico FUNCIONAL — referencia de implementación
├── examples/
│   ├── suma-basica.qvi     # Ejemplo de VI simple
│   ├── suma-subvi.qvi      # Ejemplo de sub-VI
│   └── programa-con-subvi.qvi
└── red-cli                 # Binario de Red para Linux
```

## Estado actual

**Fase 0 completada.** `src/ui/diagram/canvas.red` implementa los 4 spikes (Issues #1-#4 cerrados):
- Bloques arrastrables con drag & drop
- Wires con routing de punto medio
- Hit testing sobre bloques, puertos y wires
- Stress test con 20 nodos y 15 wires fluido

**El MVP monolítico funciona.** `MVP/QTorres-mvp.red` es referencia de implementación existente.

**Los módulos `src/` son stubs documentados.** La arquitectura está diseñada pero sin implementar.
El objetivo es implementar `src/` de forma modular usando el MVP como referencia.

**Próximo paso: Fase 1.** Empezar por Issue #22 (identidad visual) o Issue #20 (borrar wire/nodo).

## Decisiones técnicas clave

### DT-009 (la más importante para el compilador)
El compilador genera **Red/View completo** para VIs principales, NO código de terminal.
Al ejecutar `red mi-programa.qvi` debe aparecer una ventana con el Front Panel.

Ejemplo de lo que debe generar el compilador:
```red
Red [title: "mi-programa" Needs: 'View]

qvi-diagram: [...] ; cabecera gráfica (inerte para Red)

view layout [
    label "A"    fA: field "5.0"
    label "B"    fB: field "3.0"
    button "Run" [
        A: to-float fA/text
        B: to-float fB/text
        Resultado: A + B
        lResultado/text: form Resultado
    ]
    label "Resultado:"  lResultado: text "---"
]
```

### DT-008: Tres dialectos Red propios
1. **block-def** — define tipos de bloques declarativamente (`src/graph/blocks.red`)
2. **qvi-diagram** — describe la estructura de un VI (cabecera del `.qvi`)
3. **emit** — define qué código Red genera cada bloque al compilar

### DT-005: El .qvi tiene dos secciones
1. `qvi-diagram: [...]` — cabecera gráfica (inerte para Red, usada por QTorres para reconstruir la vista)
2. Código Red/View generado — ejecutable directamente con `red mi-vi.qvi`

### DT-006: Sub-VIs
Los VIs con connector pane generan una `func` Red con guarda `qtorres-runtime`.
Los VIs principales generan Red/View con ventana.

## Flujo de trabajo

### Cómo trabajar un Issue
1. Leer el Issue en GitHub (`gh issue view N --repo anlaco/QTorres`)
2. Implementar en el módulo correspondiente de `src/`
3. Usar `MVP/QTorres-mvp.red` como referencia de implementación existente
4. Verificar con los ejemplos de `examples/`
5. Cerrar el Issue cuando esté completo (`gh issue close N --repo anlaco/QTorres`)

### Orden de los Issues (backlog)
Trabajar siempre en orden de Fase. No empezar Fase 1 sin completar Fase 0.

**Fase 0 — Spike técnico ✅ COMPLETADA (Issues #1-#4 CERRADOS)**

**Fase 1 — Beta funcional (Issues #5-#13, #20-#22):**
- #20 Borrar wire/nodo con Delete ← EMPEZAR AQUÍ (edición básica)
- #21 Renombrar nodo con doble clic
- #22 Identidad visual: diseño de bloques moderno
- #5 Procesador dialecto block-def
- #6 Topological-sort
- #7 bind-emit
- #8 Compilador genera Red/View (DT-009)
- #9 save-vi y load-vi
- #10 Runner en memoria
- #11 Canvas modular
- #12 Front Panel modular
- #13 Conectar módulos en qtorres.red

**Fase 2 — Tipos de datos y estructuras (Issues #15-#17, #23-#27):**
- #23 Tipo booleano
- #24 Tipo string
- #25 Array 1D
- #26 Cluster
- #27 Waveform chart y graph
- #15 While Loop
- #16 For Loop
- #17 Case Structure

**Fase 3 — Sub-VIs y extensibilidad (Issues #18-#19):**
- #18 Sub-VI con connector pane
- #19 Librería .qlib

**Fase 4 — Hardware (Issues #28-#32):**
- #28 SCPI sobre TCP/IP (Keysight por red)
- #29 SCPI sobre USB/USBTMC (Keysight por USB)
- #30 Puerto serie RS-232/RS-485 (Arduino, ESP32)
- #31 TCP/IP genérico (Modbus TCP, protocolos propios)
- #32 DAQ analógico (comedi/libcomedi)

## Comandos útiles

```bash
# Ejecutar el MVP
red MVP/QTorres-mvp.red

# Ejecutar un ejemplo
red examples/suma-basica.qvi

# Ver Issues pendientes
gh issue list --repo anlaco/QTorres --label "fase-0"

# Ver un Issue concreto
gh issue view 1 --repo anlaco/QTorres

# Cerrar un Issue
gh issue close 1 --repo anlaco/QTorres --comment "Implementado en src/ui/diagram/canvas.red"
```

## Convenciones de código

- Todo en Red-Lang, sin excepciones (DT-001)
- Los ficheros `.qvi`, `.qproj` etc. son bloques Red válidos (DT-002)
- Los dialectos usan `parse` de Red, nunca interpolación de strings (DT-008)
- El compilador manipula bloques Red, nunca genera strings intermedios

## Documentación de referencia

- Arquitectura completa: `docs/arquitectura.md`
- Plan por fases: `docs/plan.md`
- Todas las decisiones técnicas: `docs/decisiones.md`
- Riesgos conocidos: `docs/retos.md`
