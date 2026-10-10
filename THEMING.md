# Theme inventory

Inspected 2026-10-04. This is an inventory, not a palette generator. Existing
appearance is retained; centralized generation and host profiles remain deferred.

| Component | Source | Current settings | Apply changes |
| --- | --- | --- | --- |
| DWM | `~/workspace/git/jondwm/dwm/catppuccin.h`, included by `config.h` | Catppuccin color constants and scheme assignments | Re-run `dwm`, restart DWM |
| DWM bar | `~/workspace/git/jondwm/bar/catppuccin` | Mixed Catppuccin palette: base `#1E1D2D`, blue `#87B0F9`, green `#A6E3A1` | Re-run `dwm` if bar code changed; restart X for colors |
| dmenu | `~/workspace/git/dmenu/config.h` | Background `#1E1D2D`, selected text `#CDD6F4`, highlight `#89B4FA`; cyan out scheme | Re-run `dmenu`; next invocation |
| Alacritty | `alacritty.toml` | Catppuccin Mocha ANSI, cursor, selection, search, dim, indexed colors | Config reload / reopen terminal |
| Dunst | `dunstrc` | Catppuccin colors per urgency; blue default border, peach critical border | Restart dunst / X |
| Fcitx5 | `config/fcitx5/conf/classicui.conf` | `catppuccin-mocha-blue` for light and dark theme | Restart Fcitx5 / X |
| Fcitx5 theme | `~/workspace/git/fcitx5/src/catppuccin-mocha-blue/` | Upstream Catppuccin theme, separately cloned | Restart Fcitx5 |
| Zathura | `zathura/zathurarc`, `zathura/catppuccin` | Catppuccin Mocha including PDF recoloring | Reopen Zathura |
| Xresources | `config/x11/Xresources_catppuccin` | Catppuccin terminal palette; cursor size 24 | `xrdb -merge` and restart affected clients |
| Linux TTY | `config/zsh/.zshrc`, tty color section | Catppuccin escape sequences on `TERM=linux` | Start interactive zsh on TTY |
| Starship | `starship.toml` | Named ANSI colors: yellow, green, red, purple | Next prompt; appearance also depends on terminal palette |
| Picom | `config/picom.conf` | No palette; unfocused Alacritty 65% opacity, dual-kawase strength 10, no animation/fading | Restart Picom / X |
| lf | `config/lf/lfrc`, `config/lf/icons` | ANSI black line numbers, icon table; terminal colors | Restart lf |
| fetch | `config/bin/fetch` | ANSI palette and random accent, terminal-dependent | Run fetch |
| Neovim | `~/workspace/git/gitnvim/lua/giga/colorscheme.lua` | Catppuccin Mocha with integrations; configuration remains a separate repo | Restart Neovim / reload its colorscheme |
| GTK (live machine only) | `~/.config/gtk-3.0/settings.ini` | Raleigh, hicolor, `catppuccin-mocha-dark-cursors`, Sans 10 | Restart GTK apps; not managed by this installer |

The inspected DWM/dmenu sources currently live under `~/workspace/suckless`.
Installation copies those checkouts to the canonical paths above, preserving
local changes and leaving originals untouched. Neovim currently lives in
`~/.config/nvim`; its checkout is similarly preserved before linking.

Legacy top-level `x11/`, `zsh/`, `lf/`, and `picom.conf` remain untouched because
the running desktop uses them. New deployments use `config/` for these components.
Don't edit both versions: after deployment, use the source identified above.

A later palette generator should keep non-color settings separate, explicitly
record generated-file ownership, and generate DWM/dmenu headers before rebuilding.
It should integrate with, rather than absorb, the separate Neovim repository.
