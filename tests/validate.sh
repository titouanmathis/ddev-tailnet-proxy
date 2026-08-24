#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
script="$root/bin/ddev-tailnet-proxy"

bash -n "$script"
test -x "$script"
"$script" help | grep -q '^Usage: ddev-tailnet-proxy <command>$'
printf 'Validation passed.\n'
