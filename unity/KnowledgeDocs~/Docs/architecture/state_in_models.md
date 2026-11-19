# Models own the truth

> [!RULE] ARCH-02
> All data and all state live in Models. Views and Controllers hold nothing beyond cached references.

> [!RULE] ARCH-03
> Views **render** and Controllers **receive input**. A View doesn't handle input or call commands. A Controller doesn't change anything visual.

> [!DONT]
> A `bool isOpen` in a View, or a click counter in a Controller.

> [!DO]
> That state goes in a Model, and the View reads it.
