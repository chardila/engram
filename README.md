# engram

Sistema de memoria personal: vault de Obsidian + skills para Claude Code.

**engram** = la huella física que un recuerdo deja en el cerebro. Lo que Claude escribe en el vault no es un log de actividad — es el registro de cómo se piensa y se decide.

## Qué incluye

- `.claude-plugin/` — manifiesto del plugin para Claude Code (`plugin.json`)
- `skills/` — skills de Claude Code (fuente de verdad)
- `vault-template/` — estructura del vault con plantillas
- `setup.sh` — instala todo desde cero en una máquina nueva

## Instalación rápida

```bash
git clone https://github.com/<tu-usuario>/engram.git
cd engram
./setup.sh <tu-usuario-github> brain-personal ~/vault/brain-personal
```

El script hace todo automáticamente:
1. Instala el plugin engram en Claude Code (`~/.claude/skills/engram/`)
2. Instala Obsidian (snap en Linux, Homebrew en Mac)
3. Crea el vault desde `vault-template/` o clona uno existente
4. Descarga los 8 plugins de comunidad de Obsidian (incluido Local REST API with MCP)
5. Registra el vault en Obsidian (visible al abrir la app)
6. Registra el MCP en Claude Code si el plugin ya fue inicializado, o imprime las instrucciones si no

## Configuración MCP

El MCP usa el plugin **Local REST API with MCP** (`obsidian-local-rest-api` v4.1.3 por Adam Coddington). Es el MCP recomendado para Obsidian: acceso nativo al vault con soporte de búsqueda, metadata y frontmatter.

**Primera vez (paso manual obligatorio):**

1. Abre Obsidian → `Settings → Community plugins → habilita "Local REST API with MCP"`
2. En la configuración del plugin: activa **"Enable Non-encrypted (insecure) Server"** (puerto 27123)
   - El servidor HTTPS (puerto 27124) genera un certificado autofirmado que Claude Code no acepta
3. Copia el **API Key** que muestra el plugin
4. Registra el MCP en Claude Code:

```bash
claude mcp add brain-personal -s user \
  --type http \
  --header "Authorization: Bearer <API_KEY>" \
  "http://127.0.0.1:27123/mcp"
```

Si re-ejecutas `setup.sh` después de que el plugin fue inicializado, el paso 4 se hace automáticamente.

**Requisito:** Obsidian debe estar abierto para que el MCP responda.

## Skills disponibles

| Comando | Propósito |
|---------|-----------|
| `/daily-prep` | Inicio del día: lee STATE.md, crea nota diaria, propone prioridades |
| `/end-day` | Cierre: captura aprendizajes, actualiza AI/sessions/, regenera STATE.md |
| `/process-inbox` | Convierte loops abiertos en notas y tareas estructuradas |
| `/review-week` | Journal semanal + STATE.md con vista de la semana completa |
| `/analyze-vault` | Auditoría mensual: proyectos huérfanos, áreas descuidadas, señales débiles |
| `/review-system` | Meta-revisión mensual: patrones de uso, fricciones, mejoras al sistema |
| `/ingest-url <url>` | Ingesta una URL: crea nota en Sources/, extrae conceptos a Resources/, actualiza MOCs y cross-links |

## Uso típico

```
"ejecuta /daily-prep"
"Añade a loops abiertos: revisar artículo de arquitectura hexagonal"
"ejecuta /process-inbox"
"ejecuta /end-day"
```

## Estructura del vault

```
tu-vault/
├── CLAUDE.md           ← instrucciones para Claude (completar al instalar)
├── STATE.md            ← estado actual: generado por Claude, aprobado por ti
├── Context/            ← quién eres: metas, valores, preferencias
├── Skills/             ← copias de skills/ del repo (referencia en Obsidian)
├── Inbox/              ← nota diaria + capturas rápidas
├── Projects/dev/       ← proyectos activos (con links a PRs/commits)
├── Areas/              ← responsabilidades continuas
├── Resources/concepts/ ← notas atómicas de conceptos
├── Resources/moc-*.md  ← mapas de contenido por tema
├── Archive/            ← proyectos completados
├── AI/sessions/        ← logs de sesión
├── Templates/          ← plantillas
└── Journal/            ← revisiones semanales/mensuales
```

## Tres convenciones no delegables a Claude

1. **`author:`** en frontmatter de cada archivo desde el día uno (`user` o `claude`)
2. **`## Cierre`** escrito por ti antes de archivar cualquier proyecto
3. **`## Hechos duros`** en STATE.md es solo de edición manual — ancla lo que Claude no puede inferir

## Actualizar los skills

Re-ejecuta `setup.sh` desde el repo actualizado:

```bash
cd engram
git pull
./setup.sh <tu-usuario-github> brain-personal ~/vault/brain-personal
```

El script sobreescribe `~/.claude/skills/engram/` con los skills actualizados.

## Repos relacionados

- `engram` (este repo) — plugin + template, público
- `brain-personal` — vault personal, privado
