# Git y PRs

- `develop` es la rama de integración. `main` solo se actualiza desde `release/*`.
- Ramas: `feature/{nombre}`, `bugfix/{nombre}`, `release/{versión}`.
- Un PR = una feature o un fix. Un PR de feature toca su carpeta y su installer.
- Mensajes que describen el cambio: `Add trophy details timer`.
- El PR dice qué cambió, por qué, cómo se probó y si rompe algo.
- Al menos una aprobación y CI verde antes de mergear.
