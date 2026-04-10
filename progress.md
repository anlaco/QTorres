# Progress Log — Fase 3: Libreria .qlib (#18)

## Session 2026-04-10 — Planificacion

### Contexto
- Issue #17 (sub-VI) completado en branch feat/17-subvi-connector
- 462 tests PASS, linea base limpia
- Issues #64 (FP master) y #65 (resize+scroll) creados para Fase 3
- DT-030 documentada (framework sobre Red/View + Draw)

### Investigacion
- Revisado Issue #18, docs/tipos-de-fichero.md, PLANNING.md
- Analizado patron sub-VI existente (#17): #include + context + compile-subvi-call
- Identificado que .qlib es una capa de descubrimiento sobre el patron sub-VI existente
- Impacto minimo: solo file-io.red (parseo) + canvas-dialogs.red (paleta)
- Plan de 4 fases creado en task_plan.md
- Decisiones D1-D6 documentadas

### Implementacion completada (2026-04-10)

**Fase 1 — load-qlib y find-qlibs (file-io.red):**
- load-qlib: parsea qlib.red, devuelve objeto con name/version/dir/members
- find-qlibs/from: escanea directorio buscando subdirectorios .qlib
- Fix: make object! con compose/only para evitar conflicto de nombres

**Fase 2 — Paleta integrada (canvas-dialogs.red):**
- palette-add-qlib-vi: añade nodo subvi apuntando a .qvi de librería
- open-palette ahora es dinámica: construye layout-block con find-qlibs/from what-dir
- Sección 'Librerías' aparece si hay .qlib en el directorio de trabajo

**Fase 3 — Ejemplo funcional:**
- examples/math.qlib/qlib.red + add.qvi + subtract.qvi
- examples/usa-libreria.qvi: usa add y subtract de math.qlib (headless: Suma:20 Resta:8)
- Fix: exec func necesita /local para evitar solapamiento de vars globales entre sub-VIs

**Tests:**
- tests/test-qlib.red: 19 tests nuevos
- 481 tests PASS (eran 462)
- Issue #18 cerrado

### Próximo paso
- #64 FP como ventana maestra
