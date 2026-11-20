# The scope question

A short prompt, like "create the player health feature to show it in the UI", doesn't say how much to build. Before planning a new feature or screen, the agent asks:

| Choice | The agent creates |
|---|---|
| **Code only** | The scripts. Prefabs are described in a handoff for you |
| **Code and prefabs** | The scripts and the prefabs |
| **Code and tests** | The scripts and their unit tests |
| **Code, prefabs and tests** | All of it |

> [!RULE] TASK-01
> The agent asks this once, together with the plan. It skips it when your request already says.

> [!RULE] TASK-03
> The agent doesn't write analyzers, editor tools, generators or test infrastructure unless you ask for them by name.

> [!TIP]
> Say it up front to skip the question: "Create the player health feature, code and prefabs, no tests."

Without tests, the code stays testable and the agent lists the tests it would write.
