# When the agent asks

It asks when the docs and the code don't settle a decision. Always before:

- Adding a package or dependency (referencing one already in the manifest doesn't count).
- Changing `Shared/`, core patterns or public behavior.
- Using an undocumented API with no precedent.
- Introducing a new pattern.
- Breaking any rule in `AGENTS.md`.

> [!RULE] DATA-01
> Names, amounts, prices and currencies come from the request and what it attaches (spec, mockup). Otherwise, **United States** defaults: English, US dollars, `en-US` formats.

> [!IMPORTANT]
> It never fills a gap with a guess presented as fact. If it assumed something, it says so.
