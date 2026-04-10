# Plan — Fase 3: Libreria .qlib (#18)

**Creado:** 2026-04-10
**Objetivo:** Implementar el formato `.qlib` para agrupar VIs en una libreria con namespacing, cargable desde la paleta del editor.

**Linea base:** 462 tests PASS, branch feat/17-subvi-connector, sub-VI funcional con #include + context.

## Contexto previo

El Issue #17 (sub-VI) ya establecio:
- Patron `#include %subvi.qvi` (compile-time, DT-028)
- Sub-VI genera `nombre: context [exec: func [...] [...]]`
- Standalone guard con save/restore de `qtorres-runtime`
- El compilador recopila ficheros unicos en `subvi-files` y valida unicidad de nombres
- El caller llama `nombre/exec arg1 arg2`

La .qlib extiende este patron: agrupa multiples VIs bajo un namespace comun.

## Decisiones de diseno

### D1: Formato del .qlib — directorio con manifiesto

**Decision:** Un `.qlib` es un **directorio** con un fichero `qlib.red` (manifiesto) + los .qvi miembros.

```
math.qlib/
  qlib.red          ; manifiesto
  add.qvi
  subtract.qvi
  interpolate.qvi
```

**Contenido de qlib.red:**
```red
qlib [
    name:    "math"
    version: 1
    description: "Operaciones matematicas"
    members: [
        %add.qvi
        %subtract.qvi
        %interpolate.qvi
    ]
]
```

**Razon:** Un directorio es mas facil de editar, versionar con git, y depurar que un fichero empaquetado. Los .qvi individuales siguen siendo ejecutables standalone. LabVIEW usa el mismo patron (un .lvlib es logico, los .vi son ficheros separados).

**Alternativa descartada:** Fichero unico con todo empaquetado — complicaria el editor (hay que desempaquetar), no permite git por VI, y Red no tiene zip nativo.

### D2: Namespacing — contexts existentes de cada sub-VI

**Decision:** Al compilar un VI que usa una libreria, el compilador emite `#include` de cada miembro necesario. Los contexts ya existentes de cada sub-VI (patron #17) dan el namespace natural. El nombre del context = titulo del VI (ya implementado).

**No** hay un context wrapper extra por libreria. Cada VI mantiene su propio context.

**Razon:** Ya tenemos `suma: context [exec: func [...]]` por sub-VI. Añadir otro nivel (`math: context [suma: context [...]]`) complicaria las llamadas (`math/suma/exec` vs `suma/exec`) sin beneficio real. La unicidad se valida en compile-time (ya implementado).

**Si en el futuro hay colision de nombres entre librerias:** se añade prefijo de libreria como opcion (`math-suma/exec`). Cambio aditivo, no rompe lo actual.

### D3: Directorio de librerias

**Decision:** Las librerias se buscan en:
1. Directorio del proyecto actual (ruta relativa)
2. `~/.qtorres/libs/` (directorio global del usuario)

El compilador resuelve rutas en ese orden. El manifiesto usa rutas relativas internas.

### D4: Integracion con la paleta

**Decision:** La paleta (canvas-dialogs.red) muestra una seccion "Librerias" con los VIs disponibles de las .qlib detectadas. Al seleccionar uno, se crea un nodo subvi (patron existente de #17) con el fichero apuntando al .qvi dentro de la .qlib.

### D5: Compilacion — #include selectivo

**Decision:** El compilador solo emite `#include` de los miembros de la .qlib que realmente se usan en el diagrama. No se incluye la libreria entera.

**Razon:** Un .qvi compilado debe ser autocontenido y minimo. Si solo usas `math/add`, no necesitas `math/fft`.

### D6: El manifiesto NO contiene codigo

**Decision:** `qlib.red` es solo metadata (nombre, version, lista de miembros). No contiene codigo ejecutable. Los .qvi miembros son los que tienen el codigo.

## Fases de implementacion

### Fase 1 — Formato y carga del manifiesto ⬜

> Que QTorres pueda leer un .qlib y entender su contenido.

- [ ] **1.1** Definir formato definitivo de `qlib.red` (ya esbozado en D1)
- [ ] **1.2** `file-io.red`: funcion `load-qlib` — lee directorio .qlib, parsea qlib.red, devuelve objeto con name/version/members (rutas absolutas a .qvi)
- [ ] **1.3** `file-io.red`: funcion `find-qlibs` — busca .qlib en directorio del proyecto + ~/.qtorres/libs/
- [ ] **1.4** Tests: load-qlib con manifiesto valido, invalido, miembro inexistente
- [ ] **1.5** Tests pasan. Commit.

### Fase 2 — Integracion con la paleta ⬜

> Que el usuario pueda insertar VIs de una libreria desde el editor.

- [ ] **2.1** `canvas-dialogs.red`: seccion "Librerias" en la paleta con los VIs detectados por find-qlibs
- [ ] **2.2** Al seleccionar un VI de libreria, crear nodo subvi con `file:` apuntando al .qvi (reutiliza make-subvi-node de #17)
- [ ] **2.3** El nodo subvi de libreria funciona igual que un subvi suelto (mismos puertos, misma compilacion, mismo rendering)
- [ ] **2.4** Test manual: abrir paleta, ver librerias, insertar VI, conectar wires, Run
- [ ] **2.5** Commit.

### Fase 3 — Ejemplo funcional ⬜

> Demostrar el ciclo completo con una libreria real.

- [ ] **3.1** Crear `examples/math.qlib/` con qlib.red + add.qvi + subtract.qvi (sub-VIs con connector)
- [ ] **3.2** Crear `examples/usa-libreria.qvi` — programa que usa math.qlib/add y math.qlib/subtract
- [ ] **3.3** Verificar: `./red-cli examples/usa-libreria.qvi` funciona headless
- [ ] **3.4** Verificar: cargar en QTorres, editar, guardar, recargar — round-trip OK
- [ ] **3.5** Tests automatizados del ejemplo
- [ ] **3.6** Commit.

### Fase 4 — Documentacion y cierre ⬜

- [ ] **4.1** Actualizar `docs/tipos-de-fichero.md` con formato definitivo del .qlib
- [ ] **4.2** Actualizar CLAUDE.md (estado Fase 3, .qlib como implementado)
- [ ] **4.3** Cerrar Issue #18
- [ ] **4.4** Commit + PR

## Fuera de scope

- Editor visual de librerias (crear/editar .qlib desde QTorres UI) — futuro
- Versionado de librerias / dependencias transitivas — futuro (.qproj)
- Descarga/instalacion de librerias remotas — futuro (ecosistema)
- .qprim (primitivas con codigo Red puro) — issue separado
- .qctl (type definitions) — issue separado

## Criterios de exito

- `load-qlib` parsea un directorio .qlib y devuelve metadata + rutas de miembros
- `find-qlibs` encuentra librerias en directorio actual y ~/.qtorres/libs/
- La paleta muestra VIs de librerias detectadas
- Insertar un VI de libreria crea nodo subvi funcional (compile + run)
- El compilador solo incluye los miembros usados (#include selectivo)
- Ejemplo end-to-end funciona headless y en QTorres
- Round-trip: guardar programa con subvi de libreria → cargar → mismos datos
- `./red-cli tests/run-all.red` pasa

## Riesgos

| Riesgo | Mitigacion |
|--------|-----------|
| Rutas relativas rotas al mover proyecto | Busqueda en dos directorios (D3) + error amigable |
| Colision de nombres entre librerias | Ya validado en compile-time (subvi-names del #17) |
| .qvi miembro sin connector (no usable como subvi) | Validar en load-qlib, warning al usuario |
| Rendimiento al escanear muchas .qlib | Lazy loading — solo cargar manifiesto, no los .qvi |
| Paleta muy larga con muchas librerias | Subsecciones colapsables — futuro, no bloquea MVP |

## Log de errores

| Error | Intento | Resolucion |
|-------|---------|------------|
| _(se rellenara durante ejecucion)_ | | |
