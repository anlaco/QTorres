# Decisiones técnicas — QTorres

Registro de decisiones clave del proyecto. Cada decisión documentada para referencia futura.

---

## DT-001: Lenguaje y plataforma — Red-Lang 100%

**Fecha:** 2026-03-14  
**Estado:** Adoptada  

**Contexto:** QTorres se construye íntegramente en Red-Lang. No hay alternativas — si algo no existe en Red, se crea en Red.

**Decisión:** Todo en Red-Lang. Sin excepciones.

**Razones:**
- La homoiconicidad de Red permite que el diagrama y el código generado sean el mismo tipo de dato
- Red/View elimina dependencias externas para la UI
- Los formatos .qvi/.qproj son Red nativo → sin parser
- Binario único < 1 MB
- Lo que falte se construye como parte del proyecto y se contribuye al ecosistema Red

---

## DT-002: Formato de fichero — Sintaxis Red nativa

**Fecha:** 2026-03-14  
**Estado:** Adoptada  

**Contexto:** Definir el formato de guardado de VIs y proyectos dentro de Red.

**Decisión:** Todos los ficheros QTorres (.qvi, .qproj, .qlib, .qclass, .qctl) son bloques Red válidos, cargables con `load`.

**Razones:**
- Sin parser adicional que mantener
- Legible en cualquier editor de texto
- Merge-friendly en control de versiones
- Coherente con la filosofía "todo es Red"

---

## DT-003: MVP solo con tipos numéricos

**Fecha:** 2026-03-14  
**Estado:** Adoptada  

**Contexto:** Definir el alcance mínimo del sistema de tipos para el MVP.

**Decisión:** El MVP solo maneja valores numéricos (`float!`). Un solo tipo de wire.

**Razones:**
- Simplifica el compilador (no hay conversiones de tipo)
- Simplifica el canvas (un solo color de wire)
- Suficiente para demostrar el concepto

**Consecuencia:** La estructura de datos de puertos y wires DEBE incluir un campo `type` desde el inicio, aunque en el MVP siempre sea `'number`. Esto evita refactoring cuando se añadan strings y booleanos.

---

## DT-004: Sistema de ficheros tipo LabVIEW

**Fecha:** 2026-03-14  
**Estado:** Adoptada  

**Contexto:** Definir cómo se organizan los ficheros de un proyecto QTorres.

**Decisión:** La estructura de ficheros replica las convenciones de LabVIEW. Los tipos de fichero son análogos: `.qvi` (VI), `.qproj` (proyecto), `.qlib` (librería), `.qclass` (clase), `.qctl` (type definition). La diferencia es que donde LabVIEW guarda binarios opacos, QTorres guarda Red en texto plano.

**Razones:**
- Un usuario de LabVIEW reconoce la estructura de proyecto inmediatamente
- Curva de aprendizaje cero en la organización de ficheros
- Al abrir cualquier fichero, en vez de un binario se encuentra Red legible
- La extensión `.qtorres` genérica se reemplaza por extensiones con significado semántico (`.qvi`, `.qproj`, etc.)

**MVP:** Solo `.qvi` y `.qproj`. Los demás tipos se añaden en fases posteriores.

---

## DT-005: El .qvi es ejecutable — cabecera gráfica + código generado

**Fecha:** 2026-03-14  
**Estado:** Adoptada  

**Contexto:** Definir la estructura interna del fichero `.qvi` y cómo se ejecuta.

**Decisión:** Cada `.qvi` contiene dos secciones en el mismo fichero Red:
1. **Cabecera gráfica** (`qvi-diagram: [...]`): representación completa del Front Panel y Block Diagram. Para Red es una asignación sin efectos.
2. **Código generado**: código Red ejecutable, generado por QTorres al guardar (compilación del diagrama).

El `.qvi` se ejecuta directamente con `red mi-vi.qvi` sin QTorres instalado.

**Razones:**
- Un solo fichero contiene toda la verdad: diagrama visual + código ejecutable
- No hay paso de "compilar a .red" separado — el `.qvi` ya ES el ejecutable
- La homoiconicidad de Red lo permite: `qvi-diagram: [...]` es inerte para el intérprete
- Guardar = recompilar → cabecera y código siempre están sincronizados

**Consecuencia:** El botón Compile desaparece como concepto separado. Save ya genera código ejecutable.

---

## DT-006: Sub-VIs como funciones Red + guarda qtorres-runtime

**Fecha:** 2026-03-14  
**Estado:** Adoptada  

**Contexto:** Definir cómo un VI se reutiliza dentro de otro VI (sub-VI).

**Decisión:** 
- Un VI con **connector pane** genera su código envuelto en una `func` Red.
- La guarda `if not value? 'qtorres-runtime [...]` permite ejecución standalone.
- El VI padre incluye `do %sub-vi.qvi` para cargar la función y la llama directamente.
- QTorres define `qtorres-runtime: true` antes de ejecutar, para que los sub-VIs solo definan la función sin auto-ejecutarse.

**Razones:**
- El sub-VI sigue siendo ejecutable por sí solo (`red suma.qvi`)
- Cuando se carga como sub-VI, solo expone la función sin efectos secundarios
- Es el mecanismo nativo de Red (`do` + `func`), sin patrones artificiales

---

## DT-007: Namespacing de librerías con `context` de Red

**Fecha:** 2026-03-14  
**Estado:** Adoptada  

**Contexto:** Resolver colisiones de nombres cuando dos librerías tienen VIs con el mismo nombre.

**Decisión:** Los VIs dentro de una `.qlib` se encapsulan en un `context` de Red. El acceso se hace con la sintaxis nativa de Red: `libreria/funcion`.

**Ejemplo:**
- LabVIEW: `Utilidades.lvlib » Suma.vi`
- QTorres: `utilidades/suma`

**Razones:**
- `context` es el mecanismo nativo de Red para aislamiento de nombres
- El separador `/` es enforzado por el lenguaje (no una convención que se pueda romper)
- El código generado es autodocumentado: `utilidades/suma` indica la librería de origen
- Alternativa descartada: prefijos (`utilidades-suma`) → no hay aislamiento real, nombres crecen sin control

---

## DT-008: Tres dialectos Red propios

**Fecha:** 2026-03-14  
**Estado:** Adoptada  

**Contexto:** El manifiesto de QTorres cita los dialectos de Red como una de las razones clave del proyecto. Definir dónde se usan dialectos reales (no datos pasivos ni interpolación de strings).

**Decisión:** QTorres define tres dialectos propios, cada uno con gramática procesable con `parse`:

1. **`block-def`** — Define tipos de bloques de forma declarativa. Vocabulario: `block`, `in`, `out`, `config`, `emit`. Procesado al cargar la paleta de bloques.

2. **`qvi-diagram`** — Describe la estructura de un VI (front panel, block diagram, connector). Procesado al cargar un `.qvi`. Valida estructura y campos obligatorios.

3. **`emit`** — Define la semántica de compilación de cada bloque como un bloque Red. El compilador sustituye las palabras de los puertos por los nombres reales de las variables. Es manipulación de bloques Red, no interpolación de strings.

**Razones:**
- Usar dialectos reales aprovecha la homoiconicidad de Red (el punto diferencial del proyecto)
- El código generado se produce manipulando bloques Red, no concatenando strings
- Los dialectos son extensibles: añadir un nuevo tipo de bloque es escribir una definición `block-def`, no modificar el compilador
- El formato `.qvi` queda especificado en Red (reglas de parse), no en código ad-hoc
- Alternativa descartada: interpolación de strings con `{~var~}` → no idiomático, frágil, no validable

**Consecuencia:** El compilador trabaja con `block!` (bloques Red) en todo momento. Nunca genera strings intermedios. El resultado final se serializa a texto solo al escribir el fichero `.qvi`.
