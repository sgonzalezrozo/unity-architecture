# Adaptive layouts

```text
ScreenRoot (fills parent, VerticalLayoutGroup)
├── Header (fixed or preferred height)
├── Content (flexible, fills the rest)
└── Footer (fixed or preferred height)
```

- Layouts **fill the available space** and adapt to their container.
- `LayoutGroup` with preferred and flexible sizes, not fixed positions.
- More than about **5 hierarchy levels** is a warning sign.
- Test at several aspect ratios.

> [!NOTE]
> Keep static elements apart from dynamic ones. Dynamic content is tab content or a list.
