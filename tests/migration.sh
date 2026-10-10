#!/bin/sh
# Migration fixtures only: no sudo, packages, passwd edits or live home changes.
# shellcheck disable=SC2034,SC2016
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
test_dir=$(mktemp -d /tmp/installdoc-migration-test.XXXXXXXX)
trap 'rm -rf -- "$test_dir"' 0
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

mkdir -p "$test_dir/etc/zsh"
printf '%s\n' 'export KEEP_ME=yes' "export ZDOTDIR='/home/john/.config/zsh/'" > "$test_dir/etc/zsh/zshenv"
printf '%s\n' 'emulate sh -c "source /etc/profile"' 'source "$HOME/.config/zsh/.zprofile"' 'export KEEP_PROFILE=yes' > "$test_dir/etc/zsh/zprofile"
sh "$ROOT/installer/zsh-migrate.sh" --check "$ROOT" "$test_dir/backup" "$test_dir/etc/zsh"
[ ! -e "$test_dir/backup" ] || fail 'check mutated files'
sh "$ROOT/installer/zsh-migrate.sh" --apply "$ROOT" "$test_dir/backup" "$test_dir/etc/zsh"
grep -q '^export KEEP_ME=yes$' "$test_dir/etc/zsh/zshenv" || fail 'lost unrelated env'
grep -q '^export KEEP_PROFILE=yes$' "$test_dir/etc/zsh/zprofile" || fail 'lost unrelated profile'
if grep -q '^source .*\.zprofile' "$test_dir/etc/zsh/zprofile"; then fail 'duplicate profile remains'; fi
[ -f "$test_dir/backup$test_dir/etc/zsh/zshenv/original" ] || fail 'global config backup missing'
cp "$test_dir/etc/zsh/zshenv" "$test_dir/env-before-rerun"
sh "$ROOT/installer/zsh-migrate.sh" --apply "$ROOT" "$test_dir/second-backup" "$test_dir/etc/zsh"
cmp "$test_dir/etc/zsh/zshenv" "$test_dir/env-before-rerun"
[ ! -e "$test_dir/second-backup" ] || fail 'rerun created needless backup'
# Use zsh -f so the live per-user config is not loaded. No HOME reassignment.
zsh -dfc '. "$1"; [[ $ZDOTDIR == "$HOME/.config/zsh" ]]' sh "$test_dir/etc/zsh/zshenv"
mkdir "$test_dir/custom"
printf '%s\n' 'export ZDOTDIR=/some/custom/location' > "$test_dir/custom/zshenv"
if sh "$ROOT/installer/zsh-migrate.sh" --check "$ROOT" "$test_dir/no-backup" "$test_dir/custom" 2>/dev/null; then fail 'unknown override accepted'; fi

# Source root migration functions with all filesystem targets replaced by fixtures.
set -- --library
. "$ROOT/installer/root-config.sh"
# Restore our cleanup after sourcing (the library installs no traps).
root_repo=$ROOT
root_home=$test_dir/root
root_nvim=$test_dir/gitnvim
root_backup_dir=$test_dir/root-backups
passwd_file=$test_dir/passwd
old_root_home=$test_dir/user
old_root_shell=/bin/zsh
mkdir -p "$root_home/.config/zsh" "$root_nvim" "$test_dir/user/.cache/zsh" "$root_home/.cache"
printf 'keep-user-data\n' > "$test_dir/user/important"
printf 'old-root-config\n' > "$root_home/.config/zsh/local"
printf 'root:x:0:0::%s:/bin/zsh\n' "$old_root_home" > "$passwd_file"
ln -s "$test_dir/user/.cache/zsh" "$root_home/.cache/zsh"
usermod() { printf '%s\n' "$*" >> "$test_dir/usermod-calls"; }
deploy_root
[ "$(readlink "$root_home/.config/zsh")" = "$ROOT/config/zsh" ] || fail 'wrong root zsh source'
[ "$(readlink "$root_home/.config/nvim")" = "$root_nvim" ] || fail 'wrong root nvim source'
[ "$(cat "$test_dir/user/important")" = keep-user-data ] || fail 'user data changed'
[ "$(cat "$root_backup_dir$root_home/.config/zsh/original/local")" = old-root-config ] || fail 'root conflict backup missing'
[ -f "$root_backup_dir$passwd_file/original" ] || fail 'passwd backup missing'
grep -Fx -- "-d $root_home -s /usr/bin/zsh root" "$test_dir/usermod-calls" >/dev/null || fail 'unexpected account operation'
[ ! -L "$root_home/.cache/zsh" ] || fail 'root runtime still shares user state'
old_root_home=$root_home
old_root_shell=/usr/bin/zsh
deploy_root
[ "$(wc -l < "$test_dir/usermod-calls")" -eq 1 ] || fail 'rerun edited passwd'

# Validate global-source runtime defaults in an isolated XDG state location.
XDG_CACHE_HOME="$test_dir/cache" XDG_STATE_HOME="$test_dir/state" \
    zsh -dfc '. "$1"; [[ $HISTFILE == "$XDG_STATE_HOME/zsh/history" ]]; before=$PATH; . "$1"; [[ $PATH == "$before" ]]' sh "$ROOT/config/zsh/.zshenv"
printf 'All shared-config migration tests passed.\n'
