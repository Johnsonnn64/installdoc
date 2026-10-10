# Arch + DWM bootstrap: implementation handoff

Date: 2026-10-04 (America/Los_Angeles)

### Follow-up decisions (override the root proposal below)

Prioritize migration of the existing desktop. The user selected a system-wide
`export ZDOTDIR="$HOME/.config/zsh"` evaluated at shell startup, with both normal
user and root configs symlinked to the same repository zsh directory. Root gets
a separate `/root` home without moving/chowning the normal user's home. Neovim
likewise shares its separate config checkout by symlink. Share configuration,
keep history/cache/data/state per account; no root-owned config-copy workflow.
The prepared installer source is `config/zsh`, preserving the old live `zsh/`
directory until deployment. This choice is now implemented by `root-config` in
the desktop profile; actual privileged deployment is still pending validation.

## 1. Purpose and status

Build a reusable, modular post-install configuration tool for my Arch Linux desktop and laptop, starting from my existing `installdoc` dotfiles repository and its README. Preserve my actual workflow while replacing the accumulated manual setup steps with predictable automation.

This document records decisions from the planning conversation. **No installer has been implemented or run as part of this handoff.** The repositories and their current contents were not supplied to this document-writing turn. Exact repository URLs, package lists, config contents, and build requirements must be read from the real repositories before implementation; do not invent them from the examples below.

The immediate task for the next agent is to inspect the repositories, reconcile this plan with their contents, then implement the core installer. Centralized theme generation and other future work are separate milestones.

## 2. Agreed requirements

- Assume Arch is already installed, bootable, online, and has a normal user with working sudo.
- No partitioning, bootloader configuration, OS installation, or automatic reinstall.
- Support a full `desktop` setup and independently runnable modules, including multiple modules in one invocation.
- Running a module means installing its dependencies **and configuring it**, not merely installing its package.
- Make repeat runs safe: no duplicate config blocks, nested symlinks, duplicate daemons, or needless replacement of existing files.
- Stop at the first real failure and name the failed operation/module.
- Never run `pacman -Syu` automatically. System upgrades are handled manually. Do not introduce standalone `pacman -Sy` either.
- Use `pacman -S --needed` for repository packages, subject to normal transaction/conflict handling.
- Use `yay-bin` as the AUR helper; AUR installation can be automatic without an additional per-package permission question. Build as the normal user, never root.
- Retain the Git-based dotfile workflow: editing deployed user configs should edit the tracked repository through symlinks.
- Back up conflicting existing configs before replacing them. Preserve local source changes.
- Write the installer in POSIX `sh`, with `set -eu` and explicit handling of important failures. Do not assume Bash arrays, `[[ ... ]]`, `BASH_SOURCE`, or Bash-specific traps/options. Avoid pipelines that conceal failures; `set -e` alone is not complete error handling.
- Provide meaningful `--help` and a genuinely non-mutating `--dry-run`.
- Do not implement host profiles yet; leave room for them later.

Planned interface:

```sh
./install.sh desktop
./install.sh pipewire
./install.sh fcitx
./install.sh zsh
./install.sh pipewire fcitx media
./install.sh bluetooth
./install.sh easyeffects
./install.sh gaming
./install.sh --dry-run desktop
./install.sh --help
```

`desktop` means my normal usable DWM environment, not the smallest possible package count. Optional software stays separately selectable.

## 3. Final decisions at a glance

| Area | Decision |
| --- | --- |
| Session | DWM, automatically launched after normal-user login on tty1; no display manager or automatic login requested |
| Sources | Canonical root: `~/workspace/git/` |
| Dotfiles | Keep `installdoc` as the source of truth; deploy user configs with symlinks |
| DWM/dmenu | Build my own repositories; planned install prefix `/usr/local` |
| Bar | Keep the bar in `jondwm`; update its hardcoded path to the canonical location |
| Neovim | Install Neovim with desktop; its configuration remains in its own repository |
| Login shell | Change the normal user's shell to zsh |
| `/bin/sh` | Replace with Dash by default in `desktop`, preserving the package-update hook approach |
| Network | NetworkManager with its default backend + systemd-resolved |
| Compositor | Replace `picom-ftlabs-git` with official `picom`, preserving blur/transparency and no animations |
| AUR | `yay-bin`, automatic when a requested module needs AUR packages |
| Audio | PipeWire + WirePlumber + PulseAudio compatibility + ALSA integration + pulsemixer; no JACK |
| EasyEffects | Separate optional module; preserve my EQ presets; excluded from desktop |
| Bluetooth | Separate optional module; excluded from desktop |
| Input | Fcitx5 for English/Korean/Japanese, with Catppuccin theme |
| keyd | Included in desktop; laptop needs a different mapping from hardware-programmed desktop keyboards |
| Polkit | Planned lightweight standalone agent: `lxqt-policykit` |
| Browser | Firefox in desktop |
| Screenshot | Keep scrot + xclip + xdotool |
| Wallpaper | Keep Feh and `~/personal/pictures/wall.png`; missing image should leave a black background |
| Locales | Preserve `LANG=C.UTF-8` and the existing generated `en_US.UTF-8`; no extra locales by default |
| Fonts | Retain the current README's font set |
| Themes | Create `THEMING.md` now; central palette/theme generator later |

Later clarifications override earlier answers: Bluetooth and EasyEffects are optional even though initially listed for base. Neovim's config must not be silently merged into `installdoc`.

## 4. Manual preparation before coding

These are inputs to collect, not instructions to modify the running system immediately. Start coding once the main repositories and current configs are accessible; optional-module inputs can follow separately.

### Required inputs for the core installer

- [ ] Provide access to the actual `installdoc` repository, including its current README and scripts.
- [ ] Provide the exact repository URLs/branches for `jondwm` and `dmenu`, unless already recorded in `installdoc`.
- [ ] Provide the Neovim config repository URL and its expected deployment path. Keep it separate.
- [ ] Preserve current local changes: inspect `git status`, save or commit the intended versions, and make a backup before any reorganization. Do not discard uncommitted changes just to make the tree clean.
- [ ] Compare live configs with the repository and bring over any intended changes that are currently untracked. In particular: X startup, keyboard repeat, zsh, keyd, picom, Fcitx5, lf previews, and the DWM bar.
- [ ] Supply the actual laptop keyd mapping, or state that it is not ready. Do not infer it from the desktop config.
- [ ] Record which keyd mappings still need to run on desktop, given that desktop keyboards already implement some mappings in hardware.

### Inputs needed before optional modules are finished

- [ ] Export/copy EasyEffects presets and any referenced impulse-response or other external assets. Record which preset should load automatically.
- [ ] Before implementing gaming graphics selection, identify the target GPUs and any hybrid-GPU setup. Do not assume both machines use the same driver stack.
- [ ] Identify any extra Steam/Proton tools actually wanted from the tentative gaming list in section 10.

### Existing-machine detail to resolve before root configuration is applied

- [ ] Record whether root currently has `/home/john` as its passwd home on each machine.
- [ ] Settle the root configuration deployment method in section 8. The goal is shared appearance/behavior with a separate `/root`, not shared writable runtime state.

You do **not** need to manually move all repos, rewrite configs, change `/bin/sh`, restore root's home, or replace the network stack before the installer is written. Those are implementation/migration tasks. Do not reinstall first just to supply these inputs.

### Before a real clean-install run, rather than before coding

- [ ] Back up personal data, SSH material, browser data, dotfiles, local source changes, and optional EQ assets.
- [ ] Complete the normal Arch install, create the user, grant sudo, and establish internet access.
- [ ] Update Arch manually as appropriate before package installation. If stale package databases cause failures, update manually; the installer must not initiate an upgrade or partial refresh.
- [ ] Make the repositories accessible. A private SSH remote may require restoring SSH access first; avoid designing bootstrap to depend on an SSH key that has not yet been restored.
- [ ] Keep a usable TTY/recovery path available while validating X startup, keyboard configuration, and networking.
- [ ] Restore the wallpaper if desired. Its absence is not a setup failure.

## 5. Source locations and repository layout

Canonical locations:

| Item | Location |
| --- | --- |
| Git source root | `$HOME/workspace/git` |
| Main config repository | `$HOME/workspace/git/installdoc` |
| DWM | `$HOME/workspace/git/jondwm` |
| dmenu | `$HOME/workspace/git/dmenu` |
| Neovim config source | Under the same Git root; retain its actual repository name |
| DWM bar | `$HOME/workspace/git/jondwm/bar/bar.sh` |
| Wallpaper | `$HOME/personal/pictures/wall.png` |
| User conflict backups | `$HOME/.local/state/installdoc/backups/<timestamp>/` |

Absent repositories are cloned; existing repositories are used without automatic pull/reset/clean. Detect unexpected remotes or non-repository path conflicts and explain them rather than overwriting. Never silently relocate a dirty checkout. Document the initial clone location so relocation is unnecessary in the common path.

Proposed layout inside `installdoc` (adapt to the real tree):

```text
install.sh
README.md
THEMING.md
config/
  alacritty/
  dunst/
  fcitx5/
  lf/
  picom/
  x11/
  zathura/
  zsh/
system/
  keyd/
  xserverrc
  bash-update.hook
bin/
  bluetoothdmenu.sh
  bookmarks
  fetch
  monitor
  power.sh
  screenshot
```

Splitting installer helpers/modules into additional files is fine if it makes maintenance easier; avoid a framework larger than the task. Preserve executable bits and update every reference affected by moving files.

For user configs, a link such as `~/.config/zsh -> ~/workspace/git/installdoc/config/zsh` keeps edits tracked. System-owned files require explicit installation/ownership handling; do not extend user symlinking blindly to privileged configuration. Keep their tracked source in Git and make re-running the module apply changes.

## 6. Modules and package scope

The current README's `## base installs` is the baseline, with the agreed removals and optional splits below. The following is a planning inventory from the conversation, **not a verified transcription of that README or a final dependency lockfile**. The implementing agent must reconcile exact names and current package availability against the repositories and official package documentation.

| Module | Intended content | In desktop? |
| --- | --- | --- |
| `base` | Baseline tools and documentation from README; Firefox, SSH, desktop integration dependencies | Yes |
| `git` | git + lazygit; lazygit is not optional when installing my Git workflow | Yes |
| `network` | NetworkManager + resolved configuration | Yes |
| `xorg` | X server/xinit, X utilities, keyboard-repeat setup, screenshots, clipboard utilities | Yes |
| `dwm` | Build my DWM and deploy startup/bar integration | Yes |
| `dmenu` | Build my dmenu | Yes |
| `alacritty` | Terminal and tracked config | Yes |
| `zsh` | Shell, plugins, prompt, history/cache separation, user shell change | Yes |
| `dash` | Dash as `/bin/sh` plus package-update hook | Yes |
| `pipewire` | Audio stack and pulsemixer | Yes |
| `fcitx` | Input methods, environment, theme, profile | Yes |
| `keyd` | Service with an explicitly appropriate keyboard config | Yes |
| `dunst` | Notifications and config | Yes |
| `picom` | Official package and compatible config | Yes |
| `feh` | Wallpaper behavior | Yes |
| `clipmenu` | Clipboard history and X-session daemon | Yes |
| `cli` / `lf` | lf, ncdu, btop, fzf, ripgrep; image previews | Yes |
| `neovim` | Neovim and integration with its separate config repo | Yes |
| `fonts` | Existing font set from README | Yes |
| `polkit` / desktop integration | Authentication agent and reviewed portal setup | Yes |
| `bluetooth` | bluez + bluez-utils, service, optional existing menu script | No |
| `easyeffects` | EasyEffects, EQ presets/assets, optional autostart; depends on PipeWire | No |
| `media` | nsxiv + mpv initially | No |
| `gaming` / `steam` | Steam, multilib, appropriate graphics/audio compatibility packages | No |

Baseline package candidates discussed: `base-devel`, `bc`, `firefox`, `fzf`, `man-db`, `man-pages`, `pacman-contrib`, `playerctl`, `powertop`, `ripgrep`, `unzip`, `words`, `wget`, `libnotify`, `xdg-utils`, `openssh`, `git`, `lazygit`, and `neovim`.

X candidates discussed: `xorg-server`, `xorg-xinit`, `xorg-xauth`, `xorg-xrandr`, `xorg-xset`, `xorg-xrdb`, `xorg-xprop`, `xorg-xinput`, `xdotool`, `xclip`, `arandr`, and `scrot`.

Add real dependencies discovered in scripts/build files, not a generic collection of nice-to-have utilities. Installing `openssh` does not imply enabling an SSH server. Installing `powertop` does not imply enabling automatic tuning.

Explicit removals/splits:

- Remove `bat`, `fd`, and unused rich-document lf preview dependencies. Replace any `FZF_DEFAULT_COMMAND` or preview commands that still depend on them.
- Keep lf image preview functionality; investigate `ueberzugpp` compatibility with the actual existing preview scripts.
- Do not install `dmenumount`, `dmenuumount`, or their old mounting dependencies. Remove stale bindings/references; preserve unrelated uses of a package if the audit finds them.
- Keep nsxiv/mpv in `media`. Define `zathura` placement after reading the README; its exact base/optional placement was not settled. Preserve its existing config and theme inventory either way.
- No JACK stack, gaming multilib, Bluetooth, or EasyEffects in desktop by default.

**Graphics clarification:** separating gaming from desktop means separating Vulkan/gaming-specific and 32-bit packages. Do not forbid native Mesa or necessary GPU drivers from desktop: the normal desktop, Alacritty, and Picom may require them. Resolve real native graphics dependencies while keeping the gaming additions optional. The earlier broad claim that all Mesa belongs only with Steam must not become an implementation restriction.

## 7. X session, networking, and services

### Session startup

- Start X automatically only after an interactive normal-user login on tty1, when no display is already active.
- Never start X for root or an SSH login. This is not passwordless tty autologin.
- Preserve the keyboard-repeat configuration in `xserverrc`: it exists because repeat settings reset on keyboard unplug/replug or switching keyboards. Inspect the exact existing command and arguments rather than replacing it with a casual `xset` call.
- Integrate with Arch's normal xinit setup and session D-Bus/systemd user environment. Import DISPLAY, XAUTHORITY when present, and relevant X session variables into activation environments before dependent services start. Inspect the existing/default xinit hooks; do not blindly replace them with an abbreviated snippet.
- Remove the old `dbus-launch` workaround only once the intended session-bus behavior is validated.
- Autostart the bar, dunst, Fcitx5, Picom, clipmenud, and the polkit agent as appropriate. Avoid duplicate instances on repeat setup/startup.
- Keep the wallpaper path. Set a black fallback when it is absent rather than depending on whatever background the server happened to have.
- EasyEffects starts only when its optional module has been configured.
- Keep session lifetime/cleanup coherent when DWM exits or restarts.

### Network

- Configure NetworkManager's default Wi-Fi backend; do not switch to its iwd backend as part of this work.
- Use a managed NetworkManager config with `dns=systemd-resolved`.
- Enable NetworkManager and systemd-resolved; make `/etc/resolv.conf` point to `/run/systemd/resolve/stub-resolv.conf`, backing up conflicts first.
- On an existing machine, inspect competing network/DNS services before changing anything. Do not leave multiple managers controlling the same interface or abruptly destroy the connection used for setup.
- Preserve existing connection profiles, VPNs, and credentials. No VPN rollout is included in the core project.

### Other services

- Use normal user-service/socket management for PipeWire/WirePlumber. No manual `pipewire &` or `wireplumber &` in X autostart.
- Bluetooth enables its system service only through its optional module.
- keyd is a system service; use the correct supplied mapping and avoid double-remapping hardware-programmed keys.
- `clipmenud` may stay in X autostart; do not enable a second launch path through a user service as well.
- Planned maintenance additions: enable `paccache.timer` and, where suitable for the storage setup, `fstrim.timer`. Document these in the module/README rather than adding hidden cleanup behavior.

## 8. zsh, root, and Dash

### Normal-user zsh

- Retain ZDOTDIR under `~/.config/zsh`, Starship, vi mode, autosuggestions, syntax highlighting, and the existing persistent/shared history behavior.
- Prefer packaged zsh autosuggestions/syntax-highlighting plugins over manually cloned plugins; verify package paths during implementation.
- Make XDG cache/state defaults depend on the current account's HOME. Put completion dumps and other generated files outside the Git-managed config directory.
- Automatically change the installing normal user's login shell to zsh.
- Remove `sudo` from the read-only `pacman -Q` package count in `fetch`.

### Root convenience: goal agreed, mechanism needs deliberate implementation

Current behavior on at least one daily driver is a passwd entry like `root:x:0:0::/home/john:/bin/zsh`, used for convenience. The user wants root to have the same familiar configs.

The proposed replacement is a separate `/root` home, with equivalent tracked shell configuration and separate history, cache, state, and completion files. Never move the normal user's home when restoring root's passwd home, and never recursively chown the user's home as a blanket repair.

The previous discussion proposed linking `/root/.config/zsh` directly to the user's config repository. That does share configuration, but also means root executes files writable by the normal user; it does not create a security boundary. **Recommended implementation proposal:** deploy a root-owned copy of the shared shell config through an explicit root-config action, with reapplication after edits, while leaving normal-user configs symlinked. Confirm the desired live-sharing versus explicit-sync behavior before applying root configuration; this does not block implementing the rest of the installer.

If a system-wide ZDOTDIR setting is used, evaluate `$HOME` when zsh starts rather than substituting `/home/john` during installation. Audit shared shell startup files for user-specific absolute paths and commands that should not run as root. Do not assume root needs every desktop app's configuration.

### Dash

- Default desktop setup installs Dash and points `/bin/sh` to it.
- Retain/adapt the existing pacman hook that preserves the choice after relevant package updates.
- Audit scripts labelled `#!/bin/sh` for Bashisms, including the installer and affected startup scripts. A script that genuinely requires Bash should declare Bash.
- Do not rewrite `/bin/bash` or remove Bash. User login shell remains zsh.
- Check syntax under Dash and run shell static analysis. Preserve a documented way to restore `/bin/sh` if troubleshooting requires it.

## 9. Audio, input, locales, appearance

### PipeWire and EasyEffects

`pipewire` module package target: `pipewire`, `pipewire-audio`, `pipewire-alsa`, `pipewire-pulse`, `wireplumber`, `pulsemixer`. Verify current dependency/conflict behavior when implementing, especially on machines already using PulseAudio.

EasyEffects remains optional, depends on PipeWire, restores the user's EQ setup, and gets a deliberate autostart path only when installed/configured. It must not be pulled into `desktop` through a dependency accident.

### Fcitx5 and fonts

Planned packages: `fcitx5`, `fcitx5-gtk`, `fcitx5-qt`, `fcitx5-hangul`, `fcitx5-mozc`, plus the chosen Catppuccin theme installation. Deploy existing input-method order, shortcuts, and theme settings rather than inventing new defaults. Set and validate appropriate X11 input-method environment variables.

Keep the existing JP/KR/Hanazono/JetBrains Nerd/emoji font choices from the README. Exact package names must come from the repository audit.

### Locales

Preserve the user's existing `LANG=C.UTF-8` preference and `en_US.UTF-8` generation. Do not add Korean/Japanese locales merely because those languages are typed through Fcitx. If a particular VN later requires a Japanese locale, handle that separately. Do not overwrite another existing machine's locale unexpectedly as a side effect of an unrelated module.

### Picom and screenshots

Migrate to official Picom. Inspect the real config for fork-only options, preserve the desired dual-kawase blur/transparency, and validate the resulting config and performance. Keeping blur does not mean re-enabling animations.

Keep scrot/xclip/xdotool. Rare Firefox freezes while pasting certain screenshot images were reported; the cause is unknown. Do not claim it is fixed or replace the screenshot workflow without evidence. Investigation is deferred unless reproduced during validation.

## 10. Optional gaming and convenience work

Keep gaming outside the core desktop profile, with a separate `gaming`/`steam` module. A small wrapper script is acceptable later, but it should reuse module logic rather than duplicate it. Likewise, convenience software can be installed through explicit optional modules; no automatic catch-all `nice` bundle is required.

Gaming implementation scope:

- Enable multilib only when the optional module requires it; do not enable it globally for every install.
- Respect the no-automatic-upgrade/no-`pacman -Sy` rule. If enabling multilib requires a database refresh, explain the manual full-update step and stop that module cleanly rather than silently performing a partial upgrade.
- Select native and 32-bit graphics/Vulkan packages for the actual GPU(s); do not install every vendor's stack.
- Install Steam and only the additional compatibility tools actually selected.
- Candidate extras discussed, still subject to dependency/current-package review: protontricks, umu-launcher, gamemode/lib32-gamemode, and applicable ntsync setup.
- Review actual 32-bit audio requirements. `lib32-pipewire`, `lib32-libpulse`, and `lib32-alsa-plugins` were candidates, not a requirement to force every package onto every machine.
- Blue Archive JP and visual novels motivate the optional gaming setup, but emulator/game installation, account login, per-game fixes, and guaranteed compatibility are not part of the core bootstrap.

## 11. Separate future work: centralized theming and profiles

### Do now: `THEMING.md`

Inventory every real custom color source found during repository inspection. For each, record the file path, current theme, relevant setting, and how changes take effect (live reload, restart, or rebuild).

Places to inspect include DWM, dmenu, Alacritty, Dunst, Fcitx5, Zathura, Xresources, Linux TTY colors, Starship, GTK settings, and the separate Neovim repo. These are inspection targets, not claims that all currently have custom palettes.

### Later: central palette engine

Possible design: `themes/<theme>/palette` plus `theme.sh <theme>`, generating application-specific color files. DWM/dmenu may use generated `theme.h` files and require rebuilding. Track generated-file policy clearly, preserve non-color settings, and let Neovim stay in its own repo.

Do not pick a replacement theme yet. The user likes Catppuccin integration but is becoming bored with it and wants easier future changes. A central engine is not a prerequisite for the installer.

### Other deferred work

- Full desktop/laptop host profiles; for now handle keyd's actual mapping difference explicitly.
- An explicit source-update command, if useful later. No implicit `git pull` now.
- Screenshot/Firefox freeze diagnosis if reproducible.
- New USB/phone mounting integration only if the user asks; retired mount scripts stay out.
- Additional media/CLI utilities, game-specific setup, and broader hardware tuning.

## 12. Implementation sequence for the next agent

1. Read repository instructions and the actual README/configs/build files. Inspect all involved source repos and current Git state. Identify hardcoded paths, external assets, missing executable dependencies, privileged writes, and runtime files accidentally tracked in Git.
2. Reconcile a final module/package/config map with this document. Ask only about missing inputs or real unresolved choices; do not reopen confirmed NetworkManager, Dash, Picom, or source-location decisions.
3. Implement argument validation, dependency ordering/deduplication, dry-run output, package helpers, source checkout handling, backups, symlink deployment, and failure reporting. Validate all module names before any mutation.
4. Implement independently usable core modules, then compose `desktop`. Use sudo only for system operations; never run the entire setup/AUR builds as root. Do not require X to be running to install a standalone audio module.
5. Refactor X startup, user-shell configuration, paths, lf image preview, Picom compatibility, and service activation. Make absent optional modules/assets harmless where expected, without suppressing real failures.
6. Add optional Bluetooth, EasyEffects, and media modules. Implement gaming separately once its hardware/package/manual-refresh requirements are clear.
7. Write the new README and `THEMING.md`. Explain usage, prerequisites, backups/restore, system files touched, optional modules, source updates, required manual steps, and how to apply later system-config changes.
8. Validate in a disposable Arch VM or equivalent safe target before applying a full desktop conversion to a daily driver. Report what was actually tested and any hardware-dependent checks still outstanding.

## 13. Acceptance checks

- [ ] Help lists supported modules, dependencies, and examples.
- [ ] Dry-run reports intended operations without changing files, installing packages, cloning repos, or enabling services.
- [ ] Unknown modules fail before any requested module begins making changes.
- [ ] Standalone and multi-module invocations work; shared dependencies execute once per invocation.
- [ ] Re-running setup preserves existing correct links/configs, does not duplicate daemons/entries, and does not alter dirty source trees.
- [ ] Conflicting configs are backed up with enough path information to restore them; unrelated files are preserved.
- [ ] Desktop logs into DWM from tty1; root/other TTY/SSH logins do not launch it.
- [ ] DWM/dmenu build, terminal and bar work, and wallpaper absence gives a black background without aborting startup.
- [ ] Polkit prompt, notification, clipboard/screenshot, Korean/Japanese input, and lf image preview workflows work.
- [ ] PipeWire audio and pulsemixer work without manual background daemons or JACK installation.
- [ ] DNS/networking work after reboot, with no competing managers introduced.
- [ ] Keyboard repeat survives the scenario that motivated the existing xserverrc; keyd mappings are correct for the selected keyboard.
- [ ] User-shell runtime files stay outside tracked config; any root integration keeps root runtime state in `/root`.
- [ ] `/bin/sh` resolves to Dash after setup and the preservation hook is validated; relevant shell scripts pass syntax/static checks.
- [ ] Desktop does not explicitly pull in gaming/multilib, Bluetooth, or EasyEffects; necessary native desktop graphics dependencies remain allowed.
- [ ] No automatic system upgrade, source update, partition/bootloader change, or unsolicited SSH-server enablement occurs.
- [ ] Remaining hardware/game-specific checks are recorded honestly rather than reported as completed.

## 14. Paste-ready instruction for the next chat

> Use this document as the agreed plan for refactoring my Arch `installdoc` repository into a modular POSIX-sh bootstrap/configuration tool. First inspect the actual repo README, configs, scripts, and my DWM/dmenu/Neovim repos. Preserve my workflow and local changes. Implement reusable modules plus a `desktop` profile, safe reruns, backups, dry-run, and help. Neovim config stays separate; use `~/workspace/git`; use NetworkManager + systemd-resolved; default to Dash; migrate to official Picom. Keep Bluetooth, EasyEffects, media, and gaming optional. Do not auto-upgrade Arch or pull/reset existing source repos. Create a theme inventory now and defer a centralized theme engine. Ask for missing repository/config inputs and unresolved root/keyd choices only when needed. Implement and validate the code; do not run system-changing setup against my daily driver just to test it.
