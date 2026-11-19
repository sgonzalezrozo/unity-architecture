# C# naming

| Element | Style | Example |
|---|---|---|
| Class, method, property, enum | `PascalCase` | `TrophyRoomModule` |
| Field, local, parameter | `camelCase`, no underscore | `selectedTrophyId` |
| Constant | `ALL_CAPS` | `MAX_LIVES` |
| Event | `On` + past tense | `OnLivesChanged` |
| Async method | `Async` suffix | `LoadAsync` |

Full, searchable words: no abbreviations or single letters (except loop counters).

## Method prefixes

| Prefix | Intent |
|---|---|
| `Get` | Query |
| `Set` | Assign |
| `Is` / `Has` / `Can` | Boolean query |
| `Try` | May fail, returns `bool` |
| `Calculate` | Computes |
| `Render` | A View draws Model state |
| `On` | Event handler |
| `Validate` | Throws if invalid |
