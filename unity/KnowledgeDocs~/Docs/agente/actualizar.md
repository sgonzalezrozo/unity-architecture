# Actualizar las reglas

```bash
bash .ai/templates/scripts/update.sh
```

Actualiza `.ai`, refresca los archivos copiados que no cambiaste y lista los que sí. Después pide:

```text
The .ai rules were updated. Read .ai/CHANGELOG.md and tell me what changed that affects this project's code.
```

> [!WARNING]
> Nunca edites archivos dentro de `.ai`: la siguiente actualización los sobrescribe. Lo propio del proyecto va en el `AGENTS.md` raíz.
