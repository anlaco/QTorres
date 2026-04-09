# Findings — Transición Fase 2

## Bug #54 — Cluster no persiste campos

**Issue:** https://github.com/anlaco/QTorres/issues/54

**Síntomas:**
1. Al añadir campos a cluster-control en el editor → puertos no aparecen en BD
2. Al cerrar y reabrir el editor → campos desaparecen (no persisten)
3. Cluster-indicator no permite añadir ningún elemento

**Componentes sospechosos:**
- `src/ui/diagram/canvas.red` — editor de cluster, render de puertos
- `src/ui/panel/panel.red` — gestión de cluster-indicator

**Estado:** Pendiente de investigación con Task explore agent.

---

## Auditoría Fase 2 (2026-04-03)

**Documento:** `docs/auditoria-fase-2.md` (generado por qwen3-coder:480b)

**Veredicto:** 🟢 Verde funcional, 🟡 refactor bloqueante para Fase 3

**Hallazgos críticos:**
- panel.red (1255 líneas) tiene responsabilidades de compilación y serialización
- canvas.red (2557 líneas) demasiado grande — riesgo pérdida contexto
- Ciclo canvas↔panel impide testing aislado
- Abstracciones faltantes: `find-node-by-id` (ya implementado en #56), `set-config`

---

## Protecciones QA pendientes

Extraídas de plan QA antiguo, estado desconocido:

**QA-018:** Prohibir múltiples wires al mismo puerto entrada (Regla absoluta #6)
- Ubicación: `make-wire` en canvas.red o model.red

**QA-024:** Fix `fp-default-label` + asignación label en `open-edit-dialog`
- Ubicación: panel.red

**QA-029:** `save-panel-to-diagram` debe guardar `item/value`, no `item/default`
- Ubicación: panel.red
- Impacto: Round-trip incorrecto FP → qvi-diagram → FP

---

## Estado de Issues Fase 2

**Bugs abiertos:**
- #54 (cluster) — CRÍTICO bloqueante
- #48 (bundle/unbundle altura) — menor
- #49 (string auto-update) — menor, posible GTK
- #50 (headless no imprime) — menor
- #51 (nodos apilados) — menor

**Features pendientes:**
- #16 (Case Structure) — ¿completado? Verificar
- #13 (Waveform) — ✅ completado en #55
- #12 (Cluster) — ✅ completado en #52, pero #54 es regresión
- #28 (FP standalone) — decisión pendiente: ¿Fase 2 o 3?

---

## Arquitectura actual

**Líneas de código (2026-04-07):**
- canvas.red: 2557
- panel.red: 1255
- compiler.red: 891
- file-io.red: 647

**Dependencias problemáticas:**
- canvas.red → panel.red: `render-fp-panel`
- panel.red → canvas.red: `render-bd`, `gen-node-id`
- panel.red → compiler.red: ❌ NO (panel compila solo)
- panel.red → file-io.red: ❌ NO (panel serializa solo)

**Chain loading actual (qtorres.red):**
```red
#include %graph/model.red
#include %graph/blocks.red
#include %compiler/compiler.red
#include %io/file-io.red
#include %runner/runner.red
#include %ui/diagram/canvas.red
#include %ui/panel/panel.red
```

Orden crítico: canvas antes que panel (por dependencia circular).

---

## Próximas investigaciones

1. **Grep QA-018/024/029:** Verificar si ya están aplicadas en el código actual
2. **Task explore #54:** Flujo cluster-control editor → config/fields → render puertos
3. **Inventario canvas.red:** Agrupar funciones por categoría (render/eventos/dialogs)

---

## Histórico — Issue #13 (Waveform, completado)

<details>
<summary>Investigación LabVIEW (2026-04-03)</summary>

### Diferencia fundamental Chart vs Graph

| Aspecto | Waveform Chart | Waveform Graph |
|---------|----------------|----------------|
| **Datos** | Buffer circular (history) | Sin buffer |
| **Actualización** | Incremental (punto a punto) | Batch (reemplaza todo) |
| **Input** | Acepta scalar O array | Requiere array |
| **Uso** | Real-time, loops | Post-análisis |

### Default buffer size

LabVIEW usa 1024 puntos por defecto.

### Decisión de diseño QTorres

**Waveform Chart:**
```red
type: 'waveform-chart
data-type: 'number
config: [history-size 1024]
value: []  ; buffer circular
```

**Waveform Graph:**
```red
type: 'waveform-graph
data-type: 'array
value: []  ; array completo
```

Wire colors: Chart naranja, Graph naranja doble borde (array).

</details>
