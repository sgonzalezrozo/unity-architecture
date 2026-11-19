# The flow in one line

Every change on screen takes the same path:

```flow
Input -> Controller -> Model command -> State change:blue
Parameterless event:yellow -> View reads the Model -> View renders
```

## Where to look for a bug

| Symptom | Layer at fault |
|---|---|
| A wrong value | [**Model**](doc:model.what_is_a_model) |
| A wrong pixel | [**View**](doc:view.shape) |
| A dead click | [**Controller**](doc:controller.shape) |

> [!NOTE]
> This split is the payoff of being strict: you always know which file holds the problem.

**See also:** [MVC at a glance](doc:architecture.mvc_overview) · [Pull, never push](doc:architecture.pull_not_push)
