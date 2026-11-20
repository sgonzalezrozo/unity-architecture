# Controller rules

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

| ID | Rule |
|---|---|
| `CTRL-01` | A Controller MUST handle one action and sit on the element it acts on. |
| `CTRL-02` | A Controller MUST call one command per input. If a click does two things, that is one command on a Model. |
| `CTRL-03` | A Controller MUST NOT check state or hold a rule. |
| `CTRL-04` | A Controller MAY convert raw input to a domain value, such as a pointer position to 0 to 1. |
| `CTRL-05` | A Controller MUST NOT serialize a reference to a Unity object (`UA0003`). |
| `CTRL-06` | A screen lifecycle event is input. A Controller MAY start work from it. Which events these are depends on the `navigation` fork below. |

Click Controllers on an `Action`: [Clicks and input](../ui/clicks.md).

> **Fork `navigation`** · which events show and hide a screen. Open only the branch the [profile](../OPTIONAL_PACKAGES.md#the-profile) names:
> - `screen-system`: [Screen System: navigation](../branches/screen-system/navigation.md)
> - `no-screen-system`: [Navigation without Screen System](../branches/no-screen-system/navigation.md)
