# Nombres en C#

| Elemento | Estilo | Ejemplo |
|---|---|---|
| Clase, método, propiedad, enum | `PascalCase` | `TrophyRoomModule` |
| Campo, local, parámetro | `camelCase`, sin guion bajo | `selectedTrophyId` |
| Constante | `ALL_CAPS` | `MAX_LIVES` |
| Evento | `On` + pasado | `OnLivesChanged` |
| Método async | sufijo `Async` | `LoadAsync` |

Nombres completos y buscables: sin abreviaturas ni letras sueltas (salvo contadores de bucle).

## Prefijos de métodos

| Prefijo | Intención |
|---|---|
| `Get` | Query |
| `Set` | Asigna |
| `Is` / `Has` / `Can` | Query booleana |
| `Try` | Puede fallar, devuelve `bool` |
| `Calculate` | Calcula |
| `Render` | La View pinta estado del Model |
| `On` | Manejador de evento |
| `Validate` | Lanza si es inválido |
