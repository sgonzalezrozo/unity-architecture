# No Button, Toggle or Slider

> [!RULE] ARCH-05
> `Selectable` components (`Button`, `Toggle`, `Slider`, `Dropdown`) combine View and Controller. They aren't used. Controllers implement `IPointer*` / `IDrag*`.

| Don't use | Use |
|---|---|
<!-- if: com.sgonzalezrozo.ui-foundations -->
| `Button` | A Controller that derives from `BaseClickController` |
<!-- else -->
| `Button` | A graphic plus a click Controller |
<!-- endif -->
| `Toggle` | A View with On and Off roots, plus a click Controller |
| `Slider` | An `Image` fill plus a Controller with `IPointerDownHandler` and `IDragHandler` |
| `Dropdown` | A modal with a list |
| `TMP_InputField` | <color=#3FB950>Allowed</color>: the one exception |

> [!CAUTION]
> No `onClick`, persistent `UnityEvent` or `EventTrigger` either. Analyzer `UA0005` catches them.

**See also:** [The Action object](doc:controller.action) · [Settings example](doc:examples.settings)
