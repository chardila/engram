# Skill: Revisión semanal (/review-week)

## Qué leer primero
1. Notas diarias de la semana (`Inbox/YYYY-MM-DD.md` × 5–7)
2. Proyectos activos en `Projects/` (incluyendo `Projects/dev/`)
3. Logs de sesión de la semana en `AI/sessions/`

## Qué generar (derivar, luego mostrar para aprobación)

### `Journal/YYYY-WW.md`
Inferir de notas diarias y logs:
- Resumen de lo completado (tareas ✅ y logs de sesión)
- Loops abiertos que siguen pendientes (`## Loops abiertos` sin procesar)
- Prioridades para la semana siguiente (tareas abiertas en `Projects/`)

Estructura:
```markdown
---
created: YYYY-MM-DD
tags: [weekly-review]
author: claude
---

# Semana YYYY-WW

## Completado esta semana
- ...

## Loops abiertos pendientes
- ...

## Prioridades semana siguiente
- ...
```

### `STATE.md`
Regenerar completo igual que `/end-day`, pero con vista de semana completa.

## Flujo
1. Presenta `Journal/YYYY-WW.md` → "¿Corrijo o apruebo?"
2. Escribe journal aprobado
3. Presenta `STATE.md` regenerado → "¿Corrijo o apruebo?"
4. Escribe `STATE.md` aprobado
5. Actualiza MOCs relevantes con nuevos enlaces surgidos durante la semana
6. Actualiza `Areas/` si cambió algo en alguna área continua durante la semana
