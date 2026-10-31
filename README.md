# Monitor-Aware Task Manager

A fork of Plasma 6.7.5's Task Manager that adds a **Monitor** entry to each task's
right-click menu:

- The entry's label shows which monitor the window is on, e.g. `Monitor: GS27FA (DP-3)`.
- Its submenu has **Move to This Monitor** (the monitor the panel is on), followed by
  every connected monitor, with the window's current monitor checked.
- Moving a window also un-minimizes and focuses it. For grouped tasks, all windows in
  the group are moved.

Two widgets are installed, matching the stock pair:

| Widget | Replaces |
| --- | --- |
| Monitor-Aware Icons-only Task Manager | Icons-Only Task Manager (Plasma default) |
| Monitor-Aware Task Manager | Icons-and-Text Task Manager |

## Build & install

```bash
sudo pacman -S --needed extra-cmake-modules
./install.sh --restart-plasma
```

`./install.sh` alone builds and installs without restarting Plasma; `./install.sh --help`
lists all options.

Then right-click the panel → **Add or Manage Widgets**, add the monitor-aware variant,
and remove the stock task manager. Your pinned launchers are not carried over; re-pin them.

## How it works

The task model has no "move to output" request, so the C++ backend
(`Backend::moveWindowsToScreen`) writes a one-shot KWin script that calls
`workspace.sendClientToScreen()` for the matching windows, loads it over D-Bus
(`org.kde.KWin /Scripting`), runs it and unloads it.

## Updating Plasma

The C++ part links against Plasma's private task manager libraries. After a Plasma
upgrade, re-run `./install.sh`; after a major upgrade, re-base `src/` on the matching
`plasma-desktop` tag (`applets/taskmanager`). The changes against upstream are:

- `src/qml/ContextMenu.qml` — the `monitorsMenuItem` submenu and `screenNameForGeometry`,
  `screenLabel`, `moveToScreen` helpers.
- `src/qml/main.qml` — `panelScreenName`.
- `src/backend.{h,cpp}` — `moveWindowsToScreen`.
- Plugin IDs renamed to `com.labatata.monitortasks` / `com.labatata.monitoricontasks`.

## Uninstall

```bash
./install.sh --remove
```
