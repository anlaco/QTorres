# Progress — Issue #14: While Loop

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
