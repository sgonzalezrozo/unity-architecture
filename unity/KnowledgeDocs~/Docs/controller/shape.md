# The shape of a Controller

Turns **one input** into **one command**.

<!-- if: com.sgonzalezrozo.ui-foundations -->
> [!IMPORTANT] With UI Foundations
> This project has UI Foundations: click Controllers derive from `BaseClickController` and override `OnClick()` (`OPT-02`). See [UI Foundations: click Controller](doc:pkg.foundations.click).

<!-- endif -->
```csharp
public class LoseLifeController : MonoBehaviour, IPointerClickHandler
{
    private LivesModel livesModel;

    private void Awake()
    {
        livesModel = GetComponentInParent<LivesModel>();
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        livesModel.LoseLife();
    }
}
```

> [!RULE] CTRL-01
> One action per Controller, on the element it acts on. It's named `{Action}Controller`.

> [!RULE] CTRL-02
> One command per input. If a click does two things, that's **one** command on a Model.

> [!RULE] CTRL-05
> No serialized references to Unity objects (`UA0003`). A config value (an enum for which tab it opens) is fine.

**See also:** [A Controller doesn't decide](doc:controller.no_decisions) · [The Action object](doc:controller.action) · [Drag](doc:controller.drag) · [The Model](doc:model.what_is_a_model)
