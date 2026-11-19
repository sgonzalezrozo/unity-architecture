# Singletons sin contenedor

> [!RULE] ROOT-07
> Sin contenedor de inyección, un Model de las filas 2 o 3 es un **singleton C# puro con constructor público**. Views y Controllers cachean `TModel.Instance` en `Awake`. Con contenedor, **no** se usan singletons.

```csharp
public class CoinBalanceModel
{
    public static CoinBalanceModel Instance { get; } = new CoinBalanceModel();
}
```

> [!RULE] ROOT-09
> Un test crea **su propia instancia** y nunca usa `TModel.Instance`: el estado estático pasa de un test a otro.
