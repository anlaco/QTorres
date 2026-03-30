# Progress — Issue #12: Cluster

## Session Log

### 2026-03-29 — Planificación

**Rama:** pendiente de crear (`feat/12-cluster` desde `main`)

**Tests base:** 347/347 PASS (último estado conocido, pendiente verificar)

**Plan creado:** task_plan.md con 8 fases (0-7)

**Decisiones clave tomadas:**
- Opción B (config-driven) para puertos dinámicos — campos en `node/config/fields`
- Fase 2 solo: Bundle + Unbundle básicos, sin By Name
- Cluster compila a `make object! [...]` (Red nativo, compatible `red -c`)
- Sin clusters anidados ni arrays de clusters por ahora

---

### 2026-03-30 — Phase 0 completada (Modelo y registro)

**Tests:** 381/381 PASS (+34 desde base)

**Fase completada:**
- `src/graph/blocks.red`: registrados `bundle` y `unbundle` (categoría 'cluster, puertos fijos + emit vacío)
- `src/graph/model.red`: helpers `cluster-fields`, `cluster-in-ports`, `cluster-out-ports`, `cluster-field-type`
  - `cluster-in-ports` es type-aware: solo devuelve campos para 'bundle
  - `cluster-out-ports` es type-aware: solo devuelve campos para 'unbundle
- Tests: 18 en test-blocks.red + 16 en test-model.red

**Bug encontrado:** `find` devuelve block!, no logic! → wrappear con `not none?`
**Bug encontrado:** Red path `/type` en assert se interpreta como refinamiento → precomputar valor

**Próximo paso:** Phase 1 — Wire marrón y constantes visuales

---

### 2026-03-29 — Phase 5 completada (Front Panel)

**Tests:** 399/399 PASS (sin cambio)

**Fase completada:**
- `src/ui/panel/panel.red`: soporte completo de cluster en Front Panel
  - `fp-cluster-fields` / `fp-cluster-height` — helpers para campos y altura variable
  - `fp-color?` / `fp-border-color?` — cluster-control incluido en grupo "control"
  - `fp-type-label?` / `fp-default-label` — casos cluster
  - `make-fp-item` — campo `config`, data-type 'cluster, default/value como block pares word/valor
  - `render-fp-item` — caja marrón con "CLU" tag y campos "campo: valor" por línea
  - `hit-fp-zone` — altura variable para cluster en hit-test
  - `open-cluster-fp-edit-dialog` — área de texto "campo: valor" por línea
  - `on-click` / `on-dbl-click` — cluster-control abre diálogo de edición
  - `load-panel-from-diagram` — carga cluster-control/cluster-indicator + config
  - `save-panel-to-diagram` — serializa cluster con config
  - `compile-panel` — un widget por campo (field para number/string, check para boolean)
  - `open-fp-palette` — botones "Cluster Ctrl" y "Cluster Ind"
  - BD sync desactivado para cluster (bundle/unbundle se añaden manualmente)

**Próximo paso:** Phase 6 — Serialización

---

### 2026-03-30 — Phase 6 completada (Serialización)

**Tests:** 423/423 PASS (+24 desde Phase 5)

**Descubrimiento clave:** Las tareas 6.1–6.3 ya estaban cubiertas por infraestructura existente:
- `serialize-nodes` ya incluye `config` si no está vacío (líneas 37-40 de file-io.red)
- `make-node` ya restaura `config` desde spec (línea 172 de model.red)
- `format-qvi` usa `mold node-block` → config incluido automáticamente

**Cambios realizados:**
- `tests/test-compiler.red`: 3 suites nuevas de round-trip
  - "cluster — serialize-nodes round-trip bundle" (10 tests)
  - "cluster — serialize-nodes round-trip unbundle" (5 tests)
  - "cluster — FP round-trip cluster-control" (9 tests)

**Próximo paso:** Phase 7 — Tests y ejemplo headless

---

### 2026-03-30 — Phase 7 completada (Tests y ejemplo)

**Tests:** 423/423 PASS (sin cambio)

**Verificación headless:**
```
./red-cli examples/cluster-basico.qvi headless
nombre: sensor_A  voltaje: 12.5  activo: true
```

**Ficheros creados:**
- `examples/cluster-basico.qvi` — bundle 3 campos (string+number+boolean) → unbundle → indicadores

**Issue #12 COMPLETADO:** Todas las fases 0-7 completadas, 423/423 tests PASS.

---

### 2026-03-30 — Prueba final UI (bugs encontrados)

**Bugs del Issue #12:**

| # | Bug | Fichero |
|---|-----|---------|
| B1 | Bundle/Unbundle vacíos tienen altura excesiva | canvas.red |
| B2 | String se auto-actualiza sin Run después del primer Run (GTK on-change queda enganchado) | panel.red |
| B3 | Headless no imprime valores de indicadores en VIs generados desde la UI | compiler.red |

**Bugs pre-existentes (no del #12):**
- Nodos del BD creados desde el FP se apilan hacia abajo y pueden salir del canvas
