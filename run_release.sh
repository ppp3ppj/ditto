#!/usr/bin/env bash
set -eu

RELEASE_BIN="_build/prod/rel/ditto/bin/ditto"

if [ ! -f "$RELEASE_BIN" ]; then
  echo "Release not found. Run ./release.sh first."
  exit 1
fi

export PHX_SERVER=true
export PHX_HOST="${PHX_HOST:-localhost}"
export PORT="${PORT:-4000}"
export DATABASE_PATH="${DATABASE_PATH:-$(pwd)/ditto_prod.db}"
export POOL_SIZE="${POOL_SIZE:-5}"

if [ -z "${SECRET_KEY_BASE:-}" ]; then
  echo "Generating SECRET_KEY_BASE..."
  export SECRET_KEY_BASE=$(mix phx.gen.secret)
fi

echo "==> Starting ditto release at http://localhost:${PORT}"
echo "    DATABASE_PATH=${DATABASE_PATH}"
exec "$RELEASE_BIN" start
