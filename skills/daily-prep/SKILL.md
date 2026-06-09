---
name: daily-prep
description: Use when starting the day, running /daily-prep, or asked to plan the day. Reads STATE.md, shows Hechos duros block first, creates daily note in Inbox/, drafts 3-5 priorities from projects and goals.
---

# Skill: Plan del día (/daily-prep)

## Qué leer primero
1. `STATE.md` — mostrar el bloque `## Hechos duros` al usuario ANTES de generar nada
   - Si está vacío o sin editar en más de 3 días, señalarlo como primer punto
2. `Context/metas-anuales.md` y `Context/metas-trimestrales.md`
3. Último log en `AI/sessions/` (ordenado por fecha)
4. `Inbox/YYYY-MM-DD.md` de hoy si existe

## Qué hacer

### Si la nota de hoy NO existe o existe sin prioridades
- Crear `Inbox/YYYY-MM-DD.md` desde `Templates/daily.md` si no existe
- Generar borrador de `## Prioridades del día` (3–5 puntos) derivado de:
  - Tareas con 📅 de hoy o vencidas en `Projects/`
  - `STATE.md ## Próximas prioridades`
  - Metas activas en `Context/`
  - `## Hechos duros` como restricción prioritaria sobre todo lo anterior
- Presentar borrador y preguntar: "¿Ajusto algo?"
- Escribir prioridades en la nota tras aprobación

### Si la nota de hoy YA existe con prioridades
- Mostrar las prioridades actuales tal como están (sin regenerar)
- Preguntar: "¿Ajusto algo?"
- Solo modificar si el usuario pide cambios explícitos

## Notas
- No generar nada antes de mostrar `## Hechos duros`
- Si `## Hechos duros` tiene más de 3 días sin editar, avisar antes de continuar
- Las prioridades de desarrollo van en `Projects/dev/` — no en la nota diaria directamente
