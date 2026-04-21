Red [
    Title: "Test para Issue #49 — GTK-010: on-change enganchado tras Run"
    Purpose: "Validar si GTK-010 (field on-change queda enganchado después de Run) está resuelto en fork"
    Manual: true
    Platform: "Linux GTK3 only"
]

comment {
    CASO DE TEST MANUAL PARA GTK-010

    GTK-010: `on-change` de field nativo queda enganchado tras ejecutar Run.
    Síntoma: después de pulsar Run una vez, los controles string del Front Panel
    se auto-actualizan al escribir, sin necesidad de volver a pulsar Run.
    Comportamiento esperado: indicadores solo se actualizan al pulsar Run explícitamente.

    CÓMO REVALIDAR:
    1. Abrir Telekino: ./red-view src/telekino.red
    2. Crear VI simple con string control (default: "Hola") y string indicator (default: "---")
    3. Conectar control → indicator
    4. Pulsar Run — indicator muestra "Hola"
    5. EN EL CONTROL, escribir "Mundo"
    6. SIN pulsar Run, observar:
       - ESPERADO (bug fijo): indicator sigue mostrando "Hola"
       - ACTUAL (bug presente): indicator se actualiza a "Mundo" automáticamente
    7. Pulsar Run — indicator debe mostrar "Mundo"

    ESTADO (2026-04-17):
    - Fork anlaco/red tiene fixes GTK hasta commit 2a93443
    - Los fixes no cubren explícitamente GTK-010 (on-change enganchado)
    - Requiere verificación manual en próxima sesión con GUI

    NOTA PARA IA:
    Este test no puede automatizarse con red-cli (headless).
    Añadir a checklist QA manual de Fase 3.
}
