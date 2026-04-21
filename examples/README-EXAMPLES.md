# Ejemplos Telekino

Corpus de VIs funcionales que demuestran features del proyecto.

## Ejemplos unitarios (features Fase 1-3)

- `suma-basica.qvi` — Aritmética básica (Fase 1)
- `suma-subvi.qvi` — Sub-VI standalone (Fase 3)
- `programa-con-subvi.qvi` — Llamada a sub-VI (Fase 3)
- `while-loop-basico.qvi` — While Loop (Fase 2)
- `while-loop-suma.qvi` — While Loop con shift registers (Fase 2)
- `for-loop-basico.qvi` — For Loop (Fase 2)
- `case-numeric.qvi` — Case Structure selector numérico (Fase 2)
- `case-boolean.qvi` — Case Structure selector booleano (Fase 2)
- `cluster-basico.qvi` — Cluster con Bundle/Unbundle (Fase 2)
- `waveform-demo.qvi` — Waveform Chart/Graph (Fase 2)

## Librerías

- `math.qlib` / `math/` — Librería ejemplo con Add, Subtract (Fase 3)
- `usa-libreria.qvi` — VI que consume math.qlib (Fase 3)

## Proyecto (Fase 5 pendiente)

- `ejemplo.qproj` — Prototipo temprano de formato `.qproj`. Define proyecto con 3 VIs y target executable. Sin tooling Project Explorer aún (Fase 5).

## Ejecución

**Headless (terminal):**
```bash
./red-cli examples/suma-basica.qvi A=5.0 B=3.0
# Salida: 8.0
```

**UI (ventana):**
```bash
./red-view examples/suma-basica.qvi
# Abre ventana con Front Panel
```

## Validación

Todos los ejemplos pasan en `tests/run-all.red` (482 tests PASS).
