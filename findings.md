# Findings — Fase 3: Libreria .qlib (#18)

## Estado del codebase (2026-04-10)

### Patron sub-VI existente (#17) — base para .qlib

El sub-VI ya implementa todo lo necesario para que un .qvi se use como bloque:

| Componente | Funcion | Fichero |
|------------|---------|---------|
| `make-subvi-node` | Crea nodo con file + config (puertos del connector) | model.red |
| `load-subvi-connector` | Carga connector de un .qvi externo | model.red |
| `compile-subvi-call` | Genera `nombre/exec arg1 arg2` | compiler.red |
| `compile-diagram` | Recopila subvi-files unicos, emite #include | compiler.red |
| Sub-VI en paleta | Boton "Sub-VI" + file picker | canvas-dialogs.red |
| Render subvi | Caja con label + puertos dinamicos | canvas-render.red |
| Serialize/load subvi | Emite/lee `file:` en nodos, `connector:` en diagram | file-io.red |

### Lo que .qlib añade vs lo que ya existe

| Necesidad | Ya existe? | Que falta |
|-----------|-----------|-----------|
| Leer un .qvi con connector | Si (load-subvi-connector) | Nada |
| Crear nodo subvi desde fichero | Si (make-subvi-node) | Nada |
| Compilar llamada a subvi | Si (compile-subvi-call) | Nada |
| Emitir #include | Si (compile-diagram) | Nada |
| Validar unicidad de nombres | Si (subvi-names) | Nada |
| **Parsear manifiesto qlib.red** | **No** | load-qlib en file-io.red |
| **Buscar .qlib en directorios** | **No** | find-qlibs en file-io.red |
| **Mostrar librerias en paleta** | **No** | Seccion en canvas-dialogs.red |
| **Resolver ruta de .qvi dentro de .qlib** | **No** | Ruta absoluta = dir-qlib + miembro |

### Formato qlib.red documentado en tipos-de-fichero.md

```red
qlib [
    version: 1
    name:    "math"

    members: [
        %add.qprim
        %subtract.qprim
        %interpolate.qvi
        %fft.qvi
    ]
]
```

**Nota:** El formato documentado mezcla .qprim y .qvi. Para esta fase, solo soportamos .qvi (los .qprim son issue separado). Ajustar formato.

### Ejemplo de sub-VI actual (suma-subvi.qvi)

```red
Red [title: "suma"]
qvi-diagram: [
    connector: [
        input  [pin: 1  label: "A"           id: 1]
        input  [pin: 2  label: "B"           id: 2]
        output [pin: 3  label: "Resultado"   id: 4]
    ]
    ...
]
suma: context [
    exec: func [A B] [
        ctrl_1: A
        ctrl_2: B
        add_1: ctrl_1 + ctrl_2
        ind_1: add_1
        ind_1
    ]
]
if not value? 'qtorres-runtime [view layout [...]]
```

### Ejemplo de caller actual (programa-con-subvi.qvi)

```red
Red [title: "Programa con sub-VI"]
qvi-diagram: [...]
_saved-qtorres-runtime: value? 'qtorres-runtime
qtorres-runtime: true
#include %suma-subvi.qvi
if not _saved-qtorres-runtime [unset 'qtorres-runtime]
either empty? system/options/args [
    view layout [... suma/exec subvi_1_p1 subvi_1_p2 ...]
][
    ... print ind_1
]
```

### Ficheros a modificar

| Fichero | Cambio | Lineas aprox |
|---------|--------|-------------|
| `src/io/file-io.red` | load-qlib, find-qlibs | ~60 |
| `src/ui/diagram/canvas-dialogs.red` | Seccion librerias en paleta | ~40 |
| `tests/run-all.red` | Incluir test-qlib.red | ~2 |
| `tests/test-qlib.red` | Tests de load-qlib, find-qlibs | ~40 nuevo |
| `examples/math.qlib/qlib.red` | Manifiesto ejemplo | ~8 nuevo |
| `examples/math.qlib/add.qvi` | Sub-VI add con connector | nuevo |
| `examples/math.qlib/subtract.qvi` | Sub-VI subtract con connector | nuevo |
| `examples/usa-libreria.qvi` | Programa que usa la libreria | nuevo |
| `docs/tipos-de-fichero.md` | Actualizar formato .qlib | ~20 |

### Impacto minimo

La .qlib es una capa de **descubrimiento y organizacion** sobre el patron sub-VI existente. No requiere cambios en:
- Compilador (ya maneja #include y subvi-call)
- Modelo de datos (nodos subvi ya soportados)
- Canvas render (subvi ya se renderiza)
- Serializacion (file: ya se persiste)

Solo necesita: parsear manifiesto + buscar directorios + integrar con paleta.
