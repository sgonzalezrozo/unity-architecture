# Editor tools

**Load when:** verifying a change, or when the agent can reach the Unity Editor through MCP, the Unity CLI or a verify script.

An agent that can compile, test and inspect the project checks its own work. One that can't must say so. This document decides which tool does the checking. It never changes the [architecture](../AGENTS.md#architecture-invariants).

## Capability detection

Run this with [package capability detection](OPTIONAL_PACKAGES.md#capability-detection), once per task.

| Capability | `true` when |
|---|---|
| `editorBridge` | The agent has tools that drive a running Unity Editor: the Unity CLI (`unity` command, or its `unity mcp` mode, with `com.unity.pipeline` in the manifest), [MCP for Unity](https://github.com/CoplayDev/unity-mcp) (`com.coplaydev.unity-mcp`) or another Unity MCP server |
| `verifyScript` | `scripts/verify.sh` exists. It compiles and runs the EditMode tests in batch mode, with the Editor closed |
| `generationStatus` | `fastIoC` is `true`. `Assets/FastIoC/Generated/GenerationStatus.json` reports missing bindings and cycles |

Unity's in-Editor MCP server in the AI Assistant package (`com.unity.ai.assistant`) is deprecated by Unity. Treat it as an `editorBridge`, but don't suggest it: the Unity CLI replaces it.

A bridge and the verify script can't both own the project. `verify.sh` needs the Editor closed, and a bridge needs it open. While the Editor is open, the Editor itself writes its compile and test results to `Logs/verify/` (from `Assets/Editor/UnityArchitecture`, which `install.sh` installs), and `scripts/verify-editor.sh` reads them.

## Rules

| ID | Rule |
|---|---|
| `EDIT-01` | A claim that code compiles, passes tests or runs MUST come from a tool in this document (`DET-02`). Without one, report it as not verified. |
| `EDIT-02` | After a script change, the agent MUST wait for the compile to finish, then read every error and warning it caused before it reports. With `editorBridge`, read the Console. Otherwise, run `verify.sh`. |
| `EDIT-03` | Analyzer diagnostics (`UA0001` and up) are compile errors. Fix the code. MUST NOT suppress, disable or move code out of the analyzed assembly to pass. |
| `EDIT-04` | With `generationStatus`, a change to an installer, constructor or injected field is done only when `GenerationStatus.json` reports `"status": 0` with no new `warnings`. Fix installers or code, never the generated files. |
| `EDIT-05` | With `editorBridge`, the agent MAY create GameObjects, components and prefabs through the bridge's editor tools. It MUST still write the [prefab handoff](AGENT_WORKFLOW.md#prefab-handoff) table first, as the spec, then read the built hierarchy back and report any difference. |
| `EDIT-06` | MUST NOT write `.prefab`, `.unity`, `.asset` or `.meta` YAML as text, through a bridge or not. Unity's serializer owns those files. |
| `EDIT-07` | With `editorBridge`, a new screen's Play mode check (`TEST-10`) is automated: enter Play mode, open the screen, read the Console, exit. Report it as verified only if all of that ran. |
| `EDIT-08` | Bridge actions that add or remove packages, change Project Settings, delete assets or start a build MUST follow [When to ask](AGENT_WORKFLOW.md#when-to-ask). |
| `EDIT-09` | Prefer a package's own validation tool or status file to the agent's judgment of that package (`DET-01`). |
| `EDIT-10` | With the Editor open, after changing scripts the agent MUST ask the Editor to compile (`refresh_unity` with MCP for Unity) before it finishes: an Editor without focus doesn't refresh on its own. It MUST run the EditMode tests in the Editor (`run_tests`, then `get_test_job` until it finishes) when the Stop hook asks for them, and SHOULD NOT run them on every change. |

## Verification order

Run the cheapest deterministic check first, and stop at the first failure:

```
compile + analyzers → EditMode tests → generation status → Play mode check → report
```

| Step | With `editorBridge` (Editor open) | With `verifyScript` (Editor closed) | With neither |
|---|---|---|---|
| Compile and analyzers | `refresh_unity`, then read the Console; `verify-editor.sh` reads the compile result | `verify.sh`, exit code `1` lists errors | Not verified |
| EditMode tests | `run_tests` through the bridge; `verify-editor.sh` reads the result | `verify.sh` | Not verified |
| Generation status | Read `GenerationStatus.json` | `verify.sh` reads it | Read the file. It may be stale |
| Play mode check | Automate it (`EDIT-07`) | Manual step for the developer | Manual step for the developer |

## Automatic verification

A Claude Code Stop hook stops an agent from finishing with a broken build. `templates/scripts/install.sh` installs it, as the [README](../README.md#use-it-in-a-project) shows. It runs only when `Assets`, `Packages` or `ProjectSettings` changed, sends failures back to the agent, and gives up after three attempts in a row.

Compiling is quick, so the hook checks it on every stop. The tests are slow, so it runs them at most every two hours, and only when something changed since they last passed. Between runs it sets `VERIFY_COMPILE_ONLY=1`, and its message says when the tests are due. A test run in the open Editor, such as one the developer starts in the Test Runner, counts as the last run. Set `VERIFY_TESTS_EVERY_SECONDS` to change the interval.

| Editor | The hook runs | What it checks |
|---|---|---|
| Closed | `scripts/verify.sh` | Compiles in batch mode. When the tests are due, also runs the EditMode tests |
| Open | `scripts/verify-editor.sh` | Reads `Logs/verify/editor-compile.json` and `editor-tests.json`, written by the Editor. Asks the agent to compile (`refresh_unity`) when a script changed after the last compile. When the tests are due, asks it to run them (`run_tests`) if they haven't run since the last script change |

Both check Fast IoC's `GenerationStatus.json` and use the same exit codes: `0` passed, `1` failed, `2` couldn't run.

## Reporting back

End every report with what each tool verified:

```
Verified: compile and analyzers (verify.sh), 14 EditMode tests passed, GenerationStatus.json status 0
Not verified: Play mode check for TrophyRoom (manual)
```
