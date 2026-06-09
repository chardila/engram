# /ingest-url Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar la skill `/ingest-url` al plugin engram para capturar artículos externos al vault con resumen estructurado, extracción de conceptos, cross-links y mantenimiento de catálogo/log.

**Architecture:** La skill es un archivo de instrucciones Markdown (`SKILL.md`) que Claude Code carga y ejecuta. No hay código compilado. Las plantillas en `vault-template/Sources/` se copian al crear un vault nuevo. Los archivos actuales del vault se actualizan manualmente en la tarea de prueba.

**Tech Stack:** Markdown, YAML frontmatter, Obsidian wikilinks, Claude Code skill system, WebFetch MCP tool.

---

## File Map

| Archivo | Acción | Responsabilidad |
|---------|--------|-----------------|
| `skills/ingest-url/SKILL.md` | Crear | Instrucciones completas de la skill para Claude |
| `vault-template/Sources/index.md` | Crear | Plantilla inicial del catálogo de fuentes |
| `vault-template/Sources/log.md` | Crear | Plantilla inicial del log de ingestas |
| `vault-template/Skills/ingest-url.md` | Crear | Copia plana de la skill para lectura en Obsidian |
| `README.md` | Modificar | Agregar `/ingest-url` a la tabla de skills |
| `CLAUDE.md` | Modificar | Agregar `/ingest-url` a la tabla de skills |
| `vault-template/CLAUDE.md` | Modificar | Agregar `/ingest-url` a la lista de skills |

---

## Task 1: Crear plantillas Sources/ en vault-template

**Files:**
- Create: `vault-template/Sources/index.md`
- Create: `vault-template/Sources/log.md`

- [ ] **Step 1: Crear vault-template/Sources/index.md**

Contenido exacto:

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
```

- [ ] **Step 2: Crear vault-template/Sources/log.md**

Contenido exacto:

```markdown
---
created: YYYY-MM-DD
tags: [referencias]
status: active
author: claude
---

# Sources — log de ingestas

<!-- Formato de cada entrada:
## [YYYY-MM-DD] ingest | Título del artículo
Fuente: <url>
Conceptos: [[concepto-a]], [[concepto-b]], [[concepto-c]]
-->
```

- [ ] **Step 3: Verificar que los archivos existen**

```bash
ls vault-template/Sources/
```

Esperado: `index.md  log.md`

- [ ] **Step 4: Commit**

```bash
git add vault-template/Sources/
git commit -m "feat: agregar plantillas Sources/ a vault-template"
```

---

## Task 2: Escribir skills/ingest-url/SKILL.md

**Files:**
- Create: `skills/ingest-url/SKILL.md`

- [ ] **Step 1: Crear skills/ingest-url/SKILL.md**

Contenido exacto:

```markdown
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
```

- [ ] **Step 2: Verificar que el archivo existe y tiene frontmatter correcto**

```bash
head -5 skills/ingest-url/SKILL.md
```

Esperado:
```
---
name: ingest-url
description: Use when running /ingest-url <url> or asked to ingest...
```

- [ ] **Step 3: Commit**

```bash
git add skills/ingest-url/SKILL.md
git commit -m "feat: agregar skill /ingest-url"
```

---

## Task 3: Crear copia plana para Obsidian

**Files:**
- Create: `vault-template/Skills/ingest-url.md`

- [ ] **Step 1: Copiar SKILL.md como copia plana**

```bash
cp skills/ingest-url/SKILL.md vault-template/Skills/ingest-url.md
```

- [ ] **Step 2: Verificar**

```bash
ls vault-template/Skills/
```

Esperado: lista que incluye `ingest-url.md` junto a los demás skills.

- [ ] **Step 3: Commit**

```bash
git add vault-template/Skills/ingest-url.md
git commit -m "feat: agregar copia plana de ingest-url para vault-template"
```

---

## Task 4: Actualizar documentación

**Files:**
- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `vault-template/CLAUDE.md`

- [ ] **Step 1: Agregar /ingest-url a la tabla de skills en README.md**

Localizar la tabla:
```markdown
| `/review-system` | Meta-revisión mensual: patrones de uso, fricciones, mejoras al sistema |
```

Agregar debajo:
```markdown
| `/ingest-url <url>` | Ingesta una URL: crea nota en Sources/, extrae conceptos a Resources/, actualiza MOCs y cross-links |
```

- [ ] **Step 2: Agregar /ingest-url a la tabla de skills en CLAUDE.md**

Localizar la tabla:
```markdown
| `/review-system` | Monthly meta-review: usage patterns, friction, system improvements |
```

Agregar debajo:
```markdown
| `/ingest-url <url>` | Ingest a URL: creates note in Sources/, extracts concepts to Resources/, updates MOCs and cross-links |
```

- [ ] **Step 3: Agregar /ingest-url a la lista de skills en vault-template/CLAUDE.md**

Localizar esta línea:
```
- `Skills/` — instrucciones paso a paso para flujos recurrentes (`/daily-prep`, `/end-day`, `/process-inbox`, `/review-week`, `/analyze-vault`, `/review-system`)
```

Reemplazarla por:
```
- `Skills/` — instrucciones paso a paso para flujos recurrentes (`/daily-prep`, `/end-day`, `/process-inbox`, `/review-week`, `/analyze-vault`, `/review-system`, `/ingest-url`)
```

- [ ] **Step 4: Verificar que los tres archivos mencionan ingest-url**

```bash
grep -l "ingest-url" README.md CLAUDE.md vault-template/CLAUDE.md
```

Esperado: los tres archivos listados.

- [ ] **Step 5: Commit**

```bash
git add README.md CLAUDE.md vault-template/CLAUDE.md
git commit -m "docs: documentar skill /ingest-url en README y CLAUDE.md"
```

---

## Task 5: Desplegar y probar

**Files:**
- No new files — verificación de despliegue y prueba funcional

- [ ] **Step 1: Desplegar con setup.sh**

```bash
bash setup.sh chardila brain-personal /home/carlos-ardila/vault/brain-personal
```

Esperado: línea `✓ Plugin instalado en: /home/carlos-ardila/.claude/skills/engram`

- [ ] **Step 2: Verificar que la skill quedó instalada**

```bash
ls ~/.claude/skills/engram/skills/ingest-url/
```

Esperado: `SKILL.md`

- [ ] **Step 3: Crear Sources/ en el vault actual (no usa vault-template porque el vault ya existe)**

Crear manualmente en el vault activo usando el MCP brain-personal:
- `Sources/index.md` con el contenido de la plantilla
- `Sources/log.md` con el contenido de la plantilla

- [ ] **Step 4: Probar /ingest-url con el artículo de referencia**

En una nueva sesión de Claude Code, ejecutar:
```
/ingest-url https://aimaker.substack.com/p/llm-wiki-obsidian-knowledge-base-andrej-karphaty
```

Verificar que la skill:
1. Crea `Sources/llm-wiki-obsidian-karpathy.md` (o slug similar) con las secciones correctas
2. Hace el checkpoint mostrando la lista de conceptos antes de continuar
3. Tras aprobación, crea notas en `Resources/concepts/`
4. Agrega cross-links entre conceptos relacionados
5. Actualiza `Resources/moc-ai-tools.md`
6. Actualiza `Sources/index.md` con la nueva fila
7. Agrega entrada a `Sources/log.md`

- [ ] **Step 5: Si se ajustó el SKILL.md durante la prueba, commit los ajustes**

```bash
git add skills/ingest-url/SKILL.md vault-template/Skills/ingest-url.md
git commit -m "fix: ajustes al skill /ingest-url tras prueba en vault real"
```
