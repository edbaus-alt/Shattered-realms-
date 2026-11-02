extends SceneTree
## Run: godot --headless --path . --script res://tests/test_dungeon_preview.gd

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var scene := load("res://scenes/dungeon_preview.tscn")
    var preview := scene.instantiate()
    root.add_child(preview)
    var failures := 0
    var distinct_layouts: Dictionary = {}
    for seed in range(1, 51):
        preview._generate(seed)
        var rooms: Array = preview.cells
        var edges: Array = preview.links
        if rooms.size() < 7 or rooms.size() > 10:
            push_error("Seed %d: wrong room count" % seed)
            failures += 1
        var unique: Dictionary = {}
        for room in rooms:
            unique[room] = true
        if unique.size() != rooms.size():
            push_error("Seed %d: overlapping grid positions" % seed)
            failures += 1
        var adjacency: Dictionary = {}
        for room in rooms:
            adjacency[room] = []
        var edge_keys: Dictionary = {}
        for edge in edges:
            var a: Vector2i = edge["a"]
            var b: Vector2i = edge["b"]
            var key := str(a) + ":" + str(b)
            var reverse_key := str(b) + ":" + str(a)
            if edge_keys.has(key) or edge_keys.has(reverse_key):
                push_error("Seed %d: duplicate connection" % seed)
                failures += 1
            edge_keys[key] = true
            if not adjacency.has(a) or not adjacency.has(b) or absi(a.x - b.x) + absi(a.y - b.y) != 1:
                push_error("Seed %d: invalid connection" % seed)
                failures += 1
                continue
            adjacency[a].append(b)
            adjacency[b].append(a)
        var seen: Dictionary = {}
        var pending: Array = [rooms[0]]
        seen[rooms[0]] = true
        while not pending.is_empty():
            var current: Vector2i = pending.pop_front()
            for neighbor in adjacency[current]:
                if not seen.has(neighbor):
                    seen[neighbor] = true
                    pending.append(neighbor)
        if seen.size() != rooms.size():
            push_error("Seed %d: disconnected layout" % seed)
            failures += 1
        var branched := false
        for neighbors in adjacency.values():
            if neighbors.size() >= 3:
                branched = true
        if not branched:
            push_error("Seed %d: missing three-way branch" % seed)
            failures += 1
        # Check that the preview actually built visible 3D rooms, not just a graph.
        var labels := 0
        var meshes := 0
        for child in preview.geometry.get_children():
            if child is Label3D:
                labels += 1
            elif child is MeshInstance3D:
                meshes += 1
        if labels != rooms.size() or meshes < rooms.size():
            push_error("Seed %d: missing room labels or 3D geometry" % seed)
            failures += 1
        var signature := str(preview.cells) + "|" + str(preview.links)
        distinct_layouts[signature] = true
        preview._generate(seed)
        if signature != str(preview.cells) + "|" + str(preview.links):
            push_error("Seed %d: seed replay changed topology" % seed)
            failures += 1
    if distinct_layouts.size() < 20:
        push_error("Insufficient variety: only %d distinct layouts across 50 seeds" % distinct_layouts.size())
        failures += 1
    if failures == 0:
        print("PASS: 50 seeds, %d distinct layouts, 7-10 rooms, connected branches, visible geometry, deterministic replay" % distinct_layouts.size())
        quit(0)
    else:
        push_error("FAILED: %d checks" % failures)
        quit(1)
