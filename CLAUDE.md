# QTorres — Contexto para Claude Code

> Última actualización: 2026-03-31

## Reglas absolutas — NUNCA violar

Estas reglas son inviolables. No importa qué Issue estés implementando ni qué parezca razonable.
**Si alguna de tus acciones viola cualquiera de estas reglas, PARA y replantea.**

1. **NUNCA** poner faces nativas (`field`, `button`, `slider`) en el `pane` del canvas del editor. Renderizar TODO con Draw sobre `base`. (DT-026)
2. **PROHIBIDO** `do` con bloques dinámicos, `load` de strings, o `compose` en runtime del `.qvi` generado. El código generado debe compilar con `red -c`. (DT-028)
3. **Todo** en Red-Lang, sin excepciones. Sin dependencias externas. (DT-001)
4. **NUNCA** usar herencia profunda (A → B → C). Composición + prototipos + constructores siempre. (DT-023)
5. **NUNCA** implementar zoom en el canvas. (visual-spec 1.1)
6. **NUNCA** permitir múltiples wires a un puerto de entrada. (visual-spec 5.2)
7. **NUNCA** generar strings intermedios en el compilador. Siempre manipular bloques Red. (DT-008)
8. **NUNCA** empezar una fase sin completar la anterior. Respetar el orden del backlog.
9. **SIEMPRE** implementar dentro de los ficheros existentes en `src/`. No crear módulos nuevos sin aprobación explícita.
10. **SIEMPRE** ejecutar los tests (`red-cli tests/run-all.red`) tras cada cambio. No commitear con tests rotos.
11. **SIEMPRE** consultar el skill de Red-Lang (`skills/red-lang/SKILL.md`) antes de escribir código Red, especialmente Draw y View.
12. **SIEMPRE** respetar la separación de responsabilidades entre módulos (ver sección "Problemas conocidos de arquitectura").

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
├── CLAUDE.md               # Este fichero — contexto principal para IA
├── README.md
├── docs/
│   ├── arquitectura.md     # Arquitectura de módulos
│   ├── plan.md             # Plan por fases
│   ├── decisiones.md       # Decisiones técnicas (DT-001 a DT-029)
│   ├── PLANNING.md         # Decisiones pendientes críticas
│   ├── retos.md            # Riesgos y dificultades
│   ├── visual-spec.md      # Especificación visual (documento vivo)
│   ├── tipos-de-fichero.md # Mapeo LabVIEW → QTorres
│   ├── labview-comportamiento.md # Arquitectura LabVIEW: renderizado, modos, estilos
│   └── GTK_ISSUES.md       # Bugs del backend GTK en Linux
├── src/
│   ├── qtorres.red         # Punto de entrada + toolbar + ventana principal
│   ├── graph/
│   │   ├── model.red       # Modelo: make-label, make-node, make-wire, make-fp-item, set-config, find-node-by-id (635 líneas)
│   │   └── blocks.red      # Registro de bloques + dialecto block-def — 40 bloques
│   ├── compiler/
│   │   └── compiler.red    # Compilador: topo-sort, bind-emit, compile-body/diagram/panel (1165 líneas)
│   ├── runner/
│   │   └── runner.red      # Runner: ejecución en memoria con do
│   ├── io/
│   │   └── file-io.red     # File I/O: serialize, format, save/load .qvi, save/load-panel (738 líneas)
│   └── ui/
│       ├── diagram/
│       │   ├── canvas.red          # BD canvas: hit-test, CRUD, actor render-diagram (1233 líneas)
│       │   ├── canvas-render.red   # Render puro BD: constantes, geometría, Draw (934 líneas)
│       │   └── canvas-dialogs.red  # Diálogos edición, paleta, SR helpers (413 líneas)
│       └── panel/
│           ├── panel.red           # FP: hit-test, diálogos, paleta, actor render-panel (570 líneas)
│           └── panel-render.red    # Render puro FP: constantes, Draw, waveform (411 líneas)
├── tests/
│   ├── run-all.red         # Runner de tests automatizados
│   ├── test-blocks.red     # Tests del registro de bloques (40 bloques, puertos, emit)
│   ├── test-topo.red       # Tests de topological sort (lineal, diamante, vacío, ciclos)
│   ├── test-model.red      # Tests del modelo (make-node, make-wire, make-frame, make-structure)
│   └── test-compiler.red   # Tests del compilador (bind-emit, compile-body, round-trip, estructuras)
├── examples/
│   ├── suma-basica.qvi         # Ejemplo de VI simple
│   ├── while-loop-basico.qvi   # While Loop básico
│   ├── while-loop-suma.qvi     # While Loop con shift registers
│   ├── for-loop-basico.qvi     # For Loop (suma 0..9 = 45)
│   ├── case-numeric.qvi        # Case Structure con selector numérico
│   ├── case-boolean.qvi        # Case Structure con selector booleano (either)
│   ├── suma-subvi.qvi          # Ejemplo de sub-VI
│   └── programa-con-subvi.qvi
├── .github/workflows/      # CI: tests automáticos en push/PR a main
├── red-cli                 # Ejecutar código Red sin GUI
└── red-view                # Ejecutar código Red con GUI (View)
```

## Estado actual

**Fase 0 ✅ COMPLETADA.** Spike técnico validado (Issues #1-#4 cerrados).

**Fase 1 ✅ COMPLETADA.** Pipeline end-to-end funcional:
- Modelo de datos con composición (DT-022/023/024)
- 40 bloques registrados (math, I/O, boolean, compare, string, array, cluster, estructuras, waveform)
- Compilador con topo-sort (Kahn) y generación Red/View
- Runner en memoria, File I/O con round-trip, Front Panel con Draw
- Tests automatizados + CI en GitHub Actions

**Fase 2 ✅ COMPLETADA (pendiente merge PR#60).** Tipos de datos y estructuras de control:
- ~~#9 Tipo booleano~~ ✅
- ~~#10 Tipo string~~ ✅
- ~~#14 While Loop~~ ✅ (con shift registers)
- ~~#15 For Loop~~ ✅
- ~~#11 Array 1D~~ ✅ (bloques arr-const, build-array, index-array, array-size, array-subset)
- ~~#16 Case Structure~~ ✅
- ~~#12 Cluster~~ ✅
- ~~#13 Waveform Chart y Graph~~ ✅
- ~~#54 Cluster persiste campos~~ ✅  ~~#48/#50/#51 bugs menores~~ ✅
- QA-018/029: protecciones de integridad ✅
- Refactor 4A-4E: responsabilidades reorganizadas, ficheros grandes divididos ✅
- 462 tests PASS

**Fase 3 — Sub-VIs y extensibilidad (en curso):**
- ~~#17 Sub-VI con connector pane~~ ✅ (pin-based connector, compile-subvi-call, runner carga contextos, btn-run sincronizado)
- #18 Librería .qlib

**Próximo paso:** #18 Librería .qlib

## Decisiones técnicas clave

### DT-026 — CRÍTICO: NO usar widgets nativos en el editor del Front Panel

**El editor (panel.red) renderiza TODO con Draw dialect sobre `base` face. NUNCA poner faces reales (`field`, `button`, `slider`) en el `pane` del canvas del editor.**

Por qué: Red/View usa widgets nativos del SO. Un `field` en el `pane` de un `base` intercepta TODOS los eventos de ratón en su área — hace imposible drag, resize, select y delete. Se intentó en 3 rondas de fixes sin éxito. LabVIEW usa un engine de renderizado propio (por eso puede hacerlo) — Red/View no.

- Edición de valores por defecto: usar `view/no-wait` con diálogo (patrón ya establecido en panel.red)
- Edición inline con cursor: **Fase 2** — widget Draw-based propio (ver DT-026 en decisiones.md)
- En el `.qvi` compilado: sí se pueden usar `field` nativos (no hay editor compitiendo)

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

### DT-010: Runner en memoria (decisión clave)
Run compila en memoria y ejecuta con `do`. Save escribe el `.qvi` al disco. Son independientes.

### DT-011: qvi-diagram es la fuente de verdad
El código generado es un artefacto. QTorres siempre recompila desde `qvi-diagram` al cargar.
Un `.qvi` con solo `qvi-diagram` (sin código generado) es válido.

### DT-017: El tipo de VI lo determina el contexto de llamada
Cualquier VI con `connector` puede ser sub-VI o top-level según cómo se invoque.
La presencia de `connector` en `qvi-diagram` habilita el uso como sub-VI.

### DT-022: Label como objeto propio
La label es un `object!` con `text`, `visible`, `offset`. Se compone en nodos, wires y fp-items.
Acceso: `n/label/text`, `n/label/visible`.

### DT-023: Composición sobre herencia
Prototipo `base-element` + constructores `make-node`, `make-wire`. Patrón idiomático de Red.

### DT-024: Name estático + Label libre
`name` = identificador inmutable para el compilador (tipo_N: `ctrl_1`, `add_1`).
`label/text` = texto visual libre, editable por el usuario, duplicados OK.
Son independientes. El compilador usa `name`, la UI usa `label/text`.

### DT-027 — CRÍTICO: Concurrencia cooperativa (rate/on-time)
Red no tiene multihilo. QTorres simula concurrencia con timers de Red/View:
- While Loop = timer (`face/rate` + `on-time`) que ejecuta una iteración por tick
- Múltiples loops = múltiples timers independientes, Red despacha en round-robin
- Event Structure = timer que comprueba cola de eventos
- Notifiers = `object!` compartido entre callbacks
- Fase 2: `do-events` intercalado. Fase 2.5: migrar a timers. Fase 3: notifiers.
- **El código generado es agnóstico al modelo de concurrencia** — si Red añade actors/CSP, se reemplaza sin cambiar la arquitectura.

### DT-028 — CRÍTICO: Compilabilidad (cero código dinámico)
El `.qvi` generado **debe compilarse** con `red -c` a ejecutable nativo.
- **PROHIBIDO** en código generado: `do` con bloques dinámicos, `load` de strings, `compose` en runtime
- **PERMITIDO**: `view layout [...]` estático, funciones con nombre, `face/rate` + `on-time`
- `compose` se ejecuta en el compilador de QTorres (al generar), NO en el `.qvi` generado

### DT-029: Error handling progresivo
- **Nivel 0 (Fase 2)**: Error nativo de Red — programa se para. Sin cables de error.
- **Nivel 1 (Fase 3)**: `try/catch` por nodo en sub-VIs. Error se propaga por orden topológico.
- **Nivel 2 (Fase 4)**: Error cluster completo — puertos `error-in`/`error-out`, wire amarillo, imprescindible para hardware.
- El modelo de datos **ya permite** puertos de tipo `'error`. No hay deuda técnica por esperar.

### Formato completo del qvi-diagram
```red
qvi-diagram: [
    meta:         [description: "..." version: 1 author: "..." tags: [...]]
    icon:         [; Draw dialect 32x32]
    connector:    [; opcional — habilita uso como sub-VI]
    front-panel:  [
        control   [id: 1  type: 'numeric  name: "ctrl_1"  label: [text: "A"]  default: 5.0]
        indicator [id: 2  type: 'numeric  name: "ind_1"   label: [text: "Resultado"]]
    ]
    block-diagram: [
        nodes: [
            node [id: 1  type: 'control  x: 40  y: 80  name: "ctrl_1"  label: [text: "A" visible: true]]
            node [id: 3  type: 'add      x: 200 y: 120 name: "add_1"   label: [text: "Add"]]
        ]
        wires: [
            wire [from: 1  port: 'out  to: 3  port: 'a]
        ]
    ]
]
```

## Flujo de trabajo

### Cómo trabajar un Issue
1. Leer el Issue en GitHub (`gh issue view N --repo anlaco/QTorres`)
2. Implementar en el módulo correspondiente de `src/`
3. Verificar con los ejemplos de `examples/`
4. Ejecutar los tests (`red-cli tests/run-all.red`) y verificar que pasan
5. Cerrar el Issue cuando esté completo (`gh issue close N --repo anlaco/QTorres`)

### Orden de los Issues (backlog)
Trabajar siempre en orden de Fase. No empezar una fase sin completar la anterior.

**Fase 0 — Spike técnico ✅ COMPLETADA**

**Fase 1 — Beta funcional ✅ COMPLETADA**
- Issues cerrados: #6 (renombrar nodo), #7 (Front Panel), #8 (conectar módulos), #26 (.qvi formato)
- Identidad visual: especificación en `docs/visual-spec.md` (documento vivo, se aplica progresivamente)

**Fase 2 — Tipos de datos y estructuras (orden decidido 2026-03-22):**
1. ~~#9 Tipo booleano~~ ✅
2. ~~#10 Tipo string~~ ✅
3. ~~#14 While Loop~~ ✅ (con shift registers)
4. ~~#15 For Loop~~ ✅
5. ~~#11 Array 1D~~ ✅
6. ~~#16 Case Structure~~ ✅ (PR#46 pendiente merge)
7. ~~#12 Cluster~~ ✅ (PR pendiente de merge)
8. ~~#13 Waveform chart y graph~~ ✅
9. #28 Front Panel standalone (pospuesto a Fase 3)

**Bugs detectados en pruebas (Fase 2):**
- #48 Bundle/Unbundle vacíos tienen altura excesiva (`canvas.red`)
- #49 Control string se auto-actualiza sin Run tras el primer Run (`panel.red`, GTK-010)
- #50 Modo headless no imprime valores de indicadores en VIs generados desde la UI (`compiler.red`)
- #51 Nodos creados desde FP se apilan y salen del canvas (pre-existente)

Estrategia QA: tests con cada feature nueva, no sesión QA dedicada.
Spec visual: cada tipo implementa su aspecto según `docs/visual-spec.md`.

**Fase 3 — Sub-VIs y extensibilidad:**
- #17 Sub-VI con connector pane
- #18 Librería .qlib

**Fase 4 — Hardware:**
- #19 SCPI sobre TCP/IP (Keysight por red)
- #20 SCPI sobre USB/USBTMC (Keysight por USB)
- #21 Puerto serie RS-232/RS-485 (Arduino, ESP32)
- #22 TCP/IP genérico (Modbus TCP, protocolos propios)
- #23 DAQ analógico (comedi/libcomedi)

## Ollama MCP — Delegación de tareas a modelo local

QTorres tiene un MCP server que conecta con Ollama (modelo local). Ollama tiene cargado automáticamente CLAUDE.md y el skill de Red-Lang como contexto del proyecto.

### Cuándo usar Ollama (herramienta `ollama_delegate`)

**USAR para:**
- **Generar código Red mecánico** — emit de bloques, funciones simples, boilerplate. Ollama tiene el SKILL.md y genera código idiomático.
- **Revisar ficheros grandes** — `ollama_review_file` o `ollama_explain_file` lee el fichero server-side sin gastar tokens de Claude. Ideal para canvas.red (2383 líneas).
- **Verificar convenciones** — "¿este código cumple las reglas del proyecto?"
- **Tareas repetitivas** — generar tests, formatear datos, transformar estructuras.

**NO USAR para:**
- **Decisiones de arquitectura** — Ollama no razona bien sobre trade-offs complejos.
- **Debugging** — necesita ver el contexto completo de ejecución, que no tiene.
- **Modificar ficheros** — Ollama no puede escribir ficheros, solo genera texto. Claude debe aplicar los cambios.
- **Tareas que requieren leer múltiples ficheros + razonar sobre relaciones** — Haiku/Sonnet via Agent son mejores.

### Parámetros clave de `ollama_delegate`

| Parámetro | Uso |
|-----------|-----|
| `task` | Instrucción clara y específica. Cuanto más precisa, mejor resultado. |
| `files` | Rutas absolutas de ficheros que Ollama lee server-side (0 tokens para Claude). |
| `response_format` | `"concise"` (por defecto), `"detailed"`, o `"code_only"` (solo código). |
| `context` | Contexto adicional que Ollama necesita más allá de CLAUDE.md/SKILL.md. |

### Ejemplo de uso correcto

```
ollama_delegate(
  task: "Escribe el block-def para un bloque 'divide' con puertos a, b → out, emit que genere división",
  response_format: "code_only"
)
```

### Configuración

El contexto se define en `.ollama-context.json` en la raíz del proyecto:
```json
{
  "context_files": ["./CLAUDE.md", "./skills/red-lang/SKILL.md"],
  "system_prompt": "You are a coding assistant for QTorres..."
}
```

El MCP server se lanza con la ruta del proyecto como argumento (configurado en `.claude.json`).

## Comandos útiles

```bash
# Ejecutar un ejemplo
red examples/suma-basica.qvi

# Ejecutar tests automatizados
red-cli tests/run-all.red

# Ejecutar la aplicación completa
red-view src/qtorres.red

# Ver Issues pendientes
gh issue list --repo anlaco/QTorres --label "fase-2"

# Ver un Issue concreto
gh issue view 14 --repo anlaco/QTorres

# Cerrar un Issue
gh issue close 14 --repo anlaco/QTorres --comment "Implementado en src/..."
```

## Convenciones de código

- Todo en Red-Lang, sin excepciones (DT-001)
- Los ficheros `.qvi`, `.qproj` etc. son bloques Red válidos (DT-002)
- Los dialectos usan `parse` de Red, nunca interpolación de strings (DT-008)
- El compilador manipula bloques Red, nunca genera strings intermedios

## Skill de Red-Lang

El proyecto incluye un skill completo de Red-Lang en `skills/red-lang/SKILL.md`.
Cubre sintaxis core, View, Draw, VID, Parse, patrones idiomáticos y gotchas.
**Consultar antes de escribir cualquier código Red**, especialmente Draw y View.

## Documentación de referencia

- Arquitectura completa: `docs/arquitectura.md`
- Plan por fases: `docs/plan.md`
- Todas las decisiones técnicas: `docs/decisiones.md` — **leer antes de implementar**
- Decisiones pendientes: `docs/PLANNING.md` — **leer antes de tocar compilador o file-io**
- Formato de ficheros: `docs/tipos-de-fichero.md`
- Riesgos conocidos: `docs/retos.md`
- Bugs GTK Linux: `docs/GTK_ISSUES.md`
- **Arquitectura LabVIEW:** `docs/labview-comportamiento.md` — **leer antes de tomar decisiones sobre renderizado de widgets, modos edit/run, o controles custom**

## Problemas conocidos de arquitectura

> **Estas deudas técnicas son conocidas y aceptadas.** Se corregirán en refactorings planificados.
> Mientras tanto, una IA NO debe agravar estos problemas al implementar nuevas features.

### Responsabilidades mal ubicadas

> **Refactor 4A completado (2026-04-08, PR #60):** Las responsabilidades más críticas ya están en sus módulos correctos.

| Función | Movida a | Estado |
|---------|----------|--------|
| `compile-panel`, `gen-panel-var-name`, `gen-standalone-code` | `compiler.red` | ✅ Movida |
| `save-panel-to-diagram`, `load-panel-from-diagram` | `file-io.red` | ✅ Movida |
| `make-diagram-model` | `model.red` | ✅ Movida |
| `make-fp-item`, `fp-cluster-fields`, `fp-default-label` | `model.red` | ✅ Movida |
| `find-node-by-id` | `model.red` | ✅ Añadida |
| `set-config` | `model.red` | ✅ Añadida |
| Lógica de `btn-run` (50+ líneas inline) | qtorres.red | ⚠️ Pendiente Fase 3 |

### Dependencia canvas.red <-> panel.red

- `canvas.red` llama a `render-fp-panel` (definida en panel.red)
- `panel.red` llama a `render-bd`, `gen-node-id` (definidas en canvas-render.red)

El acoplamiento es **por diseño del dominio** (FP↔BD son una unidad 1:1) y no es deuda técnica.
- **Regla para IA:** NO agravar esta dependencia. Usar el patrón existente para sincronizar BD↔FP.

### Ficheros y tamaños (2026-04-08)

| Fichero | Líneas | Contenido |
|---------|--------|-----------|
| canvas.red | 1226 | Hit-test, CRUD, actor render-diagram |
| canvas-render.red | 932 | Constantes visuales, geometría, Draw |
| canvas-dialogs.red | 397 | Diálogos de edición, paleta, SR helpers |
| panel.red | 535 | Hit-test, diálogos FP, paleta FP, actor |
| panel-render.red | 411 | Constantes FP, render Draw, waveform |
| compiler.red | 1029 | compile-diagram + compile-panel + estructuras |
| file-io.red | 738 | serialize, save/load .qvi, save/load panel |
| model.red | 635 | Constructores, helpers, find-node-by-id, set-config |

**Regla para IA:** Al trabajar en canvas.red o panel.red y sus submódulos, leer el fichero COMPLETO antes de hacer cambios.

### Abstracciones pendientes

1. **Conocimiento de tipos disperso** — El comportamiento por tipo (`bool-const`, `str-const`, etc.) está hardcodeado en canvas-render.red, panel-render.red, compiler.red y blocks.red. Añadir un tipo nuevo requiere tocar 4+ ficheros. blocks.red debería llevar hints de renderizado/compilación.

### Estado global compartido

`app-model` (definido en qtorres.red) es el único modelo compartido. canvas.red, panel.red y qtorres.red lo leen y mutan a través de `face/extra`. No hay mecanismo de notificación.

### Plan de corrección (pendiente Fase 3)

1. Centralizar conocimiento de tipos en blocks.red (hints de renderizado)
2. Extraer lógica de `btn-run` a función nombrada en qtorres.red
