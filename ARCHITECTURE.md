# Architecture Overview

Living architecture document for the `xDeFc0nx/dotfiles` repo — a personal dotfiles set for the **illogical-impulse** desktop (Quickshell shell, Hyprland compositor, Arch-based). Verified against HEAD `15bfe5ae` on 2026-10-21. It describes what is actually on disk; where reality and comments disagree, reality wins and the discrepancy is listed in §9.

## 1. Project Structure

```
dotfiles/
├── AGENTS.md            Agent working rules (global rules live in ~/.config/opencode/AGENTS.md)
├── ARCHITECTURE.md      This document
├── LICENSE
├── diagnose             Bash bug-report collector, writes gitignored diagnose.result
├── setup                Entry point (bash, 130 lines) — getopt subcommand dispatcher
├── dots/                Configs that map into $HOME (the payload)
├── dots-extra/          Optional/auxiliary configs (emacs, fcitx5, fedora, fontsets, swaylock, via-nix)
├── sdata/               Setup engine: lib/, subcmd-*, dist-* (per-distro package logic)
├── scripts/             Standalone user scripts/binaries, not referenced by anything else in the repo
├── .config/             Legacy AGS config (198 files) — tracked, never deployed
├── cache/               Repo-local scratch
├── licenses/            Third-party license texts
└── .github/             Workflows, issue/PR templates, CONTRIBUTING.md
```

`dots/` breakdown — `dots/.config/` holds **22 top-level entries (14 dirs + 8 files)**:

| Entry | Files | Role |
|---|---|---|
| `dots/.config/quickshell/` | 984 | The shell (source of truth for `qs -c ii`) |
| `dots/.config/hypr/` | 31 | Hyprland Lua config, keybinds, rules, lock/idle |
| `dots/.config/matugen/` | 13 | Color generation templates (incl. leftover `templates/ags/`) |
| `dots/.config/Kvantum/` | 7 | Qt theme |
| `dots/.config/fish/` | 7 | Shell; `conf.d` excluded on install |
| `dots/.config/kitty/`, `zshrc.d/` | 3 each | Terminals |
| `dots/.config/wlogout/`, `fuzzel/` | 2 each | Power menu, launcher |
| `dots/.config/{fontconfig,kde-material-you-colors,xdg-desktop-portal,mpv}/` | 1 each | Misc |
| `.conf`/`.rc`/`.toml` files | 8 | `chrome-flags.conf`, `thorium-flags.conf`, `code-flags.conf`, `kdeglobals`, `darklyrc`, `dolphinrc`, `konsolerc`, `starship.toml` |

`dots/.local/` is 3 files: `share/icons/illogical-impulse.svg`, `share/konsole/Profile 1.profile`, `share/kxmlgui5/konsole/…`.

Quickshell root `dots/.config/quickshell/ii/`:

| Path | Files | Role |
|---|---|---|
| `modules/` | 584 | `common/` 199, `ii/` 202, `waffle/` 144, `island/` 31, `settings/` 8 |
| `assets/` | 270 | Icons; `icons/fluent/` = 232 SVGs |
| `services/` | 58 | 46 singletons + helpers (`ai/`, `network/`, `gCloud/`, `hyprlandAntiFlashbangShader/`) |
| `scripts/` | 33 | Shell helpers incl. `colors/` wallpaper-derived theming |
| `translations/` | 15 locales + `tools/` | i18n |
| `panelFamilies/` | 4 | `IllogicalImpulseFamily.qml`, `WaffleFamily.qml`, `IslandFamily.qml`, `PanelLoader.qml` |
| `defaults/` | 8 | Defaults incl. `ai/prompts/*.md` |
| root files | — | `shell.qml`, `settings.qml`, `GlobalStates.qml`, `killDialog.qml`, `ReloadPopup.qml`, `welcome.qml`, `.qmlformat.ini` |

Also present and dead: a stray `:w` file (82 lines, accidental vim write).

## 2. High-Level System Diagram

```
 repo (git)                                   host ($HOME)
 ──────────                                   ────────────
 dots/.config/*  ──┐
 dots/.local/*   ──┤  ./setup install
 sdata/subcmd-install/3.files.sh ──► rsync -a [--delete] ──► ~/.config/*, ~/.local/share/*
                                                                  │
 Hyprland session starts (uwsm) ───────────────────────────────────┘
   hyprland.lua → hyprland/{lib,services,env}.lua → execs/rules/colors/keybinds
   execs.lua:6  hl.exec_cmd("qs -c ii")
        │
        ▼
 qs -c ii  (shell.qml, ShellRoot)
        │  families: ["ii","waffle","island"]; LazyLoader gated on Config.ready
        ▼
 panel family  ── ii (Bar/VerticalBar/Background/Dock/…) │ waffle (Win11-style) │ island (pill)
        │
        ▼
 services/ singletons (46): Notifications, Audio, Wallpapers, MprisController,
 Brightness, Network, BluetoothStatus, PolkitService, TrayService, Hyprland* …
        │
        ▼
 system: PipeWire/PulseAudio · UPower · nmcli · BlueZ · MPRIS · Polkit
         Hyprland IPC (hyprctl / qs ipc) · D-Bus org.freedesktop.Notifications
         brightnessctl/ddcutil · ydotool

 wallpaper → color branch:
 Wallpapers.apply(path) → scripts/colors/switchwall.sh
   ├─ image: matugen + generate_colors_material.py → generated/material_colors.scss,
   │         colors.json, color.txt, hypr/colors.lua, hyprlock/colors.conf, fuzzel theme, gtk.css
   └─ video: mpvpaper per monitor + ffmpeg frame-1 thumbnail, no matugen
```

## 3. Core Components

### 3.1 Deployment / Setup Engine

- **Responsibility:** install deps, run setup groups, copy `dots/` into `$HOME`, and reverse it.
- **Files:** `setup`; `sdata/lib/{environment-variables,functions,package-installers,dist-determine}.sh`; `sdata/subcmd-install/{0.greeting,1.deps-router,2.setups,3.files,3.files-exp}.sh`; `sdata/subcmd-uninstall/0.run.sh`; `sdata/dist-*/`.
- **Tech:** bash, `rsync`, `getopt`, `yay`/`makepkg`, `uv`, `goose`-free plain script order.
- **Wiring:** `setup` does `cd "$(dirname "$0")"`, sources the libs, refuses to run under sudo/root (`prevent_sudo_or_root`), `set -e`.

### 3.2 Quickshell Shell Root & Panel Families

- **Responsibility:** own the Qt/QML process, load config, select exactly one panel family.
- **Files:** `dots/.config/quickshell/ii/shell.qml` (81 lines), `panelFamilies/PanelLoader.qml`, `modules/common/Config.qml`, `GlobalStates.qml`.
- **Tech:** Quickshell (Qt 6 QML), `ShellRoot`, `LazyLoader`, `IpcHandler`, `GlobalShortcut`.
- **Wiring:** pragmas `UseQApplication`, `QS_NO_RELOAD_POPUP=1`, `QT_QUICK_CONTROLS_STYLE=Basic`, `QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000`. `Component.onCompleted` runs `MaterialThemeLoader.reapplyTheme()`, `Hyprsunset.load()`, `FirstRunExperience.load()`, `ConflictKiller.load()`, `Cliphist.refresh()`, `Wallpapers.load()`, `Updates.load()`. Families are gated `active: Config.ready && Config.options.panelFamily === identifier && extraCondition`. Switching: `IpcHandler target: "panelFamily"`, shortcut `panelFamilyCycle` (CTRL+SUPER+P, `hyprland/keybinds.lua:58`). Default `panelFamily: "ii"`; this machine's live value is `island`.

### 3.3 The island Panel Family

- **Responsibility:** dynamic-island pill at top-center; replaces bar, notification popup, wallpaper selector, session screen, polkit dialog, overview.
- **Files:** `panelFamilies/IslandFamily.qml` (999 lines, all inline: `Variants` → `LazyLoader` (`active: GlobalStates.barOpen && !GlobalStates.screenLocked`) → `PanelWindow`); sub-views in `modules/island/` (`RestView`, `HoverView`, `NotificationView`, `CommandCenterView`, `LauncherView`, `WallpaperView`, `PowerMenuView`, `PolkitView`, `VolumeView`, `BrightnessView`); `modules/island/IslandConstants.qml`.
- **Geometry:** `restWidth 130` (120+10), `restHeight 36` (34+2); `hoverWidth 490`, `hoverHeight 86`; surface `implicitWidth 600`, `implicitHeight 800`, `anchors.top`, `WlrLayershell.namespace: "quickshell:bar"`, `color: "transparent"`, `mask: Region { item: maskBoundingBox }`, `exclusiveZone: restHeight + 8`. Pill spring `15.0/1.0/0.1`, `clip: true`, grows instantly / shrinks after 70 ms.
- **State:** `isExpanded`, `controlCenterOpen`, `showingNotification`, `isFlashing`, `showingVolume`, `showingBrightness`, `hideElements`; plus `launcherOpen` (`GlobalStates.overviewOpen`), `wallpaperSelectorOpen`, `sessionOpen`, `polkitOpen` (`PolkitService.active`).
- **Notification flow:** `Connections { target: Notifications; onNotify → postNotification }` → `flashAnim` → toast + 5000 ms close timer + 200 ms reset; per-app tint from `AppColorHelper.colorForApp`.

### 3.4 Services Layer

- **Responsibility:** every system interaction lives here; UI binds to singletons, never to shell commands directly.
- **Files:** `dots/.config/quickshell/ii/services/` — 46 singletons. Load-bearing: `Notifications.qml` (315), `Wallpapers.qml` (192), `Audio.qml`, `GlobalStates.qml` (root, 52 lines, ~20 booleans referenced 368× across the tree).
- **Tech:** Quickshell `NotificationServer`, `Pipewire`/`PwNode`, `UPower`, `Network`, `Mpris`, `UPower`, `DBusMenu`/`TrayItem`, `Polkit`, `Hyprland`/`HyprlandData`, `SecretService`.
- **Notable:** `ConflictKiller` (kills competing notification daemons, spawns `killDialog.qml`), `MaterialThemeLoader`, `PolkitService`, `MprisController`, `Brightness`, `Cliphist`, `Hyprsunset`, `KeyringStorage`, `Translation`, `Updates`, `Battery`, `Network`, `BluetoothStatus`, `EasyEffects`, `Idle`, `Todo`, `TimerService`, `Weather`, `Ai` + `ai/` API strategies, `AppSearch`, `LauncherApps/Search`, `TaskbarApps`, `Emojis`, `Booru`, `SongRec`, `PrayerTimes`, `ResourceUsage`, `Privacy`, `SystemInfo`, `DateTime`, `GlobalFocusGrab`, `HyprlandConfig/Data/Keybinds/Xkb`, `LatexRenderer`, `SessionWarnings`, `Ydotool`, `FirstRunExperience`, `GoogleCloud`, `HyprlandAntiFlashbangShader`.

### 3.5 Control Center Module Tree

- **Files:** `modules/island/CommandCenterView.qml` (153; `420×600`, header + back button + `StackView` with `wifiView`/`audioView`/`mainView`); `modules/island/controlcenter/`.
- **Composition:** `mainView` = ScrollView → `ToggleGrid` (2×3: Wi-Fi, Audio, Bluetooth, Performance, Peace, Night Light) → `SliderSection` (`CustomSlider`) → `MediaCard` (MPRIS) → `NotificationHistory` (`NotificationHistoryItem`, 279 lines, per-app colors + deep-link chain: prefer `default`, then `open/view/show/reply`, then first).
- **Colors:** `controlcenter/AppColorHelper.js` (108 lines) is plain JS, deliberately not a singleton; ~55 brand colors + md5 hash fallback.

### 3.6 Hyprland Configuration

- **Files:** `dots/.config/hypr/hyprland.lua` requires `hyprland.{lib,services,env}`, then `execs/general/rules/colors/keybinds`, optional `custom.*`, `workspaces.lua`, `monitors.lua`.
- **Wiring:** `hyprland/execs.lua:6` → `hl.exec_cmd("qs -c $qsConfig")`, `qsConfig = "ii"` (`variables.lua:5`). Restart CTRL+SUPER+R → `killall ydotool qs quickshell; qs -c $qsConfig &`. `env.lua:16` exports `ILLOGICAL_IMPULSE_VIRTUAL_ENV`.
- **Process model:** no systemd user unit; Quickshell logs to Hyprland exec output, `~/.cache/quickshell/crashes/<id>/`, and `/run/user/1000/quickshell/by-id/<id>/log.log`.

### 3.7 Wallpaper & Color Pipeline

- **Files:** `dots/.config/quickshell/ii/scripts/colors/` — `switchwall.sh` (474), `generate_colors_material.py`, `applycolor.sh`, `scheme_for_image.py`, `thumbgen-venv.sh`, `generate-thumbnails-magick.sh`.
- **CLI:** `--mode dark|light`, `--type <scheme>|auto`, `--color <hex|clear>`, `--image <path>`, `--noswitch`. Schemes: content, expressive, fidelity, fruit-salad, monochrome, neutral, rainbow, tonal-spot, auto.
- **Image path:** matugen → `~/.local/state/quickshell/user/generated/{material_colors.scss,colors.json,color.txt}` + `wallpaper/{path,category}.txt` + `~/.config/hypr/hyprland/colors.lua` + `~/.config/hypr/hyprlock/colors.conf` + `~/.config/fuzzel/fuzzel_theme.ini` + `~/.config/gtk-{3,4}.0/gtk.css` + terminal themes + VS Code fork accent.
- **Video path:** `pkill -f -9 mpvpaper`, then `mpvpaper -o "$VIDEO_OPTS" <monitor> <video> &` per monitor, ffmpeg frame-1 thumbnail into `~/.config/hypr/custom/scripts/mpvpaper_thumbnails/`, regenerates `__restore_video_wallpaper.sh`. Gated by `appearance.wallpaperTheming.enable*`.

### 3.8 Scripts & Dev Tooling

- **Files:** repo-root `scripts/` (no subdirs, referenced by nothing else): `air` (Go ELF, cosmtrek/air), `update` (C ELF: updatedb → pacupdate → `yay -Syu --noconfirm` → notify-send), `packagesn`, `pacupdate`, `yayupdate`, `updatedb` (fish), `randomWallpaper` (bash, feh/X11-era), `tts` (bash, ElevenLabs, literal placeholder key), `welcome` (fish, broken).
- **`./diagnose`:** bash, 112 lines; dumps distro, XDG vars, venv, Hyprland version, `pacman` quickshell/qt6-base into gitignored `diagnose.result`; uploads to `0x0.st` only after confirmation.

## 4. Data Stores

All state is on disk; there is no database or network store.

| What | Path | Written by |
|---|---|---|
| Shell config (all options) | `~/.config/illogical-impulse/config.json` | `modules/common/Config.qml` `JsonAdapter` (50 ms debounce) |
| Cross-session UI state | `~/.local/state/states.json` | shell state helpers |
| Notification history | `~/.cache/quickshell/notifications/notifications.json` | `services/Notifications.qml` (`persistenceSupported: true`) |
| Todo list | `~/.local/state/user/todo.json` | `services/Todo.qml` |
| Generated theming | `~/.local/state/user/generated/**` | `scripts/colors/switchwall.sh` + matugen |
| Python venv | `~/.local/state/quickshell/.venv` (py 3.12) | `sdata/lib/package-installers.sh` (`uv`) |
| Secrets | GNOME Keyring | `services/KeyringStorage.qml` via SecretService |
| Crash dumps | `~/.cache/quickshell/crashes/<id>/` | Quickshell runtime |
| Installed-path ledger | `~/.config/illogical-impulse/installed_listfile` (`$INSTALLED_LISTFILE`) | every `sdata` write |
| Firstrun marker | `~/.config/illogical-impulse/installed_true` (`$FIRSTRUN_FILE`) | `gen_firstrun()`; removed by `./setup resetfirstrun` |

## 5. External Integrations / APIs

| Integration | Purpose | Method |
|---|---|---|
| matugen | Material-You palette from wallpaper | CLI subprocess from `switchwall.sh` |
| Hyprland IPC | dispatch/keybind/monitor control | `hyprctl`, `qs -c ii ipc call …`, `Hyprland*` services |
| D-Bus `org.freedesktop.Notifications` | serve and emit notifications | `NotificationServer` (all capabilities true, `keepOnReload: false`) |
| MPRIS | media metadata/transport | `MprisController`, `MediaCard` |
| PipeWire / PulseAudio | sink/source, volume, system sounds | `Audio.qml`; sounds via `ffplay /usr/share/sounds/<theme>/stereo/<name>.oga` |
| UPower | battery/charge state | `Battery.qml` |
| nmcli | Wi-Fi list/connect | `Network.qml`, `WaffleControl` |
| BlueZ | Bluetooth devices | `BluetoothStatus.qml` |
| brightnessctl / ddcutil | panel brightness | `Brightness.qml` |
| Polkit agent | privilege prompts | `PolkitService.qml`, `PolkitView` |
| Gemini / OpenAI | AI features | keyring-held keys via `KeyringStorage`, `services/ai/` strategies |
| ElevenLabs | TTS | `scripts/tts` (placeholder key, non-functional) |
| `yay` / `pacman` | package install/upgrade | `sdata/dist-arch`, `scripts/update` |
| `uv` venv | Python for matugen/thumbnail helpers | `$ILLOGICAL_IMPULSE_VIRTUAL_ENV` |

## 6. Deployment & Infrastructure

`./setup install` runs four ordered steps; each has a `--skip-all*` flag:

1. `sdata/subcmd-install/0.greeting.sh` — banner, firstrun messaging.
2. `1.deps-router.sh` — freshness gate `outdate_detect sdata/dist-arch sdata/dist-<target>` (modes `WIP|FORCE_OUTDATED|FORCE_UPDATED|AUTO`), then the distro engine.
3. `2.setups.sh` — groups video/i2c/input, `i2c-dev`, ydotool + bluetooth services per init (systemd, OpenRC, dinit), python venv, gsettings.
4. `3.files.sh` — the actual copy.

**Routing:** `sdata/lib/dist-determine.sh` reads `${REPO_ROOT}/os-release` (gitignored override) else `/etc/os-release`, sets `OS_DISTRO_ID`, `OS_DISTRO_ID_LIKE`, `OS_GROUP_ID` ∈ `arch|gentoo|fedora|suse|debian|fallback`, `INSTALL_VIA_NIX=true` for suse/debian/fallback, plus `MACHINE_ARCH`.

**Copy semantics** (`rsync` helpers in `3.files.sh`):

| Helper | Flag set | Use |
|---|---|---|
| `rsync_dir` | `rsync -a --out-format='%i %n'` | merge, keep target-only files |
| `rsync_dir__ignore_existing` | `rsync -a --ignore-existing` | `hypr/custom` — never clobbered |
| `rsync_dir__sync` | **`rsync -a --delete`** | exact mirror of a directory |
| `rsync_dir__sync_exclude` | as above + excludes | `fish` (excludes `conf.d`) |
| `cp_file` | `mkdir -p` + `cp -f` | single files (`hyprlock.conf`, `hyprland.lua`, `hypridle.conf`) |

Copies, **not symlinks** — symlinks are only a TODO in `3.files-exp.sh`; `--exp-files` is an alternative engine (`3.files-exp.yaml`, modes `sync|soft|hard|hard-backup|soft-backup|skip|skip-if-exists`). Targets: `dots/.config/<entry>` → `$XDG_CONFIG_HOME/<entry>`, `dots/.local/share/konsole` → `$XDG_DATA_HOME/konsole`, `dots/.local/share/icons/illogical-impulse.svg`. Every write is appended to `$INSTALLED_LISTFILE`. Firstrun collisions get `.old`/`.new` backups and a `$BACKUP_DIR` (default `~/ii-original-dots-backup`) copy.

**Per-distro engines:**

| Distro | Implementation |
|---|---|
| arch | Reference: 145-line `install-deps.sh`, `metapkgs=()` of 14 meta-packages / 14 PKGBUILDs, installs `yay` (comment: "paru does not support cleanbuild"), `makepkg -Afsi`, `outdate-detect-mode=AUTO`, 77-line `previous_dependencies.conf` |
| fedora | `feddeps.toml` groups + `copr.repos`, local RPM repo via `createrepo_c`, DNF transaction IDs in `user_data.yaml` for `dnf history undo` |
| gentoo | rsyncs `overlay/` to `/var/db/repos/ii-dots`, `metapkgs.sh`, keywords/useflags |
| nix | home-manager flake, `WIP` outdate mode, no uninstall |

**Pinning & hooks:** `sdata/dist-arch/illogical-impulse-quickshell-git/PKGBUILD` pins `_commit='4f508be500dea6e5732cc3d50382a0048b17e7b1'` (`pkgver=0.1.0.r1`, `pkgrel=8`, cmake+ninja, `-DINSTALL_QML_PREFIX=lib/qt6/qml`). The alpm hook `quickshell-check.hook` runs `quickshell --private-check-compat` when `qt6-base`/`qt6-wayland` upgrade (warns only). Python deps pinned by `sdata/uv/requirements.txt` (`uv pip compile requirements.in -o requirements.txt`).

**Submodule:** `.gitmodules` → `dots/.config/quickshell/ii/modules/common/widgets/shapes` ← `https://github.com/end-4/rounded-polygon-qmljs.git`, checked out by `auto_update_git_submodule` (`functions.sh:339-344`, called from `3.files.sh:215-216`). Currently uninitialized (leading `-`, commit `e31ec4cb…`).

**Uninstall** (`sdata/subcmd-uninstall/0.run.sh`) is explicitly labelled incomplete/untested: deletes only `$HOME` paths from `$INSTALLED_LISTFILE`, prompts for non-HOME, reverses 3→2→1, and delegates to per-distro `uninstall-deps.sh` (fedora `dnf history undo`, gentoo unmerge, nix "not yet available").

| Subcommand | Effect |
|---|---|
| `install` | full 4-step install |
| `install-deps` / `install-setups` / `install-files` | single step (`0.run.sh`) |
| `uninstall` | reverse deletion from ledger |
| `exp-update` / `exp-merge` | experimental update / upstream merge |
| `resetfirstrun` | delete `installed_true` |
| `checkdeps` | dependency report |
| `virtmon` | virtual monitor helper |
| `help` | usage |

## 7. Security Considerations

- **Secrets never touch the tree.** Keys live in GNOME Keyring, read with `secret-tool lookup 'application' 'illogical-impulse'` / SecretService via `KeyringStorage`. No `.env` files, no key material in any config.
- **Known exception:** `scripts/tts` contains a literal placeholder ElevenLabs key — dead code, do not fill it in.
- **Destructive operations to treat as loaded guns:**
  - `rsync -a --delete` (`rsync_dir__sync`) deletes target-only files — wrong source wipes a live config tree.
  - `pkill -f -9 mpvpaper` in `switchwall.sh` kills *every* mpvpaper process.
  - SIGUSR1 to kitty, and `/dev/pts` escape-sequence writes (terminal state manipulation).
- **Direction rule:** `./setup install` copies **repo → host**. Never use it to sync host → repo (the ledger, `--delete`, and backups all assume that direction). Manual sync = copy only intended files from `~/.config/...` into `dots/.config/...`, never `.opencode/`, caches, logs or `.git`.
- **`./diagnose`** writes local `diagnose.result` first; uploading to `0x0.st` happens only after explicit confirmation.
- **Privileges:** `setup` refuses to run as root/sudo; elevated work is funnelled through `sudo_init_keepalive` and per-distro package managers.

## 8. Development & Testing Environment

No CI validates QML, shell or lint — every check below is manual.

```bash
# edit the live tree, then copy changed files into the repo
~/.config/quickshell/ii/...  →  dots/.config/quickshell/ii/...

# validate a single file with Qt6 qmllint (6.12.0)
/usr/lib/qt6/bin/qmllint <file>

# smoke test: must log "Configuration Loaded"
timeout 12 quickshell -c ii

# restart the shell (also CTRL+SUPER+R)
pkill qs; qs -c ii

# config UI
qs -p ~/.config/quickshell/ii/settings.qml
```

- `/usr/bin/qmllint` is Qt5 (`qmllint 1.0`) and **fails** on `pragma ComponentBehavior` — always use the Qt6 path.
- Benign qmllint warning: "Type X not declared as singleton in qmldir but using pragma Singleton" (no `qmldir` files exist anywhere).
- Formatting: only `dots/.config/quickshell/ii/.qmlformat.ini` (IndentWidth 4, unix newlines, MaxColumnWidth 110) and `.config/nvim/.stylua.toml` (vendored nvim).
- Absent: shellcheck, `.editorconfig`, `.shellcheckrc`, prettier, `.clang-format`, pre-commit, markdownlint, eslint, `Makefile`, `justfile`, `Taskfile`.
- Debug loop: edit live config → validate → `timeout 12 quickshell -c ii` → copy back → `./diagnose` for reports.
- PR rules (`CONTRIBUTING.md`, 64 lines): one feature per PR, no changed defaults, config-gate fancy features off by default, use `Loader` for optional UI, translations under `translations/tools`.

## 9. Known Gotchas, Debts & Roadmap

**QML landmines**

1. Show/hide views with `visible: opacity > 0` + `opacity: <state> ? 1 : 0` + 50 ms `Behavior`. Plain `visible: true` leaves stale layers on screen.
2. QML `Popup`s (`ToolTip`, `Menu`, `ComboBox` dropdowns) are separate surfaces: they ignore ancestor `clip`, ancestor `opacity: 0`, and even ancestor `visible: false`. The island sets `clip: true` (`IslandFamily.qml:669`) + `mask: Region` (`:164`) and collapses its views by animating `opacity` to 0 (`:775`, `:820`), so a plain popup declared inside a view outlives the collapsed pill — the opacity animation never reaches it and the `clip`/`mask` never apply. House style is `StyledToolTip` — a `ToolTip` with `background: null` and visibility derived from `parent.hovered` (`modules/common/widgets/StyledToolTip.qml:12,24`), declared as a child of the hoverable control (42+ call sites). Never hardcode `ToolTip.visible: true` — the two sites that did (`modules/island/controlcenter/NotificationHistoryItem.qml:251,273`) are now `StyledToolTip`. That hover idiom has a sibling landmine: a full-bleed `MouseArea` declared as the **last** child of a card fills the parent and, painted last, swallows hover and press from sibling buttons — their `hovered` never becomes true (so `StyledToolTip` never appears) and their `releaseAction` does not fire as intended. Same file: the card-level `MouseArea` (`:133-141`) now sits **first**, before the content `ColumnLayout` (`:143`), so `viewButton`/`dismissButton` stay on top while a click on the card body still reaches it. Rule: declare interactive overlays first, or give them negative `z`.
3. Never call 2-arg `Qt.rgba(color, alpha)` — it does not exist; use `ColorUtils.applyAlpha(color, a)` (`modules/common/functions/ColorUtils.qml:122-127`). This exact mistake caused a real regression: the island toast never appeared, because the binding exception aborts the rest of the function. It is now fixed everywhere — `IslandFamily.qml:175,346,348,350` and `NotificationView.qml:21` all use `ColorUtils.applyAlpha`. Note these files also need `import qs.modules.common.functions` (`IslandFamily.qml:15`, `NotificationView.qml:7`): `qs.modules.common` does not re-export the `functions/` subdir (`modules/common/` has no `qmldir`), so `ColorUtils` is otherwise undefined.
4. `list<Notif>` is not reactive — reassign: `root.list = root.list.slice(0)`.
5. Lazy singletons need a poke: `Component.onCompleted: { var initAudio = AudioReminders; }`.
6. Notifications must be `tracked` or `actions`/`invoke()` are unavailable. Restored history has `actions: []`, so **history can never deep-link** — only focus/launch.
7. Notification IDs collide across reloads unless offset (`idOffset`).
8. Resize asymmetry is deliberate: grow instantly, shrink after 70 ms, or the shrinking pill clips outgoing content.
9. Config writes are debounced 50 ms; set `Config.readWriteDelay = 0` (settings/welcome/killDialog do) and gate option readers on `Config.ready`.
10. `pragma ComponentBehavior` kills dynamic scope: pass properties explicitly between island views. Child views still reference the `islandWindow` id from the inline component scope — moving a view out of that scope silently breaks it (why orphaned `statusPill.qml` is broken).
11. Icon paths: from `modules/island/controlcenter/` use `../../../assets/icons/fluent/…`; from `modules/island/` use `../../assets/…`; prefer `WIcons.pathForName(name)` (`modules/waffle/looks/WIcons.qml:10-12`), which resolves an absolute path via `Quickshell.shellPath`.

**Dead code & drift**

12. Zero-byte files: `modules/island/{ControlCenterView,PrayerView,ThemePickerView}.qml`, `modules/island/components/{IslandAuthPrompt,IslandIcon,IslandSlider,IslandTile}.qml`.
13. Parallel unused island implementation: `modules/island/{Island,IslandWindow,IslandStateManager}.qml` — nothing instantiates it. Plus orphaned `statusPill.qml` and a stray `:w` file in the Quickshell root.
14. `modules/ii/notificationPopup/NotificationPopup.qml:17` reads `Config.options.notifications.monitor.{enable,name}` — the real key (`Config.qml:400-406`). Was `forceMonitor`, which did not exist; fixed on both the consumer and the settings UI (`modules/settings/InterfaceConfig.qml:272-289`). Still unloaded by the island family.
15. `IslandFamily.qml:61` must be `ExclusionMode.Normal`, paired with the explicit `exclusiveZone` (`:153`). `Normal` is the only mode that honours `exclusiveZone`; with it the shell reserves 44 px (`hyprctl monitors -j` → `reserved: [0, 44, 0, 0]`). Two wrong values were tried here: `Exclusive`, which does not exist (valid set is `Normal`/`Ignore`/`Auto`, `Quickshell/_Window/ExclusionMode`) and silently fails, and `Auto`, which computes the zone as `implicitHeight + margins` and ignores `exclusiveZone` — this window is `implicitHeight: 800`, so `Auto` would reserve 800 px from the top of the screen. The dead twin `modules/island/IslandWindow.qml:40` carried the same invalid `Exclusive` and now also uses `Normal`.
16. `Config.qml:81` comment `// "ii", "waffle"` is stale. There is **no `island` config group** and no settings-UI control for `panelFamily`; switch with `qs -c ii ipc call panelFamily cycle` or CTRL+SUPER+P.
17. `dots-extra/{emacs,fcitx5,fedora,swaylock}` are never deployed; only `dots-extra/fontsets/*` (`--fontset`) and `dots-extra/via-nix/hypridle.conf` (`--via-nix`) are wired.
18. `dots/.config/hypr/hyprlock/` and `dots/.local/share/kxmlgui5/` are tracked but no install step copies them.
19. Repo-root `.config/ags/` is dead legacy AGS (198 files) — never deployed; `dots/.config/matugen/templates/ags/` is the same leftover. Do not edit expecting effect.
20. Never hand-edit generated files: `dots/.config/hypr/custom/scripts/__restore_video_wallpaper.sh` (regenerated by `switchwall.sh`) and the tracked-but-matugen-generated `hypr/hyprland/colors.lua`, `hypr/hyprlock/colors.conf`, `fuzzel/fuzzel_theme.ini`.
21. `sdata/subcmd-install/3.files.sh:256` still mentions `~/.config/hypr/hyprland/env.conf`, which is now `env.lua` — stale message only.
22. `dots/.config/quickshell/ii` (live copy) drifted from the repo in `modules/ii/bar/Workspaces.qml` and `services/SystemInfo.qml` (live was older); a full `./setup install` has not run since ~2026-10-14. Expect drift and diff before assuming.
23. The closed-island popup-escape bug class: because the pill clips and masks its contents, anything that renders outside the pill bounds (popups, tooltips without `StyledToolTip`, toast content overflowing) is invisible or clipped after the island closes — verify by opening and closing the island, not by looking at the open state.

**Process**

24. One feature per PR; new features must be config-gated and default off; don't change defaults unasked. No CI will catch a broken QML file.

**Notification rendering: mirror `ii`, never hand-roll it.** The shared stack is `modules/ii/notificationPopup/NotificationPopup.qml` → `NotificationListView` → `NotificationGroup` → `NotificationItem` (single notification gets `onlyNotification: true`, `NotificationGroup.qml:248`). Icons always go through `NotificationAppIcon` (`modules/common/widgets/NotificationAppIcon.qml`), a `MaterialShape` that owns the whole fallback chain — material symbol when no icon, `IconImage` + `Quickshell.iconPath(appIcon, "image-missing")` when an app icon name exists, `StyledImage` when the notification carries an image. Callers pass `appIcon` / `image` / `summary` / `urgency` straight through (`NotificationItem.qml:97-110`, `controlcenter/NotificationHistoryItem.qml:163-171`); Waffle's `WNotificationAppIcon` does the same with `source: icon || fallback`. Body text goes through `NotificationUtils.processNotificationBody(body, appName || summary)` with newlines mapped to `<br/>`, and styling uses `Appearance` / `ColorUtils` tokens, not literals. The island toast was the one surface that guessed icon paths itself (bare `Image` + `Quickshell.iconPath` + `ColorOverlay`), which is exactly how it ended up rendering the theme's magenta `image-missing` icon. Any new notification UI reuses these components rather than re-deriving them.

## 10. Project Identification

| Field | Value |
|---|---|
| Project | illogical-impulse dotfiles (`xDeFc0nx/dotfiles`) |
| Remote | `git@github.com:xDeFc0nx/dotfiles.git` |
| Branch | `main` |
| Upstream | `end-4/dots-hyprland` |
| Tags | none |
| Commit style | `area: summary` (`island: …`, `qs: …`, `hypr: …`, `docs: …`, `gentoo: …`, `openrc: …`); frequent `Merge branch 'end-4:main' into main` |
| Last update | 2026-10-21 |
| Active hooks | none |

## 11. Glossary

| Term | Meaning |
|---|---|
| **island** | The dynamic-island panel family: one top-center pill that morphs between rest, hover, notification, control-center, launcher, wallpaper and power states, implemented inline in `panelFamilies/IslandFamily.qml`. |
| **panel family** | A mutually exclusive top-level shell layout (`ii`, `waffle`, `island`) selected by `Config.options.panelFamily`; exactly one is active. |
| **ii** | The project name and the original panel family — full bar/vertical-bar/dock/overview layout. Also the `qs -c ii` instance name. |
| **waffle** | Windows-11-style panel family, work in progress (`WaffleBar`, `WaffleActionCenter`, `WaffleStartMenu`, `WaffleTaskView`). |
| **rest / hover state** | The island's collapsed footprint (`130×36`) versus its expanded hover footprint (`490×86`). |
| **control center** | `CommandCenterView` — the island's `StackView` panel with toggles, sliders, media card and notification history. |
| **pill** | The `Rectangle { id: island }` that is the island's visible surface (clipped, spring-animated). |
| **matugen** | Material-You color generator: takes the wallpaper and emits SCSS/JSON/theme files consumed by the whole desktop. |
| **AGS** | Aylur's Gtk Shell — the predecessor shell whose config is the dead `.config/ags/` tree. |
| **uwsm** | Universal Wayland Session Manager, used to launch the Hyprland session. |
| **II** | `ILLOGICAL_IMPULSE_VIRTUAL_ENV` / the illogical-impulse project prefix (e.g. `illogical-impulse-*` PKGBUILDs). |
| **dotfiles copy semantics** | `./setup install` **copies** (rsync) repo files into `$XDG_CONFIG_HOME`/`$XDG_DATA_HOME`; no symlinks, and it is one-way repo → host. |
