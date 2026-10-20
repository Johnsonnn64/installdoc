# Arch + DWM bootstrap

Modular post-install setup for an already installed, online Arch Linux system.
Desktop migration is the current implementation/testing priority.
Run as your normal user with working sudo. This does not install Arch, partition
disks, change bootloaders, upgrade the system, or refresh package databases.

```sh
mkdir -p ~/workspace/git
# Clone this repository into ~/workspace/git/installdoc, then:
cd ~/workspace/git/installdoc
./install.sh --help
./install.sh --dry-run desktop
./install.sh --dry-run root-config
./install.sh pipewire fcitx media
./install.sh desktop
```

The implementation is ready for disposable-machine testing. A full desktop
conversion has **not** been run on the daily driver. See [validation](docs/VALIDATION.md)
for checks actually performed and remaining hardware/session checks.
The agreed requirements are in [the plan](arch-dwm-bootstrap-plan.md); original
manual instructions are preserved in [legacy README](docs/legacy-README.md).

## Modules

A module installs its packages and deploys its configuration. Modules can be
combined; dependencies are ordered and run once. Packages use `pacman -S --needed`.
Normal package transaction/conflict prompts remain visible. AUR packages use yay;
if absent, yay-bin is built as the normal user. No automatic source pulls/resets.

| Module | Packages / configuration | Desktop |
| --- | --- | --- |
| base | Build tools, bc, Firefox, manuals, pacman-contrib, playerctl, powertop, unzip, words, wget, notifications, xdg-utils, openssh; paccache.timer | Yes |
| git | git, lazygit | Yes |
| xorg | Xorg/xinit and used X utilities, scrot/xclip/xdotool, unclutter; session and helper scripts | Yes |
| dmenu | Your dmenu source, built to /usr/local | Yes |
| dwm | Your DWM source, fonts and bar; depends on xorg/dmenu | Yes |
| alacritty | Alacritty, native Mesa, existing TOML | Yes |
| zsh | zsh, Starship, packaged autosuggestions/highlighting, state/cache separation, login shell | Yes |
| root-config | zsh + neovim dependencies; /root home, shared config symlinks, separate runtime directories | Yes |
| dash | Dash as /usr/bin/sh, pacman preservation hook | Yes |
| pipewire | PipeWire, audio, ALSA/Pulse compatibility, WirePlumber, pulsemixer, pactl | Yes |
| fcitx | Fcitx5 GTK/Qt, Hangul, Mozc, existing profile and Catppuccin theme | Yes |
| keyd | keyd and repository default.conf; optional KEYD_CONFIG override | Yes |
| dunst / picom / feh | Notifications, official Picom with blur/transparency, wallpaper | Yes |
| clipmenu | Clipboard history, session-owned clipmenud; depends on dmenu | Yes |
| lf | lf, ueberzugpp, jq, file/chafa, dragon-drop (AUR); image previews and drag/drop | Via cli |
| cli | lf plus ncdu, btop, fzf, ripgrep, Zathura/poppler with existing theme | Yes |
| neovim | Neovim, build/search tools, separate gitnvim config checkout | Yes |
| fonts | Source Han JP/KR, Hanazono, JetBrains Mono Nerd, JoyPixels (AUR) | Yes |
| polkit | lxqt-policykit agent, GTK desktop portal backend/preference | Yes |
| bluetooth | bluez/utils, bluetooth service and menu; depends on dmenu | No |
| media | nsxiv, mpv | No |
| easyeffects | PipeWire dependency, presets/assets and opt-in session startup | No; requires inputs |
| gaming / steam | Steam, selected native/32-bit GPU libraries; optional GameMode, MangoHud | No |

No JACK, gaming multilib, Bluetooth or EasyEffects is requested by desktop.
Native graphics support is allowed; proprietary/hybrid GPU setup still needs a
hardware-specific review. Installing openssh does not enable sshd; powertop is not
automatically enabled. Enable fstrim.timer manually after checking storage support.
LANG/locale generation remain unchanged (the intended baseline is C.UTF-8 plus
generated en_US.UTF-8).

## Configs and sources

User configs are linked to Git. Revised startup, shell, lf, Fcitx and Picom configs
are under `config/`; unchanged Alacritty, Dunst, Starship and Zathura configs retain
their existing locations. Old files stay intact for the running desktop. The
installer deploys individual executable scripts, never replaces all of
`~/.local/bin`. If that directory was itself a link, it is backed up and copied
into a real directory first, preserving unrelated scripts and original sources.

Repositories are verified against their origins (HTTPS URLs, case-insensitive
names, optional .git suffix). Unexpected paths/remotes stop installation. Existing
repositories are reused without updating or cleaning. Legacy DWM/dmenu checkouts
under `~/workspace/suckless` are copied, including local changes, to
`~/workspace/git/jondwm` and `~/workspace/git/dmenu`. The Neovim checkout is copied
from `~/.config/nvim` into `~/workspace/git/gitnvim` before linking the config path.
Neovim receives a checked, backed-up patch for account-relative Java paths and
per-account plugin lockfiles. Unrelated local edits are preserved; conflicting
patch contexts stop the migration rather than overwrite them. Reruns recognize
the migrated settings even after local edits, including disabling the website
upload autocmd; incomplete migrations still stop without modifying the checkout.
No other automatic
source update is performed.
Absent sources are cloned from the inspected remotes:

- https://github.com/JohnsoNNN64/jondwm
- https://github.com/Johnsonnn64/dmenu
- https://github.com/Johnsonnn64/gitnvim
- https://github.com/catppuccin/fcitx5

Builds run as the user in temporary snapshots. Retired mount bindings are stripped
from the DWM build snapshot, leaving source files untouched. Only final staged
binaries/manuals are installed with sudo. The bar remains sourced from jondwm;
a generated runtime copy in `~/.local/state/installdoc/bar.sh` adapts its old palette
path. Re-run dwm after editing bar code. Existing bright_up/bright_down and
game-specific DWM bindings need their external scripts; they are not invented here.

## Before deploying on an existing machine

Inspect `--dry-run` first. It reads paths/remotes and prints operations but creates
no backups, clones, packages, service changes, or directories. Builds are shown as
helper calls; their temporary compilation and /usr/local installation are described
above. All requested module names, keyd config paths, and EasyEffects/gaming prerequisites are
checked before changes begin. This is fail-fast, not a transactional rollback:
completed earlier modules stay applied if a later operation fails.

- keyd uses the repository's `default.conf` for now, mapping Esc to a navigation
  layer and Right Alt to Alt/Pause. To use another mapping, set
  `KEYD_CONFIG=/absolute/path/to/reviewed.conf`.
- The zsh module now migrates the inspected legacy global startup settings:
  `/etc/zsh/zshenv` exports `ZDOTDIR="$HOME/.config/zsh"`, evaluated at shell
  startup. `/etc/zsh/zprofile` retains /etc/profile sourcing without explicitly
  sourcing the user's .zprofile twice. Unrelated settings are preserved and
  originals backed up. Unsupported custom sourcing is rejected during preflight,
  including dry-run; the known configuration no longer requires manual edits.
- `root-config` is included in desktop and can run independently. It prepares
  /root and its links, backs up conflicts and /etc/passwd, then uses
  `usermod -d /root -s /usr/bin/zsh root`. It never uses `-m`, moves /home/john,
  or recursively changes ownership. Existing root parent-directory symlinks
  require review; root runtime symlinks are backed up and replaced by local dirs.
- Preserve a usable TTY and backups before changing X, keyboard, shell or network
  configuration. Do not run a full conversion merely to test the installer.

System paths managed when their modules run:
`/etc/X11/xinit/xserverrc`, `/etc/keyd/default.conf`,
`/etc/pacman.d/hooks/bash-update.hook`, `/usr/bin/sh`,
`/usr/local/bin/{dwm,dmenu,dmenu_path,dmenu_run,stest}`, associated manual pages,
`/etc/zsh/zshenv`, `/etc/zsh/zprofile`, root's config links, and root/user passwd
home/shell fields as described above. System startup files are root-owned copies;
the chosen root application configs are shared symlinks.
Re-run the owning module after editing their tracked sources.

## Manual networking setup

Networking is configured separately; the installer has no `network` module.
Keep an already working setup. If you choose NetworkManager with systemd-resolved,
the following steps reproduce the former module's setup. Run from this repository
as your normal user. Resolve competing network managers and inspect existing
NetworkManager overrides first, from a local TTY with connection profiles saved.

Install NetworkManager using your existing package databases:

```sh
sudo pacman -S --needed networkmanager
```

Back up the existing resolver file/link and any previous managed config:

```sh
network_backup="/var/backups/installdoc/network-$(date +%Y%m%dT%H%M%S)-$$"
sudo mkdir -p "$network_backup"
if [ -e /etc/resolv.conf ] || [ -L /etc/resolv.conf ]; then
    sudo cp -a /etc/resolv.conf "$network_backup/resolv.conf"
fi
if [ -e /etc/NetworkManager/conf.d/20-installdoc.conf ] || [ -L /etc/NetworkManager/conf.d/20-installdoc.conf ]; then
    sudo cp -a /etc/NetworkManager/conf.d/20-installdoc.conf "$network_backup/20-installdoc.conf"
fi
```

Deploy [system/networkmanager.conf](system/networkmanager.conf), which selects
`dns=systemd-resolved` and `wifi.backend=wpa_supplicant`. NetworkManager sends
connection DNS settings to resolved with this DNS mode; see its
[configuration reference](https://networkmanager.dev/docs/api/latest/NetworkManager.conf.html).

```sh
sudo mkdir -p /etc/NetworkManager/conf.d
sudo install -m 644 -o root -g root system/networkmanager.conf /etc/NetworkManager/conf.d/20-installdoc.conf.new
sudo mv -fT /etc/NetworkManager/conf.d/20-installdoc.conf.new /etc/NetworkManager/conf.d/20-installdoc.conf
sudo systemctl enable --now systemd-resolved
sudo ln -sfT /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sudo systemctl enable --now NetworkManager
sudo nmcli general reload conf
```

Check connectivity and DNS, including after a reboot:

```sh
nmcli device status
resolvectl status
resolvectl query archlinux.org
getent hosts archlinux.org
```

Removing the installer module does not undo networking changes from earlier runs.
Backups from those runs remain under `/var/backups/installdoc/`.

## Shared user/root configuration

Both accounts read the same source files:

| Link | Target |
| --- | --- |
| `~/.config/zsh`, `/root/.config/zsh` | `installdoc/config/zsh` |
| user Neovim config, `/root/.config/nvim` | `~/workspace/git/gitnvim` (normal user's checkout) |
| user/root `starship.toml` | `installdoc/starship.toml` |

The prepared `config/zsh` is used instead of changing the old top-level `zsh`
directory currently used by the running shell. Config edits take effect for both
accounts without copying. This intentionally makes root execute user-writable
configuration, as requested. Use a fresh root login (`sudo -i`) after migration;
existing root shells retain their previous HOME until exited.

Only configs are shared. Root history/completions live in /root/.local/state/zsh
and /root/.cache/zsh. Shared zsh startup resets root's XDG paths to its own HOME;
normal users retain their configured XDG defaults. Root never starts X.
Neovim plugins, caches, Java workspaces and state resolve per account. Each account
seeds its own state-directory lazy-lock.json from the shared repository lockfile
once; subsequent plugin updates do not write a root-owned lockfile into Git.
The existing website upload-on-save autocmd runs only in normal-user sessions.
Neovim plugin downloads/updates still belong to its separate configuration.

## Session behavior

X starts only after an interactive normal-user tty1 login without DISPLAY or SSH.
Arch xinit resource/keymap setup and executable xinitrc.d hooks are retained.
DISPLAY, optional XAUTHORITY, session and input-method variables are imported into
the systemd/D-Bus user environment. No extra dbus-launch session is created.
The original X server repeat arguments (`-ardelay 0 -arinterval 0`) are preserved.

The session starts installed dunst, Fcitx5, Picom, clipmenud, the polkit agent,
unclutter and the bar, and cleans up processes it owns when DWM exits. A runtime
lock rejects duplicate session launches. A lock left by a forced kill may need
manual removal after verifying no session remains. PipeWire uses user units,
never background commands. Disable other legacy startup paths before switching.

Wallpaper remains `~/personal/pictures/wall.png`, with explicit black fallback.
Machine-specific monitor/touchpad commands can go in executable
`~/.config/installdoc/display.sh`; the hardcoded dual-monitor script is not run on
all hosts. Standalone fcitx/feh/polkit modules integrate with the managed X session;
on another session, load their environment/startup commands there explicitly.
Re-login to apply shell and X changes. The screenshot/Firefox paste freeze has
not been diagnosed or claimed fixed.

## Backups and recovery

Conflicting user paths are moved to
`~/.local/state/installdoc/backups/<timestamp>-<pid>/<absolute-path>/original`.
Each target gets a separate directory so parent symlink backups cannot redirect
child backups into the original source. Correct links are left alone on reruns.
System originals are copied under
`/var/backups/installdoc/<timestamp>-<pid>/<absolute-path>`.
The zsh migration stores originals at `<absolute-path>/original` beneath that
backup directory. Root migration uses its private `root-config/` subdirectory
with the same `/original` layout, plus `/displaced` for replaced conflicts.
To undo the root account change, restore its former home/shell fields with
usermod using the saved passwd entry; do not overwrite the whole current passwd
file, since other accounts may have changed in the meantime.

To restore, stop the affected application, inspect the saved original, move the
new target aside, then move the user original (or sudo-copy the system original)
back to its original path. Do not bulk-copy the entire backups tree. Restore a
parent directory link and its children deliberately, not simultaneously. Package
installation and service enablement are not automatically rolled back.

To restore Bash as /bin/sh, disable the managed hook first (and inspect any legacy
hook in /usr/share/libalpm/hooks), then run `sudo ln -sfT bash /usr/bin/sh`.
Do not replace /usr/bin/bash itself. Keep a working shell open during recovery.

## Optional inputs and later work

EasyEffects requires the actual exported config tree in `optional/easyeffects/`,
including presets, autoload rules and referenced assets. It fails before package
changes if this input is absent. Validate external asset paths and the autoload
selection before using it.

### Steam and gaming

`steam` is an alias that depends on `gaming`; requesting both installs once.
Select the actual GPU vendors with `GAMING_GPU`: `amd` (Mesa/RADV), `intel`
(Mesa/ANV), or `nvidia` (the official NVIDIA userspace stack). Space-separated
selections support hybrid systems, for example `GAMING_GPU='intel nvidia'`.
NVIDIA requires an already configured compatible kernel driver and installed
`nvidia-utils`; kernel driver selection and hybrid offload configuration remain
host-specific. Older GPUs requiring legacy drivers need a separate setup.

```sh
# This desktop has an AMD Radeon GPU:
GAMING_GPU=amd ./install.sh --dry-run steam
# Optional tools are explicitly selected; the default is Steam only:
GAMING_GPU=amd GAMING_EXTRAS='gamemode mangohud' ./install.sh --dry-run gaming
```

Before installing, enable `[multilib]` and its `Include` line in
`/etc/pacman.conf`, then manually run `sudo pacman -Syu`. The installer checks
the effective repository configuration and local package availability before
any modules run. It never edits pacman.conf, refreshes databases, or upgrades
the system. Dry-run prints the package plan and notes missing prerequisites.
Once multilib is ready, run `GAMING_GPU=amd ./install.sh steam`.

The package transaction explicitly selects native and 32-bit Vulkan providers
to avoid pacman's default provider choice. It includes `lib32-libpulse` for
PulseAudio/PipeWire-Pulse compatibility; Steam's package dependencies supply
its required ALSA/PipeWire libraries. Package choices follow the
[Arch Steam package](https://archlinux.org/packages/multilib/x86_64/steam/).
No JACK stack or audio service reconfiguration is requested.

Start Steam as your normal user and select Proton under Steam's Compatibility
settings as needed. Optional per-game launch options include
`gamemoderun %command%` or `mangohud %command%`;
install the corresponding extra first. Proton downloads remain managed by Steam.
Protontricks, custom Proton builds, umu-launcher, NTSync configuration, emulators,
and per-game fixes are separate work.

[THEMING.md](THEMING.md) inventories real color sources and reload/rebuild behavior.
Central theme generation, host profiles, game-specific setup and
source-update automation are separate work.

## Development checks

```sh
sh tests/bootstrap.sh
sh tests/gaming.sh
sh tests/migration.sh
sh tests/neovim-migration.sh ~/.config/nvim
shellcheck -x install.sh installer/*.sh config/x11/xinitrc config/x11/autostart \\
  config/bin/* config/lf/preview config/lf/cleaner tests/*.sh
# Build and stage only; no sudo or system install:
sh installer/build.sh ~/workspace/suckless/jondwm/dwm dwm "$PWD" /tmp/unused --check
sh installer/build.sh ~/workspace/suckless/dmenu dmenu "$PWD" /tmp/unused --check
```

Package/session references: [Arch xinit](https://wiki.archlinux.org/title/Xinit),
[systemd user environment](https://wiki.archlinux.org/title/Systemd/User),
[official Picom configuration](https://github.com/yshui/picom/blob/next/man/picom.1.adoc),
[ueberzugpp](https://github.com/jstkdng/ueberzugpp), and Arch's
[zsh autosuggestions](https://archlinux.org/packages/extra/any/zsh-autosuggestions/files/)
and [syntax highlighting](https://archlinux.org/packages/extra/any/zsh-syntax-highlighting/files/)
package file lists. Package availability can change; stale databases must be handled
with a manual system update.
