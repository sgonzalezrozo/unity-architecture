# Layouts

```
ScreenRoot (fills parent, VerticalLayoutGroup)
├── Header (fixed or preferred height)
├── Content (flexible, fills the remainder)
└── Footer (fixed or preferred height)
```

- Layouts MUST fill the available space and adapt to their container.
- Use `LayoutGroup` with preferred and flexible sizes, not fixed positions.
- More than about 5 hierarchy levels is a warning sign.
- Test at several aspect ratios.
