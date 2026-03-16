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
