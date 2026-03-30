# Task Plan — Issue #12: Cluster

## Meta
| Campo | Valor |
|-------|-------|
| Issue | #12 — Cluster — wire marrón y editor de campos |
| Inicio | 2026-03-29 |
| Prerequisito | #16 ✅ (Case Structure mergeado) |
| Tests base | 347/347 PASS (pendiente verificar) |
| Estrategia | Entrega única: bundle/unbundle con puertos dinámicos |

## Goal
Implementar Cluster como tipo de dato que agrupa valores de tipos distintos (equivalente a struct).
El usuario crea un bundle con N campos, los conecta con wires, y el compilador genera `make object! [...]`.

---

## Criterios de aceptación (del Issue)
- [ ] Wire cluster en marrón
- [ ] Bundle/Unbundle en compilador
- [ ] Editor visual de campos del cluster
- [ ] Cluster en Front Panel como grupo

---

## Phase 0 — Modelo y registro de bloques
**Estado:** complete ✅
**Módulos:** model.red, blocks.red

### Diseño
- `bundle` y `unbundle` se registran en blocks.red como bloques de categoría `'cluster`
- Puertos dinámicos: no se definen en block-def, se generan desde `node/config/fields`
- Config: `[fields [campo1 'tipo1 campo2 'tipo2 ...]]`
- Helpers en model.red: `cluster-fields node`, `cluster-in-ports node`, `cluster-out-ports node`

### Tasks
- [x] 0.1 Registrar `'bundle` en blocks.red (categoría 'cluster, sin puertos fijos, emit vacío)
- [x] 0.2 Registrar `'unbundle` en blocks.red (categoría 'cluster, sin puertos fijos, emit vacío)
- [x] 0.3 Helper `cluster-fields` en model.red — extrae `[name 'type ...]` del config
- [x] 0.4 Helper `cluster-in-ports` en model.red — bundle: devuelve field names; otros: []
- [x] 0.5 Helper `cluster-out-ports` en model.red — unbundle: devuelve field names; otros: []
- [x] 0.5b Helper `cluster-field-type` en model.red — tipo de un campo concreto
- [x] 0.6 `gen-name 'bundle` → "bundle_1", `gen-name 'unbundle` → "unbundle_1"
- [x] 0.7 Tests: 34 tests nuevos (381/381 PASS)

---

## Phase 1 — Wire marrón y constantes visuales
**Estado:** complete ✅
**Módulos:** canvas.red

### Tasks
- [x] 1.1 Constante `col-wire-cluster: 139.69.19` (marrón)
- [x] 1.2 Actualizar `wire-data-color` para devolver `col-wire-cluster` cuando `data-type = 'cluster`
- [x] 1.3 Actualizar `block-color` — categoría 'cluster usa col-wire-cluster (marrón oscuro)

---

## Phase 2 — Renderizado de bundle/unbundle
**Estado:** complete ✅
**Módulos:** canvas.red

### Diseño visual
Bundle y unbundle son nodos normales con altura variable según número de campos.
Cada puerto de campo tiene el color de su tipo (naranja=number, verde=bool, rosa=string).
El puerto cluster (result en bundle, cluster-in en unbundle) es marrón.

### Tasks
- [x] 2.1 `in-ports`/`out-ports` cluster-aware (bundle→campos dinámicos, unbundle→campos dinámicos)
- [x] 2.2 `port-out-type`/`port-in-type` cluster-aware (delega a cluster-field-type)
- [x] 2.3 `node-height` helper — altura variable: max(block-height, 12+N*20+10)
- [x] 2.4 `render-cluster-node` — cuerpo marrón, puertos coloreados por tipo de campo
- [x] 2.5 `render-node-list` delega a render-cluster-node con `continue` para bundle/unbundle

---

## Phase 3 — Hit-testing e interacción
**Estado:** complete ✅
**Módulos:** canvas.red

### Tasks
- [x] 3.1 `hit-node` usa `node-height` — bundle/unbundle clickeables en toda su altura
- [x] 3.2 `hit-port` ya funciona — usa `in-ports`/`out-ports` que son cluster-aware
- [x] 3.3 Wiring type-check automático — `port-out-type`/`port-in-type` son cluster-aware
- [x] 3.4 `apply-cluster-fields` + `parse-cluster-fields-text` — helpers de edición
- [x] 3.5 `open-cluster-edit-dialog` — diálogo área de texto (nombre:tipo por línea)
- [x] 3.6 `on-dbl-click` dispatch — bundle/unbundle abren cluster dialog (nodo normal + interno)
- [x] 3.7 Paleta — botones "Bundle" y "Unbundle" en sección "Cluster:"
- [x] 3.8 Delete — ya funciona (bundle/unbundle son nodos normales)

---

## Phase 4 — Compilador
**Estado:** complete ✅
**Módulos:** compiler.red

### Generación de código

**Bundle** (N inputs → 1 cluster output):
```red
bundle_1_result: make object! [
    name: ctrl_1_value
    voltage: ctrl_2_value
    active: ctrl_3_value
]
```

**Unbundle** (1 cluster input → N outputs):
```red
unbundle_1_name: bundle_1_result/name
unbundle_1_voltage: bundle_1_result/voltage
unbundle_1_active: bundle_1_result/active
```

### Tasks
- [x] 4.1 `emit-bundle` — genera `bundle_1_result: make object! [fn: var ...]` con fields dinámicos
- [x] 4.2 `emit-unbundle` — genera `unbundle_1_fn: cluster_var/fn` por cada campo (path!)
- [x] 4.3 Integrar en `compile-body` — case bundle/unbundle antes del flujo estándar
- [x] 4.4 Integrar en `compile-diagram` run-body — misma bifurcación
- [x] 4.5 Topological sort: bundle/unbundle son nodos normales ✓ (sin cambios)
- [x] 4.6 Tests: emit-bundle, emit-unbundle, pipeline completo bundle→unbundle ejecutado con do
- [x] Tests: 399/399 PASS (+18 tests)

---

## Phase 5 — Front Panel
**Estado:** complete ✅
**Módulos:** panel.red

### Diseño
Cluster en FP se muestra como grupo de controles/indicadores agrupados visualmente.
- Control cluster = grupo editable (cada campo es un sub-control según su tipo)
- Indicator cluster = grupo read-only (cada campo es un sub-indicator)

### Tasks
- [x] 5.1 Tipo 'cluster en `make-fp-item` — campo `config` + data-type 'cluster
- [x] 5.2 Renderizar cluster control en panel como grupo con borde marrón
- [x] 5.3 Renderizar campos internos según tipo (texto "campo: valor" por línea)
- [x] 5.4 `compile-panel` para cluster — un widget por campo (field/check/text)
- [x] 5.5 Diálogo edición valor default del cluster (área de texto campo:valor)

---

## Phase 6 — Serialización
**Estado:** complete ✅
**Módulos:** file-io.red

### Formato qvi-diagram
```red
block-diagram: [
    nodes: [
        node [id: 5  type: 'bundle  name: "bundle_1"  label: [text: "Bundle"]
              x: 200  y: 100
              config: [fields [name 'string  voltage 'number  active 'boolean]]]
        node [id: 6  type: 'unbundle  name: "unbundle_1"  label: [text: "Unbundle"]
              x: 400  y: 100
              config: [fields [name 'string  voltage 'number  active 'boolean]]]
    ]
    wires: [
        wire [from: 5  port: 'result  to: 6  port: 'cluster]
    ]
]

front-panel: [
    control   [id: 1  type: 'cluster  name: "ctrl_1"  label: [text: "Datos"]
               config: [fields [name 'string  voltage 'number  active 'boolean]]
               default: [name: ""  voltage: 0.0  active: false]]
    indicator [id: 2  type: 'cluster  name: "ind_1"   label: [text: "Resultado"]
               config: [fields [name 'string  voltage 'number  active 'boolean]]]
]
```

### Tasks
- [x] 6.1 `serialize-diagram`: config/fields ya incluido por `serialize-nodes` (infraestructura existente)
- [x] 6.2 `format-qvi`: nodes con config se formatean via `mold node-block` (sin cambios)
- [x] 6.3 `load-vi`: `make-node` ya restaura config desde spec (sin cambios)
- [x] 6.4 FP: hecho en Phase 5 — `save/load-panel-to/from-diagram` con config
- [x] 6.5 Tests round-trip: serialize-nodes→load-node-list, save/load-panel (24 tests nuevos → 423/423)

---

## Phase 7 — Tests y ejemplo
**Estado:** complete ✅
**Módulos:** tests/, examples/

### Tasks
- [x] 7.1 Tests modelo: cluster-fields, cluster-in-ports, cluster-out-ports (Phase 0)
- [x] 7.2 Tests bloques: bundle/unbundle registrados correctamente (Phase 0)
- [x] 7.3 Tests compilador: bundle → make object! + unbundle → path access (Phase 4)
- [x] 7.4 Tests compilador: bundle → wire → unbundle (pipeline completo) (Phase 4)
- [x] 7.5 Tests file-io: round-trip con cluster (Phase 6)
- [x] 7.6 `examples/cluster-basico.qvi` — bundle 3 campos (string+number+boolean) → unbundle → mostrar
- [x] 7.7 Verificado headless: `nombre: sensor_A  voltaje: 12.5  activo: true` ✓

---

## Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Puertos dinámicos = patrón nuevo | Alto | Helpers centralizados en model.red, no dispersar lógica |
| canvas.red ya tiene 2383 líneas | Alto | Mínimas adiciones, reutilizar render-node existente |
| bind-emit asume puertos estáticos | Medio | Bifurcar en compile-body para bundle/unbundle |
| Editor de campos complejo | Medio | Diálogo simple: lista de fields, botones +/− |
| FP cluster rendering | Medio | Grupo simple con borde, sin nested scroll |

---

## Exclusiones (futuro)

- **Bundle By Name / Unbundle By Name** — Fase 3+
- **Clusters anidados** (cluster dentro de cluster)
- **Array de clusters**
- **Selector de campos** en unbundle (seleccionar qué campos extraer)
- **Cluster constante** como bloque (literal en el diagrama)
