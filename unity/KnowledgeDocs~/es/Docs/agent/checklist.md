# Checklist antes de responder

- [ ] ¿Algún Model conoce una View, un Controller o un componente de Unity?
- [ ] ¿Alguna View recibe input, llama comandos o conoce un servicio? ¿Una inner View lee el Model? ¿Más de 5 campos serializados?
- [ ] ¿Algún Controller cambia algo visual, guarda reglas o serializa referencias?
- [ ] ¿Algún evento tiene parámetros? ¿Se empuja algo que podría pedirse?
- [ ] ¿Hay `Button`, `Toggle`, `Slider`, `Dropdown`, `onClick` o `Initialize(model)`? ¿Se usa un package que no está?
- [ ] ¿Campos inyectados `internal` y sin atributo; el resto `private`?
- [ ] ¿Cada archivo en su carpeta, arte fuente fuera de la feature?
- [ ] ¿Lambdas, LINQ, `var`, `?.` en Unity, `///` en miembros, texto hardcodeado?
- [ ] ¿Podría haberlo decidido una herramienta? ¿Un Model lee tiempo o azar directo?
- [ ] ¿Todo lo testeable cubierto, con tests de Model primero? Sin tests en el alcance, ¿sigue siendo testeable y se listan los tests que faltan?
- [ ] ¿Model y View en la raíz de su scope?
- [ ] ¿Ciclos entre Models? ¿Model con campos serializados?
- [ ] ¿Es lo mínimo, sin abstracciones sin uso?
- [ ] ¿Una herramienta verificó compilación, analyzers, tests y generación?
