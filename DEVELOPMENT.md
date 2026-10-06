# Development

The repository contains the complete mod source, original texture assets, native furniture resource definitions and regression tests. Download the ready-to-install package from [Releases](https://github.com/Fr33d0m206/Cabin-Shooting-Range/releases) if you only want to play.

## Project layout

| Path | Contents |
| --- | --- |
| `project/mods/ShootingRange/` | Seventeen focused runtime scripts and original textures/icons |
| `project/Assets/ShootingRange/` | Furniture scenes, item resources and icon scenes |
| `project/tests/` | Geometry, editor, scoring, attachment, rendering and native integration checks |
| `tools/` | Asset generation, VMZ packaging, validation and release packaging |
| `release/docs/` | Installation instructions, changelog and full mod description |

Native game scripts and art are referenced by resource path. They are supplied by the installed game and are not distributed here.

## Build the mod

Python 3 is required for the package tools. Run commands from the repository root:

```powershell
python tools/build_package.py
```

This creates **release/ShootingRange-0.2.4.vmz** and checks every archive entry against the current source. Committed textures and furniture definitions are already ready to package.

To install your build into a specific game folder:

```powershell
python tools/build_package.py --install --mods-dir "C:/Games/Road to Vostok/mods"
```

A different existing range archive is backed up before replacement. Other mods are left in place. Restart the game after changing the installed archive.

## Rebuild original assets

Asset generation uses NumPy and Pillow. The versions used for this release are pinned in **requirements.txt**.

```powershell
python -m pip install -r requirements.txt
python tools/build_art.py
python tools/build_furniture.py
python tools/build_package.py
```

The art generator uses a fixed random seed. Its font lookup uses Windows system fonts, so rebuilding artwork on another operating system may produce different text rendering.

## Standalone checks

Standalone checks were verified with Godot 4.6.2. Set the path to your console executable:

```powershell
$rangeGodot = "C:/Tools/Godot/Godot_v4.6.2-stable_win64_console.exe"
python tools/run_checks.py --godot $rangeGodot
python tools/run_checks.py --godot $rangeGodot --scores
python tools/run_checks.py --godot $rangeGodot --reactive
python tools/run_package.py --godot $rangeGodot
python tools/run_checks.py --godot $rangeGodot --render --renderer forward_plus
```

Reports and screenshots are written to the ignored **validation/** directory. Each check redirects its user-data paths into a fixture. It does not open the player's normal saves.

## Native integration checks

Native tests require an installed copy of Road to Vostok with Metro Mod Loader. The verified compatibility stack uses these additional installed archives: 00ModConfigurationMenu.vmz, CheatMenu.vmz, ChickenCompanion.vmz, InventoryCompatibilityGlow.vmz, RTVQualityMap.vmz, ScavengedDrone.vmz and StockpileContainer.vmz. These are test-stack requirements, not bundled downloads. Cheat Menu is optional for normal use of the range mod.

Keep the repository on the same drive as the game. The fixture hard-links the game's PCK to avoid duplicating the large pack file.

```powershell
python tools/run_native.py --game-dir "C:/Games/Road to Vostok" --mods-dir "C:/Games/Road to Vostok/mods"
```

The fixture copies the game's executable and Metro loader into **validation/native/**, mounts the locally built range archive and uses isolated saves. Nothing in that fixture belongs in a Git commit or release download.

Metro 3.4.1 generates its hook pack on the first fixture launch. If that launch reports that Database or Loader rewrites are not active, run the same command again so Metro can mount the generated pack before those scripts load. Do not treat the first failed report as a passing result.

Focused options are **--hotkey**, **--furniture** and **--reactive**. The full suite tests actual shortcut dispatch, furniture discovery and purchasing, placement, weapon impacts, scoring and map travel. The hotkey check uses game input events; it does not test delivery of physical keys through external overlay software.

## Package a release

After the checks pass:

```powershell
python tools/package_release.py --mods-dir "C:/Games/Road to Vostok/mods"
```

The tool requires passing reports, an exact source/archive match and matching archives from the native and package-only tests. It creates **release/ShootingRange-v0.2.4.zip**, containing the VMZ, public documents and checksums. Compiled archives and local validation files are ignored by Git; publish the ZIP as a release asset.
