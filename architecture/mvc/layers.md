# Layers

## Layer definitions

| Term | Definition |
|---|---|
| **Model** | Class that owns state and business rules. See [Where a Model lives](where-a-model-lives.md#where-a-model-lives) |
| **Outside-MVC Model** | Model created by the container that no View or Controller uses |
| **Module** | Model that wraps a feature's backend access. See [Backend integration](../BACKEND_INTEGRATION.md) |
| **Slot Model** | MonoBehaviour Model on a list slot prefab |
| **Connector** | Stateless class that performs backend calls |
| **View** | MonoBehaviour that reads Models and renders |
| **Controller** | MonoBehaviour that converts one input into one Model command |
| **Query** | Read-only member. Changes no state |
| **Command** | Method that changes state. Validates its own input |
| **Config value** | Enum or number serialized on a View or Controller that selects behavior. Never a component or Model reference |
| **Configuration asset** | `ScriptableObject` with serialized values, read by a Model |
| **Scope** | Self-contained part of a feature with one root GameObject. See [Scopes](scopes.md#scopes) |

## Dependency matrix

| Layer | Models | Connector | Rendering components | Input interfaces | Views | Controllers |
|---|---|---|---|---|---|---|
| **Model** | Yes | Module only | No | No | No | No |
| **View** | Yes | No | Yes | No | No | No |
| **Controller** | Yes | No | No | Yes | No | No |

A Model MAY also reference a configuration asset (`MODEL-10`).
