#!/usr/bin/env bash
set -e

GITHUB_USER="${1:?Uso: setup.sh <tu-usuario-github> <nombre-vault> [ruta-vault]}"
VAULT_NAME="${2:?Uso: setup.sh <tu-usuario-github> <nombre-vault> [ruta-vault]}"
VAULT_PATH="${3:-$HOME/vault/$VAULT_NAME}"
ENGRAM_REPO="https://github.com/$GITHUB_USER/engram.git"
BRAIN_REPO="https://github.com/$GITHUB_USER/$VAULT_NAME.git"

echo "=== engram setup: $VAULT_NAME ==="

# 1. Instalar plugin de Claude Code (solo si no está instalado)
echo "→ Instalando plugin engram..."
claude plugin install "$ENGRAM_REPO"

# 2. Clonar o crear el vault
if git ls-remote "$BRAIN_REPO" &>/dev/null; then
  echo "→ Clonando vault existente: $VAULT_NAME..."
  git clone "$BRAIN_REPO" "$VAULT_PATH"
else
  echo "→ Creando vault nuevo desde vault-template..."
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  cp -r "$SCRIPT_DIR/vault-template" "$VAULT_PATH"
  # Skills: copiar desde plugin/skills/ (fuente de verdad) al vault
  cp "$SCRIPT_DIR/plugin/skills/"*.md "$VAULT_PATH/Skills/"
  cd "$VAULT_PATH"
  git init
  git remote add origin "$BRAIN_REPO"
  git add .
  git commit -m "initial vault setup from engram template"
  git push -u origin main
fi

# 3. Configurar MCP
echo ""
echo "→ Configurando MCP..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  MCP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
else
  MCP_CONFIG="$HOME/.claude/settings.json"
fi

echo ""
echo "   Agrega manualmente a: $MCP_CONFIG"
echo "   (usando el nombre del vault como clave MCP):"
echo ""
echo '   "mcpServers": {'
echo "     \"$VAULT_NAME\": {"
echo '       "command": "npx",'
echo '       "args": ["-y", "@modelcontextprotocol/server-filesystem", "'"$VAULT_PATH"'"]'
echo '     }'
echo '   }'
echo ""
echo "=== Listo ==="
echo "Vault: $VAULT_NAME en $VAULT_PATH"
echo "Siguiente paso: configura el MCP (ver instrucciones arriba) y ejecuta /daily-prep"
