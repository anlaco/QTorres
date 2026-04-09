# Findings — Fase 3: Sub-VI (#17)

## Investigacion del codebase (2026-04-09)

### Gaps identificados para Sub-VI

| Componente | Estado actual | Que falta |
|------------|--------------|-----------|
| **blocks.red** | Sin entry para `'subvi` | Registro con puertos dinamicos (leidos del connector del .qvi cargado) |
| **model.red:make-node** | Sin campo `file` | Anadir campo `file: none` para nodos subvi |
| **model.red:make-diagram** | Campo `connector: none` existe (l.344) pero nunca se puebla | Parsear y poblar al cargar |
| **file-io.red:serialize-nodes** | No serializa `file:` | Anadir caso para nodos con `file` |
| **file-io.red:load-node-list** | Ignora `file:` del spec | Leer y almacenar en nodo |
| **file-io.red:load-vi** | No parsea `connector:` del qvi-diagram | Anadir regla parse |
| **file-io.red:serialize-diagram** | No emite `connector:` | Anadir seccion |
| **compiler.red:compile-body** | catch-all salta nodos sin bdef | Caso explicito `'subvi`: generar `do %file` + llamada a func |
| **compiler.red:compile-diagram** | Idem en run-body UI | Caso `'subvi` para UI |
| **canvas-render.red:in/out-ports** | Devuelven `[]` para subvi (no hay bdef) | Puertos dinamicos desde connector cargado |
| **canvas-render.red** | Label "SUBVI" ya existe (l.308) | OK, pero renderizar icono del sub-VI |
| **canvas-dialogs.red:open-palette** | Sin boton Sub-VI | Anadir boton + file picker |

### Formato del connector (de suma-subvi.qvi)

```red
connector: [
    input  [id: 1  name: "ctrl_1"  label: [text: "A"]]
    input  [id: 2  name: "ctrl_2"  label: [text: "B"]]
    output [id: 4  name: "ind_1"   label: [text: "Resultado"]]
]
```

### Formato del nodo subvi en el caller (programa-con-subvi.qvi)

```red
node [id: 10  type: 'subvi  x: 200  y: 120  name: "subvi_1"  file: %suma-subvi.qvi  label: [text: "suma"]]
```

Puertos del nodo = labels del connector: `'A`, `'B`, `'Resultado`.

### Codigo generado esperado (hand-written en ejemplo)

**Sub-VI (suma-subvi.qvi):**
```red
suma: func [A [float!] B [float!]] [
    Resultado: A + B
    Resultado
]
```
- Nombre funcion = titulo del VI (Red [title: "suma"])
- Parametros = label/text de connector inputs
- Retorno = ultima variable de connector outputs

**Caller (programa-con-subvi.qvi):**
```red
do %suma-subvi.qvi        ; carga la funcion
ind_1: suma ctrl_1 ctrl_2  ; llamada
```

### Decisiones tecnicas relevantes

- **DT-006:** Sub-VIs generan `func` Red. Standalone con `if not value? 'qtorres-runtime`
- **DT-009:** VIs principales generan Red/View. Sub-VIs generan func sin UI.
- **DT-017:** Tipo de VI lo determina el contexto, no el VI. `connector` habilita uso como sub-VI.
- **DT-028:** Codigo generado debe compilar con `red -c`. Usar `#include` (compile-time), NO `do` (runtime).
- **DT-029 nivel 1:** try/catch por nodo en sub-VIs (Fase 3).

### Decisiones tomadas en sesion de diseno (2026-04-09/10)

1. **`#include` + `context`** — Cada sub-VI se envuelve en `context` con nombre (namespace). El caller usa `#include %subvi.qvi` (compile-time, cumple DT-028). Validado experimentalmente con 3 niveles de anidamiento.
2. **Convencion de llamada: `nombre/exec`** — Sub-VI genera `suma: context [exec: func [...] [...]]`. Caller llama `suma/exec arg1 arg2`. El context da namespace natural, sin colisiones.
3. **Standalone guard con save/restore** — El patron `_qt-imported: value? 'qtorres-runtime` + `if not _qt-imported [unset 'qtorres-runtime]` permite que cada VI funcione standalone Y como sub-VI. Validado con tests.
4. **Unicidad de nombres por titulo** — Nombre del context = titulo del VI. Compilador valida duplicados y da error.
5. **Sin deuda tecnica** — El context es extensible (se puede anadir `panel` func en el futuro). El runner sigue usando `do` en memoria para experiencia IDE completa.

### Puntos de atencion

1. **Puertos dinamicos** — A diferencia de otros bloques (puertos fijos en blocks.red), un subvi tiene puertos definidos por su connector. `in-ports`/`out-ports` en canvas-render.red deben leer del nodo, no del registry.
2. **Carga lazy del connector** — Al anadir un subvi al diagrama, hay que cargar el .qvi referenciado para leer su connector y extraer puertos. Si el fichero no existe, error amigable.
3. **port-var para subvi** — El compilador usa `node/name + "_" + port-name`. Para subvi los port names vienen del connector (ej: `subvi_1_A`).
4. **Nombre del context** — Viene del `title` del .qvi cargado. Se almacena en `node/config` como `[func-name "suma"]`.
5. **Multiples subvi del mismo .qvi** — Cada instancia es un nodo distinto con nombre unico, pero el `#include` se emite una sola vez.
6. **Round-trip** — serialize debe emitir `file:` en nodos subvi y `connector:` en el diagrama.

### Test experimental: #include + context (2026-04-10)

Verificado en `/tmp/red-include-test/` con `red-cli`:

| Test | Resultado |
|------|-----------|
| `#include` de fichero con header `Red [...]` | Header del incluido se ignora ✓ |
| Context con nombre en fichero incluido | Accesible desde caller (`suma/exec`) ✓ |
| 3 niveles anidados (base → middle → top) | Todo funciona ✓ |
| `qvi-diagram` del caller no sobreescrito | Definir despues de includes → ultima asignacion gana ✓ |
| Standalone guard con `qtorres-runtime` | Sub-VIs no ejecutan standalone cuando son incluidos ✓ |
| Save/restore flag para VIs intermedios | `_qt-imported` + `unset 'qtorres-runtime` ✓ |
