# Checklist and Definition of Done

## Pre-response checklist

Run this before returning code. Item numbers are stable: the [analyzers](../../analyzers) refer to them.

1. Does any Model know a View, a Controller or a Unity component?
2. Does any View handle input, call a command, or know a service? Does an inner View read a Model or subscribe, or does a View reach into a nested prefab or have more than 5 serialized fields?
3. Does any Controller change a visual, hold a rule, or serialize a reference?
4. Does any event have parameters? Is anything pushed that could be pulled?
5. Is there a `Button`, `Toggle`, `Slider`, `Dropdown`, `onClick` or `Initialize(model)`?
   Does the code reference a package whose capability is `false`? Does `Client.asmdef` reference every assembly the packages it uses need (`ASM-02`)?
6. Are assigned fields `internal`, with no attribute under Fast IoC, and everything else `private`?
7. Is every file in the right folder, and is source art outside the feature?
8. Are there lambdas, LINQ, `var`, `?.` on Unity objects, `///` comments on members, or hardcoded text?
9. Could a deterministic tool have decided this? Does a Model read time or randomness directly?
10. Is everything that can be unit tested covered by a test, with Model tests written first? When the scope has no tests (`TASK-02`), is the logic still testable, and are the missing tests listed in the report?
11. Is each Model and View on its scope root? Does any View render outside its scope?
12. Do Model dependencies form a cycle? Does any Model have a serialized field?
13. Is this the minimum that finishes the need, with no unused abstraction and nothing loaded before it's needed?
14. Did a tool verify the compile, analyzers, tests and generation status (`EDIT-01`)? Is anything reported as verified that no tool checked?

## Reporting back

State what changed, which tool verified it, and what wasn't verified. If you couldn't compile or run the code, say so.

## Definition of Done

**Every change**

- [ ] Follows `AGENTS.md` and the checklist above
- [ ] Compiles with no new warnings or analyzer errors, checked by a tool (`EDIT-02`)
- [ ] Only what the chosen scope includes was created (`TASK-02`)
- [ ] When the scope includes tests: everything that can be unit tested has tests, and the tests directly related to the change, existing and new, pass (`TEST-11`). Without tests in the scope, the existing related tests still pass. The Stop hook runs the tests of the scoped and changed features on every stop, and the full suite at most every two hours (every 24 hours while the task is scoped to features); until the full suite has run, report it as not verified
- [ ] A bug fix includes a test that fails without the fix
- [ ] No unused code, no debug logs

**UI changes**

- [ ] Strings use localization when the project has a localization system; otherwise they are English
- [ ] A new screen passed its Play mode check (`TEST-10`)
- [ ] Any prefab left to a person has a complete [handoff](prefab-handoff.md#prefab-handoff)
- [ ] Layout adapts to the target resolutions
- [ ] Subscriptions, tokens and Addressables are cleaned up

**Before release**

- [ ] Tested on iOS and Android devices, checked with IL2CPP
- [ ] Memory and frame rate checked on target devices
