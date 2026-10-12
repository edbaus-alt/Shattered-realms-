extends Node3D
## Minimal third-person 3D prototype. Procedural geometry; no external assets.
var player: CharacterBody3D
var camera_pivot: Node3D
var move_input := Vector2.ZERO
var touch_start := Vector2.ZERO
var touch_id := -1
const SPEED := 5.0
const GRAVITY := 18.0

func _ready() -> void:
    _make_world()
    _make_player()
    _make_camera()
    _make_ui()

func _make_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid := true) -> Node3D:
    var root := Node3D.new()
    parent.add_child(root)
    root.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mesh.material_override = mat
    root.add_child(mesh)
    if solid:
        var body := StaticBody3D.new()
        root.add_child(body)
        var shape := CollisionShape3D.new()
        var box_shape := BoxShape3D.new()
        box_shape.size = size
        shape.shape = box_shape
        body.add_child(shape)
    return root

func _make_world() -> void:
    var env := WorldEnvironment.new()
    var world_env := Environment.new()
    world_env.background_mode = Environment.BG_COLOR
    world_env.background_color = Color(0.07, 0.09, 0.13)
    world_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world_env.ambient_light_color = Color(0.6, 0.65, 0.8)
    world_env.ambient_light_energy = 0.65
    env.environment = world_env
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, 25, 0)
    sun.light_energy = 1.2
    add_child(sun)
    _make_box(self, Vector3(0, -0.25, 0), Vector3(12, 0.5, 12), Color(0.27, 0.29, 0.32))
    _make_box(self, Vector3(-6, 1.5, 0), Vector3(0.5, 3, 12), Color(0.38, 0.39, 0.43))
    _make_box(self, Vector3(6, 1.5, 0), Vector3(0.5, 3, 12), Color(0.38, 0.39, 0.43))
    _make_box(self, Vector3(0, 1.5, -6), Vector3(12, 3, 0.5), Color(0.38, 0.39, 0.43))
    _make_box(self, Vector3(-4, 1.5, 6), Vector3(4, 3, 0.5), Color(0.38, 0.39, 0.43))
    _make_box(self, Vector3(4, 1.5, 6), Vector3(4, 3, 0.5), Color(0.38, 0.39, 0.43))
    _make_box(self, Vector3(0, -0.25, 12), Vector3(4, 0.5, 12), Color(0.28, 0.29, 0.32))
    _make_box(self, Vector3(-2, 1.5, 12), Vector3(0.5, 3, 12), Color(0.38, 0.39, 0.43))
    _make_box(self, Vector3(2, 1.5, 12), Vector3(0.5, 3, 12), Color(0.38, 0.39, 0.43))

func _make_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 1, 0)
    add_child(player)
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.35
    capsule.height = 1.8
    var collision := CollisionShape3D.new()
    collision.shape = capsule
    player.add_child(collision)
    var visual := MeshInstance3D.new()
    var shape := CapsuleMesh.new()
    shape.radius = 0.35
    shape.height = 1.8
    visual.mesh = shape
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.2, 0.7, 0.85)
    visual.material_override = mat
    player.add_child(visual)

func _make_camera() -> void:
    camera_pivot = Node3D.new()
    add_child(camera_pivot)
    var camera := Camera3D.new()
    camera.position = Vector3(0, 3.5, 6.5)
    camera.rotation_degrees.x = -18
    camera.current = true
    camera_pivot.add_child(camera)

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var label := Label.new()
    label.text = "SHATTERED REALMS  |  Move: WASD / arrows or drag left side"
    label.position = Vector2(24, 20)
    layer.add_child(label)
    var hint := Label.new()
    hint.text = "Prototype 0.1 - static modular test chamber"
    hint.position = Vector2(24, 50)
    layer.add_child(hint)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x * 0.5 and touch_id == -1:
            touch_id = event.index
            touch_start = event.position
        elif not event.pressed and event.index == touch_id:
            touch_id = -1
            move_input = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == touch_id:
        move_input = ((event.position - touch_start) / 85.0).limit_length(1.0)

func _physics_process(delta: float) -> void:
    var keys := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var direction := keys if keys.length() > 0.01 else move_input
    var desired := Vector3(direction.x, 0, direction.y).normalized() * SPEED
    player.velocity.x = desired.x
    player.velocity.z = desired.z
    if not player.is_on_floor():
        player.velocity.y -= GRAVITY * delta
    else:
        player.velocity.y = 0
    player.move_and_slide()
    camera_pivot.global_position = player.global_position
