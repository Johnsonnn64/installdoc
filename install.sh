#!/bin/sh
# Arch post-install configuration. Run as the account being configured.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$ROOT/installer/common.sh"
. "$ROOT/installer/modules.sh"

dry_run=false
requested=
for arg do
    case $arg in
        --help|-h) help; exit 0 ;;
        --dry-run) dry_run=true ;;
        -*) die "Unknown option: $arg" ;;
        *) validate_module "$arg"; requested="$requested $arg" ;;
    esac
done
[ -n "$requested" ] || { help; exit 1; }
for module in $requested; do resolve "$module"; done
printf 'Modules:%s\n' "$ordered"
preflight
for module in $ordered; do
    operation="starting $module"
    printf '\n[%s]\n' "$module"
    apply_module "$module"
done
printf '\nCompleted%s.\n' "$(if "$dry_run"; then printf ' dry-run'; fi)"
