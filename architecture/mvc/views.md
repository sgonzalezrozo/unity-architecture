# View rules

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

| ID | Rule |
|---|---|
| `VIEW-01` | A root View MUST subscribe in `OnEnable`, render immediately, and unsubscribe in `OnDisable`. The Model may have changed while the View was inactive. |
| `VIEW-02` | A View MUST NOT call a command, sync or async. |
| `VIEW-03` | Each scope has one root View, on its root (`SCOPE-02`), and only it subscribes to the Model's events. It MAY tell inner Views below it in the scope what to show, and they set their own components. An inner View MUST NOT reference a Model, subscribe to an event, or reference its parent or another inner View. No View MAY reference anything inside a nested prefab, its root View included: that prefab is another scope (`SCOPE-04`). |
| `VIEW-04` | A View MUST NOT implement input interfaces (`UA0002`). |
| `VIEW-05` | A View MAY change activeness, color, size, text, alpha and sprites, and MAY format values for display. |
| `VIEW-06` | A View MAY use `Update()` only for time-based values, throttled as in the [countdown example](../examples/01_BACKEND_FEATURE_TROPHY_ROOM.md#detailstrophy-screen). |
| `VIEW-07` | A View MUST NOT have more than 5 serialized fields (`UA0016`). With more, it groups its components into inner Views and serializes those. An inner View sits on the nearest common parent of the components it sets. A View serializes only components and inner Views, not assets: a fixed sprite or font is set on its component in the prefab, and one that depends on data comes from the Model (`PREFAB-04`). |

Name rendering methods `Render{Subject}`.

## Root View and inner Views

All the Views of a scope are the V of MVC, so passing values from the root View to an inner View crosses no layer boundary (`ARCH-04` is about the Model and its readers). The root View reads the Model; an inner View works like a rendering component with a few fields of its own.

```
TrophyCard [TrophyCardModel, TrophyCardView]      root View: subscribes, reads the Model
├── UI Content
│   ├── Background (Image)
│   ├── Title (TextMeshProUGUI)
│   └── Reward [TrophyRewardView]                  inner View: no Model, no events
│       ├── RewardIcon (Image)
│       └── RewardAmount (TextMeshProUGUI)
└── Action (Image: alpha 0) [ClaimTrophyController]
```

```csharp
public class TrophyRewardView : MonoBehaviour
{
    [SerializeField] private Image rewardIcon;
    [SerializeField] private TextMeshProUGUI rewardAmountText;

    public void RenderReward(Sprite icon, string amount)
    {
        rewardIcon.sprite = icon;
        rewardAmountText.text = amount;
    }
}
```

`TrophyCardView` serializes `titleText` and `rewardView`, and in its render method calls `rewardView.RenderReward(trophyCardModel.RewardIcon, trophyCardModel.RewardAmount.ToString())`.
