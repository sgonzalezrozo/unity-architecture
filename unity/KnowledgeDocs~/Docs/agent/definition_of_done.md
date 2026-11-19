# Definition of Done

**Every change**

- [ ] Follows `AGENTS.md` and the checklist
- [ ] Compiles with no new warnings or analyzer errors, checked by a tool
- [ ] Everything testable has tests, and the related ones pass
- [ ] A bug fix includes a test that fails without the fix
- [ ] No unused code or debug logs

**UI changes**

- [ ] Strings localized (or English if there's no system)
- [ ] A new screen passed its Play mode check
- [ ] A prefab left to a person has a complete handoff
- [ ] Layout adapts to the target resolutions
- [ ] Subscriptions, tokens and Addressables cleaned up

**Before release**

- [ ] Tested on iOS and Android, with IL2CPP
- [ ] Memory and frame rate checked on devices
