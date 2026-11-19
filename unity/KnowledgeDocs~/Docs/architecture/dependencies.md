# Who knows whom

> [!RULE] ARCH-01
> Dependencies go **one way**. Views and Controllers never reference each other.

| | Models | Rendering | Input | Views | Controllers |
|---|:---:|:---:|:---:|:---:|:---:|
| **Model** | <color=#3FB950>Yes</color> | <color=#F85149>No</color> | <color=#F85149>No</color> | <color=#F85149>No</color> | <color=#F85149>No</color> |
| **View** | <color=#3FB950>Yes</color> | <color=#3FB950>Yes</color> | <color=#F85149>No</color> | Inner only | <color=#F85149>No</color> |
| **Controller** | <color=#3FB950>Yes</color> | <color=#F85149>No</color> | <color=#3FB950>Yes</color> | <color=#F85149>No</color> | <color=#F85149>No</color> |

- *Rendering* = `Image`, `TextMeshProUGUI`... *Input* = `IPointer*`, `IDrag*`.
- A Model may also reference **configuration assets**.
- Exception: a feature's **Module** also knows its **Connector**.

> [!CAUTION] The compiler checks it
> Analyzer `UA0001` fails the build when a layer knows one it shouldn't.

**See also:** [The backend pieces](doc:backend.pieces) · [Models never form a cycle](doc:architecture.no_cycles)
