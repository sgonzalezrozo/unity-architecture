# Comentarios y textos

> [!DONT] Comentarios `///` en miembros
> Métodos, propiedades, campos, eventos y valores de enum **no** llevan `///`. El analyzer `UA0015` falla el build.

> [!DO]
> Un `///` corto en una **clase** o tipo sí vale. Otros comentarios, solo para lo que el código no puede explicar (un bug del motor, una dependencia de orden).

> [!RULE] Textos de usuario
> Nada de texto hardcodeado: usa el sistema de localización. Sin él, el texto va en inglés hasta que exista (`DATA-01`).

Borra usings, código y código comentado que no se use.
