# SOLID and duplication

- **One responsibility** per class.
- Depend on interfaces **at boundaries**: HTTP, files and SDKs behind an interface we own, as Connectors do.
- Composition over inheritance. A base class never checks for its derived types.
- Polymorphism over a `switch` on type. A `switch` expression for a simple mapping is fine.
- `private` by default; `{ get; private set; }` over public setters.

> [!RULE] Duplication
> A second copy of a rule or calculation **is extracted**. Repeated structure (a View's subscribe pattern) is fine.

> [!NOTE]
> No speculative abstraction (`ARCH-10`).
