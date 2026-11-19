# Qué es un Model

Guarda el estado, aplica las reglas y avisa cuando algo cambia. No sabe nada de Unity UI.

```csharp
public class LivesModel : MonoBehaviour
{
    private const int MAX_LIVES = 3;

    public event Action OnLivesChanged;

    private int remainingLives = MAX_LIVES;

    public int RemainingLives => remainingLives;
    public bool IsAlive => remainingLives > 0;

    public void LoseLife()
    {
        if (!IsAlive)
            return;

        remainingLives--;
        OnLivesChanged?.Invoke();
    }
}
```

- Un Model MonoBehaviour vive en la raíz de su scope (ver [Dónde vive cada Model](doc:scopes.donde_vive_model)).
- Una responsabilidad. Más de unos **5 comandos**: plantéate dividirlo (`MODEL-08`).
- El estado inicial va en **inicializadores de campo**: el `OnEnable` de una View puede correr antes que el `Awake` del Model (`ROOT-03`).

> [!TIP]
> Se testea en EditMode con `new GameObject().AddComponent<LivesModel>()` (`ROOT-05`).

**Ver también:** [Comandos y queries](doc:model.comandos_queries) · [Eventos](doc:model.eventos) · [Configuración](doc:model.configuracion) · [La View](doc:view.forma)
