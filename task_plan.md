# Task Plan — Issue #7: Front Panel modular

## Meta
| Campo | Valor |
|-------|-------|
| Issue | [#7 — Front Panel modular](https://github.com/anlaco/QTorres/issues/7) |
| Labels | enhancement, fase-1 |
| Estado | OPEN |
| Inicio | 2026-03-20 |

## Goal
Implementar `src/ui/panel/panel.red` como módulo independiente con controles e indicadores arrastrables, equivalente al canvas del Block Diagram.

## Criterios de aceptación
- [ ] Panel muestra controles e indicadores del `qvi-diagram`
- [ ] Controles permiten editar valores de entrada
- [ ] Indicadores muestran valores de salida tras Run
- [ ] Elementos arrastrables para reposicionar
- [ ] Posiciones se persisten en `qvi-diagram`

---

## Phase 1 — Diseño del modelo de datos del Front Panel
**Responsable:** Modelo  
**Duración:** Estimada  
**Estado:** pending

### Tasks
- [ ] Diseñar estructura `fp-item` (control/indicator) análoga a `base-element` (DT-022/DT-023)
- [ ] Definir campos: `id`, `type`, `name`, `label` (objeto), `default`, `value`, `offset`
- [ ] Diseñar `make-fp-item` constructor
- [ ] Añadir `front-panel` al modelo del diagrama (`make-diagram-model` ya existe)

### Entregable
Estructura de datos para items del front panel.

---

## Phase 2 — Parser del `front-panel:` en qvi-diagram
**Responsable:** File I/O  
**Duração:** Estimada  
**Estado:** pending

### Tasks
- [ ] Procesar bloque `front-panel:` del `qvi-diagram`
- [ ] Reconstruir lista de `fp-item` desde la spec
- [ ] Integrar con `make-diagram-model`

### Entregable
Lectura de front-panel desde qvi-diagram.

---

## Phase 3 — render-panel: cara visual Red/View
**Responsable:** UI/Panel  
**Duração:** Estimada  
**Estado:** pending

### Tasks
- [ ] Función `render-panel model panel-width panel-height → face`
- [ ] Generar `field` para cada control (numérico)
- [ ] Generar `text` para cada indicador (numérico)
- [ ] Generar `label` con el texto de `label/text`
- [ ] Botón Run visible
- [ ] Drag & drop de elementos (patrón análogo a `render-diagram`)
- [ ] Hit-testing para seleccionar elementos
- [ ] Actualizar `offset` de `fp-item` tras drag

### Entregable
Face funcional con controles arrastrables.

---

## Phase 4 — Binding de valores con el modelo
**Responsable:** UI/Panel + Runner  
**Duração:** Estimada  
**Estado:** pending

### Tasks
- [ ] Binding bidireccional: control → modelo (al editar)
- [ ] Binding unidireccional: modelo → indicador (tras Run)

### Entregable
Valores fluyen entre panel y modelo.

---

## Phase 5 — Persistencia de posiciones
**Responsable:** File I/O  
**Duração:** Estimada  
**Estado:** pending

### Tasks
- [ ] Guardar posiciones de `fp-item` en `front-panel:` del `qvi-diagram`
- [ ] Cargar posiciones al abrir VI

### Entregable
Layout persiste entre sesiones.

---

## Phase 6 — Test standalone del módulo panel
**Responsable:** QA  
**Duração:** Estimada  
**Estado:** pending

### Tasks
- [ ] Verificar controles e indicadores se renderizan
- [ ] Verificar arrastrar controles
- [ ] Verificar Run actualiza indicadores
- [ ] Verificar persistencia de layout

### Entregable
Módulo panel funcional standalone.

---

## Phase 7 — Integración en qtorres.red (Issue #8)
**Responsable:** App  
**Duração:** Estimada  
**Estado:** pending (belongs to Issue #8)

### Tasks
- [ ] Cargar `panel.red` desde `qtorres.red`
- [ ] Crear `render-panel` junto a `render-diagram`
- [ ] Gestionar visibilidad de ambos paneles

### Entregable
App completa con Block Diagram + Front Panel (Issue #8).

---

## Phase 8 — Test y verificación final
**Responsable:** QA  
**Duração:** Estimada  
**Estado:** pending

### Tasks
- [ ] Verificar con `examples/suma-basica.qvi` (panel standalone)
- [ ] Verificar arrastrar controles/indicadores
- [ ] Verificar layout persiste entre cargas
- [ ] Nota: "Run actualiza indicadores" requiere Runner (Issue #10)

### Entregable
Issue #7 cerrado.

## Notes
- Integración completa (Issue #7 + #8) es para test final
- Runner (Issue #10) es independiente — needed for "Run shows results"
- Drag & drop ya existente en `canvas.red` — reutilizar patrón
- `base-element` + `make-label` (DT-022/023) es el patrón a seguir
