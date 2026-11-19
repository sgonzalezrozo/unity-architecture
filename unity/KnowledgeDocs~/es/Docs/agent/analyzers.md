# Analyzers: reglas que fallan el build

Una instrucción es una petición, no una garantía. Estos analyzers Roslyn convierten las reglas mecánicas en **errores de compilación**, lo escriba una persona o un agente.

> [!NOTE] Opcionales
> Solo se instalan con `bash .ai/templates/scripts/install.sh --analyzers`. Sin ellos, las reglas siguen aplicando y se revisan en review. Un agente nunca escribe analyzers nuevos en una tarea de feature (`SCOPE-03`).

| Regla | Falla cuando |
|---|---|
| `UA0001` | Una capa conoce a otra que no debe |
| `UA0002` | Una View implementa una interfaz de input |
| `UA0003` | Un Controller serializa un objeto de Unity |
| `UA0004` | Un evento tiene parámetros |
| `UA0005` | Se usa `Button`, `Toggle`, `Slider`, `Dropdown`... |
| `UA0006` | Un MonoBehaviour tiene `Initialize` con parámetros |
| `UA0007` | `[Inject]` con Fast IoC |
| `UA0008` | Campo de MonoBehaviour que no es `private`/`internal` |
| `UA0009` | Lambda o método anónimo |
| `UA0010` | LINQ |
| `UA0011` | `var` |
| `UA0012` | `?.` sobre un objeto de Unity |
| `UA0013` | Un Model con campo serializado |
| `UA0014` | Ciclo entre Models |
| `UA0015` | `///` en un miembro |
| `UA0016` | View con más de 5 campos serializados |

> [!NOTE]
> Solo analizan el assembly **`Client`** (`Assets/Client`). Los tests y el código de terceros quedan fuera.
