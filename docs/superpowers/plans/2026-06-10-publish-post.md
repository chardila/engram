# publish-post Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Crear el skill `engram:publish-post` que convierte una nota del vault en un post draft para el blog personal (Astro Cactus), incluyendo generación y optimización automática de imagen de portada.

**Architecture:** Un único `SKILL.md` con instrucciones paso a paso para Claude. El skill busca una nota en el vault via MCP, adapta su contenido al formato de blog, genera una imagen via Pollinations.ai, la optimiza con `optimizar.sh`, y escribe el archivo final en el repositorio del blog. Flujo de 3 checkpoints: confirmar nota → aprobar frontmatter → aprobar borrador de contenido.

**Tech Stack:** MCP brain-personal (búsqueda en vault), Pollinations.ai API (generación de imagen, free, sin API key), ImageMagick + jpegoptim via `optimizar.sh` (optimización de imagen), Astro Cactus content collections schema.

---

## File Map

| Archivo | Acción | Responsabilidad |
|---------|--------|-----------------|
| `skills/publish-post/SKILL.md` | Crear | Instrucciones del skill para Claude Code |
| `vault-template/Skills/publish-post.md` | Crear | Copia de referencia para el vault (Obsidian) |
| `vault-template/CLAUDE.md` | Modificar | Agregar `/publish-post` a la lista de Skills/ |
| `README.md` | Modificar | Agregar fila en tabla "Skills disponibles" |
| `CLAUDE.md` | Modificar | Agregar fila en tabla "Available Skills" |

---

## Task 1: Crear `skills/publish-post/SKILL.md`

**Files:**
- Create: `skills/publish-post/SKILL.md`

- [ ] **Step 1: Crear el directorio del skill**

```bash
mkdir -p skills/publish-post
```

- [ ] **Step 2: Escribir el SKILL.md**

Crear `skills/publish-post/SKILL.md` con este contenido exacto:

````markdown
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
````

- [ ] **Step 3: Verificar que el archivo fue creado correctamente**

```bash
ls -la skills/publish-post/SKILL.md
head -5 skills/publish-post/SKILL.md
```

Resultado esperado: archivo existente, primera línea `---`, segunda línea `name: publish-post`.

- [ ] **Step 4: Commit**

```bash
git add skills/publish-post/SKILL.md
git commit -m "feat: agregar skill engram:publish-post"
```

---

## Task 2: Crear `vault-template/Skills/publish-post.md`

**Files:**
- Create: `vault-template/Skills/publish-post.md`

- [ ] **Step 1: Copiar el SKILL.md al vault template**

```bash
cp skills/publish-post/SKILL.md vault-template/Skills/publish-post.md
```

- [ ] **Step 2: Verificar que la copia es idéntica**

```bash
diff skills/publish-post/SKILL.md vault-template/Skills/publish-post.md
```

Resultado esperado: sin diferencias (salida vacía).

- [ ] **Step 3: Commit**

```bash
git add vault-template/Skills/publish-post.md
git commit -m "feat: agregar copia plana de publish-post en vault-template"
```

---

## Task 3: Actualizar documentación

**Files:**
- Modify: `vault-template/CLAUDE.md`
- Modify: `README.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Actualizar `vault-template/CLAUDE.md`**

Localizar la línea que lista los skills en la sección `Skills/`:
```
- `Skills/` — instrucciones paso a paso para flujos recurrentes (`/daily-prep`, `/end-day`, `/process-inbox`, `/review-week`, `/analyze-vault`, `/review-system`, `/ingest-url`)
```

Reemplazar por:
```
- `Skills/` — instrucciones paso a paso para flujos recurrentes (`/daily-prep`, `/end-day`, `/process-inbox`, `/review-week`, `/analyze-vault`, `/review-system`, `/ingest-url`, `/publish-post`)
```

- [ ] **Step 2: Actualizar `README.md`**

Localizar el final de la tabla "Skills disponibles":
```
| `/ingest-url <url>` | Ingesta una URL: crea nota en Sources/, extrae conceptos a Resources/, actualiza MOCs y cross-links |
```

Agregar fila después:
```
| `/publish-post <búsqueda>` | Publica una nota del vault como post en el blog: adapta contenido, genera imagen de portada, escribe draft en el repositorio del blog |
```

- [ ] **Step 3: Actualizar `CLAUDE.md`**

Localizar el final de la tabla "Available Skills":
```
| `/ingest-url <url>` | Ingest a URL: creates note in Sources/, extracts concepts to Resources/, updates MOCs and cross-links |
```

Agregar fila después:
```
| `/publish-post <búsqueda>` | Publish a vault note as a blog post: adapts content, generates cover image, writes draft to blog repository |
```

- [ ] **Step 4: Verificar los tres archivos**

```bash
grep "publish-post" vault-template/CLAUDE.md README.md CLAUDE.md
```

Resultado esperado: una línea con `publish-post` en cada archivo (3 líneas total).

- [ ] **Step 5: Commit**

```bash
git add vault-template/CLAUDE.md README.md CLAUDE.md
git commit -m "docs: documentar skill /publish-post en README y CLAUDE.md"
```

---

## Task 4: Verificación manual del skill

> Esta tarea no tiene tests automatizados — es verificación manual end-to-end.

**Files:** ninguno nuevo — verificación de lo ya creado.

- [ ] **Step 1: Confirmar que el skill está disponible en Claude Code**

Abrir una nueva sesión de Claude Code en el proyecto engram y verificar que `/publish-post` aparece en la lista de skills disponibles (en el `system-reminder` de sesión).

Si no aparece: verificar que `skills/publish-post/SKILL.md` tiene el frontmatter correcto con `name: publish-post`.

- [ ] **Step 2: Ejecutar el skill con una nota real del vault**

Invocar:
```
/publish-post llm obsidian karpathy
```

(Esta nota existe en `Sources/` del vault — fue ingresada previamente con `/ingest-url`.)

- [ ] **Step 3: Verificar CP1 — nota encontrada correctamente**

Confirmar que el skill muestra:
- Título correcto de la nota
- Ruta en el vault
- Primeras líneas del contenido

- [ ] **Step 4: Verificar CP2 — frontmatter válido**

Confirmar que el frontmatter propuesto:
- `title` tiene ≤ 60 caracteres
- `publishDate` es la fecha de hoy
- `draft: true` presente
- `slug` en kebab-case sin fecha
- `coverImage.src` con el path correcto

- [ ] **Step 5: Verificar CP3 — contenido adaptado**

Confirmar que el borrador:
- Tiene estructura intro / desarrollo / cierre
- No tiene frontmatter YAML ni secciones de vault
- No tiene wikilinks `[[...]]` visibles

- [ ] **Step 6: Verificar imagen generada**

```bash
ls -la /home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/assets/images/
```

Confirmar que:
- Existe el archivo `YYYY-MM-DD-{slug}.jpg`
- No existe el archivo `YYYY-MM-DD-{slug}.jpg.backup`
- El tamaño del archivo es mayor a 0 bytes

- [ ] **Step 7: Verificar el post creado**

```bash
ls -la /home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/content/post/
head -15 /home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/content/post/YYYY-MM-DD-{slug}.md
```

Confirmar que el archivo existe y el frontmatter es válido YAML.

- [ ] **Step 8: Verificar que el post compila con Astro**

```bash
cd /home/carlos-ardila/Documents/gitprojects/blogcardila/blog && npm run build 2>&1 | tail -20
```

Resultado esperado: build sin errores de schema. Si hay error con `coverImage.src`, ajustar el path en el SKILL.md hasta que Astro lo acepte (ver nota en spec sobre verificación del path del helper `image()`).

- [ ] **Step 9: Commit final si hubo ajustes al SKILL.md**

Si el step 8 requirió correcciones al path de `coverImage.src`:
```bash
git add skills/publish-post/SKILL.md vault-template/Skills/publish-post.md
git commit -m "fix: corregir path de coverImage en skill publish-post"
```
