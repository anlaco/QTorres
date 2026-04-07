# Plan — Issue #13: Waveform Chart y Graph

## Contexto

**Issue:** #13 - Waveform chart y graph en Front Panel
**Prioridad:** 7 de 8 en Fase 2 (último feature de Fase 2)
**Estado:** ✅ COMPLETADO

**Objetivo:** Implementar controles de visualización de señales en el Front Panel:
- **Waveform Chart:** acumula valores en cada iteración (buffer circular)
- **Waveform Graph:** muestra un array completo como señal

**Referencias LabVIEW:**
- [NI Knowledge Base: Waveform Graphs vs Charts](https://knowledge.ni.com/KnowledgeArticleDetails?id=kA00Z000000P9zsSAC)
- [LabVIEW Docs: Waveform Charts](https://ni.com/docs/en-US/bundle/labview/page/waveform-charts.html)

**Problema:** No hay validación que impida conectar dos wires al mismo puerto de entrada. Viola visual-spec 5.2.

## Fases

### Phase 0: Diseño ✅ COMPLETE

Diseño completado y aprobado. Ver detalles en `/home/alaforga/.claude/plans/toasty-plotting-parrot.md`.

### Phase 1: Registro de bloques ✅ COMPLETE

**Fichero:** `src/graph/blocks.red`

**Cambios:**
- [x] 1.1 Añadir `waveform-chart` al block-registry
- [x] 1.2 Añadir `waveform-graph` al block-registry
- [x] 1.3 Añadir tests en `tests/test-blocks.red`

### Phase 2: Modelo FP ✅ COMPLETE

**Fichero:** `src/ui/panel/panel.red`

**Cambios:**
- [x] 2.1 Añadir casos en `fp-type-label?` para waveform-chart/graph
- [x] 2.2 Añadir casos en `fp-default-label` para waveform-chart/graph
- [x] 2.3 Actualizar `make-fp-item` para soportar tipos waveform
- [x] 2.4 Añadir constantes de dimensiones `fp-chart-width`, `fp-chart-height`

### Phase 3: Renderizado Draw ✅ COMPLETE

**Fichero:** `src/ui/panel/panel.red`

**Cambios:**
- [x] 3.1 Crear función `render-waveform`
- [x] 3.2 Añadir case en `render-fp-item` para waveform-chart/graph
- [x] 3.3 Actualizar `hit-fp-zone` para waveform

### Phase 4: Compilación ✅ COMPLETE

**Fichero:** `src/ui/panel/panel.red` (compile-panel), `src/qtorres.red` (btn-run)

**Cambios:**
- [x] 4.1 Añadir casos en `compile-panel` para waveform-chart
- [x] 4.2 Añadir casos en `compile-panel` para waveform-graph
- [x] 4.3 Actualizar indicadores waveform en el botón Run (qtorres.red)
  - Chart: acumula valores en buffer circular (history-size)
  - Graph: reemplaza con array completo

### Phase 5: Serialización ✅ COMPLETE

**Fichero:** `src/ui/panel/panel.red` (save/load)

**Cambios:**
- [x] 5.1 `save-panel-to-diagram` serializa config/value
- [x] 5.2 `load-panel-from-diagram` restaura config/value

### Phase 6: Tests ✅ COMPLETE

**Ficheros:** `tests/test-blocks.red`

**Tests:**
- [x] 6.1 Tests de block registry (waveform-chart y waveform-graph)
- [x] 6.2 Tests de make-fp-item para waveform
- [x] 6.3 450 tests pasando

### Phase 7: Ejemplo y documentación ✅ COMPLETE

**Ficheros:**
- [x] 7.1 `examples/waveform-demo.qvi` creado
- [x] 7.2 `docs/visual-spec.md` actualizado con sección 8

### Phase 8: Paleta del Front Panel ✅ COMPLETE

**Fichero:** `src/ui/panel/panel.red`

**Cambios:**
- [x] 8.1 Añadir botones "Waveform Chart" y "Waveform Graph" en `open-fp-palette`
- [x] 8.2 Actualizar `fp-palette-add-item` para default value de waveform (array vacío)
- [x] 8.3 Sincronización con BD (ya funciona para tipos no-cluster)

---

## Verificación final

- [x] `red-cli tests/run-all.red` → 450 tests PASS
- [x] UI: crear chart/graph en FP desde paleta
- [ ] UI: conectar wires en BD (PENDIENTE - requiere drag dentro de estructuras)
- [x] Headless: ejemplo waveform-demo.qvi creado
- [x] Botón Run: actualiza item/value para waveform
- [ ] Chart acumula valores en loop (PENDIENTE - requiere nodos dentro de estructuras)
- [x] Graph muestra array completo (funciona con arrays externos)

---

## Trabajo pendiente

La infraestructura de waveform está completada:
- Bloques registrados en blocks.red
- Modelo FP en panel.red
- Renderizado Draw con grid y línea verde
- Serialización/deserialización
- Tests automatizados (450 PASS)
- Paleta del FP con botones Waveform Chart/Graph
- Botón Run actualiza item/value para waveform

**Lo que funciona ahora:**
- Waveform Graph conectado a un array externo (fuera de estructuras) ✅
- Crear waveform-chart y waveform-graph desde la paleta del FP ✅
- Los nodos se crean automáticamente en el BD ✅
- Botón Run actualiza el valor del indicador ✅

**Lo que requiere otra feature (drag nodos dentro de estructuras):**
- Waveform Chart dentro de un loop (necesita poder meter el nodo dentro del loop)
- Conectar nodos desde dentro de estructuras

**Issue relacionado:**
- Crear issue nuevo: "Permitir arrastrar nodos dentro/fuera de estructuras"

---

## Errores encontrados

| Error | Intento | Resolución |
|-------|---------|------------|
| — | — | — |
