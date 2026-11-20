#!/usr/bin/env bash
# Serves built folders at https://chaosmos.studio/<path>/ from one Cloudflare Worker with static assets.
#
#   deploy.sh <worker> <path>=<folder> [<path>=<folder> ...]
#   deploy.sh plumb-play plumb/play=build/web
#
# Each path gets the routes chaosmos.studio/<path> and chaosmos.studio/<path>/*, so the Worker answers only its
# own addresses and the studio site's Worker answers the rest. HOSTS replaces chaosmos.studio, for a staging host.
# Wrangler reads CLOUDFLARE_API_TOKEN, or uses its own login when it is unset.
set -euo pipefail

WRANGLER_VERSION=4.165.0
read -r -a hosts <<< "${HOSTS:-chaosmos.studio}"

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
  # The path under site/ is the path on the site: site/plumb/play/index.html is chaosmos.studio/plumb/play/.
  mkdir -p "$work/site/$path"
  cp -R "$folder/." "$work/site/$path/"
  for host in "${hosts[@]}"; do
    routes+=("{ \"pattern\": \"$host/$path\", \"zone_name\": \"chaosmos.studio\" }")
    routes+=("{ \"pattern\": \"$host/$path/*\", \"zone_name\": \"chaosmos.studio\" }")
  done
done

# A Worker serves no file over 25 MiB, and the upload would stop on one anyway.
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
  // The Chaosmos Studio account, a public identifier, so the token is the only secret.
  "account_id": "8bc19d12de5e264d90d6667284a711c8",
  "compatibility_date": "2026-11-18",
  "assets": { "directory": "./site", "html_handling": "auto-trailing-slash", "not_found_handling": "none" },
  "observability": { "enabled": true },
  "routes": [
    ${joined%,*}
  ],
  // Only the routes above serve it, never a workers.dev address.
  "workers_dev": false,
  "preview_urls": false
}
EOF

cd "$work"
npx --yes "wrangler@$WRANGLER_VERSION" deploy --config wrangler.jsonc
