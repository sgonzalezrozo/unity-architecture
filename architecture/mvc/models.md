# Model rules

```csharp
public class LivesModel : MonoBehaviour
{
    private const int MAX_LIVES = 3;

    public event Action OnLivesChanged;

    private int remainingLives = MAX_LIVES;

    public int RemainingLives => remainingLives;
    public bool IsAlive => remainingLives > 0;

    public void LoseLife()
    {
        if (!IsAlive)
            return;

        remainingLives--;
        OnLivesChanged?.Invoke();
    }
}
```

| ID | Rule |
|---|---|
| `MODEL-01` | A Model MUST live where [Where a Model lives](where-a-model-lives.md#where-a-model-lives) says. |
| `MODEL-02` | A method MUST be a query or a command, not both. `Try*` is the accepted exception. A query MUST NOT change state, lazy initialization included: building a source the first time a View asks for it is a command hidden in a query. |
| `MODEL-03` | A command MUST validate its input. A condition the player can reach, such as too few coins, is ignored or returns a state. A condition only a bug can reach, such as an unknown ID, throws. Business rules MUST NOT live in a Controller. |
| `MODEL-04` | Commands MAY take parameters. Events MUST NOT (`UA0004`). |
| `MODEL-05` | Events MUST use `public event Action OnSomethingChanged;`, in the past tense. |
| `MODEL-06` | A Model MUST fire an event only when state changed. |
| `MODEL-07` | A Model MAY subscribe to another Model. It MUST use a named method and unsubscribe in `OnDestroy()` on a MonoBehaviour, or `Dispose()` in pure C#. |
| `MODEL-08` | A Model SHOULD have one responsibility. More than about 5 commands signals a split. |
| `MODEL-09` | A Model MUST NOT have serialized fields (`UA0013`). |
| `MODEL-10` | A value set outside code MUST come from an injected configuration asset or from backend JSON. Everything else is a constant. Without a container, load the asset by address or path. |
| `MODEL-11` | A Model MUST finish changing state before it fires an event. A subscriber MUST NOT call a command on the Model that fired the event. |
| `MODEL-12` | Data a feature shows comes from one of two places, never from constants inside a Model or View. **Runtime data** (what the player owns or a server returns: an inventory, a store's offers, a friends list) comes from the backend's Module; while the request names no backend, it comes from `Services/Mock{Feature}Items.cs`, a pure C# class whose constructor builds the sample items, bound in the installer, so a Module replaces it later without touching the Models. **Configuration** the request calls tunable by a designer (prices, tables, layout values) comes from a configuration asset built from its spec (`EDIT-14`). When the request doesn't say, it's runtime data. |
| `MODEL-13` | The data a feature lists is owned by a pure C# Model created by the container, `{Feature}ItemsModel`, which builds its sources in its constructor from the Module or the mock (`MODEL-12`). The screen's MonoBehaviour Model receives it injected and only reads it, so its queries change nothing (`MODEL-02`) and a View that reads it in `OnEnable` never triggers a build. |
