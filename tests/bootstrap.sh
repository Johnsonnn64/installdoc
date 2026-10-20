#!/bin/sh
# shellcheck disable=SC2030,SC2031
# No root, package installation, home changes, network access, or running X needed.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
test_dir=$(mktemp -d /tmp/installdoc-test.XXXXXXXX)
trap 'rm -rf -- "$test_dir"' 0
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

"$ROOT/install.sh" --help > "$test_dir/help"
grep -q 'pipewire fcitx media' "$test_dir/help" || fail help
if "$ROOT/install.sh" base invalid-module > "$test_dir/invalid" 2>&1; then fail 'unknown module accepted'; fi
if grep -q '^\[base\]' "$test_dir/invalid"; then fail 'base ran before validation'; fi
if "$ROOT/install.sh" --dry-run base network > "$test_dir/network" 2>&1; then fail 'removed network module accepted'; fi
if grep -q '^\[base\]' "$test_dir/network"; then fail 'base ran before removed-module validation'; fi
"$ROOT/install.sh" --dry-run pipewire pipewire media > "$test_dir/dry"
[ "$(grep -c '^\[pipewire\]' "$test_dir/dry")" = 1 ] || fail deduplication
if grep -Eq '<(-Syu|-Sy)>' "$test_dir/dry"; then fail 'database refresh'; fi
if "$ROOT/install.sh" --dry-run base gaming > "$test_dir/gaming" 2>&1; then fail 'gaming accepted without hardware selection'; fi
if grep -q '^\[base\]' "$test_dir/gaming"; then fail 'base ran before missing-input gate'; fi

(
    . "$ROOT/installer/common.sh"
    . "$ROOT/installer/modules.sh"
    # Helpers operate solely on explicit paths under the temporary test directory.
    BACKUP=$test_dir/backups
    dry_run=true
    link "$ROOT/README.md" "$test_dir/dry-target/file"
    run touch "$test_dir/forbidden"
    [ ! -e "$test_dir/forbidden" ] || fail 'dry-run executed command'
    [ ! -e "$test_dir/dry-target" ] || fail 'dry-run wrote files'
    dry_run=false
    mkdir "$test_dir/source" "$test_dir/user"
    printf 'original\n' > "$test_dir/source/file"
    original_inode=$(stat -c %i "$test_dir/source/file")
    printf 'keep\n' > "$test_dir/source/unrelated"
    ln -s "$test_dir/source" "$test_dir/user/bin"
    link "$ROOT/README.md" "$test_dir/user/bin/file"
    [ ! -L "$test_dir/user/bin" ] || fail 'parent not detached'
    [ "$(cat "$test_dir/source/file")" = original ] || fail 'source changed through parent symlink'
    [ "$(stat -c %i "$test_dir/source/file")" = "$original_inode" ] || fail 'source inode replaced through backup symlink'
    [ "$(cat "$test_dir/user/bin/unrelated")" = keep ] || fail 'unrelated file lost'
    [ -L "$test_dir/user/bin/file" ] || fail 'file not linked'
    [ -L "$BACKUP$test_dir/user/bin/original" ] || fail 'parent backup lost'
    # Parent and child backups must not collide or write through backup symlinks.
    before=$(find "$BACKUP" -type f -o -type l | sort)
    link "$ROOT/README.md" "$test_dir/user/bin/file"
    after=$(find "$BACKUP" -type f -o -type l | sort)
    [ "$before" = "$after" ] || fail 'rerun made additional backups'
    ln -s /no/such/target "$test_dir/dangling"
    link "$ROOT/README.md" "$test_dir/dangling"
    [ "$(readlink "$BACKUP$test_dir/dangling/original")" = /no/such/target ] || fail 'dangling link not backed up'
    git init -q "$test_dir/repo"
    git -C "$test_dir/repo" remote add origin https://github.com/Johnsonnn64/gitnvim
    printf 'uncommitted\n' > "$test_dir/repo/local"
    checkout "$test_dir/repo" https://github.com/Johnsonnn64/gitnvim
    [ "$(cat "$test_dir/repo/local")" = uncommitted ] || fail 'dirty checkout changed'
    resolve desktop
    resolve pipewire
    case " $ordered " in *' network '*) fail 'removed network module in desktop' ;; esac
    case " $ordered " in *' bluetooth '*|*' easyeffects '*|*' media '*|*' gaming '*) fail 'optional module in desktop' ;; esac
)

if (
    . "$ROOT/installer/common.sh"
    check_repo "$test_dir/repo" https://github.com/wrong/repository
) > "$test_dir/remote" 2>&1; then fail 'unexpected remote accepted'; fi
grep -q 'Unexpected origin' "$test_dir/remote" || fail 'missing remote error'

if (
    . "$ROOT/installer/common.sh"
    dry_run=false
    module='expected-failure'
    run false
    touch "$test_dir/should-not-exist"
) > "$test_dir/failure" 2>&1; then fail 'failure ignored'; fi
[ ! -e "$test_dir/should-not-exist" ] || fail 'continued after failure'
grep -q expected-failure "$test_dir/failure" || fail 'missing failure context'

for file in "$ROOT/install.sh" "$ROOT"/installer/*.sh "$ROOT"/config/x11/xinitrc "$ROOT"/config/x11/autostart "$ROOT"/config/bin/lfrun "$ROOT"/config/bin/screenshot "$ROOT"/config/lf/preview "$ROOT"/config/lf/cleaner; do
    dash -n "$file"
done
for file in "$ROOT/config/zsh/.zshenv" "$ROOT/config/zsh/.zprofile" "$ROOT/config/zsh/.zshrc" "$ROOT/system/zprofile"; do zsh -n "$file"; done
printf 'All bootstrap tests passed.\n'
