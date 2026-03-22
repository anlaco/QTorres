# Findings — Fase 2: Tipos de datos y estructuras de control

## Auditoría Post-Fase 1 (2026-03-21)

### Problemas Críticos (resolver en Sprint 0)

| ID | Problema | Módulos | Riesgo |
|----|---------|---------|--------|
| C1 | `make-fp-item` y `fp-value-text` duplicados en model.red y panel.red | model.red, panel.red | La IA editará el que no se ejecuta |
| C2 | `in-ports`/`out-ports`/`ncolor` hardcodeados, duplican block-registry | canvas.red | Fallo silencioso al añadir tipo nuevo |
| C3 | Wires inline sin `make-wire` (sin campo `label`) | canvas.red | Crash al acceder wire/label |
| A3 | Shims control/indicator en qtorres.red en vez de blocks.red | qtorres.red | Tests sin qtorres.red fallan |

### Deuda Técnica No-Crítica

| ID | Problema | Impacto |
|----|---------|---------|
| A1 | `compile-diagram` monolítica (80 líneas, 3 responsabilidades) | Difícil extender para nuevos tipos |
| A2 | `format-qvi` con parser de índices manuales (`i: i + 3`) | Widget nuevo requiere entender máquina de estados |
| M1 | Estado global mutable para diálogos (view/no-wait) | No peligroso con 1 instancia |
| M2 | Demo code mezclado con producción en canvas.red y panel.red | Confusión lectura |
| M3 | Sin tests de FP (make-fp-item, render, save/load) | Errores se detectan solo visual |

### Métricas del Codebase

| Módulo | LOC | Complejidad | Riesgo IA |
|--------|-----|-------------|-----------|
| model.red | 326 | Baja | Bajo |
| blocks.red | 126 | Baja | Bajo |
| compiler.red | 280 | Media | Medio |
| runner.red | 31 | Mínima | Bajo |
| file-io.red | 287 | Alta | Alto |
| canvas.red | 642 | Alta | Alto |
| panel.red | 568 | Alta | Alto |
| qtorres.red | 236 | Media | Medio |

**Total:** ~2,934 LOC producción + 568 LOC tests. 53 tests PASS.

## Decisiones de Arquitectura para Fase 2

| Decisión | Razón |
|----------|-------|
| Sprint 0 Cleanup antes de cualquier feature | Sin limpieza, agentes van a producir código inconsistente |
| Boolean y String antes de control structures | Tipos son auto-contenidos; while/for/case son paradigm shift |
| Array 1D y Charts → Fase 2b | Demasiado alcance para una fase; control structures ya son un salto |
| `color` en block-registry | Elimina hardcoding en canvas, auto-renderiza tipos nuevos |
| Guard de tipo en wire-connect | Prerequisito para multi-tipo, previene wires inválidos |

## Issue #9 — Tipo Booleano: Hallazgos de Implementación (2026-03-22)

### Bloques nuevos a añadir (blocks.red)

| Nombre       | Categoría | Inputs                     | Outputs          | Emit                  |
|--------------|-----------|----------------------------|------------------|-----------------------|
| bool-const   | input     | —                          | result 'boolean  | [result: default]     |
| bool-control | input     | —                          | result 'boolean  | [result: default]     |
| bool-indicator | output  | value 'boolean             | —                | —                     |
| and-op       | logic     | a 'boolean, b 'boolean     | result 'boolean  | [result: a and b]     |
| or-op        | logic     | a 'boolean, b 'boolean     | result 'boolean  | [result: a or b]      |
| not-op       | logic     | a 'boolean                 | result 'boolean  | [result: not a]       |
| gt-op        | compare   | a 'number, b 'number       | result 'boolean  | [result: a > b]       |
| lt-op        | compare   | a 'number, b 'number       | result 'boolean  | [result: a < b]       |
| eq-op        | compare   | a 'number, b 'number       | result 'boolean  | [result: a = b]       |

### Función port-out-type / port-in-type (nueva en canvas.red)

Necesaria para wire color y guard. Lookup: `find-block node/type` → buscar port por nombre → devolver `p/type`.
Default seguro: `'number` si no se encuentra.

### Wire color por tipo (canvas.red)

- Añadir constante `col-wire-bool: 20.80.160` (azul oscuro, estilo LabVIEW)
- En `render-bd`: buscar tipo del puerto de salida del nodo fuente → elegir color
- El wire seleccionado siempre usa `col-wire-sel` (cian) independientemente del tipo

### Guard de tipo en on-down (canvas.red, línea ~413)

- Antes de `append model/wires make-wire`: comprobar que tipo fuente = tipo destino
- Si incompatible: limpiar wire-src sin crear wire (silencioso, sin popup)

### Panel.red — make-fp-item con data-type

- Añadir campo `data-type: any [select spec 'data-type 'numeric]` en make-fp-item
- `render-fp-item`: si `item/data-type = 'boolean` → dibujar LED (círculo verde/rojo)
- `open-edit-dialog`: si boolean → toggle directo (no campo de texto)
- `open-fp-palette`: añadir botones "Bool Control" y "Bool Indicator"
- `fp-palette-add-item`: aceptar `bool-control` y `bool-indicator` como tipos de bloque

### Compiler.red — compile-diagram para booleanos

Detectar si nodo es boolean: `block-out-type` o checar primera salida del bdef.
- **input boolean**: VID usa `check "label"`, run-body lee `face/data` (logic!, no to-float)
- **output boolean**: texto es suficiente (`form true` → `"true"`)

### Cambios en canvas.red open-palette

Añadir sección "Lógica": AND, OR, NOT y sección "Comparadores": >, <, =.

### Tests a añadir

- `test-blocks.red`: 9 nuevos bloques registrados (suites: logic, compare, bool-io)
- `test-blocks.red`: tipos de puertos correctos (boolean en and-op, number en gt-op inputs)
- `test-compiler.red`: compile-body con and-op entre dos bool-const → emite `a and b`
- `test-compiler.red`: port-out-type / port-in-type funciones (si se extraen como helpers)
- Total esperado: 70 actuales + ~15 nuevos ≈ 85 tests PASS

## Contexto de Ficheros por Sprint

### Sprint 0 (Cleanup)
Pin: model.red, blocks.red, canvas.red, panel.red, qtorres.red, test-compiler.red

### Sprint 1-3 (Types)
Pin: blocks.red, canvas.red, compiler.red, panel.red, file-io.red
Tests: test-blocks.red, test-compiler.red

### Sprint 4 (FP Standalone)
Pin: compiler.red, panel.red, file-io.red
Test: .qvi ejecutable manual

### Sprint 5-7 (Control Structures)
Pin: model.red, compiler.red, canvas.red
Research: docs/arquitectura.md (execution model), LabVIEW structure behavior
