# shellcheck shell=sh disable=SC2034,SC2154
# Sourced by install.sh; variables are shared with modules.sh and the entrypoint.
module=preflight
operation=initialization
ordered=
SOURCE_ROOT=$HOME/workspace/git
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/installdoc
BACKUP=$STATE/backups/$(date +%Y%m%dT%H%M%S)-$$
CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
trap 'result=$?; if [ "$result" -ne 0 ]; then printf "ERROR [%s]: %s (exit %s)\n" "$module" "$operation" "$result" >&2; fi' 0

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
run() {
    operation="$*"
    printf '  +'; printf ' <%s>' "$@"; printf '\n'
    if ! "$dry_run"; then "$@" || die "[$module] failed: $operation"; fi
}
packages() { run sudo pacman -S --needed "$@"; }
backup() {
    # Keep absolute-path structure, including dangling symlinks.
    if [ -e "$1" ] || [ -L "$1" ]; then
        # Store each target beneath its own directory. A backed-up parent
        # symlink must never become a path we traverse for a child's backup.
        run mkdir -p "$BACKUP$1"
        run mv -T -- "$1" "$BACKUP$1/original"
    fi
}
link() {
    # A legacy ~/.local/bin may link to the whole repository bin directory.
    # Detach symlinked parents before replacing children; never edit their source.
    prepare_parent "$(dirname -- "$2")"
    if [ -L "$2" ] && [ "$(readlink -- "$2")" = "$1" ]; then return; fi
    backup "$2"
    run mkdir -p "$(dirname -- "$2")"
    run ln -sT -- "$1" "$2"
}
prepare_parent() {
    [ "$1" != / ] || return 0
    prepare_parent "$(dirname -- "$1")"
    if [ -L "$1" ]; then
        [ -d "$1" ] || die "Parent is not a directory: $1"
        parent_source=$(readlink -f -- "$1")
        backup "$1"
        run mkdir -p "$1"
        run cp -a -- "$parent_source/." "$1/"
    fi
}
system_file() {
    if [ ! -L "$2" ] && [ -f "$2" ] && cmp -s -- "$1" "$2" &&
        [ "$(stat -c '%u:%g:%a' "$2")" = "0:0:${3:-644}" ]; then return; fi
    if [ -e "$2" ] || [ -L "$2" ]; then
        run sudo mkdir -p "/var/backups/installdoc/${BACKUP##*/}$(dirname -- "$2")"
        run sudo cp -a -- "$2" "/var/backups/installdoc/${BACKUP##*/}$2"
    fi
    # install must never follow a pre-existing user-owned symlink.
    run sudo mkdir -p "$(dirname -- "$2")"
    run sudo install -m "${3:-644}" -o root -g root "$1" "$2.installdoc-new"
    run sudo mv -fT -- "$2.installdoc-new" "$2"
}
check_repo() {
    [ -d "$1/.git" ] || die "Not a regular checkout: $1"
    actual=$(git -C "$1" remote get-url origin) || die "No origin in $1"
    # GitHub owner/repository names are case-insensitive; accept .git suffix.
    actual=$(printf '%s' "$actual" | sed 's/\.git$//' | tr '[:upper:]' '[:lower:]')
    expected=$(printf '%s' "$2" | sed 's/\.git$//' | tr '[:upper:]' '[:lower:]')
    [ "$actual" = "$expected" ] || die "Unexpected origin in $1: $actual (expected $expected)"
}
checkout() {
    if [ -e "$1" ]; then check_repo "$1" "$2"; return; fi
    [ ! -L "$1" ] || die "Dangling source symlink: $1"
    run mkdir -p "$(dirname -- "$1")"
    if [ -n "${3:-}" ] && [ -d "$3" ]; then
        check_repo "$3" "$2"
        # Preserve all local work and .git; leave the old checkout untouched.
        run cp -a -- "$3/." "$1"
    else
        run git clone -- "$2" "$1"
    fi
}
aur() {
    if ! command -v yay >/dev/null 2>&1; then
        packages base-devel git
        checkout "$SOURCE_ROOT/yay-bin" https://aur.archlinux.org/yay-bin.git
        run sh "$ROOT/installer/aur-helper.sh" "$SOURCE_ROOT/yay-bin"
    fi
    run yay -S --needed "$@"
}
validate_module() {
    case $1 in
        desktop|base|git|xorg|dwm|dmenu|alacritty|zsh|root-config|dash|pipewire|fcitx|keyd|dunst|picom|feh|clipmenu|cli|lf|neovim|fonts|polkit|bluetooth|easyeffects|media|gaming|steam) ;;
        *) die "Unknown module: $1 (see --help)" ;;
    esac
}
resolve() {
    case " $ordered " in *" $1 "*) return ;; esac
    case $1 in
        desktop) for dependency in base git xorg dmenu dwm alacritty zsh dash pipewire fcitx keyd dunst picom feh clipmenu cli neovim root-config fonts polkit; do resolve "$dependency"; done ;;
        root-config) resolve zsh; resolve neovim ;;
        dwm) resolve xorg; resolve dmenu ;;
        clipmenu|bluetooth) resolve dmenu ;;
        cli) resolve lf ;;
        easyeffects) resolve pipewire ;;
        steam) resolve gaming ;;
    esac
    ordered="$ordered $1"
}
has_module() { case " $ordered " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
preflight() {
    if has_module gaming; then gaming_preflight; fi
    if has_module keyd && [ -z "${KEYD_CONFIG:-}" ]; then
        KEYD_CONFIG=$ROOT/default.conf
    fi
    if [ -n "${KEYD_CONFIG:-}" ]; then
        case $KEYD_CONFIG in /*) ;; *) die 'KEYD_CONFIG must be an absolute path' ;; esac
        [ -f "$KEYD_CONFIG" ] || die "Missing keyd mapping: $KEYD_CONFIG"
    fi
    if has_module easyeffects && [ ! -d "$ROOT/optional/easyeffects" ]; then
        die 'EasyEffects needs exported presets/assets in optional/easyeffects/; see README. No changes made.'
    fi
    if has_module zsh; then
        sh "$ROOT/installer/zsh-migrate.sh" --check "$ROOT" "$BACKUP" || die 'Global zsh customization needs review; no changes made.'
    fi
    if "$dry_run"; then return; fi
    [ "$(id -u)" -ne 0 ] || die 'Run as the normal user, not root or sudo ./install.sh.'
    [ -f /etc/arch-release ] || die 'This installer targets Arch Linux.'
    command -v sudo >/dev/null || die 'sudo is required.'
    command -v pacman >/dev/null || die 'pacman is required.'
    if has_module pipewire; then
        systemctl --user show-environment >/dev/null || die 'A working systemd user session is required for audio.'
    fi
}
help() {
    cat <<'EOF'
Usage: ./install.sh [--dry-run] MODULE [MODULE ...]

desktop: base git xorg dmenu dwm alacritty zsh dash pipewire fcitx
         keyd dunst picom feh clipmenu cli neovim root-config fonts polkit
Standalone modules: every name above, plus lf.
Optional: bluetooth, media, easyeffects (requires exported presets), gaming/steam.
Gaming: GAMING_GPU='amd intel nvidia' (select actual GPUs, space-separated).
        GAMING_EXTRAS='gamemode mangohud' (optional; empty by default).
        Requires enabled multilib and a manual full update before installation.
Dependencies: dwm -> xorg dmenu; clipmenu/bluetooth -> dmenu;
              cli -> lf; easyeffects -> pipewire; root-config -> zsh neovim.
              Shared modules run once.

Examples:
  ./install.sh --dry-run desktop
  ./install.sh pipewire fcitx media
  ./install.sh --dry-run root-config
  ./install.sh keyd
  GAMING_GPU=amd ./install.sh --dry-run steam
  KEYD_CONFIG=/path/to/reviewed.conf ./install.sh desktop

keyd uses the repository's default.conf unless KEYD_CONFIG is supplied.
Run as a normal Arch user with sudo. Never upgrades/refreshes package databases.
Existing repositories are never pulled/reset; legacy checkouts are copied.
Backups: ~/.local/state/installdoc/backups and /var/backups/installdoc.
Dry-run prints actions and performs no writes. See README for migration gates.
root-config restores root's home to /root (no home move) and shares zsh/Neovim
sources by symlink. Runtime state stays separate. Included in desktop migration.
EOF
}
