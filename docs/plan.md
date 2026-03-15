# Plan de desarrollo — QTorres

## Visión

QTorres es un entorno de programación visual open source que replica el modelo mental de LabVIEW (bloques, wires, Front Panel, Block Diagram) compilando a código Red-Lang puro y legible.

## Fases

### Fase 0 — Spike técnico (validación)

Antes de construir arquitectura, validar que Red/View soporta las primitivas necesarias:

- [ ] Prototipo de canvas con bloques arrastrables (drag & drop)
- [ ] Dibujo de wires entre bloques con Red/Draw
- [ ] Hit testing: detectar clic sobre bloque, sobre wire, sobre puerto
- [ ] Scroll del canvas
- [ ] Evaluar rendimiento con 20+ bloques en pantalla

**Criterio de éxito:** Se puede arrastrar bloques y dibujar wires entre ellos de forma fluida.

### Fase 1 — MVP

Ciclo completo: dibujar → compilar → ejecutar → ver resultado.

#### Bloques primitivos
- Constante numérica (entrada)
- Suma, Resta, Multiplicación (operación)
- Display / Print (salida)

#### Funcionalidades
- [ ] Canvas interactivo con bloques arrastrables
- [ ] Conexión de bloques mediante wires
- [ ] Front Panel con controles numéricos e indicadores
- [ ] Botón Run (ejecuta el .qvi en memoria)
- [ ] Guardar .qvi con cabecera gráfica + código generado
- [ ] Cargar .qvi (reconstruir Front Panel y Block Diagram desde cabecera)
- [ ] El .qvi guardado es ejecutable con `red mi-vi.qvi`
- [ ] Validación básica (tipos compatibles, sin ciclos)

#### Qué genera el compilador en la beta (decisión DT-009)

El compilador genera **código Red/View completo**, no solo código imperativo. Al ejecutar el `.qvi` con Red aparece una ventana con el Front Panel, igual que en LabVIEW.

Estructura del `.qvi` generado:

```
[Cabecera Red]
[qvi-diagram: ... — para reconstruir la vista en QTorres]
[view layout [ ... — ventana con controles, botón Run e indicadores ]]
```

Los controles de entrada se convierten en `field` editables. Los indicadores de salida se convierten en `text` que se actualizan al pulsar Run. El botón Run ejecuta la lógica del diagrama y actualiza los indicadores en la misma ventana.

Esta es la diferencia principal respecto al MVP actual, que genera código de terminal sin UI.

### Fase 2 — Tipos y estructuras

- Wires tipados (numérico, string, booleano) con color por tipo
- Estructuras de control: While Loop, For Loop, Case Structure
- Bloques de string y booleanos
- Undo/Redo

### Fase 3 — Extensibilidad

- Sub-VIs: connector pane, `func` generada, guarda `qtorres-runtime`
- Un .qvi con connector se puede usar como bloque dentro de otro .qvi
- `.qlib` con `context` de Red para namespacing (`libreria/funcion`)
- Bloques de I/O (ficheros, puertos serie, red)
- Paleta de bloques extensible por el usuario
- Depurador con sondas en wires

### Fase 4 — Madurez

- Editor de tipos de wire personalizados
- Clusters y arrays como tipos de wire
- Exportar a ejecutable (compilación Red nativa)
- Documentación y tutoriales

## Hitos clave

| Hito | Descripción | Fase |
|------|------------|------|
| Canvas vivo | Bloques arrastrables con wires dibujados | 0 |
| Primera compilación | .qvi guardado se ejecuta con Red directamente | 1 |
| Primer programa útil | Usuario puede hacer aritmética y ver resultado | 1 |
| Estructuras de control | Bucles y condicionales en el diagrama | 2 |
| SubVIs | VIs reutilizables dentro de otros con connector | 3 |
| Librerías | Namespacing con context de Red | 3 |
