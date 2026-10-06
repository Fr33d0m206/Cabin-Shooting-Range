# Release Verification

**Version:** 0.2.4

**Verified:** 2026-10-06

**Game:** Road to Vostok Build 2, version 0.2.0.0

**Loader:** Metro Mod Loader 3.4.1

## Results

| Check | Result |
| --- | --- |
| Geometry, editor, placement and storage | 100 passed |
| Hanging attachments and paddle recovery | 80 passed |
| Scoring, popup throttling and records | 37 passed |
| Full native game integration | 80 passed |
| Archive-only loading | All twelve designs loaded |
| Forward+ / D3D12 review renders | Fifteen captures, no script or engine errors |
| VMZ contents | 82 entries verified byte-for-byte against source |

## Covered behavior

- F4 and Alt+R open and close the editor through the game's input system.
- F4 has no conflicts in the tested native InputMap. Repeat and release events do not toggle the editor.
- Closing restores the original camera, mouse mode and player controls.
- All twelve pieces appear in the Furniture Spawner during normal startup.
- Furniture catalog addition, duplicate prevention and Generalist purchasing work through native systems.
- Native placement, return to catalog, shelter saves and map travel retain the expected items and layouts.
- Real weapon-impact code detects target zones and awards points once per player impact.
- Geometric targets cannot earn headshots. No-shoot hits apply the penalty.
- Arcade popups are throttled and completed timed rounds announce saved new records.
- Hanging chains remain attached to the beam and plate throughout the swing.
- Falling and flipping paddles return after three seconds, independently and without clearing earned points or impact marks.
- Placement rejects occupied, unsupported and uneven footprints. Failed storage writes preserve the prior layout.

## Test conditions

Standalone checks used Godot 4.6.2. Native checks used the installed game's Godot 4.6.3 executable and the seven-mod compatibility stack documented in [DEVELOPMENT.md](DEVELOPMENT.md). User-data paths were redirected into isolated fixtures. Metro's first fixture launch generated its hook pack; integration checks ran after restarting that fixture.

Native shots used controlled physics rays through the game's impact method. Record tests exercised completion and storage with controlled scores. These are automated checks, not claims of a human-played perfect round.

Audio dispatch was tested with sound output routed to Dummy. Audible balance, sustained manual gameplay and frame-time performance still need hands-on review. Game-side input dispatch cannot establish whether an external overlay intercepts a physical shortcut.

## Artifact integrity

The release ZIP includes **SHA256SUMS.txt** for its files. The verified VMZ SHA-256 is:

```text
fa32f88e91fb27f648004c07fda4a8a13cb7eee4a5c09f2d3d7760a8d7e6ce7f
```

Use the commands in [DEVELOPMENT.md](DEVELOPMENT.md) to reproduce the checks. Local logs, fixtures, saves and cached game resources are excluded from this repository.
