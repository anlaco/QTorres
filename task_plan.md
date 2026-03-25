# Task Plan — Issue #14: While Loop

## Meta
| Campo | Valor |
|-------|-------|
| Issue | #14 — While Loop — estructura de control con terminal de condición |
| Inicio | 2026-03-23 |
| Prerequisito | #9 ✅, #10 ✅ |
| Tests base | 132/132 PASS |
| Estrategia | 2 entregas: 14a (loop básico) → 14b (shift registers) |

## Goal
Implementar el While Loop como primer **bloque contenedor** en el Block Diagram, en dos entregas incrementales.

---

# ENTREGA 14a — While Loop básico

Contenedor + terminal condición + terminal iteración `i` + compilador `until`.
Sin shift registers, sin wires cruzando bordes.

## Criterios de aceptación (14a)
- [ ] While Loop aparece como contenedor redimensionable en el canvas
- [ ] Nodos dentro del loop se mueven con él
- [ ] Terminal de condición acepta wire booleano interno
- [ ] Terminal de iteración (i) disponible como fuente de wire interno
- [ ] Compilador genera `until [...]` correcto
- [ ] Save/load del .qvi con structures
- [ ] Añadir/borrar While Loop desde paleta

---

## Phase 0 — Modelo de datos
**Estado:** complete
**Módulos:** model.red, blocks.red

### Modelo: `make-structure`
```red
structure: object! [
    id:        <int>
    type:      'while-loop
    name:      "while_1"
    label:     object! [text: "While Loop" visible: true offset: 0x-15]
    x:         <int>       ; esquina superior-izquierda (absoluta)
    y:         <int>
    w:         300         ; ancho (redimensionable)
    h:         200         ; alto (redimensionable)
    nodes:     block!      ; nodos internos (coords absolutas en memoria)
    wires:     block!      ; wires internos
    cond-wire: none        ; object! [from: <node-id>  port: <word>] o none
]
```

Dónde vive:
```
diagram/
  nodes:      [...]       ; nodos normales (fuera de estructuras)
  wires:      [...]       ; wires normales
  structures: [...]       ; NUEVO — lista de structure objects
```

### Tasks
- [x] 0.1 `make-structure` en model.red
- [x] 0.2 `make-diagram` y `make-diagram-model`: añadir `structures: copy []`
- [x] 0.3 Registrar `while-loop` en blocks.red (categoría 'structure)
- [x] 0.4 `gen-name` ya funciona para while-loop (verificar)
- [x] 0.5 Tests de modelo: 27 nuevos tests en test-model.red (159 total)

---

## Phase 1 — Renderizado
**Estado:** complete
**Módulos:** canvas.red

### Diseño visual
```
┌─ While Loop ─────────────────────────────┐
│                                           │
│   (nodos internos con wires)              │
│                                           │
│  [i]                                  [●] │
└───────────────────────────────────[resize]─┘

Borde:     2px gris azulado oscuro, rounded 8px
Fondo:     ligeramente más oscuro que el canvas
Label:     "While Loop" arriba-izquierda
[i]:       cuadrado azul "i" abajo-izquierda (terminal iteración)
[●]:       círculo verde abajo-derecha (terminal condición booleana)
[resize]:  cuadrado 8x8 esquina inferior-derecha
```

### Tasks
- [x] 1.1 `render-structure` — Draw commands del rectángulo + label
- [x] 1.2 Renderizar terminal condición (●) y terminal iteración (i)
- [x] 1.3 `render-node-list` helper — reutilizable por render-bd y render-structure
- [x] 1.4 `render-wire-list` helper — reutilizable por render-bd y render-structure
- [x] 1.5 Integrar en `render-bd`: llamar `render-structure` para cada structure
- [x] 1.6 Borde de selección cian cuando está seleccionada
- [x] 1.7 Handle de resize visual

---

## Phase 2 — Hit-testing
**Estado:** complete
**Módulos:** canvas.red

### Prioridad (más específico primero)
1. Nodo interno
2. Terminal condición / iteración
3. Wire interno
4. Handle resize
5. Borde del loop (drag)
6. Fondo del loop (deseleccionar / paleta)

### Tasks
- [x] 2.1 `hit-structure-node` — nodos dentro del rectángulo de una structure
- [x] 2.2 `hit-structure-terminal` — terminales condición e iteración
- [x] 2.3 `hit-structure-resize` — handle de esquina
- [x] 2.4 `hit-structure-border` — franja de ~10px del borde
- [x] 2.5 `point-in-structure?` — ¿punto dentro del rectángulo?
- [x] 2.6 Integrar en `on-down`: structures antes que nodos normales (9 prioridades)
- [x] 3.1 Drag de estructura en `on-over` — mueve estructura + nodos internos
- [x] 3.3 Resize en `on-over` — mínimo 120x80

---

## Phase 3 — Interacción
**Estado:** complete
**Módulos:** canvas.red

### Tasks
- [x] 3.1 Drag de estructura en on-over (borde → mover estructura + nodos internos)
- [x] 3.2 Drag de nodo interno con clamp (margen 20px dentro del rectángulo)
- [x] 3.3 Resize con handle (mínimo 120x80)
- [x] 3.4-3.5 Wires terminales: reservado (14a sin shift registers)
- [x] 3.6 Wire entre nodos internos → va a st/wires; node-structure helper
- [x] 3.7 Doble clic en fondo → paleta interna (open-palette/struct); en nodo interno → renombrar
- [x] 3.8 Delete nodo interno (de st/nodes + st/wires) y wire interno
- [x] 3.9 Delete estructura completa (remove-each model/structures)
- [x] 3.10 "While Loop" en open-palette sección Estructuras → palette-add-structure

---

## Phase 4 — Compilador
**Estado:** complete
**Módulos:** compiler.red

### Generación de código
```red
; Sin shift registers, el loop solo tiene iteración + condición
_while_1_i: 0
until [
    ; --- nodos internos (topological sort) ---
    add_1_result: ctrl_1_result + _while_1_i

    ; --- incrementar iteración ---
    _while_1_i: _while_1_i + 1

    ; --- condición (última expresión) ---
    gt_1_result: _while_1_i > 10
    gt_1_result
]
```

### Topological sort con structures
En el sort principal: cada structure es un **nodo virtual**.
- En 14a no hay wires entrantes/salientes → structure no tiene dependencias externas
- Se compila en el orden que aparece (o después de todos los nodos sin dependencias)
- Dentro del until: topological sort del sub-diagrama (structure/nodes + structure/wires)

### Tasks
- [ ] 4.1 `compile-structure` — genera bloque `until [...]` para while-loop
- [ ] 4.2 Topological sort del sub-diagrama
- [ ] 4.3 Inyectar terminal iteración (_while_M_i: 0, incremento)
- [ ] 4.4 Resolver terminal condición como última expresión del until
- [ ] 4.5 Caso borde: condición no conectada → `true` (ejecuta una vez)
- [ ] 4.6 Integrar en `compile-body`: structures se compilan con nodos normales
- [ ] 4.7 Integrar en `compile-diagram` (run-body del botón Run)

---

## Phase 5 — Serialización
**Estado:** complete
**Módulos:** file-io.red

### Formato qvi-diagram
```red
block-diagram: [
    nodes: [...]
    wires: [...]
    structures: [
        while-loop [
            id: 10  name: "while_1"  label: [text: "While Loop"]
            x: 100  y: 80  w: 300  h: 200
            condition: [from: 15  port: 'result]
            nodes: [
                node [id: 11  type: 'add  name: "add_1"  label: [text: "Add"]
                      x: 30  y: 40]  ; coords RELATIVAS a la estructura
            ]
            wires: [
                wire [from: 11  port: 'result  to: 12  to-port: 'a]
            ]
        ]
    ]
]
```

### Tasks
- [ ] 5.1 `serialize-diagram`: incluir `structures:` con nodos internos en coords relativas
- [ ] 5.2 `load-vi`: parsear `structures:`, reconstruir con make-structure, convertir coords relativas → absolutas
- [ ] 5.3 `format-qvi`: formatear structures en .qvi multi-línea
- [ ] 5.4 Test round-trip: save → load → save

---

## Phase 6 — Tests y ejemplo
**Estado:** complete
**Módulos:** tests/, examples/

### Tasks
- [ ] 6.1 Tests modelo: make-structure, fields, defaults
- [ ] 6.2 Tests compilador: while-loop con condición → until correcto
- [ ] 6.3 Tests compilador: terminal iteración accesible
- [ ] 6.4 Tests compilador: condición no conectada → true
- [ ] 6.5 Tests file-io: round-trip con structures
- [ ] 6.6 Ejemplo: `examples/while-loop-basico.qvi` — cuenta de 0 a 9
- [ ] 6.7 Verificación visual manual

---

# ENTREGA 14b — Shift Registers

Pares de terminales ▲/▼ en bordes del loop para mantener estado entre iteraciones.
Prerequisito: 14a completa y estable.

## Criterios de aceptación (14b)
- [ ] Shift registers como pares de terminales izq (▲) / der (▼)
- [ ] Wire externo → SR-left establece valor inicial
- [ ] SR-left → nodo interno (lectura en cada iteración)
- [ ] Nodo interno → SR-right (escritura al final de iteración)
- [ ] SR-right → wire externo (valor final tras el loop)
- [ ] Múltiples shift registers por loop
- [ ] Compilador genera inicialización + actualización correctas
- [ ] Save/load de shift registers en .qvi

---

## Phase 7 — Modelo de shift registers
**Estado:** pending (espera 14a)
**Módulos:** model.red

### Modelo: `make-shift-register`
```red
shift-reg: object! [
    id:         <int>
    name:       "sr_1"
    data-type:  'number     ; inferido del primer wire conectado
    init-value: 0.0         ; default según tipo
    y-offset:   40          ; posición vertical relativa al borde del loop
]
```

Se añade a structure:
```red
structure/shift-regs: [sr-object-1  sr-object-2  ...]
```

### 6 tipos de wire del loop
| Wire | Desde → Hasta | Dónde vive |
|------|--------------|------------|
| Externo → SR-left | nodo externo → SR | diagram/wires (to: structure-id, to-port: 'sr_1_left) |
| SR-left → interno | SR → nodo interno | structure/wires (from: -1, from-port: 'sr_1) |
| Interno → SR-right | nodo interno → SR | structure/wires (to: -2, to-port: 'sr_1) |
| SR-right → externo | SR → nodo externo | diagram/wires (from: structure-id, from-port: 'sr_1_right) |
| Iteración → interno | i → nodo interno | structure/wires (from: -3, from-port: 'i) |
| Interno → condición | nodo → cond | structure/cond-wire |

Convención IDs negativos: -1 = SR-left virtual, -2 = SR-right virtual, -3 = iteración virtual.

### Tasks
- [ ] 7.1 `make-shift-register` en model.red
- [ ] 7.2 Añadir `shift-regs: copy []` a make-structure
- [ ] 7.3 Definir convención de wires a/desde SRs (IDs virtuales o campo especial)

---

## Phase 8 — Renderizado de shift registers
**Estado:** pending
**Módulos:** canvas.red

### Visual
```
      ┌─ While Loop ──────────────────────────┐
      │                                        │
 ▲ sr1├── ←wire ext    wire int→ ──────────────├── sr1 ▼ →wire ext
      │                                        │
 ▲ sr2├──                              ────────├── sr2 ▼
      │                                        │
      │  [i]                               [●] │
      └────────────────────────────────[resize]─┘

▲ = triángulo apuntando arriba (lectura, borde izquierdo)
▼ = triángulo apuntando abajo (escritura, borde derecho)
Color = según data-type del SR (naranja number, verde bool, rosa string)
```

### Tasks
- [ ] 8.1 Renderizar terminales SR (▲ izq, ▼ der) en los bordes
- [ ] 8.2 Renderizar wires externos a/desde SRs
- [ ] 8.3 Texto con init-value cuando SR no tiene wire conectado

---

## Phase 9 — Interacción con shift registers
**Estado:** pending
**Módulos:** canvas.red

### Tasks
- [ ] 9.1 Hit-test en terminales SR (▲/▼)
- [ ] 9.2 Wire externo → SR-left (clic en puerto de nodo externo → clic en ▲)
- [ ] 9.3 Wire SR-right → externo (clic en ▼ → clic en puerto de nodo externo)
- [ ] 9.4 Wire interno desde SR-left (clic en ▲ interior → nodo interno)
- [ ] 9.5 Wire interno a SR-right (nodo interno → clic en ▼ interior)
- [ ] 9.6 Añadir SR: botón en menú/paleta o doble clic en borde
- [ ] 9.7 Borrar SR: delete cuando SR seleccionado + limpiar wires asociados
- [ ] 9.8 Doble clic en SR: editar valor inicial (diálogo)
- [ ] 9.9 Type guard: wire a SR valida tipo compatible

---

## Phase 10 — Compilador con shift registers
**Estado:** pending
**Módulos:** compiler.red

### Generación de código
```red
; Inicialización (antes del until)
_sr_1: 0           ; del wire externo o init-value
_sr_2: ""

_while_1_i: 0
until [
    ; Nodos internos leen _sr_1, _sr_2, _while_1_i
    add_1_result: _sr_1 + _while_1_i

    ; Actualizar SRs (wires internos → SR-right)
    _sr_1: add_1_result
    _sr_2: rejoin [_sr_2 "x"]

    _while_1_i: _while_1_i + 1
    <condición>
]
; _sr_1 y _sr_2 disponibles para nodos externos
```

### Topological sort actualizado
Con shift registers, la structure tiene dependencias externas:
- **Entradas**: wires que llegan a SR-left → nodos fuente deben compilarse antes
- **Salidas**: wires que salen de SR-right → structure debe compilarse antes de nodos destino
- La structure participa en el sort principal como nodo virtual con in-degree/out-degree

### Tasks
- [ ] 10.1 Inicialización de SRs antes del until
- [ ] 10.2 Resolver bindings: SR-left como fuente, SR-right como destino
- [ ] 10.3 Actualizar SRs dentro del until (wires internos → SR-right)
- [ ] 10.4 Topological sort: structure con dependencias externas (wires a/desde SRs)
- [ ] 10.5 Nodos externos leen SRs tras el loop

---

## Phase 11 — Serialización de shift registers
**Estado:** pending
**Módulos:** file-io.red

### Formato qvi-diagram extendido
```red
structures: [
    while-loop [
        id: 10  name: "while_1"  label: [text: "While Loop"]
        x: 100  y: 80  w: 300  h: 200
        shift-registers: [
            sr [id: 20  name: "sr_1"  data-type: 'number  init-value: 0.0  y-offset: 40]
            sr [id: 21  name: "sr_2"  data-type: 'string  init-value: ""   y-offset: 80]
        ]
        condition: [from: 15  port: 'result]
        nodes: [...]
        wires: [...]
    ]
]
```

### Tasks
- [ ] 11.1 Serializar shift-registers dentro de la estructura
- [ ] 11.2 Cargar shift-registers desde qvi-diagram
- [ ] 11.3 Serializar wires externos a/desde SRs (en diagram/wires con to/from: structure-id)
- [ ] 11.4 Test round-trip con SRs

---

## Phase 12 — Tests y ejemplo con shift registers
**Estado:** pending

### Tasks
- [ ] 12.1 Tests: make-shift-register, fields
- [ ] 12.2 Tests compilador: SR inicialización + actualización
- [ ] 12.3 Tests compilador: múltiples SRs
- [ ] 12.4 Tests compilador: SR con wire externo (valor inicial dinámico)
- [ ] 12.5 Tests file-io: round-trip con SRs
- [ ] 12.6 Ejemplo: `examples/while-loop-suma.qvi` — suma acumulativa 1 a 10 con SR
- [ ] 12.7 Verificación visual manual

---

## Riesgos

| Riesgo | Entrega | Impacto | Mitigación |
|--------|---------|---------|------------|
| Hit-test complejo: nodo vs terminal vs borde vs resize | 14a | Alto | Prioridad estricta en Phase 2 |
| Coord relativas/absolutas en save/load | 14a | Medio | Absoluto en memoria, relativo al serializar |
| Topological sort con structures como nodo virtual | 14a/14b | Medio | 14a sin deps externas; 14b añade deps |
| Wires cruzando bordes: routing visual | 14b | Alto | Tratar como wires normales entre coords del borde |
| Type inference de SR desde wire | 14b | Medio | Default 'number; actualizar al conectar wire |
| GTK Draw performance | 14a | Bajo | Monitorizar |

## Exclusiones (futuro)

- **Anidamiento** (while dentro de while)
- **Stacked shift registers** (leer i-1, i-2, etc.)
- **Auto-indexing** (pasar array, procesar por elemento)
- **Feedback nodes**
- **Continue if True** (solo Stop if True)
