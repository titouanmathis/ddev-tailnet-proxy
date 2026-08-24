#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
name=ddev-tailnet-proxy
version=${1:-$(tr -d '\n' < "$root/VERSION")}

[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.][A-Za-z0-9.]+)?$ ]] || {
  printf 'Usage: %s [version]\n' "${0##*/}" >&2
  exit 1
}

"$root/tests/validate.sh"
archive_dir="$root/dist"
release_root="$archive_dir/$name-$version"
archive="$archive_dir/$name-$version.tar.gz"

rm -rf "$release_root"
mkdir -p "$release_root/bin"
cp "$root/bin/$name" "$release_root/bin/$name"
cp "$root/README.md" "$root/LICENSE" "$release_root/"
chmod 755 "$release_root/bin/$name"
tar -C "$archive_dir" -czf "$archive" "$name-$version"
(
  cd "$archive_dir"
  sha256sum "$(basename "$archive")" > "$(basename "$archive").sha256"
)
printf 'Created %s and %s.sha256\n' "$archive" "$archive"
