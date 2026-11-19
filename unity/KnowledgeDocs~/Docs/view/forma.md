# La forma de una View

Lee Models y pinta. Siempre tiene esta misma forma:

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
> Se suscribe en `OnEnable`, **pinta enseguida** (el Model pudo cambiar mientras estaba inactiva) y se desuscribe en `OnDisable`.

Los métodos de pintado se llaman `Render{Algo}`.

**Ver también:** [Qué puede y qué no](doc:view.que_puede) · [Inner Views](doc:view.inner_views) · [El Model](doc:model.que_es) · [El Controller](doc:controller.forma)
