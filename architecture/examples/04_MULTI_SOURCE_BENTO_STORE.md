# Example: multi-source bento store with a popup (Store)

**Load when:** a list shows several sources (sections), a bento layout, runtime data without a backend, a countdown, or a click that opens a popup with what was clicked.

**Request:** a Store with three independent sources in one vertical bento list: discounts (a reduced price and an expiry countdown), promotions (featured banners) and packs (bundles). A click on a promotion opens a popup with its details, a claim button and a close button that returns to the Store. Scope: code only. Test scope: `Assets/Client/Store`.

Capability profile: `fastIoC`, `uiScroller`, `screenSystem` and `uiFoundations` are `true`. Every file name starts with `Store` (`TASK-05`), every file is a row of the Feature files table (`CHK-14`), and `scripts/check-feature.sh Store` passes.

**Demonstrates:** `SectionedSource` with one section per source (`LIST-10`), a bento layout in JSON (`LIST-08`), runtime data from a mock behind a pure C# items Model (`MODEL-12`, `MODEL-13`), a clock behind an interface for the countdown (`DET-06`), a throttled countdown in a slot View (`VIEW-06`), navigation as a command on the root Model (`SCR-16`), a popup that receives its ID (`IScreenParameter<T>`), and the handoff (`HAND-07`).

## The plan (`Logs/ai/plan.md`)

```
Feature: Store
Folder: Assets/Client/Store
Scope: code                                                        # TASK-01 (the user chose code only)
Test scope: Assets/Client/Store                                    # TEST-13
Decisions:
  model-location: screen-root                                      # StoreModel on the Store screen root; the popup has its own
  data: mock                                                       # MODEL-12: runtime data, no backend named
  installer: yes                                                   # DI-11: clock, mock and items Model
  list: sectioned                                                  # LIST-10: three sources, one section each
  layout: bento                                                    # the request
  input: OpenPromotionController, ClaimPromotionController, ClosePromotionController
  backend: none
  localization: none                                               # project facts: not configured and used
  outside-feature: none
Files:
  StoreMain/StoreModel.cs                                          # root Model: reads the items Model, opens the popup
  StoreMain/StoreListView.cs                                       # root View of the list
  StoreMain/StoreScroller.cs
  StoreMain/StoreItemData.cs
  StoreMain/StoreSectionData.cs
  StoreMain/StoreSlotModel.cs
  StoreMain/StoreSlotView.cs
  StoreMain/StorePriceView.cs                                      # inner View of the slot (VIEW-07)
  StoreMain/StoreHeaderSlotModel.cs
  StoreMain/StoreHeaderSlotView.cs
  StoreMain/OpenPromotionController.cs
  StoreMain/StoreBentoLayout.json
  StorePromotionPopup/StorePromotionPopupModel.cs                  # the popup's root Model
  StorePromotionPopup/StorePromotionPopupView.cs
  StorePromotionPopup/ClaimPromotionController.cs
  StorePromotionPopup/ClosePromotionController.cs
  Services/StoreItemsModel.cs
  Services/MockStoreItems.cs
  Services/IStoreClock.cs
  Services/StoreSystemClock.cs
  Services/StoreInstaller.cs
  IMPLEMENTATION.md
Open questions:
  none: the user created the StorePromotionPopup screen (Modal) before the task, so ScreenIds.StorePromotionPopup exists
Notes:
  UI Scroller uses one bento layout for the whole list and starts it again in every section, so the banners can't
  be full width only in Promotions: every section starts with one full-width featured tile, then a 2-column grid.
```

The scope is code only, so there's no `Tests/` folder: the report lists the tests that would cover `StoreItemsModel` (`TASK-02`). The tests at the end are what a scope with tests adds.

## Files

```
Assets/Client/Store/
├── StoreMain/                    the Store screen
├── StorePromotionPopup/          the popup, a Modal screen
├── Services/                     clock, mock, items Model, installer
└── IMPLEMENTATION.md
```

## Services

The clock is an interface only because a test sets the time (`ARCH-10`, `DET-06`).

```csharp
namespace Client.Store
{
    public interface IStoreClock
    {
        long UtcNowUnixSeconds { get; }
    }
}

namespace Client.Store
{
    public class StoreSystemClock : IStoreClock
    {
        public long UtcNowUnixSeconds => System.DateTimeOffset.UtcNow.ToUnixTimeSeconds();
    }
}
```

The mock stands in for the backend: its constructor builds the sample items, in English (`DATA-01`). A Module replaces it later without touching the Models.

```csharp
using System.Collections.Generic;

namespace Client.Store
{
    public class MockStoreItems
    {
        private const long ONE_HOUR_SECONDS = 3600;

        public MockStoreItems()
        {
            PromotionsTitle = "Promotions";
            DiscountsTitle = "Discounts";
            PacksTitle = "Packs";
            Promotions = new List<StoreItemData>
            {
                new() { id = 1, title = "Winter Festival", description = "Three chests and a skin.", price = 9.99f },
                new() { id = 2, title = "Starter Bundle", description = "Gems and gold to begin.", price = 4.99f }
            };
            Discounts = new List<StoreItemData>
            {
                new() { id = 10, title = "Iron Sword", price = 2.99f, originalPrice = 4.99f, expiresInSeconds = ONE_HOUR_SECONDS },
                new() { id = 11, title = "Tower Shield", price = 3.49f, originalPrice = 5.99f, expiresInSeconds = 2 * ONE_HOUR_SECONDS }
            };
            Packs = new List<StoreItemData>
            {
                new() { id = 20, title = "500 Gems", price = 4.99f },
                new() { id = 21, title = "Gold Chest", price = 1.99f }
            };
        }

        public string PromotionsTitle { get; }
        public string DiscountsTitle { get; }
        public string PacksTitle { get; }
        public IReadOnlyList<StoreItemData> Promotions { get; }
        public IReadOnlyList<StoreItemData> Discounts { get; }
        public IReadOnlyList<StoreItemData> Packs { get; }
    }
}
```

The items Model owns the sources and builds them in its constructor, so its queries change nothing (`MODEL-02`, `MODEL-13`). The section order is the order on screen, and the section titles come from the data, like every text the player sees (`MODEL-12`).

```csharp
using System;
using System.Collections.Generic;
using UIScroller;

namespace Client.Store
{
    public class StoreItemsModel
    {
        public event Action OnItemsChanged;

        private readonly SectionedSource<StoreItemData, StoreSectionData> sections = new();
        private readonly List<StoreItemData> allItems = new();
        private readonly IStoreClock clock;

        public StoreItemsModel(MockStoreItems mockStoreItems, IStoreClock clock)
        {
            this.clock = clock;
            AddSection(mockStoreItems.PromotionsTitle, mockStoreItems.Promotions, true);
            AddSection(mockStoreItems.DiscountsTitle, mockStoreItems.Discounts, false);
            AddSection(mockStoreItems.PacksTitle, mockStoreItems.Packs, false);
        }

        public SectionedSource<StoreItemData, StoreSectionData> Sections => sections;

        public StoreItemData FindItem(int itemId)
        {
            for (int i = 0; i < allItems.Count; i++)
            {
                if (allItems[i].id == itemId)
                    return allItems[i];
            }

            return null;
        }

        public long GetSecondsRemaining(StoreItemData item)
        {
            if (item.expiresAtUnixSeconds == 0)
                return 0;

            return Math.Max(0, item.expiresAtUnixSeconds - clock.UtcNowUnixSeconds);
        }

        public void ClaimPromotion(int itemId)
        {
            StoreItemData item = FindItem(itemId) ?? throw new ArgumentException($"Unknown store item {itemId}");
            if (!item.isPromotion || item.isClaimed)
                return;

            item.isClaimed = true;
            OnItemsChanged?.Invoke();
        }

        private void AddSection(string title, IReadOnlyList<StoreItemData> items, bool isPromotion)
        {
            List<StoreItemData> sectionItems = new();
            foreach (StoreItemData item in items)
            {
                item.isPromotion = isPromotion;
                if (item.expiresInSeconds > 0)
                    item.expiresAtUnixSeconds = clock.UtcNowUnixSeconds + item.expiresInSeconds;
                sectionItems.Add(item);
                allItems.Add(item);
            }

            sections.AddSection(new StoreSectionData { title = title }, new ListSource<StoreItemData>(sectionItems));
        }
    }
}
```

`ClaimPromotion` validates itself, so the Controller checks nothing (`CTRL-03`, `MODEL-03`). Claiming without a backend only marks the item; a Module adds the purchase later.

```csharp
using FastIoC.API;

namespace Client.Store
{
    [MonoInstaller("Frontend", Priority = 200)]
    public class StoreInstaller : BindingRecorder
    {
        public override void InstallBindings()
        {
            Bind<IStoreClock>().To<StoreSystemClock>().AsSingle();
            Bind<MockStoreItems>().AsSingle();
            Bind<StoreItemsModel>().AsSingle();
        }
    }
}
```

The scene name comes from the project facts (`Logs/ai/project-facts.md`), not a guess.

## Store screen

```
Store [StoreModel, StoreListView]
└── StoreScroller [StoreScroller]       Layout: Bento, Layout JSON StoreBentoLayout, Slot Prefab StoreSlot, Header Prefab StoreHeaderSlot

StoreSlot.prefab [StoreSlotModel, StoreSlotView]
├── UI Content
│   ├── TitleText (TextMeshProUGUI)
│   ├── Price [StorePriceView]
│   │   ├── PriceText (TextMeshProUGUI)
│   │   └── OriginalPriceRoot
│   │       └── OriginalPriceText (TextMeshProUGUI)
│   └── CountdownText (TextMeshProUGUI)
└── PromotionRoot
    └── Action [OpenPromotionController]

StoreHeaderSlot.prefab [StoreHeaderSlotModel, StoreHeaderSlotView]
└── UI Content
    └── TitleText (TextMeshProUGUI)
```

```csharp
using System;

namespace Client.Store
{
    [Serializable]
    public class StoreItemData
    {
        public int id;
        public string title;
        public string description;
        public float price;
        public float originalPrice;
        public long expiresInSeconds;
        public long expiresAtUnixSeconds;
        public bool isPromotion;
        public bool isClaimed;
    }

    [Serializable]
    public class StoreSectionData
    {
        public string title;
    }
}
```

Each type has its own file (`StoreItemData.cs`, `StoreSectionData.cs`). One item type serves the three sources: what a slot shows comes from the data (a countdown when it expires, an original price when it's discounted, the click when it's a promotion), so no enum of kinds is needed.

The root Model reads the injected items Model and holds the navigation command (`SCR-16`). The command is synchronous: the Controller never sees a `Task`.

```csharp
using System;
using ToolsCore;
using ScreenSystem;
using UIScroller;
using UnityEngine;

namespace Client.Store
{
    public class StoreModel : MonoBehaviour
    {
        public event Action OnItemsChanged
        {
            add { storeItemsModel.OnItemsChanged += value; }
            remove { storeItemsModel.OnItemsChanged -= value; }
        }

        internal StoreItemsModel storeItemsModel;

        public SectionedSource<StoreItemData, StoreSectionData> Sections => storeItemsModel.Sections;

        public void OpenPromotion(int promotionId)
        {
            ScreenManager.Instance.GoTo(ScreenIds.StorePromotionPopup, promotionId).Forget(nameof(StoreModel));
        }
    }
}
```

`Forget` is the Tools Core helper, `ToolsCore.TaskExtensions`, from the package every project installs ([async and errors](../csharp/async-and-errors.md)); a feature never writes its own (`CHK-17`). `ScreenIds.StorePromotionPopup` exists only once a person creates the popup screen ([Screen System authoring](../branches/screen-system/authoring.md)), so the plan asks for it first: navigating with a string instead fails `CHK-16`.

```csharp
using UnityEngine;

namespace Client.Store
{
    public class StoreListView : MonoBehaviour
    {
        [SerializeField] private StoreScroller storeScroller;

        private StoreModel storeModel;

        private void Awake()
        {
            storeModel = GetComponentInParent<StoreModel>();
        }

        private void OnEnable()
        {
            storeModel.OnItemsChanged += RenderItems;
            if (!storeScroller.IsInitialized)
                storeScroller.SetSource(storeModel.Sections);
            RenderItems();
        }

        private void OnDisable()
        {
            storeModel.OnItemsChanged -= RenderItems;
        }

        private void RenderItems()
        {
            storeScroller.Refresh();
        }
    }

    public class StoreScroller : SectionedScroller<StoreItemData, StoreSectionData>
    {
    }
}
```

The View reads the screen Model with `GetComponentInParent`, never the injected items Model (`ROOT-06`, `CHK-11`).

The slot Model gets the items Model through `IInjectableForChildren` (`LIST-01`) and exposes the values its Views draw (`LIST-05`).

```csharp
using System;
using FastIoC.Core;
using UIScroller;
using UnityEngine;

namespace Client.Store
{
    public class StoreSlotModel : MonoBehaviour, IInjectableForChildren, ISlot<StoreItemData>
    {
        public event Action OnItemDataChanged;

        internal StoreItemsModel storeItemsModel;

        private StoreItemData itemData;

        public float DefaultExtent => 0f;
        public bool IsPromotion => itemData != null && itemData.isPromotion && !itemData.isClaimed;
        public long SecondsRemaining => itemData == null ? 0 : storeItemsModel.GetSecondsRemaining(itemData);
        public int ItemId => itemData == null ? 0 : itemData.id;

        public StoreItemData Data
        {
            get => itemData;
            set
            {
                itemData = value;
                OnItemDataChanged?.Invoke();
            }
        }
    }
}
```

`DefaultExtent` doesn't matter in bento: the layout sizes every tile (`LIST-08`).

```csharp
using TMPro;
using UnityEngine;

namespace Client.Store
{
    public class StoreSlotView : MonoBehaviour
    {
        private const float COUNTDOWN_RENDER_INTERVAL_SECONDS = 1f;

        [SerializeField] private TextMeshProUGUI titleText;
        [SerializeField] private StorePriceView priceView;
        [SerializeField] private TextMeshProUGUI countdownText;
        [SerializeField] private GameObject promotionRoot;

        private StoreSlotModel storeSlotModel;
        private float nextCountdownRenderTime;

        private void Awake()
        {
            storeSlotModel = GetComponentInParent<StoreSlotModel>();
        }

        private void OnEnable()
        {
            storeSlotModel.OnItemDataChanged += RenderItem;
            RenderItem();
        }

        private void OnDisable()
        {
            storeSlotModel.OnItemDataChanged -= RenderItem;
        }

        private void Update()
        {
            if (Time.unscaledTime < nextCountdownRenderTime)
                return;

            nextCountdownRenderTime = Time.unscaledTime + COUNTDOWN_RENDER_INTERVAL_SECONDS;
            RenderCountdown();
        }

        private void RenderItem()
        {
            StoreItemData item = storeSlotModel.Data;
            if (item == null)
                return;

            titleText.text = item.title;
            priceView.RenderPrice(item.price, item.originalPrice);
            promotionRoot.SetActive(storeSlotModel.IsPromotion);
            RenderCountdown();
        }

        private void RenderCountdown()
        {
            long seconds = storeSlotModel.SecondsRemaining;
            countdownText.gameObject.SetActive(seconds > 0);
            countdownText.text = System.TimeSpan.FromSeconds(seconds).ToString(@"hh\:mm\:ss");
        }
    }
}
```

The slot redraws from the Data setter's event, since pooled slots stay active out of view (`LIST-02`); the countdown is throttled to once a second (`VIEW-06`).

```csharp
using TMPro;
using UnityEngine;

namespace Client.Store
{
    public class StorePriceView : MonoBehaviour
    {
        [SerializeField] private TextMeshProUGUI priceText;
        [SerializeField] private GameObject originalPriceRoot;
        [SerializeField] private TextMeshProUGUI originalPriceText;

        public void RenderPrice(float price, float originalPrice)
        {
            priceText.text = price.ToString("C", System.Globalization.CultureInfo.GetCultureInfo("en-US"));
            originalPriceRoot.SetActive(originalPrice > price);
            originalPriceText.text = originalPrice.ToString("C", System.Globalization.CultureInfo.GetCultureInfo("en-US"));
        }
    }
}
```

An inner View: no Model, no events, the root View tells it what to show (`VIEW-03`, `VIEW-07`).

```csharp
using UIFoundations;

namespace Client.Store
{
    public class OpenPromotionController : BaseClickController
    {
        private StoreModel storeModel;
        private StoreSlotModel storeSlotModel;

        private void Awake()
        {
            storeModel = GetComponentInParent<StoreModel>();
            storeSlotModel = GetComponentInParent<StoreSlotModel>();
        }

        protected override void OnClick()
        {
            storeModel.OpenPromotion(storeSlotModel.ItemId);
        }
    }
}
```

The Controller is only the user's trigger: one command on the root Model (`CTRL-02`, `SCR-16`). It sits under `PromotionRoot`, which the View shows only for an unclaimed promotion, so it checks nothing (`CTRL-03`).

`StoreHeaderSlotModel` and `StoreHeaderSlotView` are the item slot's pattern with `StoreSectionData` and one `TitleText`.

### `StoreBentoLayout.json`

Two columns. Every section starts with one full-width tile (the featured item), then a grid of 1x1 tiles; the layout starts again in each section.

```json
{
    "columns": 2,
    "repeatFrom": 1,
    "patterns": [
        { "rows": 1, "tiles": [ { "c": 0, "r": 0, "w": 2, "h": 1 } ] },
        { "rows": 1, "tiles": [ { "c": 0, "r": 0, "w": 1, "h": 1 }, { "c": 1, "r": 0, "w": 1, "h": 1 } ] }
    ]
}
```

## Promotion popup

A Modal screen. It receives the promotion's ID once, before it shows (`SCR-08`), and closes itself with a command on its own root Model (`SCR-16`).

```
StorePromotionPopup [StorePromotionPopupModel, StorePromotionPopupView]
├── UI Content
│   ├── TitleText (TextMeshProUGUI)
│   ├── DescriptionText (TextMeshProUGUI)
│   └── PriceText (TextMeshProUGUI)
├── Claim
│   ├── UI Content
│   └── Action [ClaimPromotionController]
└── Close
    ├── UI Content
    └── Action [ClosePromotionController]
```

```csharp
using System;
using ToolsCore;
using ScreenSystem;
using UnityEngine;

namespace Client.Store
{
    public class StorePromotionPopupModel : MonoBehaviour, IScreenParameter<int>
    {
        public event Action OnPromotionChanged;

        internal StoreItemsModel storeItemsModel;

        private int promotionId;

        public StoreItemData Promotion => storeItemsModel.FindItem(promotionId);

        public void OnScreenParameter(int value)
        {
            promotionId = value;
            OnPromotionChanged?.Invoke();
        }

        public void ClaimPromotion()
        {
            storeItemsModel.ClaimPromotion(promotionId);
            Close();
        }

        public void Close()
        {
            ScreenManager.Instance.GoBack().Forget(nameof(StorePromotionPopupModel));
        }
    }
}
```

The popup's root Model is the only class of the popup that calls `ScreenManager`. Claiming and closing is one command for one click (`CTRL-02`).

```csharp
using TMPro;
using UnityEngine;

namespace Client.Store
{
    public class StorePromotionPopupView : MonoBehaviour
    {
        [SerializeField] private TextMeshProUGUI titleText;
        [SerializeField] private TextMeshProUGUI descriptionText;
        [SerializeField] private TextMeshProUGUI priceText;

        private StorePromotionPopupModel popupModel;

        private void Awake()
        {
            popupModel = GetComponentInParent<StorePromotionPopupModel>();
        }

        private void OnEnable()
        {
            popupModel.OnPromotionChanged += RenderPromotion;
            RenderPromotion();
        }

        private void OnDisable()
        {
            popupModel.OnPromotionChanged -= RenderPromotion;
        }

        private void RenderPromotion()
        {
            StoreItemData promotion = popupModel.Promotion;
            if (promotion == null)
                return;

            titleText.text = promotion.title;
            descriptionText.text = promotion.description;
            priceText.text = promotion.price.ToString("C", System.Globalization.CultureInfo.GetCultureInfo("en-US"));
        }
    }
}
```

```csharp
using UIFoundations;

namespace Client.Store
{
    public class ClaimPromotionController : BaseClickController
    {
        private StorePromotionPopupModel popupModel;

        private void Awake()
        {
            popupModel = GetComponentInParent<StorePromotionPopupModel>();
        }

        protected override void OnClick()
        {
            popupModel.ClaimPromotion();
        }
    }

    public class ClosePromotionController : BaseClickController
    {
        private StorePromotionPopupModel popupModel;

        private void Awake()
        {
            popupModel = GetComponentInParent<StorePromotionPopupModel>();
        }

        protected override void OnClick()
        {
            popupModel.Close();
        }
    }
}
```

Each Controller has its own file.

## `IMPLEMENTATION.md`

The scope has no prefabs, so the Unity work goes to the handoff in the fixed sections (`HAND-07`): **Code** (one line per file above), **Prefabs** (the Store screen, `StoreSlot`, `StoreHeaderSlot` and `StorePromotionPopup` hierarchies above, with the handoff tables), **Inspector assignments** (the Scroller's Layout Bento, Layout JSON `StoreBentoLayout`, Slot Prefab and Header Prefab; each View's fields), **First run** (create the `StorePromotionPopup` screen as a **Modal** with Screen System authoring so `ScreenIds.StorePromotionPopup` exists; the installer runs in `Frontend`) and **Play mode check** (three sections with their headers, the countdown ticking, a promotion opening the popup with its title, Claim hiding its click, Close returning to the Store), reported as not verified.

## Tests (a scope with tests)

`Tests/Client.Store.Tests.asmdef` from the [template](../FEATURE_STRUCTURE.md#test-assembly), and the clock double as a private class inside the test file.

```csharp
using NUnit.Framework;

namespace Client.Store.Tests
{
    public class StoreItemsModelTests
    {
        private FakeClock clock;
        private StoreItemsModel storeItemsModel;

        [SetUp]
        public void SetUp()
        {
            clock = new FakeClock { UtcNowUnixSeconds = 1000 };
            storeItemsModel = new StoreItemsModel(new MockStoreItems(), clock);
        }

        [Test]
        public void Constructor_ThreeSources_OneSectionEach()
        {
            Assert.AreEqual(3, storeItemsModel.Sections.SectionCount);
        }

        [Test]
        public void GetSecondsRemaining_TimePasses_CountsDown()
        {
            StoreItemData sword = storeItemsModel.FindItem(10);

            clock.UtcNowUnixSeconds += 600;

            Assert.AreEqual(3000, storeItemsModel.GetSecondsRemaining(sword));
        }

        [Test]
        public void ClaimPromotion_UnknownItem_Throws()
        {
            Assert.Throws<System.ArgumentException>(() => storeItemsModel.ClaimPromotion(999));
        }

        private class FakeClock : IStoreClock
        {
            public long UtcNowUnixSeconds { get; set; }
        }
    }
}
```
