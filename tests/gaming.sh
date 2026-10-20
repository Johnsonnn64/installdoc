#!/bin/sh
# Offline checks: no system files, packages, services, or databases are changed.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
test_dir=$(mktemp -d /tmp/installdoc-gaming.XXXXXXXX)
trap 'rm -rf -- "$test_dir"' 0
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
. "$ROOT/installer/common.sh"
. "$ROOT/installer/modules.sh"
# Fixtures replace package-manager calls, including the live preflight.
mkdir "$test_dir/bin"
cat > "$test_dir/bin/pacman-conf" <<'EOF'
#!/bin/sh
printf '%s\n' core extra
if "$multilib"; then printf '%s\n' multilib; fi
EOF
chmod +x "$test_dir/bin/pacman-conf"
PATH=$test_dir/bin:$PATH
export PATH multilib
pacman() {
    case $1 in
        -Si)
            if [ "$#" = 2 ] && [ "$2" = steam ]; then "$synced"; else "$available"; fi
            ;;
        -Q) "$nvidia_installed" ;;
        *) fail "unexpected pacman invocation: $*" ;;
    esac
}
packages() { printf '%s\n' "$@" > "$test_dir/packages"; }
multilib=true
synced=true
available=true
nvidia_installed=false
dry_run=false
GAMING_GPU=amd
GAMING_EXTRAS=
gaming_preflight
gaming_install > "$test_dir/install"
grep -qx lib32-vulkan-radeon "$test_dir/packages" || fail 'AMD Vulkan missing'
grep -qx lib32-libpulse "$test_dir/packages" || fail 'PulseAudio compatibility missing'
if grep -Eq 'intel|nvidia|gamemode|mangohud' "$test_dir/packages"; then fail 'unselected packages'; fi

GAMING_GPU='intel amd intel'
GAMING_EXTRAS='gamemode mangohud gamemode'
gaming_preflight
gaming_install > "$test_dir/install"
for package in mesa lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-radeon lib32-vulkan-radeon gamemode lib32-gamemode mangohud lib32-mangohud steam; do
    [ "$(grep -cx "$package" "$test_dir/packages")" = 1 ] || fail "missing/duplicate $package"
done

GAMING_GPU=nvidia
if (gaming_preflight) > "$test_dir/error" 2>&1; then fail 'NVIDIA driver prerequisite ignored'; fi
nvidia_installed=true
gaming_preflight
gaming_install > "$test_dir/install"
grep -qx lib32-nvidia-utils "$test_dir/packages" || fail 'NVIDIA userspace missing'
if grep -Eq 'mesa|vulkan-radeon|vulkan-intel' "$test_dir/packages"; then fail 'unselected vendor'; fi

GAMING_GPU=amd
GAMING_EXTRAS=
multilib=false
if (gaming_preflight) > "$test_dir/error" 2>&1; then fail 'disabled multilib accepted'; fi
grep -q 'sudo pacman -Syu' "$test_dir/error" || fail 'missing manual update instructions'
multilib=true
available=false
if (gaming_preflight) > "$test_dir/error" 2>&1; then fail 'unavailable selected package accepted'; fi
available=true
synced=false
if (gaming_preflight) > "$test_dir/error" 2>&1; then fail 'missing sync database accepted'; fi
dry_run=true
gaming_preflight > "$test_dir/dry"
grep -q '^NOTE:' "$test_dir/dry" || fail 'dry-run prerequisite note missing'
synced=true
GAMING_GPU=' '
if (gaming_plan) > "$test_dir/error" 2>&1; then fail 'empty GPU selection accepted'; fi
GAMING_GPU=unknown
if (gaming_plan) > "$test_dir/error" 2>&1; then fail 'unknown GPU accepted'; fi
GAMING_GPU='*'
if (gaming_plan) > "$test_dir/error" 2>&1; then fail 'GPU glob accepted'; fi
GAMING_GPU=amd
GAMING_EXTRAS=unknown
if (gaming_plan) > "$test_dir/error" 2>&1; then fail 'unknown extra accepted'; fi
GAMING_EXTRAS=
resolve steam
resolve gaming
[ "$ordered" = ' gaming steam' ] || fail 'Steam dependency deduplication'
printf 'All gaming tests passed.\n'
