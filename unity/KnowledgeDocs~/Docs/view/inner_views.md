# View raíz e inner Views

> [!RULE] VIEW-03
> Cada scope tiene **una View raíz**, en su raíz, y solo ella se suscribe al Model. Puede decir a sus inner Views qué mostrar. Una inner View no conoce el Model, no se suscribe y no conoce a otras Views.

> [!RULE] VIEW-07
> Máximo **5 campos serializados** por View (`UA0016`). Con más, agrupa componentes en inner Views. Solo serializa componentes e inner Views, nunca assets.

```text
TrophyCard [TrophyCardModel, TrophyCardView]      raíz: se suscribe y lee el Model
├── UI Content
│   ├── Title (TextMeshProUGUI)
│   └── Reward [TrophyRewardView]                  inner: sin Model, sin eventos
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
> Ninguna View toca nada **dentro de un prefab anidado**, ni su View raíz: es otro scope.
