# Editor open or closed

| | Editor open (MCP) | Editor closed |
|---|---|---|
| Compile | `refresh_unity` + Console | `scripts/verify.sh` in batch mode |
| Tests | `run_tests` with a filter | `VERIFY_TEST_FILTER="..." scripts/verify.sh` |
| Prefabs | Built and validated through `execute_code` | Not built: the agent writes the spec or handoff |
| Play mode | Automated | Manual step |
| Stop hook | `verify-editor.sh` | `verify.sh` |

> [!TIP]
> Work with the Editor **open** for anything with UI. The closed mode suits pure C# changes, CI and machines without Unity open.

> [!RULE] EDIT-10
> With the Editor open, after changing scripts the agent **asks it to compile** (`refresh_unity`): an Editor without focus doesn't refresh on its own.
