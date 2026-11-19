# Size limits

**The target is what you write; the limit is a hard stop in code review.**

| | Target | Limit | At the limit |
|---|:---:|:---:|---|
| Lines in a method | 12 | <color=#F85149>**15**</color> | Extract a named method |
| Lines in a class | 120 | <color=#F85149>**200**</color> | Split by responsibility |
| Parameters | 2 | <color=#F85149>**3**</color> | Create a parameter class |
| Line width | | <color=#F85149>**120**</color> | Wrap |

> [!NOTE] Counting
> Body lines, without blank lines and lines holding only a brace. A class counts everything. The limits apply to constructors and Unity methods too. Only tests and generated code are exempt.

A method stays at **one level of abstraction**: it either coordinates named steps or does one low-level step.
