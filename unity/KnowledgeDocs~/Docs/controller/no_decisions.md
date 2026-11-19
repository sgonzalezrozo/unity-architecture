# A Controller doesn't decide

> [!RULE] CTRL-03
> A Controller **doesn't check state** or hold rules.

> [!DONT]
> ```csharp
> public void OnPointerClick(PointerEventData eventData)
> {
>     if (storeModel.State == PurchaseState.Available)
>         storeModel.Buy();
> }
> ```

> [!DO]
> ```csharp
> public void OnPointerClick(PointerEventData eventData)
> {
>     storeModel.Buy();   // Buy() validates itself
> }
> ```

> [!RULE] CTRL-06
> A screen being shown is input too: a Controller may start work from `OnScreenShown()` (or `OnEnable` without Screen System).
