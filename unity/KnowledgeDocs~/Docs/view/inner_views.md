# Root View and inner Views

> [!RULE] VIEW-03
> Each scope has **one root View**, on its root, and only it subscribes to the Model. It may tell its inner Views what to show. An inner View doesn't know the Model, doesn't subscribe, and doesn't know other Views.

> [!RULE] VIEW-07
> At most **5 serialized fields** per View (`UA0016`). With more, group components into inner Views. Serialize only components and inner Views, never assets.

```text
TrophyCard [TrophyCardModel, TrophyCardView]      root: subscribes, reads the Model
├── UI Content
│   ├── Title (TextMeshProUGUI)
│   └── Reward [TrophyRewardView]                  inner: no Model, no events
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

> [!CAUTION]
> No View touches anything **inside a nested prefab**, not even its root View: it's another scope.
