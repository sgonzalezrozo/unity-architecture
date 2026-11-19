# Drag and input values

> [!RULE] CTRL-04
> A Controller may **convert** input to a domain value (a pointer position to 0–1). Clamping and change detection belong to the Model.

```csharp
public class DragVolumeController : MonoBehaviour, IPointerDownHandler, IDragHandler
{
    private SettingsModel settingsModel;
    private RectTransform barRectTransform;

    private void Awake()
    {
        settingsModel = GetComponentInParent<SettingsModel>();
        barRectTransform = (RectTransform)transform;
    }

    public void OnPointerDown(PointerEventData eventData)
    {
        SetVolumeFromPointer(eventData);
    }

    public void OnDrag(PointerEventData eventData)
    {
        SetVolumeFromPointer(eventData);
    }

    private void SetVolumeFromPointer(PointerEventData eventData)
    {
        bool isOnBar = RectTransformUtility.ScreenPointToLocalPointInRectangle(
            barRectTransform, eventData.position, eventData.pressEventCamera, out Vector2 localPoint);

        if (!isOnBar)
            return;

        settingsModel.SetNormalizedVolume(Rect.PointToNormalized(barRectTransform.rect, localPoint).x);
    }
}
```

`SetNormalizedVolume` clamps with `Clamp01` and fires no event when the value didn't change.
