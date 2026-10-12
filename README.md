# Shattered Realms

Tablet-first 3D dungeon crawler, developed in Godot 4.

## Roadmap
1. Third-person exploration on Android tablet
2. Modular dungeon assembly (rooms, corridors, turns, ramps, pits)
3. Forging, alchemy, equipment crafting, and skill trees
4. First-person camera option
5. VR / AR investigation via OpenXR and platform-specific prototypes

## Prototype 0.1
A **static test chamber** with a third-person follow camera, collision geometry, placeholder player, and basic movement. It is **not** procedural dungeon generation yet.

## Test
1. Open this repository as a Godot 4 project (Compatibility renderer).
2. Run the main scene.
3. Use arrow keys or WASD in the editor; on a touch device drag on the left half of the screen.
4. Verify that the player moves, walls block movement, and the camera follows.
5. Android packaging and performance remain to be validated on the target tablet.

The Godot editor and Android export pipeline may require additional setup; the repository alone is not an installable APK.
