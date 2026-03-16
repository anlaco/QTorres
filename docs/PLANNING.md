# Planning — Decisiones pendientes críticas

Decisiones arquitecturales que **deben tomarse antes de implementar** los módulos afectados.
Para el registro de decisiones ya adoptadas, ver [`decisiones.md`](decisiones.md).

---

## [P1] Formato del archivo .qvi — RESUELTO

**Estado:** RESUELTO — ver decisiones DT-010 a DT-019 en `decisiones.md`

La decisión arquitectural más importante del proyecto. El formato `.qvi` debe satisfacer simultáneamente varios requisitos que pueden estar en tensión:

### Requisitos

1. Ser **código Red válido ejecutable** sin QTorres (con el toolchain estándar de Red, sin dependencias)
2. Almacenar **metadata visual completa** (front panel + block diagram) para reconstruir la vista en QTorres
3. Ser **parseable por QTorres** para reconstruir el canvas desde el fichero
4. Permitir **análisis estático del grafo** para compilación topológica
5. Ser **legible por humanos** (texto plano, en cualquier editor)
6. Escalar a **programas complejos** sin volverse ilegible o inmanejable

### Contexto (decisiones ya adoptadas)

- **DT-005:** El `.qvi` tiene dos secciones: cabecera gráfica (`qvi-diagram: [...]`) + código generado ejecutable.
- **DT-008:** La cabecera usa el dialecto `qvi-diagram`, procesable con `parse`.
- **DT-009:** El código generado es Red/View completo (ventana con Front Panel) para VIs principales; `func` Red para sub-VIs.
- En `docs/tipos-de-fichero.md` hay ejemplos concretos del formato actual (ilustrativos, no necesariamente definitivos).

> **[REVISAR]** El ejemplo de VI standalone en `tipos-de-fichero.md` genera `print Resultado` (salida de terminal), mientras que DT-009 especifica que los VIs principales deben generar Red/View con ventana. Hay una inconsistencia que debe resolverse al definir P1.

### Preguntas abiertas

1. **Separación metadata/lógica:** ¿Cómo separar la metadata visual de la lógica ejecutable dentro de un archivo Red válido? La propuesta actual (cabecera `qvi-diagram: [...]` como asignación inerte) funciona pero tiene limitaciones — ¿es suficiente para todos los casos?

2. **Representación del grafo:** ¿Cómo representar el grafo (nodos, cables, tipos) de forma que sea a la vez legible, parseable y suficientemente expresivo para el compilador?

3. **SubVIs referenciados:** ¿Cómo manejar subVIs referenciados desde otros `.qvi`? ¿Rutas relativas, absolutas, por nombre?

4. **Versionado del formato:** ¿Cómo versionar el formato para compatibilidad hacia atrás? ¿Campo `version` en la cabecera?

5. **Tipos de datos en cables:** ¿Cómo representar los tipos de datos de los cables en el formato? ¿En los puertos de los nodos, en los wires, o en ambos?

6. **Ejecución continua:** El modelo de ejecución es un loop continuo, no single-shot. ¿Cómo se refleja esto en el código generado? ¿`forever [...]` de Red, `loop [...] [...]`, o algo diferente?

### Decisiones adoptadas

Las decisiones que resuelven P1 están en `decisiones.md` como DT-010 a DT-019. Resumen:
- Formato de dos secciones: `qvi-diagram` (fuente de verdad) + código generado (artefacto)
- `qvi-diagram` incluye: `meta`, `icon`, `connector` (opcional), `front-panel`, `block-diagram`
- Modo dual de ejecución: sin args → UI, con args → headless (DT-012)
- Unicidad de nombres por ruta relativa (DT-015)
- Dos contextos de aislamiento (DT-016)

Issues #8 y #9 están desbloqueados para implementación.

---

## [P2] Modelo del grafo en memoria

**Estado:** PENDIENTE

La estructura de datos interna que representa el estado del programa mientras el usuario edita.

### Preguntas abiertas

1. **Estructura de datos:** ¿Qué estructura de datos representa el grafo internamente? El prototipo actual en `src/graph/model.red` define `make-node`, `make-wire`, `make-diagram` como bloques Red. ¿Es suficiente para la Fase 1 completa?

2. **Sincronización Front Panel ↔ Block Diagram:** ¿Cómo se sincronizan en memoria? ¿Un único modelo compartido, o dos modelos con eventos de sincronización?

3. **Detección de ciclos:** ¿Cómo se detectan ciclos en el grafo (que serían un error)? ¿En tiempo de conexión de un wire, en tiempo de compilación, o ambos?

4. **Tipos en tiempo de diseño:** Los cables deben tener tipo en tiempo de diseño (validación de que no se conecta un numérico a un booleano). ¿Cómo se propaga esta información por el grafo al conectar wires?

5. **Undo/Redo:** La arquitectura del modelo de datos debe contemplarlo desde el diseño. ¿Command pattern, snapshot, event sourcing?

### Módulos afectados

- `src/graph/model.red`
- `src/graph/blocks.red`
- Issue #6 (topological sort)

---

## [P3] Motor de ejecución dataflow

**Estado:** PENDIENTE

Cómo se traduce el grafo visual dataflow a ejecución real.

### Preguntas abiertas

1. **Algoritmo de ordenación topológica:** ¿Kahn, DFS? ¿Cómo maneja estructuras de control (While Loop, For Loop, Case Structure) que rompen el orden lineal?

2. **Mapeo nodos → funciones Red:** ¿Cómo se mapean los nodos visuales a funciones Red durante la compilación? ¿El dialecto `emit` de `block-def` es suficiente o se necesita algo más expresivo?

3. **Loop de ejecución continua:** ¿Cómo se gestiona el loop de ejecución continua? ¿`forever [...]` de Red, un temporizador, evento-driven? ¿Cómo se para el loop (botón Stop, condición de parada)?

4. **Timing determinista:** ¿Se necesita control de timing (ejecutar N veces por segundo)? ¿Cómo se implementa con el runtime de Red?

5. **Errores en tiempo de ejecución:** ¿Cómo se propagan los errores por los cables (al estilo LabVIEW con el cluster de error)? ¿Desde qué fase del proyecto?

### Módulos afectados

- `src/compiler/compiler.red` (depende también de P1)
- `src/runner/runner.red`
- Issues #6, #7, #8, #10

---

## Orden de resolución sugerido

```
P1 (formato .qvi)
  └── P2 (modelo en memoria)   ← se puede avanzar en paralelo con P1
        └── P3 (motor dataflow) ← depende de P1 y P2
```

P1 y P2 se pueden explorar en paralelo. P3 depende de tener P1 y P2 resueltos.
