# Analyzers: rules that fail the build

An instruction is a request, not a guarantee. These Roslyn analyzers turn the mechanical rules into **compile errors**, whether a person or an agent wrote the code.

> [!NOTE] Optional
> They're installed only with `bash .ai/templates/scripts/install.sh --analyzers`. Without them, the rules still apply and review checks them. An agent never writes new analyzers on a feature task (`TASK-03`).

| Rule | Fails when |
|---|---|
| `UA0001` | A layer knows one it shouldn't |
| `UA0002` | A View implements an input interface |
| `UA0003` | A Controller serializes a Unity object |
| `UA0004` | An event has parameters |
| `UA0005` | `Button`, `Toggle`, `Slider`, `Dropdown`... is used |
| `UA0006` | A MonoBehaviour has `Initialize` with parameters |
| `UA0007` | `[Inject]` with Fast IoC |
| `UA0008` | A MonoBehaviour field isn't `private`/`internal` |
| `UA0009` | A lambda or anonymous method |
| `UA0010` | LINQ |
| `UA0011` | `var` |
| `UA0012` | `?.` on a Unity object |
| `UA0013` | A Model with a serialized field |
| `UA0014` | A cycle between Models |
| `UA0015` | `///` on a member |
| `UA0016` | A View with more than 5 serialized fields |

> [!NOTE]
> They only analyze the **`Client`** assembly (`Assets/Client`). Tests and third-party code are left out.
