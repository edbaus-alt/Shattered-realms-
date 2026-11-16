extends SceneTree
## Regression guard for modular dungeon doorway geometry.
## Run: godot --headless --path . --script res://tests/test_doorway_clearance.gd
## Checks geometric clearance, not physics-based character traversal.

const PLAYER_DIAMETER := 1.0
const MARGIN := 0.25

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/dungeon_preview.tscn")
    if scene == null:
        push_error("Missing preview scene")
        quit(1)
        return
    var preview = scene.instantiate()
    root.add_child(preview)
    var failures := 0
    if preview.DOOR_WIDTH < PLAYER_DIAMETER + 2.0 * MARGIN:
        push_error("Door too narrow for test character plus clearance")
        failures += 1
    if preview.GRID_STEP <= preview.ROOM_SIZE:
        push_error("Modules overlap or leave no passage length")
        failures += 1
    for seed in range(1, 101):
        preview._generate(seed)
        var links: Array = preview.links
        var rooms: Array = preview.cells
        var adjacent: Dictionary = {}
        for cell in rooms:
            adjacent[cell] = []
        for edge in links:
            var a: Vector2i = edge["a"]
            var b: Vector2i = edge["b"]
            if not adjacent.has(a) or not adjacent.has(b):
                push_error("Seed %d: link endpoint absent" % seed)
                failures += 1
                continue
            if absi(a.x - b.x) + absi(a.y - b.y) != 1:
                push_error("Seed %d: non-cardinal corridor" % seed)
                failures += 1
                continue
            adjacent[a].append(b)
            adjacent[b].append(a)
            if not preview._is_linked(a, b) or not preview._is_linked(b, a):
                push_error("Seed %d: asymmetric doorway lookup" % seed)
                failures += 1
        var visited: Dictionary = {rooms[0]: true}
        var queue: Array = [rooms[0]]
        while not queue.is_empty():
            var current: Vector2i = queue.pop_front()
            for next_cell in adjacent[current]:
                if not visited.has(next_cell):
                    visited[next_cell] = true
                    queue.append(next_cell)
        if visited.size() != rooms.size():
            push_error("Seed %d: inaccessible room" % seed)
            failures += 1
        await process_frame
    if failures == 0:
        print("PASS: 100 seeds, connected room graphs, aligned cardinal doorways, nominal character clearance")
        quit(0)
    else:
        push_error("FAIL: %d doorway-clearance checks" % failures)
        quit(1)
