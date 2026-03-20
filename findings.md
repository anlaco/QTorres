# Findings & Decisions — Issue #7: Front Panel modular

## Requirements
<!-- Captured from issue #7 -->
- Controles numéricos editables (`field`)
- Indicadores numéricos (`text` que se actualiza)
- Botón Run visible en el panel
- Elementos arrastrables para reposicionar
- Posiciones se persisten en `front-panel:` del `qvi-diagram`

## Research Findings

### Red/View VID dialect para Front Panel
- Controles numéricos → `field` (editables)
- Indicadores numéricos → `text` (solo lectura visual)
- Labels → `label` VID word
- Botón Run → `button`
- Layout: Red/View VID es declarativo,face returned por `layout`

### Patrón de drag & drop en canvas.red
- `on-down`: detecta clic, inicia drag si es nodo
- `on-over`: actualiza posición si `event/down?`
- `on-up`: limpia estado de drag
- Modelo vive en `face/extra`

### Estructura existente del modelo
- `make-diagram-model` en `canvas.red:86` — objeto con `nodes`, `wires`, `next-id`, `selected-node`, etc.
- `base-element` + `make-label` patrón (DT-022/023)
- Label como objeto con `text`, `visible`, `offset`

### Formato front-panel en qvi-diagram (DT-011)
```red
front-panel: [
    control   [id: 1  type: 'numeric  name: "ctrl_1"  label: [text: "A" visible: true]  default: 5.0]
    indicator [id: 2  type: 'numeric  name: "ind_1"   label: [text: "Resultado" visible: true]]
]
```

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| Usar `field` para controles | Red/View nativo, editable por defecto |
| Usar `text` para indicadores | Display de solo lectura, actualizable via `/text` |
| `fp-item` como objeto análogo a nodo | Consistencia con DT-022/DT-023 |
| Drag vía `on-over` con `event/down?` | Mismo patrón que canvas.red |
| Posiciones en `offset` (pair!) | Red tiene tipo nativo para coordenadas |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
| (none yet) | |

## Resources
- `src/ui/diagram/canvas.red` — patrón drag & drop
- `src/ui/panel/panel.red` — stub actual
- `docs/arquitectura.md` — sección Front Panel
- `docs/labview-comportamiento.md` — comportamiento labels
