#!/usr/bin/env bash
set -euo pipefail

WRANGLER_VERSION=4.165.0

if [ $# -lt 2 ]; then
  echo "usage: deploy.sh <worker> <path>=<folder> [<path>=<folder> ...]" >&2
  exit 2
fi
worker=$1
shift

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "$work/site"
routes=()

for pair in "$@"; do
  path=${pair%%=*}
  folder=${pair#*=}
  path=${path#/}
  path=${path%/}
  if [[ $pair != *=* ]] || [ -z "$path" ] || [ ! -f "$folder/index.html" ]; then
    echo "deploy.sh: '$pair' needs the form <path>=<folder>, with an index.html in the folder" >&2
    exit 2
  fi
  mkdir -p "$work/site/$path"
  cp -R "$folder/." "$work/site/$path/"
  routes+=("{ \"pattern\": \"chaosmos.studio/$path\", \"zone_name\": \"chaosmos.studio\" }")
  routes+=("{ \"pattern\": \"chaosmos.studio/$path/*\", \"zone_name\": \"chaosmos.studio\" }")
done

too_big=$(find "$work/site" -type f -size +25M)
if [ -n "$too_big" ]; then
  echo "deploy.sh: these files are over 25 MiB, so a Worker cannot serve them:" >&2
  echo "$too_big" >&2
  exit 1
fi

joined=$(printf '%s,\n    ' "${routes[@]}")
cat > "$work/wrangler.jsonc" <<EOF
{
  "name": "$worker",
  "account_id": "8bc19d12de5e264d90d6667284a711c8",
  "compatibility_date": "2026-11-18",
  "assets": { "directory": "./site", "html_handling": "auto-trailing-slash", "not_found_handling": "none" },
  "observability": { "enabled": true },
  "routes": [
    ${joined%,*}
  ],
  "workers_dev": false,
  "preview_urls": false
}
EOF

cd "$work"
npx --yes "wrangler@$WRANGLER_VERSION" deploy --config wrangler.jsonc
