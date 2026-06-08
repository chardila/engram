#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GITHUB_USER="${1:?Uso: setup.sh <tu-usuario-github> <nombre-vault> [ruta-vault]}"
VAULT_NAME="${2:?Uso: setup.sh <tu-usuario-github> <nombre-vault> [ruta-vault]}"
VAULT_PATH="${3:-$HOME/vault/$VAULT_NAME}"
ENGRAM_REPO="https://github.com/$GITHUB_USER/engram.git"
BRAIN_REPO="https://github.com/$GITHUB_USER/$VAULT_NAME.git"

# plugin-id:owner/repo
PLUGINS=(
  "obsidian-git:Vinzent03/obsidian-git"
  "obsidian-tasks-plugin:obsidian-tasks-group/obsidian-tasks"
  "dataview:blacksmithgu/obsidian-dataview"
  "periodic-notes:liamcain/obsidian-periodic-notes"
  "templater-obsidian:SilentVoid13/Templater"
  "quickadd:chhoumann/quickadd"
  "calendar:liamcain/obsidian-calendar-plugin"
)

# ── helpers ───────────────────────────────────────────────────────────────────

obsidian_installed() {
  command -v obsidian &>/dev/null ||
  flatpak list 2>/dev/null | grep -qi obsidian ||
  snap list 2>/dev/null | grep -qi obsidian ||
  [[ -f "$HOME/.local/bin/obsidian.AppImage" ]]
}

install_obsidian() {
  echo "→ Instalando Obsidian..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      brew install --cask obsidian && echo "  ✓ Obsidian instalado via Homebrew" && return 0
    fi
    echo "  ⚠ Homebrew no encontrado — instala Obsidian manualmente: https://obsidian.md/download"
    return 0
  fi

  # Linux: brew → flatpak → snap (si hay sudo) → AppImage
  if command -v brew &>/dev/null; then
    brew install --cask obsidian && echo "  ✓ Obsidian instalado via Homebrew" && return 0
  fi

  if command -v flatpak &>/dev/null; then
    flatpak install -y flathub md.obsidian.Obsidian && echo "  ✓ Obsidian instalado via flatpak" && return 0
  fi

  if command -v snap &>/dev/null && sudo -n snap install obsidian --classic 2>/dev/null; then
    echo "  ✓ Obsidian instalado via snap" && return 0
  fi

  # AppImage (no requiere sudo)
  echo "  → Descargando AppImage..."
  local version
  version=$(curl -sf "https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'].lstrip('v'))" 2>/dev/null || echo "")
  if [[ -z "$version" ]]; then
    echo "  ⚠ No se pudo obtener la versión de Obsidian — instala manualmente: https://obsidian.md/download"
    return 0
  fi
  local appimage="$HOME/.local/bin/obsidian.AppImage"
  mkdir -p "$HOME/.local/bin"
  curl -fL# \
    "https://github.com/obsidianmd/obsidian-releases/releases/latest/download/Obsidian-${version}.AppImage" \
    -o "$appimage"
  chmod +x "$appimage"
  echo "  ✓ Obsidian AppImage instalado en: $appimage"
}

download_plugin() {
  local plugin_id="$1"
  local gh_repo="$2"
  local plugin_dir="$VAULT_PATH/.obsidian/plugins/$plugin_id"
  mkdir -p "$plugin_dir"

  local urls
  urls=$(curl -sf "https://api.github.com/repos/$gh_repo/releases/latest" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for a in data.get('assets', []):
    if a['name'] in ('main.js', 'manifest.json', 'styles.css'):
        print(a['browser_download_url'])
" 2>/dev/null || true)

  if [[ -z "$urls" ]]; then
    # Fallback: raw de la rama principal
    for branch in main master; do
      if curl -sf "https://raw.githubusercontent.com/$gh_repo/$branch/manifest.json" \
          -o "$plugin_dir/manifest.json" 2>/dev/null; then
        echo "  ⚠ $plugin_id: solo manifest (sin binario en releases)"
        return 0
      fi
    done
    echo "  ✗ $plugin_id: no se pudo descargar"
    return 0
  fi

  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    curl -sfL "$url" -o "$plugin_dir/${url##*/}"
  done <<< "$urls"
  echo "  ✓ $plugin_id"
}

register_vault() {
  local vault_path
  vault_path="$(realpath "$1")"
  local obsidian_config

  if [[ "$OSTYPE" == "darwin"* ]]; then
    obsidian_config="$HOME/Library/Application Support/obsidian/obsidian.json"
  else
    obsidian_config="${XDG_CONFIG_HOME:-$HOME/.config}/obsidian/obsidian.json"
  fi

  mkdir -p "$(dirname "$obsidian_config")"

  python3 - "$obsidian_config" "$vault_path" <<'PYEOF'
import sys, json, secrets, time, os

config_path, vault_path = sys.argv[1], sys.argv[2]

if os.path.exists(config_path):
    with open(config_path) as f:
        config = json.load(f)
else:
    config = {}

config.setdefault("vaults", {})

for vid, vdata in config["vaults"].items():
    if vdata.get("path") == vault_path:
        print(f"  Vault ya registrado en Obsidian.")
        sys.exit(0)

vault_id = secrets.token_hex(8)
config["vaults"][vault_id] = {
    "path": vault_path,
    "ts": int(time.time() * 1000),
    "open": True
}

with open(config_path, "w") as f:
    json.dump(config, f, indent=2)

print(f"  ✓ Vault registrado en: {config_path}")
PYEOF
}

# ── main ──────────────────────────────────────────────────────────────────────

echo ""
echo "=== engram setup: $VAULT_NAME ==="
echo ""

# 1. Plugin de Claude Code
echo "→ Instalando plugin engram en Claude Code..."
PLUGIN_DEST="$HOME/.claude/skills/engram"
if [[ -d "$PLUGIN_DEST" ]]; then
  echo "  Plugin ya instalado — actualizando skills..."
  cp "$SCRIPT_DIR/plugin/skills/"*.md "$PLUGIN_DEST/skills/" 2>/dev/null || true
else
  mkdir -p "$PLUGIN_DEST/skills"
  cp "$SCRIPT_DIR/plugin/skills/"*.md "$PLUGIN_DEST/skills/"
  cp -r "$SCRIPT_DIR/.claude-plugin" "$PLUGIN_DEST/"
fi
echo "  ✓ Plugin instalado en: $PLUGIN_DEST"
echo "  (disponible la próxima sesión de Claude Code)"

# 2. Obsidian
if obsidian_installed; then
  echo "→ Obsidian ya instalado, omitiendo."
else
  install_obsidian
fi

# 3. Vault
if git ls-remote --heads "$BRAIN_REPO" 2>/dev/null | grep -q .; then
  echo "→ Clonando vault existente: $VAULT_NAME..."
  git clone "$BRAIN_REPO" "$VAULT_PATH"
else
  echo "→ Creando vault nuevo desde vault-template..."
  mkdir -p "$VAULT_PATH"
  cp -r "$SCRIPT_DIR/vault-template/." "$VAULT_PATH"
  # Skills: fuente de verdad es plugin/skills/
  cp "$SCRIPT_DIR/plugin/skills/"*.md "$VAULT_PATH/Skills/"
  cd "$VAULT_PATH"
  git init
  git remote add origin "$BRAIN_REPO"
  git add .
  git commit -m "initial vault setup from engram template"
  git push -u origin main
  cd - >/dev/null
fi

# 4. Plugins de Obsidian
echo "→ Descargando plugins de Obsidian..."
for entry in "${PLUGINS[@]}"; do
  plugin_id="${entry%%:*}"
  gh_repo="${entry##*:}"
  if [[ -f "$VAULT_PATH/.obsidian/plugins/$plugin_id/main.js" ]]; then
    echo "  ✓ $plugin_id (ya instalado)"
    continue
  fi
  download_plugin "$plugin_id" "$gh_repo"
done

# 5. Registrar vault en Obsidian
echo "→ Registrando vault en Obsidian..."
register_vault "$VAULT_PATH"

# 6. MCP server
VAULT_ABS="$(realpath "$VAULT_PATH")"
echo "→ Configurando MCP server para Claude Code..."
if claude mcp add "$VAULT_NAME" -s user -- npx -y @modelcontextprotocol/server-filesystem "$VAULT_ABS" 2>/dev/null; then
  echo "  ✓ MCP server '$VAULT_NAME' registrado"
else
  echo "  ⚠ claude mcp add falló — agrega manualmente a Claude Desktop:"
  echo "    \"$VAULT_NAME\": { \"command\": \"npx\", \"args\": [\"-y\", \"@modelcontextprotocol/server-filesystem\", \"$VAULT_ABS\"] }"
fi

echo ""
echo "=== Listo ==="
echo "Vault:   $VAULT_ABS"
echo ""
echo "Próximos pasos:"
echo "  1. Abre Obsidian — el vault ya está registrado"
echo "  2. Settings → Community plugins → Enable plugins  (un click)"
echo "  3. En Claude Code: /daily-prep"
echo ""
