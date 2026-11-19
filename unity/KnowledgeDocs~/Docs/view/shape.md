# The shape of a View

Reads Models and renders. Always this same shape:

```csharp
public class LivesView : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI remainingLivesText;

    private LivesModel livesModel;

    private void Awake()
    {
        livesModel = GetComponentInParent<LivesModel>();
    }

    private void OnEnable()
    {
        livesModel.OnLivesChanged += RenderRemainingLives;
        RenderRemainingLives();
    }

    private void OnDisable()
    {
        livesModel.OnLivesChanged -= RenderRemainingLives;
    }

    private void RenderRemainingLives()
    {
        remainingLivesText.text = livesModel.RemainingLives.ToString();
    }
}
```

> [!RULE] VIEW-01
> Subscribe in `OnEnable`, **render right away** (the Model may have changed while the View was inactive), and unsubscribe in `OnDisable`.

Rendering methods are named `Render{Subject}`.

**See also:** [What a View can do](doc:view.allowed) · [Inner Views](doc:view.inner_views) · [The Model](doc:model.what_is_a_model) · [The Controller](doc:controller.shape)
