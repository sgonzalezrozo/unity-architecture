# Comments and text

> [!DONT] `///` on members
> Methods, properties, fields, events and enum members get **no** `///`. Analyzer `UA0015` fails the build.

> [!DO]
> A short `///` on a **class** or type is fine. Other comments only for what code can't say (an engine bug, an order dependency).

> [!RULE] User-facing text
> No hardcoded text: use the localization system. Without one, text is English until there is one (`DATA-01`).

Remove unused usings, code and commented-out code.
