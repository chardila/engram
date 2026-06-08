# Skill: Revisión diaria — cierre de sesión (/end-day)

## Qué leer primero
1. Nota diaria de hoy (`Inbox/YYYY-MM-DD.md`)
2. `Projects/` — tareas completadas o actualizadas hoy

## Flujo (el orden importa — el usuario sintetiza primero)

### Paso 1: síntesis del usuario
Preguntar: "¿Qué aprendiste hoy y qué decidiste?"
Esperar respuesta libre (2–4 oraciones). No sugerir ni estructurar antes de que el usuario escriba.

### Paso 2: complemento de Claude → `AI/sessions/YYYY-MM-DD-HH.md`
Añadir contexto técnico inferido de la conversación:
- Acciones realizadas (tareas cerradas, notas creadas)
- Decisiones tomadas no explícitas en la respuesta del usuario
- Prioridad para mañana (tarea más urgente en `Projects/`)
- ¿Nuevo skill? si se repitió un flujo manual por segunda vez

Estructura del log:
```markdown
---
created: YYYY-MM-DD
tags: [session-log]
author: claude
---

## Síntesis del usuario
<!-- author: user -->
[Respuesta literal del usuario]

## Complemento de Claude
<!-- author: claude -->
### Acciones realizadas
- ...

### Decisiones no explícitas
- ...

### Prioridad para mañana
- ...

### ¿Nuevo skill?
- ...
```

### Paso 3: STATE.md
Regenerar secciones derivadas (`## Activo ahora`, `## En pausa`, `## Próximas prioridades`) desde `Projects/`.
**No tocar `## Hechos duros`** — solo edición manual.
Si está desactualizado (>3 días), señalarlo.
Presentar STATE.md regenerado → "¿Corrijo o apruebo?"

### Paso 4: cerrar
Solo tras aprobación:
- Escribir log en `AI/sessions/`
- Actualizar `## Agent Log` en la nota diaria
- Escribir `STATE.md` aprobado
