# Bugs del backend GTK — Red en Linux

> **Contexto:** QTorres usa Red/View para su interfaz gráfica. En Linux, Red/View usa el backend GTK3, que actualmente tiene varios bugs críticos. El canvas visual de QTorres depende de posicionamiento preciso — un cable que conecta dos nodos no puede aparecer desplazado entre plataformas. Estos bugs son por tanto **bloqueantes** para QTorres en Linux.
>
> **Estrategia:** Contribuir los fixes directamente al repositorio `red/red`, no añadir workarounds locales en QTorres. Ver [`CONTRIBUTING.md`](../CONTRIBUTING.md) para el proceso.

---

## Bugs confirmados

### GTK-001: `system/view/metrics/dpi` retorna `none`

**Severidad:** Crítica
**Impacto en QTorres:** Offsets incorrectos en el canvas. Las coordenadas de nodos y wires se calculan sin información de DPI, produciendo posicionamiento incorrecto.

**Descripción:**
En Linux, `system/view/metrics/dpi` devuelve `none` en lugar del valor de DPI de la pantalla. En Windows devuelve el valor correcto.

**Workaround temporal conocido:** Ninguno limpio sin parchear el backend.

---

### GTK-002: Coordenadas en píxeles físicos vs DPI virtual

**Severidad:** Crítica
**Impacto en QTorres:** Las posiciones guardadas en un `.qvi` en Windows no reproducen el mismo layout visual en Linux, y viceversa.

**Descripción:**
Windows usa DPI virtual (coordenadas independientes de la densidad de píxeles). Linux usa píxeles físicos directamente. Esto genera posiciones distintas para el mismo diagrama entre plataformas. Un diagrama creado en Windows aparece con elementos descolocados en Linux.

---

### GTK-003: Eventos `resize` reportan tamaños incorrectos

**Severidad:** Alta
**Impacto en QTorres:** El canvas no se adapta correctamente cuando el usuario redimensiona la ventana de QTorres en Linux.

**Descripción:**
Los eventos de cambio de tamaño de ventana reportan dimensiones incorrectas en el backend GTK. La ventana visualmente cambia de tamaño, pero los valores que recibe el código son incorrectos.

---

### GTK-004: Bug de locale — aritmética float incorrecta sin `LC_ALL=C`

**Severidad:** Alta
**Impacto en QTorres:** Los cálculos numéricos del programa del usuario pueden producir resultados incorrectos en Linux con locales que usan coma decimal (ej. `es_ES.UTF-8`).

**Descripción:**
Red en Linux tiene un bug de locale donde la aritmética de punto flotante produce resultados incorrectos a menos que se establezca `LC_ALL=C`. Afecta a cualquier sistema con locale de coma decimal (la mayoría de Europa).

**Workaround temporal:** Lanzar Red con `LC_ALL=C red mi-programa.qvi`. No es aceptable para usuarios finales.

---

### GTK-005: `system/view/metrics/colors` retorna `none`

**Severidad:** Media
**Impacto en QTorres:** No se pueden usar los colores del tema del sistema para la identidad visual. Los colores de la UI de QTorres deben definirse completamente de forma explícita.

**Descripción:**
En Linux, `system/view/metrics/colors` devuelve `none`. En Windows devuelve los colores del tema del sistema operativo.

---

### GTK-006: Backend GTK es 32-bit, requiere librerías i386

**Severidad:** Alta (tendencia creciente)
**Impacto en QTorres:** Instalación compleja en Linux moderno. En algunas distribuciones, QTorres directamente no puede ejecutarse.

**Descripción:**
Red es actualmente 32-bit. El backend GTK requiere las librerías GTK3 i386 en sistemas de 64-bit. Muchas distribuciones Linux modernas están eliminando o han eliminado el soporte para librerías 32-bit (ej. Ubuntu 24.04+ requiere configuración adicional).

**Contexto del roadmap de Red:**
- Red v1.0: migración del core a 64-bit
- Red v1.1: migración del View engine a 64-bit

Cuando Red migre a 64-bit, este problema desaparece. QTorres debe seguir ese roadmap.

---

## Estado de las contribuciones

| Bug | Issue en red/red | Estado |
|-----|-----------------|--------|
| GTK-001 DPI `none` | — | Pendiente de crear |
| GTK-002 Coordenadas físicas vs virtuales | — | Pendiente de crear |
| GTK-003 Resize incorrecto | — | Pendiente de crear |
| GTK-004 Bug locale float | — | Pendiente de crear |
| GTK-005 Colors `none` | — | Pendiente de crear |
| GTK-006 32-bit / i386 | Upstream roadmap | Pendiente de migración 64-bit |
| GTK-007 Modal pierde foco teclado | — | Pendiente de crear |
| GTK-008 `request-file/save` abre diálogo de carpetas | — | Workaround: diálogo VID propio |
| GTK-009 `request-file` no permite controlar tamaño | — | Posible: file browser VID propio |
| DRAW-001 `push` no restaura `font` | [red/red#5134](https://github.com/red/red/issues/5134) | Cerrado upstream (2024-03-07) — pendiente verificar en GTK |

---

### GTK-007: `view/flags [modal]` pierde foco de teclado del window padre

**Severidad:** Alta
**Impacto en QTorres:** Tras cerrar un diálogo modal, `on-key` deja de dispararse en la ventana principal. Delete, Backspace y cualquier tecla dejan de funcionar permanentemente.

**Descripción:**
Al cerrar un diálogo creado con `view/flags [modal]`, el window padre pierde el foco de teclado GTK. Los eventos de ratón siguen funcionando (clicks, drag), pero los eventos de teclado no llegan al `on-key` del window. El bug es permanente: ni clics ni `show` restauran el foco.

La causa probable es que Red/View no llama a `gtk_window_set_transient_for()` o `gtk_window_present()` correctamente al destruir el diálogo modal.

**Notas:**
- `system/view/focal-face` es read-only, no se puede reasignar para forzar el foco.
- No es un bug de GTK en general: apps GTK nativas (GIMP, Inkscape, Gedit) manejan modales correctamente.

**Workaround temporal:** Usar `view/no-wait` en vez de `view/flags [modal]`. El diálogo no es modal pero preserva el foco. Requiere variables de módulo en vez de `/local` porque la función retorna antes de que se cierre el diálogo.

**Test reproducible:** `tests/test-focus-modal.red` — V1 reproduce el bug, V2 muestra el workaround.

---

## Bugs del engine Draw (cross-platform)

> Bugs del motor Draw de Red que afectan a QTorres en **todas** las plataformas (Windows, Linux, macOS). Se documentan aquí junto con los bugs GTK porque comparten el mismo proceso de seguimiento y contribución upstream.

### DRAW-001: `push` no preserva ni restaura el estado de `font`

**Severidad:** Alta
**Impacto en QTorres:** No se puede usar `push`/`pop` para aislar estado gráfico entre items del Front Panel. Obliga a un reset manual de `pen`, `fill-pen`, `line-width` y `font` al inicio de cada `render-fp-item`.

**Issue upstream:** [red/red#5134](https://github.com/red/red/issues/5134) — **cerrado el 2024-03-07**, fix en commit [`e0c9abc`](https://github.com/red/red/commit/e0c9abcddfd9749f713ff20fb3d3a4d2cac5c933).
**Issue relacionado:** [red/red#4261](https://github.com/red/red/issues/4261) — crash en GTK con `font!` y estilos.

**Estado actual:** El bug cross-platform fue resuelto upstream en Red ≥ 0.6.5. Sin embargo, **queda pendiente verificar si el fix funciona correctamente en el backend GTK (Linux)**. El error original en QTorres se observó en Linux/GTK, donde `font!` llegaba al engine Draw como `make object! []` (tipo genérico). Esto podría ser un problema adicional específico de GTK no cubierto por el fix de red/red#5134.

**Descripción:**

El comando `push` en Red Draw guarda y restaura "transformations, clipping region, and pen settings" según la documentación oficial. Sin embargo, **`font` no forma parte del estado guardado/restaurado**. Un `font` establecido dentro de un bloque `push` "escapa" y afecta a todos los comandos `text` posteriores.

Caso mínimo de reproducción (de red/red#5134):
```red
; El segundo "ABC" debería usar la fuente por defecto, no la de size: 20
draw 30x50 compose/deep [
    text 0x0 "ABC"
    push [font (make font! [size: 20])]
    text 0x15 "ABC"
]
```

En QTorres, el problema se manifiesta porque `render-fp-panel` concatena los bloques Draw de cada item:
```red
; Patrón ideal (que NO funciona por este bug):
foreach item model/front-panel [
    append cmds 'push
    append/only cmds render-fp-item item selected?
]
```

Con `push`, el `font!` object dentro de `render-fp-item` no se restaura al salir del bloque. Además, en Linux/GTK se observó que el `font!` puede llegar al engine Draw como `make object! []` (objeto genérico) en vez del tipo `font!` real, causando:
```
*** Script Error: invalid Draw dialect input at: [font make object! [] text ...]
```

**Causa raíz:**

1. **Bug del engine Draw (cross-platform) — RESUELTO:** `push`/`pop` internamente no salvaba/restauraba el puntero de `font`. Confirmado tanto en Windows como en Linux (red/red#5134). **Corregido** en commit [`e0c9abc`](https://github.com/red/red/commit/e0c9abcddfd9749f713ff20fb3d3a4d2cac5c933) (2024-03-07), disponible en Red ≥ 0.6.5.

2. **Posible problema residual en Linux/GTK — PENDIENTE DE VERIFICAR:** El error `make object! []` sugiere que en el backend GTK, el `font!` pierde su tipo al ser procesado dentro de un bloque `push`. Esto podría ser:
   - Un `copy/deep` interno del bloque de `push` que serializa `font!` a `object!`
   - El parser del dialecto Draw en GTK que no reconoce `font!` dentro de sub-bloques
   - Una interacción entre `compose` y el procesamiento interno de `push`

   Hay que verificar si este problema persiste con Red ≥ 0.6.5 en Linux/GTK.

**Workaround actual en QTorres:**

Reset manual de estado Draw al inicio de cada `render-fp-item` (`src/ui/panel/panel.red`, línea 203):
```red
append cmds compose [pen 0.0.0  fill-pen off  line-width 1  font (fp-black-font)]
```

Funciona correctamente. Cada item resetea todo el estado Draw que necesita, eliminando la dependencia del item anterior.

**Plan de resolución (3 niveles):**

**Nivel 1 — Mantener workaround actual (ahora):**
El reset manual en `render-fp-item` es correcto y funcional. No requiere cambios inmediatos.

**Nivel 2 — Verificar el fix upstream en GTK (próximo paso):**
- Actualizar el binario de Red a ≥ 0.6.5 (que incluye el fix de red/red#5134).
- Ejecutar los tests de reproducción (abajo) en Linux/GTK.
- Si `push` restaura `font` correctamente en GTK → pasar a Nivel 3.
- Si `font!` sigue llegando como `make object! []` en GTK → documentar como bug GTK-específico separado y mantener el workaround.

**Nivel 3 — Migrar a `push`/`pop` (cuando se verifique que funciona en GTK):**
- Refactorizar `render-fp-panel` al patrón canónico:
  ```red
  foreach item model/front-panel [
      append cmds 'push
      append/only cmds render-fp-item item selected?
  ]
  ```
- Eliminar el reset manual de `render-fp-item`.

**Pruebas necesarias para validar el fix upstream:**
```red
; Test 1: font se restaura después de push
f1: make font! [size: 12]
f2: make font! [size: 24]
draw 100x50 compose/deep [
    font (f1) text 0x0 "Small"
    push [font (f2) text 0x15 "Big"]
    text 0x30 "Should be Small again"
]

; Test 2: font! mantiene su tipo dentro de push
cmds: compose/deep [push [font (make font! [color: 0.0.0]) text 10x10 "Test"]]
; Verificar que el tercer elemento del bloque interno es font! (no object!)
```

---

## Cómo reproducir los bugs

> Sección a completar conforme se caractericen los bugs con casos mínimos reproducibles.

Para cada bug, el proceso es:

1. Escribir un script Red mínimo que reproduzca el comportamiento incorrecto
2. Verificar que el mismo script funciona correctamente en Windows
3. Abrir un issue en `https://github.com/red/red` con el script mínimo y la descripción del comportamiento esperado vs observado
4. Actualizar la tabla de estado de arriba con el link al issue

---

## Referencias

- Repositorio Red: https://github.com/red/red
- Branch GTK de Red: rama `GTK` del repositorio oficial
- Proceso de contribución: [`CONTRIBUTING.md`](../CONTRIBUTING.md)
