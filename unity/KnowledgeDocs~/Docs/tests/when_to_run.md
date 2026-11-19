# When tests run

> [!RULE] TEST-11
> Before finishing a change, the **related** tests run: those of the classes changed or added, and of the classes that use them. The full suite runs in the Stop hook at most every two hours.

> [!RULE] TEST-10
> A new screen gets a **Play mode check**: it opens, its main input works, and the Console has no errors.

> [!RULE] TEST-12
> Every prefab under `Assets/Client` passes the prefab validator.
