# Screen System: modals and alerts

> [!RULE] SCR-09
> **One modal open at a time**: close it before opening another. An alert opens over everything, blocks navigation and Escape, and closes only with `DismissAlert()`.

For an answer (confirmation, picker):

```csharp
ModalResult<bool> result = await screens.GoToForResult<bool>(ScreenIds.ConfirmPurchase);

if (result.Returned && result.Value)
    shopModel.Buy();
```

The modal answers with `CloseWithResult(value)`. Check `Returned` before `Value`: going back gives `Dismissed`.

> [!RULE] SCR-14
> The splash and the quit confirmation are the screens the `ScreenManager` names. The quit modal's buttons call `QuitConfirmationLayer.Quit` / `Cancel`; feature code **never** calls `Application.Quit`.
