# Model events

> [!RULE] MODEL-05
> Always `public event Action OnSomethingChanged;`, in the past tense.

> [!RULE] MODEL-04
> Commands may take parameters. Events **never** do (`UA0004`).

> [!RULE] MODEL-06
> Fire the event **only when state changed**.

> [!RULE] MODEL-07
> A Model may subscribe to another with a **named method**, and unsubscribes in `OnDestroy()` (MonoBehaviour) or `Dispose()` (pure C#).

| Wrong | Right |
|---|---|
| `event Action<int> OnScoreChanged` | `event Action OnScoreChanged` |
| `public Action OnChanged { get; set; }` | `public event Action OnChanged;` |
| `OnChanged += () => Render();` | `OnChanged += Render;` |
