# Task Plan — Fase 2: Tipos de datos y estructuras de control

## Meta
| Campo | Valor |
|-------|-------|
| Fase  | 2 |
| Issues | #23, #24, #28, #15, #16, #17 (core) · #25, #27 (stretch) |
| Inicio | 2026-03-22 |
| Prerequisito | Sprint 0 Cleanup |

## Goal
Expandir QTorres desde un entorno solo-numérico a un sistema multi-tipo (boolean, string) con estructuras de control (while, for, case).

## Phase 0 — Sprint 0: Cleanup Anti-Alucinaciones
**Estado:** ✅ COMPLETO (2026-03-21)

### Tasks
- [x] 0.1 Eliminar `make-fp-item` y `fp-value-text` duplicados de model.red (dejar solo panel.red)
- [x] 0.2 `in-ports`/`out-ports`/`ncolor` en canvas.red → leer de `block-registry` via `block-color`/`block-in-ports`/`block-out-ports`
- [x] 0.3 Wires en actores canvas.red → usan `make-wire` de model.red (3 sitios: on-down, on-up, demo)
- [x] 0.4 Mover shims `control`/`indicator` de qtorres.red a blocks.red
- [x] 0.5 Añadir tests FP round-trip (save-vi→load-vi con front-panel, 17 asserts nuevos)

### Verificación
- `./red-cli tests/run-all.red` → 70 tests, 70 PASS ✅
- `./red-view src/qtorres.red` → pendiente verificación visual manual

---

## Phase 1 — Sprint 1: Type System Foundation
**Estado:** ✅ COMPLETO (2026-03-22)

### Tasks
- [x] 1.1 Añadir `port-out-type` y `port-in-type` en canvas.red
- [x] 1.2 Constante `col-wire-bool: 20.80.160` + función `wire-data-color`
- [x] 1.3 `render-bd`: wire color dinámico por tipo de puerto
- [x] 1.4 Guard en `on-down`: no crear wire si tipos incompatibles

---

## Phase 2 — Sprint 2: Tipo Booleano (Issue #9)
**Estado:** ✅ COMPLETO (2026-03-22)

### Tasks
- [x] 2.1 blocks.red: 9 bloques booleanos/lógicos/comparadores
- [x] 2.2 canvas.red open-palette: sección Lógica y Comparadores
- [x] 2.3 canvas.red type-label switch: labels para nuevos tipos
- [x] 2.4 panel.red make-fp-item: campo `data-type`
- [x] 2.5 panel.red render-fp-item: LED (círculo verde/rojo) para boolean
- [x] 2.6 panel.red open-fp-palette: Bool Control y Bool Indicator
- [x] 2.7 compiler.red compile-diagram: boolean input → `check` face
- [x] 2.8 Tests: 28 nuevos asserts — 98/98 PASS ✅

---

## Phase 3 — Sprint 3: Tipo String (#24)
**Estado:** pending
**Depende de:** Phase 1

### Tasks
- [ ] 3.1 block-def: string-const, concat, string-length
- [ ] 3.2 Widget string en panel.red
- [ ] 3.3 Compiler: string controls/indicators
- [ ] 3.4 Tests: string blocks + VI round-trip

---

## Phase 4 — Sprint 4: FP Standalone Fiel (#28)
**Estado:** pending
**Depende de:** Phase 2, Phase 3

### Tasks
- [ ] 4.1 compile-panel genera VID con posiciones del canvas
- [ ] 4.2 format-qvi emite layout posicional
- [ ] 4.3 .qvi standalone refleja layout del canvas

---

## Phase 5 — Sprint 5: While Loop (#15)
**Estado:** pending
**Depende de:** Phase 4

### Tasks
- [ ] 5.1 structure-node en model.red (nodo con sub-diagrama)
- [ ] 5.2 Canvas: borde de estructura + drag internal
- [ ] 5.3 Compiler: while → `while [cond] [body]` Red
- [ ] 5.4 Tests: while loop

---

## Phase 6 — Sprint 6: For Loop (#16)
**Estado:** pending
**Depende de:** Phase 5

### Tasks
- [ ] 6.1 For Loop como variante de structure-node
- [ ] 6.2 Terminales N, index
- [ ] 6.3 Tests: for loop

---

## Phase 7 — Sprint 7: Case Structure (#17)
**Estado:** pending
**Depende de:** Phase 5

### Tasks
- [ ] 7.1 Case con múltiples frames
- [ ] 7.2 Canvas: switch de frame + selector
- [ ] 7.3 Compiler: case → switch Red
- [ ] 7.4 Tests: case structure

## Phase 3 — Parser front-panel desde qvi-diagram
**Responsable:** File I/O (stub)  
**Estado:** ~~pending~~ **complete**

### Tasks
- [x] Al cargar un `.qvi`, parsear bloque `front-panel:` del `qvi-diagram`
- [x] Crear `fp-item` por cada `control` y `indicator`
- [x] Rellenar `offset` desde las specs (si existen) o usar defaults (auto-layout inicial)
- [x] Añadir a `model/front-panel`

### Entregable
Carga de front-panel desde `.qvi`. ✅

---

## Phase 4 — Persistencia de posiciones en qvi-diagram
**Responsable:** File I/O (stub)  
**Estado:** ~~pending~~ **complete**

### Tasks
- [x] Al guardar, serializar `model/front-panel` a formato `front-panel: [...]`
- [x] Incluir `offset` de cada fp-item
- [x] Orden: control primero, luego indicator (determinista)

### Entregable
`.qvi` guarda y carga layout del panel. ✅

---

## Phase 5 — compile-panel (generación VID para .qvi ejecutable)
**Responsable:** Compiler (stub)  
**Estado:** ~~pending~~ **complete**

### Tasks
- [x] Función `compile-panel model → block!` que genera VID layout
- [x] Por cada control: `label "nombre" field "default"`
- [x] Por cada indicador: `label "nombre" text "valor"`
- [x] Botón `button "Run" [...]` con lógica del diagrama
- [x] Sección `qvi-diagram: [...]` + código generado `view layout [...]`

### Entregable
Código Red/View completo (DT-009). ✅

---

## Phase 6 — Demo standalone (sin integración en qtorres.red)
**Responsable:** QA  
**Estado:** ~~pending~~ **complete**

### Tasks
- [x] `demo-panel-model` con 2 controles, 1 indicator
- [x] Ejecutar `red src/ui/panel/panel.red` → ventana con panel editable
- [x] Verificar drag & drop
- [x] Verificar edición inline de controles
- [x] Verificar persistencia de offset

### Entregable
Módulo panel funcional standalone. ✅

---

## Phase 7 — Integración en qtorres.red (Issue #8)
**Responsable:** App  
**Estado:** pending (belongs to Issue #8)

### Tasks
- [ ] Cargar `panel.red` desde `qtorres.red`
- [ ] Vista dividida: Block Diagram + Front Panel
- [ ] Sincronización modelo único

### Entregable
App con ambos paneles (Issue #8).

---

## Notas arquitectónicas

| Modo | Tecnología | Propósito |
|------|------------|-----------|
| Edición (QTorres) | `base` + Draw | Drag, hit-test, posición |
| Ejecución (.qvi) | VID layout (`view [...]`) | `field`/`text` interactivos |

**Binding de valores:**
- Edición: valor temporal en `fp-item/value`, se usa al compilar
- Ejecución: el usuario edita `field`, pulsa Run, `text` muestra resultado

**Separación Issue #7 vs #8:**
- #7 = módulo panel standalone (fases 1-6)
- #8 = integración en app principal (fase 7)

**Dependencias cruzadas:**
- Runner (Issue #10) necesita `compile-panel` para ejecutar
- File I/O (Issue #9) necesita fase 3 y 4
