# Plan — QA Fix Sprint

## Contexto

Sesión QA ejecutada 2026-03-30 (resultados en `qa-session-2026-03-30.md`). 33 bugs detectados, 13 confirmados como reales. Este plan cubre los fixes ordenados por impacto y riesgo.

**Reglas:** Todo en Red-Lang. No crear módulos nuevos. Ejecutar `red-cli tests/run-all.red` tras cada cambio.

---

## Fix 1 — QA-018: Dos wires al mismo puerto de entrada (CRÍTICO)

**Problema:** No hay validación que impida conectar dos wires al mismo puerto de entrada. Viola visual-spec 5.2.

**Fichero:** `src/ui/diagram/canvas.red`

**Líneas a modificar:** 1904, 2359 (y potencialmente 1966)

**Patrón a seguir:** Línea 2156-2158 (for-loop count) ya hace esto correctamente:
```red
remove-each _w model/wires [
    all [_w/to-node = _fst/id  _w/to-port = 'count]
]
```

**Implementación:**
1. Crear una función helper (o inline) antes de cada `append wire-list make-wire`:
```red
; Antes de crear wire, eliminar wire previo al mismo puerto de entrada
remove-each _w wire-list [
    all [_w/to-node = target-node-id  _w/to-port = target-port-name]
]
```
2. Aplicar en las 3 ubicaciones donde se crea un wire a un puerto de entrada sin check:
   - **Línea ~1904**: wire a nodo interno de estructura — `wire-list` es `st/wires`
   - **Línea ~1966**: wire externo a SR-left — `model/wires`
   - **Línea ~2359**: wire a nodo normal — `wire-list` es `model/wires` o `st/wires`

**Notas:** Verificar cuál es el `wire-list` correcto en cada caso (puede ser `model/wires` para wires del diagrama principal o `st/wires` para wires internos de estructuras).

**Test manual:** Crear dos const, un add. Conectar const_1→add/a. Luego conectar const_2→add/a. Solo debe quedar el segundo wire.

---

## Fix 2 — QA-024: Label compartida entre controles numéricos (CRÍTICO)

**Problema:** Dos causas:
1. `fp-default-label` retorna strings literales (referencia compartida en Red)
2. `open-edit-dialog` tiene campo `flabel` pero nunca lo asigna a `item/label/text`

**Fichero:** `src/ui/panel/panel.red`

**Fix 2a — Copiar string en `fp-default-label` (línea 64-75):**
```red
; ANTES (referencia compartida):
true ["Numeric"]

; DESPUÉS (copia):
true [copy "Numeric"]
```
Añadir `copy` a CADA rama del `case` en `fp-default-label`. Todas retornan strings literales que hay que copiar.

**Fix 2b — Asignar label en `open-edit-dialog` (línea 592-597):**
Dentro del botón OK, ANTES de `unview`, añadir:
```red
if all [edit-dialog-item/label  object? edit-dialog-item/label] [
    edit-dialog-item/label/text: copy flabel/text
]
```

**Test manual:** Crear 2 Num Ctrl en FP. Dbl-click en uno, cambiar label a "Voltaje". Verificar que el otro sigue mostrando "Numeric".

---

## Fix 3 — QA-029: Valores por defecto no se guardan

**Problema:** `save-panel-to-diagram` guarda `item/default` en vez de `item/value`.

**Fichero:** `src/ui/panel/panel.red`

**Línea 896:**
```red
; ANTES:
either block? item/default [append/only spec copy item/default] [append spec item/default]

; DESPUÉS:
either block? item/value [append/only spec copy item/value] [append spec item/value]
```

**Test manual:** Crear Num Ctrl, editar valor a 42. Save. Cerrar. Load. Verificar que muestra 42.

---

## Fix 4 — QA-032: Ejemplo while-loop-basico.qvi corrupto

**Problema:** `wires: []` vacío dentro del while-loop. El nodo `gt-op` referencia variables `a` y `b` sin definir.

**Fichero:** `examples/while-loop-basico.qvi`

**Solución:** Regenerar el ejemplo. El while-loop básico debería:
1. Tener un `const` con límite (ej: 10)
2. Un `gt-op` comparando [i] con el límite
3. Wire de [i] → gt-op/a
4. Wire de const → gt-op/b
5. Wire de gt-op → condición [●]

**Alternativa:** Abrir QTorres, crear el while-loop manualmente con las conexiones correctas, verificar que Run funciona, y guardar como `while-loop-basico.qvi`.

**Verificación:** `./red-cli examples/while-loop-basico.qvi headless` debe ejecutar sin error.

---

## Fix 5 — QA-003/004/005: Puertos de nodos normales sin color por tipo

**Problema:** `render-node-list` (líneas 379-398) usa colores fijos (`col-port-in` azul, `col-port-out` naranja) para TODOS los puertos, sin consultar el tipo de dato.

**Fichero:** `src/ui/diagram/canvas.red`

**Líneas a modificar:** 379-398 en `render-node-list`

**Implementación:** Usar `wire-data-color` con `port-out-type`/`port-in-type` para colorear cada puerto:

```red
; ANTES (líneas ~380-382) — puertos de entrada:
append cmds compose [
    pen col-port-in  fill-pen col-port-in
    circle (as-pair (node/x - port-radius) in-port-y) (port-radius)
]

; DESPUÉS:
p-col: wire-data-color port-in-type node port
append cmds compose [
    pen (p-col)  fill-pen (p-col)
    circle (as-pair (node/x - port-radius) in-port-y) (port-radius)
]
```

```red
; ANTES (líneas ~391-393) — puertos de salida:
append cmds compose [
    pen col-port-out  fill-pen col-port-out
    circle (as-pair (node/x + block-width + port-radius) out-port-y) (port-radius)
]

; DESPUÉS:
p-col: wire-data-color port-out-type node port
append cmds compose [
    pen (p-col)  fill-pen (p-col)
    circle (as-pair (node/x + block-width + port-radius) out-port-y) (port-radius)
]
```

**Importante:** El `port` aquí es el nombre del puerto en el `foreach`. Verificar que el `foreach` itera sobre nombres de puertos (words) y no sobre objetos.

**Nota sobre `port-in-type`/`port-out-type`:** Estas funciones ya existen (líneas 80-100) y devuelven el tipo correcto consultando `blocks.red`.

**Test manual:** Crear bool-const → verificar puerto verde. Crear str-const → verificar puerto rosa. Crear arr-const → verificar puerto azul/naranja con doble borde.

---

## Fix 6 — QA-013/014: Etiquetas cortadas en While/For Loop

**Problema:** `render-structure` (línea 636) dibuja la label en `by + 6` sin usar `text-dy` que compensa el baseline en Linux/GTK.

**Fichero:** `src/ui/diagram/canvas.red`

**Línea 636:**
```red
; ANTES:
text (as-pair (bx + 8) (by + 6)) (st/label/text)

; DESPUÉS:
text (as-pair (bx + 8) (by + 6 + text-dy)) (st/label/text)
```

**Contexto:** `text-dy` está definido en línea 42 como `either system/platform = 'Linux [8] [0]`. Ya se usa en `render-case-structure` (línea 507) pero NO en `render-structure`.

**Test manual:** Crear While Loop y For Loop en Linux. Verificar que las labels "While Loop" y "For Loop" no se cortan por el marco superior.

---

## Fix 7 — QA-015: Layout roto en Case Structure

**Problema:** Símbolos de navegación pegados al borde, número pisa título, botones tapan título.

**Fichero:** `src/ui/diagram/canvas.red`

**Requiere investigación adicional:** Leer `render-case-structure` completa (desde ~línea 490) y ajustar offsets de:
- Barra de navegación (constantes `case-nav-height`, `case-btn-size`)
- Posición del título vs botones ◀▶[+][-]
- Posición del número de frame activo

**Guía:** El fix probablemente es ajustar las constantes de offset y/o reorganizar dónde se dibuja el título respecto a los botones de navegación. Comparar con cómo render-structure posiciona la label de While/For.

---

## Fix 8 — QA-016: Dbl-click en bool-const abre diálogo label

**Problema:** Al hacer doble clic en un `bool-const`, se abre el diálogo de renombrar label. Debería alternar el valor (como hace single-click). La edición de label debería activarse solo con dbl-click en la LABEL, no en el cuerpo del nodo.

**Fichero:** `src/ui/diagram/canvas.red`

**Líneas a modificar:** Handler `on-dbl-click` (~línea 2434-2475)

**Implementación:** Añadir case para `bool-const` en dbl-click:
```red
; Dentro del handler de dbl-click para nodo normal:
if hit-ref/type = 'bool-const [
    toggle-bool-const hit-ref
    ; re-render
    exit
]
```

**Nota del usuario:** En el futuro, dbl-click en la LABEL (no en el cuerpo) debería editar la label, y dbl-click en el cuerpo debería hacer la acción del control. Pero eso requiere separar el hit-test de label vs cuerpo, que es un cambio más grande. Por ahora, hacer que dbl-click en bool-const SIEMPRE alterne.

---

## Fix 9 — #48: Bundle/Unbundle vacíos demasiado grandes

**Problema:** Bundle/Unbundle sin campos tienen tamaño visual excesivo.

**Fichero:** `src/ui/diagram/canvas.red`

**Investigar:** La fórmula `node-height` da 50px (igual que nodos normales) para bundle vacío. El problema puede ser en `render-cluster-node` que reserva espacio extra para la zona de puertos aunque esté vacía. Revisar la función completa (~línea 414-470) y comparar la altura renderizada vs `node-height`.

**Posible fix:** Si `render-cluster-node` añade padding extra innecesario para 0 campos, reducirlo. O si la altura de 50 es correcta pero el render ocupa más espacio visualmente, ajustar el rendering.

---

## Fix 10 — QA-023: Cluster Ctrl/Ind no crean nodo en BD

**Problema:** Al crear un Cluster Ctrl o Cluster Ind desde el FP, no se crea el nodo correspondiente en el BD. El progress.md dice "BD sync desactivado para cluster".

**Fichero:** `src/ui/panel/panel.red`

**Investigar:** Buscar en la función que sincroniza FP→BD (probablemente en la paleta del FP) por qué cluster está excluido. El comentario en progress.md dice "bundle/unbundle se añaden manualmente" — pero debería crear al menos un control/indicator en el BD, no un bundle/unbundle.

**Decisión a tomar:** ¿Cluster Ctrl en FP debería crear un nodo `cluster-control` en BD (como hace Num Ctrl → `control`)? Si es así, hay que añadir el caso en la sincronización FP→BD. Consultar con el usuario si quiere este comportamiento.

---

## Fix 11 — QA-001: BD tapa FP a veces

**Problema:** La ventana FP (400x375) se posiciona en offset 960x60. En pantallas < 1360px de ancho, queda parcialmente oculta.

**Fichero:** `src/qtorres.red`

**Líneas relevantes:** 200-207 (ventana FP), 209-226 (ventana BD)

**Posible fix:** Calcular offset del FP dinámicamente basándose en el tamaño de pantalla:
```red
fp-offset: as-pair (min 960 (system/view/screens/1/x - 420)) 60
```
O reducir el tamaño del BD si la pantalla es pequeña.

**Alternativa minimalista:** Solo asegurar que FP siempre esté visible con `view/no-wait/flags [on-top]` o similar.

---

## Orden de ejecución recomendado

1. **Fix 2** (QA-024 label compartida) — más fácil, 1 fichero, bajo riesgo
2. **Fix 3** (QA-029 valores no se guardan) — 1 línea
3. **Fix 1** (QA-018 dos wires) — crítico pero más complejo
4. **Fix 5** (QA-003/004/005 colores de puertos) — visual, impactante
5. **Fix 6** (QA-013/014 labels cortadas) — 1 línea + text-dy
6. **Fix 4** (QA-032 ejemplo corrupto) — regenerar fichero
7. **Fix 8** (QA-016 bool-const dbl-click) — comportamiento
8. **Fix 9** (#48 cluster vacío) — investigar primero
9. **Fix 7** (QA-015 case layout) — investigar primero
10. **Fix 10** (QA-023 cluster sync) — decisión del usuario
11. **Fix 11** (QA-001 BD tapa FP) — último, bajo impacto

Tras cada fix: `red-cli tests/run-all.red` → 423/423 PASS

---

## Verificación final

1. Ejecutar los 423 tests automatizados
2. Re-ejecutar los tests QA fallidos del checklist `qa-session-2026-03-30.md`
3. Ejecutar todos los ejemplos headless:
   - `./red-cli examples/suma-basica.qvi headless`
   - `./red-cli examples/while-loop-basico.qvi headless`
   - `./red-cli examples/while-loop-suma.qvi headless`
   - `./red-cli examples/for-loop-basico.qvi headless`
   - `./red-cli examples/case-numeric.qvi headless`
   - `./red-cli examples/case-boolean.qvi headless`
   - `./red-cli examples/cluster-basico.qvi headless`
4. Abrir QTorres, crear pipeline suma + cluster + while, guardar, cerrar, recargar, Run
