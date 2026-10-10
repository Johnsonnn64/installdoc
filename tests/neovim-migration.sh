#!/bin/sh
# Copies a local gitnvim checkout into /tmp; no plugin startup/network access.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
source_dir=${1:?Pass the existing gitnvim checkout}
test_dir=$(mktemp -d /tmp/installdoc-nvim-test.XXXXXXXX)
trap 'rm -rf -- "$test_dir"' 0
trap 'exit 130' INT
trap 'exit 143' TERM
cp -a "$source_dir/." "$test_dir/source"
printf 'preserve unrelated edits\n' > "$test_dir/source/unrelated-test-file"
sh "$ROOT/installer/neovim-migrate.sh" "$test_dir/source" "$ROOT/installer/patches/gitnvim-shared-home.patch" "$test_dir/backups"
sh "$ROOT/installer/neovim-migrate.sh" "$test_dir/source" "$ROOT/installer/patches/gitnvim-shared-home.patch" "$test_dir/rerun-backups"
[ ! -e "$test_dir/rerun-backups" ]
[ "$(cat "$test_dir/source/unrelated-test-file")" = 'preserve unrelated edits' ]
cmp "$source_dir/lua/giga/plugins.lua" "$test_dir/backups$test_dir/source/lua/giga/plugins.lua"
for file in lua/giga/plugins.lua lua/giga/lsp/jdtls_setup.lua lua/giga/autocmd.lua lua/installdoc_shared.lua; do
    luac -p "$test_dir/source/$file"
done
lua "$ROOT/tests/neovim-runtime.lua" "$test_dir/source"
printf 'Neovim migration, rerun, and separate runtime tests passed.\n'
