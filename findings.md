# Findings — Issue #16: Case Structure

## Investigación inicial (2026-03-26)

### Estructuras existentes: While/For Loop

**Archivo:** `src/graph/model.red:261-295`
- `make-structure` ya soporta While/For Loop
- Campo `type:` distingue el tipo de estructura
- Estructura tiene: `id, type, name, label, x, y, w, h, nodes, wires, cond-wire, shift-regs`

**Patrón de extensión:**
```red
s/type: any [select spec 'type  'while-loop]
```
Puede extenderse para aceptar `'case-structure`

### Compilador actual

**Archivo:** `src/compiler/compiler.red:312-415`
- `compile-structure` bifurca por `st/type`:
  - `while-loop` → `until [...]`
  - `for-loop` → `loop N [...]`
- Patrón sencillo de extensión: añadir rama `case st/type = 'case-structure`

### Serialización (Actualizado 2026-03-26)

**Archivo:** `src/io/file-io.red`
- `serialize-diagram` itera sobre `diagram/structures`
  - **Patrón clave:** usar `case` en lugar de `switch` porque los valores son lit-words
  - `switch st/type` no funciona porque `st/type` es word!, no lit-word!
  - `case [st/type = 'for-loop [...] st/type = 'while-loop [...]]` funciona correctamente
- `format-qvi` formatea cada tipo con su keyword
  - Case-structure añade `frames: [...]` y `active-frame: N` y `selector: [...]`
- `load-vi` parse con `parse structs-data [...]`
  - Case-structure: parse `frames` array con `relative → absolute` coord conversion

**Key gotcha:** Red's `1-based indexing` — frame 0 en qvi-diagram es `frames/1` en memoria

### Renderizado

**Archivo:** `src/ui/diagram/canvas.red:361-563`
- `render-structure` genera Draw commands para rectángulo + terminales + nodos internos
- Terminales actuales:
  - `[i]` — iteración (while/for)
  - `[●]` — condición (while)
  - `[N]` — count (for)
- Para Case: necesita terminal selector en esquina superior-izquierda

### Hit-testing

**Archivo:** `src/ui/diagram/canvas.red:740-769`
- `hit-structure-terminal` detecta `[i]`, `[●]`, `[N]`
- Extensible para detectar terminal selector de case

### Patrones de LabVIEW Case Structure

**Comportamiento:**
1. Selector puede ser numérico, booleano, string, enum
2. Cada "case" es un frame con su propio diagrama
3. Frames tienen labels que se muestran en el selector
4. Usuario navega entre frames con flechas
5. Default case se ejecuta si no hay match

**Diferencias con While/For:**
- Múltiples frames internos vs uno solo
- Navegación activa entre frames (solo uno visible a la vez)
- Terminal selector tiene tipo dinámico (inferido del wire conectado)

### Decisiones de diseño

1. **Terminal selector arriba-izquierda** (igual que `[N]` de for-loop)
2. **Barra de navegación arriba** con ◀ [N] ▶ [+][−]
3. **Frames como sub-diagramas** independientes (nodes/wires propios)
4. **Sin túneles de salida en Fase 2** — simplificación, solo ejecución interna
5. **Selector obligatorio** — Case sin selector = error de compilación

---

## Historial (Issue #14: While Loop — ARCHIVADO)

### Análisis del codebase (2026-03-23)

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

### Topological sort con structures

Structure con SRs tiene dependencias externas:
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