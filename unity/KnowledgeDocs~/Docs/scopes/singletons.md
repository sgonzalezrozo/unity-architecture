# Singletons without a container

> [!RULE] ROOT-07
> Without a DI container, a row 2 or 3 Model is a **pure C# singleton with a public constructor**. Views and Controllers cache `TModel.Instance` in `Awake`. With a container, singletons **aren't** used.

```csharp
public class CoinBalanceModel
{
    public static CoinBalanceModel Instance { get; } = new CoinBalanceModel();
}
```

> [!RULE] ROOT-09
> A test creates **its own instance** and never uses `TModel.Instance`: static state carries over between tests.
