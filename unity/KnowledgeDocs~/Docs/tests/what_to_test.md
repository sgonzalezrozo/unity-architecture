# What gets tested

| ID | Rule |
|---|---|
| `TEST-01` | When the scope includes tests, anything testable has them: Models, Modules, pure C# classes, conversions and calculations |
| `TEST-02` | Happy path, edge cases and errors |
| `TEST-03` | Logic that can't be tested where it is moves (usually to a Model) |
| `TEST-06` | Views and Controllers hold no logic: they rely on manual QA. If one needs a test, logic is misplaced |

> [!RULE] TEST-08
> A Model behavior test is written **first**, and fails before the code exists.

> [!RULE] TEST-04
> A bug fix includes a test that **fails without the fix**.
