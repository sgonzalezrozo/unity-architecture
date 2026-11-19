# La forma de un Controller

Convierte **un input** en **un comando**.

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

<!-- if: com.sgonzalezrozo.ui-foundations -->
> [!IMPORTANT] Con UI Foundations
> Este proyecto tiene UI Foundations: los click Controllers derivan de `BaseClickController` y sobrescriben `OnClick()` (`OPT-02`). Busca `BaseClickController`.

<!-- endif -->
> [!RULE] CTRL-01
> Una acción por Controller, sobre el elemento en el que actúa. Se llama `{Acción}Controller`.

> [!RULE] CTRL-02
> Un comando por input. Si un click hace dos cosas, eso es **un** comando en un Model.

> [!RULE] CTRL-05
> Sin referencias serializadas a objetos de Unity (`UA0003`). Un valor de configuración (un enum de qué pestaña abre) sí.

**Ver también:** [Un Controller no decide](doc:controller.no_decide) · [El objeto Action](doc:controller.action) · [Drag](doc:controller.drag) · [El Model](doc:model.que_es)
