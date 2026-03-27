# Progress — Issue #16: Case Structure

## Session Log

### 2026-03-26 — Phase 6 completada (Ejemplos)

**Tests:** 347/347 PASS

**Fase completada:**
- Phase 6: Ejemplos creados
  - `examples/case-numeric.qvi` — selector numérico (case → case/case/default)
  - `examples/case-boolean.qvi` — selector booleano (either true/false)

**Ejemplos ejecutables con:** `./red-cli examples/case-numeric.qvi` o `./red-view examples/case-numeric.qvi`

**Estado del Issue:** ✅ COMPLETADO

---

### 2026-03-26 — Phase 5 completada (Serialización)

**Tests:** 347/347 PASS (+20 desde Phase 3)

**Fase completada:**
- Phase 5: Serialización (serialize-diagram, format-qvi, load-vi para case-structure con frames)
  - `serialize-diagram`: maneja `frames` array con coords relativas, `active-frame`, `selector` wire
  - `format-qvi`: formato multi-línea con indentación para frames
  - `load-vi`: parse de `case-structure` con frames, conversión coords absolutas
  - Tests round-trip: 12 asserts verificando save/load correcto

**Cambios en archivos:**
- `src/io/file-io.red`:
  - `serialize-diagram`: añadido caso `case-structure` con `switch/default` → `case`
  - `format-qvi`: añadido parsing de `case-structure` con frames
  - `load-vi`: añadido parse de `case-structure` con frames, selector-wire, active-frame

**Tests añadidos:**
- Round-trip Case-structure (12 asserts en test-compiler.red)

**Próximos pasos:** Phase 6 — Tests y ejemplos (.qvi de demostración)

---

### 2026-03-26 — Phase 0, 1, 2 completadas

**Tests:** 327/327 PASS

**Phases completadas:**
- Phase 0: Modelo (`make-frame`, extensión `make-structure` con `frames`, `active-frame`, `selector-wire`)
- Phase 1: Renderizado (`render-case-structure` con barra navegación `[<][>][+][-]`, terminal `[?]`, nodos del frame activo)
- Phase 2: Hit-testing (`hit-case-nav-buttons`, `hit-case-terminal`, `hit-structure-node` actualizado para frames)

**Cambios en archivos:**
- `src/graph/model.red`: añadido `make-frame`, campos `frames`, `active-frame`, `selector-wire` en estructura
- `src/graph/blocks.red`: registrado `'case-structure`
- `src/ui/diagram/canvas.red`: constantes `case-nav-height`, `case-btn-size`, `col-case-nav-bg`; función `render-case-structure`; funciones de hit-test
- `tests/test-model.red`: 26 tests nuevos para frame y case-structure
- `tests/test-blocks.red`: contador actualizado (+1 bloque)

**Próximos pasos:** Phase 3 — Interacción (navegación frames, drag/resize, wiring selector)

---

### 2026-03-26 — Inicio (Planificación)

**Rama:** `feat/case-structure-v2` creada desde `main`

**Tests base:** 271/271 PASS (estado tras Issue #15)

**Plan creado:** task_plan.md con 7 fases

---

# Progress histórico — Issue #15: For Loop

## Session Log

### 2026-03-25 — Implementación completa

**Tests:** 271/271 PASS (partíamos de 241/241 al cerrar #14)

**Fases completadas:**
- Phase 0: Modelo (model.red label por tipo, blocks.red registra 'for-loop)
- Phase 1: Render (terminal [N] cuadrado naranja top-left, [●] solo while-loop)
- Phase 2: Interacción (wiring [N], paleta "For", delete limpia wire N)
- Phase 3: Compilador (compile-structure bifurcado, `loop N [...]`, to-integer, /no-gui)
- Phase 4: Serialización (for-loop en serialize/load/format-qvi)
- Phase 5: Tests + ejemplo for-loop-basico.qvi (0+1+...+9=45)

**Bug corregido durante #15:**
- `make-wire` convierte `to-port` a `word!` — todas las comparaciones `"count"` cambiadas a `'count`
- `compile-structure` emitía `do-events/no-wait` también en rama headless → cuelga
  Solución: refinamiento `/no-gui` en `compile-structure`; `compile-body` usa `/no-gui`
- `compile-body` y `compile-diagram` solo manejaban `'while-loop` → `'for-loop` se saltaba
  Solución: `find [while-loop for-loop] item/type` en ambos

**Ejecución del ejemplo headless:**
`./red-cli examples/for-loop-basico.qvi headless` → `Resultado: 45.0`
(sin args → rama GUI, requiere red-view; con cualquier arg → rama headless)

---

# Progress histórico — Issue #14: While Loop

## Session Log

### 2026-03-23 — Planificación final (v3: dos entregas)
**Tema:** Plan definitivo con 2 entregas incrementales

**Evolución del plan:**
- v1: sin shift registers → usuario pidió incluirlos
- v2: todo junto → demasiado trabajo de una vez
- v3: **dos entregas** — 14a (loop básico) → 14b (shift registers)

**Entrega 14a (Phases 0-6):**
- Modelo: make-structure con nodes, wires, cond-wire
- Render: rectángulo con terminales condición (●) e iteración (i)
- Hit-test: nodo interno > terminal > resize > borde > fondo
- Interacción: drag estructura, drag nodo interno, resize, wiring interno
- Compilador: `until [...]` con variable _i
- Serialización: structures en qvi-diagram (coords relativas)
- Tests + ejemplo while-loop-basico.qvi

**Entrega 14b (Phases 7-12):**
- Modelo: make-shift-register, 6 tipos de wire especial
- Render: terminales ▲/▼ en bordes, color por tipo
- Interacción: wire externo → SR-left, SR-right → externo, añadir/borrar SR
- Compilador: inicialización SRs, actualización dentro del until, lectura fuera
- Topological sort: structure como nodo virtual con dependencias externas
- Tests + ejemplo while-loop-suma.qvi (suma acumulativa)

**Estado:** Plan aprobado, listo para implementar Phase 0

### 2026-03-23 — Phase 0 completada
**Implementado:**
- `make-structure` en model.red — constructor para estructuras contenedoras (while-loop)
- `make-diagram` actualizado con campo `structures: copy []`
- `while-loop` registrado en blocks.red (categoría 'structure)
- `gen-name 'while-loop` funciona: produce "while-loop_1", "while-loop_2", etc.
- 27 tests nuevos en test-model.red (159/159 PASS)

### 2026-03-23 — Phase 1 completada
**Implementado:**
- `render-wire-list` helper: extrae lógica de wires de render-bd, reutilizable
- `render-node-list` helper: extrae lógica de nodos de render-bd, reutilizable
- `render-structure`: rectángulo + label + terminal i (cuadrado azul) + terminal ● (círculo verde) + handle resize + borde selección cian + nodos/wires internos
- `render-bd` refactorizado: usa helpers, renderiza estructuras antes que nodos normales
- Estado estructura en `make-diagram-model`: selected-struct, drag-struct, drag-struct-off, resize-struct

### 2026-03-24 — Revisión visual 14a + corrección de bugs
**Verificado manualmente:**
- Añadir/borrar While Loop, render completo, resize, drag, nodos internos, wires internos
- Wire desde [i] a nodo interno, wire condición a [●], delete interno, save/load round-trip
- Compilador genera `until [...]` correcto, Run ejecuta sin error

**Bugs encontrados y corregidos:**
1. Bug #3 — Selección visual: fix en `render-structure`
2. Bug #4 — Delete doble: limpiar `selected-struct` tras borrar nodo interno
3. Bug #5 — [i] no wireable: crear virtual iter-node (id=-3)
4. Bug #5b — Wire [i] sale mal: precomputar `half-tx`
5. Bug #7 — Nodo externo atrapado: orden de hit-tests
6. Bug topological-sort ciclo: ignorar wires virtuales (id<0)
7. Bug Load sin structures: copiar `loaded/structures`
8. Bug case+all en Red: reescribir con `if/exit`

**Tests:** 186/186 PASS (25 bloques registrados: +1 iter virtual)

### 2026-03-24 — Phase 7-12 completadas (Shift Registers)
**Implementado:**
- `make-shift-register` en model.red
- Render terminales ▲/▼ en bordes
- Hit-test + wiring de SRs
- Compilador con inicialización/actualización SRs
- Serialización SRs en file-io.red
- Tests + ejemplo while-loop-suma.qvi

**Tests:** 241/241 PASS