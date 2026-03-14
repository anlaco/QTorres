# Arquitectura — QTorres

## Visión general

```
┌────────────────────────────────────────────────┐
│                   QTorres App                  │
│                                                │
│  ┌──────────────┐       ┌──────────────────┐   │
│  │  Front Panel │◄─────►│  Block Diagram   │   │
│  │  (Red/View)  │       │  (Red/View+Draw) │   │
│  └──────┬───────┘       └────────┬─────────┘   │
│         │                        │             │
│         ▼                        ▼             │
│  ┌─────────────────────────────────────────┐   │
│  │           Modelo del Grafo              │   │
│  │   (nodos, puertos, wires, valores)      │   │
│  └──────────────────┬──────────────────────┘   │
│                     │                          │
│         ┌───────────┼───────────┐              │
│         ▼           ▼           ▼              │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐    │
│  │ Compiler │ │  Runner  │ │ File I/O     │    │
│  │ → .red   │ │ (do)     │ │ .qvi/.qproj  │    │
│  └──────────┘ └──────────┘ └──────────────┘    │
└────────────────────────────────────────────────┘
```

## Módulos principales

### 1. Modelo del Grafo (`graph/`)

Estructura de datos central. Todo el resto opera sobre este modelo.

- **Nodo:** id, tipo, posición (x, y), puertos de entrada, puertos de salida, configuración
- **Puerto:** id, nombre, tipo de dato, dirección (in/out)
- **Wire:** id, puerto-origen, puerto-destino
- **Diagrama:** lista de nodos + lista de wires + metadatos

El modelo es un bloque Red (datos Red puros). No hay objetos opacos.

### 2. Canvas / Block Diagram (`ui/diagram/`)

Vista visual del grafo. Responsabilidades:

- Renderizar nodos como bloques dibujados con Red/Draw
- Renderizar wires como líneas/curvas entre puertos
- Gestionar interacción: drag, clic, selección, conexión de wires
- Sincronizar con el modelo del grafo (el canvas lee el modelo, las acciones del usuario lo modifican)

### 3. Front Panel (`ui/panel/`)

Vista de controles/indicadores. Responsabilidades:

- Generar widgets Red/View para cada control/indicador del diagrama
- Binding reactivo: el valor del control actualiza el nodo en el grafo

### 4. Compilador (`compiler/`)

Transforma el modelo del grafo en código Red. El compilador genera la sección de código del `.qvi`:

- Recorrido topológico del grafo
- Instanciación de plantillas de código por tipo de nodo
- Si el VI tiene connector pane → envuelve el código en una `func` Red
- Si el VI contiene sub-VIs → emite `do %sub-vi.qvi` al inicio
- Si el VI pertenece a una `.qlib` → el código va dentro de un `context`
- Genera la guarda `if not value? 'qtorres-runtime [...]` para ejecución standalone

### 5. Runner (`runner/`)

Ejecuta el diagrama:

- Define `qtorres-runtime: true` en el entorno
- Compila en memoria (misma lógica que el compilador)
- Ejecuta con `do`
- Captura salida y la escribe en los indicadores del Front Panel

### 6. File I/O (`io/`)

Serialización/deserialización de VIs y proyectos. Al guardar, el `.qvi` se genera completo con sus dos secciones:

1. **Cabecera gráfica** (`qvi-diagram: [...]`): estado actual del Front Panel y Block Diagram
2. **Código generado**: resultado de compilar el diagrama

- Guardar VI: modelo del grafo → cabecera + compilación → fichero .qvi
- Cargar VI: fichero .qvi → `load` → reconstruir modelo desde `qvi-diagram`
- Guardar proyecto: referencias + config → fichero .qproj
- Cargar proyecto: fichero .qproj → `load` → árbol de ficheros

## Flujo de datos

```
Usuario arrastra bloque  →  Modelo se actualiza  →  Canvas se redibuja
Usuario conecta wire     →  Modelo se actualiza  →  Canvas se redibuja
Usuario pulsa Run        →  Runner define qtorres-runtime → Compilador genera Red → do ejecuta → Panel muestra resultado
Usuario pulsa Save       →  Compilador genera código + cabecera gráfica → Se escribe fichero .qvi completo
Usuario abre .qvi        →  load lee el fichero → qvi-diagram se parsea → Canvas + Panel se reconstruyen
```

## El fichero `.qvi` como ejecutable

Un `.qvi` guardado es directamente ejecutable con Red (`red mi-vi.qvi`):

1. Red ejecuta `qvi-diagram: [...]` → asigna el bloque a una variable, sin efectos
2. Red ejecuta el código generado debajo → resultado

La clave es que la cabecera es una asignación inerte. El código vive debajo. Un mismo fichero, dos usos (QTorres para editar, Red para ejecutar).

## Sub-VIs

Cuando un VI se usa dentro de otro:

1. El sub-VI define un **connector pane** (entradas/salidas expuestas)
2. Su código generado se envuelve en una `func` Red en lugar de código lineal
3. La guarda `if not value? 'qtorres-runtime` permite ejecución standalone
4. El VI padre emite `do %sub-vi.qvi` para cargar la función, y la llama como `nombre-funcion arg1 arg2`

## Namespacing con `context`

Los VIs dentro de una `.qlib` (librería) se aíslan usando `context` de Red:

```
LabVIEW:   Utilidades.lvlib » Suma.vi
QTorres:   utilidades/suma
```

Esto evita colisiones de nombres: `utilidades/suma` y `matematica/suma` coexisten sin problema. Es el mecanismo nativo de Red, no una convención de nombres.

## Registro de bloques

Cada tipo de bloque se registra con:

- Nombre y categoría
- Lista de puertos (nombre, tipo, dirección)
- Plantilla de código Red
- Función de renderizado (icono, color, forma)

Esto permite extender QTorres con nuevos bloques sin modificar el núcleo.
