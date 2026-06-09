# Sistema de Memoria Personal: Obsidian (`engram`)

## Contexto

Setup para un desarrollador solo con máquinas Mac (oficina) + Linux (desarrollo). El objetivo es tener un sistema unificado donde Claude pueda leer y escribir notas y tareas personales en lenguaje natural, con sincronización automática entre las dos máquinas.

El sistema se distribuye como el monorepo `engram`: un plugin de Claude Code (skills + instrucciones) y un template del vault de Obsidian (estructura + ejemplos ficticios comentados). Todo instalable desde un solo repo, reutilizable en ambas máquinas y compartible con otros.

El plugin es genérico — se instala una vez por máquina. Los vaults son instancias independientes: cada uno tiene su propio repo privado, su propio MCP configurado, y su propio contexto. Las instancias son completamente aisladas entre sí; una sesión de Claude opera sobre un solo vault a la vez.

**Por qué "engram":** en neurociencia, un engrama es la huella física que un recuerdo deja en el cerebro — el sustrato material del pensamiento. Lo que Claude escribe en el vault no es un log de actividad: es el registro de cómo se piensa y se decide. El nombre captura eso.

**Objetivo declarado:** optimizar comprensión, no throughput. El vault existe para construir pensamiento propio y registrar lo que se decidió y por qué — no para recuperar información eficientemente. Esta distinción define cuándo Claude genera y cuándo el usuario escribe primero.

**División clara de responsabilidades:**
- Todo — notas personales, estudio, tareas de desarrollo y tareas personales → **Obsidian vault** (instancia `brain-personal` o `brain-work` según el contexto)
- Claude como interfaz unificada via un MCP server
- Una sesión opera sobre un solo vault — los contextos de trabajo y personal son completamente aislados

```
GitHub (fuente de verdad)
├── Repo público "engram"            ← monorepo: plugin + vault-template
│   ├── .claude-plugin/              ← manifiesto del plugin (plugin.json)
│   ├── skills/                      ← skills de Claude Code (fuente de verdad)
│   ├── vault-template/              ← estructura del vault con ejemplos ficticios
│   └── setup.sh                     ← instala plugin, clona vault, configura MCP
├── Repo privado "brain-work"        ← vault instancia trabajo
└── Repo privado "brain-personal"    ← vault instancia personal

Obsidian app (Mac + Linux)
├── Vault trabajo   → Obsidian Git → auto-sync a brain-work cada 5 min
└── Vault personal  → Obsidian Git → auto-sync a brain-personal cada 5 min

Claude Desktop (Mac) + Claude Code (Linux)
├── Plugin engram → provee skills (/daily-prep, /end-day, /process-inbox, /review-week)
├── MCP "brain-work"     → Local REST API with MCP (obsidian-local-rest-api, HTTP :27123)
└── MCP "brain-personal" → Local REST API with MCP (obsidian-local-rest-api, HTTP :27123)
    (cada sesión usa uno solo — completamente aislados)
```

---

## Paso 0: Crear el monorepo `engram`

El monorepo es el artefacto de distribución. Contiene el plugin de Claude Code y el template del vault. De aquí se parte para instalar el sistema en cualquier máquina.

### Estructura

```
engram/
├── README.md                    ← instrucciones de instalación
├── setup.sh                     ← script de setup completo (ver Paso 0b)
├── CLAUDE.md                    ← instrucciones del plugin para Claude Code
├── .claude-plugin/
│   └── plugin.json              ← manifiesto del plugin para Claude Code
├── skills/                      ← fuente de verdad de los skills
│   ├── daily-prep/
│   │   └── SKILL.md             ← /daily-prep
│   ├── end-day/
│   │   └── SKILL.md             ← /end-day
│   ├── process-inbox/
│   │   └── SKILL.md             ← /process-inbox
│   ├── review-week/
│   │   └── SKILL.md             ← /review-week
│   ├── analyze-vault/
│   │   └── SKILL.md             ← /analyze-vault
│   └── review-system/
│       └── SKILL.md             ← /review-system
└── vault-template/              ← template del vault con ejemplos ficticios comentados
    ├── CLAUDE.md                ← instrucciones específicas del vault (ver Paso 3)
    ├── STATE.md
    ├── Context/
    │   ├── metas-anuales.md
    │   ├── metas-trimestrales.md
    │   ├── valores.md
    │   ├── preferencias-de-trabajo.md
    │   └── preferencias-de-aprendizaje.md
    ├── Skills/                  ← copias de skills/*/SKILL.md — setup.sh las copia aquí
    ├── Inbox/
    ├── Projects/dev/
    ├── Areas/
    ├── Resources/concepts/
    ├── Resources/moc-*.md
    ├── Archive/
    ├── AI/sessions/
    ├── Templates/daily.md
    └── Journal/
```

> **Convención:** `skills/*/SKILL.md` es la fuente de verdad. `vault-template/Skills/` son copias planas para referencia en Obsidian. Para actualizar, re-ejecuta `setup.sh` desde el repo actualizado.

### Crear el repo en GitHub

1. Ir a https://github.com/new
2. Nombre: `engram`
3. Visibilidad: **Public** (para compartir) o **Private** (solo para uso personal)
4. Sin README, sin .gitignore — `setup.sh` los genera
5. Crear repositorio

### `plugin.json` (manifiesto del plugin)

```json
{
  "name": "engram",
  "version": "1.0.0",
  "description": "Personal memory system: Obsidian vault + Claude skills",
  "skills": [
    { "name": "daily-prep", "path": "skills/daily-prep.md" },
    { "name": "end-day", "path": "skills/end-day.md" },
    { "name": "process-inbox", "path": "skills/process-inbox.md" },
    { "name": "review-week", "path": "skills/review-week.md" }
  ],
  "claudeMd": "CLAUDE.md"
}
```

---

## Paso 0b: `setup.sh` — Instalación desde cero

Este script configura todo el sistema en una máquina nueva. Requiere: `git`, `node`, `npx`, y acceso SSH a GitHub.

```bash
#!/usr/bin/env bash
set -e

GITHUB_USER="${1:?Uso: setup.sh <tu-usuario-github> <nombre-vault> [ruta-vault]}"
VAULT_NAME="${2:?Uso: setup.sh <tu-usuario-github> <nombre-vault> [ruta-vault]}"
VAULT_PATH="${3:-$HOME/vault/$VAULT_NAME}"
ENGRAM_REPO="git@github.com:$GITHUB_USER/engram.git"
BRAIN_REPO="git@github.com:$GITHUB_USER/$VAULT_NAME.git"

echo "=== engram setup: $VAULT_NAME ==="

# 1. Instalar plugin de Claude Code (solo si no está instalado)
echo "→ Instalando plugin engram..."
claude plugin install "$ENGRAM_REPO"

# 2. Clonar o crear el vault
if git ls-remote "$BRAIN_REPO" &>/dev/null; then
  echo "→ Clonando vault existente desde $VAULT_NAME..."
  git clone "$BRAIN_REPO" "$VAULT_PATH"
else
  echo "→ Creando vault nuevo desde vault-template..."
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  cp -r "$SCRIPT_DIR/vault-template" "$VAULT_PATH"
  # Copiar skills (fuente de verdad: skills/*/SKILL.md)
  for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    cp "$skill_dir/SKILL.md" "$VAULT_PATH/Skills/$(basename "$skill_dir").md"
  done
  cd "$VAULT_PATH"
  git init
  git remote add origin "$BRAIN_REPO"
  git add .
  git commit -m "initial vault setup from engram template"
  git push -u origin main
fi

# 3. Configurar MCP
REST_API_CONFIG="$VAULT_PATH/.obsidian/plugins/obsidian-local-rest-api/data.json"
echo "→ Configurando MCP server..."
if [[ -f "$REST_API_CONFIG" ]]; then
  API_KEY=$(python3 -c "import json; print(json.load(open('$REST_API_CONFIG'))['apiKey'])" 2>/dev/null || echo "")
fi
if [[ -n "${API_KEY:-}" ]]; then
  claude mcp add "$VAULT_NAME" -s user \
    --type http \
    --header "Authorization: Bearer $API_KEY" \
    "http://127.0.0.1:27123/mcp"
else
  echo "  ⚠ Obsidian aún no inició el plugin — pasos manuales en README.md"
fi

echo ""
echo "=== Listo ==="
echo "Vault: $VAULT_NAME en $VAULT_PATH"
```

> **Nota:** El MCP usa el plugin `obsidian-local-rest-api` ("Local REST API with MCP"). Ver Paso 7 para instrucciones de configuración manual y por qué se eligió este enfoque.

---

## Paso 1: Crear los repos de vault en GitHub

Crear un repo privado por cada instancia. Ejemplos de nombres:

| Instancia | Repo sugerido |
|-----------|--------------|
| Trabajo   | `brain-work` |
| Personal  | `brain-personal` |

Para cada uno:
1. Ir a https://github.com/new
2. Nombre: `brain-work` o `brain-personal`
3. Visibilidad: **Private**
4. Sin README, sin .gitignore
5. Crear repositorio

Luego ejecutar `setup.sh` una vez por instancia:
```bash
./setup.sh <tu-usuario-github> brain-work ~/vault/brain-work
./setup.sh <tu-usuario-github> brain-personal ~/vault/brain-personal
```

---

## Paso 2: Estructura del Vault de Obsidian

```
carlos-brain/
├── CLAUDE.md                  ← instrucciones para Claude (ver Paso 3) — máx. 500 líneas
├── STATE.md                   ← estado actual: qué está activo, prioridades, en pausa
├── Context/                   ← quién eres: metas, valores, preferencias
│   ├── metas-anuales.md
│   ├── metas-trimestrales.md
│   ├── valores.md
│   ├── preferencias-de-trabajo.md
│   └── preferencias-de-aprendizaje.md
├── Skills/                    ← instrucciones reutilizables que Claude carga bajo demanda
│   ├── plan-dia.md            ← /daily-prep
│   ├── revision-diaria.md     ← /end-day
│   ├── procesar-inbox.md      ← /process-inbox
│   ├── revision-semanal.md    ← /review-week
│   ├── analizar-vault.md      ← /analyze-vault
│   └── revisar-sistema.md     ← /review-system
├── Inbox/                     ← captura rápida sin procesar
│   └── YYYY-MM-DD.md          ← nota diaria (punto de entrada por sesión)
├── Projects/                  ← proyectos activos (cada uno enlazado a un Area y a Resources)
│   └── dev/                   ← proyectos de desarrollo (tasks con links a PRs/commits)
├── Areas/                     ← responsabilidades continuas
│   ├── salud.md
│   ├── finanzas.md
│   ├── familia.md
│   ├── trabajo.md
│   ├── aprendizaje.md
│   └── musica.md
├── Resources/
│   ├── concepts/              ← notas atómicas de conceptos (una idea por archivo)
│   │   ├── arquitectura-hexagonal.md
│   │   └── mcp-model-context-protocol.md
│   ├── moc-ai-tools.md        ← Mapa de Contenido: herramientas de IA
│   ├── moc-finanzas-personales.md
│   ├── moc-desarrollo-web.md
│   ├── moc-musica-y-audio.md
│   └── moc-familia-y-hijos.md
├── Archive/                   ← proyectos completados
├── AI/                        ← logs de sesión
│   └── sessions/              ← YYYY-MM-DD-HH.md por sesión
├── Templates/                 ← plantillas reutilizables
└── Journal/                   ← notas semanales/mensuales (Periodic Notes)
```

**Context/** — notas de perfil que Claude lee al iniciar. Sin esto, cada sesión empieza desde cero. Incluye metas anuales, trimestrales, valores y preferencias de trabajo y aprendizaje.

**Skills/** — instrucciones paso a paso para flujos recurrentes. Cada skill especifica qué archivos leer, qué secciones actualizar y qué notas crear. Claude los carga bajo demanda: *"ejecuta /daily-prep"*.

**Resources/concepts/** — notas atómicas de conceptos técnicos o personales que surgen en conversaciones. Se enlazan desde Projects, Areas y Journal con wiki-links.

**Resources/moc-*.md** — Mapas de Contenido (MOC): un índice por tema clave que agrupa enlaces a proyectos, áreas, recursos y journal relacionados. Se actualiza cada vez que se trabaja ese tema.

**Convención Projects/** — cada proyecto debe tener en frontmatter `related` apuntando a al menos un Area y a notas de concepto relevantes, y en el cuerpo links a Context/ y Resources/ cuando aplique.

**Protocolo de cierre de Projects/:** antes de mover un proyecto a Archive/, el usuario escribe tres oraciones directamente en la nota del proyecto (Claude no puede hacer esto):
```
## Cierre
- Qué pasó: ___
- Por qué terminó: ___
- Qué queda: ___
```
Sin este bloque, Claude leerá proyectos cerrados como contexto activo al regenerar STATE.md.

**STATE.md** es un artefacto derivado, no un archivo que el usuario mantiene manualmente. Claude lo regenera al cerrar cada sesión a partir de fuentes observables: tareas activas en Projects/, áreas con cambios recientes en Areas/, y la conversación de la sesión. El usuario lo revisa y aprueba — no lo escribe desde cero. Claude lo lee al iniciar para arrancar con contexto sin preguntar.

> **Importante:** STATE.md se lee al INICIO de cada sesión. El bloque `## Hechos duros` (ver abajo) es lo primero que el usuario lee antes de que Claude genere nada — funciona como ancla activa, no como contexto pasivo.

Ejemplo de estructura generada:

```markdown
# Estado actual — generado: 2026-06-07

## Hechos duros
<!-- Solo edición manual por el usuario — Claude lee esto como restricción, nunca lo modifica -->
<!-- Propósito: romper el loop cerrado. Claude genera STATE.md desde lo que ve en el vault,
     pero no ve conversaciones externas, decisiones verbales, ni cambios de contexto fuera de
     sesión. Este bloque es el canal para inyectar esa realidad externa. Sin él, los errores
     de inferencia de Claude se amplifican silenciosamente de sesión en sesión. -->
- Proyecto prioritario esta semana: ___
- Bloqueador real actual: ___
- Próximo deadline real: ___

## Activo ahora
<!-- Claude infiere esto de tareas `status: active` en Projects/ -->
- Leyendo "Clean Code" — capítulo 5 (Areas/aprendizaje.md)
- Proyecto: rediseño de presupuesto mensual (Projects/presupuesto.md)

## En pausa
<!-- Claude infiere esto de tareas `status: someday` en Projects/ -->
- Curso de Rust — retomar después del proyecto de presupuesto

## Próximas prioridades
<!-- Claude infiere esto de tareas con 📅 próximas o sin fecha en Projects/ -->
- Revisar suscripciones activas
```

**Convención de frontmatter** (todas las notas deben incluirlo):
```yaml
---
created: 2026-06-07
tags: [tema, area]
status: active       # active | someday | done
related: [[Otra Nota]]
author: user         # user | claude — obligatorio desde el día uno
---
```

> **Convención de autoría:** `author: user` si el contenido fue escrito por el usuario (incluyendo ediciones sustanciales de borradores de Claude). `author: claude` si fue generado por Claude y aprobado sin edición significativa. Sin esta distinción, en 6 meses es imposible separar el registro cognitivo propio del output aprobado.

**Sintaxis de tareas (Tasks plugin):**
```markdown
- [ ] Llamar al banco 📅 2026-06-10 #personal
- [ ] Leer capítulo 3 de SICP #estudio
- [x] Revisar presupuesto ✅ 2026-06-07
```

---

## Paso 3: El Archivo CLAUDE.md en la Raíz del Vault

Este archivo es el más importante: Claude lo lee automáticamente en cada sesión y define cómo comportarse dentro del vault.

Contenido recomendado para `carlos-brain/CLAUDE.md`:

> Límite: máximo 500 líneas. Si crece más, es una señal de error arquitectónico — el contenido excedente pertenece a sus carpetas correspondientes, no aquí.

```markdown
# Instrucciones para Claude

## Quién soy
Desarrollador de software independiente. Uso este vault para todo: notas personales,
aprendizaje, tareas personales y tareas de desarrollo.
Lee Context/ para perfil detallado (metas, valores, preferencias).

## MCP configurado
El vault se accede via MCP Obsidian (servidor: mcp-obsidian).
Úsalo siempre para leer y escribir notas en el vault.
Todas las tareas — personales y de desarrollo — se gestionan aquí.

## Estructura del vault
- Context/ — metas anuales/trimestrales, valores, preferencias de trabajo y aprendizaje
- Skills/ — instrucciones paso a paso para flujos recurrentes (/daily-prep, /end-day, /process-inbox, /review-week, /analyze-vault, /review-system)
- Inbox/YYYY-MM-DD.md — nota diaria, punto de entrada
- Projects/ — proyectos activos (cada uno enlazado a un Area y a Resources/)
  - Projects/dev/ — proyectos de desarrollo; las tareas incluyen links a PRs/commits en lugar de GitHub Issues
- Areas/ — responsabilidades continuas: salud, finanzas, familia, trabajo, aprendizaje, música
- Resources/concepts/ — notas atómicas de conceptos técnicos y personales
- Resources/moc-*.md — Mapas de Contenido por tema clave
- Archive/ — proyectos completados
- AI/sessions/ — logs históricos de sesión
- Templates/ — plantillas

## Protocolo al iniciar sesión (/daily-prep)
1. Lee STATE.md — muestra el bloque ## Hechos duros al usuario ANTES de generar nada
   - Si ## Hechos duros está vacío o no ha sido editado desde hace más de 3 días, señalarlo como primer punto
2. Lee Context/ (metas-anuales.md, metas-trimestrales.md)
3. Lee el último log en AI/sessions/
4. Abre/crea la nota diaria Inbox/YYYY-MM-DD.md
5. Genera borrador de ## Prioridades del día (3–5 puntos) usando ## Hechos duros como restricción prioritaria
6. Presenta → usuario aprueba → escribe

## Protocolo al cerrar sesión (/end-day)
1. Claude pregunta al usuario: "¿Qué aprendiste hoy y qué decidiste?"
   El usuario escribe primero — 2 a 4 oraciones libres, sin estructura.
2. Claude complementa con contexto técnico inferido de la conversación:
   - Qué acciones se realizaron (tareas cerradas, notas creadas)
   - Decisiones tomadas que no quedaron explícitas en la respuesta del usuario
   - Prioridad para mañana (de tareas abiertas en Projects/)
3. El resultado combinado se escribe en AI/sessions/YYYY-MM-DD-HH.md con `author: user` en las oraciones del usuario y `author: claude` en el complemento
4. Claude actualiza ## Agent Log en la nota diaria con el resumen combinado
5. Regenera STATE.md a partir de Projects/ — no toca ## Hechos duros
6. Presenta STATE.md regenerado → "¿Corrijo o apruebo?"
7. Si hay un patrón repetido que merezca un nuevo skill, lo señala al usuario

## Durante el día
- Capturas rápidas → ## Loops abiertos de la nota diaria
- Cuando se pida: convierte loops en tareas (Tasks plugin) o en notas de Projects/Areas/Resources

## Mapas de Contenido (MOC)
Cada vez que trabajemos un tema, actualiza el MOC correspondiente en Resources/ con enlaces
a proyectos, áreas, recursos y journal relevantes.

## Tags permitidos (lista cerrada)
personal, estudio, finanzas, salud, proyectos, referencias, ideas

## Convenciones
- Nombres de archivo en kebab-case (ej: clean-code-notas.md)
- Notas atómicas: una idea por archivo
- Frontmatter YAML en todas las notas (created, tags, status, related, author)
- `author: user` si el contenido fue escrito o editado sustancialmente por el usuario
- `author: claude` si fue generado por Claude y aprobado sin edición significativa
- Projects: campo `related` apuntando a al menos un Area y notas de concepto relevantes
- Projects: bloque `## Cierre` escrito por el usuario antes de archivar (no generado por Claude)
- Tareas con sintaxis del Tasks plugin: - [ ] tarea 📅 fecha #tag
- Wiki-links [[nombre-nota]] para conectar conceptos
- Responde en español
```

---

## Paso 4: Contenido de Skills/

Cada skill especifica qué leer, qué actualizar y qué crear. Plantillas iniciales:

### `Skills/plan-dia.md` (/daily-prep)
```markdown
# Skill: Plan del día

## Qué leer primero
1. STATE.md
2. Context/metas-anuales.md y Context/metas-trimestrales.md
3. Último log en AI/sessions/
4. Nota diaria de hoy (Inbox/YYYY-MM-DD.md) si existe

## Qué hacer
- Crear Inbox/YYYY-MM-DD.md desde Templates/daily.md si no existe
- Generar borrador de ## Prioridades del día (3–5 puntos) derivado de:
  - Tareas con 📅 de hoy o vencidas en Projects/
  - STATE.md ## Próximas prioridades
  - Metas activas en Context/
- Presentar borrador y preguntar: "¿Ajusto algo?"

## Qué actualizar
- ## Prioridades del día en la nota diaria (tras aprobación del usuario)
```

### `Skills/revision-diaria.md` (/end-day)
```markdown
# Skill: Revisión diaria (cierre de sesión)

## Qué leer primero
1. Nota diaria de hoy (Inbox/YYYY-MM-DD.md)
2. Projects/ — tareas completadas o actualizadas hoy

## Flujo (el orden importa — el usuario sintetiza primero)

### Paso 1: síntesis del usuario
Preguntar: "¿Qué aprendiste hoy y qué decidiste?"
Esperar respuesta libre (2–4 oraciones). No sugerir ni estructurar antes de que el usuario escriba.

### Paso 2: complemento de Claude → AI/sessions/YYYY-MM-DD-HH.md
Añadir contexto técnico inferido de la conversación:
- Acciones realizadas (tareas cerradas, notas creadas)
- Decisiones tomadas no explícitas en la respuesta del usuario
- Prioridad para mañana (tarea más urgente en Projects/)
- ¿Nuevo skill? si se repitió un flujo manual por segunda vez

Estructura del log:
- Síntesis del usuario (`author: user`)
- Complemento de Claude (`author: claude`)

### Paso 3: STATE.md
Regenerar secciones derivadas (## Activo ahora, ## En pausa, ## Próximas prioridades) desde Projects/.
**No tocar ## Hechos duros** — solo edición manual. Si está desactualizado (>3 días), señalarlo.
Presentar STATE.md regenerado → "¿Corrijo o apruebo?"

### Paso 4: cerrar
Escribir log aprobado en AI/sessions/ y ## Agent Log de la nota diaria.
Escribir STATE.md aprobado.
```

### `Skills/procesar-inbox.md` (/process-inbox)
```markdown
# Skill: Procesar inbox

## Qué leer primero
1. Inbox/YYYY-MM-DD.md — sección ## Loops abiertos

## Qué hacer por cada item
- Decidir destino: Projects/, Areas/, Resources/concepts/, o tarea descartable
- Crear nota estructurada con frontmatter (created, tags, status, related)
- Para Projects: campo related apuntando a un Area y notas de concepto relevantes
- Para conceptos nuevos: crear Resources/concepts/nombre-concepto.md y enlazar desde el MOC correspondiente
- Convertir items accionables en tareas con sintaxis Tasks: - [ ] tarea 📅 fecha #tag

## Qué actualizar
- Marcar items procesados en la nota diaria
- MOC correspondiente si se crearon notas de concepto nuevas
```

### `Skills/revision-semanal.md` (/review-week)
```markdown
# Skill: Revisión semanal

## Qué leer primero
1. Notas diarias de la semana (Inbox/YYYY-MM-DD.md × 5–7)
2. Proyectos activos en Projects/ (incluyendo Projects/dev/)
3. Logs de sesión de la semana en AI/sessions/

## Qué generar (derivar, luego mostrar para aprobación)

### Journal/YYYY-WW.md
Inferir de las notas diarias y logs:
- Resumen de lo completado (de tareas ✅ y logs de sesión)
- Loops abiertos que siguen pendientes (de ## Loops abiertos sin procesar)
- Prioridades para la semana siguiente (de tareas abiertas en Projects/)

### STATE.md
Regenerar completo igual que /end-day, pero con vista de semana completa.

## Flujo
1. Presenta Journal/YYYY-WW.md → "¿Corrijo o apruebo?"
2. Escribe journal aprobado
3. Presenta STATE.md regenerado → "¿Corrijo o apruebo?"
4. Escribe STATE.md aprobado
5. Actualiza MOCs relevantes con nuevos enlaces surgidos durante la semana
6. Actualiza Areas/ si cambió algo en alguna área continua
```

### `Skills/analizar-vault.md` (/analyze-vault)
```markdown
# Skill: Análisis topológico del vault

Detecta degradación estructural: proyectos aislados, áreas descuidadas, recursos sin acción,
y señales débiles acumuladas sin procesar. Ejecutar mensualmente o cuando el vault se sienta
"pesado".

## Qué leer
1. Todos los archivos en Projects/ (incluyendo Projects/dev/)
2. Todos los archivos en Areas/
3. Todos los archivos en Resources/concepts/
4. Resources/moc-*.md
5. Inbox/ — últimas 2 semanas de notas diarias (sección ## Señales débiles)

## Qué detectar

### Proyectos huérfanos
- Proyectos sin frontmatter `related` apuntando a un Area
- Proyectos con `status: active` pero sin tarea abierta (- [ ]) en el cuerpo
- Proyectos con última modificación > 30 días sin nota de pausa explícita

### Áreas descuidadas
- Areas/ con última modificación > 60 días
- Areas/ sin ningún proyecto activo enlazado en Resources/moc-*.md

### Recursos sin acción
- Resources/concepts/ sin wikilinks entrantes desde Projects/ o Areas/
- Resources/moc-*.md con enlaces rotos (apuntan a notas que no existen)

### Señales débiles acumuladas
- Entradas en ## Señales débiles de las últimas 2 semanas sin convertir en tarea o concepto
- Mismo tema apareciendo en Señales débiles más de 2 veces → candidato a nota atómica

## Qué generar
Un informe conciso con cuatro secciones:
1. **Proyectos que necesitan atención** — listado con diagnóstico
2. **Áreas descuidadas** — listado con días desde última modificación
3. **Recursos huérfanos** — listado con acción sugerida (conectar / archivar / eliminar)
4. **Señales débiles recurrentes** — temas que merecen una nota atómica en Resources/concepts/

Presentar informe → usuario decide qué accionar → Claude ejecuta solo lo que el usuario aprueba.
No modificar nada sin aprobación explícita.
```

### `Skills/revisar-sistema.md` (/review-system)
```markdown
# Skill: Revisión y mejora continua del sistema

Analiza un mes de uso del vault para detectar fricciones, patrones de abandono y oportunidades
de mejora. Propone cambios concretos al sistema (skills, CLAUDE.md, estructura) como borradores
para aprobación. Ningún archivo se modifica sin que el usuario lo autorice explícitamente.

Ejecutar: primer día de cada mes, antes del /analyze-vault mensual.

## Qué leer
1. AI/sessions/ — todos los logs del mes anterior
2. Inbox/ — notas diarias del mes (sección ## Señales débiles)
3. Skills/*.md en el vault — versión actual de cada skill (copiados desde `skills/*/SKILL.md` en el repo engram)
4. CLAUDE.md — instrucciones actuales

## Qué detectar

### Patrones de uso
- ¿Qué skills se ejecutaron más? ¿Cuáles no se ejecutaron ninguna vez?
- ¿Qué secciones del protocolo se saltaron consistentemente?
- ¿Hubo sesiones sin /end-day? ¿Con qué frecuencia?

### Fricciones registradas
- Entradas en ## Señales débiles que mencionan el sistema, la captura o el vault
- Comentarios en ## Contexto para Claude que corrijan comportamiento de Claude
- Tareas repetidas que podrían convertirse en un nuevo skill

### Deriva del sistema
- ¿CLAUDE.md creció más de 50 líneas este mes? ¿Por qué?
- ¿Algún skill tiene pasos que el usuario omite siempre? → candidato a simplificación
- ¿Algún flujo manual se repitió 3+ veces sin skill? → candidato a nuevo skill

## Qué generar

Un informe con tres secciones:

### 1. Diagnóstico de uso
Métricas observadas: skills usados, sesiones con /end-day, frecuencia de captura en
Señales débiles, etc.

### 2. Propuestas de cambio
Para cada propuesta, especificar:
- Qué cambiaría (skill X, sección Y de CLAUDE.md, nueva estructura Z)
- Por qué (patrón observado que lo justifica)
- Borrador del cambio propuesto (diff o texto completo del nuevo contenido)

### 3. Experimentos para el próximo mes
1–2 ajustes pequeños para probar antes de comprometerse con un cambio permanente.

## Flujo de aprobación
1. Presentar informe completo
2. Para cada propuesta: "¿Aplico este cambio? (sí / no / modificar)"
3. Solo tras aprobación explícita: editar el archivo correspondiente en `skills/<nombre>/SKILL.md` o `CLAUDE.md` en el repo engram
4. Registrar cambios aprobados en AI/sessions/YYYY-MM-DD-review-system.md con `author: user`
   en las decisiones del usuario y `author: claude` en el diagnóstico
```

---

## Paso 5: Nota Diaria — Estructura

Cada nota diaria en `Inbox/YYYY-MM-DD.md` sirve como punto de entrada para Claude:

```markdown
---
created: 2026-06-07
tags: [daily]
---

## Prioridades del día
<!-- Claude genera este borrador al ejecutar /daily-prep — el usuario aprueba -->

## Loops abiertos
<!-- Capturas rápidas durante el día -->

## Señales débiles
<!-- Intuiciones, corazonadas, incomodidades que no sabes articular todavía.
     No requieren estructura. Ejemplos: "algo raro con el deploy de hoy",
     "esa reunión me dejó con duda sobre X", "creo que estoy evitando algo".
     Claude no procesa esta sección automáticamente — es materia prima para
     reflexión futura, no tareas. /process-inbox puede convertirlas en notas
     de concepto si el usuario lo pide explícitamente. -->

## Contexto para Claude
<!-- Instrucciones específicas para esta sesión -->

## Agent Log
<!-- Claude genera este borrador al ejecutar /end-day — el usuario aprueba -->
```

---

## Paso 6: Plugins de Obsidian a Instalar

Ir a **Settings → Community plugins → Browse** e instalar:

| Plugin | Propósito |
|--------|-----------|
| **Obsidian Git** | Sync automático al repo de cada vault instancia |
| **Tasks** | Gestión de tareas con fechas, filtros, recurrencia |
| **Dataview** | Queries para crear dashboards de tareas y notas |
| **Periodic Notes** | Notas diarias/semanales/mensuales con plantilla |
| **Templater** | Plantillas con lógica y variables de fecha |
| **QuickAdd** | Captura rápida al inbox sin abrir nota manualmente |
| **Calendar** | Vista de notas diarias por fecha |

### Configuración de Obsidian Git

Settings → Obsidian Git:
- **Vault backup interval:** `5` (minutos)
- **Auto pull interval:** `5` (minutos)
- **Commit message:** `vault backup: {{date}}`
- **Remote:** `origin` → apuntando al repo de la instancia (`brain-work` o `brain-personal`)

> `setup.sh` hace esto automáticamente al crear el vault.

---

## Paso 7: MCP Server — Obsidian

El MCP usa el plugin **Local REST API with MCP** (`obsidian-local-rest-api` v4.1.3, Adam Coddington). Expone el vault vía HTTP con operaciones nativas de Obsidian (búsqueda, metadata, frontmatter, tags) — más rico que el servidor filesystem genérico.

**Requisito:** Obsidian debe estar abierto y el plugin activo para que el MCP responda.

### Configuración manual (primera vez)

1. Abre Obsidian → `Settings → Community plugins → habilita "Local REST API with MCP"`
2. En el plugin: activa **"Enable Non-encrypted (insecure) Server"** (puerto 27123)
   - El servidor HTTPS (puerto 27124) usa certificado autofirmado — Claude Code no lo acepta
3. Copia el **API Key** del plugin
4. Registra el MCP con `claude mcp add` (aplica igual en Mac y Linux):

```bash
# Para brain-personal:
claude mcp add brain-personal -s user \
  --type http \
  --header "Authorization: Bearer <API_KEY>" \
  "http://127.0.0.1:27123/mcp"

# Para brain-work (mismo proceso, Obsidian debe tener ese vault abierto):
claude mcp add brain-work -s user \
  --type http \
  --header "Authorization: Bearer <API_KEY>" \
  "http://127.0.0.1:27123/mcp"
```

Si re-ejecutas `setup.sh` con el plugin ya inicializado, este paso se hace automáticamente.

### Verificar que funciona

```bash
claude mcp list
# Debe mostrar: brain-personal: http://127.0.0.1:27123/mcp (HTTP) - ✔ Connected
```

> **Por qué no `@modelcontextprotocol/server-filesystem`:** En Linux con Obsidian instalado via snap, el servidor filesystem tenía conflictos con el sandbox al resolver paths. El Local REST API with MCP resuelve esto y además expone operaciones semánticas del vault.

> **Ambas instancias:** Cada vault tiene su propia entrada MCP. Los skills operan sobre uno solo a la vez — especificado en el `CLAUDE.md` de cada vault. Al inicio de sesión indica cuál usar: *"sesión de trabajo"* o *"sesión personal"*.

---

## Paso 8: Verificar que Todo Funciona

### Verificación de sync (por cada vault)

```bash
cd ~/vault/brain-work
git remote -v
git log --oneline -5
```

### Verificación del MCP

En una sesión de Claude Code, probar con cada instancia:
- "sesión de trabajo — ¿qué tengo en el inbox de hoy?" → Claude debe leer `brain-work/Inbox/YYYY-MM-DD.md`
- "sesión personal — agrega una tarea al inbox: llamar al banco" → debe editar `brain-personal/Inbox/YYYY-MM-DD.md`
- "¿Qué tareas de desarrollo tengo activas?" → debe leer `brain-work/Projects/dev/`

---

## Flujos de Trabajo Típicos

### Inicio de jornada
> "ejecuta /daily-prep"

Claude lee STATE.md + Context/ + últimos logs → crea la nota diaria → propone 3–5 prioridades → añade referencia breve de tareas de desarrollo activas en Projects/dev/.

### Captura rápida durante el día
> "Añade a loops abiertos: revisar el artículo de arquitectura hexagonal"

Claude añade el item a `## Loops abiertos` en la nota diaria de hoy.

### Procesar inbox
> "ejecuta /process-inbox"

Claude lee loops abiertos → clasifica cada item (Projects/Areas/Resources/tarea) → crea notas estructuradas con frontmatter y wiki-links → actualiza MOC si se crean conceptos nuevos.

### Cierre de jornada
> "ejecuta /end-day"

Claude pregunta: "¿Qué aprendiste hoy y qué decidiste?" → el usuario escribe 2–4 oraciones libres → Claude complementa con contexto técnico inferido de la conversación → ambas partes se escriben en `AI/sessions/` con atribución de autoría → Claude regenera STATE.md desde Projects/ → presenta para aprobación → escribe.

### Revisión semanal
> "ejecuta /review-week"

Claude lee notas de la semana + issues de GitHub → genera `Journal/YYYY-WW.md` → actualiza MOCs y STATE.md.

### Nuevo concepto en conversación
> "Explícame qué es arquitectura hexagonal y guárdalo"

Claude crea `Resources/concepts/arquitectura-hexagonal.md` con nota atómica → enlaza desde el MOC correspondiente (`Resources/moc-desarrollo-web.md`) → enlaza desde el proyecto activo si aplica.

### Tareas de desarrollo (en el vault)
> "Crea una tarea en el proyecto oraculobot: implementar rate limiting en la API"

Claude crea la tarea con sintaxis Tasks plugin en `Projects/dev/oraculobot.md` (o la nota del proyecto correspondiente). Si hay un PR/commit relacionado, se añade como link en el body de la tarea.

### Análisis topológico del vault
> "ejecuta /analyze-vault"

Claude lee Projects/, Areas/, Resources/ e Inbox/ → genera informe de proyectos huérfanos, áreas descuidadas, recursos sin acción y señales débiles recurrentes → presenta diagnóstico → ejecuta solo lo que el usuario aprueba explícitamente.

### Revisión y mejora del sistema
> "ejecuta /review-system"

Claude lee los logs de `AI/sessions/` del mes + señales débiles + skills actuales → genera diagnóstico de uso, propuestas de cambio con borrador de cada modificación, y experimentos para el mes siguiente → ningún archivo se toca sin aprobación explícita por cada propuesta.

---

## Mantenimiento Mensual

**Graph Orphan Test** — primer día de cada mes, ~30 minutos:

Un archivo sin wikilinks entrantes ni salientes es un nodo huérfano: Claude nunca lo "verá" en contexto porque ninguna nota lo referencia. En Obsidian: *Graph view → filtrar nodos sin conexiones*.

Para cada huérfano: conectarlo con [[wiki-links]] a notas relacionadas, moverlo a Archive/, o eliminarlo si ya no aporta.

También revisar:
- ¿CLAUDE.md sigue siendo preciso respecto al workflow actual? ¿Sigue bajo 500 líneas?
- ¿Hay flujos repetidos que merezcan un nuevo skill en Skills/?
- ¿Los MOCs en Resources/ están actualizados con los proyectos y áreas activos?
- ¿Hay notas en Resources/concepts/ sin enlaces desde Projects o Areas? Conectarlas o archivarlas.

**Auditoría de portabilidad** — una vez por trimestre, ~15 minutos:

El vault es texto plano en git, pero depende de tres herramientas: Claude, Obsidian y GitHub. Verificar que el conocimiento sigue siendo tuyo sin ellas:

- ¿Las notas más importantes tienen sentido leídas directamente como `.md` sin Obsidian?
- ¿Los wiki-links `[[nombre]]` están documentados como rutas reales para que un script pueda resolverlos?
- ¿Podrías reconstruir el contexto de un proyecto leyendo solo sus archivos, sin STATE.md?

Si la respuesta a alguna es no, el vault tiene deuda de portabilidad. La solución no es migrar — es escribir con suficiente contexto en cada nota para que no dependa de sus enlaces.

---

## Notas de Implementación

- **Tres repos, responsabilidades separadas:** `engram` (público, plugin + template), `brain-work` (privado, vault trabajo), `brain-personal` (privado, vault personal). `setup.sh` los conecta. No mezclar contenido personal en `engram`.
- **Instancias aisladas:** cada vault tiene su propio MCP, su propio repo git, y su propio contexto. Claude opera sobre uno solo por sesión. Indicar cuál al inicio: *"sesión de trabajo"* o *"sesión personal"*.
- **Skills: fuente de verdad en `skills/*/SKILL.md`**. Los archivos en `vault-template/Skills/` son copias planas para referencia en Obsidian. Si editas un skill, edítalo en `skills/<nombre>/SKILL.md` y re-ejecuta `setup.sh` para propagar los cambios.
- Las tareas de desarrollo van en `Projects/dev/<repo>.md` con sintaxis Tasks plugin. Los links a PRs/commits se añaden como texto en el body de cada tarea — no hay integración bidireccional automática con GitHub.
- Claude no tiene memoria nativa entre sesiones — la continuidad viene de STATE.md y los logs en `AI/sessions/`. Ambos son generados automáticamente por Claude al cerrar sesión y aprobados por el usuario: no se escriben a mano.
- **Fuentes de verdad para STATE.md:** tareas `status: active/someday` en Projects/ y la conversación de la sesión. Si Projects/ está actualizado, STATE.md siempre puede regenerarse correctamente.
- **Tres convenciones no delegables a Claude:** (1) `author:` en frontmatter de cada archivo desde el día uno; (2) bloque `## Cierre` escrito por el usuario antes de archivar cualquier proyecto; (3) bloque `## Hechos duros` en STATE.md de solo edición manual. Sin estas tres, el vault pierde su valor como registro cognitivo personal a mediano plazo.
- Si hay conflictos de git por editar en dos máquinas al mismo tiempo, son conflictos de texto plano, fáciles de resolver.
