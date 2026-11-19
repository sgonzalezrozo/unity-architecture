# UI Tweens: API

| Target | Métodos |
|---|---|
| `RectTransform` | `DOAnchorPos`, `DOAnchorPosX/Y`, `DOScale`, `DOScaleX/Y/Z`, `DORotate`, `DOSizeDelta`, `DOPivot` |
| `Graphic` (Image, TMP...) | `DOFade`, `DOColor`, `DOColorFromTo` |
| `Image` | `DOFillAmount` |
| `CanvasGroup` | `DOFade`, `DOFadeFromTo` |

| Opción | Para qué |
|---|---|
| `Delay(s)` | Esperar antes de empezar |
| `Loop(n)`, `LoopInfinite()`, `LoopType.Yoyo` | Repetir |
| `From()`, `Relative()` | Desde un valor / como offset |
| `IgnoreTimeScale()` | Seguir con `timeScale = 0` |
| `WhenDisabled(behaviour)` | Qué pasa al desactivar el GameObject |
| `Then(handle)`, `Sequential()` | Encadenar |
| `OnComplete(callback)` | Al terminar |

Easing: `Linear`, `Quad`, `Cubic`, `Quart`, `Quint`, `Sine`, `Expo`, `Circ`, `Back`, `Bounce`, `Elastic` (`In`/`Out`/`InOut`), `SpringOut`, `PunchOut`.
