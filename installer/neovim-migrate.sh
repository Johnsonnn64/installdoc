#!/bin/sh
# Apply the reviewed account-relative migration to the separate config checkout.
set -eu
source_dir=$1
patch_file=$2
backup_dir=$3
# Reverse-patch matching alone is too strict after normal config edits, such as
# disabling the website upload autocmd. Check the migration settings themselves.
has_setting() { grep -Eq "$2" "$source_dir/$1"; }
migration_complete() {
    [ -f "$source_dir/lua/installdoc_shared.lua" ] || return 1
    has_setting lua/giga/plugins.lua '^[[:space:]]*}, require\("installdoc_shared"\)\.lazy_options\(\)\)' || return 1
    has_setting lua/installdoc_shared.lua '^[[:space:]]*local lock = state \.\. "/lazy-lock.json"' || return 1
    has_setting lua/installdoc_shared.lua '^[[:space:]]*local state = vim.fn.stdpath\("state"\)' || return 1
    for setting in \
        'local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/workspace/"' \
        'local equinox_launcher = vim.fn.glob(vim.fn.stdpath("data")' \
        'vim.fn.stdpath("data") .. "/mason/packages/jdtls/config_linux"' \
        'vim.fn.glob(vim.fn.stdpath("data") .. "/mason/packages/java-debug-adapter/' \
        'vim.fn.glob(vim.fn.stdpath("data") .. "/mason/packages/java-test/'; do
        # Ignore commented lines so a partially reverted migration is rejected.
        sed '/^[[:space:]]*--/d' "$source_dir/lua/giga/lsp/jdtls_setup.lua" |
            grep -Fq "$setting" || return 1
    done
    has_setting lua/giga/autocmd.lua '^[[:space:]]*pattern = vim.env.HOME \.\. "/personal/school/\*"' || return 1
    # An intentionally disabled upload hook needs no root guard. An active one
    # must retain both its account-relative path and the migration's root guard.
    if has_setting lua/giga/autocmd.lua '^[[:space:]]*AC\("BufWritePost",'; then
        has_setting lua/giga/autocmd.lua '^[[:space:]]*if vim.fn.getuid\(\) ~= 0 then' || return 1
        has_setting lua/giga/autocmd.lua '^[[:space:]]*pattern = vim.env.HOME \.\. "/workspace/site/\*"' || return 1
    fi
}
if git -C "$source_dir" apply --reverse --check "$patch_file" 2>/dev/null || migration_complete; then
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
