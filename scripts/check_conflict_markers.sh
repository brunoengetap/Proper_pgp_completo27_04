#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "🔎 Verificando marcadores de conflito (<<<<<<<, =======, >>>>>>>)..."

if rg -n "^(<<<<<<<|=======|>>>>>>>)" \
  --glob '!*.png' --glob '!*.jpg' --glob '!*.jpeg' --glob '!*.gif' \
  --glob '!*.pdf' --glob '!*.lock' .; then
  echo ""
  echo "❌ Marcadores de conflito encontrados."
  exit 1
fi

echo "✅ Nenhum marcador de conflito encontrado."
