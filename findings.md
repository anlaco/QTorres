# Findings — Issue #14: While Loop

## Análisis del codebase (2026-03-23)

### Estado base
- 132 tests, 132 PASS
- Tipos implementados: number, boolean, string
- Infraestructura: topological sort, bind-emit, block-registry, wire color por tipo, type guard

### Qué reutilizar

| Componente | Reutilizable | Notas |
|-----------|-------------|-------|
| `make-node` | Sí | Nodos internos son nodos normales |
| `make-wire` | Sí | Wires internos misma estructura |
| `topological-sort` | Sí | Aplicar al sub-diagrama |
| `bind-emit` + `build-bindings` | Sí | Nodos internos compilan igual |
| `render-bd` nodos/wires | Reutilizar lógica | Para nodos/wires internos |
| `hit-node/hit-port/hit-wire` | Modelo | Replicar para internos |
| `serialize-diagram` | Extender | Sección structures |
| `format-qvi` | Extender | Formatear structures |

### Qué es completamente nuevo

1. Concepto de estructura contenedora (rectángulo con sub-diagrama)
2. Terminales de borde (condición, iteración)
3. Drag compuesto (mover estructura + internos)
4. Resize (dimensiones editables)
5. Compilación jerárquica (sort principal + sub-sort)
6. Variable de iteración _i (pseudo-nodo)
7. [14b] Shift registers (terminales pareados izq/der)
8. [14b] Wires cruzando bordes

### Coordenadas: absoluto en memoria, relativo al serializar

- En memoria: nodos internos con coords absolutas → mismas funciones de render
- Mover estructura: desplazar todos los nodos por delta
- Serializar: restar x/y de estructura → coords relativas
- Cargar: sumar x/y → coords absolutas
- Clamp: nodos no salen del rectángulo (margen 20px)

### Compilación: `until [...]`

LabVIEW While Loop = ejecuta al menos una vez, para cuando condición = true.
Red `until [body]` = ejecuta body hasta que retorne true. Encaje perfecto.

**14a — sin shift registers:**
```red
_while_1_i: 0
until [
    ; nodos internos
    _while_1_i: _while_1_i + 1
    ; condición
    <var-booleana>
]
```

**14b — con shift registers:**
```red
_sr_1: 0                ; init value
_while_1_i: 0
until [
    ; nodos internos leen _sr_1
    add_1_result: _sr_1 + _while_1_i
    ; actualizar SR
    _sr_1: add_1_result
    ; iteración
    _while_1_i: _while_1_i + 1
    ; condición
    <var-booleana>
]
; _sr_1 disponible fuera del loop
```

### Topological sort con structures

**14a**: structure sin dependencias externas → se compila en orden de aparición.

**14b**: structure con SRs tiene dependencias externas:
- Wires a SR-left = entradas (nodos fuente deben compilarse antes)
- Wires desde SR-right = salidas (structure antes de nodos destino)
- Structure = nodo virtual en el sort principal

### 6 tipos de wire del loop (14b)

| Wire | Desde → Hasta | Dónde vive |
|------|--------------|------------|
| Externo → SR-left | nodo externo → SR | diagram/wires |
| SR-left → interno | SR → nodo interno | structure/wires |
| Interno → SR-right | nodo interno → SR | structure/wires |
| SR-right → externo | SR → nodo externo | diagram/wires |
| Iteración → interno | i → nodo interno | structure/wires |
| Interno → condición | nodo → cond | structure/cond-wire |

Convención para wires internos a terminales virtuales:
- from/to: IDs negativos (-1 = SR-left, -2 = SR-right, -3 = iteración)
- O bien: IDs especiales derivados del SR (sr/id para left, sr/id + 1000 para right)
- Decisión final: al implementar Phase 3/7
