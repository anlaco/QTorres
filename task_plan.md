# Task Plan — Issue #7: Front Panel modular

## Meta
| Campo | Valor |
|-------|-------|
| Issue | [#7 — Front Panel modular](https://github.com/anlaco/QTorres/issues/7) |
| Labels | enhancement, fase-1 |
| Estado | OPEN |
| Inicio | 2026-03-20 |

## Goal
Implementar `src/ui/panel/panel.red` con **dos modos**:
1. **Modo edición** (en QTorres): canvas tipo `base` con Draw, drag & drop de elementos
2. **Modo ejecución** (Runner/compilado): código VID generado para el `.qvi`

## Criterios de aceptación
- [ ] Modo edición: Panel muestra controles e indicadores como shapes Draw arrastrables
- [ ] Modo edición: Clic en control → field editable temporal (no VID layout)
- [ ] Modo compilación: `compile-panel` genera `view layout [field ... button ... text ...]`
- [ ] Elementos arrastrables para reposicionar (offset actualizado)
- [ ] Posiciones se persisten en `front-panel:` del `qvi-diagram`

## Distinción clave (DT-009)
- **Edición:** face tipo `base` con Draw (como `canvas.red`) → drag, hit-test, posición
- **Ejecución:** VID layout con `field`/`text`/`button` reales → DT-009

---

## Phase 1 — Modelo fp-item + make-fp-item
**Responsable:** Modelo  
**Estado:** pending

### Tasks
- [ ] Definir `fp-item` como `object!` con campos: `id`, `type` ('control/'indicator), `name`, `label` (objeto DT-022), `default`, `value`, `offset` (pair!)
- [ ] Constructor `make-fp-item spec` siguiendo patrón DT-023 (composición sobre herencia)
- [ ] Añadir `front-panel: []` a `make-diagram-model` (lista de fp-items)
- [ ] Campo `offset` para posición arrastrable (x/y en canvas de panel)

### Entregable
Estructura de datos en `src/graph/model.red`.

---

## Phase 2 — render-panel (modo edición, Draw canvas)
**Responsable:** UI/Panel  
**Estado:** pending

### Tasks
- [ ] Función `render-panel model w h → face` tipo `base`
- [ ] Draw shapes para controles/indicadores: rectángulo + label + valor
- [ ] Hit-testing para seleccionar elementos
- [ ] Drag & drop actualiza `fp-item/offset` y redraw (patrón canvas.red)
- [ ] Clic en control → abre field temporal sobre el shape (edit inline)
- [ ] Botón "Run" visual (placeholder, no funcional aún)

### Entregable
Face funcional con Draw, drag & drop, hit-testing.

---

## Phase 3 — Parser front-panel desde qvi-diagram
**Responsable:** File I/O (stub)  
**Estado:** pending

### Tasks
- [ ] Al cargar un `.qvi`, parsear bloque `front-panel:` del `qvi-diagram`
- [ ] Crear `fp-item` por cada `control` y `indicator`
- [ ] Rellenar `offset` desde las specs (si existen) o usar defaults (auto-layout inicial)
- [ ] Añadir a `model/front-panel`

### Entregable
Carga de front-panel desde `.qvi`.

---

## Phase 4 — Persistencia de posiciones en qvi-diagram
**Responsable:** File I/O (stub)  
**Estado:** pending

### Tasks
- [ ] Al guardar, serializar `model/front-panel` a formato `front-panel: [...]`
- [ ] Incluir `offset` de cada fp-item
- [ ] Orden: control primero, luego indicator (determinista)

### Entregable
`.qvi` guarda y carga layout del panel.

---

## Phase 5 — compile-panel (generación VID para .qvi ejecutable)
**Responsable:** Compiler (stub)  
**Estado:** pending

### Tasks
- [ ] Función `compile-panel model → block!` que genera VID layout
- [ ] Por cada control: `label "nombre" field "default"`
- [ ] Por cada indicador: `label "nombre" text "valor"`
- [ ] Botón `button "Run" [...]` con lógica del diagrama
- [ ] Sección `qvi-diagram: [...]` + código generado `view layout [...]`

### Entregable
Código Red/View completo (DT-009).

---

## Phase 6 — Demo standalone (sin integración en qtorres.red)
**Responsable:** QA  
**Estado:** pending

### Tasks
- [ ] `demo-panel-model` con 2 controles, 1 indicator
- [ ] Ejecutar `red src/ui/panel/panel.red` → ventana con panel editable
- [ ] Verificar drag & drop
- [ ] Verificar edición inline de controles
- [ ] Verificar persistencia de offset

### Entregable
Issue #7 cerrado. Integración en app principal = Issue #8.

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
