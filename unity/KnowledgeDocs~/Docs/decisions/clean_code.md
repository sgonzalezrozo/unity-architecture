# Deliberate decisions

Some rules differ from *Clean Code* on purpose. **Don't "fix" them.**

| Topic | *Clean Code* | Here | Why |
|---|---|---|---|
| Tell, don't ask | Objects do the work | Views pull from the Model | It's the core of the design |
| Boy scout rule | Improve what you touch | Refactor only when asked | Small, low-risk diffs |
| Exceptions | Exceptions | `Result<T>` or state for what's expected | "Not enough coins" isn't exceptional |
| Construction vs use | Through the constructor | `GetComponentInParent` and `internal` injection | A MonoBehaviour has no constructor |
| Global state | Avoid it | Singletons without a container | A public constructor keeps them testable |
| Readability first | Optimize after measuring | No LINQ or lambdas | Hot paths need no audit |
| No duplication | Remove repeated structure | Every View repeats the subscribe pattern | Always written right, no deep inheritance |
