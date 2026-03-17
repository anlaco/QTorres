# Plan de desarrollo — QTorres

## Visión

QTorres es una alternativa open source a LabVIEW para el mismo público objetivo: ingenieros de instrumentación y automatización. El usuario construye programas visualmente con bloques y wires (igual que en LabVIEW), y QTorres genera código Red-Lang puro y legible.

**Principios de diseño:**
- Mismo modelo mental que LabVIEW: Front Panel + Block Diagram, dataflow, sub-VIs
- Identidad visual propia y más moderna (no un clon visual de LabVIEW)
- Hardware como ciudadano de primera clase: SCPI/VISA para Keysight, serie para microcontroladores, DAQ
- Sin dependencias externas. Un binario, multiplataforma.

**Por qué puede competir con LabVIEW:**
- Open source vs licencias de miles de euros
- Binarios ~1 MB sin runtime externo
- Linux real, no segunda clase
- Código generado legible y modificable a mano

---

## Etapas de alto nivel

> Esta sección es una visión de alto nivel. El detalle de implementación por Issues está en las Fases de abajo. Para decisiones arquitecturales pendientes ver [`docs/PLANNING.md`](PLANNING.md).

### Etapa 1 — Fundaciones (actual)

- **[CRÍTICO — PENDIENTE]** Diseño del formato `.qvi` (ver Planning P1) — no implementar nada hasta tener esta decisión
- **[CRÍTICO — PENDIENTE]** Modelo del grafo en memoria (ver Planning P2)
- **[CRÍTICO]** Fix bugs backend GTK contribuyendo a `red/red` (ver `docs/GTK_ISSUES.md`)
- Compilador dataflow → Red secuencial (análisis topológico)

### Etapa 2 — Motor de ejecución

- Ejecución continua en loop
- Timing determinista
- Manejo de errores por cable
- Tipos Red nativos en cables con validación en tiempo de diseño

### Etapa 3 — Paralelismo

- Aprovechar concurrencia Red cuando esté madura
- Mismo grafo `.qvi`, ejecución paralela automática — sin cambios para el usuario

### Etapa 4 — Ecosistema

- Drivers de hardware vía `Red/System #import`
- Librería estándar de VIs
- Sistema de distribución de VIs de comunidad

### Etapa 5 — Competir con LabVIEW

- Plataforma completa para ingeniería de test y automatización
- Alternativa real para proyectos industriales

---

---

## Fase 0 — Spike técnico ✅ COMPLETADA

Validar que Red/View soporta las primitivas necesarias.

- [x] Prototipo de canvas con bloques arrastrables (drag & drop)
- [x] Dibujo de wires entre bloques con Red/Draw
- [x] Hit testing: detectar clic sobre bloque, sobre wire, sobre puerto
- [x] Evaluar rendimiento con 20+ bloques en pantalla

**Resultado:** `src/ui/diagram/canvas.red` funcional con 20 nodos y 15 wires fluidos.

---

## Fase 1 — Beta funcional

Ciclo completo: dibujar → compilar → ejecutar → ver resultado.

### Edición del diagrama
- [ ] Canvas modular (refactor de canvas.red a src/ui/diagram/)
- [ ] Borrar wire/nodo con tecla Delete (#20)
- [ ] Renombrar nodo con doble clic (#21)
- [ ] Identidad visual: diseño de bloques moderno, customizable (#22)

### Motor de compilación
- [ ] Procesador dialecto `block-def` (#5)
- [ ] Topological sort del grafo (#6)
- [ ] `bind-emit`: sustituye nombres de puerto por variables (#7)
- [ ] Compilador genera Red/View completo (DT-009) (#8)
- [ ] Guardar/cargar .qvi: `save-vi` y `load-vi` (#9)
- [ ] Runner en memoria (ejecuta sin generar fichero) (#10) — ver [REVISAR] en `docs/arquitectura.md`
- [ ] Ejecución continua en loop (Etapa 2)

### Bloques primitivos de Fase 1
- Constante numérica, Suma, Resta, Multiplicación, División
- Display numérico
- Controles e indicadores numéricos en Front Panel

### Front Panel modular
- [ ] Panel con controles e indicadores arrastrables (#12)
- [ ] Botón Run visible en el panel
- [ ] Conectar módulos en `qtorres.red` (#13)

### Qué genera el compilador (decisión DT-009)

El compilador genera **código Red/View completo**. Al ejecutar el `.qvi` con Red aparece una ventana con el Front Panel, igual que en LabVIEW.

Estructura del `.qvi` generado:

```
[Cabecera Red]
[qvi-diagram: ... — para reconstruir la vista en QTorres]
[view layout [ ... — ventana con controles, botón Run e indicadores ]]
```

Los controles de entrada se convierten en `field` editables. Los indicadores de salida en `text` que se actualizan al pulsar Run.

---

## Fase 2 — Tipos de datos y estructuras de control

### Tipos de datos esenciales
- [ ] Tipo booleano: wire azul oscuro, control LED, indicador LED (#23)
- [ ] Tipo string: wire rosa, control field, indicador text (#24)
- [ ] Array 1D: wire con borde doble, representación en Front Panel (#25)
- [ ] Cluster: wire marrón, editor de campos (#26)

### Visualización
- [ ] Waveform chart y graph en Front Panel (#27)
- [ ] Wires con color según tipo (numérico naranja, booleano azul, string rosa)
- [ ] Error de tipo al conectar wires incompatibles (visual en el wire)

### Estructuras de control
- [ ] While Loop con terminal de condición (#15)
- [ ] For Loop con terminal N e índice (#16)
- [ ] Case Structure con selector y múltiples frames (#17)

### Calidad de edición
- [ ] Undo/Redo (historial de acciones)
- [ ] Validación: detectar ciclos, tipos incompatibles, puertos sin conectar

---

## Fase 3 — Sub-VIs y extensibilidad

- [ ] Connector pane: definir entradas/salidas de un VI para usarlo como bloque (#18)
- [ ] Compilador genera `func` Red para sub-VIs (DT-006, DT-009)
- [ ] Un .qvi con connector pane se puede usar como bloque en otro .qvi
- [ ] `.qlib`: librería de bloques con `context` Red para namespacing
- [ ] Paleta de bloques extensible por el usuario
- [ ] Depurador con sondas en wires (ver valor en ejecución)
- [ ] Exportar a ejecutable (compilación Red nativa a binario)

---

## Fase 4 — Hardware (instrumentación y automatización)

Esta fase es esencial para el público objetivo (mismo que LabVIEW: ingeniería de test y automatización).

### SCPI para instrumentos Keysight y compatibles
- [ ] SCPI sobre TCP/IP (puerto 5025): bloques connect/write/query/close (#28)
- [ ] SCPI sobre USB/USBTMC (/dev/usbtmc*): mismos bloques, diferente transporte (#29)
- [ ] Gestión de errores de instrumento (+/-OPC, error queue)
- [ ] Bloque de identificación: `*IDN?` y detección automática de instrumento

### Comunicación serie
- [ ] Puerto serie RS-232/RS-485: bloques open/write/read/close (#30)
- [ ] Configuración: baud rate, paridad, bits de stop, timeout
- [ ] Soporte para /dev/ttyUSB* (Arduino, ESP32, adaptadores USB-serie)

### Red genérica
- [ ] TCP/IP cliente y servidor para protocolos propios (#31)
- [ ] UDP para comunicación de baja latencia
- [ ] Modbus TCP (protocolo industrial estándar)

### Adquisición de datos (DAQ)
- [ ] Tarjetas DAQ vía comedi/libcomedi en Linux (#32)
- [ ] Alternativa ligera: Arduino como DAQ de bajo coste (vía serie)
- [ ] Entradas analógicas, salidas analógicas, I/O digital
- [ ] Adquisición continua con timestamp

---

## Hitos clave

| Hito | Descripción | Fase |
|------|------------|------|
| Canvas vivo | Bloques arrastrables con wires dibujados | 0 ✅ |
| Primera compilación | .qvi guardado se ejecuta con Red directamente | 1 |
| Primer programa útil | Aritmética con Front Panel funcional | 1 |
| Tipos completos | Boolean, string, array, cluster en wires | 2 |
| Estructuras de control | Bucles y condicionales en el diagrama | 2 |
| Sub-VIs | VIs reutilizables como bloques con connector | 3 |
| Primera medida real | Controlar un Keysight desde QTorres | 4 |
| DAQ completo | Adquisición continua con tarjeta o Arduino | 4 |

---

## Orden de trabajo recomendado

Trabajar siempre Issues en orden de Fase. No empezar una fase sin completar la anterior.

**Próximo:** Fase 1 — empezar por Issue #20 (borrar wire/nodo) o Issue #22 (identidad visual, decide el look antes de construir más UI).

---

## Notas para el futuro

### Referencia del lenguaje Red para agentes de IA

Si en el futuro los agentes de IA muestran problemas recurrentes con la sintaxis Red (confusión con Rebol, funciones inventadas, mezcla de dialectos), se creará un documento o skill de referencia del lenguaje Red específicamente diseñado para consumo por LLMs. Por ahora no es necesario — no se han observado problemas que lo justifiquen.

### Generación de ficheros QTorres por IA (vibe coding → spec-driven design)

Ver DT-021 en `docs/decisiones.md`. La referencia de formatos para agentes de IA está en `docs/ai-reference.md`. Conforme el proyecto madure y se implementen más tipos de fichero, esta referencia crecerá y el nivel de rigor de la generación por IA aumentará progresivamente — desde generar un `.qvi` individual (vibe coding) hasta generar proyectos completos desde especificaciones técnicas (spec-driven design).
