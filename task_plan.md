# Task Plan — Issue #16: Case Structure

## Meta
| Campo | Valor |
|-------|-------|
| Issue | #16 — Case Structure — selector con múltiples frames |
| Inicio | 2026-03-26 |
| Prerequisito | #14 ✅, #15 ✅ |
| Tests base | 271/271 PASS |
| Tests actuales | 327/327 PASS |
| Estrategia | Entrega única: estructura completa con frames navegables |

## Goal
Implementar Case Structure como **contenedor con múltiples frames** (casos) intercambiables en el canvas. El usuario navega entre frames y cada frame contiene nodos distintos. Compila a `case`/`switch` o `either` según el tipo del selector.

---

## Criterios de aceptación
- [ ] Case Structure como contenedor en canvas
- [ ] Terminal selector acepta wire numérico o booleano
- [ ] Botones de navegación (◀/▶) para cambiar frame activo
- [ ] Indicador visual del frame actual (ej: "0", "1", "2"... o "Default")
- [ ] Cada frame contiene sus propios nodos y wires
- [ ] Botón "+" para añadir frame, botón "−" para eliminar frame activo
- [ ] Compilador genera `case`/`switch` (numérico) o `either` (booleano)
- [ ] Save/load del .qvi con case-structure y frames

---

## Phase 0 — Modelo de datos
**Estado:** complete ✅
**Módulos:** model.red, blocks.red, test-model.red

### Tasks
- [x] 0.1 `make-frame` en model.red — constructor de frame (id, label, nodes, wires)
- [x] 0.2 Extender `make-structure` para soportar type: 'case-structure
- [x] 0.3 Registrar 'case-structure en blocks.red (categoría 'structure)
- [x] 0.4 `gen-name 'case-structure` → "case_1", "case_2", etc.
- [x] 0.5 Tests de modelo: make-frame, make-structure con type: 'case-structure (26 tests nuevos)

---

## Phase 1 — Renderizado
**Estado:** complete ✅
**Módulos:** canvas.red

### Diseño visual
```
┌─ Case Structure ─────────────────────┐
│ ◀ [0] ▶   [+][−]                        │  ← barra superior: navegación
│                                           │
│   (nodos y wires del frame activo)       │
│                                           │
│  [?]                                    │  ← terminal selector arriba-izq
└────────────────────────────────[resize]─┘

Borde:     2px gris azulado oscuro (mismo que while-loop)
Fondo:     ligeramente más oscuro que el canvas (mismo que while-loop)
Label:     "Case Structure" arriba-izquierda
◀/▶:      botones de navegación (flechas)
[0]:       indicador de frame actual (texto)
[+][−]:    botones añadir/eliminar frame
[?]:       terminal selector (cuadrado naranja)
```

### Constantes añadidas
- `case-nav-height: 24` — altura de la barra de navegación
- `case-btn-size: 18` — tamaño de botones ◀ ▶ [+][-]
- `col-case-nav-bg: 45.70.110` — fondo de barra de navegación

### Tasks
- [x] 1.1 Constantes visuales en canvas.red
- [x] 1.2 `render-case-structure` — barra navegación + terminal selector + frame activo
- [x] 1.3 Render nodos y wires del frame activo (st/frames/(st/active-frame))
- [x] 1.4 Handle resize en esquina inferior-derecha
- [x] 1.5 Borde de selección cian

---

## Phase 2 — Hit-testing
**Estado:** complete ✅
**Módulos:** canvas.red

### Prioridad (más específico primero)
1. Botones de navegación ◀ ▶ [+][-]
2. Terminal selector
3. Nodos internos del frame activo
4. Wires internos del frame activo
5. Handle resize
6. Borde del contenedor (drag)
7. Fondo del contenedor (deseleccionar)

### Tasks
- [x] 2.1 `hit-case-nav-buttons` — detecta clic en ◀ ▶ [+][-]
- [x] 2.2 `hit-case-terminal` — detecta clic en terminal selector [?]
- [x] 2.3 `hit-structure-node` actualizado — busca en frame activo para case-structure
- [x] 2.4 `hit-structure-terminal` actualizado — detecta 'selector para case-structure
- [x] 2.5 Reutilizar `hit-wire-in-list` para frame activo

---

## Phase 3 — Interacción
**Estado:** pending
**Módulos:** canvas.red

### Navegación entre frames
- **◀**: decremente active-frame (mínimo 0)
- **▶**: incrementa active-frame (máximo frames - 1)
- **Clic en indicador**: menú dropdown con lista de frames (opcional para Fase 2)
- **[+]**: añade nuevo frame al final con label = str(length frames)
- **[−]**: elimina frame activo (mínimo 1 frame, el Default no se puede eliminar)

### Drag del contenedor
- Mover estructura arrastra todos los frames (coords absolutas)
- Mover nodo interno: solo dentro del frame activo, con clamp al margen

### Resize
- Mismo comportamiento que while-loop

### Terminal selector
- Clic en terminal selector → inicia wire (como puerto normal)
- Clic en puerto de nodo externo → completa wire en terminal selector
- Tipo de dato: numérico (cualquier entero) o booleano

### Tasks
- [ ] 3.1 `on-down` en botones de navegación — cambiar active-frame
- [ ] 3.2 `on-down` en botones [+][-] — añadir/eliminar frame
- [ ] 3.3 Drag de estructura completa (mismo patrón que while-loop)
- [ ] 3.4 Drag de nodo interno dentro del frame activo
- [ ] 3.5 Resize del contenedor
- [ ] 3.6 Wire a terminal selector (type-check: number o boolean)
- [ ] 3.7 Delete de estructura — elimina todos los frames
- [ ] 3.8 Delete de nodo interno — elimina del frame activo y sus wires

---

## Phase 4 — Compilador
**Estado:** pending
**Módulos:** compiler.red

### Generación de código (numérico)
```red
; Selector conectado a un nodo numérico
_selector: <variable-externa>
case _selector [
    0 [
        ; nodos del frame 0 (orden topológico)
        add_1_result: ctrl_1_result + 5
    ]
    1 [
        ; nodos del frame 1
        mul_1_result: ctrl_1_result * 2
    ]
    default [
        ; nodos del frame Default
        sub_1_result: ctrl_1_result - 10
    ]
]
```

### Generación de código (booleano)
```red
; Selector conectado a un nodo booleano
_selector: <variable-externa>
either _selector [
    ; True frame
    add_1_result: ctrl_1_result + 5
][
    ; False frame (solo 2 frames para boolean)
    mul_1_result: ctrl_1_result * 2
]
```

### Sin selector conectado
Para Fase 2: Caso de error — generar warning o ejecutar default. El selector es obligatorio.

### Topological sort
- Cada frame tiene su propio sub-diagrama
- Compilar frames en orden: primero todos los frames internos, luego el case
- Los frames NO tienen dependencias entre sí (son mutuamente excluyentes)

### Tasks
- [ ] 4.1 `compile-case-structure` — bifurcación en `compile-structure`
- [ ] 4.2 Detección de tipo de selector (number vs boolean)
- [ ] 4.3 Generación de `case` para selector numérico
- [ ] 4.4 Generación de `either` para selector booleano
- [ ] 4.5 Tratamiento de frame "Default" como `default` en case
- [ ] 4.6 Error si selector no conectado
- [ ] 4.7 Integrar en `compile-body` y `compile-diagram`

---

## Phase 5 — Serialización
**Estado:** pending
**Módulos:** file-io.red

### Formato qvi-diagram
```red
structures: [
    case-structure [
        id: 10  name: "case_1"  label: [text: "Case Structure"]
        x: 100  y: 80  w: 300  h: 200
        selector: [from: 5  port: 'result]  ; opcional
        active-frame: 0
        frames: [
            frame [id: 0  label: "0"
                   nodes: [node [id: 11 ...]]  ; coords relativas
                   wires: [wire [...]]]
            frame [id: 1  label: "1"
                   nodes: [...]  wires: [...]]
            frame [id: 2  label: "Default"
                   nodes: [...]  wires: [...]]
        ]
    ]
]
```

### Tasks
- [ ] 5.1 `serialize-diagram`: incluir case-structure con frames
- [ ] 5.2 `format-qvi`: formatear case-structure en .qvi multi-línea
- [ ] 5.3 `load-vi`: parsear case-structure, reconstruir frames (coords relativas → absolutas)
- [ ] 5.4 Test round-trip: save → load → save

---

## Phase 6 — Tests y ejemplo
**Estado:** pending
**Módulos:** tests/, examples/

### Tests
- [ ] 6.1 Tests modelo: make-frame, make-structure con case-structure
- [ ] 6.2 Tests compilador: case-structure con selector numérico → `case`
- [ ] 6.3 Tests compilador: case-structure con selector booleano → `either`
- [ ] 6.4 Tests compilador: múltiples frames
- [ ] 6.5 Tests file-io: round-trip con case-structure
- [ ] 6.6 Tests canvas: navegación entre frames

### Ejemplos
- [ ] 6.7 `examples/case-numeric.qvi` — selector numérico con 3 frames
- [ ] 6.8 `examples/case-boolean.qvi` — selector booleano (if/else)

---

## Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Navegación entre frames compleja UI | Alto | Usar mismo patrón de clic/hit-test que while-loop |
| Coords relativas/absolutas en frames | Medio | Mismo patrón que nodos internos de while-loop |
| Terminal selector tipo dinámico | Bajo | Detectar tipo al cablear, validación en compilación |
| Case sin default | Bajo | Siempre incluir frame "Default" al crear |

---

## Exclusiones (futuro)

- **Túneles de salida** (output tunnels como LabVIEW)
- **Entradas de frame** (input tunnels)
- **Case structures anidadas**
- **Selector string** (solo number y boolean en Fase 2)