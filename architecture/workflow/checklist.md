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
7. Is every file in the right folder, and is source art outside the feature? When a person still has Unity work to do, is it in the feature's `IMPLEMENTATION.md` (`HAND-07`), and does the response link it instead of repeating it?
8. Are there lambdas, LINQ, `var`, `?.` on Unity objects, `///` comments on members, or hardcoded text?
9. Could a deterministic tool have decided this? Does a Model read time or randomness directly?
10. Is everything that can be unit tested covered by a test, with Model tests written first? When the scope has no tests (`TASK-02`), is the logic still testable, and are the missing tests listed in the report?
11. Is each Model and View on its scope root? Does any View render outside its scope?
12. Do Model dependencies form a cycle? Does any Model have a serialized field?
13. Is this the minimum that finishes the need, with no unused abstraction and nothing loaded before it's needed? Does the delivery match `Logs/ai/plan.md` file by file, with nothing outside the feature that `outside-feature` doesn't name (`PLAN-02`)?
14. Did a tool verify the compile, analyzers, tests and generation status (`EDIT-01`)? Is anything reported as verified that no tool checked?

## Reporting back

State what changed, which tool verified it, and what wasn't verified. If you couldn't compile or run the code, say so. Name every file or kind the feature files table doesn't list, with the suggestion used, under **Table gaps**, so the table can grow (`planning.md`). With packs, end with the `Outside packs:` line (`OPT-07`).

## Definition of Done

**Every change**

- [ ] Follows `AGENTS.md` and the checklist above
- [ ] Compiles with no new warnings or analyzer errors, checked by a tool (`EDIT-02`)
- [ ] Only what the chosen scope includes was created (`TASK-02`)
- [ ] When the scope includes tests: everything that can be unit tested has tests, and the tests directly related to the change, existing and new, pass (`TEST-11`). Without tests in the scope, the existing related tests still pass. The tests of the scoped and changed features run where the scope asks, and never the full suite; unless you ran it by hand, report the full suite as not verified. With "solo codigo" the scope has no tests: run none, and say so
- [ ] A bug fix includes a test that fails without the fix
- [ ] No unused code, no debug logs

**UI changes**

- [ ] Strings use localization when the project has a localization system; otherwise they are English
- [ ] A new screen passed its Play mode check (`TEST-10`)
- [ ] Any prefab or setup left to a person has a complete [handoff](prefab-handoff.md#prefab-handoff) in `{Feature}/IMPLEMENTATION.md` (`HAND-07`)
- [ ] Layout adapts to the target resolutions
- [ ] Subscriptions, tokens and Addressables are cleaned up

**Before release**

- [ ] Tested on iOS and Android devices, checked with IL2CPP
- [ ] Memory and frame rate checked on target devices
