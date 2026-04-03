# Findings — Issue #13: Waveform Chart y Graph

## Investigación LabVIEW (2026-04-03)

### Diferencia fundamental Chart vs Graph

| Aspecto | Waveform Chart | Waveform Graph |
|---------|----------------|----------------|
| **Datos** | Buffer circular (history) | Sin buffer |
| **Actualización** | Incremental (punto a punto) | Batch (reemplaza todo) |
| **Input** | Acepta scalar O array | Requiere array |
| **Uso** | Real-time, loops | Post-análisis |

### Comportamiento en loops

En LabVIEW:
- **Chart dentro de loop**: Se actualiza en CADA iteración. El wire conecta un valor escalar.
- **Graph dentro de loop**: Se actualiza al FINAL. El wire usa auto-indexing para acumular valores en un array.

### Default buffer size

LabVIEW usa 1024 puntos por defecto para el history buffer del Chart.

### Dimensiones

LabVIEW no documenta dimensiones fijas en pixels. El tamaño por defecto depende de la versión y resolución de pantalla. Para QTorres:
- Área de trazado: 200x160 px (razonable para ver señal)
- Con bordes: ~240x200 px total

---

## Decisión de diseño para QTorres

### Waveform Chart

```red
; fp-item
type: 'waveform-chart
data-type: 'number
config: [history-size 1024]
value: []  ; buffer circular
```

- Input: scalar (se añade al buffer) o array (se añade punto a punto)
- Buffer circular: cuando se llena, descarta el más antiguo
- Render: fondo negro, línea verde, escala automática

### Waveform Graph

```red
; fp-item
type: 'waveform-graph
data-type: 'array
value: []  ; array completo a mostrar
```

- Input: array obligatorio
- Render: fondo negro, línea verde, escala automática
- No tiene buffer interno

### Wire colors

- Chart input: naranja (numérico escalar)
- Graph input: naranja con borde doble (array numérico)