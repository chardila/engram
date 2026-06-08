# Instrucciones para Claude

## Quién soy
Desarrollador de software independiente. Uso este vault para todo: notas personales,
aprendizaje, tareas personales y tareas de desarrollo.
Lee `Context/` para perfil detallado (metas, valores, preferencias).

## MCP configurado
El vault se accede via MCP filesystem (servidor: nombre del vault, ej: `brain-work`).
Úsalo siempre para leer y escribir notas en el vault.
Todas las tareas — personales y de desarrollo — se gestionan aquí.

## Estructura del vault
- `Context/` — metas anuales/trimestrales, valores, preferencias de trabajo y aprendizaje
- `Skills/` — instrucciones paso a paso para flujos recurrentes (`/daily-prep`, `/end-day`, `/process-inbox`, `/review-week`, `/analyze-vault`, `/review-system`)
- `Inbox/YYYY-MM-DD.md` — nota diaria, punto de entrada
- `Projects/` — proyectos activos (cada uno enlazado a un Area y a `Resources/`)
  - `Projects/dev/` — proyectos de desarrollo; las tareas incluyen links a PRs/commits
- `Areas/` — responsabilidades continuas: salud, finanzas, familia, trabajo, aprendizaje, música
- `Resources/concepts/` — notas atómicas de conceptos técnicos y personales
- `Resources/moc-*.md` — Mapas de Contenido por tema clave
- `Archive/` — proyectos completados
- `AI/sessions/` — logs históricos de sesión
- `Templates/` — plantillas

## Protocolo al iniciar sesión (/daily-prep)
1. Lee `STATE.md` — muestra el bloque `## Hechos duros` al usuario ANTES de generar nada
   - Si `## Hechos duros` está vacío o no ha sido editado desde hace más de 3 días, señalarlo como primer punto
2. Lee `Context/` (metas-anuales.md, metas-trimestrales.md)
3. Lee el último log en `AI/sessions/`
4. Abre/crea la nota diaria `Inbox/YYYY-MM-DD.md`
5. Genera borrador de `## Prioridades del día` (3–5 puntos) usando `## Hechos duros` como restricción prioritaria
6. Presenta → usuario aprueba → escribe

## Protocolo al cerrar sesión (/end-day)
1. Claude pregunta al usuario: "¿Qué aprendiste hoy y qué decidiste?"
   El usuario escribe primero — 2 a 4 oraciones libres, sin estructura.
2. Claude complementa con contexto técnico inferido de la conversación
3. El resultado combinado se escribe en `AI/sessions/YYYY-MM-DD-HH.md`
4. Claude actualiza `## Agent Log` en la nota diaria
5. Regenera `STATE.md` a partir de `Projects/` — no toca `## Hechos duros`
6. Presenta `STATE.md` regenerado → "¿Corrijo o apruebo?"
7. Si hay un patrón repetido que merezca un nuevo skill, lo señala al usuario

## Durante el día
- Capturas rápidas → `## Loops abiertos` de la nota diaria
- Cuando se pida: convierte loops en tareas (Tasks plugin) o en notas de `Projects/Areas/Resources`

## Mapas de Contenido (MOC)
Cada vez que trabajemos un tema, actualiza el MOC correspondiente en `Resources/` con enlaces
a proyectos, áreas, recursos y journal relacionados.

## Tags permitidos (lista cerrada)
`personal`, `estudio`, `finanzas`, `salud`, `proyectos`, `referencias`, `ideas`

## Convenciones
- Nombres de archivo en kebab-case (ej: `clean-code-notas.md`)
- Notas atómicas: una idea por archivo
- Frontmatter YAML en todas las notas (`created`, `tags`, `status`, `related`, `author`)
- `author: user` si el contenido fue escrito o editado sustancialmente por el usuario
- `author: claude` si fue generado por Claude y aprobado sin edición significativa
- `Projects`: campo `related` apuntando a al menos un Area y notas de concepto relevantes
- `Projects`: bloque `## Cierre` escrito por el usuario antes de archivar (no generado por Claude)
- Tareas con sintaxis del Tasks plugin: `- [ ] tarea 📅 fecha #tag`
- Wiki-links `[[nombre-nota]]` para conectar conceptos
- Responde en español
