# Fedora + Niri Setup Guide

A repeatable checklist for provisioning a fresh Fedora + Niri (Wayland compositor) desktop.

## 1. Base System

### 1.1 Fedora
- [ ] Install Fedora
- [ ] Configure GRUB
	```nano
	sudo nano /etc/default/grub
	GRUB_TIMEOUT=5
	sudo grub2-mkconfig -o /etc/grub2-efi.cfg`
	```

### 1.2 Niri (compositor)
- [ ] Install Niri
  ```bash
  sudo dnf copr enable -y yalter/niri
  sudo dnf install -y niri
  ```
- [ ] Set up `config.kdl`
- [ ] Install `jq` (for JSON parsing, e.g. `niri msg --json outputs`)
  ```bash
  sudo dnf install -y jq
  ```
- [ ] Install `grim`, `slurp`, `tesseract`, `tesseract-langpack-eng` (screenshots + OCR)
  ```bash
  sudo dnf install -y grim slurp tesseract tesseract-langpack-eng
  ```
- [ ] Install `wl-clipboard`, `cliphist` (clipboard history)
  ```bash
  sudo dnf install -y wl-clipboard
  sudo dnf copr enable -y wef/cliphist
  sudo dnf install -y cliphist
  ```

### 1.3 Noctalia (shell)
- [ ] Install Noctalia
  ```bash
  # Fedora 44+: available directly from the default repos
  sudo dnf install -y noctalia

  # Older Fedora releases: use the Terra repo instead
  sudo dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
  sudo dnf install -y noctalia
  ```
- [ ] Apply base customization (theme, panels, etc.)
- [ ] Install plugins:
  - [ ] Web search
  - [ ] YouTube search (requires `yt-dlp`)
    ```bash
    sudo dnf install -y yt-dlp
    ```

## 2. Applications

### 2.1 Terminal & System Info
- [ ] Install Ghostty
  ```bash
  sudo dnf copr enable -y scottames/ghostty
  sudo dnf install -y ghostty
  ```
  - [ ] Set up `.config.ghostty`
- [ ] Install fastfetch
  ```bash
  sudo dnf install -y fastfetch
  ```
  - [ ] Set up `.config.jsonc`

### 2.2 Browser — Vivaldi
- [ ] Install Vivaldi
  ```bash
  sudo dnf config-manager addrepo --from-repofile=https://repo.vivaldi.com/stable/vivaldi-fedora.repo
  sudo dnf install -y vivaldi-stable
  ```
- [ ] Configure PDF settings
- [ ] Import bookmarks
- [ ] Install extensions:
  - [ ] Enhancer for YouTube
  - [ ] Stylish
  - [ ] YouTube Playlist Duration Calculator

### 2.3 Development & Productivity
- [ ] Install VS Code
  ```bash
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
  sudo dnf install -y code
  ```
- [ ] Install Discord
  ```bash
  sudo dnf install -y "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
  sudo dnf install -y discord
  ```
- [ ] Install Obsidian
  ```bash
  mkdir -p ~/Applications
  curl -L "$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | grep -oP '"browser_download_url":\s*"\K[^"]*\.AppImage')" -o ~/Applications/Obsidian.AppImage
  chmod +x ~/Applications/Obsidian.AppImage
  ```
  - [ ] Set up Git integration (vault versioning)
  - [ ] Set up Syncthing (vault sync)

## 3. Personal Scripts (`~/.local/bin`)
- [ ] Restore `display-cycle` script
- [ ] Restore `ghostty-stack` script

## 4. Cleanup
- [ ] Uninstall unwanted default apps

## Suggested Order Rationale

1. **Base OS + compositor first** — Niri and Noctalia need to exist before anything else is usable.
2. **Apps next** — once the desktop environment is functional, install daily-driver software.
3. **Scripts last** — these depend on tools installed in steps 1–2 (`jq`, `niri msg`, etc.).
4. **Cleanup at the end** — easier to spot unwanted bloat once the real setup is in place.

## Single line code for installation

```
sudo dnf copr enable -y yalter/niri && sudo dnf copr enable -y scottames/ghostty && sudo dnf copr enable -y wef/cliphist && sudo dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release && sudo dnf install -y "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" && sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' && sudo dnf config-manager addrepo --from-repofile=https://repo.vivaldi.com/stable/vivaldi-fedora.repo && sudo dnf install -y niri noctalia jq grim slurp tesseract tesseract-langpack-eng wl-clipboard cliphist yt-dlp ghostty fastfetch code vivaldi-stable discord && mkdir -p ~/Applications && curl -L "$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | grep -oP '"browser_download_url":\s*"\K[^"]*\.AppImage')" -o ~/Applications/Obsidian.AppImage && chmod +x ~/Applications/Obsidian.AppImage
```
