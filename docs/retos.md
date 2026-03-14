# Retos y dificultades — QTorres

## Riesgo alto

### Madurez de Red-Lang

**Riesgo:** Red no ha alcanzado la versión 1.0. La comunidad es pequeña. El desarrollo es lento.

**Impacto:** Puede haber bugs o carencias en Red/View que haya que resolver nosotros mismos.

**Mitigación:**
- Contribuir fixes y mejoras upstream a Red cuando se encuentren problemas
- Construir las utilidades que falten dentro del ecosistema Red (si algo no existe, se crea)
- Validar Red/View en las tres plataformas durante el spike técnico

### Canvas interactivo en Red/View

**Riesgo:** Red/View + Draw no tienen primitivas de alto nivel para editores gráficos (hit testing, z-order, layout automático de wires). Hay que construirlas.

**Impacto:** Construir el canvas puede consumir la mayor parte del esfuerzo del MVP.

**Mitigación:**
- Spike técnico (Fase 0) antes de cualquier otra cosa
- Construir las primitivas que falten (hit testing, z-order) como módulos Red reutilizables
- Diseñar el canvas como módulo aislado dentro del proyecto

## Riesgo medio

### Routing de wires

**Riesgo:** Dibujar wires que no se solapen, que rodeen bloques y que sean legibles es un problema de layout no trivial.

**Impacto:** Un diagrama ilegible hace que QTorres sea inutilizable incluso si todo funciona.

**Mitigación:**
- MVP con wires rectos (línea directa entre puertos)
- Routing ortogonal (estilo LabVIEW) como mejora posterior
- Estudiar algoritmos existentes de routing en editores de grafos

### Modelo de ejecución dataflow

**Riesgo:** LabVIEW ejecuta nodos cuando sus entradas están listas (dataflow). Compilar a código imperativo Red (secuencial) requiere un sort topológico que se complica con estructuras de control.

**Impacto:** Bucles y condicionales pueden requerir un rediseño del compilador si no se anticipan.

**Mitigación:**
- El MVP solo tiene aritmética lineal (sort topológico trivial)
- Diseñar la representación intermedia del grafo pensando en que habrá estructuras de control
- Estudiar cómo LabVIEW internamente compila sus diagramas

### Gestión de errores del usuario

**Riesgo:** Sin mensajes de error claros, el usuario no sabe por qué su diagrama no compila o no funciona.

**Impacto:** Usabilidad baja → abandonan QTorres.

**Mitigación:**
- Definir desde el MVP qué errores se detectan: tipos incompatibles, ciclos, puertos sin conectar
- Mostrar errores visualmente en el diagrama (wire rojo, bloque resaltado), no solo en texto

## Riesgo bajo (pero a tener en cuenta)

### Tipado de wires

Los wires en LabVIEW tienen tipo (numérico, string, booleano, cluster, array). El color del wire indica el tipo. Esto hay que diseñarlo desde el inicio aunque el MVP solo use numéricos, para no tener que refactorizar la estructura de datos del grafo.

### Rendimiento del canvas

Con pocos bloques no hay problema. Con 50+ bloques y wires, el redibujo del canvas con Red/Draw puede ser lento. Hay que perfilar temprano.

### Undo/Redo

No está en el MVP pero es imprescindible para cualquier editor. La arquitectura del modelo de datos debe contemplarlo (command pattern o similar) desde el diseño.

## Preguntas abiertas

1. ¿Red interpretado o compilado como target de ejecución para Run?
2. ¿Soporta Red/View canvas con scroll nativo o hay que construirlo?
3. ¿El usuario objetivo es ingeniero saliendo de LabVIEW o programador Red?

## Retos resueltos en diseño

### .qvi como ejecutable

Resuelto: el .qvi contiene cabecera gráfica (inerte para Red) + código generado. Se ejecuta con `red mi-vi.qvi` directamente. No hay paso de compilación separado.

### Sub-VIs y reutilización

Resuelto: VIs con connector pane generan una `func` Red. La guarda `qtorres-runtime` distingue ejecución standalone de carga como sub-VI. El VI padre hace `do %sub-vi.qvi` y llama la función.

### Colisiones de nombres en librerías

Resuelto: los VIs de una `.qlib` se encapsulan en `context` de Red. Acceso con `libreria/funcion`. Aislamiento enforced por el lenguaje.
