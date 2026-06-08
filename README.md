# engram

Sistema de memoria personal: vault de Obsidian + skills para Claude Code.

**engram** = la huella física que un recuerdo deja en el cerebro. Lo que Claude escribe en el vault no es un log de actividad — es el registro de cómo se piensa y se decide.

## Qué incluye

- `plugin/` — skills e instrucciones base para Claude Code
- `vault-template/` — estructura del vault con plantillas
- `setup.sh` — instala todo desde cero en una máquina nueva

## Instalación rápida

```bash
git clone https://github.com/<tu-usuario>/engram.git
cd engram
./setup.sh <tu-usuario-github> brain-work ~/vault/brain-work
./setup.sh <tu-usuario-github> brain-personal ~/vault/brain-personal
```

El script hace todo automáticamente:
1. Instala el plugin engram en Claude Code
2. Instala Obsidian (flatpak/snap en Linux, Homebrew en Mac)
3. Crea el vault desde `vault-template/` o clona uno existente
4. Descarga los 7 plugins de comunidad de Obsidian
5. Registra el vault en Obsidian (visible al abrir la app)
6. Imprime el snippet MCP para pegar manualmente (único paso manual)

**Único paso manual:** pegar el snippet MCP en la config de Claude y hacer click en "Enable plugins" la primera vez que abras Obsidian.

## Configuración MCP

Después de ejecutar `setup.sh`, agrega a `~/.claude/settings.json` (Linux) o `~/Library/Application Support/Claude/claude_desktop_config.json` (Mac):

```json
{
  "mcpServers": {
    "brain-work": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/ruta/vault/brain-work"]
    },
    "brain-personal": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/ruta/vault/brain-personal"]
    }
  }
}
```

## Skills disponibles

| Comando | Propósito |
|---------|-----------|
| `/daily-prep` | Inicio del día: lee STATE.md, crea nota diaria, propone prioridades |
| `/end-day` | Cierre: captura aprendizajes, actualiza AI/sessions/, regenera STATE.md |
| `/process-inbox` | Convierte loops abiertos en notas y tareas estructuradas |
| `/review-week` | Journal semanal + STATE.md con vista de la semana completa |
| `/analyze-vault` | Auditoría mensual: proyectos huérfanos, áreas descuidadas, señales débiles |
| `/review-system` | Meta-revisión mensual: patrones de uso, fricciones, mejoras al sistema |

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
├── Skills/             ← copias de plugin/skills/ (actualizar via claude plugin update)
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

```bash
claude plugin update engram
# Luego copiar skills actualizados al vault:
cp ~/.claude/plugins/engram/skills/*.md ~/vault/brain-work/Skills/
```

## Repos relacionados

- `engram` (este repo) — plugin + template, público
- `brain-work` — vault de trabajo, privado
- `brain-personal` — vault personal, privado
