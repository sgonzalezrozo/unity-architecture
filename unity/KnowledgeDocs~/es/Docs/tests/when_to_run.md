# Cuándo corren los tests

> [!RULE] TEST-11
> Antes de terminar un cambio corren los tests **relacionados**: los de las clases cambiadas o añadidas y los de quien las usa. El Stop hook corre los tests de las features de la tarea en cada stop, y la suite completa como mucho cada dos horas (cada 24 horas mientras la tarea está acotada a features).

> [!RULE] TEST-10
> Una pantalla nueva pasa un **check en Play mode**: abre, su input principal funciona y la Consola no tiene errores.

> [!RULE] TEST-12
> Todo prefab bajo `Assets/Client` pasa el validador de prefabs. Tiene un caso por feature, así que un prefab cambiado solo comprueba su feature.

> [!RULE] TEST-13
> Con la pregunta de alcance, el agente pregunta a qué **carpeta de feature** se acotan los tests de la tarea, o si es todo el proyecto, y lo escribe en `Logs/verify/test-scope`. Para saltar la pregunta, nómbrala en el prompt: `tests: Assets/Client/Inventory`. El hook siempre testea también cada feature que tocó el cambio.
