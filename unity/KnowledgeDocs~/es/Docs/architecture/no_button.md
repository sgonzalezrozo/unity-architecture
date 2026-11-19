# Nada de Button, Toggle ni Slider

> [!RULE] ARCH-05
> Los `Selectable` (`Button`, `Toggle`, `Slider`, `Dropdown`) mezclan View y Controller. No se usan. Los Controllers implementan `IPointer*` / `IDrag*`.

| No uses | Usa |
|---|---|
<!-- if: com.sgonzalezrozo.ui-foundations -->
| `Button` | Un Controller que deriva de `BaseClickController` |
<!-- else -->
| `Button` | Un gráfico + un Controller de click |
<!-- endif -->
| `Toggle` | View con raíces On/Off + Controller de click |
| `Slider` | `Image` con fill + Controller con `IPointerDownHandler` y `IDragHandler` |
| `Dropdown` | Un modal con una lista |
| `TMP_InputField` | <color=#3FB950>Permitido</color>: la única excepción |

> [!CAUTION]
> Tampoco `onClick`, `UnityEvent` persistentes ni `EventTrigger`. El analyzer `UA0005` lo detecta.

> [!TIP]
> Mira el ejemplo **Settings** para un Toggle y un Slider hechos a mano.

**Ver también:** [El objeto Action](doc:controller.action) · [Ejemplo Settings](doc:examples.settings)
