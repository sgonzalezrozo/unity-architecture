# Tests

| ID | Rule |
|---|---|
| `TEST-01` | Anything that can be unit tested MUST have unit tests when the task's scope includes tests (`TASK-01`): Models, Modules, pure C# classes, data conversions and calculations. |
| `TEST-02` | Tests MUST cover the happy path, edge cases and errors. |
| `TEST-03` | Logic that can't be tested where it is MUST move to a testable class. It usually belongs in a Model. |
| `TEST-04` | A bug fix MUST include a test that fails without the fix. |
| `TEST-05` | Tests MUST be deterministic: no real time, randomness, network or dependence on run order. Fake them through interfaces. |
| `TEST-06` | Views and Controllers hold no logic, so they rely on manual QA. If one needs a test, that signals misplaced logic. |
| `TEST-07` | Mock only boundaries you own, such as Connectors and clocks. Use real Models. |
| `TEST-08` | A test for Model behavior MUST be written first, and MUST fail before the code exists. |
| `TEST-09` | Test code follows these standards, including naming and no duplication. Only the lambda ban and size limits don't apply. |
| `TEST-10` | A new screen MUST get a Play mode check: it opens, its main input works and the Console has no errors. Automate it when possible. Otherwise, report it as a manual step. |
| `TEST-11` | Before finishing a change, the agent MUST run the tests directly related to it, existing and new: the tests of the classes it changed or added, and of the classes that use them. They MUST pass. The Stop hook also runs, on every stop, the tests of the features the task is scoped to (`TEST-13`) and of every feature the change touched, and the full suite at most every two hours, or every 24 hours while the task is scoped to features ([Automatic verification](../EDITOR_TOOLS.md#automatic-verification)). The agent SHOULD NOT run the full suite on every change. |
| `TEST-12` | Every prefab under `Assets/Client` MUST pass the prefab validator: an EditMode test in the rules' package (`com.sgonzalezrozo.unity-architecture`) that checks the [prefab rules](../PREFABS.md#checking-a-prefab) a tool can check, with one case per feature folder. Fix the prefab, never the validator, and never by writing the prefab as text (`EDIT-06`). |
| `TEST-13` | With the scope question (`TASK-01`), unless the request already names it (`tests: Assets/Client/Inventory`), the agent MUST ask which folder the task's tests are scoped to: a feature folder under `Assets/Client`, or the whole project. It writes the answer to `Logs/verify/test-scope`, one path per line (`Assets/Client/Inventory`), and deletes the file for the whole project. The Stop hook then runs those features' tests on every stop ([Automatic verification](../EDITOR_TOOLS.md#automatic-verification)). The agent MUST NOT write anything else to that file, or edit it, the hook or `Logs/verify/` to skip a check: the hook always also tests every feature the change touched. |

Use NUnit and Arrange-Act-Assert, with one concern per test. Mock Connectors with NSubstitute. Name tests `{Method}_{Condition}_{Result}`.
