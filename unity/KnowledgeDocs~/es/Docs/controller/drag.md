# Drag y valores de input

> [!RULE] CTRL-04
> Un Controller puede **convertir** input en un valor de dominio (una posición del puntero a 0–1). Limitar y detectar cambios es cosa del Model.

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

`SetNormalizedVolume` hace el `Clamp01` y no lanza evento si el valor no cambió.
