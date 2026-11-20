# Determinism and working in Unity

## Determinism

Agent output varies between runs. A deterministic tool gives the same result every time, so it MUST carry the work whenever it can.

| ID | Rule |
|---|---|
| `DET-01` | If a compiler, analyzer, test, script or generator can decide something, the agent MUST use that tool and MUST NOT rely on its own judgment. |
| `DET-02` | A claim about code MUST come from a tool result, not from memory. If no tool can check it, report it as unverified. |
| `DET-03` | Mechanical work repeated across files SHOULD become a script or generator, and the output SHOULD be reproducible. |
| `DET-04` | For the maintainers of these rules: a rule that can be checked mechanically SHOULD become an analyzer or a test, not only a sentence in a document. An agent on a feature task doesn't write analyzers (`TASK-03`). |
| `DET-05` | Runtime logic MUST be reproducible: the same state and input produce the same result. |
| `DET-06` | Models MUST NOT read time, randomness or external state directly. They MUST receive them through an interface, so tests control them. See [the example](../examples/01_BACKEND_FEATURE_TROPHY_ROOM.md#services). |
| `DET-07` | Logic MUST NOT depend on undefined order, such as `Dictionary` enumeration order or the Unity `Awake` order of unrelated objects. |

## Working in Unity

- Do not hand-edit `.prefab`, `.unity`, `.asset` or `.meta` files (`EDIT-06`). Describe the hierarchy with the [notation](../FEATURE_STRUCTURE.md#screen-composition), plus the Inspector steps for the developer. With an editor bridge, you MAY also build it through editor tools (`EDIT-05`).
- Verify with the tools in [Editor tools](../EDITOR_TOOLS.md), in its [verification order](../EDITOR_TOOLS.md#verification-order).
- Unity generates `.meta` files. A moved file must move with its `.meta`.
- Do not change generated code or external packages.
- Never rename serialized fields without `[FormerlySerializedAs]`.
- Stay within the agreed scope. Mention other problems you notice, but do not fix them unasked.
