# UI Tweens: API

| Target | Methods |
|---|---|
| `RectTransform` | `DOAnchorPos`, `DOAnchorPosX/Y`, `DOScale`, `DOScaleX/Y/Z`, `DORotate`, `DOSizeDelta`, `DOPivot` |
| `Graphic` (Image, TMP...) | `DOFade`, `DOColor`, `DOColorFromTo` |
| `Image` | `DOFillAmount` |
| `CanvasGroup` | `DOFade`, `DOFadeFromTo` |

| Option | For |
|---|---|
| `Delay(s)` | Wait before starting |
| `Loop(n)`, `LoopInfinite()`, `LoopType.Yoyo` | Repeat |
| `From()`, `Relative()` | From a value / as an offset |
| `IgnoreTimeScale()` | Keep playing at `timeScale = 0` |
| `WhenDisabled(behaviour)` | What happens when the GameObject is disabled |
| `Then(handle)`, `Sequential()` | Chain |
| `OnComplete(callback)` | When it finishes |

Easing: `Linear`, `Quad`, `Cubic`, `Quart`, `Quint`, `Sine`, `Expo`, `Circ`, `Back`, `Bounce`, `Elastic` (`In`/`Out`/`InOut`), `SpringOut`, `PunchOut`.
