# Diseño: skill `/ingest-url` para engram

**Fecha:** 2026-06-09
**Estado:** aprobado por el usuario

---

## Contexto

El usuario quiere capturar URLs de artículos para leerlos y procesarlos posteriormente, e integrar ese flujo de captura dentro del sistema engram. La inspiración es el patrón "LLM Wiki" (Karpathy): en lugar de RAG puro, el LLM construye y mantiene una wiki estructurada que crece con cada fuente ingresada.

---

## Estructura de archivos nueva en el vault

```
Sources/
  index.md          ← catálogo de todo lo ingresado (actualizado en cada ingesta)
  log.md            ← log append-only cronológico de ingestas
  <slug>.md         ← una nota por artículo (inmutable después de creación)
```

Las carpetas `Resources/concepts/` y `Resources/moc-*.md` ya existen y se siguen usando.

### Archivos nuevos en el repo

```
skills/
  ingest-url/
    SKILL.md
vault-template/
  Skills/
    ingest-url.md   ← copia plana para lectura en Obsidian
  Sources/
    index.md        ← plantilla inicial vacía
    log.md          ← plantilla inicial vacía
```

No se requieren cambios en `setup.sh` — ya copia `skills/` completo.

---

## Flujo de ejecución

```
/ingest-url <url>
```

1. Claude lee la URL con `WebFetch`.
2. Crea `Sources/<slug>.md` con resumen estructurado (inmutable desde este momento).
3. **Checkpoint**: muestra la nota creada y propone lista de conceptos a extraer. Pregunta: "¿Los ajusto?"
4. Usuario aprueba o modifica la lista de conceptos.
5. Para cada concepto aprobado:
   - Crea o actualiza `Resources/concepts/<concepto>.md`
   - Busca notas existentes en `Resources/concepts/` y agrega `[[wikilinks]]` cruzados donde aplique
   - Actualiza el `Resources/moc-*.md` correspondiente
6. Actualiza `Sources/index.md` — agrega fila al catálogo.
7. Append a `Sources/log.md` — entrada con fecha y título.

---

## Formatos

### `Sources/<slug>.md`

```markdown
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
3. ...

## Citas relevantes
> ...

## Conceptos extraídos
[[concepto-a]], [[concepto-b]], [[concepto-c]]
```

### `Sources/index.md`

```markdown
---
created: YYYY-MM-DD
tags: [referencias]
status: active
author: claude
---

# Sources — índice

| Título | Fecha | Conceptos extraídos |
|--------|-------|---------------------|
| [[slug]] | YYYY-MM-DD | [[concepto-a]], [[concepto-b]] |
```

### `Sources/log.md`

```markdown
# Sources — log de ingestas

## [YYYY-MM-DD] ingest | Título del artículo
Fuente: <url>
Conceptos: [[concepto-a]], [[concepto-b]], [[concepto-c]]
```

---

## Reglas del skill

- `Sources/` son inmutables: Claude nunca modifica una nota de fuente después de crearla.
- El slug de la nota = kebab-case del título del artículo.
- Máximo 5 conceptos por ingesta (evitar ruido en `Resources/concepts/`).
- Si un concepto ya existe en `Resources/concepts/`, actualizar en vez de crear nota nueva.
- `author: claude` en todos los archivos generados por la skill.
- El checkpoint (paso 3) es obligatorio — nunca saltarlo.

---

## Integración con el plugin

- Skill registrada en `skills/ingest-url/SKILL.md` siguiendo el mismo formato que `daily-prep`, `process-inbox`, etc.
- Entrada en la tabla de skills del `README.md`.
- Entrada en la tabla de skills del `CLAUDE.md` del plugin.
- Plantillas `Sources/index.md` y `Sources/log.md` agregadas a `vault-template/Sources/`.
- Copia plana `vault-template/Skills/ingest-url.md` para referencia en Obsidian.
- El `setup.sh` no requiere cambios.

---

## Fuera de alcance (esta versión)

- Ingestión en batch de múltiples URLs.
- Queries filing back al vault (respuestas guardadas como notas nuevas).
- CLI tools / búsqueda indexada (qmd).
- Obsidian Web Clipper.
- Modo rápido vs. modo profundo (`/ingest-url deep`).
