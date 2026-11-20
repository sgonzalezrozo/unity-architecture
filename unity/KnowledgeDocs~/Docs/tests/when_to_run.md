# When tests run

> [!RULE] TEST-11
> Before finishing a change, the **related** tests run: those of the classes changed or added, and of the classes that use them. The Stop hook runs the tests of the task's features on every stop, and the full suite at most every two hours (every 24 hours while the task is scoped to features).

> [!RULE] TEST-10
> A new screen gets a **Play mode check**: it opens, its main input works, and the Console has no errors.

> [!RULE] TEST-12
> Every prefab under `Assets/Client` passes the prefab validator. It has one case per feature, so a changed prefab only checks its feature.

> [!RULE] TEST-13
> With the scope question, the agent asks which **feature folder** the task's tests are scoped to, or the whole project, and writes it to `Logs/verify/test-scope`. Skip the question by naming it in the prompt: `tests: Assets/Client/Inventory`. The hook always also tests every feature the change touched.
