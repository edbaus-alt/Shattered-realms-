# Shattered Realms 0.8 — Modular 3D Dungeon Preview (Godot 4)

This is an **isolated editor preview**, not a replacement for the playable scene or an Android APK. It introduces a seeded layout graph and roofless 3D visualization. It does not yet implement a walkable generated dungeon, cellular caves, traps, equipment, forging gameplay, or the separate AXIOM Level Builder.

## Run
1. Open the repository in Godot 4 with the Compatibility renderer.
2. Open `res://scenes/dungeon_preview.tscn` and select **Run Current Scene (F6)**.
3. Press **New Dungeon** repeatedly: 7–10 modules, branches, and connecting bridges should change position.
4. Record the displayed seed, enter it in the seed box, and press **Load Seed**. The same topology and room types should return.
5. Drag to orbit; use the mouse wheel or a two-finger pinch to zoom; press **Reset View** to restore the viewing angle.
6. Run the existing `res://scenes/main.tscn` to verify the original movement and follow camera are unchanged.

## Automated layout checks

From a machine with Godot 4 on PATH, at the repository root:

`godot --headless --path . --script res://tests/test_dungeon_preview.gd`

The test exercises 50 seeds and checks 7–10 unique module positions, adjacent/valid connections, full connectivity, at least one three-way branch, and same-seed topology replay. It does not verify visual correctness, touch interactions, player collision, Android export, or performance. Those require an editor/tablet test.

## Geometry contract
- Grid step: 12 m; square module footprint: 10 m; connection bridge: 2 m; opening width: 3 m.
- Entrance, hub, forge, archive, and other room labels are **visual placeholders**; only layout, connection ports, and preview are implemented.
- Adjacent but unlinked modules have sealed walls; no interaction with sealed endpoints yet.
- The existing player scene is intentionally untouched to avoid camera/control regressions.

## Next integration step (not included)
Refactor the topology into a shared generator resource, add collision/navigation to generated geometry, and connect it to the player scene. Later, import compatible layouts from the separate AXIOM Level Builder and add cellular caves as specialized modules.
