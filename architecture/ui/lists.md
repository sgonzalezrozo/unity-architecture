# Lists

Dynamic lists and grids keep the MVC split in every form: a Model owns the items, the list View shows them, and each cell gets its own item instead of having it pushed (`ARCH-04`). How the list is built depends on the package.

> **Fork `list`** · open only the branch the [profile](../OPTIONAL_PACKAGES.md#the-profile) names:
> - `ui-scroller`: [UI Scroller lists](../branches/ui-scroller/lists.md)
> - `no-ui-scroller`: [Lists without UI Scroller](../branches/no-ui-scroller/lists.md)

Tabs that filter one list need no separate prefabs: see [Filtered list](../examples/03_FILTERED_LIST_INVENTORY.md).
