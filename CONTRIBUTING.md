# Contribuir a QTorres

QTorres es un proyecto open source en desarrollo inicial. Las contribuciones son bienvenidas.

## Tipos de contribución

### 1. Contribuciones al código de QTorres

Todo el código de QTorres está en Red-Lang. Ver [`CLAUDE.md`](CLAUDE.md) para el contexto completo del proyecto, la arquitectura, el stack y el orden de trabajo recomendado.

**Antes de contribuir:**
- Lee [`docs/PLANNING.md`](docs/PLANNING.md) para entender qué decisiones arquitecturales están pendientes. No implementar módulos bloqueados por decisiones no tomadas (especialmente P1 — formato `.qvi`).
- Mira el backlog en https://github.com/users/anlaco/projects/1
- Trabaja Issues en orden de Fase (no empezar Fase 1 sin completar Fase 0, etc.)

**Flujo de trabajo:**
1. Crea un branch desde `main`
2. Implementa en el módulo correspondiente de `src/`
3. Usa `MVP/QTorres-mvp.red` como referencia de implementación existente
4. Verifica con los ejemplos de `examples/`
5. Abre un Pull Request

### 2. Contribuciones al backend GTK de Red (crítico para Linux)

> Esta es una de las contribuciones más valiosas que alguien puede hacer al proyecto ahora mismo.

QTorres en Linux depende del backend GTK de Red (`red/red`), que tiene varios bugs críticos que bloquean el funcionamiento del canvas visual. Ver [`docs/GTK_ISSUES.md`](docs/GTK_ISSUES.md) para la lista completa de bugs con descripción y estado.

**Por qué contribuir a `red/red` en lugar de parchear QTorres:**
- Los fixes en `red/red` benefician a todo el ecosistema Red en Linux, no solo a QTorres.
- Un workaround local en QTorres sería frágil y crearía deuda técnica.
- La estrategia del proyecto es trabajar *con* Red, no alrededor de él.

**Proceso para contribuir un fix GTK a `red/red`:**

1. **Reproduce el bug localmente**
   - Escribe un script Red mínimo que reproduzca el comportamiento incorrecto
   - Confirma que el mismo script funciona correctamente en Windows (o en la spec)

2. **Verifica que no hay un issue abierto ya**
   - Busca en https://github.com/red/red/issues

3. **Abre un issue en `red/red`**
   - Incluye el script mínimo reproducible
   - Describe el comportamiento esperado vs el observado
   - Menciona la versión de Red, la distribución Linux y la versión de GTK

4. **Desarrolla el fix**
   - El backend GTK está en la rama `GTK` del repo `red/red`
   - Los cambios van en los ficheros del sistema View de Red

5. **Abre un Pull Request en `red/red`**
   - Referencia el issue
   - Incluye test si es posible

6. **Actualiza `docs/GTK_ISSUES.md`** en este repositorio con el link al issue/PR de `red/red`

**Bugs prioritarios para QTorres** (en orden de impacto):

| Bug | Descripción | Detalle |
|-----|-------------|---------|
| GTK-001 | `system/view/metrics/dpi` retorna `none` | [`docs/GTK_ISSUES.md#gtk-001`](docs/GTK_ISSUES.md#gtk-001-systemviewmetricsdpi-retorna-none) |
| GTK-002 | Coordenadas físicas vs DPI virtual | [`docs/GTK_ISSUES.md#gtk-002`](docs/GTK_ISSUES.md#gtk-002-coordenadas-en-píxeles-físicos-vs-dpi-virtual) |
| GTK-004 | Bug de locale — float incorrecto sin `LC_ALL=C` | [`docs/GTK_ISSUES.md#gtk-004`](docs/GTK_ISSUES.md#gtk-004-bug-de-locale--aritmética-float-incorrecta-sin-lc_allc) |

### 3. Documentación

La documentación vive en `docs/`. Si encuentras algo incorrecto, desactualizado o poco claro, corrige directamente con un PR.

Los conflictos entre documentos están marcados con `[REVISAR]`. Si puedes resolver uno con información definitiva, hazlo y quita el marcador.

### 4. Ejemplos

Los ejemplos de `.qvi` viven en `examples/`. Un ejemplo nuevo que demuestre una capacidad del sistema (o una limitación conocida) es siempre útil.

---

## Convenciones

- Todo el código en Red-Lang, sin excepciones (DT-001)
- Los ficheros `.qvi`, `.qproj`, etc. son bloques Red válidos (DT-002)
- Los dialectos usan `parse` de Red, nunca interpolación de strings (DT-008)
- El compilador manipula bloques Red, nunca genera strings intermedios

---

## Links útiles

- Repositorio QTorres: https://github.com/anlaco/QTorres
- Backlog: https://github.com/users/anlaco/projects/1
- Repositorio Red: https://github.com/red/red
- Documentación Red: https://www.red-lang.org/
