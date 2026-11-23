extends SceneTree
## Traversal-route regression for the Godot modular dungeon graph.
## This is a topology test, not a physics or tablet movement test.
## Run: godot --headless --path . --script res://tests/test_room_routes.gd

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/dungeon_preview.tscn")
    if packed == null:
        push_error("Dungeon preview scene missing")
        quit(1)
        return
    var preview = packed.instantiate()
    root.add_child(preview)
    var failures := 0
    var checked_routes := 0
    for seed in range(1, 101):
        preview._generate(seed)
        var rooms: Array = preview.cells
        var links: Array = preview.links
        if rooms.is_empty():
            push_error("Seed %d: empty dungeon" % seed)
            failures += 1
            continue
        var adjacency: Dictionary = {}
        for room in rooms:
            adjacency[room] = []
        for link in links:
            var a: Vector2i = link["a"]
            var b: Vector2i = link["b"]
            if not adjacency.has(a) or not adjacency.has(b):
                push_error("Seed %d: edge references missing room" % seed)
                failures += 1
                continue
            adjacency[a].append(b)
            adjacency[b].append(a)
        for destination in rooms:
            var start: Vector2i = rooms[0]
            var queue: Array[Vector2i] = [start]
            var previous: Dictionary = {start: start}
            while not queue.is_empty():
                var current: Vector2i = queue.pop_front()
                if current == destination:
                    break
                for neighbor in adjacency[current]:
                    if not previous.has(neighbor):
                        previous[neighbor] = current
                        queue.append(neighbor)
            if not previous.has(destination):
                push_error("Seed %d: no route from entrance to %s" % [seed, destination])
                failures += 1
                continue
            var cursor: Vector2i = destination
            var steps := 0
            while cursor != start:
                var parent: Vector2i = previous[cursor]
                if not adjacency[parent].has(cursor) or not preview._is_linked(parent, cursor):
                    push_error("Seed %d: invalid route hop" % seed)
                    failures += 1
                    break
                cursor = parent
                steps += 1
                if steps > rooms.size() - 1:
                    push_error("Seed %d: route cycle" % seed)
                    failures += 1
                    break
            checked_routes += 1
        await process_frame
    if failures == 0:
        print("PASS: 100 seeds, %d entrance-to-room routes, all hops follow generated doorways" % checked_routes)
        quit(0)
    else:
        push_error("FAIL: %d room-route errors" % failures)
        quit(1)
