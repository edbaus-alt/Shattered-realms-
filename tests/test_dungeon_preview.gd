extends SceneTree
## Run: godot --headless --path . --script res://tests/test_dungeon_preview.gd

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var scene := load("res://scenes/dungeon_preview.tscn")
    var preview := scene.instantiate()
    root.add_child(preview)
    var failures := 0
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
        for edge in edges:
            var a: Vector2i = edge["a"]
            var b: Vector2i = edge["b"]
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
        var signature := str(preview.cells) + "|" + str(preview.links)
        preview._generate(seed)
        if signature != str(preview.cells) + "|" + str(preview.links):
            push_error("Seed %d: seed replay changed topology" % seed)
            failures += 1
    if failures == 0:
        print("PASS: 50 seeds, 7-10 rooms, no grid overlap, connected branches, deterministic replay")
        quit(0)
    else:
        push_error("FAILED: %d checks" % failures)
        quit(1)
