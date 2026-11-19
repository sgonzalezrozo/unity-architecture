# Screen System: modales y alerts

> [!RULE] SCR-09
> **Un modal abierto a la vez**: ciérralo antes de abrir otro. Un alert va sobre todo, bloquea la navegación y Escape, y solo se cierra con `DismissAlert()`.

Para una respuesta (confirmación, selector):

```csharp
ModalResult<bool> result = await screens.GoToForResult<bool>(ScreenIds.ConfirmPurchase);

if (result.Returned && result.Value)
    shopModel.Buy();
```

El modal responde con `CloseWithResult(value)`. Comprueba `Returned` antes de `Value`: volver atrás da `Dismissed`.

> [!RULE] SCR-14
> Splash y confirmación de salida son las pantallas que nombra el `ScreenManager`. Los botones del modal de salida llaman `QuitConfirmationLayer.Quit` / `Cancel`; el código de feature **nunca** llama `Application.Quit`.
