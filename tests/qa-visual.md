# QA Visual — Test Manual entre Fases

> **Propósito:** Checklist exhaustivo para detectar bugs visuales e interactivos.
> Ejecutar entre cada fase del proyecto, guiado por una IA o manualmente.
>
> **Cómo usar:** Abrir QTorres (`red-view src/qtorres.red`), seguir los pasos en orden.
> Marcar cada test como PASS/FAIL. Anotar bugs con descripción y screenshot si es posible.
>
> **Última ejecución:** (pendiente)

---

## Convenciones

- **[BD]** = Block Diagram (canvas izquierdo)
- **[FP]** = Front Panel (canvas derecho)
- **Alt+Click** = Abrir paleta de bloques/controles
- **Dbl-Click** = Doble clic
- Resultado esperado entre paréntesis

---

## 1. Toolbar y ventana principal

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 1.1 | Abrir QTorres | Ventana con BD (izquierda) y FP (derecha), toolbar arriba con Run/Save/Load | |
| 1.2 | Verificar que BD y FP están vacíos | Sin nodos, wires ni controles | |

---

## 2. Paleta del BD — Creación de nodos

Para cada tipo de nodo, hacer **Alt+Click en el BD** y seleccionar el botón correspondiente.

### 2.1 Nodos matemáticos

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 2.1.1 | Alt+Click → botón "+" | Nodo `add` aparece con puertos `a`, `b` (entrada) y `result` (salida) | |
| 2.1.2 | Alt+Click → botón "−" | Nodo `sub` aparece | |
| 2.1.3 | Alt+Click → botón "×" | Nodo `mul` aparece | |
| 2.1.4 | Alt+Click → botón "÷" | Nodo `div` aparece | |

### 2.2 Nodos de entrada (constantes y controles)

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 2.2.1 | Alt+Click → "Const" | Nodo `const` con puerto `result` (naranja) | |
| 2.2.2 | Alt+Click → "B-Const" | Nodo `bool-const` con puerto `result` (verde) | |
| 2.2.3 | Alt+Click → "S-Const" | Nodo `str-const` con puerto `result` (rosa) | |
| 2.2.4 | Alt+Click → "Arr[]" | Nodo `arr-const` con puerto `result` (azul, doble borde) | |

### 2.3 Nodos de salida

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 2.3.1 | Alt+Click → "Display" | Nodo `display` con puerto `value` (entrada) | |

### 2.4 Nodos lógicos

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 2.4.1 | Alt+Click → "AND" | Nodo `and-op` con puertos `a`, `b` (entrada, verde) y `result` (salida, verde) | |
| 2.4.2 | Alt+Click → "OR" | Nodo `or-op` | |
| 2.4.3 | Alt+Click → "NOT" | Nodo `not-op` con un solo puerto de entrada | |

### 2.5 Nodos comparadores

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 2.5.1 | Alt+Click → ">" | Nodo `gt-op` — entradas naranjas, salida verde | |
| 2.5.2 | Alt+Click → "<" | Nodo `lt-op` | |
| 2.5.3 | Alt+Click → "=" | Nodo `eq-op` | |
| 2.5.4 | Alt+Click → "≠" | Nodo `neq-op` | |

### 2.6 Nodos string

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 2.6.1 | Alt+Click → "Concat" | Nodo con puertos `a`, `b` (rosa) y `result` (rosa) | |
| 2.6.2 | Alt+Click → "Len" | Nodo con entrada rosa, salida naranja | |
| 2.6.3 | Alt+Click → "→STR" | Nodo con entrada naranja, salida rosa | |

### 2.7 Nodos array

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 2.7.1 | Alt+Click → "Build[]" | Nodo `build-array` | |
| 2.7.2 | Alt+Click → "Index[]" | Nodo `index-array` — entrada array + index, salida number | |
| 2.7.3 | Alt+Click → "Size[]" | Nodo `array-size` — entrada array, salida number | |
| 2.7.4 | Alt+Click → "Subset[]" | Nodo `array-subset` — 3 entradas, salida array | |

### 2.8 Nodos cluster

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 2.8.1 | Alt+Click → "Bundle" | Nodo `bundle` con solo puerto `result` (marrón) | |
| 2.8.2 | Alt+Click → "Unbundle" | Nodo `unbundle` con solo puerto `cluster-in` (marrón) | |
| 2.8.3 | Verificar tamaño de Bundle/Unbundle vacíos | Deben tener tamaño similar a un nodo normal (BUG CONOCIDO #48 si son demasiado altos) | |

### 2.9 Estructuras

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 2.9.1 | Alt+Click → "While" | Rectángulo While Loop con terminales [i] (azul) y [●] (verde) | |
| 2.9.2 | Alt+Click → "For" | Rectángulo For Loop con terminal [N] (naranja) y [i] (azul) | |
| 2.9.3 | Alt+Click → "Case" | Rectángulo Case Structure con barra de navegación ◀ ▶ [+] [-] y terminal [?] | |

---

## 3. Interacción con nodos en el BD

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 3.1 | Click en un nodo | Se selecciona (borde cian) | |
| 3.2 | Drag un nodo | El nodo se mueve con el ratón | |
| 3.3 | Delete/Backspace con nodo seleccionado | El nodo desaparece | |
| 3.4 | Crear un wire y luego borrar el nodo origen | El nodo y el wire desaparecen | |

---

## 4. Diálogos de edición (Dbl-Click en BD)

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 4.1 | Dbl-Click en `const` | Diálogo con campo numérico. Escribir "42", OK → el nodo muestra 42 | |
| 4.2 | Dbl-Click en `bool-const` | Alterna el valor true↔false visualmente en el nodo | |
| 4.3 | Dbl-Click en `str-const` | Diálogo con campo texto. Escribir "hola", OK → el nodo muestra "hola" | |
| 4.4 | Dbl-Click en `arr-const` | Diálogo con campo texto. Escribir "1.0 2.0 3.0", OK | |
| 4.5 | Dbl-Click en `add` (o cualquier nodo normal) | Diálogo de renombrar label | |
| 4.6 | Dbl-Click en `bundle` | Diálogo de campos cluster (nombre tipo por línea) | |
| 4.7 | Dbl-Click en `unbundle` | Diálogo de campos cluster (mismo formato) | |
| 4.8 | Cancelar cualquier diálogo | Sin cambios en el nodo | |

---

## 5. Wiring — Conexión de nodos

### 5.1 Wires válidos (tipo compatible)

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 5.1.1 | Conectar `const/result` → `add/a` | Wire naranja entre los dos puertos | |
| 5.1.2 | Conectar `bool-const/result` → `and-op/a` | Wire verde | |
| 5.1.3 | Conectar `str-const/result` → `concat/a` | Wire rosa | |
| 5.1.4 | Conectar `bundle/result` → `unbundle/cluster-in` | Wire marrón | |
| 5.1.5 | Conectar `arr-const/result` → `index-array/arr` | Wire azul (doble borde) | |

### 5.2 Wires inválidos (tipo incompatible)

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 5.2.1 | Intentar conectar `const/result` → `and-op/a` (number→boolean) | Wire rechazado o rojo — no se crea conexión | |
| 5.2.2 | Intentar conectar `str-const/result` → `add/a` (string→number) | Wire rechazado | |

### 5.3 Regla de puerto único

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 5.3.1 | Conectar dos wires al mismo puerto de entrada | Solo uno permitido — el segundo reemplaza o se rechaza | |

### 5.4 Borrado de wires

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 5.4.1 | Click en un wire para seleccionarlo | Wire se resalta (cian) | |
| 5.4.2 | Delete/Backspace con wire seleccionado | Wire desaparece, nodos permanecen | |

---

## 6. Estructuras — While Loop

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 6.1 | Crear While Loop | Rectángulo con [i] (azul, abajo-izq) y [●] (verde, abajo-der) | |
| 6.2 | Drag el borde del While Loop | Toda la estructura y sus nodos internos se mueven | |
| 6.3 | Resize (handle esquina inferior-der) | La estructura se agranda/reduce (mínimo 120x80) | |
| 6.4 | Alt+Click dentro del While Loop | Paleta aparece — crear nodo `add` dentro | |
| 6.5 | Verificar que el nodo interno no sale del rectángulo | Drag del nodo se confina al interior | |
| 6.6 | Conectar [i] a un nodo interno | Wire azul desde terminal [i] al nodo | |
| 6.7 | Conectar un nodo interno al terminal [●] | Wire verde (condición de parada) | |
| 6.8 | Add SR → "Number" | Terminales ▲ (izq) y ▼ (der) aparecen en los bordes | |
| 6.9 | Conectar wire externo → SR-left (▲) | Wire va desde nodo externo al terminal SR izquierdo | |
| 6.10 | Conectar SR-right (▼) → nodo externo | Wire sale del terminal SR derecho al nodo externo | |
| 6.11 | Dbl-Click en SR-left | Diálogo editar valor inicial | |
| 6.12 | Delete While Loop | Estructura + nodos internos + wires + SRs eliminados | |

---

## 7. Estructuras — For Loop

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 7.1 | Crear For Loop | Rectángulo con [N] (naranja, arriba-izq) y [i] (azul) | |
| 7.2 | Conectar `const` → terminal [N] | Wire naranja — define número de iteraciones | |
| 7.3 | Crear nodo interno y conectar [i] a él | Wire azul — variable de iteración | |
| 7.4 | Add SR + conectar como en While | SRs funcionan igual que en While Loop | |
| 7.5 | Resize y drag | Igual que While Loop | |

---

## 8. Estructuras — Case Structure

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 8.1 | Crear Case Structure | Rectángulo con barra de navegación arriba (◀ ▶ [+] [-]) y terminal [?] | |
| 8.2 | Click botón [+] | Se añade un frame nuevo. El contador muestra "2" (o similar) | |
| 8.3 | Click botón ▶ | Cambia al siguiente frame (el contenido del interior cambia) | |
| 8.4 | Click botón ◀ | Vuelve al frame anterior | |
| 8.5 | Click botón [-] | Elimina el frame actual | |
| 8.6 | Crear nodos en Frame 0 | Los nodos solo aparecen en Frame 0, no en Frame 1 | |
| 8.7 | Navegar a Frame 1 y crear otros nodos | Nodos solo en Frame 1 | |
| 8.8 | Conectar wire al terminal [?] (selector) | Wire de tipo compatible conectado al selector | |
| 8.9 | Resize y drag | Igual que While/For | |

---

## 9. Front Panel — Creación y edición

### 9.1 Paleta del FP

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 9.1.1 | Alt+Click en FP → "Num Ctrl" | Control numérico en FP + nodo `control` en BD | |
| 9.1.2 | Alt+Click → "Num Ind" | Indicador numérico en FP + nodo `indicator` en BD | |
| 9.1.3 | Alt+Click → "Bool Ctrl" | Control booleano (checkbox) en FP + nodo en BD | |
| 9.1.4 | Alt+Click → "Bool Ind" | Indicador booleano (LED) en FP + nodo en BD | |
| 9.1.5 | Alt+Click → "Str Ctrl" | Control string en FP + nodo en BD | |
| 9.1.6 | Alt+Click → "Str Ind" | Indicador string en FP + nodo en BD | |
| 9.1.7 | Alt+Click → "Arr Ctrl" | Control array en FP + nodo en BD | |
| 9.1.8 | Alt+Click → "Arr Ind" | Indicador array en FP + nodo en BD | |
| 9.1.9 | Alt+Click → "Cluster Ctrl" | Control cluster en FP (caja marrón) | |
| 9.1.10 | Alt+Click → "Cluster Ind" | Indicador cluster en FP (caja marrón) | |

### 9.2 Interacción con controles del FP

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 9.2.1 | Click en `control` numérico | Diálogo editar valor | |
| 9.2.2 | Click en `bool-control` | Alterna true↔false (color cambia) | |
| 9.2.3 | Click en `str-control` | Diálogo editar string | |
| 9.2.4 | Click en `arr-control` | Diálogo editar array | |
| 9.2.5 | Click en `cluster-control` | Diálogo editar campos (campo: valor por línea) | |
| 9.2.6 | Click en cualquier indicator | No pasa nada (read-only) | |
| 9.2.7 | Drag un control | El control se mueve por el FP | |
| 9.2.8 | Delete control con Delete/Backspace | Control desaparece del FP + nodo asociado del BD | |

### 9.3 Sincronización BD ↔ FP

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 9.3.1 | Crear control en FP → verificar BD | Nodo correspondiente aparece en el BD | |
| 9.3.2 | Borrar control en FP → verificar BD | Nodo desaparece del BD + wires asociados | |
| 9.3.3 | Borrar nodo control/indicator en BD | Control/indicator correspondiente desaparece del FP | |
| 9.3.4 | Verificar posicionamiento en BD | Los nodos no se superponen ni salen del canvas (BUG CONOCIDO #51) | |

---

## 10. Pipeline completo — Suma básica

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 10.1 | Crear: Num Ctrl (A), Num Ctrl (B), Num Ind (Resultado) desde FP | 2 controles + 1 indicador en FP, 3 nodos en BD | |
| 10.2 | Crear `add` en BD | Nodo add con puertos a, b, result | |
| 10.3 | Conectar ctrl_A → add/a, ctrl_B → add/b | 2 wires naranjas | |
| 10.4 | Conectar add/result → ind_Resultado | 1 wire naranja | |
| 10.5 | Poner A=5, B=3 en FP (click para editar) | Valores actualizados | |
| 10.6 | Pulsar Run | Indicador muestra 8.0 | |

---

## 11. Pipeline completo — Boolean

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 11.1 | Nuevo VI (o borrar todo) | Limpio | |
| 11.2 | Crear Bool Ctrl (X), Bool Ctrl (Y), Bool Ind (Resultado) | Controles + indicador booleanos | |
| 11.3 | Crear `and-op` en BD, conectar X→a, Y→b, result→ind | Wires verdes | |
| 11.4 | Poner X=true, Y=false | Click toggle en FP | |
| 11.5 | Run | Indicador en false (true AND false = false) | |
| 11.6 | Poner Y=true, Run | Indicador en true (true AND true = true) | |

---

## 12. Pipeline completo — String

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 12.1 | Nuevo VI | Limpio | |
| 12.2 | Crear Str Ctrl (A), Str Ctrl (B), Str Ind (Resultado) | Controles + indicador string | |
| 12.3 | Crear `concat` en BD, conectar A→a, B→b, result→ind | Wires rosa | |
| 12.4 | Poner A="Hola ", B="mundo" | Editar via FP | |
| 12.5 | Run | Indicador muestra "Hola mundo" | |

---

## 13. Pipeline completo — Cluster

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 13.1 | Nuevo VI | Limpio | |
| 13.2 | Crear Str Ctrl, Num Ctrl, Bool Ctrl desde FP | 3 controles en FP + 3 nodos en BD | |
| 13.3 | Crear Bundle en BD, Dbl-Click → campos: `nombre string`, `valor number`, `activo boolean` | Bundle con 3 puertos de entrada coloreados + 1 salida marrón | |
| 13.4 | Crear Unbundle en BD, Dbl-Click → mismos campos | Unbundle con 1 entrada marrón + 3 salidas coloreadas | |
| 13.5 | Crear Str Ind, Num Ind, Bool Ind desde FP | 3 indicadores | |
| 13.6 | Conectar: ctrls → bundle, bundle → unbundle, unbundle → inds | Wires de colores correctos | |
| 13.7 | Poner valores: nombre="test", valor=42, activo=true | Editar via FP | |
| 13.8 | Run | Indicadores muestran: "test", 42.0, true (verde) | |

---

## 14. Pipeline completo — While Loop con Shift Register

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 14.1 | Nuevo VI | Limpio | |
| 14.2 | Crear Num Ind (Resultado) desde FP | Indicador numérico | |
| 14.3 | Crear While Loop en BD | Rectángulo con [i] y [●] | |
| 14.4 | Add SR tipo Number en While Loop | Terminales ▲▼ en bordes | |
| 14.5 | Dbl-Click SR-left → valor inicial 0 | SR inicia en 0 | |
| 14.6 | Crear `const` (valor=1) y `add` dentro del While | Nodos internos | |
| 14.7 | Conectar SR-left → add/a, const → add/b, add/result → SR-right | SR acumula +1 cada iteración | |
| 14.8 | Crear `const` (valor=10), `gt-op` dentro | Comparador | |
| 14.9 | Conectar [i] → gt-op/a, const_10 → gt-op/b, gt-op → [●] | Para cuando i > 10 | |
| 14.10 | Conectar SR-right → ind_Resultado (wire externo) | SR sale del loop | |
| 14.11 | Run | Indicador muestra resultado de la acumulación | |

---

## 15. Pipeline completo — For Loop

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 15.1 | Nuevo VI | Limpio | |
| 15.2 | Crear Num Ctrl (N), Num Ind (Resultado) | Control + indicador | |
| 15.3 | Crear For Loop, conectar ctrl_N → [N] | Wire naranja al terminal | |
| 15.4 | Add SR tipo Number (init=0), add + const(1) dentro | Suma acumulativa | |
| 15.5 | Conectar SR → add → SR, SR-right → ind | Pipeline de acumulación | |
| 15.6 | Poner N=10, Run | Resultado = 10.0 (0+1+1+...+1 diez veces) | |

---

## 16. Pipeline completo — Case Structure

### 16.1 Case numérico

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 16.1.1 | Nuevo VI, crear Num Ctrl (Selector), Num Ind (Resultado) | Control + indicador | |
| 16.1.2 | Crear Case Structure, conectar ctrl_Selector → [?] | Wire al selector | |
| 16.1.3 | En Frame 0: crear `const` (valor=100), conectar a indicador (si hay túnel) | Frame 0 produce 100 | |
| 16.1.4 | [+] para crear Frame 1, poner `const` (valor=200) | Frame 1 produce 200 | |
| 16.1.5 | Poner Selector=0, Run | Resultado = 100 | |
| 16.1.6 | Poner Selector=1, Run | Resultado = 200 | |

### 16.2 Case booleano

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 16.2.1 | Nuevo VI, crear Bool Ctrl (Selector), Str Ind (Resultado) | Control boolean + indicador string | |
| 16.2.2 | Crear Case, conectar ctrl_bool → [?] | Selector booleano (compila a either) | |
| 16.2.3 | Frame true: `str-const` "verdadero", Frame false: `str-const` "falso" | Cada frame produce texto diferente | |
| 16.2.4 | Toggle true, Run | "verdadero" | |
| 16.2.5 | Toggle false, Run | "falso" | |

---

## 17. Serialización — Save/Load round-trip

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 17.1 | Con un pipeline completo montado, pulsar Save | Diálogo de guardado → guardar como "qa-test.qvi" | |
| 17.2 | Cerrar y reabrir QTorres | Ventana limpia | |
| 17.3 | Load → seleccionar "qa-test.qvi" | Diagrama completo restaurado: nodos, wires, estructuras, FP | |
| 17.4 | Verificar que todos los wires están conectados | Sin wires rotos ni sueltos | |
| 17.5 | Verificar que los valores de controles se preservan | Los defaults están como se guardaron | |
| 17.6 | Run tras cargar | Mismo resultado que antes de guardar | |

---

## 18. Ejecución directa del .qvi

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 18.1 | `red-view qa-test.qvi` desde terminal | Se abre ventana con Front Panel compilado (faces nativas) | |
| 18.2 | Interactuar con el VI compilado (poner valores, Run) | Resultados correctos | |
| 18.3 | `./red-cli qa-test.qvi headless` | Output de indicadores en terminal (BUG CONOCIDO #50 si no hay output) | |

---

## 19. Ejecución de los ejemplos existentes

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 19.1 | `./red-cli examples/suma-basica.qvi headless` | Output numérico correcto | |
| 19.2 | `./red-cli examples/while-loop-basico.qvi headless` | Output del while loop | |
| 19.3 | `./red-cli examples/while-loop-suma.qvi headless` | Suma acumulativa correcta | |
| 19.4 | `./red-cli examples/for-loop-basico.qvi headless` | Resultado: 45.0 | |
| 19.5 | `./red-cli examples/case-numeric.qvi headless` | Output del case numérico | |
| 19.6 | `./red-cli examples/case-boolean.qvi headless` | Output del case booleano | |
| 19.7 | `./red-cli examples/cluster-basico.qvi headless` | `nombre: sensor_A  voltaje: 12.5  activo: true` | |

---

## 20. Tests automatizados

| # | Paso | Resultado esperado | PASS/FAIL |
|---|------|--------------------|-----------|
| 20.1 | `./red-cli tests/run-all.red` | Todos los tests PASS (actualmente 423/423) | |

---

## 21. Bugs conocidos — Verificar estado

| # | Bug | Issue | Estado esperado |
|---|-----|-------|-----------------|
| 21.1 | Bundle/Unbundle vacíos altura excesiva | #48 | Pendiente (verificar si sigue) |
| 21.2 | String se auto-actualiza sin Run tras primer Run | #49 | Pendiente (verificar si sigue) |
| 21.3 | Headless no imprime indicadores en VIs de UI | #50 | Pendiente (verificar si sigue) |
| 21.4 | Nodos del BD salen del canvas al crear desde FP | #51 | Pendiente (verificar si sigue) |

---

## Registro de ejecuciones

| Fecha | Fase | Tests total | PASS | FAIL | Bugs nuevos |
|-------|------|-------------|------|------|-------------|
| | | | | | |
