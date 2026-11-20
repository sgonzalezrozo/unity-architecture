# No container: singletons

Branch `no-container` of the `container` fork. Read it only when the [profile](../../OPTIONAL_PACKAGES.md#the-profile) says `container: no-container`.

A Model in row 2 or 3 of [Where a Model lives](../../mvc/where-a-model-lives.md) is a pure C# singleton with a public constructor (`ROOT-07`):

```csharp
public class CoinBalanceModel
{
    public static CoinBalanceModel Instance { get; } = new CoinBalanceModel();
}
```

Views and Controllers cache it in `Awake`:

```csharp
private CoinBalanceModel coinBalanceModel;

private void Awake()
{
    coinBalanceModel = CoinBalanceModel.Instance;
}
```

- A test creates its own instance with the public constructor and never uses `Instance` (`ROOT-09`).
- A configuration asset for a Model is loaded by address or path (`MODEL-10`): through Addressables with `addressables`, otherwise from `Resources`.
- A Model in row 1 (common parent) never becomes a singleton (`ROOT-02`).
- Features have no installer.
