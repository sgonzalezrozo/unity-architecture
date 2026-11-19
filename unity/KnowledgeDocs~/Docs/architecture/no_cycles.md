# Models never form a cycle

> [!RULE] ARCH-09
> If two Models need each other, what they share moves to a **new Model** that needs neither. A shared Model never references a feature's Model.

```flow
ShopModel -> WalletModel:red -> ShopModel
ShopModel -> CoinBalanceModel:green
WalletModel -> CoinBalanceModel:green
```

The first row is a cycle (wrong). The other two both depend on a third Model (right).

> [!NOTE]
> Analyzer `UA0014` catches cycles at compile time.
