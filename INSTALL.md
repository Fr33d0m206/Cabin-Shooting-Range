# Cabin Shooting Range 0.2.5

Nine practice targets, three modular room pieces, reactive steel, scoring and saved range layouts for Road to Vostok.

## Requirements

- Road to Vostok. Verified against Build 2, game version 0.2.0.0.
- Metro Mod Loader. Verified with version 3.4.1.
- Cheat Menu is optional. Its Furniture Spawner provides quick access to all twelve pieces.

## Install or update

1. Close the game.
2. Extract **ShootingRange.vmz** from this ZIP into the game's **mods** folder, beside your other VMZ mods.
3. When updating, replace the existing **ShootingRange.vmz**. Keep only one copy of this mod in that folder.
4. Start the game and enable **Cabin Shooting Range** in Metro Mod Loader. Restart if prompted.

The usual Steam location is:

```text
Steam\steamapps\common\Road to Vostok\mods\ShootingRange.vmz
```

The ZIP is the download package. The **VMZ inside it** is the file Metro loads. Metro Mod Loader and other mods are separate downloads.

Existing targets use the corrected geometry when their map loads after restarting. Your layouts and scores can stay in place.

## Start practicing

Head outside the cabin into **Village**. On the first visit, six starter targets are placed on supported terrain around the cabin.

Press **F4 outdoors** to open the range editor. **Alt+R** also works if another application does not capture it. Choose a piece and click clear ground to place it. Click and hold an existing piece to drag it; release to commit. Invalid placements are rejected. Use the editor's rotation, undo and scenario controls to arrange your range.

To save an arrangement, choose **Scenario 1**, **2** or **3**, then click **Save**. To switch to a saved arrangement, choose its scenario button and click **Load**. An empty slot leaves your current arrangement in place.

| Feature | Details |
| --- | --- |
| Target collection | Paper bullseye, paper silhouette, steel torso, gong, square, diamond, five-plate rack, dueling tree and no-shoot silhouette |
| Room pieces | Practice wall, doorway and window |
| Saved scenarios | Three slots per outdoor map |
| Layout limit | Forty pieces per map |
| Timed rounds | 30, 60, 90 or 120 seconds |
| Paddle recovery | Falling and flipping paddles return after 3 seconds |
| Hanging targets | Connected chains and mounting pins move with the plate |
| Headshots | Human-shaped targets only |

## Add pieces through furniture

With Cheat Menu installed, open **F6 → Furniture** and look for **Range:** items. Add a piece there to put it in your native furniture catalog. This spawner route is free.

For normal purchasing, all twelve designs join the **Generalist** trader's stock pool. Their availability follows normal random stock and resupply. Purchases go into your furniture catalog.

Use the game's **Decor Mode** binding outdoors, then **Tab** to open the catalog. Choose a piece and **Place**. Normal furniture placement and rotation controls apply. Pieces must be added or purchased before they appear in the owned furniture catalog.

## Scoring and records

Bullseye rings award 100 down to 10 points. Human-shaped targets award 100 for head or center-mass shots and 50 for body shots. Other steel plates award 100 for center hits and 50 for edge hits. No-shoot targets subtract 50 points, with the total stopping at zero.

Occasional **HEADSHOT**, **BULLSEYE**, **EPIC!**, **ON FIRE!** and points popups provide feedback without appearing on every shot. **NEW HIGH SCORE!** appears when a completed timed round beats its saved record. Records are separate for each map, layout and duration. Moving pieces or changing the layout ends the current challenge.

## Saves and removal

Outdoor layouts and records use **cabin_shooting_range.cfg** in the game's user-data folder. Furniture catalog entries and shelter placements use the native save system.

Before removing the mod, return its placed furniture to the catalog and remove its custom furniture items from the catalog. Saved custom furniture refers to resources supplied by this mod. Back up your saves before uninstalling.

## Release checks

This version passed 100 geometry/editor/storage checks and 80 automated checks in the actual game, including input dispatch for both editor shortcuts, furniture, scoring, placement and travel. The unchanged attachment/reaction and scoring systems have 80 and 37 passing checks respectively. Archive-only loading and fifteen Forward+/D3D12 review captures passed.

Game checks used isolated saves and controlled shot inputs. Sustained manual play, audible sound balance and frame-time performance still need hands-on review.

See **CHANGELOG.md** for the included fixes and **MOD_DESCRIPTION.md** for the full feature description. **SHA256SUMS.txt** lists checksums for the included files.
