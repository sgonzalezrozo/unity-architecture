# Fast IoC: injected Models

Branch `fast-ioc` of the `container` fork. Read it only when the [profile](../../OPTIONAL_PACKAGES.md#the-profile) says `container: fast-ioc`.

A Model in row 2 or 3 of [Where a Model lives](../../mvc/where-a-model-lives.md) is a pure C# class created by Fast IoC. A View or Controller gets it through an `internal` field with no attribute:

```csharp
public class TrophyCountView : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI countText;

    internal TrophyRoomModule trophyRoomModule;
}
```

FastIoC matches by **type**. The field name doesn't matter and no attribute marks intent, so `internal` is the only signal that a field is injected.

Injected fields are assigned before `Awake`, in the first scene, in scenes loaded later and in prefabs created with `IPrefabInstantiator`, so a View or Controller MAY use them in `Awake` and `OnEnable`. A scene with no baked manifest is injected after `Awake`: the package's `injection.md` lists those cases.

A configuration asset for a Model is bound with `Bind<T>().FromInstance("Path").AsSingle()` and injected into an `internal` field (`MODEL-10`).

| ID | Rule |
|---|---|
| `DI-01` | `[Inject]` MUST NOT be used with Fast IoC (`UA0007`). |
| `DI-05` | Code MUST NOT resolve from `ContextRuntime` as a service locator. FastIoC flags this in the Editor and development builds. |

## Runtime-created objects

List slots receive injection through `IInjectableForChildren` on their Slot Model (`LIST-01`).

Code MUST NOT call `Instantiate` directly for a prefab with injected fields. Use `IPrefabInstantiator`, or the fields stay empty.

Bindings and installers: [Fast IoC installers](installers.md).

Verify these symbols before use (`API` policy in [AGENTS.md](../../../AGENTS.md#api-policy)): `IInjectableForChildren`, `IPrefabInstantiator`, `IInjectingPrefabInstantiator`.
