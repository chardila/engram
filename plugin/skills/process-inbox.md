# Skill: Procesar inbox (/process-inbox)

## Qué leer primero
1. `Inbox/YYYY-MM-DD.md` — sección `## Loops abiertos`

## Qué hacer por cada item
Decidir destino:
- **`Projects/`** — si es un proyecto accionable o tarea con múltiples pasos
- **`Projects/dev/`** — si es una tarea de desarrollo (incluir links a PRs/commits si aplica)
- **`Areas/`** — si actualiza una responsabilidad continua
- **`Resources/concepts/`** — si es un concepto técnico o personal que merece nota atómica
- **Tarea descartable** — si es accionable en menos de 2 minutos (crear tarea inline sin nota)

Para cada nota creada, incluir frontmatter:
```yaml
---
created: YYYY-MM-DD
tags: [tema, area]
status: active
related: [[Area correspondiente]]
author: claude
---
```

Para `Projects/`: campo `related` apuntando a al menos un Area y notas de concepto relevantes.
Para `Resources/concepts/`: crear nota atómica (una idea por archivo) y enlazar desde el MOC.
Convertir items accionables en tareas con sintaxis Tasks:
```
- [ ] tarea 📅 YYYY-MM-DD #tag
```

## Qué actualizar
- Marcar items procesados en la nota diaria
- MOC correspondiente en `Resources/` si se crearon notas de concepto nuevas

## Notas
- `## Señales débiles` no se procesa automáticamente — solo si el usuario lo pide explícitamente
- No crear notas para items que son solo recordatorios fugaces
