#!/bin/sh
# Apply the reviewed account-relative migration to the separate config checkout.
set -eu
source_dir=$1
patch_file=$2
backup_dir=$3
if git -C "$source_dir" apply --reverse --check "$patch_file" 2>/dev/null; then
    printf 'Neovim shared-home migration already applied.\n'
    exit 0
fi
git -C "$source_dir" apply --check "$patch_file" || {
    printf 'Neovim migration does not match local source; preserve it and reconcile the patch before retrying.\n' >&2
    exit 1
}
# Back up complete originals before modifying the checkout, including dirty work.
for file in lua/giga/plugins.lua lua/giga/lsp/jdtls_setup.lua lua/giga/autocmd.lua; do
    mkdir -p "$backup_dir$source_dir/$(dirname "$file")"
    cp -p "$source_dir/$file" "$backup_dir$source_dir/$file"
done
git -C "$source_dir" apply "$patch_file"
