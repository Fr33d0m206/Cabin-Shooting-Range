# Cabin Shooting Range

## 0.2.5

- Fixed editor world clicks being consumed by the native HUD.
- Hide the native HUD while editing and restore its original visibility when closing.
- Resolve placement clicks during physics updates using the input event's viewport coordinates.
- Fixed selecting an existing target with an empty collision-exclusion list.
- Fixed scenario loads rejecting their own positions while old colliders were still being removed.
- Replaced the scenario dropdown with three visible scenario buttons and clear Save/Load instructions.
- Added mouse-input checks covering target selection, placement, dragging, scenario saves, scenario loads and empty slots.

## 0.2.4

- Added **F4** as the main range-editor shortcut to avoid Alt+R overlay conflicts. Alt+R remains available as an alternative.
- Updated the startup hint, editor button and installation instructions to show F4.
- Added visible messages when the editor is unavailable indoors, during another action or while its controls are loading.
- Shortcut key repeat and release do not toggle the editor. Modified F4 combinations remain available to other controls.
- Added native input-dispatch checks for opening and closing with both shortcuts and restoring the camera, mouse and player controls.

## 0.2.3

- Connected chains to mounting pins on the gong, torso, square and diamond plates.
- Changed link spacing so the alternating chain links overlap and interlock.
- Moved the hanging suspension pivot to the crossbar. Chains and plates now swing together, keeping both ends connected.
- Added mounting washers and bolt heads within each plate's profile.
- Preserved existing layouts, scores and furniture items.

## 0.2.2

- Fixed range pieces missing from the Furniture Spawner after normal startup.
- Refreshes the spawner once after the twelve furniture pieces register.
- Keeps adding furniture separate from discovering it. Pieces enter the owned catalog when added or purchased.

## 0.2.1

- Falling rack paddles and flipping tree paddles begin returning 3 seconds after their latest hit.
- Recovery runs independently for each paddle and preserves points and impact marks.
- Recessed rack stems and tree attachment arms to prevent overlap with the visible paddle faces.
- Aligned reaction animation with physics updates.

## Included features

- Nine targets and three modular room pieces.
- Worn textures, chipped paint, rust and visible bullet impacts.
- Native furniture catalog, placement and Generalist trader integration.
- Outdoor editor with dragging, rotation, undo and three scenario slots per map.
- Free practice, four timed round lengths and saved high scores.
- Human-target headshots, geometric-target center scoring and no-shoot penalties.
- Occasional arcade feedback with throttled popups.
