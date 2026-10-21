# AGENTS.md — dotfiles repo guidance for AI agents

## Repo overview

Personal dotfiles for **illogical-impulse** (Quickshell desktop shell config) on Arch-based systems.

| Path | Purpose |
|------|---------|
| `dots/` | Configs that map into `$HOME` (see *Sync workflow*). Contains `.config/`, `.local/`. |
| `dots-extra/` | Optional/auxiliary configs (emacs, fcitx5, fedora, fontsets, swaylock, via-nix). |
| `sdata/` | Setup engine: `lib/` (shared bash functions), `subcmd-*` (install, update, uninstall, etc.), `dist-*` (per-distro packages). |
| `scripts/` | Standalone user scripts (`air`, `update`, `tts`, etc.). |
| `setup` | Entry point: `./setup install`, `./setup exp-update`, `./setup uninstall`, … |
| `.github/` | CI workflows, issue templates, contributing guide. |

**Deployment:** `setup install` copies files from `dots/.config/` → `$XDG_CONFIG_HOME` and `dots/.local/share/` → `$XDG_DATA_HOME` using `rsync -a --delete` (see `sdata/subcmd-install/3.files.sh`). It is a **copy**, not a symlink. The submodule `dots/.config/quickshell/ii/modules/common/widgets/shapes` (rounded-polygon-qmljs) is declared in `.gitmodules` but **not checked out** by default; `auto_update_git_submodule` in the install script handles it.

## Sync workflow

Live configs are edited in `~/.config/...`, then copied back into `dots/.config/...` for version control.

**Rules for agents:**
- Copy only the intended changed files from `~/.config/...` → `dots/.config/...`.
- Never copy `.opencode/`, caches, logs, `.git`, or any VCS/IDE directories.
- Do not delete repo-only files (e.g. `sdata/`, `scripts/`, `.github/`) unless the user explicitly asks.
- Do not run `git pull` / `git stash` / rebase without being asked.
- Commit and push to `main` **only when the user asks**.

## Quickshell config

Root: `dots/.config/quickshell/ii` (live: `~/.config/quickshell/ii`).  
Active panel family: **island** (`panelFamilies/IslandFamily.qml`).

### Validation
```bash
# Qt 6 qmllint (the /usr/bin/qmllint is Qt 5 and fails on `pragma ComponentBehavior`)
/usr/lib/qt6/bin/qmllint <file>

# Smoke test — must log "Configuration Loaded"
timeout 12 quickshell -c ii
# Ignore the pre-existing Qt 6.11.2-vs-6.12.0 version-mismatch warning.
```

### Key files (verified to exist)

| File | Role |
|------|------|
| `services/Notifications.qml` | Notification server, system sound (`Audio.playSystemSound("message-new-instant")`), history persistence, toggle `sounds.notification`. |
| `services/Wallpapers.qml` | Image + video wallpaper browsing; `videoExtensions: ["mp4","webm","mkv","avi","mov"]`, `isVideo(path)` helper; delegates to `switchwall.sh`/`mpvpaper`. |
| `panelFamilies/IslandFamily.qml` | Island panel wiring, inline notification, per-app animation tint. |
| `modules/island/NotificationView.qml` | Inline notification toast. |
| `modules/island/CommandCenterView.qml` | Control-center composition root. |
| `modules/island/controlcenter/` | Modular control center: `ToggleGrid.qml`, `ToggleButton.qml`, `SliderSection.qml`, `CustomSlider.qml`, `MediaCard.qml`, `NotificationHistory.qml`, `NotificationHistoryItem.qml`, `AppColorHelper.js`. |
| `modules/island/WallpaperView.qml` | Island wallpaper browser (image + video previews via `VideoThumbnail.qml`). |
| `modules/common/widgets/VideoThumbnail.qml` | ffmpeg first-frame video preview cache. |
| `modules/ii/wallpaperSelector/WallpaperDirectoryItem.qml` | ii selector video preview (uses `Wallpapers.isVideo`). |
| `modules/common/Config.qml` / `modules/settings/GeneralConfig.qml` | Config schema and settings UI. |

## Quickshell conventions / gotchas (verified)

- **Asset paths from `modules/island/controlcenter/`** need `../../../assets/icons/fluent/...` (three levels up). Prefer `WIcons.pathForName(...)` where available.
- **Video wallpapers** (mp4/webm/mkv/avi/mov) are applied via `scripts/colors/switchwall.sh` → `mpvpaper`; previews come from an ffmpeg first-frame cache (`VideoThumbnail.qml`, `thumbgen-venv.sh`).
- **Notification sound** uses `Audio.playSystemSound("message-new-instant")`, gated by `sounds.notification` config.
- **History cards** get per-app colors from `AppColorHelper.js`.
- **View / deep-link behavior:**
  - Live notifications: invoke the raw notification action directly (`Notification.actions`: prefer `default`, then `open`/`view`/`reply`, then first) so apps like Discord jump to the channel.
  - Fallback chain: focus window by `appId`/`desktopEntry` → cleaned `appName` → launch desktop entry (`DesktopEntries.byId` → `heuristicLookup` → `AppSearch.fuzzyQuery`).
  - **Persisted history entries cannot deep-link:** `Notifications.qml` discards actions on load and `invoke()` is not serializable — only focus/launch works for history.
- Some apps (e.g. vesktop) send empty `appIcon`/`image`; the icon widget handles the fallback.

## Code style

- Self-explanatory code; **comments explain WHY, not WHAT**.
- No placeholder, TODO, or narration-style comments.
- Keep changes consistent with surrounding QML patterns (property bindings, `readonly` where appropriate, `pragma ComponentBehavior: Bound` on singletons).

## Git

- Remote: `git@github.com:xDeFc0nx/dotfiles.git`
- Branch: `main`
- Commit style: short imperative subject, e.g. `island: fix notification deep-link`, `docs: update AGENTS.md`.
- Push to `main` only when asked.
- Keep the `modules/common/widgets/shapes` submodule declaration intact (currently not checked out).

## Agent workflow

Defer to the global rules in `~/.config/opencode/AGENTS.md` (subagent-first, skill routing). Do not duplicate them here.