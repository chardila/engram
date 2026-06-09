---
name: ingest-url
description: Use when running /ingest-url <url> or asked to ingest, save, or process a URL into the vault. Reads the URL, creates a structured source note in Sources/, extracts concepts to Resources/concepts/, updates MOCs and cross-links, maintains Sources/index.md and Sources/log.md.
---

# Skill: Ingestar URL (/ingest-url <url>)

## Pasos

### 1. Leer la URL
Usa WebFetch para leer el contenido completo de la URL.
Si WebFetch falla (URL inaccesible, paywall, error de red), informa al usuario y detén la ejecución.

### 2. Crear Sources/<slug>.md (inmutable)
- El slug = título del artículo en kebab-case (ej: `llm-wiki-obsidian-karpathy`)
- Si el archivo ya existe en Sources/, informa al usuario y detén la ejecución. No sobreescribir.
- Usar este formato:

~~~markdown
---
created: YYYY-MM-DD
tags: [referencias, <tema>]
status: active
author: claude
source: <url>
---

# Título del artículo

**Fuente:** [título](url)
**Fecha de ingesta:** YYYY-MM-DD

## Contexto
Una o dos líneas sobre el autor, publicación, por qué importa.

## Ideas clave
1. ...
2. ...

## Citas relevantes
> ...

## Conceptos extraídos
[[concepto-a]], [[concepto-b]], [[concepto-c]]
~~~

### 3. Checkpoint — esperar aprobación del usuario
Muestra la nota de fuente recién creada y propón una lista de **máximo 5 conceptos** a extraer a `Resources/concepts/`.
Pregunta: "¿Ajusto algún concepto antes de continuar?"
No continuar hasta recibir respuesta.

### 4. Procesar conceptos aprobados
Para cada concepto de la lista aprobada:

**4a. Crear o actualizar Resources/concepts/<concepto>.md**
- Si no existe: crear con frontmatter + estas secciones:
  - `## ¿Qué es?`
  - `## ¿Por qué importa?`
  - `## Cómo se relaciona con mi trabajo`
  - `## Referencias` — incluir link a la fuente recién ingresada
- Si ya existe: agregar información nueva sin duplicar. Agregar link a la fuente en `## Referencias`.

**4b. Agregar wikilinks cruzados**
- Buscar en `Resources/concepts/` notas existentes conceptualmente relacionadas con el concepto nuevo.
- En la nota nueva/actualizada: agregar `[[wikilinks]]` a conceptos relacionados en la sección correspondiente.
- En las notas relacionadas existentes: agregar `[[wikilink]]` al concepto nuevo si aplica y no está ya.

**4c. Actualizar Resources/moc-*.md correspondiente**
- Identificar el MOC más relevante según el tema del artículo (ej: moc-ai-tools.md para artículos de IA).
- Agregar link al nuevo concepto bajo la sección apropiada del MOC.

### 5. Actualizar Sources/index.md
Agregar una fila al final de la tabla:
```
| [[slug]] | YYYY-MM-DD | [[concepto-a]], [[concepto-b]] |
```
Si `Sources/index.md` no existe en el vault, crearlo con la plantilla antes de agregar la fila.

### 6. Append a Sources/log.md
Agregar al final del archivo:
```
## [YYYY-MM-DD] ingest | Título del artículo
Fuente: <url>
Conceptos: [[concepto-a]], [[concepto-b]], [[concepto-c]]
```
Si `Sources/log.md` no existe en el vault, crearlo con la plantilla antes de agregar la entrada.

## Reglas
- `Sources/<slug>.md` es inmutable después de crearse — nunca modificar.
- Máximo 5 conceptos por ingesta para evitar ruido en `Resources/concepts/`.
- Si un concepto ya existe en `Resources/concepts/`, actualizar en vez de crear nota nueva.
- `author: claude` en todos los archivos generados por esta skill.
- El checkpoint del paso 3 es obligatorio — nunca saltarlo.
- Responder en español.
