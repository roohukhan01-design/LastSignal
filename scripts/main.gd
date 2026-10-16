extends Node3D
# LAST SIGNAL — Android-first offline vertical slice. Generated geometry, no API keys.
const SAVE_FILE := "user://last_signal.json"
var astronaut: Node3D
var world: Node3D
var cam: Camera3D
var hud: Label
var mission: Label
var message: Label
var ship: Node3D
var mode := "orbit"
var oxygen := 100.0
var fuel := 100.0
var minerals := 0
var scans := 0
var move_input := Vector2.ZERO
var dragging := -1
var touch_start := Vector2.ZERO
var notice_time := 0.0

func material(c: Color, luminous: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	if luminous:
		m.emission_enabled = true
		m.emission = c
	return m

func box(parent: Node3D, p: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.position = p
	n.material_override = material(c)
	parent.add_child(n)
	return n

func sphere(parent: Node3D, p: Vector3, r: float, c: Color, luminous: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = 2.0 * r
	mesh.radial_segments = 16
	mesh.rings = 8
	n.mesh = mesh
	n.position = p
	n.material_override = material(c, luminous)
	parent.add_child(n)
	return n

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("050b20"))
	world = Node3D.new()
	add_child(world)
	astronaut = Node3D.new()
	add_child(astronaut)
	box(astronaut, Vector3(0, 1.05, 0), Vector3(0.7, 1.1, 0.42), Color("e0e8f2"))
	sphere(astronaut, Vector3(0, 1.87, 0), 0.34, Color("4ad9e8"), true)
	box(astronaut, Vector3(-0.22, 0.35, 0), Vector3(0.22, 0.7, 0.25), Color("cad3dd"))
	box(astronaut, Vector3(0.22, 0.35, 0), Vector3(0.22, 0.7, 0.25), Color("cad3dd"))
	cam = Camera3D.new()
	add_child(cam)
	cam.current = true
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 25, 0)
	sun.light_energy = 1.5
	add_child(sun)
	var light := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("050b20")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8497c1")
	env.ambient_light_energy = 0.65
	light.environment = env
	add_child(light)
	_make_ui()
	_load_game()
	_change_scene(mode)
	_orion("Emergency signal detected. Explore Aetheria.")

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	hud = Label.new()
	hud.position = Vector2(24, 18)
	hud.add_theme_font_size_override("font_size", 22)
	overlay.add_child(hud)
	mission = Label.new()
	mission.position = Vector2(24, 66)
	mission.add_theme_font_size_override("font_size", 19)
	overlay.add_child(mission)
	message = Label.new()
	message.position = Vector2(24, 110)
	message.add_theme_font_size_override("font_size", 19)
	overlay.add_child(message)
	var buttons := HBoxContainer.new()
	buttons.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	buttons.position = Vector2(-485, -115)
	buttons.add_theme_constant_override("separation", 12)
	overlay.add_child(buttons)
	for name in ["SCAN", "COLLECT", "LAND / ORBIT", "SAVE"]:
		var b := Button.new()
		b.text = name
		b.custom_minimum_size = Vector2(110, 64)
		b.add_theme_font_size_override("font_size", 17)
		buttons.add_child(b)
		b.pressed.connect(_action.bind(name))
	var hint := Label.new()
	hint.text = "MOVE: drag left side    •    CAMERA: follows astronaut"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = Vector2(24, -45)
	overlay.add_child(hint)

func _change_scene(next_mode: String) -> void:
	mode = next_mode
	for child in world.get_children():
		child.queue_free()
	astronaut.visible = mode == "planet"
	astronaut.position = Vector3.ZERO
	if mode == "orbit":
		_make_orbit()
	else:
		_make_planet()
	_refresh_hud()

func _make_orbit() -> void:
	sphere(world, Vector3(0, 0, -28), 10.0, Color("277f91"))
	sphere(world, Vector3(-18, 10, -44), 4.0, Color("de7b3c"))
	sphere(world, Vector3(24, -3, -55), 6.0, Color("a5b8df"))
	ship = Node3D.new()
	world.add_child(ship)
	box(ship, Vector3(0, 0, 0), Vector3(2.4, 0.8, 5.0), Color("b6c8d6"))
	box(ship, Vector3(0, 0.2, -2.0), Vector3(1.3, 0.65, 1.4), Color("4ad9e8"))
	box(ship, Vector3(-2.2, 0, 0.5), Vector3(2.7, 0.15, 2.2), Color("7b91ac"))
	box(ship, Vector3(2.2, 0, 0.5), Vector3(2.7, 0.15, 2.2), Color("7b91ac"))
	for i in range(80):
		var rng := RandomNumberGenerator.new()
		rng.seed = i * 7117 + 91
		sphere(world, Vector3(rng.randf_range(-65, 65), rng.randf_range(-35, 35), rng.randf_range(-100, -55)), 0.08, Color.WHITE, true)
	_orion("AURORA-7 in orbit. Tap LAND / ORBIT to deploy.")

func _make_planet() -> void:
	box(world, Vector3(0, -0.4, 0), Vector3(150, 0.8, 150), Color("304e48"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2187
	for i in range(60):
		var p := Vector3(rng.randf_range(-58, 58), 0, rng.randf_range(-58, 58))
		if p.length() < 5.0:
			continue
		if i % 4 == 0:
			sphere(world, p + Vector3(0, 1.2, 0), rng.randf_range(0.7, 1.6), Color("38b0a0"), true)
			box(world, p + Vector3(0, 0.6, 0), Vector3(0.3, 1.2, 0.3), Color("4e6960"))
		else:
			box(world, p + Vector3(0, 0.45, 0), Vector3(rng.randf_range(0.4, 1.3), 0.9, 0.7), Color("627d72"))
	for i in range(8):
		box(world, Vector3(-9 + i * 2.5, 1.5, -18), Vector3(1.1, 3.0, 1.1), Color("777d90"))
	_orion("Aetheria atmosphere breathable only with suit filtration.")

func _process(delta: float) -> void:
	if notice_time > 0.0:
		notice_time -= delta
		if notice_time <= 0.0:
			message.text = ""
	if mode == "planet":
		var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction := move_input if move_input.length() > 0.05 else keyboard
		astronaut.position.x += direction.x * 6.0 * delta
		astronaut.position.z += direction.y * 6.0 * delta
		astronaut.position.x = clampf(astronaut.position.x, -65, 65)
		astronaut.position.z = clampf(astronaut.position.z, -65, 65)
		if direction.length() > 0.1:
			astronaut.rotation.y = atan2(direction.x, direction.y)
		oxygen = maxf(0.0, oxygen - delta * 0.12)
		if oxygen <= 0.0:
			oxygen = 100.0
			astronaut.position = Vector3.ZERO
			_orion("Suit oxygen exhausted. Emergency respawn.")
		cam.position = cam.position.lerp(astronaut.position + Vector3(0, 5, 10), minf(delta * 5.0, 1.0))
		cam.look_at(astronaut.position + Vector3(0, 1, 0))
	else:
		cam.position = cam.position.lerp(Vector3(0, 6, 16), minf(delta * 4.0, 1.0))
		cam.look_at(Vector3(0, 0, -14))
	_refresh_hud()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and t.position.x < get_viewport().get_visible_rect().size.x * 0.45 and dragging == -1:
			dragging = t.index
			touch_start = t.position
		elif not t.pressed and t.index == dragging:
			dragging = -1
			move_input = Vector2.ZERO
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == dragging:
			move_input = ((d.position - touch_start) / 90.0).limit_length(1.0)

func _action(name: String) -> void:
	match name:
		"LAND / ORBIT":
			if mode == "orbit":
				if fuel < 5.0:
					_orion("Not enough fuel to land.")
					return
				fuel -= 5.0
				_change_scene("planet")
			else:
				fuel = maxf(0.0, fuel - 3.0)
				_change_scene("orbit")
			_save_game()
		"SCAN":
			scans += 1
			_orion("ORION: Scan %d complete. Unusual energy signatures." % scans)
		"COLLECT":
			if mode == "planet":
				minerals += 1
				oxygen = minf(100.0, oxygen + 2.0)
				_orion("Mineral sample secured. Total: %d" % minerals)
			else:
				_orion("Land on a planet to collect resources.")
		"SAVE":
			_save_game()
			_orion("Mission saved offline.")
	_refresh_hud()

func _refresh_hud() -> void:
	hud.text = "LAST SIGNAL  •  %s" % ("AETHERIA" if mode == "planet" else "AURORA-7 / ORBIT")
	mission.text = "O2: %d%%   FUEL: %d%%   MINERALS: %d   SCANS: %d" % [int(oxygen), int(fuel), minerals, scans]

func _orion(text: String) -> void:
	message.text = text
	notice_time = 6.0

func _save_game() -> void:
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"mode": mode, "oxygen": oxygen, "fuel": fuel, "minerals": minerals, "scans": scans}))

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		mode = str(parsed.get("mode", "orbit"))
		oxygen = float(parsed.get("oxygen", 100.0))
		fuel = float(parsed.get("fuel", 100.0))
		minerals = int(parsed.get("minerals", 0))
		scans = int(parsed.get("scans", 0))
