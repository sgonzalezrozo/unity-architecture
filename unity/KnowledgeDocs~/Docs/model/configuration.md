# Model configuration

> [!RULE] MODEL-09
> A Model has **no serialized fields** (`UA0013`).

> [!RULE] MODEL-10
> A value set outside code comes from an injected **configuration asset** (`ScriptableObject`) or from backend JSON. Everything else is a constant.

| Value | Where it goes |
|---|---|
| A fixed maximum of lives | `private const int MAX_LIVES = 3;` |
| Prices that design tunes | An injected `ScriptableObject` |
| Prices from the server | Backend JSON |

> [!NOTE]
> Without a container, load the asset by address or path (Addressables or `Resources`).
