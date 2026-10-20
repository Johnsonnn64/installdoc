# Validation record — 2026-10-04

The installer has not been applied to the running desktop. No packages, services,
login shells, /bin/sh, network files or home deployment links were changed.
Original live config files remain intact. A pre-implementation snapshot is at
`/tmp/installdoc-before-bootstrap-20261004.tar.gz` (temporary storage, not a durable
personal backup). New runtime configs are under `config/`.

## Passed

- `sh tests/bootstrap.sh`: help; unknown-module rejection before work; module
  dependency deduplication; missing gaming-input rejection before work; dry-run
  file/command non-mutation; user conflict backup; dangling-link backup; correct
  link reruns; parent-symlink detachment without changing source contents or inode;
  unrelated-file preservation; dirty-checkout preservation; unexpected-origin
  rejection; explicit first-failure handling and module context.
- POSIX shell syntax with Dash for installer/helpers/session/preview scripts;
  zsh syntax for the revised shell startup files.
- ShellCheck 0.11.0, including installer, helpers, revised executable scripts,
  and tests. It was downloaded into /tmp, not installed on the host.
- Full desktop dry-run and optional Bluetooth/media dry-run. Logs are in
  `/tmp/installdoc-desktop-dry-run.log` and
  `/tmp/installdoc-optional-dry-run.log`.
- DWM and dmenu compiled and completed staged `make install` in isolated temporary
  copies of the inspected local checkouts. No sudo install ran. DWM's retired
  mount commands/bindings were removed only from the build snapshot.
- Generated DWM bar passes Dash syntax; canonical palette path and volume printf
  adaptation were inspected. Bar hardware/audio behavior is not validated.
- Official Arch Picom 13-2, extracted under /tmp, ran with `config/picom.conf` on
  an isolated Xvfb display for three seconds until the test timeout. No warnings
  or early exit. The sandbox initially blocked the X socket; the successful check
  ran with approved access outside it. The running desktop compositor was untouched.
- Arch package file lists verified zsh plugin paths; upstream ueberzugpp and the
  installed CLI expose the compatible layer/JSON interface. AUR RPC confirmed
  dragon-drop and ttf-joypixels exist. No AUR build/install was attempted.
- `git diff --check`.

## Required before claiming full desktop acceptance

Use a disposable Arch VM for package transactions, clone-only installation,
privileged backups and reruns, tty1 login/X shutdown, session D-Bus, Dash hook
after package updates, user audio units, network/DNS after reboot, portal/polkit
prompts, clipboard/screenshots, input methods, and normal-user shell behavior.

Test actual hardware separately: keyd mapping, keyboard unplug/replug repeat,
monitor layouts, lf image placement in Alacritty, blur appearance/GPU performance,
audio devices, proprietary/hybrid graphics, laptop battery/brightness bar behavior.
The source DWM still has external bright_up/bright_down and game bindings; those
scripts were not found or supplied. Retired mounting bindings are excluded from
the installed build.

The complete X startup/session cleanup is syntax-reviewed but not end-to-end
tested. Neovim's source stays separate; its plugins download on first startup
according to its own configuration and were not upgraded/tested here.

## Inputs and migration gates

- keyd: uses the repository's default.conf for now (Esc navigation / Right Alt
  mapping); KEYD_CONFIG can override it. Hardware behavior remains untested.
- Existing-machine zsh: the known global hardcoded ZDOTDIR and duplicate profile
  sourcing now have an automatic backed-up migration. Unknown custom forms still
  need review; preflight checks these even during dry-run.
- Root: the user selected live shared zsh/Neovim config symlinks with /root as
  root's home. The root-config module now implements this; it has not been applied
  to the running machine. Actual privileged deployment and fresh root login remain
  VM acceptance checks, not completed live tests.
- EasyEffects: provide presets, autoload choice/rules, referenced external assets.
- Gaming: select GAMING_GPU and optional GAMING_EXTRAS. Enable multilib and
  perform a manual full update before installation. Package transactions and
  actual Steam/game behavior still require machine testing.
- Network: now configured manually using the README instructions; the installer
  no longer manages network services, NetworkManager config, or /etc/resolv.conf.

The initial optional-module gates deliberately fail even for their dry-run when
required inputs are missing. The desktop dry-run uses the repository's default.conf
for keyd unless KEYD_CONFIG supplies another mapping.

## Desktop migration follow-up

Implemented global account-relative ZDOTDIR, removal of the known duplicate
global profile source line, the root-config module, and Neovim shared-home patch.
Root-config is part of desktop and depends on zsh/neovim. User/root shell configs
share config/zsh; Neovim remains a separate repository. No live system deployment
or edits to the existing Neovim checkout occurred.

Additional passing tests:

- `sh tests/migration.sh`: preserved unrelated global settings, backup contents,
  non-mutating preflight, unknown override rejection, repeat-run idempotence,
  account-relative ZDOTDIR, shared root config links, preserved user home data,
  separated runtime symlinks, and mocked passwd update without `-m`.
- `sh tests/neovim-migration.sh ~/.config/nvim`: patch applied to a temporary copy
  of the actual checkout; backed-up originals, unrelated local file preserved,
  rerun without extra backups; changed Lua files parsed without starting plugins.
- Offline Lua API fixtures for user/root lockfile separation, preservation of
  existing account locks, root Java paths, and exclusion of root upload-on-save.
- Bootstrap regression suite, ShellCheck, and root-config/desktop dry-runs.

These fixtures do not replace a privileged VM migration, real root shell startup,
or full Neovim/plugin startup. The initial full-desktop validation gaps above remain.

## Steam/gaming implementation — 2026-10-11

The local PCI inventory identifies an AMD Radeon Navi 23 GPU. Multilib is
currently disabled. No packages, repositories, services, or system configs were
changed while implementing gaming.

- `sh tests/gaming.sh`: offline package selection for AMD, Intel/AMD hybrid, and
  NVIDIA; native/32-bit packages; selected extras; package deduplication; invalid
  selection rejection; NVIDIA prerequisite; disabled multilib, missing database,
  and unavailable package rejection; dry-run prerequisite notes; Steam dependency.
- `sh tests/bootstrap.sh`: installer regression checks, including rejection of
  missing gaming hardware selection before any requested module runs.
- `GAMING_GPU=amd ./install.sh --dry-run steam gaming`: one gaming transaction,
  AMD native/32-bit providers, and a manual multilib/full-update prerequisite note.
- Dash syntax checks and whitespace checks for changed installer/docs/tests.

Actual multilib package resolution/installation, Steam startup, Proton games,
optional overlays, NVIDIA driver compatibility, and hybrid offload remain
machine acceptance checks. NVIDIA kernel drivers are configured separately.
