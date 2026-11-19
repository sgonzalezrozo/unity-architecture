# Commands and queries

> [!RULE] MODEL-02
> A method is a **query** (reads) or a **command** (changes state), never both. `Try*` is the accepted exception.

> [!RULE] MODEL-03
> A command **validates its input**. What the player can cause (too few coins) is ignored or returns a state. What only a bug can cause (an unknown ID) throws. Business rules **never** live in a Controller.

| Situation | What the command does |
|---|---|
| Not enough coins | Ignore, or return a state |
| An ID that doesn't exist | `throw` |
| Already in that state | `return` with no event |

> [!RULE] MODEL-11
> The Model finishes changing state **before** it fires the event. A listener doesn't call commands on the Model that fired it.
