# Decisiones deliberadas

Algunas reglas se apartan de *Clean Code* a propósito. **No las "arregles".**

| Tema | *Clean Code* | Aquí | Por qué |
|---|---|---|---|
| Tell, don't ask | Los objetos hacen el trabajo | Las Views piden al Model | Es el núcleo del diseño |
| Boy scout rule | Mejora lo que tocas | Refactor solo si se pide | Diffs pequeños y de bajo riesgo |
| Excepciones | Excepciones | `Result<T>` o estado para lo esperado | "No hay monedas" no es excepcional |
| Construcción vs uso | Por constructor | `GetComponentInParent` e inyección `internal` | Un MonoBehaviour no tiene constructor |
| Estado global | Evitarlo | Singletons sin contenedor | Con constructor público siguen siendo testeables |
| Legibilidad primero | Optimiza tras medir | Sin LINQ ni lambdas | Los hot paths no necesitan auditoría |
| No duplicar | Quita estructura repetida | Cada View repite el patrón de suscripción | Se escribe bien siempre, sin herencia profunda |
