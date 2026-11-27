#!/usr/bin/env bash
# Sync flake.nix version/src hash/npmDepsHash and package-lock.json to the latest @tinacms/cli on npm.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

name=@tinacms/cli
current=$(grep -oP '^\s*version = "\K[^"]+' flake.nix | head -n1)
latest=$(npm view "$name" version)

if [ "$latest" = "$current" ] || [ "$(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -n1)" = "$current" ]; then
  echo "tinacms-cli up to date ($current; npm $latest)"
  exit 0
fi

work=$(mktemp -d "${XDG_CACHE_HOME:-$HOME/.cache}/tinacms-sync.XXXXXX")
trap 'rm -rf "$work"' EXIT
integrity=$(npm view "$name@$latest" dist.integrity)

(cd "$work" && npm pack "$name@$latest" --silent >/dev/null && tar xzf ./*.tgz \
  && cd package && npm install --package-lock-only --legacy-peer-deps --ignore-scripts --silent)
cp "$work/package/package-lock.json" package-lock.json

sed -i \
  -e "s|^\(\s*version = \)\"[^\"]*\"|\1\"$latest\"|" \
  -e "s|^\(\s*hash = \)\"[^\"]*\"|\1\"$integrity\"|" \
  -e "s|^\(\s*npmDepsHash = \)\"[^\"]*\"|\1\"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\"|" flake.nix

# npmDepsFetcherVersion 2 hashes differ from prefetch-npm-deps; read the real hash from the failed build.
deps_hash=$(nix build .#default --accept-flake-config --no-link 2>&1 | sed -n 's/^ *got: *//p' | head -n1)
case "$deps_hash" in sha256-*) ;; *) echo "bad npmDepsHash: $deps_hash" >&2; exit 1 ;; esac
sed -i "s|^\(\s*npmDepsHash = \)\"[^\"]*\"|\1\"$deps_hash\"|" flake.nix
echo "tinacms-cli synced $current -> $latest"
