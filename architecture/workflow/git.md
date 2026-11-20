# Git

- `develop` is the integration branch. `main` is updated only from `release/*`.
- Branches: `feature/{name}`, `bugfix/{name}`, `release/{version}`.
- One feature or fix per PR. A feature PR touches its own folder and installer.
- Commit messages describe the change: `Add trophy details timer`.
- PRs state what changed, why, how it was tested, and any breaking change.
- At least one approval, and CI must pass before merging.
