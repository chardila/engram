# Spec: skill `engram:publish-post`

**Fecha:** 2026-06-10  
**Estado:** aprobado por usuario  
**Repositorio:** engram (`skills/publish-post/SKILL.md`)

---

## Objetivo

Agregar a engram un skill `/publish-post <búsqueda>` que convierta una nota del vault (Source, concepto, o draft libre) en un post listo para revisar en el blog personal (Astro Cactus).

---

## Contexto

- El vault ya tiene flujo de entrada: `/ingest-url` ingesta URLs como notas en `Sources/`
- Este skill completa el ciclo: vault → blog
- Blog: Astro Cactus en `blogcardila/blog/src/content/post/`
- Meta trimestral activa: publicar al menos 4 posts en el blog (Q3 2026)

---

## Flujo general

```
/publish-post <búsqueda>
        │
        ▼
  Buscar nota en vault (search_simple)
        │
        ▼
┌─────────────────────────┐
│  CP1: Confirmar nota     │
└─────────────────────────┘
        │ sí
        ▼
  Claude adapta contenido
  (intro + desarrollo + cierre, corrección ortografía/redacción)
        │
        ▼
┌─────────────────────────┐
│  CP2: Frontmatter        │
└─────────────────────────┘
        │ aprobado
        ▼
┌─────────────────────────┐
│  CP3: Borrador completo  │
└─────────────────────────┘
        │ aprobado
        ▼
  Generar imagen (Pollinations.ai)
  Guardar → blog/src/assets/images/
  Optimizar → optimizar.sh
  Borrar backup
        │
        ▼
  Escribir blog/src/content/post/YYYY-MM-DD-{slug}.md
        │
        ▼
  Confirmación final
```

---

## Sección 1: Búsqueda y CP1

### Búsqueda
- Usar `mcp__brain-personal__search_simple` con el término que escribe el usuario
- Si hay múltiples resultados: mostrar los 3 más relevantes numerados, pedir al usuario que elija
- Si no hay resultados: informar y terminar ejecución
- Mostrar de la nota encontrada: título, ruta en vault, primeras 5–8 líneas de contenido

### CP1 — texto
> "Encontré esta nota: **[título]** (`[ruta]`)
> [primeras líneas...]
> ¿Es esta la nota que quieres publicar?"

Si el usuario dice no: preguntar si quiere intentar con otro término.

---

## Sección 2: Frontmatter (CP2)

### Campos

| Campo | Regla |
|-------|-------|
| `title` | Derivado del título de la nota, máximo 60 caracteres |
| `description` | 1–2 oraciones resumen generadas por Claude |
| `publishDate` | Fecha de hoy (`YYYY-MM-DD`) |
| `tags` | Derivados de las tags de la nota original en el vault |
| `draft` | Siempre `true` |
| `coverImage.src` | `../../assets/images/YYYY-MM-DD-{slug}.jpg` |
| `coverImage.alt` | Igual que `title` |

El slug se deriva del título en kebab-case (sin fecha; la fecha va en el nombre del archivo).  
El nombre del archivo: `YYYY-MM-DD-{slug}.md`.

### CP2 — texto
Presentar el frontmatter en bloque YAML y preguntar:
> "¿Ajusto algo antes de continuar?"

---

## Sección 3: Adaptación de contenido (CP3)

### Estructura del post
1. **Introducción** — por qué escribes esto, qué encontraste, qué espera el lector
2. **Desarrollo** — ideas clave de la nota original, reorganizadas con fluidez narrativa
3. **Cierre** — conclusión o reflexión personal

### Reglas de adaptación
- Preservar la voz del autor: reorganizar y pulir, no reescribir
- Corregir errores de ortografía y gramática
- Eliminar estructura de vault (frontmatter, secciones "Ideas clave", "Citas relevantes") — convertir a prosa
- Integrar citas originales como blockquotes `>`
- Eliminar wikilinks que se verían raros en el blog; mantener los que tienen texto natural

### CP3 — texto
> "Este es el borrador adaptado del post. ¿Ajusto algo antes de generar la imagen y escribir el archivo?"

---

## Sección 4: Generación de imagen

### API: Pollinations.ai
```
GET https://image.pollinations.ai/prompt/{prompt_codificado}?width=1200&height=630&model=flux&nologo=true
```
- Sin autenticación, completamente gratuito
- Dimensiones 1200×630 (ratio estándar Open Graph / cover de blog)

### Construcción del prompt
```
Minimalist editorial illustration for a blog post titled "{title}".
{1-2 sentences capturing the main theme}.
Clean composition, modern style, no text.
```

### Flujo técnico
1. `curl -L -o /tmp/YYYY-MM-DD-{slug}.jpg "{url_pollinations}"`
2. Mover a `blog/src/assets/images/YYYY-MM-DD-{slug}.jpg`
   - Ruta absoluta: `/home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/assets/images/`
3. Ejecutar `/home/carlos-ardila/Documents/gitprojects/blogcardila/optimizar.sh {ruta_absoluta_imagen}`
4. Borrar backup si existe: `rm -f {ruta_imagen}.backup`
5. Agregar `coverImage` al frontmatter del post

### Manejo de errores
Si Pollinations.ai falla (timeout, error de red):
- Informar al usuario
- Escribir el post igualmente sin campo `coverImage`
- No bloquear la publicación

---

## Sección 5: Escritura del archivo final

### Ruta de salida
```
/home/carlos-ardila/Documents/gitprojects/blogcardila/blog/src/content/post/YYYY-MM-DD-{slug}.md
```

### Formato del archivo
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

> **Nota de implementación:** El path de `coverImage.src` debe ser relativo al archivo del post y compatible con el helper `image()` de Astro. Verificar con un post real durante las pruebas.

### Confirmación final
Mostrar:
- Ruta del archivo creado
- Ruta de la imagen generada (si aplica)
- Recordatorio: cambiar `draft: true` a `draft: false` cuando esté listo para publicar

---

## Fuera del scope (decisiones explícitas)

- El skill **NO** hace `git commit` ni `git push` — control editorial completo en el usuario
- El skill **NO** modifica la nota original en el vault
- El skill **NO** genera imágenes PNG — siempre JPG (compatible con `optimizar.sh`)

---

## Archivos a crear/modificar

| Archivo | Acción |
|---------|--------|
| `skills/publish-post/SKILL.md` | Crear — instrucciones del skill |
| `vault-template/Skills/publish-post.md` | Crear — copia plana para el vault template |
| `README.md` | Modificar — agregar skill a la tabla de comandos |
| `CLAUDE.md` | Modificar — agregar fila en tabla de skills disponibles |
