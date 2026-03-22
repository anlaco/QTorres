# Progress — Issue #9: Tipo Booleano

## Session Log

### 2026-03-22 — Implementación completa
**Tema:** Issue #9 — Tipo booleano en todo el sistema

**Acciones:**
- Phase 1: Type System — `port-out-type`, `port-in-type`, `col-wire-bool`, `wire-data-color`, wire color dinámico en `render-bd`, guard de tipos en `on-down`
- Phase 2.1: blocks.red — 9 bloques nuevos (bool-const, bool-control, bool-indicator, and-op, or-op, not-op, gt-op, lt-op, eq-op)
- Phase 2.2-2.3: canvas.red — paleta Lógica/Comparadores + type-label switch
- Phase 2.4-2.6: panel.red — campo data-type, LED render, toggle bool-control, paleta FP, save/load actualizado
- Phase 2.7: compiler.red — node-boolean-input? helper, compile-diagram genera `check` face para boolean inputs
- Phase 2.8: Tests — 28 nuevos asserts; **98/98 PASS**

**Errores encontrados y resueltos:**
- `find block false` no fiable en Red → usar `do body` + verificar variable directamente
- Test de `and-op NO es input` incorrecto: `node-boolean-input?` chequea tipo del output (boolean), no la categoría del bloque → corregido

**Estado:** Implementación completa, tests verdes, pendiente commit y PR

---

# Progress — Issue #7: Front Panel modular (histórico)

## Session Log

### 2026-03-20 — Sesión inicial
**Tema:** Planificación de Issue #7  
**Acciones:**
- Leído issue #7 (GitHub API — Classic Projects deprecated, usé --json)
- Leído `docs/arquitectura.md` (328 líneas)
- Leído `src/ui/diagram/canvas.red` (574 líneas) — referencia para drag & drop
- Leído stub `src/ui/panel/panel.red` (12 líneas)
- Leído skill `planning-with-files` y templates
- Creados `task_plan.md`, `findings.md`, `progress.md`

**Decisiones iniciales:**
- 7 fases: modelo → parser → render → binding → persistencia → integración → test
- Reutilizar patrón drag & drop de canvas.red
- `fp-item` como objeto análogo a nodo con `base-element`
- `offset` (pair!) para posiciones arrastrables

**Estado:** Plan creado

### 2026-03-20 — Revisión arquitectónica
**Tema:** Validación contra decisiones técnicas y Red-lang  
**Acciones:**
- Leído skill Red-lang completo (secciones View, Draw, VID)
- Leído `docs/decisiones.md` (DT-001 a DT-024)
- Re-analizado DT-009 (compiler genera Red/View completo)

**Problema identificado:**
- Plan original mezclaba dos modos distintos
- En modo edición no se pueden usar `field`/`text` con drag
- DT-009 aplica al `.qvi` ejecutable, no a la edición

**Corrección arquitectónica:**
- Dos modos: **edición** (Draw canvas) vs **ejecución** (VID layout)
- Fase 2: `render-panel` → base + Draw (drag & drop)
- Fase 5: `compile-panel` → VID layout (DT-009)
- Eliminado "binding" como fase separada (es parte de compile)

**Fases corregidas:**
1. Modelo `fp-item` + `make-fp-item`
2. `render-panel` (Draw canvas para edición)
3. Parser desde `front-panel:` del qvi-diagram
4. Persistencia de `offset` en qvi-diagram
5. `compile-panel` (VID layout para .qvi ejecutable)
6. Demo standalone
7. Integración en app → Issue #8

**Commit:** Corrección del plan completa
**Estado:** Plan validado, listo para implementar

### 2026-03-20 — Implementación Issue #7
**Tema:** Implementación de las fases 1-6  
**Acciones:**
- Fase 1: Añadido `make-fp-item` a `src/graph/model.red` (object con id, type, name, label, default, value, offset)
- Fase 2: Implementado `render-panel` en `src/ui/panel/panel.red` — face base + Draw
  - Drag & drop con `on-over` + `event/down?` (patrón canvas.red)
  - Hit-testing `hit-fp-item` para seleccionar elementos
  - `open-edit-dialog` para editar valores inline
- Fase 3: `load-panel-from-diagram` — parser del bloque `front-panel:`
- Fase 4: `save-panel-to-diagram` — serialización con offsets
- Fase 5: `compile-panel` — genera VID layout para .qvi ejecutable
- Fase 6: Demo standalone funcionando

**Errores encontrados:**
- Error de sintaxis en `gen-standalone-code` con `reduce compose [...]` → corregido usando `rejoin` + `mold`

**Commits:**
- `6c8bc1a` — Issue #7: Front Panel modular — phases 1-6 complete

**Estado:** Fases 1-6 completas. Fase 7 (integración) = Issue #8.
