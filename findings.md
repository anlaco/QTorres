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
