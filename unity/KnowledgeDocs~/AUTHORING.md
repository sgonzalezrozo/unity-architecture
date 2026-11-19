# Writing the Rules Guide docs

Internal notes for maintaining the Rules Guide docs. **This file doesn't show in the window**: the docs are fixed and maintained together with the `.ai` rules, not per project.

## Where everything lives

| File | For |
|---|---|
| `KnowledgeDocs~/knowledge.json` | The index: title, summary, category, color, keywords, source, requirements and home page |
| `KnowledgeDocs~/Docs/<topic>/*.md` | One doc per topic, short (under about 50 lines) |
| `KnowledgeDocs~/Images/` | Screenshots and diagrams (`.png` or `.jpg`) |

The `~` in the folder name keeps Unity from **importing** it: no `.meta` files or assets, but the window reads it from disk.

## Catalog entry

```json
{
  "id": "model.what_is_a_model",
  "title": "What a Model is",
  "summary": "What a Model does and how it looks",
  "category": "Model",
  "color": "blue",
  "keywords": ["model", "state", "MODEL-08"],
  "markdownPath": "Docs/model/what_is_a_model.md",
  "source": "architecture/MVC.md",
  "home": "Architecture",
  "homeOrder": 0,
  "requires": ["com.sgonzalezrozo.ui-scroller"]
}
```

- `source`: the original rule, relative to the `.ai` root, or `package:<name>/<file>` for a package file.
- `keywords`: add synonyms and every rule ID the doc defines; rule links resolve through them.
- `home` / `homeOrder`: shows the doc on the home page, in a section from `homeSections`.
- `requires` / `requiresMissing`: the doc shows only when those packages are (or aren't) installed.

## Text

- **Bold** with `**text**`, *italic* with `*text*`, ~~strikethrough~~ with `~~text~~`, ==highlight== with `==text==`.
- Inline code with backticks: `GetComponentInParent<TModel>()`.
- Free color with Unity's tag `<color=#hex>text</color>`: <color=#3FB950>green</color>, <color=#F85149>red</color>.

## Links

- To another doc: `[Model](doc:model.what_is_a_model)` (the `id` from `knowledge.json`).
- Rule IDs in code (`` `VIEW-03` ``, `` `UA0012` ``) link on their own to the doc with that ID in its keywords (preferring the one whose summary names it).
- A `https://...` URL opens in the browser.

## Callouts

Start a quote with `> [!TYPE]` and, optionally, a title of your own.

> [!NOTE]
> Useful information.

> [!TIP] A shortcut
> A faster way to do it.

> [!IMPORTANT]
> Something you can't miss.

> [!WARNING]
> It can break something if you're not careful.

> [!CAUTION]
> Serious consequences.

> [!DO]
> The right way. Pair it with a `[!DONT]`.

> [!DONT]
> The wrong way.

> [!RULE] ARCH-01
> A rule with its ID.

> [!EXAMPLE]
> A concrete example.

## Lists

1. Numbered lists renumber themselves.
1. You can write `1.` on every line.
   - Nest with two or three spaces.

- [x] A done checklist item
- [ ] A pending one

## Code

Name the language after the backticks for highlighting. Every block gets a **Copy** button.

```csharp
public class LivesModel : MonoBehaviour
{
    public event Action OnLivesChanged;
}
```

## Flow diagrams

A code block with the `flow` language draws boxes with arrows. Separate steps with `->`. MVC layers get their color automatically; force one with `:green`, `:red`, `:#FF00FF`...

```flow
Input -> Controller -> Model -> View
Button:gray -> Backend:teal -> Result:green
```

Each line is a row, and rows wrap when they don't fit.

## Images

```text
![Caption](../../Images/my_screenshot.png "Optional title")
```

The path is relative to the `.md`. A name ending in `@2x` is drawn at half size (retina screenshots). A missing image shows a placeholder box.

## Content that depends on a tool

- **A whole doc:** `"requires"` in `knowledge.json`.
- **Part of a doc:** conditional blocks, each marker on its own line:

```text
<!-- if: com.sgonzalezrozo.screen-system -->
Text with Screen System
<!-- else -->
Text without Screen System
<!-- endif -->
```

Also `<!-- if-not: ... -->`. They can nest.

> [!NOTE]
> The editor font has no emoji: use callouts and colors instead of icons.
