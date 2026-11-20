# Where a Model lives

This applies to every project, with or without a container. Use the first row that fits.

| Order | Case | Where it lives | How a View or Controller gets it |
|---|---|---|---|
| 1 | Its Views and Controllers can share a parent | MonoBehaviour in the scene or prefab, on the lowest common parent, even if that is a root GameObject of the scene | `GetComponentInParent<TModel>()` |
| 2 | They can't share a parent, or it must persist | Pure C#, created by the container. Without one, a singleton | Injected `internal` field. Without a container, `TModel.Instance` |
| 3 | Outside MVC: no View or Controller uses it | Created by the container. Without one, a singleton | It doesn't. Only Models reference it |

> **Fork `container`** · how a Model in row 2 or 3 is created and reached. Open only the branch the [profile](../OPTIONAL_PACKAGES.md#the-profile) names:
> - `fast-ioc`: [Fast IoC: injected Models](../branches/fast-ioc/models.md)
> - `other-container`: [Another container: injected Models](../branches/other-container/models.md)
> - `no-container`: [No container: singletons](../branches/no-container/models.md)

```
LivesScreen.prefab [LivesModel, LivesView]
├── UI Content
│   └── RemainingLivesText (TextMeshProUGUI)
└── Action (Image: alpha 0) [LoseLifeController]
```

| ID | Rule |
|---|---|
| `ROOT-01` | A Model MUST sit on the lowest common parent of the Views and Controllers that use it, whenever one can exist. That is usually its scope root (`SCOPE-03`). Prefabs loaded with Addressables count. |
| `ROOT-02` | Those Views and Controllers MUST get it with `GetComponentInParent<TModel>()` in `Awake`, and cache it. A singleton or a service locator MUST NOT replace this. |
| `ROOT-03` | A MonoBehaviour Model MUST set its initial state in field initializers. A View's `OnEnable` can run before the Model's `Awake`. |
| `ROOT-04` | A MonoBehaviour Model is still a Model: it MUST NOT reference a View, a Controller or a non-Model component. |
| `ROOT-05` | Unit test a MonoBehaviour Model in EditMode with `new GameObject().AddComponent<TModel>()`. |
| `ROOT-06` | Injection is the exception. A Model MUST NOT be injected into a View or Controller when a common parent can exist. |
| `ROOT-07` | Without a container, a Model in row 2 or 3 MUST be a pure C# singleton with a public constructor. Views and Controllers cache `TModel.Instance` in `Awake`. With a container, singletons MUST NOT be used. |
| `ROOT-08` | Views and Controllers MUST NOT reference an Outside-MVC Model (row 3). |
| `ROOT-09` | A test MUST create its own instance and MUST NOT use `TModel.Instance`, because static state carries over between tests. |

## Reference acquisition

| Layer | Serialized field | Injected `internal` field | `GetComponentInParent` | Constructor |
|---|---|---|---|---|
| **Pure C# Model** | No | No | No | Yes |
| **MonoBehaviour Model** | No | Models | Parent Models | No |
| **View** | Rendering components, state roots, config values | Models, row 2 only | Models, row 1 only | No |
| **Controller** | Config values | Models, row 2 only | Models, row 1 only | No |

`Initialize(model)` on a MonoBehaviour is method injection and MUST NOT be used (`UA0006`).
