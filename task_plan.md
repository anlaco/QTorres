# Plan — Transición limpia a Fase 3

**Creado:** 2026-04-07
**Objetivo:** Cerrar Fase 2 con calidad para abrir Fase 3 (#17 Sub-VIs) sin arrastrar deuda bloqueante.

## Fuentes

- `docs/auditoria-fase-2.md` (2026-04-03, qwen3-coder:480b) — veredicto 🟢 verde con refactor 🟡 bloqueante
- `CLAUDE.md` sección "Problemas conocidos de arquitectura"
- Issues abiertos: #28, #48, #49, #50, #51, #54 + QA-018/024/029

## Reglas absolutas (recordatorio)

- Todo en Red-Lang. Sin crear módulos nuevos sin aprobación.
- `./red-cli tests/run-all.red` debe pasar tras cada cambio (línea base: 450/450).
- NUNCA empezar una fase sin completar la anterior.
- NUNCA mergear PRs sin aprobación del usuario.
- Consultar `skills/red-lang/SKILL.md` antes de tocar Draw/View.

## Estrategia de delegación a Ollama

Delegación habilitada a través de MCP configurado en el proyecto. El contexto (CLAUDE.md + skill Red-Lang) se carga automáticamente.

| Tarea | Herramienta recomendada | Razón |
|-------|-------------------------|-------|
| Lectura masiva de canvas.red/panel.red | Task tool con agent explore | Contexto largo, análisis de codebase |
| Búsqueda de patrones específicos | Grep/Glob directos | Más rápido que delegar |
| Generación de tests Red | Decisión case-by-case | Según complejidad |
| Decisiones arquitectónicas | Claude (NO delegar) | Ollama no razona bien trade-offs |
| Escritura de ficheros | Claude (NO delegar) | Requiere revisión manual |

## Hitos del plan

### Fase 0 — Sincronización ✅ COMPLETADA

- [x] **0.1** Informar de divergencia local vs origin/main
- [x] **0.2** Reset a origin/main (commit 8dc1610)
- [x] **0.3** Verificar línea base: **450 tests PASS**
- [x] **0.4** Contar líneas actuales: canvas.red (2557), panel.red (1255), compiler.red (891), file-io.red (647)
- [ ] **0.5** Revisar si QA-018/024/029 ya se aplicaron — grep/diff

### Fase 1 — Bug bloqueante #54 Cluster (CRÍTICO)

> Regresión funcional detectada en QA. No se puede abrir Fase 3 con Cluster roto.

**Síntomas (Issue #54):**
1. Puertos no aparecen al añadir campos al cluster-control
2. Config/fields no persiste al cerrar y reabrir el editor
3. Cluster-indicator no permite añadir ningún elemento

**Plan:**
- [x] **1.1** Usar Task tool (explore agent) para localizar en canvas.red + panel.red el flujo cluster dbl-click → editor → persistencia
- [x] **1.2** Claude: leer fragmentos identificados, diagnosticar causa raíz
- [x] **1.3** Aplicar fixes
- [x] **1.4** Añadir tests de regresión (persistencia config + round-trip cluster con N campos)
- [x] **1.5** Prueba manual: crear cluster-ctrl, añadir 3 campos, cerrar, reabrir, verificar
- [x] **1.6** Tests pasan (450+). Crear PR (sin mergear — esperar aprobación)

### Fase 2 — Protecciones de auditoría (🔴 ROJO)

- [x] **2.1** QA-018: proteger `make-wire` para no permitir 2 wires al mismo puerto entrada (Regla absoluta #6)
- [x] **2.2** QA-024: fix `fp-default-label` + asignación label en `open-edit-dialog`
- [x] **2.3** QA-029: `save-panel-to-diagram` debe guardar `item/value`, no `item/default`
- [x] **2.4** Tests de regresión para las 3 protecciones
- [x] **2.5** PR de safety fixes

### Fase 3 — Bugs Fase 2 menores

- [x] **3.1** #48 Bundle/Unbundle vacíos con altura excesiva (`canvas.red`)
- [x] **3.2** #49 Control string auto-actualiza sin Run (`panel.red`)
- [x] **3.3** #50 Modo headless no imprime valores desde UI-generated VIs
- [x] **3.4** #51 Nodos creados desde FP se apilan — calcular offset libre
- [x] **3.5** Cada fix → test → commit agrupado por fichero
- [x] **3.6** PR de bug batch

### Fase 4 — Refactor estructural (🟡 BLOQUEANTE PARA #17)

> Auditoría marca panel.red y ciclo canvas↔panel como bloqueantes para Sub-VIs.

#### 4A — Mover responsabilidades mal ubicadas

- [x] **4A.1** Grep para listar todas las llamadas a funciones mal ubicadas
- [x] **4A.2** Mover `compile-panel` + helpers → `compiler.red`
- [x] **4A.3** Mover `save/load-panel-*` → `file-io.red`
- [x] **4A.4** Mover `make-fp-item` → `model.red`
- [x] **4A.5** Mover `make-diagram-model` → `model.red`
- [x] **4A.6** Chain loading verificado: model→blocks→compiler→runner→file-io→canvas→panel ✅
- [x] **4A.7** Tests 465/465 PASS ✅ (2026-04-08)
- [x] **4A.8** PR #60 abierto (actualización body bloqueada por bug gh Projects classic)

#### 4B — Abstracción `set-config`

- [ ] **4B.1** Grep patrón `either pos: find node/config` en src/
- [x] **4B.2** Añadir `set-config` a `model.red`
- [x] **4B.3** Aplicar helper en todas las ocurrencias (parcial: canvas.red ✅, panel.red pendiente)
- [ ] **4B.4** Tests → PR


#### 4D — Split conservador de canvas.red ✅ COMPLETADA

> Prerrequisito: 4A completada. (4C eliminada — acoplamiento canvas↔panel es correcto por diseño del dominio)

- [x] **4D.1** Inventario exhaustivo de canvas.red por categoría (2526 líneas → 3 secciones)
- [x] **4D.2** Agrupación: render puro / hit-test+CRUD+actor / diálogos+paleta+SR
- [x] **4D.3** Creado `canvas-render.red` (932 líneas): constantes + geometría + render Draw
- [x] **4D.4** Creado `canvas-dialogs.red` (397 líneas): diálogos + paleta + SR helpers
- [x] **4D.5** canvas.red queda con: hit-test + CRUD + actor + demo (1226 líneas)
- [x] **4D.6** Chain loading correcto: canvas.red include canvas-render.red, luego canvas-dialogs.red
- [x] **4D.7** Tests 465/465 PASS ✅ (2026-04-08)
- [ ] **4D.8** PR "refactor: split conservador canvas.red"

#### 4E — Split conservador panel.red ✅ COMPLETADA

- [x] **4E.1** Medido: 933 líneas post-4A → > 900, split necesario
- [x] **4E.2** Creado `panel-render.red` (411 líneas): constantes + render puro
- [x] **4E.3** panel.red queda con: hit-test + diálogos + paleta + actor (535 líneas)
- [x] **4E.4** Tests 465/465 PASS ✅ (2026-04-08)
- [ ] **4E.5** PR "refactor: split conservador panel.red" (incluye en PR #60 o nuevo)

### Fase 4F — Bugs cluster post-revisión manual ✅ COMPLETADA

- [x] **4F.1** Colores de puertos: resuelto — block-color 'cluster → col-wire-cluster ya implementado
- [x] **4F.2** Editar desde FP: open-cluster-fp-edit-dialog en panel.red, doble-clic FP → edita + sync BD
- [x] **4F.3** Sincronización BD→FP: cluster-apply-and-refresh en canvas-dialogs.red
- [x] **4F.4** Tests 462/462 PASS ✅ (commit 8d84635)

### Sesión pendiente Fase 3 — Labels FP/BD

> Decisión 2026-04-08: Los labels tienen comportamientos complejos (compartidos entre
> control/indicador del mismo tipo, desconectados de labels del BD). Se deja para sesión
> dedicada en Fase 3 donde se definirán comportamientos y aspecto.

- Definir: ¿labels FP e BD sincronizados (LabVIEW) o independientes?
- Definir: ¿un control y su indicador comparten label o son independientes?
- Definir: ¿dónde se edita el label — FP, BD, ambos?
- Fix: objeto label usa `copy` del string por defecto para evitar literales compartidos

### Fase 5 — Decisión #28 y limpieza final

- [ ] **5.1** Preguntar: ¿#28 Front Panel standalone entra en Fase 2 o posponer?
- [ ] **5.2** Limpiar ficheros sueltos (con aprobación)
- [ ] **5.3** Actualizar CLAUDE.md (líneas reales, bugs cerrados, estado Fase 2 COMPLETADA)
- [ ] **5.4** Tag `v0.2-fase2-complete` tras aprobación
- [ ] **5.5** Abrir Fase 3: plan para #17 Sub-VI

## Criterios de "Fase 2 cerrada"

- 450+ tests pasando
- Issues #48-#51, #54 cerrados
- QA-018/024/029 protegidos con tests
- panel.red < 800 líneas
- canvas.red core < 1500 líneas
- canvas-render.red y canvas-dialogs.red existen

- CLAUDE.md refleja estructura real
- Todos los ejemplos headless pasan
- red-view src/qtorres.red funciona

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| Refactor 4A rompe chain loading | Probar red-cli y red-view tras cada mover |
| #54 tiene causa profunda config-driven | Tiempo adicional en investigación |
| Task tool devuelve resultados inexactos | Verificar con Grep/Read antes de actuar |
| Split 4D parte acoplamientos ocultos | Inventario previo + tests tras cada sub-paso |

## Log de errores

| Error | Intento | Resolución |
|-------|---------|------------|
| _(se rellenará durante ejecución)_ | | |

## Lección aprendida — opencode

El incidente con compiler.red (qwen3-coder-next reemplazó compile-diagram en lugar de solo añadir al final) fue probablemente un problema de selección de modelo, no una limitación de opencode.

Para refactors que implican añadir código a ficheros grandes con funciones críticas:
- Usar modelos con mejor comprensión de contexto largo: kimi-k2:1t, deepseek-v3.1:671b, mistral-large-3:675b
- qwen3-coder-next: bueno para tests y fixes quirúrgicos en ficheros pequeños
- glm-5 / gpt-oss:120b: fiables para ediciones mecánicas
- Verificar siempre con git diff antes de ejecutar tests cuando el agente toca ficheros críticos