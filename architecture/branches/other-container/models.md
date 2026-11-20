# Another container: injected Models

Branch `other-container` of the `container` fork. Read it only when the [profile](../../OPTIONAL_PACKAGES.md#the-profile) says `container: other-container`: the project uses a container other than Fast IoC, such as VContainer or Zenject.

- A Model in row 2 or 3 of [Where a Model lives](../../mvc/where-a-model-lives.md) is created by that container and reaches Views and Controllers the way that container injects. Read how existing features do it; ask if there is no precedent.
- The general rules still apply: [`DI-02` to `DI-08`](../../DEPENDENCY_INJECTION.md#rules), `ROOT-06`, and no singletons (`ROOT-07`).
- Bindings go in that container's installers: one per feature, in `Services/`, named `{Feature}Installer`.
- Components that need services are injected through Tools Core: VContainer with `builder.UseToolsCore()`, Zenject with `ToolsCoreInstaller` (`SCR-11` with `screenSystem`).
- A configuration asset for a Model is bound in the container and injected (`MODEL-10`).
