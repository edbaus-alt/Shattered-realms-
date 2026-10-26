extends Node3D
## Standalone Godot 4 preview of a seeded, connected modular dungeon.
## The existing playable prototype is intentionally left unchanged.

const ROOM_SIZE := 10.0
const GRID_STEP := 12.0
const DOOR_WIDTH := 3.0
const WALL_HEIGHT := 2.4
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

var rng := RandomNumberGenerator.new()
var dungeon_seed: int = 0
var cells: Array[Vector2i] = []
var links: Array[Dictionary] = []
var geometry: Node3D
var camera: Camera3D
var seed_field: LineEdit
var status_label: Label
var orbit_yaw := 0.8
var orbit_pitch := 0.95
var orbit_distance := 65.0
var focus := Vector3.ZERO
var touches: Dictionary = {}
var pinch_distance := 0.0

func _ready() -> void:
    _setup_environment()
    geometry = Node3D.new()
    geometry.name = "GeneratedDungeon"
    add_child(geometry)
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 55.0
    add_child(camera)
    _setup_ui()
    randomize()
    _generate(randi_range(1, 2147483646))

func _setup_environment() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.055, 0.075, 0.10)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.7, 0.77, 0.9)
    environment.ambient_light_energy = 0.85
    world.environment = environment
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-60, 30, 0)
    sun.light_energy = 1.3
    add_child(sun)

func _setup_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    layer.add_child(panel)
    var stack := VBoxContainer.new()
    panel.add_child(stack)
    var title := Label.new()
    title.text = "SHATTERED REALMS | Modular Dungeon Preview 0.8"
    stack.add_child(title)
    var row := HBoxContainer.new()
    stack.add_child(row)
    var new_button := Button.new()
    new_button.text = "New Dungeon"
    new_button.pressed.connect(_new_dungeon)
    row.add_child(new_button)
    seed_field = LineEdit.new()
    seed_field.custom_minimum_size = Vector2(140, 0)
    seed_field.placeholder_text = "Seed number"
    seed_field.text_submitted.connect(_load_seed_text)
    row.add_child(seed_field)
    var load_button := Button.new()
    load_button.text = "Load Seed"
    load_button.pressed.connect(_load_seed_button)
    row.add_child(load_button)
    var reset_button := Button.new()
    reset_button.text = "Reset View"
    reset_button.pressed.connect(_reset_view)
    row.add_child(reset_button)
    status_label = Label.new()
    stack.add_child(status_label)
    var hint := Label.new()
    hint.text = "Drag to orbit | Mouse wheel or two-finger pinch to zoom | Preview only"
    stack.add_child(hint)

func _new_dungeon() -> void:
    _generate(randi_range(1, 2147483646))

func _load_seed_button() -> void:
    _load_seed_text(seed_field.text)

func _load_seed_text(value: String) -> void:
    if not value.is_valid_int():
        status_label.text = "Enter an integer seed to reproduce a dungeon."
        return
    _generate(int(value))

func _generate(new_seed: int) -> void:
    dungeon_seed = new_seed
    rng.seed = dungeon_seed
    cells.clear()
    links.clear()
    # Seeded three-way hub ensures a branching layout.
    var entrance := Vector2i.ZERO
    var hub_direction: Vector2i = DIRECTIONS[rng.randi_range(0, 3)]
    var hub := entrance + hub_direction
    cells.append(entrance)
    _add_cell(hub, entrance)
    var branches: Array[Vector2i] = []
    for direction in DIRECTIONS:
        if direction != -hub_direction:
            branches.append(direction)
    for i in range(branches.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var temp: Vector2i = branches[i]
        branches[i] = branches[j]
        branches[j] = temp
    _add_cell(hub + branches[0], hub)
    _add_cell(hub + branches[1], hub)
    var target := rng.randi_range(7, 10)
    while cells.size() < target:
        var options: Array[Dictionary] = []
        for cell in cells:
            for direction in DIRECTIONS:
                var neighbor := cell + direction
                if not cells.has(neighbor):
                    options.append({"from": cell, "to": neighbor})
        if options.is_empty():
            break
        var selected: Dictionary = options[rng.randi_range(0, options.size() - 1)]
        _add_cell(selected["to"], selected["from"])
    # Optional loops between adjacent but previously unconnected modules.
    for cell in cells:
        for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
            var neighbor := cell + direction
            if cells.has(neighbor) and not _is_linked(cell, neighbor) and rng.randf() < 0.22:
                links.append({"a": cell, "b": neighbor})
    _rebuild_geometry()
    seed_field.text = str(dungeon_seed)
    status_label.text = "Seed %d | %d rooms | %d connections | guaranteed branch" % [dungeon_seed, cells.size(), links.size()]

func _add_cell(cell: Vector2i, parent: Vector2i) -> void:
    assert(not cells.has(cell))
    cells.append(cell)
    links.append({"a": parent, "b": cell})

func _is_linked(a: Vector2i, b: Vector2i) -> bool:
    for edge in links:
        if (edge["a"] == a and edge["b"] == b) or (edge["a"] == b and edge["b"] == a):
            return true
    return false

func _cell_world(cell: Vector2i) -> Vector3:
    return Vector3(float(cell.x) * GRID_STEP, 0.0, float(cell.y) * GRID_STEP)

func _rebuild_geometry() -> void:
    for child in geometry.get_children():
        geometry.remove_child(child)
        child.queue_free()
    var min_x := cells[0].x
    var max_x := cells[0].x
    var min_y := cells[0].y
    var max_y := cells[0].y
    for i in range(cells.size()):
        var cell := cells[i]
        min_x = mini(min_x, cell.x)
        max_x = maxi(max_x, cell.x)
        min_y = mini(min_y, cell.y)
        max_y = maxi(max_y, cell.y)
        _build_room(cell, _room_kind(i), i + 1)
    for edge in links:
        _build_bridge(edge["a"], edge["b"])
    focus = Vector3(float(min_x + max_x) * GRID_STEP * 0.5, 0.0, float(min_y + max_y) * GRID_STEP * 0.5)
    var span := float(maxi(max_x - min_x, max_y - min_y) + 1) * GRID_STEP
    orbit_distance = maxf(32.0, span * 1.5)
    _update_camera()

func _room_kind(index: int) -> String:
    if index == 0:
        return "Entrance"
    if index == 1:
        return "Hub"
    if index == 2:
        return "Forge"
    if index == 3:
        return "Archive"
    var options := ["Chamber", "Hall", "Vault", "Alchemy", "Crypt"]
    return options[(index + int(rng.randi_range(0, options.size() - 1))) % options.size()]

func _build_room(cell: Vector2i, kind: String, number: int) -> void:
    var origin := _cell_world(cell)
    var color := Color(0.27, 0.34, 0.40)
    if kind == "Forge":
        color = Color(0.47, 0.29, 0.19)
    elif kind == "Entrance":
        color = Color(0.22, 0.43, 0.32)
    elif kind == "Hub":
        color = Color(0.34, 0.33, 0.53)
    _box(origin + Vector3(0, -0.15, 0), Vector3(ROOM_SIZE, 0.3, ROOM_SIZE), color)
    var wall_color := Color(0.53, 0.56, 0.60)
    for direction in DIRECTIONS:
        var linked := _is_linked(cell, cell + direction)
        if direction.x != 0:
            var x := float(direction.x) * ROOM_SIZE * 0.5
            if linked:
                var length := (ROOM_SIZE - DOOR_WIDTH) * 0.5
                for signum in [-1.0, 1.0]:
                    var z := signum * (DOOR_WIDTH * 0.5 + length * 0.5)
                    _box(origin + Vector3(x, WALL_HEIGHT * 0.5, z), Vector3(0.3, WALL_HEIGHT, length), wall_color)
            else:
                _box(origin + Vector3(x, WALL_HEIGHT * 0.5, 0), Vector3(0.3, WALL_HEIGHT, ROOM_SIZE), wall_color)
        else:
            var z := float(direction.y) * ROOM_SIZE * 0.5
            if linked:
                var length := (ROOM_SIZE - DOOR_WIDTH) * 0.5
                for signum in [-1.0, 1.0]:
                    var x := signum * (DOOR_WIDTH * 0.5 + length * 0.5)
                    _box(origin + Vector3(x, WALL_HEIGHT * 0.5, z), Vector3(length, WALL_HEIGHT, 0.3), wall_color)
            else:
                _box(origin + Vector3(0, WALL_HEIGHT * 0.5, z), Vector3(ROOM_SIZE, WALL_HEIGHT, 0.3), wall_color)
    var label := Label3D.new()
    label.text = "%02d  %s" % [number, kind]
    label.font_size = 38
    label.pixel_size = 0.009
    label.position = origin + Vector3(0, 0.10, 0)
    label.rotation_degrees.x = -90
    label.modulate = Color.WHITE
    geometry.add_child(label)
    if kind == "Forge":
        _box(origin + Vector3(2.5, 0.45, 2.5), Vector3(1.7, 0.9, 1.7), Color(0.75, 0.33, 0.12))

func _build_bridge(a: Vector2i, b: Vector2i) -> void:
    var middle := (_cell_world(a) + _cell_world(b)) * 0.5
    var gap := GRID_STEP - ROOM_SIZE + 0.15
    var rail_color := Color(0.45, 0.47, 0.50)
    if a.x != b.x:
        _box(middle + Vector3(0, -0.15, 0), Vector3(gap, 0.3, DOOR_WIDTH), Color(0.30, 0.34, 0.37))
        for signum in [-1.0, 1.0]:
            _box(middle + Vector3(0, 0.8, signum * DOOR_WIDTH * 0.5), Vector3(gap, 1.6, 0.3), rail_color)
    else:
        _box(middle + Vector3(0, -0.15, 0), Vector3(DOOR_WIDTH, 0.3, gap), Color(0.30, 0.34, 0.37))
        for signum in [-1.0, 1.0]:
            _box(middle + Vector3(signum * DOOR_WIDTH * 0.5, 0.8, 0), Vector3(0.3, 1.6, gap), rail_color)

func _box(position_3d: Vector3, dimensions: Vector3, color: Color) -> void:
    var instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    instance.material_override = material
    instance.position = position_3d
    geometry.add_child(instance)

func _reset_view() -> void:
    orbit_yaw = 0.8
    orbit_pitch = 0.95
    _update_camera()

func _update_camera() -> void:
    var offset := Vector3(sin(orbit_yaw) * cos(orbit_pitch), sin(orbit_pitch), cos(orbit_yaw) * cos(orbit_pitch)) * orbit_distance
    camera.global_position = focus + offset
    camera.look_at(focus, Vector3.UP)

func _zoom(factor: float) -> void:
    orbit_distance = clampf(orbit_distance * factor, 15.0, 220.0)
    _update_camera()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _zoom(0.9)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _zoom(1.1)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        orbit_yaw -= event.relative.x * 0.008
        orbit_pitch = clampf(orbit_pitch + event.relative.y * 0.006, 0.35, 1.45)
        _update_camera()
    elif event is InputEventScreenTouch:
        if event.pressed:
            touches[event.index] = event.position
        else:
            touches.erase(event.index)
        pinch_distance = 0.0
    elif event is InputEventScreenDrag:
        touches[event.index] = event.position
        if touches.size() == 1:
            orbit_yaw -= event.relative.x * 0.008
            orbit_pitch = clampf(orbit_pitch + event.relative.y * 0.006, 0.35, 1.45)
            _update_camera()
        elif touches.size() == 2:
            var positions := touches.values()
            var distance: float = positions[0].distance_to(positions[1])
            if pinch_distance > 1.0 and distance > 1.0:
                _zoom(pinch_distance / distance)
            pinch_distance = distance
