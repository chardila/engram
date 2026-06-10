---
name: publish-post
description: Use when running /publish-post <búsqueda> or asked to publish, convert, or export a vault note to the blog. Searches the vault for the note, adapts content for blog format, generates a cover image via Pollinations.ai, and creates the draft post file in the blog repository.
---

# Skill: Publicar post en el blog (/publish-post <búsqueda>)

## Rutas
- Posts del blog: `/home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/content/post/`
- Imágenes del blog: `/home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/assets/images/`
- Script de optimización: `/home/carlos-ardila/Documents/gitprojects/blogcardila/optimizar.sh`

## Pasos

### 1. Buscar la nota

Usa `mcp__brain-personal__search_simple` con el término que escribió el usuario.

- Si hay múltiples resultados: muestra los 3 más relevantes numerados y pide al usuario que elija cuál.
- Si no hay resultados: informa al usuario y termina la ejecución.

### 2. CP1 — Confirmar nota

Muestra título, ruta en el vault y primeras 5–8 líneas del contenido. Pregunta:

> "Encontré esta nota: **[título]** (`[ruta]`)
> [primeras líneas...]
> ¿Es esta la nota que quieres publicar?"

Si el usuario dice no: pregunta si quiere intentar con otro término de búsqueda.

### 3. Adaptar el contenido

Transforma la nota al formato de post con esta estructura:

1. **Introducción** — por qué escribes esto, qué encontraste o aprendiste, qué espera el lector
2. **Desarrollo** — las ideas clave de la nota, reorganizadas con fluidez narrativa
3. **Cierre** — conclusión o reflexión personal

Reglas:
- Preservar la voz del autor — reorganizar y pulir, no reescribir
- Corregir errores de ortografía y gramática
- Eliminar estructura del vault (frontmatter, secciones "Ideas clave", "Citas relevantes") — convertir a prosa
- Integrar citas originales como blockquotes `>`
- Eliminar wikilinks `[[...]]` que se verían extraños en el blog; conservar los que tienen texto natural

### 4. CP2 — Aprobar frontmatter

Genera el frontmatter del post con estas reglas:
- `title`: derivado del título de la nota, máximo 60 caracteres
- `description`: 1–2 oraciones resumen generadas por Claude
- `publishDate`: fecha de hoy en formato `YYYY-MM-DD`
- `tags`: derivados de las tags de la nota original en el vault
- `draft`: siempre `true`
- `slug`: kebab-case del título (sin fecha; la fecha va en el nombre del archivo)
- Nombre del archivo de salida: `YYYY-MM-DD-{slug}.md`
- `coverImage.src`: `../../assets/images/YYYY-MM-DD-{slug}.jpg`
- `coverImage.alt`: igual que `title`

Preséntalo en bloque YAML y pregunta:
> "¿Ajusto algo antes de continuar?"

### 5. CP3 — Aprobar borrador de contenido

Muestra el borrador completo (sin frontmatter) y pregunta:
> "Este es el borrador adaptado del post. ¿Ajusto algo antes de generar la imagen y escribir el archivo?"

Si el usuario pide cambios: aplícalos y muestra el borrador de nuevo.

### 6. Generar imagen de portada

**Construir el prompt** (en inglés, describe visualmente el tema del post):
```
Minimalist editorial illustration for a blog post titled "[title]".
[1-2 sentences capturing the main theme of the post].
Clean composition, modern style, no text.
```

**Descargar la imagen:**
```bash
curl -L -o /tmp/YYYY-MM-DD-{slug}.jpg \
  "https://image.pollinations.ai/prompt/{prompt_url_encoded}?width=1200&height=630&model=flux&nologo=true"
```

**Mover al directorio de imágenes del blog:**
```bash
mv /tmp/YYYY-MM-DD-{slug}.jpg \
  /home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/assets/images/YYYY-MM-DD-{slug}.jpg
```

**Optimizar la imagen:**
```bash
/home/carlos-ardila/Documents/gitprojects/blogcardila/optimizar.sh \
  /home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/assets/images/YYYY-MM-DD-{slug}.jpg
```

**Borrar el backup si fue creado:**
```bash
rm -f /home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/assets/images/YYYY-MM-DD-{slug}.jpg.backup
```

**Si la generación de imagen falla** (curl retorna error, timeout, archivo vacío):
- Informa al usuario brevemente
- Escribe el post sin campo `coverImage` en el frontmatter
- Continúa con el paso 7 sin interrumpir la publicación

### 7. Escribir el archivo del post

Crea el archivo en:
```
/home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/content/post/YYYY-MM-DD-{slug}.md
```

Con este formato:
```markdown
---
title: "Título del post"
description: "Descripción breve."
publishDate: "YYYY-MM-DD"
tags: [tag1, tag2]
draft: true
coverImage:
  src: "../../assets/images/YYYY-MM-DD-{slug}.jpg"
  alt: "Título del post"
---

[contenido adaptado]
```

### 8. Confirmación final

Muestra:
- Ruta del archivo del post creado
- Ruta de la imagen generada (si aplica)

Recuerda al usuario:
> "Post guardado como draft en `[ruta]`. Cuando esté listo para publicar, cambia `draft: true` a `draft: false` en el frontmatter."

## Reglas
- El skill nunca hace `git commit` ni `git push` — el control editorial es del usuario
- El skill nunca modifica la nota original en el vault
- `draft: true` siempre en el frontmatter de salida
- Responder en español
