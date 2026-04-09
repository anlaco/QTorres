# Plan — Fase 3: Sub-VI con connector pane (#17)

**Creado:** 2026-04-09
**Objetivo:** Permitir que un VI con `connector` se use como bloque dentro de otro VI, con puertos dinamicos, compilacion a `func` Red, y round-trip completo.

**Linea base:** 462 tests PASS, v0.2.0, main limpia.

## Reglas absolutas (recordatorio)

- Todo en Red-Lang. Sin crear modulos nuevos sin aprobacion.
- `./red-cli tests/run-all.red` debe pasar tras cada cambio.
- Consultar `skills/red-lang/SKILL.md` antes de tocar Draw/View.
- NUNCA `do` dinamico, `load` strings, ni `compose` runtime en .qvi generado (DT-028).
- Los puertos del subvi vienen del connector del .qvi cargado, no de blocks.red.

## Decisiones de diseno

### D1: Puertos dinamicos vs registro en blocks.red

**Decision:** Los puertos del nodo subvi se almacenan en `node/config` como `[connector [...]]` al momento de insertar el nodo. `in-ports`/`out-ports` en canvas-render.red consultan esta config cuando `node/type = 'subvi`. blocks.red tiene un entry minimo (categoria, sin puertos fijos).

**Razon:** Cada subvi tiene puertos distintos segun su connector. No se puede registrar en blocks.red con puertos fijos.

### D2: Campo `file` en el nodo

**Decision:** Anadir campo `file: none` al prototipo de nodo en `make-node`. Solo se puebla para nodos `'subvi`. Se serializa/carga en file-io.red.

### D3: Nombre del context = titulo del VI (unicidad obligatoria)

**Decision:** El nombre del context viene del `title` del header Red del .qvi cargado. Se almacena en `node/config` como `[func-name "suma"]`. El compilador valida que no haya dos sub-VIs con el mismo titulo — si colisionan, error de compilacion.

**Razon:** Igual que LabVIEW, donde los nombres de VI deben ser unicos dentro del proyecto. El context da namespace natural (`suma/exec`).

### D4: `#include` + context (validado con tests)

**Decision:** El codigo generado usa `#include %subvi.qvi` con cada sub-VI envuelto en un `context` con nombre. Validado experimentalmente con 3 niveles de anidamiento.

**Patron del sub-VI (.qvi con connector):**
```red
Red [title: "suma" Needs: 'View]
qvi-diagram: [...]

suma: context [
    exec: func [A [float!] B [float!] /local Resultado] [
        Resultado: A + B
        Resultado
    ]
]

if not value? 'qtorres-runtime [
    context [view layout [...]]
]
```

**Patron del sub-VI que usa otros sub-VIs:**
```red
Red [title: "filtro" Needs: 'View]
qvi-diagram: [...]

_qt-imported: value? 'qtorres-runtime
qtorres-runtime: true
#include %suma.qvi
if not _qt-imported [unset 'qtorres-runtime]

filtro: context [
    exec: func [X [float!]] [suma/exec X 0.5]
]

if not value? 'qtorres-runtime [
    context [view layout [...]]
]
```

**Patron del VI caller (programa principal):**
```red
Red [title: "main" Needs: 'View]
qvi-diagram: [...]

qtorres-runtime: true
#include %filtro.qvi

context [
    view layout [
        button "Run" [l_ind_1/text: form filtro/exec to-float f_ctrl_1/text]
    ]
]
```

**Comportamiento verificado:**
- `red suma.qvi` → standalone, muestra panel ✓
- `red filtro.qvi` → standalone, muestra panel (suma NO ejecuta standalone) ✓
- `red main.qvi` → solo main, ni filtro ni suma ejecutan standalone ✓
- `red -c main.qvi` → compilable, #include es compile-time ✓

**Ventajas sobre inlining:**
- Cada VI es 100% independiente — ejecutable por si solo
- El compilador de QTorres solo emite #include + llamadas, NO necesita compilar recursivamente sub-VIs
- Los namespaces (context) evitan colisiones de forma natural
- El .qvi del sub-VI es la fuente de verdad — si cambia, el caller lo ve al recompilar

**Razon:** `#include` es compile-time (cumple DT-028). El context con nombre da namespace. El patron save/restore de `qtorres-runtime` permite que cada VI funcione standalone Y como sub-VI sin conflictos.

### D5: `context` con `exec` para sub-VIs

**Decision:** El codigo generado sigue esta estructura:
- **VI con connector:** `nombre: context [exec: func [...] [...]]` + standalone guard
- **VI sin connector (solo standalone):** `context [view layout [...]]`
- **VI que usa sub-VIs:** save/restore flag + `#include`s + su propio context (si tiene connector) o standalone

**Convencion de llamada:** `suma/exec arg1 arg2` — el context es el namespace, `exec` es la funcion.

**Razon:** No hay diferencia entre "VI principal" y "sub-VI" — un VI con connector siempre genera context + standalone guard, independientemente de como se use (DT-017). El caller decide si lo incluye.

### D6: Connector se edita manualmente (por ahora)

**Decision:** Un VI que quiera ser usable como sub-VI necesita una seccion `connector:` en su `qvi-diagram`. En esta fase, el connector se edita manualmente en el .qvi. El editor visual de connector pane es fase posterior.

### D7: Error handling (DT-029 nivel 1)

**Decision:** Cada llamada a sub-VI se envuelve en `try`: `result: try [subvi-name/exec arg1 arg2]`. Si falla, se propaga el error nativo de Red.

### D8: Vision a largo plazo — sin deuda tecnica

El modelo de dos caminos (runner vs .qvi generado) permite:
- **Runner (IDE):** abrir multiples VIs, sub-VI mostrando su panel, valores en vivo — todo posible via `do` en memoria + `view/no-wait`
- **Compilado (.qvi):** binario autocontenido via `#include`. Sub-VIs son context con `exec` (sin panel) en Fase 3.

**Evolucion futura sin romper arquitectura:**
- Sub-VIs con panel en compilado: anadir func `panel` al context → `suma/panel`. Cambio aditivo, no rompe `exec`.
- Multiples VIs abiertos: cada context es independiente, no comparten estado.
- Clases (.qclass): futuro, modelo diferente.
- El unico riesgo conocido es `app-model` unico (un VI en memoria), que se abordara con .qproj.

Las decisiones de esta fase no bloquean ninguna de estas evoluciones.

## Fases de implementacion

### Fase 1 — Modelo y serializacion ✅ COMPLETADA

> Cimientos: que el formato se cargue, persista y haga round-trip.

- [x] **1.1** `model.red`: campo `file: none` en `make-node`
- [x] **1.2** `model.red`: helper `load-subvi-connector`
- [x] **1.3** `model.red`: helper `make-subvi-node`
- [x] **1.4** `file-io.red`: `serialize-nodes` emite `file:`
- [x] **1.5** `file-io.red`: `load-node-list` lee `file:`
- [x] **1.6** `file-io.red`: `serialize-diagram` emite `connector:`
- [x] **1.7** `file-io.red`: `load-vi` parsea `connector:`
- [x] **1.8** Tests round-trip
- [x] **1.9** 462 tests PASS

### Fase 2 — Compilador ⬜

> Que el codigo generado sea correcto para caller y callee.

- [x] **2.1** `blocks.red`: registrar `'subvi` con block-def minimo (category: 'function, sin puertos, sin emit)
- [x] **2.2** `compiler.red`: funcion `compile-subvi-call` que genera la llamada `nombre/exec arg1 arg2`
- [x] **2.3** `compiler.red`: en `compile-body`, caso `item/type = 'subvi` → `compile-subvi-call`
- [x] **2.4** `compiler.red`: en `compile-diagram` run-body, caso `'subvi` para modo UI
- [ ] **2.5** `compiler.red`: emitir `#include %subvi.qvi` + save/restore `qtorres-runtime` al inicio del codigo generado. Recopilar ficheros unicos (sin duplicados).
- [ ] **2.6** `compiler.red`: para VIs con connector propio, generar `nombre: context [exec: func [...] [...]]` + standalone guard con save/restore
- [ ] **2.7** `compiler.red`: validar unicidad de func-name entre todos los sub-VIs referenciados — error si colision
- [ ] **2.8** Actualizar `compile-subvi-call` para usar convencion `nombre/exec` en vez de func directa
- [ ] **2.9** Tests: compile-body con nodo subvi, codigo generado correcto, round-trip compile
- [ ] **2.10** Tests pasan. Commit.

### Fase 3 — Renderizado y UI ⬜

> Que el subvi se vea y se pueda anadir desde el editor.

- [ ] **3.1** `canvas-render.red`: `in-ports` / `out-ports` — si `node/type = 'subvi`, leer puertos de `node/config` en vez de blocks registry
- [ ] **3.2** `canvas-render.red`: renderizar nodo subvi con icono (si tiene) o caja generica con label = func-name
- [ ] **3.3** `canvas-render.red`: colores de puertos segun tipo del connector (number/string/boolean/etc)
- [ ] **3.4** `canvas-dialogs.red`: boton "Sub-VI" en paleta → file picker (`request-file`) → `make-subvi-node` → anadir al diagrama
- [ ] **3.5** `canvas.red`: hit-test de puertos del subvi (misma logica que otros nodos, pero puertos dinamicos)
- [ ] **3.6** Test manual: crear diagrama con subvi, conectar wires, verificar render
- [ ] **3.7** Commit.

### Fase 4 — Ejemplo funcional end-to-end ⬜

> Que suma-subvi.qvi + programa-con-subvi.qvi funcionen de verdad.

- [ ] **4.1** Actualizar `examples/suma-subvi.qvi`: qvi-diagram con connector + codigo generado (context + standalone guard)
- [ ] **4.2** Actualizar `examples/programa-con-subvi.qvi`: qvi-diagram con nodo subvi + codigo generado (#include + context)
- [ ] **4.3** Verificar: `./red-cli examples/programa-con-subvi.qvi` produce resultado correcto
- [ ] **4.4** Verificar: cargar en QTorres, editar, guardar, volver a cargar → round-trip OK
- [ ] **4.5** Test automatizado: headless round-trip del ejemplo
- [ ] **4.6** Commit + PR.

### Fase 5 — Cierre ⬜

- [ ] **5.1** Actualizar CLAUDE.md (estado Fase 3, nuevos ficheros/funciones, D4 como nueva DT)
- [ ] **5.2** Cerrar Issue #17
- [ ] **5.3** Actualizar version a 0.3.0 y tag

## Criterios de exito

- `./red-cli tests/run-all.red` → todos pasan
- `./red-cli examples/suma-subvi.qvi` → standalone funciona
- `./red-cli examples/programa-con-subvi.qvi` → output correcto (headless, usa sub-VI)
- Round-trip: cargar .qvi con subvi → guardar → cargar → mismos datos
- Un VI con connector genera `nombre: context [exec: func [...]]` + standalone guard
- Un VI caller genera `#include` + llamada `nombre/exec` correcta
- Compilador detecta colision de nombres entre sub-VIs
- Nodo subvi se renderiza con puertos del connector en el canvas

## Riesgos

| Riesgo | Mitigacion |
|--------|-----------|
| `#include` de .qvi con header Red | Verificado: Red strip header de ficheros incluidos ✓ |
| `qvi-diagram` sobreescrito por includes | Caller define su qvi-diagram DESPUES de includes → ultima asignacion gana ✓ |
| Standalone guard en sub-VIs anidados | Patron save/restore validado con 3 niveles ✓ |
| Connector con tipos no-number (string, bool, cluster) | Fase 1 solo number, extender despues |
| Fichero .qvi referenciado no existe | Error amigable en `load-subvi-connector`, no crash |
| Puertos dinamicos rompen hit-test en canvas | Reusar misma logica de port positioning pero con lista dinamica |
| Cambio en connector del subvi invalida el caller | Detectar en load, warning al usuario — fase posterior |
| Dos sub-VIs con mismo titulo | Compilador valida y da error (D3) |

## Log de errores

| Error | Intento | Resolucion |
|-------|---------|------------|
| _(se rellenara durante ejecucion)_ | | |
