---
name: publish-post
description: Use when running /publish-post <búsqueda> or asked to publish, convert, or export a vault note to the blog. Searches the vault for the note, adapts content for blog format, generates a cover image via Cloudflare Workers AI, and creates the draft post file in the blog repository.
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
- Eliminar wikilinks `[[nombre-de-archivo]]` cuyo destino es un nombre interno del vault; conservar solo si el alias es una frase legible en prosa (ej: `[[algoritmos|algoritmos de búsqueda]]` → "algoritmos de búsqueda")

### 4. CP2 — Aprobar frontmatter

Genera el frontmatter del post con estas reglas:
- `title`: derivado del título de la nota, máximo 60 caracteres
- `description`: 1–2 oraciones resumen generadas por Claude
- `publishDate`: fecha de hoy en formato `YYYY-MM-DD`
- `tags`: derivados de las tags de la nota original en el vault
- `draft`: siempre `true`
- `slug` (solo para construir el nombre del archivo, no va en el frontmatter): kebab-case del título, sin fecha
- Nombre del archivo de salida: `YYYY-MM-DD-{slug}.md`
- `coverImage.src`: `../../assets/images/YYYY-MM-DD-{slug}.png`
- `coverImage.alt`: igual que `title`

Preséntalo en bloque YAML y pregunta:
> "¿Ajusto algo antes de continuar?"

### 5. CP3 — Aprobar borrador de contenido

Muestra el borrador completo (sin frontmatter) y pregunta:
> "Este es el borrador adaptado del post. ¿Ajusto algo antes de generar la imagen y escribir el archivo?"

Si el usuario pide cambios: aplícalos y muestra el borrador de nuevo.

### 6. Generar imagen de portada

**Requiere variables de entorno:** `CLOUDFLARE_ACCOUNT_ID` y `CLOUDFLARE_API_TOKEN`.
Si alguna no está configurada, informa al usuario y salta directamente a "Si la generación de imagen falla".

**Verificar variables:**
```bash
[ -z "$CLOUDFLARE_ACCOUNT_ID" ] || [ -z "$CLOUDFLARE_API_TOKEN" ] && \
  { echo "Error: faltan CLOUDFLARE_ACCOUNT_ID o CLOUDFLARE_API_TOKEN"; IMAGEN_FALLIDA=true; }
```

**Construir el prompt** (en inglés, usando objetos físicos concretos que evoquen el tema):
```
[1-2 concrete physical objects or a simple scene that suggests the post's theme].
Soft natural light. Minimalist, editorial style, muted colors, no text.
```

Regla crítica: **no uses conceptos abstractos** (graphs, networks, nodes, connections, systems, AI, code) — los modelos los convierten en imágenes sin sentido. En su lugar, elige objetos tangibles: una mesa de trabajo, un cuaderno, una planta, una taza de café, una ventana. El objeto debe evocar el tema, no representarlo literalmente.

**Generar y descargar la imagen:**
```bash
curl -X POST "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/ai/run/@cf/stabilityai/stable-diffusion-xl-base-1.0" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"prompt\": \"AQUÍ_VA_EL_PROMPT_CONSTRUIDO\"}" \
  --output /tmp/YYYY-MM-DD-{slug}.png
```
Donde `AQUÍ_VA_EL_PROMPT_CONSTRUIDO` es el prompt literal que construiste arriba.

**Verificar que la imagen se generó correctamente:**
Inmediatamente después del curl, verifica que el archivo existe y no está vacío:
```bash
[ -s /tmp/YYYY-MM-DD-{slug}.png ] || { echo "Imagen no generada o vacía"; IMAGEN_FALLIDA=true; }
```
Si `IMAGEN_FALLIDA=true`, salta a "Si la generación de imagen falla" al final de este paso. De lo contrario, continúa.

**Mover al directorio de imágenes del blog:**
```bash
mv /tmp/YYYY-MM-DD-{slug}.png \
  /home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/assets/images/YYYY-MM-DD-{slug}.png
```

**Optimizar la imagen** (si falla, continuar con la imagen sin optimizar):
```bash
/home/carlos-ardila/Documents/gitprojects/blogcardila/optimizar.sh \
  /home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/assets/images/YYYY-MM-DD-{slug}.png || \
  echo "Advertencia: optimizar.sh falló — se usará la imagen sin optimizar"
```

**Borrar el backup si fue creado:**
```bash
rm -f /home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/assets/images/YYYY-MM-DD-{slug}.png.backup
```

**Si la generación de imagen falla** (variables no configuradas, curl retorna error, timeout, o archivo vacío):
Si `IMAGEN_FALLIDA=true`:
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
  src: "../../assets/images/YYYY-MM-DD-{slug}.png"
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
