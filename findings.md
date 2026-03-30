# Findings — Issue #12: Cluster

## Investigación inicial (2026-03-29)

### Infraestructura existente

**Wire colors** (`canvas.red:17-20, 83-90`):
- Numeric: `col-wire: 195.95.20` (naranja)
- Boolean: `col-wire-bool: 20.160.20` (verde)
- String: `col-wire-str: 220.100.160` (rosa)
- Cluster: **marrón** — definido en visual-spec.md línea 71/155, pendiente de implementar
- Color sugerido: `col-wire-cluster: 139.69.19`

**Block-def dialect** (`blocks.red`):
- Puertos estáticos: `in name 'type`, `out name 'type`
- Config: `config name 'type default`
- Emit: bloque Red donde port-names se sustituyen por variables reales
- 34 bloques registrados, todos con puertos fijos

**Compilador** (`compiler.red`):
- `bind-emit` sustituye nombres de puertos por variables reales en bloques emit
- `build-bindings` crea pares [port-name var-name]
- Funciona con cualquier código Red en emit — `make object! [...]` es válido

**Modelo** (`model.red`):
- `data-type` ya soporta cualquier word: `'cluster` encaja naturalmente
- `node/config` puede almacenar definición de campos del cluster

### Red object! — target de compilación

```red
; Crear cluster
my-cluster: make object! [name: "test"  voltage: 12.5  active: true]

; Acceder campo
my-cluster/voltage     ; → 12.5

; Asignar campo
my-cluster/name: "new"
```

Es completamente estático, compatible con `red -c` (DT-028 ✅).

### DESAFÍO CLAVE: Puertos dinámicos

**Problema:** Todos los bloques actuales tienen puertos fijos definidos en block-def.
Bundle/unbundle necesitan N puertos según los campos del cluster.

**Opciones evaluadas:**

| Opción | Descripción | Pro | Contra |
|--------|-------------|-----|--------|
| A — Bloques fijos | `bundle-2`, `bundle-3`, etc. | Simple | Limitado, feo, no escala |
| B — Config-driven | Campos en `node/config`, ports generados dinámicamente | Flexible, un solo tipo | Requiere cambiar render + compilador para leer config |
| C — Tipo especial | Como structures (while-loop) | Ya hay patrón | Overengineering — no son contenedores |

**Decisión: Opción B** — campos en `node/config`, funciones helper para generar puertos y emit dinámicamente.

### Diseño del config para clusters

```red
; En node/config de un bundle:
config: [fields [name 'string  voltage 'number  active 'boolean]]

; En node/config de un unbundle:
config: [fields [name 'string  voltage 'number  active 'boolean]]
```

Los puertos se generan leyendo `fields` del config:
- bundle: 1 puerto `in` por campo + 1 puerto `out result 'cluster`
- unbundle: 1 puerto `in cluster 'cluster` + 1 puerto `out` por campo

### Impacto por módulo

| Módulo | Cambio | Complejidad |
|--------|--------|-------------|
| blocks.red | Registrar bundle/unbundle con marcador dinámico | Baja |
| model.red | Helpers: `cluster-fields`, `cluster-in-ports`, `cluster-out-ports` | Baja |
| canvas.red | Render puertos dinámicos, color marrón, diálogo edición campos | Alta |
| compiler.red | Emit dinámico para bundle (`make object!`) y unbundle (path access) | Media |
| panel.red | Cluster como grupo en FP (control/indicator) | Media |
| file-io.red | Serializar/deserializar config con fields | Baja |
| tests/ | Tests para todo lo anterior | Media |

### Patrón de LabVIEW

- **Bundle**: N entradas escalares → 1 salida cluster
- **Unbundle**: 1 entrada cluster → N salidas escalares
- **Bundle By Name**: cluster in + campos seleccionados → cluster out (modifica campos)
- **Unbundle By Name**: cluster in → campos seleccionados
- Los campos tienen nombre y tipo
- El cluster es como un struct/record

### Simplificaciones para Fase 2

- **Bundle** y **Unbundle** básicos (todos los campos)
- **Sin** Bundle By Name / Unbundle By Name (Fase 3+)
- **Sin** clusters anidados (Fase 3+)
- **Sin** arrays de clusters (Fase 3+)
- Campos soportados: `'number`, `'boolean`, `'string`

### Compilación esperada

**Bundle:**
```red
; Entrada: ctrl_1 = "John", ctrl_2 = 42.0, ctrl_3 = true
; Config: fields [name 'string  age 'number  active 'boolean]
bundle_1_result: make object! [name: ctrl_1  age: ctrl_2  active: ctrl_3]
```

**Unbundle:**
```red
; Entrada: bundle_1_result (un object!)
; Config: fields [name 'string  age 'number  active 'boolean]
unbundle_1_name: bundle_1_result/name
unbundle_1_age: bundle_1_result/age
unbundle_1_active: bundle_1_result/active
```

### Renderizado esperado

Bundle/Unbundle son nodos normales (no contenedores como while-loop).
La diferencia: altura variable según número de campos.

```
┌─ Bundle ──────┐        ┌─ Unbundle ────┐
│ ● name     ●──│        │──● cluster  ● name   │
│ ● age         │        │             ● age     │
│ ● active      │        │             ● active  │
│         result │        │                       │
└────────────────┘        └───────────────────────┘
```

Puerto cluster = marrón. Puertos de campo = color según tipo del campo.
