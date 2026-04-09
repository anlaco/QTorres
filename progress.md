# Progress Log — Fase 3: Sub-VI (#17)

## Session 2026-04-09 — Planificacion

### Cierre Fase 2 completado
- PR #62 mergeado: refactor 4D/4E, fixes cluster, v0.2.0
- Ramas limpiadas: solo main queda (local y remoto)
- Tag v0.2.0 publicado
- Issues #28 y #49 movidos a fase-3
- 462 tests PASS, linea base limpia

### Investigacion Sub-VI
- Analisis exhaustivo del codebase: compiler, model, file-io, canvas, blocks
- Gaps documentados en findings.md
- Ejemplos existentes (suma-subvi.qvi, programa-con-subvi.qvi) son hand-written, no funcionales con el compilador actual
- Plan de 5 fases creado en task_plan.md
- Decisiones de diseno D1-D6 documentadas

### Fase 1 — Modelo y serializacion COMPLETADA
- 1.1: Campo `file: none` añadido al prototipo de `make-node`
- 1.2: Helper `load-subvi-connector` implementado (carga connector desde .qvi)
- 1.3: Helper `make-subvi-node` implementado (crea nodo con file + config)
- 1.4: `serialize-nodes` emite `file:` para nodos subvi
- 1.5: `make-node` lee campo `file` del spec (carga)
- 1.6: `serialize-diagram` emite sección `connector:`
- 1.7: `load-vi` parsea `connector:` del qvi-diagram
- 462 tests PASS

### Fase 2 — Compilador (parcial)
- 2.1: Bloque 'subvi registrado en blocks.red (category: 'function)
- 2.2: Función `compile-subvi-call` implementada
- 2.3: Caso 'subvi añadido a `compile-body`
- 2.4: Caso 'subvi añadido a `compile-diagram` (modo UI)
- 2.5-2.7: Pendientes (#include, func generation, unicidad)
- 462 tests PASS

### Session 2026-04-10 — Revision de arquitectura (con Opus)

**Cambio fundamental:** De inlining de funcs a `#include` + `context`.

**Decisiones revisadas:**
- D4: `#include %subvi.qvi` en vez de inlinar funcs (validado con tests en /tmp/red-include-test/)
- D5: Sub-VI genera `nombre: context [exec: func [...] [...]]`, caller llama `nombre/exec`
- Patron save/restore de `qtorres-runtime` para VIs intermedios que incluyen sub-VIs
- Verificado: Red strip header de ficheros incluidos, qvi-diagram del caller no se sobreescribe

**Problemas resueltos:**
- `do` rompe `red -c` → `#include` es compile-time ✓
- `#include` de .qvi entero causa header duplicado → Red lo maneja ✓
- Sub-VIs anidados → save/restore de flag funciona ✓
- Colision de nombres → context da namespace natural ✓

**Impacto en Fase 2 (compilador):**
- 2.5: cambiar de inlining a emitir `#include` + save/restore
- 2.6: generar `context [exec: func [...]]` en vez de func bare
- 2.8: llamadas usan `nombre/exec` en vez de `nombre`
- Simplifica el compilador (no necesita compilar recursivamente sub-VIs)

### Proximo paso
- Completar Fase 2: #include emission, context generation, validacion de unicidad
