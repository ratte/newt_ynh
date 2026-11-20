#!/usr/bin/env bash
# Bump the packaged Newt version: downloads the release assets,
# computes their sha256 and rewrites manifest.toml.
# Usage: tools/bump_version.sh 1.21.0
# (Not needed once the app is in the catalog: the YunoHost autoupdate bot does this.)
set -euo pipefail

version="${1:?usage: $0 <newt version, e.g. 1.21.0>}"
cd "$(dirname "$0")/.."

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

declare -A assets=([amd64]=newt_linux_amd64 [arm64]=newt_linux_arm64 [armhf]=newt_linux_arm32)

for arch in amd64 arm64 armhf; do
    url="https://github.com/fosrl/newt/releases/download/${version}/${assets[$arch]}"
    echo "Fetching $url"
    if ! curl -fsSL -o "$tmp/$arch" "$url"; then
        echo "ERROR: could not download $url" >&2
        exit 1
    fi
    sum="$(sha256sum "$tmp/$arch" | cut -d' ' -f1)"
    sed -i -E \
        -e "s|^([[:space:]]*${arch}\.url = ).*|\1\"${url}\"|" \
        -e "s|^([[:space:]]*${arch}\.sha256 = ).*|\1\"${sum}\"|" \
        manifest.toml
done

sed -i -E "s|^version = \".*\"|version = \"${version}~ynh1\"|" manifest.toml
echo "manifest.toml updated to ${version}~ynh1"
