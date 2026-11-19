# Un Controller no decide

> [!RULE] CTRL-03
> Un Controller **no comprueba estado** ni guarda reglas.

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
>     storeModel.Buy();   // Buy() se valida solo
> }
> ```

> [!RULE] CTRL-06
> Que una pantalla se muestre también es input: un Controller puede arrancar trabajo desde `OnScreenShown()` (o `OnEnable` sin Screen System).
