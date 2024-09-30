# Installdoc
fed up with forgetting how my system works and workarounds to some of the problems i encounter, so a comprehensive documentation for my whole arch system.

# Base Settings
## AUR helper
using YAY
```bash
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
```

## Base Installs
<details>
<summary>Pacman Packages</summary>
  
| packages | details |
| --- | --- |
| bc | cmd calcu |
| bluez | bluetooth support |
| bluez-utils | bluetooth support |
| clipmenu | dmenu for clipboard |
| feh | wallpaper |
| firefox | internet browser |
| fzf | fuzzy finder |
| lazygit | git cli |
| man | man page reader |
| ncdu | ncurses disk usage manager |
| pacman-contrib | tools for pacman |
| playerctl | media player controller | 
| powertop | tool for power management |
| pulsemixer | volume control cli | 
| ripgrep | neovim plugin dependency |
| scrot | screenshot tool |
| unclutter | make cursor disappear | 
| unzip | tool for .zip files |
| words | dictionary |
| xclip | clipboard | 
| arandr | xrandr gui | 

</details>

<details>
<summary>AUR packages: </summary>

| AUR Packages | Details |
| --- | --- |
| simple-mtpfs | reading usb devices |
| dragon-drop | drag & drop support |
| youtube-music-bin | youtube music |

</details>

one line install:  
``` bash
sudo pacman -s bc bluez bluez-utils clipmenu feh firefox fzf man-db ncdu pacman-contrib playerctl powertop pulsemixer ripgrep scrot unclutter unzip words xclip arandr
yay -S simple-mtpfs dragon-drop youtube-music-bin
```

## Fonts
fonts needed for various applications
```bash
sudo pacman -S adobe-source-han-sans-jp-fonts adobe-source-han-sans-kr-fonts ttf-hanazono ttf-joypixels ttf-jetbrains-mono-nerd
```

# Desktop Environment
## Xorg
Xorg setup
- install needed Xorg packages
```bash
sudo pacman -S xdotool xdotool xf86-input-libinput xf86-video-amdgpu xf86-video-vesa xkeyboard-config xorg-fonts-encodings xorg-mkfontscale xorg-server xorg-server-common xorg-server-devel xorg-server-xephyr xorg-server-xnest xorg-server-xvfb xorg-setxkbmap xorg-smproxy xorg-util-macros xorg-x11perf xorg-xauth xorg-xcmsdb xorg-xcursorgen xorg-xdpyinfo xorg-xdriinfo xorg-xev xorg-xgamma xorg-xhost xorg-xinit xorg-xinput xorg-xkbcomp xorg-xkbevd xorg-xkbutils xorg-xkill xorg-xlsatoms xorg-xlsclients xorg-xmodmap xorg-xpr xorg-xprop xorg-xrandr xorg-xrdb xorg-xrefresh xorg-xset xorg-xsetroot xorg-xvinfo xorg-xwd xorg-xwininfo xorg-xwud xorgproto xsel
```
- link Xorg configs
```bash
ln -vsf x11/ ~/.config/
sudo ln -vsf xserverrc /etc/X11/xinit # keyboard repeat delay setting
```

## Window Manager
using DWM and only DWM since the start
- my own rice of DWM (https://dwm.suckless.org)
``` bash
sudo pacman -S libxinerama imlib2
git clone https://github.com/johnsonnn64/jondwm
cd jondwm/dwm
sudo make clean install
mkdir -p ~/.local/share/fonts/ # for font compatibility
cp jondwm/dwm/fonts/* ~/.local/share/fonts/
```

## Menu Launcher
using Dmenu from Suckless (suckless.org)
- install my rice of dmenu
```bash
git clone https://github.com/Johnsonnn64/dmenu
cd dmenu
sudo make clean install
```

## Terminal
used to use st (https://github.com/johnsonnn64/st) but changed to alacritty due to font problems
- install alacritty
``` bash
sudo pacman -s alacritty
ln -vsf alacritty.toml ~/.config/
```

## Audio
using pipewire for audio
- install pipewire
```bash
sudo pacman -S pipewire-pulse pipewire-jack wireplumber qjackctl easyeffects
```

## Compositor
using a fork of picom 
- install picom-ftlabs-git
```bash
yay -S picom-ftlabs-git
ln -vsf picom.conf ~/.config/picom/
```

## Input Method Framework
using fcitx5 
- install fcitx5

```bash
sudo pacman -S fcitx5-im fcitx5-hangul fcitx5-mozc
ln -vsf fcitx5/ ~/.config/
git clone https://github.com/catppuccin/fcitx5.git
mkdir -p ~/.local/share/fcitx5/themes/ # catppuccin theme for fctix5
cd fcitx5/
cp -r src/* ~/.local/share/fcitx5/themes/
```

## Keyboard Remap
using keyd to remap caps-esc and more
- install keyd
```bash
sudo pacman -S keyd
sudo ln -vsf default.conf /etc/keyd/
```

