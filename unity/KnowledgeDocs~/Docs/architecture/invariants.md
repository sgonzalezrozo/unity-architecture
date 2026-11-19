# The 11 architecture rules

Code that breaks one of these **is wrong even if it compiles and runs**.

| ID | In one sentence |
|---|---|
| `ARCH-01` | Dependencies go one way: Views and Controllers know Models; Models know only Models |
| `ARCH-02` | All state lives in Models |
| `ARCH-03` | Views render, Controllers receive input |
| `ARCH-04` | Pull, never push: events have no parameters |
| `ARCH-05` | No `Button`, `Toggle`, `Slider` or `Dropdown` |
| `ARCH-06` | Code and its prefabs share a folder; source art doesn't |
| `ARCH-07` | Anything that can be deterministic is |
| `ARCH-08` | Anything testable is testable, and has tests when the scope includes them |
| `ARCH-09` | Models never form a cycle |
| `ARCH-10` | No abstraction without a second use |
| `ARCH-11` | Do the minimum; what isn't used costs nothing |

> [!TIP]
> Click an ID to open its doc with examples.
