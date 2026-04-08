# Progress Log — Transición Fase 2

## Session 2026-04-08 — Cierre de Fase 2 (continuación)

### Cluster model refactor + compilador ✅

- Refactor arquitectónico: cluster-control/indicator ahora tienen 1 cable tipo 'cluster
  (puerto estático), no N puertos dinámicos por campo. bundle/unbundle siguen con puertos dinámicos.
- compiler.red: añadido emit-cluster-control/indicator (UI + headless), casos en compile-body
  y compile-diagram run-body.
- model.red: cluster-in/out-ports limitados a bundle/unbundle respectivamente.
- canvas-render.red: in-ports/out-ports/render actualizados al nuevo modelo.
- Tests: 462/462 PASS.

### Issues cerrados
- #54 Cluster persistencia y puertos ✅
- #48 Bundle/Unbundle altura excesiva ✅
- #50 Headless no imprime indicadores ✅
- #51 Nodos del FP se apilan ✅
- #12 Cluster completo ✅
- #13 Waveform ✅
- #16 Case Structure ✅

### Estado actual
- 7 commits en refactor/fase4-estructural listos para merge en PR #60
- 462 tests PASS
- Fase 2 COMPLETADA — pendiente aprobación usuario para merge y tag v0.2

---

## Session 2026-04-07 — Cierre de Fase 2

### Fase 0 — Sincronización ✅

**0.1-0.3** Sincronizado con origin/main (commit 8dc1610). Línea base: **450 tests PASS**.

**0.4** Conteo de líneas actual:
- canvas.red: 2557 líneas
- panel.red: 1255 líneas  
- compiler.red: 891 líneas
- file-io.red: 647 líneas

**Próximo:** Delegar análisis bug #54 (Cluster) a qwen3-coder:480b.

---

## Session Log — Issue #13 (histórico)

### 2026-04-03 — Implementación completa (infraestructura)

**Rama:** `feat/13-waveform`

**Tests:** 450/450 PASS

**Fases completadas:**

### Phase 1: Registro de bloques ✅
- `src/graph/blocks.red`: añadidos `waveform-chart` y `waveform-graph`

### Phase 2: Modelo FP ✅
- `src/ui/panel/panel.red`:
  - Constantes: `fp-chart-width`, `fp-chart-height`
  - `fp-type-label?`: casos "CHART" y "GRAPH"
  - `fp-default-label`: casos "Chart" y "Graph"
  - `make-fp-item`: data-type 'waveform, default/value como block
  - `fp-color?`/`fp-border-color?`: waveform usa color de indicador

### Phase 3: Renderizado Draw ✅
- `src/ui/panel/panel.red`:
  - Función `render-waveform`: fondo negro, grid gris, línea verde
  - Caso en `render-fp-item` para `item/data-type = 'waveform`
  - `hit-fp-zone`: dimensiones de waveform

### Phase 4: Compilación ✅
- `src/ui/panel/panel.red` (compile-panel):
  - Caso para waveform-chart/graph: genera `base` face con Draw
- `src/qtorres.red` (btn-run):
  - Chart: acumula valores en buffer circular (history-size)
  - Graph: reemplaza con array completo

### Phase 5: Serialización ✅
- `src/ui/panel/panel.red`:
  - `load-panel-from-diagram`: parsea waveform-chart/graph
  - `save-panel-to-diagram`: serializa waveform-chart/graph

### Phase 6: Tests ✅
- 450 tests pasando
- Tests de make-fp-item para waveform

### Phase 7: Ejemplo y documentación ✅
- `examples/waveform-demo.qvi`: ejemplo básico
- `docs/visual-spec.md`: sección 8

### Phase 8: Paleta del Front Panel ✅
- `src/ui/panel/panel.red`:
  - Botones "Waveform Chart" y "Waveform Graph" en `open-fp-palette`
  - Default value para waveform en `fp-palette-add-item`
  - Sincronización con BD (nodos se crean automáticamente)

---

## Estado actual

**Funcionalidad disponible:**
- ✅ Crear waveform-chart y waveform-graph desde la paleta del FP
- ✅ Los nodos se crean automáticamente en el BD
- ✅ Botón Run actualiza el valor del indicador waveform
- ✅ Waveform Graph funciona con arrays externos (fuera de estructuras)

**Funcionalidad pendiente (requiere otra feature):**
- ⏳ Waveform Chart dentro de loops (necesita drag nodos dentro de estructuras)
- ⏳ Conectar wires desde dentro de estructuras

**Issue relacionado:**
- Issue nuevo: "Permitir arrastrar nodos dentro/fuera de estructuras"

---

## Próximo paso

El issue #13 está completo en cuanto a infraestructura. La funcionalidad completa de Chart dentro de loops requiere implementar drag de nodos dentro/fuera de estructuras.

## Session 2026-04-08 — Bug #54 + QA fixes

- Fase 1 del plan completada: bug #54 (cluster no persiste campos)
  - canvas.red: cluster-control/cluster-indicator añadidos al dbl-click handler (L2357, L2399)
  - model.red: cluster-in-ports ahora incluye 'cluster-indicator, cluster-out-ports incluye 'cluster-control
  - model.red: añadido helper `wire-port-in-used?` para QA-018
  - canvas.red: QA-018 aplicado en 3 lugares (L1911, L1933, L2309)
- Fase 2 del plan completada: protecciones QA
  - QA-018: `wire-port-in-used?` en model.red + 3 llamadas en canvas.red ✅
  - QA-024: `fp-default-label` ya tenía todos los tipos cubiertos ✅ (ya estaba)
  - QA-029: `save-panel-to-diagram` ahora guarda item/value en lugar de item/default (panel.red L1017) ✅
- Bonus refactor (hecho por opencode agent):
  - load-panel-from-diagram movida de panel.red a file-io.red (Fase 4A parcial)
  - apply-const/str/arr-value en canvas.red usan `set-config` (Fase 4B parcial)
- Tests: 450/450 PASS
- Modelos usados: kimi-k2.5 (análisis + canvas.red), qwen3-coder-next (panel.red)