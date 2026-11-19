# Where a Model lives

Use the **first row** that fits:

| # | Case | Where it lives | How Views and Controllers get it |
|:---:|---|---|---|
| 1 | Its Views and Controllers can share a parent | MonoBehaviour on the lowest common parent | `GetComponentInParent<TModel>()` |
| 2 | They can't, or it must persist | Pure C#, created by the container (without one: a singleton) | Injected `internal` field (or `TModel.Instance`) |
| 3 | Outside MVC: no UI uses it | Created by the container | They don't: only other Models use it |

> [!RULE] ROOT-06
> Injection is the **exception**. If a common parent can exist, the Model isn't injected.

> [!RULE] ROOT-02
> `GetComponentInParent` in `Awake`, cached. A singleton or a service locator doesn't replace it.

> [!RULE] ROOT-08
> Views and Controllers don't reference a row 3 Model.

**See also:** [When to inject](doc:di.when_to_inject) · [Singletons without a container](doc:scopes.singletons) · [What a scope is](doc:scopes.what_is_a_scope)
