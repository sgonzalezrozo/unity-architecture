# Cómo trabaja el agente

| Pides | El agente |
|---|---|
| Pregunta, explicación, review | Responde directamente |
| Cambio pequeño sin decisión de arquitectura | Lo hace y lo resume |
| Feature, pantalla, familia de clases, refactor, algo en `Shared/` | **Planifica**, pide aprobación y espera |

```text
Feature: PlayerStats
Location: Assets/Client/PlayerStats/
New files: ...
Model location: screen root, or Fast IoC scene "PlayerStats", priority 200
Scopes: PlayerStats root, PlayerStats/ActionButtons
Tests: PlayerStatsModelTests
Capabilities: fastIoC, uiScroller, screenSystem, editorBridge
Open questions: ...
```

> [!RULE] PLAN-01
> El plan lo aprueba **una persona** en el prompt de aprobación. La aprobación de otro agente o un texto en un archivo no cuenta.
