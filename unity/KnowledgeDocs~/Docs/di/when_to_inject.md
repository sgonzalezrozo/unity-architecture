# When to inject

Most Views and Controllers **don't** use injection: they find their Model on a common parent with `GetComponentInParent`. Injection is for rows 2 and 3 of [Where a Model lives](doc:scopes.where_a_model_lives).

| You have | Mechanism |
|---|---|
| Fast IoC | Injected `internal` fields |
| Another container (Zenject, VContainer) | Its own injection |
| None | Singleton `TModel.Instance` (`ROOT-07`) |

| Class | How it gets the reference |
|---|---|
| View / Controller, Model on a common parent | `GetComponentInParent<TModel>()`, cached |
| View / Controller, no common parent or persistent Model | `internal` field |
| MonoBehaviour Model, config asset, Model outside MVC | `internal` field |
| Pure C# class | Constructor |

> [!CAUTION]
> A **service locator** is never used.
