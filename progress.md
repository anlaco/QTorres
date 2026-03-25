# Progress — Issue #15: For Loop

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

**Gotchas encontrados:**
- En Red 0.6.6, bloques literales `[visible: true]` almacenan `true` como word!, no logic!. Hay que usar `compose [visible: (true)]` para insertar el valor logic!.
- `true = true` devuelve false en Red (word vs logic). Usar `logic?` + valor directo.
- `#[true]` literal no soportado en Red 0.6.6. Evitarlo.

**Tests base:** 159/159 PASS

### 2026-03-23 — Phase 1 completada
**Implementado:**
- `render-wire-list` helper: extrae lógica de wires de render-bd, reutilizable
- `render-node-list` helper: extrae lógica de nodos de render-bd, reutilizable
- `render-structure`: rectángulo + label + terminal i (cuadrado azul) + terminal ● (círculo verde) + handle resize + borde selección cian + nodos/wires internos
- `render-bd` refactorizado: usa helpers, renderiza estructuras antes que nodos normales
- Estado estructura en `make-diagram-model`: selected-struct, drag-struct, drag-struct-off, resize-struct

**Tests:** 159/159 PASS (sin tests nuevos de render — son funciones puras visuales)

### 2026-03-24 — Revisión visual 14a + corrección de bugs
**Verificado manualmente:**
- Añadir/borrar While Loop, render completo, resize, drag, nodos internos, wires internos
- Wire desde [i] a nodo interno, wire condición a [●], delete interno, save/load round-trip
- Compilador genera `until [...]` correcto, Run ejecuta sin error

**Bugs encontrados y corregidos:**
1. **Bug #3 — Selección visual**: clic en nodo interno mostraba borde rojo en toda la estructura. Fix: `render-structure` solo muestra borde selección si `none? model/selected-node`.
2. **Bug #4 — Delete doble**: GTK dispara on-key dos veces (key-down + key-up). El primer Delete borraba el nodo interno pero dejaba `selected-struct` activo; el segundo Delete borraba la estructura. Fix: limpiar `selected-struct` tras borrar nodo interno.
3. **Bug #5 — [i] no wireable**: el terminal [i] no podía iniciar wires. Fix: al clic en [i], crear virtual iter-node (id=-3), almacenar en `wire-src-struct`, wire se crea en `st/wires` con `from-port: _while_N_i`. Registrado bloque 'iter en blocks.red.
4. **Bug #5b — Wire [i] sale mal**: fórmula `bx + 8 + to-integer tx / 2` se evaluaba como `(bx + 8 + tx) / 2` por precedencia left-to-right de Red. Fix: precomputar `half-tx: to-integer (tx / 2)`.
5. **Bug #7 — Nodo externo atrapado**: nodo arrastrado sobre while quedaba inaccesible. Fix: mover `hit-node` (externo) antes de `point-in-structure?` en prioridad de on-down.
6. **Bug topological-sort ciclo**: wires virtuales (from-node < 0) contaban como dependencia real en in-degree. Fix: `if w/from-node >= 0` en el cálculo de in-degree.
7. **Bug Load sin structures**: `qtorres.red` btn-load no copiaba `loaded/structures` al app-model. Fix: añadir `app-model/structures: loaded/structures`.
8. **Bug case+all en Red**: `case [all [A B] [...]]` no funciona como esperado — Red parsea `all` como condición truthy y `[A B]` como acción. Fix: reescribir `canvas-delete-selected` con `if/exit` explícitos.

**Gotchas Red importantes:**
- `case [all [A B] [action]]` → Red parsea `all` (truthy word) + `[A B]` (action block), NO `all [A B]` como condición
- `bx + 8 + to-integer tx / 2` → Red evalúa left-to-right: `(bx + 8 + 14) / 2`, no `bx + 8 + 7`
- GTK on-key dispara DOS veces por pulsación (key-down + key-up)

**Tests:** 186/186 PASS (25 bloques registrados: +1 iter virtual)

**Pendientes menores (no bloqueantes):**
- [i] offset visual ligeramente desplazado
- Hit-test resize requiere clic un poco fuera del borde
- Terminal [i] no movible (futuro)

### 2026-03-24 — Entrega 14a COMPLETA — inicio 14b (shift registers)
**Estado confirmado:** 187/187 PASS. Todas las fases 0-6 verificadas en código.
- compile-structure en compiler.red (funciones: compile-structure, compile-body, compile-diagram)
- round-trip while-loop en test-compiler.red (suites de test-file-io)
- examples/while-loop-basico.qvi presente
- task_plan.md actualizado (phases 4-6 checked)

### 2026-03-24 — Phase 7 completada (shift register model)
**Implementado:**
- `make-shift-register` en model.red — constructor con id, name, data-type, init-value, y-offset
- `shift-regs: copy []` añadido a `make-structure` (campo nuevo)
- init-value por defecto: `""` si data-type = 'string, `0.0` en todos los demás casos
- 21 tests nuevos en test-model.red (208/208 PASS)

**14b COMPLETA — Shift Registers**
- ~~Phase 7: make-shift-register en model.red~~ ✅
- ~~Phase 8: render terminales ▲/▼ en canvas.red~~ ✅
- ~~Phase 9: hit-test + wiring de SRs~~ ✅
- ~~Phase 10: compilador con inicialización/actualización SRs~~ ✅
- ~~Phase 11: serialización SRs en file-io.red~~ ✅
- ~~Phase 12: tests + ejemplo while-loop-suma.qvi~~ ✅

### 2026-03-24 — Phase 8 completada (render SR)
**Implementado en canvas.red:**
- Constante `sr-terminal-half: 6`
- Helper `sr-type-color` — mismo patrón que `wire-data-color` (number=naranja, bool=verde, string=rosa)
- `render-structure` step 5: loop sobre `st/shift-regs`:
  - ▲ (triángulo apuntando arriba) en borde izquierdo (lectura)
  - ▼ (triángulo apuntando abajo) en borde derecho (escritura)
  - texto `init-value` junto al ▲ (visible cuando sin wire externo)
- Steps 5-10 existentes renumerados a 6-11
**Tests:** 208/208 PASS (solo render, sin tests de render puro)

### 2026-03-24 — Phase 9 completada (interacción SR en canvas)
**Implementado en canvas.red:**
- `make-diagram-model` extendido: `wire-src-sr`, `selected-sr`
- `hit-structure-sr`: detecta clic en ▲/▼, devuelve `[struct sr 'left|'right]`
- `render-structure` y `render-bd`: wires SR (int SR-left, int SR-right, ext→▲, ▼→ext)
- Helpers: `add-sr-to-structure`, `open-add-sr-dialog`, `apply-sr-init-value`, `open-sr-edit-dialog`
- `canvas-delete-selected`: borra SR + todos sus wires internos y externos
- `on-down` prioridad 2.5: crea wires SR (validación de tipo, dirección)
- `on-up`: completa wires SR
- `on-dbl-click` priority 0: editar init-value de SR
- `open-palette` con botón "Add SR"
**Tests:** 208/208 PASS (solo render, sin tests de render puro)

### 2026-03-24 — Phase 10 completada (compilador SR)
**Implementado en compiler.red:**
- `build-sorted-items`: topo-sort unificado de nodos + estructuras, usando IDs externos de wires SR
- `compile-structure` actualizado: nueva firma `[st outer-diagram]`
  - Inicialización de SRs antes del `until` (literal o variable de nodo fuente externo)
  - Actualización de SRs dentro del `until` (antes del incremento de iteración)
- `compile-body` actualizado: usa `build-sorted-items`, maneja nodos y estructuras en un solo loop
- `compile-diagram` actualizado: usa `build-sorted-items`, elimina bloque "Añadir estructuras" separado
- `test-compiler.red` actualizado: 3 llamadas a `compile-structure` actualizadas con `empty-outer`
**Tests:** 208/208 PASS

### 2026-03-24 — Phase 11 completada (serialización SR en file-io)
**Implementado en file-io.red:**
- `serialize-diagram`: añade bloque `shift-registers: [sr [...] sr [...]]` en cada estructura
- `format-qvi`: formatea `shift-registers:` con indentación correcta (omitido si vacío)
- `load-vi`: parsea `sr [...]` y reconstruye con `make-shift-register`, sincroniza names
- Wires externos SR se serializan automáticamente (están en `diagram/wires`)
- 15 tests nuevos en test-compiler.red (suite "file-io — round-trip shift registers")
**Tests:** 223/223 PASS

### 2026-03-24 — Phase 12 completada + Issue #14 CERRADO
**Implementado:**
- `make-node` en model.red: carga `config` desde spec (habilita round-trip de valores de constantes)
- `serialize-nodes` en file-io.red: incluye `config:` en el bloque si no está vacío
- `compile-diagram` en compiler.red: indicadores conectados a SR-right encuentran la variable `_sr_name`
- `topological-sort`: ignorar wires con `to-node < 0` (fix para SR-right virtual en sub-diagramas)
- Tests 12.2-12.4 (SR init, múltiples SRs, SR con wire externo) + test config round-trip
- `examples/while-loop-suma.qvi`: suma 0+1+...+9 = 45 usando SR — funciona headless y UI
**Tests:** 241/241 PASS
