# Qué se testea

| ID | Regla |
|---|---|
| `TEST-01` | Todo lo testeable tiene test: Models, Modules, clases C# puras, conversiones y cálculos |
| `TEST-02` | Camino feliz, casos límite y errores |
| `TEST-03` | La lógica que no se puede testear donde está se mueve (normalmente a un Model) |
| `TEST-06` | Views y Controllers no tienen lógica: van a QA manual. Si uno necesita test, hay lógica mal puesta |

> [!RULE] TEST-08
> El test de comportamiento de un Model se escribe **primero**, y falla antes de que exista el código.

> [!RULE] TEST-04
> Un bug fix incluye un test que **falla sin el fix**.
