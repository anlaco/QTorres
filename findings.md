# Findings & Decisions — Issue #7: Front Panel modular

## Requirements
<!-- Captured from issue #7 -->
- Controles numéricos editables (`field`)
- Indicadores numéricos (`text` que se actualiza)
- Botón Run visible en el panel
- Elementos arrastrables para reposicionar
- Posiciones se persisten en `front-panel:` del `qvi-diagram`

## Critical Architectural Distinction (DT-009)

| Modo | Cuándo | Tecnología | Propósito |
|------|--------|------------|-----------|
| **Edición** | En QTorres | `base` face + Draw dialect | Drag, hit-test, posición, shapes |
| **Ejecución** | `.qvi` compilado | VID layout (`view [...]`) | `field` editable, `text` reactivo, `button` |

**Implicación:** El panel tiene DOS renders:
1. `render-panel` → face con Draw para edición (drag & drop)
2. `compile-panel` → bloque VID para ejecución (DT-009)

## Research Findings

### Red/View VID dialect para ejecución
- Controles numéricos → `field` (editables)
- Indicadores numéricos → `text` (solo lectura visual)
- Labels → `label` VID word
- Botón Run → `button`
- Layout: VID es declarativo, generado por `compile-panel`

### Red/View Draw dialect para edición
- Usar `base` face con `draw: [...]`
- Shapes: `box`, `text`, `circle`
- Hit-testing con coordenadas absolutas (igual que canvas.red)
- Drag actualiza `offset` del `fp-item`, luego redraw

### Patrón de drag & drop en canvas.red
- `on-down`: detecta clic, inicia drag si es elemento
- `on-over`: actualiza posición si `event/down?`
- `on-up`: limpia estado de drag
- Modelo vive en `face/extra`

### Edición inline de valores
- Clic en un control → crear `field` temporal sobre el shape
- On-enter → guarda valor en `fp-item/value`, destruye field
- El valor se usa cuando `compile-panel` genera el código

### Estructura existente del modelo
- `make-diagram-model` en `canvas.red:86` — objeto con `nodes`, `wires`, `next-id`, `selected-node`, etc.
- `base-element` + `make-label` patrón (DT-022/023)
- Label como objeto con `text`, `visible`, `offset`

### Formato front-panel en qvi-diagram (DT-005, DT-011)
```red
front-panel: [
    control   [id: 1  type: 'numeric  name: "ctrl_1"  label: [text: "A" visible: true]  default: 5.0  offset: 50x30]
    indicator [id: 2  type: 'numeric  name: "ind_1"   label: [text: "Resultado" visible: true]  offset: 50x150]
]
```

### Código generado para ejecución (DT-009)
```red
view layout [
    label "A"    fA: field "5.0"
    label "B"    fB: field "3.0"
    button "Run" [
        A: to-float fA/text
        B: to-float fB/text
        Resultado: A + B
        lResultado/text: form Resultado
    ]
    label "Resultado:"  lResultado: text "---"
]
```

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| Dos modos: edición vs ejecución | DT-009 exige `view layout` para .qvi ejecutable |
| Edición = `base` + Draw | Permite drag & drop, hit-testing, mismo patrón que canvas.red |
| Ejecución = VID layout | `field` y `text` son widgets interactivos reales |
| `fp-item` como objeto análogo a nodo | Consistencia con DT-022/DT-023 |
| `offset` (pair!) para posición | Red tiene tipo nativo, fácil de serializar |
| `make-fp-item` constructor | Sigue patrón DT-023 (composición sobre herencia) |
| Campo `value` en fp-item | Guarda valor editado durante la sesión de edición |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
| VID layout no permite drag fácil | Usar Draw para edición, VID solo para ejecución |

## Resources
- `src/ui/diagram/canvas.red` — patrón drag & drop y Draw
- `src/ui/panel/panel.red` — stub actual
- `docs/arquitectura.md` — sección Front Panel y Runner
- `docs/decisiones.md` — DT-009, DT-022, DT-023, DT-024
