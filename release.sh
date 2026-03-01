#!/usr/bin/env bash
set -eu

export MIX_ENV=prod

echo "==> Getting production dependencies..."
mix deps.get --only prod

echo "==> Compiling (prod)..."
mix compile

echo "==> Building production assets..."
mix assets.deploy

echo "==> Building release..."
mix release

echo ""
echo "Release built at _build/prod/rel/ditto"
