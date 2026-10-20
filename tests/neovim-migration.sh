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
# Exercise initial application even when the user's working copy is migrated.
for file in lua/giga/plugins.lua lua/giga/lsp/jdtls_setup.lua lua/giga/autocmd.lua; do
    git -C "$source_dir" show "HEAD:$file" > "$test_dir/source/$file"
done
rm -f "$test_dir/source/lua/installdoc_shared.lua"
cp -a "$test_dir/source" "$test_dir/original"
printf 'preserve unrelated edits\n' > "$test_dir/source/unrelated-test-file"
sh "$ROOT/installer/neovim-migrate.sh" "$test_dir/source" "$ROOT/installer/patches/gitnvim-shared-home.patch" "$test_dir/backups"
sh "$ROOT/installer/neovim-migrate.sh" "$test_dir/source" "$ROOT/installer/patches/gitnvim-shared-home.patch" "$test_dir/rerun-backups"
[ ! -e "$test_dir/rerun-backups" ]
[ "$(cat "$test_dir/source/unrelated-test-file")" = 'preserve unrelated edits' ]
cmp "$test_dir/original/lua/giga/plugins.lua" "$test_dir/backups$test_dir/source/lua/giga/plugins.lua"
for file in lua/giga/plugins.lua lua/giga/lsp/jdtls_setup.lua lua/giga/autocmd.lua lua/installdoc_shared.lua; do
    luac -p "$test_dir/source/$file"
done
lua "$ROOT/tests/neovim-runtime.lua" "$test_dir/source"
# User customization after migration must not require the patch to match again.
sed '/^if vim.fn.getuid() ~= 0 then$/,/^end$/s/^/--/' \
    "$test_dir/source/lua/giga/autocmd.lua" > "$test_dir/autocmd.lua"
mv "$test_dir/autocmd.lua" "$test_dir/source/lua/giga/autocmd.lua"
printf '\n-- User customization near the lazy setup call.\n' >> "$test_dir/source/lua/giga/plugins.lua"
cp -a "$test_dir/source" "$test_dir/customized"
sh "$ROOT/installer/neovim-migrate.sh" "$test_dir/source" "$ROOT/installer/patches/gitnvim-shared-home.patch" "$test_dir/custom-rerun-backups"
[ ! -e "$test_dir/custom-rerun-backups" ]
diff -r "$test_dir/customized" "$test_dir/source"
# Reject incomplete migrations instead of mistaking any helper file for success.
cp "$test_dir/original/lua/giga/lsp/jdtls_setup.lua" "$test_dir/source/lua/giga/lsp/jdtls_setup.lua"
cp -a "$test_dir/source" "$test_dir/partial"
if sh "$ROOT/installer/neovim-migrate.sh" "$test_dir/source" "$ROOT/installer/patches/gitnvim-shared-home.patch" "$test_dir/partial-backups" > "$test_dir/partial-error" 2>&1; then
    printf 'Partial migration was incorrectly accepted.\n' >&2
    exit 1
fi
[ ! -e "$test_dir/partial-backups" ]
diff -r "$test_dir/partial" "$test_dir/source"
printf 'Neovim migration, customized rerun, partial rejection, and separate runtime tests passed.\n'
