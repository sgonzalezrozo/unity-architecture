# Code style

These standards are mandatory in every project, with or without the optional packages.

`.editorconfig` covers formatting in the editor but doesn't stop compilation. The [analyzers](../../analyzers) fail the build for `var`, LINQ, lambdas and `?.` on Unity objects. Code review enforces the rest.

Apply these rules to new code. Refactor old code only when asked.

## Naming

| Element | Style |
|---|---|
| Classes, public methods, properties, enums | `PascalCase` |
| Fields, locals, parameters | `camelCase`, no underscore |
| Constants | `ALL_CAPS` |
| Events | `OnSomethingChanged`, past tense |
| Async methods | Suffix `Async` |

Names MUST say what something is or does, without a comment. Use full, specific, searchable words: no abbreviations, no single letters outside loop counters, and no type or layer encodings beyond the patterns here.

Method prefixes state intent: `Get` (query), `Set` (assign), `Is`/`Has`/`Can` (bool query), `Try` (may fail, returns bool), `Calculate` (computes), `Update` (recomputes), `Render` (View draws Model state), `On` (event handler), `Validate` (throws if invalid).

## Class layout

Constants → events → injected fields → serialized fields → public fields → private fields → properties → constructor → Unity methods → other methods in order of use.

## Size

| | Target | Hard limit | At the limit |
|---|---|---|---|
| Lines in a method | 12 | 18 | Extract a named method |
| Lines in a class | 120 | 240 | Split by responsibility |
| Parameters | 2 | 4 | Create a parameter class |
| Line width | | 120 characters | Wrap |

A method MUST stay at one level of abstraction: it either coordinates named steps or does one low-level step, not both.

Method lines count the body, without blank lines and lines holding only a brace. Class lines count everything in the class. The limits also apply to constructors and Unity methods. Only tests and generated code are exempt.

## Writing code

- Explicit types, never `var`.
- `new()` when the type is on the left: `List<string> names = new();`.
- Guard clauses and early returns instead of nested `if`/`else`. In loops, invert and `continue`.
- A single statement after `if`/`for`/`foreach` goes on the next line, indented, without braces.
- Opening braces on a new line. Expression-bodied methods put `=>` on a new line.
- No `#region`.
- No `///` summaries on members (methods, properties, fields, events, enum members); `UA0015` fails the build. A short `///` summary on a class or other type is allowed. No other comments unless explaining something the code cannot, such as an engine bug or an order dependency.
- No magic numbers (0, 1 and -1 in obvious contexts are fine). Name timeouts, retries, delays and thresholds.
- No hardcoded user-facing text. Use the localization system. A project has one when its settings are configured and Client code already uses it (both in `Logs/ai/project-facts.md`); an installed package alone isn't one. A project without one uses English text until it has one (`DATA-01`), and adopting a localization package is a new dependency to ask about.
- No boolean flag parameters that select a code path; make two methods. `SetVisible(bool)` is fine, since the value is the state being set.
- Command-query separation. `Try*` is the accepted exception.
- `out` and `ref` parameters only in `Try*` methods.
- No duplicated logic: a second copy of a rule or calculation MUST be extracted. Repeated structure, such as the View subscribe pattern, is fine.
- Law of Demeter: `player.GetCaptainHealth()`, not `player.Team.Captain.Health`.
- Prefer polymorphism over a `switch` on type that chooses behavior. A `switch` expression for a simple mapping is fine.
- Prefer `private`, and `{ get; private set; }` over public setters.
- Remove unused usings, code and commented-out code.

## SOLID

Single responsibility per class, depend on interfaces at boundaries, prefer composition to inheritance. Don't add abstraction speculatively (`ARCH-10`). External systems (HTTP, files, SDKs) stay behind an interface we own, as Connectors do. A base class never checks for its derived types.

## Unity

- **Never use `?.`, `??` or `??=` on anything derived from `UnityEngine.Object`.** They bypass Unity's destroyed-object check. Use `if (x == null)`.
- **Never rename a serialized field in use** without `[FormerlySerializedAs("oldName")]`. The Inspector data is lost otherwise.
- Cache components once in `Awake`. Do not call `GetComponent` in `Update`.
- A GameObject does not call `SetActive` on itself; its parent controls visibility.
- Avoid `OnValidate` and decorative `[Header]` attributes.
- Data classes that must serialize are `[Serializable]` with public fields. Unity does not serialize auto-properties.
- Check your Unity version's C# level before using newer syntax. `record` and `init` need an `IsExternalInit` shim on older profiles, and `required` is not available at C# 9.
