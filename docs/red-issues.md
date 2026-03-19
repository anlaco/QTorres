# QTorres — Informe de problemas Red-Lang

Análisis estático de los ficheros `.red` del proyecto contra las buenas prácticas del
lenguaje Red (style guide oficial, SKILL.md del proyecto y gotchas documentados).

Niveles de severidad:
- **BUG** — comportamiento incorrecto garantizado o muy probable en ejecución
- **WARN** — posible error o violación de contrato, dependiente del contexto
- **STYLE** — no sigue la guía de estilo oficial; no causa bugs pero reduce legibilidad

---

## 0001 — BUG · `src/graph/model.red:54`

**`any` con booleano `false` siempre devuelve `true`**

```red
visible: any [select spec 'visible  true]
```

`any` evalúa cada elemento; si `visible: false` está en el spec, `select` devuelve
`false`, que es falsy → `any` ignora ese valor y cae al `true` del final.
Resultado: la visibilidad **nunca puede ser `false`** desde el spec.

Corrección idiomática:
```red
visible: either none? select spec 'visible [true] [select spec 'visible]
```

---

## 0002 — BUG · `src/ui/diagram/canvas.red:95`

**Block de Draw con palabras sin evaluar en `render-grid`**

```red
cmds: copy [pen col-grid  fill-pen col-grid  line-width 1]
```

El motor Draw de Red **no evalúa palabras** en el bloque de dibujo; `col-grid` permanece
como `word!` y no como el `tuple!` que espera `pen`/`fill-pen`. La cuadrícula nunca se
dibuja con el color correcto (falla silencioso o error en runtime).

Corrección:
```red
cmds: compose [pen (col-grid)  fill-pen (col-grid)  line-width 1]
```

---

## 0003 — BUG · `src/ui/diagram/canvas.red` ↔ `src/graph/model.red`

**Incompatibilidad de nombres de campos en los wire objects**

`canvas.red` (líneas 354-359) crea wires con:
```red
from-id:  ...
from-p:   ...
to-id:    ...
to-p:     ...
```

`model.red` / `compiler.red` / `file-io.red` esperan:
```red
from-node: ...
from-port: ...
to-node:   ...
to-port:   ...
```

Los wires creados en el canvas son **incompatibles** con el compilador y con
`serialize-diagram` / `load-vi`. Al integrar los módulos, la compilación y el guardado
fallarán con `none` en todos los campos.

---

## 0004 — BUG · `src/graph/blocks.red:87–124`

**Lit-words pasados a parámetro tipado como `word!`**

```red
block 'const 'input [...]
block 'add   'math  [...]
```

La firma de `block` es:
```red
block: func [name [word!]  category [word!]  body [block!] ...]
```

`'const` y `'input` son `lit-word!`, no `word!`. Red aplica type-checking estricto en
parámetros tipados; esta llamada debería lanzar un error de tipo en runtime.
Si no falla actualmente es por una coerción implícita no documentada; en cualquier
caso no es código robusto.

Corrección: cambiar la firma a `[word! lit-word!]` en ambos parámetros, o usar `to-word`
al principio del body.

---

## 0005 — BUG · `src/compiler/compiler.red:222–230`

**Generación de código por concatenación de strings**

```red
append run-body load rejoin [face-n "/text"]
append run-body load rejoin [face-n "/text:"]
```

Se usa `rejoin` + `load` para construir rutas de acceso como `f_1/text`. Esto es
generación de código mediante strings, explícitamente prohibida por DT-008:
> "El compilador manipula bloques Red, nunca genera strings intermedios"

Además, si `face-n` contiene caracteres especiales, `load` puede fallar o producir
un resultado inesperado.

Corrección idiomática con `compose`:
```red
append run-body compose [(to-set-word port-var node 'result) to-float (:face-n)/text]
```

---

## 0006 — WARN · `src/graph/model.red:144`

**`object` sin `make` en la definición del prototipo base**

```red
base-element: object [
    id: 0  name: ""  label: none  x: 0  y: 0
]
```

`object` sin `make` no es la forma canónica. El patrón oficial es:
```red
base-element: make object! [...]
; o
base-element: context [...]
```

Algunas versiones de Red pueden aceptar `object [...]` como azúcar sintáctico, pero
no está garantizado. Usar `context [...]` es más portable y legible.

---

## 0007 — WARN · `src/graph/model.red:178–180`

**Mutación del bloque `spec` de entrada**

```red
if none? select lbl-spec 'visible [
    append lbl-spec compose [visible: (default-label-visible? n/type)]
]
```

`lbl-spec` es el bloque que el llamante pasó en `spec`. Si ese bloque es un literal
del código fuente (p.ej. `[text: "A"]`), **mutarlo con `append` corrompe el bloque
original** (gotcha #1 de series — aliasing). En carga desde `.qvi`, el bloque viene
de `load`, por lo que es probable que sea fresco, pero no está garantizado.

Corrección: `lbl-spec: copy lbl-spec` antes de hacer `append`.

---

## 0008 — WARN · `src/runner/runner.red:26–29`

**`qtorres-runtime` queda a `true` si `do code` lanza error**

```red
qtorres-runtime: true
code: compile-body diagram
do code
qtorres-runtime: false    ; nunca se ejecuta si do falla
```

Si `do code` provoca un error, el flag permanece en `true` indefinidamente, lo que
puede causar que los sub-VIs no se auto-ejecuten en llamadas posteriores correctas.

Corrección:
```red
qtorres-runtime: true
attempt [do compile-body diagram]
qtorres-runtime: false
```

---

## 0009 — WARN · `src/ui/diagram/canvas.red:27–53`

**`switch` sin caso por defecto en `ncolor`, `in-ports` y `out-ports`**

```red
ncolor: func [node-type] [
    switch node-type [
        control   [col-block-ctrl]
        indicator [col-block-ind]
        add       [col-block-op]
        sub       [col-block-op]
    ]
]
```

Si `node-type` no está en la lista (p.ej. un bloque `mul` o `display`), `switch`
devuelve `none`. `ncolor` devuelve `none`, que luego se usa en `compose [fill-pen (block-color)]`
→ error en el motor Draw. Lo mismo aplica a `in-ports`/`out-ports` → `foreach port none`
→ crash.

Añadir un caso por defecto en cada `switch`.

---

## 0010 — WARN · `src/ui/diagram/canvas.red:57–58`

**`index? find ports port-name` sin guardia de `none`**

```red
port-index: index? find ports port-name
```

Si `find` devuelve `none` (puerto no existe en el nodo), `index?` sobre `none` causa
error. No hay comprobación previa.

---

## 0011 — WARN · `src/io/file-io.red:156`

**`if not empty?` — no idiomático en Red**

```red
if not empty? names [sync-name-counters names]
```

La forma idiomática Red es `unless`:
```red
unless empty? names [sync-name-counters names]
```

---

## 0012 — WARN · `src/graph/model.red:80–83`

**Docstring de función dentro del body en vez del spec**

```red
reset-name-counters: does [
    "Reinicia todos los contadores de nombres"
    clear name-counters
]
```

En Red, la docstring va en el **spec** de la función, no en el body.
Para `does` (sin argumentos) la convención es añadir el string como primer argumento
del spec de `func` vacío si se quiere documentación accesible por `help`:
```red
reset-name-counters: func ["Reinicia todos los contadores de nombres"] [
    clear name-counters
]
```
Así la convierte en documentable con `help reset-name-counters`.

---

## 0013 — WARN · `src/graph/model.red:96–99`

**Bucle manual para unir partes de string — preferir `rejoin`**

```red
type-str: copy ""
repeat i ((length? parts) - 1) [
    if i > 1 [append type-str "_"]
    append type-str parts/:i
]
```

Equivalente más legible y correcto con `rejoin`:
```red
type-str: rejoin collect [
    repeat i ((length? parts) - 1) [
        if i > 1 [keep "_"]
        keep parts/:i
    ]
]
```
O directamente con `copy/part`:
```red
type-str: form rejoin next next reverse copy parts  ; (ejemplo conceptual)
```
El bucle manual es propenso a errores de índice.

---

## 0014 — WARN · `src/compiler/compiler.red:109`

**`to-set-word v` sin guardar tipo de `v`**

```red
set-word? item [
    k: to-word item
    v: select bindings k
    append result either v [to-set-word v] [item]
]
```

`to-set-word` espera un `word!`, `string!` o `lit-word!`. Si `v` es un `integer!`,
`float!`, u otro escalar, `to-set-word` fallará. No hay type guard.

---

## 0015 — WARN · `src/graph/model.red:207–212`

**`make-port` — campos obligatorios sin validación**

```red
make-port: func [spec [block!]] [
    make object! [
        id:        select spec 'id
        name:      select spec 'name
        direction: select spec 'direction
        ...
    ]
]
```

Si `spec` no contiene `'id`, `'name` o `'direction`, los campos quedan en `none`
sin error. El error aparecería tarde, en tiempo de uso del puerto. Añadir validación
o al menos valores por defecto explícitos con `any [select spec 'id  0]`.

---

## 0016 — STYLE · `src/ui/diagram/canvas.red:444–475`

**Lógica de renombrado duplicada en `on-enter` y `button "OK"`**

El bloque de código que aplica el renombrado aparece dos veces (líneas 444-458 y
461-475) dentro del diálogo `view/no-wait`. Si se modifica uno, el otro queda
desactualizado. Extraer en una función local o un bloque compartido.

---

## 0017 — STYLE · `src/ui/diagram/canvas.red:493–555`

**Código de demo ejecutado en el nivel superior del módulo**

Las líneas 493-555 crean el modelo de demo y llaman a `view` directamente. Si
`canvas.red` se `do`'d desde otro módulo (p.ej. `qtorres.red`), la ventana de
demo se abrirá inmediatamente.

Proteger con una guardia de script:
```red
if system/options/script = system/script/path [
    ; demo aquí
]
```
O mover el demo a un fichero separado `tests/canvas-demo.red`.

---

## 0018 — STYLE · `src/ui/diagram/canvas.red:507–518`

**Demo crea nodos con `make object!` directo, sin usar `make-node` de `model.red`**

```red
append demo-model/nodes make object! [
    id: node-id  type: node-type  name: ...  label: make object! [...]  x: ...  y: ...
]
```

Bypasea la API del módulo de modelo. Si `make-node` cambia, el demo queda
desincronizado y puede generar nodos con campos faltantes.

---

## 0019 — STYLE · `src/io/file-io.red:72–84`

**`save-vi` genera el header del fichero `.qvi` con concatenación de strings**

```red
content: rejoin [
    {Red [Title: } mold diagram/name { Needs: 'View]} "^/"
    ...
]
```

El proyecto establece como convención no generar código mediante strings (DT-008).
Aunque esta es la sección de la cabecera Red (no un dialecto propio), el uso de
`rejoin` con `mold` puede producir salida incorrecta si `diagram/name` contiene
comillas o caracteres especiales.

Alternativa más robusta: usar un template de bloque y `mold`:
```red
header: reduce [to-set-word 'Red  compose [Title: (diagram/name)  Needs: 'View]]
write path append mold header "^/..."
```

---

## 0020 — STYLE · `src/qtorres.red`

**Punto de entrada sin `Needs: 'View` cuando la UI lo requerirá**

```red
Red [
    Title:   "QTorres"
    ...
]
```

Una vez que se integren los módulos de UI, el punto de entrada necesitará `Needs: 'View`.
No es un bug ahora (es un stub), pero es mejor añadirlo antes de que los módulos de
UI rompan al cargarse sin View disponible.

---

## Resumen por fichero

| Fichero | BUG | WARN | STYLE | Total |
|---------|-----|------|-------|-------|
| `src/graph/model.red` | 1 | 4 | 1 | 6 |
| `src/ui/diagram/canvas.red` | 2 | 3 | 3 | 8 |
| `src/compiler/compiler.red` | 1 | 1 | — | 2 |
| `src/graph/blocks.red` | 1 | — | — | 1 |
| `src/io/file-io.red` | — | 1 | 1 | 2 |
| `src/runner/runner.red` | — | 1 | — | 1 |
| `src/qtorres.red` | — | — | 1 | 1 |
| **Total** | **5** | **10** | **6** | **21** |

---

## Prioridad de corrección

**Crítico (antes de integrar módulos):**
- 0003 — Incompatibilidad wire `canvas` ↔ `model/compiler/file-io`
- 0001 — Bug boolean `false` en `make-label`
- 0002 — Draw block con palabras sin evaluar en `render-grid`
- 0004 — Tipo incorrecto en llamadas a `block`

**Importante (antes de pruebas de integración):**
- 0005 — Generación de código por strings en compilador
- 0007 — Mutación del spec de entrada en `make-node`
- 0008 — Flag `qtorres-runtime` no se resetea en error
- 0009 — Switch sin default en funciones de geometría

**Menor (deuda técnica):**
- 0010 al 0020
