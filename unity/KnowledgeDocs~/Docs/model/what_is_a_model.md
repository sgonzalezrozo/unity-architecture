# What a Model is

Owns state, applies rules and announces changes. Knows nothing about Unity UI.

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

- A MonoBehaviour Model lives on its scope root (see [Where a Model lives](doc:scopes.where_a_model_lives)).
- One responsibility. More than about **5 commands** signals a split (`MODEL-08`).
- Initial state goes in **field initializers**: a View's `OnEnable` can run before the Model's `Awake` (`ROOT-03`).

> [!TIP]
> Test it in EditMode with `new GameObject().AddComponent<LivesModel>()` (`ROOT-05`).

**See also:** [Commands and queries](doc:model.commands_and_queries) · [Events](doc:model.events) · [Configuration](doc:model.configuration) · [The View](doc:view.shape)
