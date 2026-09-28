extends Node3D

const MARKET_BLUE := Color("#182d4a")
const LANTERN_GOLD := Color("#f6bd60")
const MUSHROOM_PINK := Color("#e07a9a")
const GLASS_TEAL := Color("#55c2bb")
const CREAM := Color("#f5ead6")
const SAND := Color("#e9c77b")
const SEA_BLUE := Color("#4d9fc3")
const WOOD := Color("#744a36")
const LEAF_GREEN := Color("#77ae57")
const NIGHT_NAVY := Color("#101526")
const COBBLE := Color("#3b414c")
const FESTIVAL_RED := Color("#9e4255")
const FESTIVAL_BLUE := Color("#3f5f83")
const WORN_CANVAS := Color("#b58d6b")
const STONE := Color("#565b66")
const STONE_EDGE := Color("#77717a")
const WOOD_DARK := Color("#3d2928")
const VendorPuzzle = preload("res://vendor_puzzle.gd")
const SHOPPER_TARGETS := [Vector3(-7,1,-6),Vector3(-3,1,-3),Vector3(2,1,-4),Vector3(7,1,-6),Vector3(-7,1,1),Vector3(-3,1,4),Vector3(3,1,3),Vector3(8,1,1),Vector3(-7,1,6),Vector3(0,1,6),Vector3(7,1,6)]

var player: CharacterBody3D
var camera: Camera3D
var ui_message: Label
var dialogue_speaker: Label
var dialogue_panel: ColorRect
var objective_label: Label
var task_heading_label: Label
var task_labels: Array[Label] = []
var interaction_label: Label
var forager: Node3D
var glassblower: Node3D
var market_npcs: Array[Node3D] = []
var shoppers: Array[Node3D] = []
var introduced_npcs: Array[Node3D] = []
var learned_vendors: Array[Node3D] = []
var matched_vendors: Array[Node3D] = []
var completed_pairs: Array[String] = []
var note_labels: Array[Label] = []
var trade_first_rotation := 0.0
var trade_second_rotation := 0.0
var introduced := false
var barter_complete := false
var message_timer := 0.0
var conversation_timer := 0.0
var conversation_step := 0
var nearby_npc: Node3D
var visited_fountain := false
var fountain_phase_unlocked := false
var fountain_visit_armed := false
var fountain_phase_message_shown := false
var fountain_ending_shown := false
var fountain_celebration_timer := 0.0
var celebration_rotations: Dictionary = {}
var celebration_bubbles: Array[Node3D] = []
var fireworks: Node3D
var trade_state := "idle"
var trade_first_home := Vector3.ZERO
var trade_second_home := Vector3.ZERO
var sudoku_open := false
var sudoku_layer: CanvasLayer
const SUDOKU_DOOR_POSITION := Vector3(0,1.0,-10.55)

func _ready() -> void:
	_build_world()
	_remove_world_lettering(self)
	_build_ui()
	_update_tasks()

func _process(delta: float) -> void:
	if fountain_celebration_timer>0.0:
		_update_shoppers(delta)
		_update_fountain_celebration(delta)
	else:
		_update_shoppers(delta)
	_animate_creatures(delta)
	_update_roof_visibility()
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			ui_message.text = ""
			dialogue_speaker.text = ""
			dialogue_panel.visible = false
	_update_nearby_npc()
	_update_tasks()
	if introduced and trade_state == "talking":
		conversation_timer -= delta
		if conversation_timer <= 0.0:
			_advance_conversation()

func _physics_process(delta: float) -> void:
	if not player:
		return
	if sudoku_open:
		player.velocity=Vector3.ZERO
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var view_forward := Vector3(-0.72, 0.0, -0.69)
	var view_right := Vector3(-view_forward.z, 0.0, view_forward.x)
	var direction := (view_right * input_vector.x) + (view_forward * -input_vector.y)
	var target_velocity := direction * 5.0
	player.velocity.x = move_toward(player.velocity.x, target_velocity.x, 18.0 * delta)
	player.velocity.z = move_toward(player.velocity.z, target_velocity.z, 18.0 * delta)
	if direction.length() > 0.1:
		var target_angle := atan2(direction.x, direction.z)
		player.rotation.y = lerp_angle(player.rotation.y, target_angle, min(1.0, delta * 8.0))
	player.velocity.y = -0.2
	player.move_and_slide()
	player.global_position.x = clamp(player.global_position.x, -17.0, 17.0)
	player.global_position.z = clamp(player.global_position.z, -11.0, 11.0)
	var camera_target := player.global_position + Vector3(0, 0.5, 0)
	var desired_camera_position := camera_target + Vector3(10, 14, 11)
	camera.global_position = camera.global_position.lerp(desired_camera_position, min(1.0, delta * 6.0))
	camera.look_at(camera_target)
	if introduced:
		_update_trade(delta)

func _unhandled_input(event: InputEvent) -> void:
	if sudoku_open:
		return
	if event.is_action_pressed("interact"):
		if _can_interact_with_sudoku_door():
			_open_sudoku()
		elif _can_interact_with_fountain():
			_interact_with_fountain()
		elif nearby_npc:
			_interact_with_npc(nearby_npc)

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = NIGHT_NAVY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#53658e")
	env.ambient_light_energy = 0.52
	env.fog_enabled = true
	env.fog_light_color = Color("#1a2139")
	env.fog_density = 0.018
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, -25, 0)
	moon.light_color = Color("#8296c7")
	moon.light_energy = 0.43
	moon.shadow_enabled = true
	moon.shadow_blur = 1.8
	add_child(moon)

	var floor_body := _make_box("StoneFloor", Vector3(36, 0.3, 24), Vector3(0, -0.3, 0), STONE)
	floor_body.get_child(1).visible = false
	_add_stone_bricks()
	_add_town_rows()
	_make_stall("Your Stall", Vector3(-2, 0, 9), FESTIVAL_RED, "YOUR STALL", ["odd jobs", "friendship"])
	_make_stall("Button Stall", Vector3(-9.5, 0, -8), Color("#75445b"), "BUTTONS", ["shell buttons", "ribbon"])
	_make_stall("Lantern Stall", Vector3(8, 0, -7), Color("#a8793b"), "LANTERNS", ["paper moons", "fireflies"])
	_make_stall("Mushroom Stall", Vector3(-10.5, 0, -2.5), Color("#8d4961"), "FORAGER", ["mooncap spores", "forest herbs"])
	_make_stall("Glass Stall", Vector3(11.5, 0, 8.5), Color("#397d7d"), "GLASSBLOWER", ["sturdy jars", "sun charms"])
	_make_stall("Tea Stall", Vector3(-13, 0, 2.8), FESTIVAL_BLUE, "TEA WITCH", ["dream tea", "moon-sugar"])
	_make_stall("Bakery Stall", Vector3(9.5, 0, 4.8), Color("#98603e"), "BAKER", ["cinnamon buns", "star loaves"])
	_make_stall("Cloud Stall", Vector3(-10, 0, 7.2), Color("#667485"), "CLOUD HERDER", ["bottled rain", "soft thunder"])
	_make_stall("Map Stall", Vector3(11.5, 0, -0.5), Color("#5b714d"), "MAPMAKER", ["weather maps", "wayfinding feathers"])
	_make_fountain(Vector3(0, 0, -0.5))
	_add_festival_decor()
	preload("res://premium_decor.gd").new().build(self)
	preload("res://magical_motes.gd").new().build(self)
	fireworks=preload("res://festival_fireworks.gd").new().build(self)
	_add_city_lights()

	player = CharacterBody3D.new()
	player.name = "Player"
	player.collision_mask = 5
	player.set_meta("species", "Wandering Changeling")
	# Begin in the open aisle, clear of the counter and canopy collision at z = 9.
	player.position = Vector3(0, 0.9, 7.0)
	add_child(player)
	var player_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	player_shape.shape = capsule
	player.add_child(player_shape)
	var player_visual := Node3D.new()
	player_visual.name = "PlayerCreatureVisual"
	player.add_child(player_visual)
	_build_ghost(player_visual, Color("#c9d9e2"))
	camera = Camera3D.new()
	camera.position = Vector3(10, 14, 11)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 22.0
	camera.near = 0.1
	camera.current = true
	add_child(camera)

	forager = _make_npc("Mira", Vector3(-10.5, 1.0, -3.55), MUSHROOM_PINK, "Mooncap Forager", "needs a sturdy jar for her rare spores")
	glassblower = _make_npc("Pip", Vector3(11.5, 1.0, 7.45), GLASS_TEAL, "Glassblower Sprite", "needs glowing mushrooms for warm furnace fuel")
	market_npcs = [
		forager,
		glassblower,
		_make_npc("Juniper", Vector3(-13, 1.0, 1.75), Color("#8c9ed6"), "Tea Witch", "needs cinnamon buns for her tea guests"),
		_make_npc("Bramble", Vector3(9.5, 1.0, 3.75), Color("#d69b60"), "Hearth Baker", "needs calming dream tea after baking"),
		_make_npc("Cloud", Vector3(-10, 1.0, 6.15), Color("#c6d6df"), "Cloud Herder", "needs weather maps to guide the clouds"),
		_make_npc("Tula", Vector3(11.5, 1.0, -1.55), Color("#9ebd78"), "Wandering Mapmaker", "needs bottled rain to reveal hidden map ink"),
		_make_npc("Pella", Vector3(-9.5, 1.0, -9.05), Color("#d86d88"), "Button Stallkeeper", "one-liner", "A button for every mood, and a mood for every button!", false),
		_make_npc("Sol", Vector3(8, 1.0, -8.05), Color("#e5aa4e"), "Lantern Stallkeeper", "one-liner", "Take a little light with you; the road home is prettier that way.", false),
		_make_npc("Nell", Vector3(-1.5, 1.0, 0.0), Color("#d78c62"), "Cinnamon Bun Shopper", "one-liner", "I am only buying one bun today. Probably.", false),
		_make_npc("Otto", Vector3(3.2, 1.0, 2.0), Color("#6e9fc0"), "Curious Shopper", "one-liner", "Have you seen a blue teacup with legs?", false),
		_make_npc("Faye", Vector3(-4.5, 1.0, -1.0), Color("#a57fc0"), "Ribbon Shopper", "one-liner", "This ribbon matches my cloak, my basket, and my feelings.", false),
		_make_npc("Wren", Vector3(1.0, 1.0, -4.0), Color("#7cad78"), "Herb Shopper", "one-liner", "The basil smells like a tiny green sunrise.", false),
		_make_npc("Moss", Vector3(-2.0, 1.0, 3.0), Color("#8d7b63"), "Button Collector", "one-liner", "I never lose a button. I simply relocate it forever.", false),
		_make_npc("Lio", Vector3(4.5, 1.0, 5.0), Color("#db8b72"), "Picnic Shopper", "one-liner", "A market picnic needs three napkins and at least two pastries.", false),
		_make_npc("Saffron", Vector3(-5.0, 1.0, 5.5), Color("#d1a34f"), "Spice Shopper", "one-liner", "I am searching for a spice with a very dramatic sneeze.", false),
		_make_npc("Pebble", Vector3(5.5, 1.0, -1.0), Color("#7695b2"), "Toy Shopper", "one-liner", "This wooden dragon is small enough to fit in my pocket.", false)
	]
	shoppers = [market_npcs[8], market_npcs[9], market_npcs[10], market_npcs[11], market_npcs[12], market_npcs[13], market_npcs[14], market_npcs[15]]
	for npc in market_npcs:
		_keep_npc_outside_fountain(npc)
	for shopper in shoppers:
		shopper.set_meta("wander_target", _shopper_target(shopper))

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.035, 0.055, 0.11, 0.92)
	panel.position = Vector2(26, 24)
	panel.size = Vector2(460, 128)
	layer.add_child(panel)
	var task_title := Label.new()
	task_title.text = "TONIGHT'S TASK"
	task_title.position = Vector2(22, 12)
	task_title.add_theme_font_size_override("font_size", 12)
	task_title.add_theme_color_override("font_color", LANTERN_GOLD)
	panel.add_child(task_title)
	var title := Label.new()
	title.text = "MIDNIGHT MARKET EXCHANGE"
	title.position = Vector2(22, 31)
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", LANTERN_GOLD)
	panel.add_child(title)
	objective_label = Label.new()
	objective_label.text = "FIND 3 TRADING PAIRS  /  ask about wares and needs"
	objective_label.position = Vector2(22, 67)
	objective_label.add_theme_font_size_override("font_size", 14)
	objective_label.add_theme_color_override("font_color", CREAM)
	panel.add_child(objective_label)
	var controls := Label.new()
	controls.text = "WASD  move     E  ask / choose / introduce"
	controls.position = Vector2(22, 101)
	controls.add_theme_font_size_override("font_size", 13)
	controls.add_theme_color_override("font_color", Color("#9eb0c9"))
	panel.add_child(controls)
	var task_panel := ColorRect.new()
	task_panel.color = Color(0.035, 0.055, 0.11, 0.72)
	task_panel.position = Vector2(1010, 28)
	task_panel.size = Vector2(244, 156)
	layer.add_child(task_panel)
	task_heading_label = Label.new()
	task_heading_label.text = "MARKET TASKS"
	task_heading_label.position = Vector2(16, 12)
	task_heading_label.add_theme_font_size_override("font_size", 17)
	task_heading_label.add_theme_color_override("font_color", LANTERN_GOLD)
	task_panel.add_child(task_heading_label)
	for task_index in 3:
		var task_label := Label.new()
		task_label.position = Vector2(16, 44 + task_index * 32)
		task_label.size = Vector2(212, 28)
		task_label.add_theme_font_size_override("font_size", 13)
		task_label.add_theme_color_override("font_color", CREAM)
		task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		task_panel.add_child(task_label)
		task_labels.append(task_label)
	dialogue_panel = ColorRect.new()
	dialogue_panel.color = Color(0.035, 0.055, 0.11, 0.96)
	dialogue_panel.position = Vector2(285, 525)
	dialogue_panel.size = Vector2(710, 100)
	dialogue_panel.visible = false
	layer.add_child(dialogue_panel)
	dialogue_speaker = Label.new()
	dialogue_speaker.position = Vector2(24, 14)
	dialogue_speaker.size = Vector2(662, 26)
	dialogue_speaker.add_theme_font_size_override("font_size", 19)
	dialogue_speaker.add_theme_color_override("font_color", LANTERN_GOLD)
	dialogue_panel.add_child(dialogue_speaker)

	interaction_label = Label.new()
	interaction_label.position = Vector2(0, 630)
	interaction_label.size = Vector2(1280, 40)
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.add_theme_font_size_override("font_size", 20)
	interaction_label.add_theme_color_override("font_color", CREAM)
	layer.add_child(interaction_label)
	ui_message = Label.new()
	ui_message.position = Vector2(24, 42)
	ui_message.size = Vector2(662, 48)
	ui_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ui_message.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	ui_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui_message.add_theme_font_size_override("font_size", 20)
	ui_message.add_theme_color_override("font_color", CREAM)
	dialogue_panel.add_child(ui_message)

	var notes_panel := ColorRect.new()
	notes_panel.name = "VendorNotesPanel"
	notes_panel.color = Color(.035,.055,.11,.88)
	notes_panel.position = Vector2(1010,205)
	notes_panel.size = Vector2(244,310)
	layer.add_child(notes_panel)
	var notes_heading := Label.new()
	notes_heading.text = "VENDOR NOTES"
	notes_heading.position = Vector2(16,10)
	notes_heading.add_theme_font_size_override("font_size",15)
	notes_heading.add_theme_color_override("font_color",LANTERN_GOLD)
	notes_panel.add_child(notes_heading)
	for i in 6:
		var note := Label.new()
		note.position = Vector2(16,36+i*44)
		note.size = Vector2(218,42)
		note.add_theme_font_size_override("font_size",12)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		notes_panel.add_child(note)
		note_labels.append(note)

func _update_shoppers(delta: float) -> void:
	for shopper in shoppers:
		if not is_instance_valid(shopper):
			continue
		var target: Vector3 = shopper.get_meta("wander_target")
		var direction := target - shopper.global_position
		direction.y = 0.0
		if direction.length() < 0.35:
			shopper.set_meta("wander_target", _shopper_target(shopper))
		else:
			var separation := Vector3.ZERO
			for neighbor in shoppers:
				if neighbor==shopper: continue
				var away: Vector3=shopper.global_position-neighbor.global_position
				away.y=0.0
				if away.length()>.01 and away.length()<1.45:
					separation+=away.normalized()*(1.45-away.length())/1.45
			var travel := (direction.normalized()+separation*1.15).normalized()
			shopper.velocity = travel * 0.7
			shopper.move_and_slide()
			_keep_npc_outside_fountain(shopper)
			shopper.look_at(shopper.global_position + travel, Vector3.UP)

func _keep_npc_outside_fountain(npc: CharacterBody3D) -> void:
	# Physics blocks the stonework; this radial guard also protects against
	# steering/spawn edge cases and guarantees no NPC enters the whole ensemble.
	var center:=Vector3(0,npc.global_position.y,-.5)
	var offset:=npc.global_position-center
	offset.y=0.0
	const SAFE_RADIUS:=2.38
	if offset.length()<SAFE_RADIUS:
		if offset.length()<.001: offset=Vector3.RIGHT
		npc.global_position=center+offset.normalized()*SAFE_RADIUS
		if npc.velocity.dot(offset)<0.0:
			npc.velocity-=npc.velocity.project(offset.normalized())

func _animate_creatures(delta: float) -> void:
	var time := Time.get_ticks_msec() * 0.001
	for npc in market_npcs:
		if not is_instance_valid(npc) or not npc.has_meta("creature_visual"):
			continue
		var visual: Node3D = npc.get_meta("creature_visual")
		var species: String = npc.get_meta("species")
		if species in ["Moon Moth", "Mothkin", "Star Sprite"]:
			visual.position.y = .14+sin(time * 2.2 + npc.get_instance_id() * 0.01) * .07
		elif species == "Pebble Golem":
			visual.rotation.z = sin(time * 1.2 + npc.get_instance_id() * 0.03) * 0.025
		elif npc.velocity.length() > 0.2:
			visual.position.y = abs(sin(time * 7.0)) * 0.06
		else:
			visual.position.y = lerp(visual.position.y, 0.0, min(1.0, delta * 8.0))

func _update_roof_visibility() -> void:
	if not player or not camera:
		return
	var characters: Array[Node3D] = [player]
	characters.append_array(market_npcs)
	var view_direction := -camera.global_transform.basis.z
	for roof in stall_roofs:
		var obstructing := false
		var bounds := roof.get_aabb()
		var inverse := roof.global_transform.affine_inverse()
		for character in characters:
			# Test head and shoulders along parallel orthographic camera rays.
			for height in [0.35, 0.65, -0.15]:
				var target := character.global_position + Vector3(0, height, 0)
				var origin := target - view_direction * 40.0
				if bounds.intersects_segment(inverse * origin, inverse * target):
					obstructing = true
		var desired := 0.96 if obstructing else 0.0
		roof.transparency = move_toward(roof.transparency, desired, get_process_delta_time() * 3.5)
		roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if obstructing else GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func _shopper_target(shopper: Node3D) -> Vector3:
	var available: Array[Vector3]=[]
	for target in SHOPPER_TARGETS:
		var occupied:=0
		for other in shoppers:
			if other!=shopper and other.has_meta("wander_target") and Vector3(other.get_meta("wander_target")).distance_to(target)<.1:
				occupied+=1
		if occupied<2:
			available.append(target)
	if available.is_empty():
		available.append_array(SHOPPER_TARGETS)
	return available[randi()%available.size()]

func _update_nearby_npc() -> void:
	nearby_npc = null
	if sudoku_open:
		interaction_label.text=""
		return
	var nearest_distance := 4.0
	for npc in market_npcs:
		var distance := player.global_position.distance_to(npc.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearby_npc = npc
	if _can_interact_with_sudoku_door():
		interaction_label.text = "[E] Open the Town Hall puzzle door"
		return
	if _can_interact_with_fountain():
		interaction_label.text = "[E] Touch the fountain"
		return
	if not nearby_npc:
		interaction_label.text = ""
		return
	var npc_name: String = nearby_npc.get_meta("npc_name")
	if not nearby_npc.get_meta("story_character",true) or matched_vendors.has(nearby_npc):
		interaction_label.text = "[E] Visit " + npc_name
	elif introduced:
		interaction_label.text = "[E] Check in with " + npc_name
	elif not learned_vendors.has(nearby_npc):
		interaction_label.text = "[E] Ask " + npc_name + " about wares and needs"
	elif introduced_npcs.has(nearby_npc):
		interaction_label.text = "[E] Cancel choosing " + npc_name
	elif introduced_npcs.is_empty():
		interaction_label.text = "[E] Choose " + npc_name + " for an introduction"
	else:
		interaction_label.text = "[E] Introduce " + str(introduced_npcs[0].get_meta("npc_name")) + " to " + npc_name

func _can_interact_with_sudoku_door() -> bool:
	return player and player.global_position.distance_to(SUDOKU_DOOR_POSITION)<2.35

func _open_sudoku() -> void:
	if sudoku_open: return
	sudoku_open=true
	player.velocity=Vector3.ZERO
	sudoku_layer=CanvasLayer.new()
	sudoku_layer.name="MiniSudokuBrowserLayer"
	sudoku_layer.layer=20
	add_child(sudoku_layer)
	var popup:=preload("res://mini_sudoku.gd").new()
	popup.name="MiniSudokuBrowser"
	popup.dismissed.connect(_close_sudoku)
	sudoku_layer.add_child(popup)

func _close_sudoku() -> void:
	sudoku_open=false
	if is_instance_valid(sudoku_layer):
		sudoku_layer.queue_free()
	sudoku_layer=null

func _can_interact_with_fountain() -> bool:
	return fountain_phase_unlocked and not visited_fountain and player and player.global_position.distance_to(Vector3(0,.9,-.5))<3.15

func _interact_with_fountain() -> void:
	if not _can_interact_with_fountain():
		return
	visited_fountain=true
	fountain_ending_shown=true
	fountain_celebration_timer=5.5
	celebration_rotations.clear()
	for npc in market_npcs:
		if not shoppers.has(npc):
			celebration_rotations[npc]=npc.rotation.y
			npc.velocity=Vector3.ZERO
			_face_npc(npc,Vector3(0,1.2,-.5)-npc.global_position)
	preload("res://festival_fireworks.gd").new().celebrate(fireworks)
	_add_celebration_bubbles()
	_show_dialogue("Fountain","The market glows together as storybook fireworks bloom overhead!",5.5)
	_update_tasks()

func _update_fountain_celebration(delta: float) -> void:
	fountain_celebration_timer=maxf(0.0,fountain_celebration_timer-delta)
	for npc in market_npcs:
		if not shoppers.has(npc):
			npc.velocity=Vector3.ZERO
			_face_npc(npc,Vector3(0,1.2,-.5)-npc.global_position)
	if fountain_celebration_timer<=0.0:
		for npc in market_npcs:
			if celebration_rotations.has(npc):
				npc.rotation.y=celebration_rotations[npc]
		for bubble in celebration_bubbles:
			if is_instance_valid(bubble):
				bubble.queue_free()
		celebration_bubbles.clear()
		celebration_rotations.clear()

func _add_celebration_bubbles() -> void:
	var reactions := {"Pella":"Ooh!","Bramble":"Ahh!","Cloud":"So bright!","Nell":"Lovely!"}
	for npc_name in reactions:
		var npc: Node3D=get_node(NodePath(npc_name))
		var bubble := Node3D.new()
		bubble.name="FireworkReaction"
		bubble.position=Vector3(0,2.25,0)
		npc.add_child(bubble)
		for x in [-.20,0.0,.20]:
			bubble.add_child(_make_mesh("SpeechCloud",SphereMesh.new(),Vector3(.28,.18,.06),Color("#f3efe4"),Vector3(x,.02*int(x==0),0)))
		var label := Label3D.new()
		label.text=reactions[npc_name]
		label.font_size=36
		label.modulate=Color("#343a40")
		label.outline_size=5
		label.outline_modulate=Color("#f3efe4")
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.position=Vector3(0,0,.07)
		bubble.add_child(label)
		celebration_bubbles.append(bubble)

func _interact_with_npc(npc: Node3D) -> void:
	var npc_name: String = npc.get_meta("npc_name")
	if not npc.get_meta("story_character",true):
		_show_dialogue(npc_name,npc.get_meta("one_liner"),4.0)
		return
	if introduced and trade_state!="returning":
		_show_dialogue("You","Let's give our neighbors a moment to finish their trade.",2.2)
		return
	if matched_vendors.has(npc):
		_show_dialogue(npc_name,"I've found my trading friend. Thank you for bringing us together!",3.0)
		return
	if introduced and trade_state=="returning":
		if not learned_vendors.has(npc) and VendorPuzzle.VENDORS.has(npc_name):
			learned_vendors.append(npc)
		_show_dialogue(npc_name,VendorPuzzle.VENDORS[npc_name].greeting if VendorPuzzle.VENDORS.has(npc_name) else "What a lovely market night!",4.0)
		return
	if not learned_vendors.has(npc):
		learned_vendors.append(npc)
		_show_dialogue(npc_name,VendorPuzzle.VENDORS[npc_name].greeting,4.5)
		return
	if introduced_npcs.has(npc):
		introduced_npcs.clear()
		_show_dialogue(npc_name,"Of course, take your time. I'll be here when you find a good match.",3.0)
		return
	if introduced_npcs.is_empty():
		introduced_npcs.append(npc)
		_show_dialogue(npc_name,VendorPuzzle.VENDORS[npc_name].greeting,4.5)
		return
	var first: Node3D = introduced_npcs[0]
	var first_name: String = first.get_meta("npc_name")
	if not VendorPuzzle.matches(first_name,npc_name):
		_show_dialogue("You","These wares don't meet both neighbors' needs. Let's try another introduction.",3.5)
		return
	introduced_npcs.append(npc)
	introduced = true
	trade_state = "approaching"
	conversation_step = 0
	conversation_timer = 0.0
	trade_first_home = first.global_position
	trade_second_home = npc.global_position
	trade_first_rotation = first.rotation.y
	trade_second_rotation = npc.rotation.y
	first.set_meta("trade_route_stage",0)
	npc.set_meta("trade_route_stage",0)
	for vendor in introduced_npcs:
		vendor.set_meta("directed",true)
		_set_trade_collision_mode(vendor,true)
	_show_dialogue("You",first_name + ", " + npc_name + ": you can help each other. Shall we trade?",2.4)

func _update_tasks() -> void:
	if task_labels.size()<3:
		return
	if not fountain_phase_unlocked and learned_vendors.size()==6 and completed_pairs.size()==3 and not introduced:
		fountain_phase_unlocked = true
		visited_fountain = false
	if fountain_phase_unlocked:
		task_heading_label.text = "FINAL MARKET TASK"
		task_labels[0].visible = true
		task_labels[1].visible = false
		task_labels[2].visible = false
		task_labels[0].text = ("[x] " if visited_fountain else "[ ] ") + "Interact with the fountain"
		task_labels[0].add_theme_color_override("font_color",Color("#a8d9b0") if visited_fountain else CREAM)
		objective_label.text = "MARKET COMPLETE  /  the fountain welcomes you home" if visited_fountain else "FINAL TASK  /  interact with the fountain"
		if not fountain_phase_message_shown and message_timer<=0.0:
			fountain_phase_message_shown = true
			_show_dialogue("Market","Every neighbor has found their match. Meet us by the fountain!",4.0)
	else:
		task_heading_label.text = "MARKET TASKS"
		var tasks := [learned_vendors.size()==6,completed_pairs.size()==3]
		var text := ["Learn vendor clues (%d/6)" % learned_vendors.size(),"Find trading pairs (%d/3)" % completed_pairs.size()]
		for index in 2:
			task_labels[index].visible = true
			task_labels[index].text = ("[x] " if tasks[index] else "[ ] ") + text[index]
			task_labels[index].add_theme_color_override("font_color",Color("#a8d9b0") if tasks[index] else CREAM)
		task_labels[2].visible = false
	if fountain_phase_unlocked:
		pass
	elif introduced:
		objective_label.text = "MATCHES %d/3  /  %s" % [completed_pairs.size(),"neighbors returning home" if trade_state=="returning" else "neighbors making a trade"]
	elif completed_pairs.size()==3:
		objective_label.text = "ALL 3 PAIRS FOUND  /  six happy neighbors!"
	elif not introduced_npcs.is_empty():
		objective_label.text = "CHOOSE A PARTNER FOR " + str(introduced_npcs[0].get_meta("npc_name")).to_upper()
	else:
		objective_label.text = "MATCHES %d/3  /  E to ask, E again to choose" % completed_pairs.size()
	var names: Array = VendorPuzzle.VENDORS.keys()
	for i in note_labels.size():
		var npc_name: String = names[i]
		var npc: Node3D = get_node(NodePath(npc_name))
		if learned_vendors.has(npc):
			note_labels[i].text = npc_name + (" [matched]" if matched_vendors.has(npc) else "") + "\n" + VendorPuzzle.VENDORS[npc_name].note
		else:
			note_labels[i].text = npc_name + "\nAsk about their wares and needs"
		note_labels[i].modulate = Color("#a8d9b0") if matched_vendors.has(npc) else CREAM

func _advance_conversation() -> void:
	var lines := VendorPuzzle.conversation(introduced_npcs[0].get_meta("npc_name"),introduced_npcs[1].get_meta("npc_name"))
	if conversation_step>=lines.size():
		_complete_barter()
		trade_state = "returning"
		for vendor in introduced_npcs:
			vendor.set_meta("trade_route_stage",0)
		_clear_trade_dialogue()
		return
	var line: Array = lines[conversation_step]
	_show_dialogue(line[0],line[1],2.4)
	conversation_step += 1
	conversation_timer = 2.4

func _face_npc(npc: Node3D,direction: Vector3) -> void:
	if Vector2(direction.x,direction.z).length_squared()<.00001:
		return
	var visual: Node3D = npc.get_meta("creature_visual")
	# Sculpted faces use +Z; compensate for each fitted visual's local yaw.
	npc.rotation.y = atan2(direction.x,direction.z)-visual.rotation.y

func _face_trade_partners(first: Node3D,second: Node3D) -> void:
	_face_npc(first,second.global_position-first.global_position)
	_face_npc(second,first.global_position-second.global_position)

func _update_trade(delta: float) -> void:
	if introduced_npcs.size()!=2:
		return
	var first: CharacterBody3D = introduced_npcs[0]
	var second: CharacterBody3D = introduced_npcs[1]
	var meeting := _trade_meeting_point()
	# Home-side seating avoids crossed walking paths when selected in reverse order.
	var offset := Vector3(-1.10,0,0) if trade_first_home.x<=trade_second_home.x else Vector3(1.10,0,0)
	var first_target := meeting+offset
	var second_target := meeting-offset
	if trade_state=="approaching":
		_move_npc_toward(first,_trade_route_target(first,trade_first_home,first_target,false),delta)
		_move_npc_toward(second,_trade_route_target(second,trade_second_home,second_target,false),delta)
		if first.global_position.distance_to(first_target)<.08 and second.global_position.distance_to(second_target)<.08:
			first.velocity = Vector3.ZERO
			second.velocity = Vector3.ZERO
			trade_state = "talking"
			conversation_timer = .25
			_face_trade_partners(first,second)
	elif trade_state=="talking":
		_face_trade_partners(first,second)
	elif trade_state=="returning":
		_move_npc_toward(first,_trade_route_target(first,trade_first_home,first_target,true),delta)
		_move_npc_toward(second,_trade_route_target(second,trade_second_home,second_target,true),delta)
		if first.global_position.distance_to(trade_first_home)<.08 and second.global_position.distance_to(trade_second_home)<.08:
			for vendor in [first,second]:
				_set_trade_collision_mode(vendor,false)
				vendor.velocity = Vector3.ZERO
				vendor.set_meta("directed",false)
			first.rotation.y = trade_first_rotation
			second.rotation.y = trade_second_rotation
			introduced = false
			trade_state = "idle"
			introduced_npcs.clear()
			conversation_step = 0
			if completed_pairs.size()==3:
				_show_dialogue("You","Three lovely trades, six happy neighbors. What a welcoming market!",4.0)

func _trade_route_target(npc: Node3D,home: Vector3,meeting_target: Vector3,returning: bool) -> Vector3:
	var inward := -1.0 if home.x>0 else 1.0
	var rear := home+Vector3(0,0,-.55)
	var exit := rear+Vector3(inward*3.2,0,0)
	var waypoints: Array
	var north_route := trade_first_home.z>6.0 and trade_second_home.z>6.0
	if returning:
		waypoints = ([Vector3(exit.x,1.0,10.72),exit,rear,home] if north_route else [exit,rear,home])
	else:
		waypoints = ([rear,exit,Vector3(exit.x,1.0,10.72),meeting_target] if north_route else [rear,exit,meeting_target])
	var stage: int = npc.get_meta("trade_route_stage",0)
	while stage<waypoints.size()-1 and npc.global_position.distance_to(waypoints[stage])<.10:
		stage+=1
		npc.set_meta("trade_route_stage",stage)
	return waypoints[min(stage,waypoints.size()-1)]

func _trade_meeting_point() -> Vector3:
	var meeting := (trade_first_home+trade_second_home)*.5
	meeting.y = 1.0
	# The north pair meets beyond the player's stall, following its open front
	# instead of attempting to cross the solid counter.
	if trade_first_home.z>6.0 and trade_second_home.z>6.0:
		return Vector3(.75,1.0,10.72)
	var fountain_center := Vector3(0,1.0,-.5)
	var away := meeting-fountain_center
	away.y = 0.0
	if away.length()<2.75:
		if away.length()<.01:
			away = Vector3.FORWARD
		meeting = fountain_center+away.normalized()*2.75
	return meeting

func _move_npc_toward(npc: CharacterBody3D,target: Vector3,delta: float) -> void:
	var direction := target-npc.global_position
	direction.y = 0.0
	if direction.length()<.08:
		npc.velocity = Vector3.ZERO
		return
	_face_npc(npc,direction)
	npc.velocity = direction.normalized()*minf(2.2,direction.length()/maxf(delta,.001))
	npc.move_and_slide()
	_keep_npc_outside_fountain(npc)

func _set_trade_collision_mode(npc: CharacterBody3D,active: bool) -> void:
	npc.collision_layer = 2 if active else 1
	npc.collision_mask = 6 if active else 5

func _clear_trade_dialogue() -> void:
	message_timer = 0.0
	ui_message.text = ""
	dialogue_speaker.text = ""
	dialogue_panel.visible = false

func _complete_barter() -> void:
	if introduced_npcs.size()!=2:
		return
	var first: Node3D = introduced_npcs[0]
	var second: Node3D = introduced_npcs[1]
	var first_name: String = first.get_meta("npc_name")
	var second_name: String = second.get_meta("npc_name")
	var key := VendorPuzzle.pair_key(first_name,second_name)
	if not VendorPuzzle.matches(first_name,second_name) or completed_pairs.has(key) or matched_vendors.has(first) or matched_vendors.has(second):
		return
	completed_pairs.append(key)
	matched_vendors.append(first)
	matched_vendors.append(second)
	first.set_meta("matched_with",second_name)
	second.set_meta("matched_with",first_name)
	barter_complete = completed_pairs.size()==3

func _remove_world_lettering(node: Node) -> void:
	for child in node.get_children():
		if child is Label3D:
			node.remove_child(child)
			child.queue_free()
		else:
			_remove_world_lettering(child)

func _show_dialogue(speaker: String, text: String, duration: float) -> void:
	if dialogue_speaker and ui_message:
		dialogue_panel.visible = true
		dialogue_speaker.text = speaker
		ui_message.text = "\"" + text + "\""
		message_timer = duration

func _make_npc(npc_name: String, pos: Vector3, color: Color, role: String, need: String, one_liner: String = "", story_character: bool = true) -> Node3D:
	var npc := CharacterBody3D.new()
	npc.name = npc_name
	npc.position = pos
	npc.collision_mask = 5
	npc.set_meta("npc_name", npc_name)
	npc.set_meta("npc_role", role)
	npc.set_meta("npc_need", VendorPuzzle.VENDORS[npc_name].need if VendorPuzzle.VENDORS.has(npc_name) else need)
	if VendorPuzzle.VENDORS.has(npc_name):
		npc.set_meta("npc_sells", VendorPuzzle.VENDORS[npc_name].wares)
	npc.set_meta("one_liner", one_liner)
	npc.set_meta("story_character", story_character)
	var species_map := {
		"Mira": "Moss Fox", "Pip": "Moon Moth", "Juniper": "Pebble Golem", "Bramble": "Forest Dragon",
		"Cloud": "Star Sprite", "Tula": "Leaf Deer", "Pella": "Kobold", "Sol": "Salamander",
		"Nell": "Satyr", "Otto": "Frogfolk", "Faye": "Mothkin", "Wren": "Dryad",
		"Moss": "Trollkin", "Lio": "Halfling", "Saffron": "Catfolk", "Pebble": "Cyclops"
	}
	npc.set_meta("species", species_map.get(npc_name, "Wanderer"))
	add_child(npc)
	_add_creature_collision(npc, npc.get_meta("species"))
	var creature_visual := Node3D.new()
	creature_visual.name = "CreatureVisual"
	npc.add_child(creature_visual)
	_build_creature(creature_visual, npc.get_meta("species"), color)
	var tailor := preload("res://premium_residents.gd").new()
	tailor.dress(creature_visual, npc.get_meta("species"), npc_name, color, npc_name in ["Nell","Otto","Faye","Wren","Moss","Lio","Saffron","Pebble"])
	creature_visual.set_meta("premium_resident", true)
	tailor.batch_geometry(creature_visual, null, true)
	npc.set_meta("creature_visual", creature_visual)
	return npc

func _add_creature_collision(npc: CharacterBody3D, species: String) -> void:
	var collision := CollisionShape3D.new()
	if species == "Moss Fox" or species == "Leaf Deer" or species == "Forest Dragon":
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.40
		capsule.height = 1.7
		collision.shape = capsule
	elif species == "Pebble Golem":
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, 1.5, .80)
		collision.shape = box
	else:
		var sphere := SphereShape3D.new()
		sphere.radius = 0.40
		collision.shape = sphere
	collision.position.y = 0.0
	npc.add_child(collision)

var sculpt_cache: Dictionary = {}
var stall_roofs: Array[MeshInstance3D] = []

func _build_creature(root: Node3D, species: String, color: Color) -> void:
	if not sculpt_cache.has(species):
		var asset_name := "mira_premium" if species == "Moss Fox" else species.to_lower().replace(" ", "_")
		var path := "res://assets/creatures/" + asset_name + ".json"
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var vertices := PackedVector3Array()
		var normals := PackedVector3Array()
		var colors := PackedColorArray()
		for v in data.vertices:
			vertices.append(Vector3(v[0], v[1], v[2]))
		for n in data.normals:
			normals.append(Vector3(n[0], n[1], n[2]))
		for ci in data.colors.size():
			var c: Array = data.colors[ci]
			var v: Array = data.vertices[ci]
			if species != "Moss Fox" and v[2] > .30 and v[1] > -.05 and v[1] < .70:
				colors.append(Color.WHITE)
			else:
				colors.append(Color(c[0], c[1], c[2], 1.0))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(data.indices)
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		sculpt_cache[species] = mesh
	var body := MeshInstance3D.new()
	body.name = "SculptedCreature"
	body.mesh = sculpt_cache[species]
	var material := StandardMaterial3D.new()
	material.albedo_color = color.lightened(0.16)
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.72
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	body.material_override = material
	root.add_child(body)

func _build_ghost(root: Node3D, color: Color) -> void:
	_build_creature(root, "Wandering Changeling", color)
	var tailor := preload("res://premium_residents.gd").new()
	tailor.dress(root, "Wandering Changeling", "You", color, false)
	root.set_meta("premium_resident",true)
	tailor.batch_geometry(root,null,true)

func _make_ghost_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_ellipsoid(surface, Vector3(0.7, 0.62, 0.58), Vector3(0, 1.55, 0))
	_append_ellipsoid(surface, Vector3(0.72, 0.82, 0.58), Vector3(0, 0.82, 0))
	_append_ellipsoid(surface, Vector3(0.5, 0.35, 0.42), Vector3(-0.52, 0.28, 0), Vector3(0, 0, 18))
	_append_ellipsoid(surface, Vector3(0.5, 0.35, 0.42), Vector3(0.52, 0.28, 0), Vector3(0, 0, -18))
	_append_ellipsoid(surface, Vector3(0.25, 0.22, 0.3), Vector3(0, 0.18, 0))
	surface.generate_normals()
	return surface.commit()

func _append_ellipsoid(surface: SurfaceTool, radius: Vector3, center: Vector3, rotation := Vector3.ZERO) -> void:
	var basis := Basis.from_euler(Vector3(deg_to_rad(rotation.x), deg_to_rad(rotation.y), deg_to_rad(rotation.z)))
	var rings := 8
	var segments := 16
	for ring in range(rings):
		for segment in range(segments):
			var p0 := PI * float(ring) / float(rings)
			var p1 := PI * float(ring + 1) / float(rings)
			var u0 := TAU * float(segment) / float(segments)
			var u1 := TAU * float(segment + 1) / float(segments)
			var a := center + basis * (Vector3(sin(p0) * cos(u0), cos(p0), sin(p0) * sin(u0)) * radius)
			var b := center + basis * (Vector3(sin(p0) * cos(u1), cos(p0), sin(p0) * sin(u1)) * radius)
			var c := center + basis * (Vector3(sin(p1) * cos(u1), cos(p1), sin(p1) * sin(u1)) * radius)
			var d := center + basis * (Vector3(sin(p1) * cos(u0), cos(p1), sin(p1) * sin(u0)) * radius)
			surface.add_vertex(a); surface.add_vertex(b); surface.add_vertex(c)
			surface.add_vertex(a); surface.add_vertex(c); surface.add_vertex(d)

func _append_cone(surface: SurfaceTool, base_radius: float, tip_radius: float, height: float, center: Vector3, rotation := Vector3.ZERO) -> void:
	var basis := Basis.from_euler(Vector3(deg_to_rad(rotation.x), deg_to_rad(rotation.y), deg_to_rad(rotation.z)))
	var segments := 12
	for segment in range(segments):
		var a0 := TAU * float(segment) / float(segments)
		var a1 := TAU * float(segment + 1) / float(segments)
		var base_a := center + basis * Vector3(cos(a0) * base_radius, -height * 0.5, sin(a0) * base_radius)
		var base_b := center + basis * Vector3(cos(a1) * base_radius, -height * 0.5, sin(a1) * base_radius)
		var tip_a := center + basis * Vector3(cos(a0) * tip_radius, height * 0.5, sin(a0) * tip_radius)
		var tip_b := center + basis * Vector3(cos(a1) * tip_radius, height * 0.5, sin(a1) * tip_radius)
		surface.add_vertex(base_a); surface.add_vertex(base_b); surface.add_vertex(tip_b)
		surface.add_vertex(base_a); surface.add_vertex(tip_b); surface.add_vertex(tip_a)

func _append_curve(surface: SurfaceTool, start: Vector3, finish: Vector3, radius: float) -> void:
	var direction := finish - start
	var midpoint := (start + finish) * 0.5
	_append_ellipsoid(surface, Vector3(radius, direction.length() * 0.5, radius), midpoint, Vector3(0, 0, -atan2(direction.x, direction.y) * 180.0 / PI))

func _append_star(surface: SurfaceTool, center: Vector3) -> void:
	for index in range(10):
		var next := (index + 1) % 10
		var angle := -PI * 0.5 + TAU * float(index) / 10.0
		var next_angle := -PI * 0.5 + TAU * float(next) / 10.0
		var radius := 0.95 if index % 2 == 0 else 0.42
		var next_radius := 0.95 if next % 2 == 0 else 0.42
		surface.add_vertex(center + Vector3(0, 0.16, 0))
		surface.add_vertex(center + Vector3(cos(angle) * radius, 0, sin(angle) * radius))
		surface.add_vertex(center + Vector3(cos(next_angle) * next_radius, 0, sin(next_angle) * next_radius))

func _append_leaf(surface: SurfaceTool, center: Vector3) -> void:
	var points := [center, center + Vector3(-0.55, 0.85, 0), center + Vector3(-0.28, 0.42, 0.12), center + Vector3(0.28, 0.42, 0.12)]
	surface.add_vertex(points[0]); surface.add_vertex(points[1]); surface.add_vertex(points[2])
	surface.add_vertex(points[0]); surface.add_vertex(points[1]); surface.add_vertex(points[3])
func _make_ellipsoid_mesh(radius: Vector3) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 10
	var segments := 20
	for ring in range(rings):
		var v0 := float(ring) / float(rings)
		var v1 := float(ring + 1) / float(rings)
		var phi0 := PI * v0
		var phi1 := PI * v1
		for segment in range(segments):
			var u0 := TAU * float(segment) / float(segments)
			var u1 := TAU * float(segment + 1) / float(segments)
			var a := Vector3(sin(phi0) * cos(u0), cos(phi0), sin(phi0) * sin(u0)) * radius
			var b := Vector3(sin(phi0) * cos(u1), cos(phi0), sin(phi0) * sin(u1)) * radius
			var c := Vector3(sin(phi1) * cos(u1), cos(phi1), sin(phi1) * sin(u1)) * radius
			var d := Vector3(sin(phi1) * cos(u0), cos(phi1), sin(phi1) * sin(u0)) * radius
			surface.add_vertex(a)
			surface.add_vertex(b)
			surface.add_vertex(c)
			surface.add_vertex(a)
			surface.add_vertex(c)
			surface.add_vertex(d)
	surface.generate_normals()
	return surface.commit()

func _add_stone_bricks() -> void:
	preload("res://premium_town.gd").new().build_floor(self)

func _make_town_building(building_name: String, pos: Vector3, wall_color: Color, roof_color: Color, sign_text: String, facing_rotation: float = 0.0) -> void:
	var building := Node3D.new()
	building.name = building_name
	building.position = pos
	building.rotation.y = facing_rotation
	add_child(building)
	_make_box("Facade", Vector3(7.0, 4.2, 1.0), Vector3(0, 2.1, 0), wall_color, building)
	_make_box("Roof", Vector3(7.6, 0.55, 1.5), Vector3(0, 4.45, 0), roof_color, building)
	_make_box("Awning", Vector3(6.4, 0.18, 0.9), Vector3(0, 1.65, -0.85), roof_color.lightened(0.16), building)
	_make_box("Door", Vector3(1.0, 1.8, 0.12), Vector3(0, 0.9, -0.58), Color("#332a2d"), building)
	_make_box("LeftBeam", Vector3(0.16, 4.2, 0.16), Vector3(-3.25, 2.1, -0.6), WOOD_DARK, building)
	_make_box("RightBeam", Vector3(0.16, 4.2, 0.16), Vector3(3.25, 2.1, -0.6), WOOD_DARK, building)
	var window_layout := [-2.2, 0.0, 2.2] if int(abs(pos.x) + abs(pos.z)) % 2 == 0 else [-1.8, 0.9, 2.45]
	for window_x in window_layout:
		var window := _make_mesh("Window", BoxMesh.new(), Vector3(0.75, 1.0, 0.08), Color("#d8a85f"), Vector3(window_x, 2.6, -0.56))
		building.add_child(window)
		var window_cross := _make_mesh("WindowCross", BoxMesh.new(), Vector3(0.08, 1.0, 0.1), WOOD_DARK, Vector3(window_x, 2.6, -0.66))
		building.add_child(window_cross)
		var window_cross_horizontal := _make_mesh("WindowCrossBar", BoxMesh.new(), Vector3(0.75, 0.08, 0.1), WOOD_DARK, Vector3(window_x, 2.6, -0.67))
		building.add_child(window_cross_horizontal)
		if int(window_x * 10.0 + pos.x + pos.z) % 2 == 0:
			var flower_box := _make_box("WindowBox", Vector3(0.95, 0.16, 0.32), Vector3(window_x, 2.02, -0.72), WOOD_DARK, building)
			for flower_offset in [-0.25, 0.0, 0.25]:
				var flower := _make_mesh("WindowFlower", SphereMesh.new(), Vector3(0.1, 0.14, 0.1), Color("#d98278") if flower_offset < 0 else Color("#e4b65b"), Vector3(window_x + flower_offset, 2.2, -0.78))
				building.add_child(flower)
	var chimney := _make_box("Chimney", Vector3(0.55, 1.2, 0.55), Vector3(2.0, 5.1, 0.1), Color("#51464a"), building)
	var sign := Label3D.new()
	sign.text = sign_text
	sign.position = Vector3(0, 4.9, -0.6)
	sign.font_size = 34
	sign.modulate = CREAM
	sign.outline_size = 8
	sign.outline_modulate = Color("#1d1b27")
	building.add_child(sign)
	_hide_legacy_building_visuals(building)

func _hide_legacy_building_visuals(node: Node) -> void:
	if node is MeshInstance3D or node is Label3D:
		node.visible = false
	for child in node.get_children():
		_hide_legacy_building_visuals(child)

func _add_town_rows() -> void:
	# Approximate the supplied Cozy Neutrals swatches in daylight albedo;
	# existing nighttime illumination naturally cools their appearance.
	var rear_buildings := [
		["Apothecary", Color("#eeeede"), Color("#435158")],
		["Candlemaker", Color("#ddd4c7"), Color("#899c9f")],
		["Town Hall", Color("#c5bfae"), Color("#998b73")],
		["Bookseller", Color("#a8b2a9"), Color("#435158")],
		["Traveler's Rest", Color("#b79b8e"), Color("#98a091")]
	]
	for index in rear_buildings.size():
		var entry: Array = rear_buildings[index]
		_make_town_building(entry[0], Vector3(-14.0 + index * 7.0, 0, -11.4), entry[1], entry[2], entry[0].to_upper(), PI)
	var side_buildings := [
		["The Inn", Color("#ddd4c7"), Color("#435158")],
		["Guild House", Color("#98a091"), Color("#899c9f")],
		["Tailor", Color("#b79b8e"), Color("#998b73")],
		["Watchmaker", Color("#a8b2a9"), Color("#435158")]
	]
	for index in side_buildings.size():
		var entry: Array = side_buildings[index]
		_make_town_building(entry[0], Vector3(-17.0, 0, -10.5 + index * 7.0), entry[1], entry[2], entry[0].to_upper(), -PI * 0.5)

	preload("res://premium_town.gd").new().build_boundary(self)

func _add_city_lights() -> void:
	# Every street lantern is fixed to a facade; none float over the square.
	for position in [Vector3(-14.0,2.8,-10.25),Vector3(-10.5,2.8,-10.25),Vector3(-7.0,2.8,-10.25),Vector3(-3.5,2.8,-10.25),Vector3(0,2.8,-10.25),Vector3(3.5,2.8,-10.25),Vector3(7.0,2.8,-10.25),Vector3(-16.15,2.8,-8.0),Vector3(-16.15,2.8,-3.0),Vector3(-16.15,2.8,2.0),Vector3(-16.15,2.8,7.0)]:
		_make_lantern(position)

func _make_stall(stall_name: String, pos: Vector3, color: Color, sign_text: String, items: Array[String] = []) -> Node3D:
	var stall := Node3D.new()
	stall.name = stall_name
	stall.position = pos
	add_child(stall)
	# Preserve original collision footprints independently of the new scenery.
	var blockers := [
		# Match visible solids closely. The counter blocks its complete footprint.
		["Counter", Vector3(4.55,.72,1.12),Vector3(0,.36,0)],
		["Canopy",Vector3(4.8,.18,1.8),Vector3(0,3.35,0)]
	]
	for entry in blockers:
		var blocker := StaticBody3D.new()
		blocker.name = entry[0] + "Collision"
		blocker.collision_layer = 4
		blocker.position = entry[2]
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = entry[1]
		shape.shape = box
		blocker.add_child(shape)
		stall.add_child(blocker)
	# Physical posts coincide with the visible posts; there is no offset rear wall.
	for side in [-1.0,1.0]:
		var post_blocker := StaticBody3D.new()
		post_blocker.name="PostCollision"
		post_blocker.collision_layer=4
		post_blocker.position=Vector3(side*2.2,1.825,-.72)
		var post_shape := CollisionShape3D.new()
		var post_box := BoxShape3D.new()
		post_box.size=Vector3(.18,3.65,.18)
		post_shape.shape=post_box
		post_blocker.add_child(post_shape)
		stall.add_child(post_blocker)
	stall.add_child(_make_mesh("LowCounter", BoxMesh.new(), Vector3(4.4, 0.46, 1.05), WOOD, Vector3(0, 0.23, 0)))
	stall.add_child(_make_mesh("CounterTop", BoxMesh.new(), Vector3(4.5, 0.09, 1.12), Color("#bc9064"), Vector3(0, 0.50, 0)))
	for side in [-1.0, 1.0]:
		stall.add_child(_make_mesh("Post", BoxMesh.new(), Vector3(0.14, 3.65, 0.14), WOOD, Vector3(side * 2.2, 1.825, -0.72)))
		stall.add_child(_make_mesh("Curtain", BoxMesh.new(), Vector3(0.40, 1.8, 0.10), color, Vector3(side * 2.0, 2.0, -0.82)))
	var roof := _make_mesh("RaisedCanopy", BoxMesh.new(), Vector3(4.65, 0.16, 1.12), color, Vector3(0, 3.70, -0.55))
	stall.add_child(roof)
	stall_roofs.append(roof)
	var trim := _make_mesh("CanopyTrim", BoxMesh.new(), Vector3(4.65, 0.12, 0.08), CREAM, Vector3(0, 3.59, 0.02))
	stall.add_child(trim)
	stall_roofs.append(trim)
	var sign := Label3D.new()
	sign.text = sign_text
	sign.position = Vector3(0, 0.27, 0.57)
	sign.font_size = 32
	sign.modulate = CREAM
	sign.outline_size = 6
	sign.outline_modulate = WOOD_DARK
	stall.add_child(sign)
	var item_label := Label3D.new()
	item_label.text = "  ?  ".join(items)
	item_label.position = Vector3(0, 3.97, -0.55)
	item_label.font_size = 20
	item_label.modulate = CREAM
	item_label.outline_size = 5
	stall.add_child(item_label)
	_add_stall_goods(stall, sign_text, color)
	preload("res://premium_market.gd").new().upgrade(stall, self, sign_text, color)
	return stall

func _add_stall_goods(stall: Node3D, sign_text: String, color: Color) -> void:
	var display_positions := [Vector3(-1.45, 0.78, 0.15), Vector3(-0.9, 0.78, 0.15), Vector3(1.45, 0.78, 0.15)]
	if sign_text == "FORAGER":
		for position in display_positions:
			var mushroom := _make_mesh("Mooncap", SphereMesh.new(), Vector3(0.42, 0.3, 0.42), MUSHROOM_PINK, position)
			stall.add_child(mushroom)
			var stem := _make_mesh("MushroomStem", CylinderMesh.new(), Vector3(0.12, 0.32, 0.12), Color("#f2d7b0"), position + Vector3(0, -0.2, 0))
			stall.add_child(stem)
	elif sign_text == "GLASSBLOWER":
		for position in display_positions:
			var bottle := _make_mesh("GlowBottle", CylinderMesh.new(), Vector3(0.24, 0.5, 0.24), GLASS_TEAL.lightened(0.2), position)
			stall.add_child(bottle)
	elif sign_text == "TEA WITCH":
		var teapot := _make_mesh("Teapot", SphereMesh.new(), Vector3(0.55, 0.42, 0.55), Color("#8c9ed6"), display_positions[1])
		stall.add_child(teapot)
		for position in [display_positions[0], display_positions[2]]:
			stall.add_child(_make_mesh("Teacup", CylinderMesh.new(), Vector3(0.25, 0.18, 0.25), Color("#eee2c2"), position))
	elif sign_text == "BAKER":
		for position in display_positions:
			stall.add_child(_make_mesh("BreadLoaf", SphereMesh.new(), Vector3(0.52, 0.32, 0.35), Color("#d89a55"), position))
	elif sign_text == "CLOUD HERDER":
		for position in display_positions:
			stall.add_child(_make_mesh("RainJar", CylinderMesh.new(), Vector3(0.3, 0.6, 0.3), Color("#8bd8df"), position))
	elif sign_text == "MAPMAKER":
		var map_roll := _make_mesh("MapRoll", CylinderMesh.new(), Vector3(0.32, 0.6, 0.32), Color("#e7c987"), display_positions[1])
		map_roll.rotation_degrees.z = 90
		stall.add_child(map_roll)
		stall.add_child(_make_mesh("Compass", CylinderMesh.new(), Vector3(0.4, 0.08, 0.4), Color("#d8a44d"), display_positions[0]))
		stall.add_child(_make_mesh("Feather", BoxMesh.new(), Vector3(0.12, 0.55, 0.12), Color("#e8e1bd"), display_positions[2]))
	elif sign_text == "BUTTONS":
		for position in display_positions:
			stall.add_child(_make_mesh("ButtonStack", CylinderMesh.new(), Vector3(0.32, 0.22, 0.32), Color("#d86d88"), position))
	elif sign_text == "LANTERNS":
		for position in display_positions:
			var lantern := _make_mesh("PaperLantern", SphereMesh.new(), Vector3(0.38, 0.48, 0.38), Color("#f2bd5b"), position)
			stall.add_child(lantern)

func _add_island_decor() -> void:
	for position in [Vector3(-17, 0, -7), Vector3(17, 0, -7), Vector3(-17, 0, 8), Vector3(17, 0, 8)]:
		_make_palm(position)
	_make_crate(Vector3(-3.8, 0, 8.2), Color("#c68d4c"))
	_make_crate(Vector3(3.8, 0, 8.2), Color("#b8784f"))
	_make_crate(Vector3(15.7, 0, -7.5), Color("#d49a54"))
	_make_rock(Vector3(-15.5, 0, -1.8), Color("#8c9b9c"))
	_make_rock(Vector3(15.5, 0, -1.8), Color("#a6a09a"))

func _add_festival_decor() -> void:
	# Keep the plaza skyline clear; permanent lighting is architecture-mounted.
	pass

func _make_fountain(pos: Vector3) -> void:
	preload("res://premium_fountain.gd").new().build(self,pos)

func _make_palm(pos: Vector3) -> void:
	var trunk := _make_mesh("PalmTrunk", CylinderMesh.new(), Vector3(0.38, 3.0, 0.38), WOOD, pos + Vector3(0, 1.5, 0))
	trunk.rotation_degrees.z = -8
	add_child(trunk)
	for angle in [0.0, 1.25, 2.5, 3.75, 5.0]:
		var frond := _make_mesh("PalmLeaf", BoxMesh.new(), Vector3(0.18, 0.1, 1.5), LEAF_GREEN, pos + Vector3(cos(angle) * 0.7, 3.2, sin(angle) * 0.7))
		frond.rotation.y = angle
		frond.rotation.z = -0.35
		add_child(frond)

func _make_crate(pos: Vector3, color: Color) -> void:
	_make_box("Crate", Vector3(1.2, 1.0, 1.2), pos + Vector3(0, 0.5, 0), color)

func _make_rock(pos: Vector3, color: Color) -> void:
	var rock := _make_mesh("MarketRock", SphereMesh.new(), Vector3(1.5, 0.9, 1.1), color, pos + Vector3(0, 0.45, 0))
	rock.rotation_degrees = Vector3(0, 25, 12)
	add_child(rock)

func _make_lantern(pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.name = "AlwaysOnWarmLantern"
	light.position = pos
	light.light_color = LANTERN_GOLD
	light.light_energy = 2.15
	light.omni_range = 10.5
	light.distance_fade_enabled = false
	light.shadow_enabled = false
	light.add_to_group("persistent_market_lights")
	add_child(light)
	var paper_shape := CylinderMesh.new()
	paper_shape.top_radius=.28
	paper_shape.bottom_radius=.28
	paper_shape.height=.70
	paper_shape.radial_segments=24
	var glow := _make_mesh("AlwaysVisiblePaperLantern",paper_shape,Vector3.ONE,LANTERN_GOLD,pos)
	var glow_material := _make_material(Color("#f6bd60"))
	glow_material.emission_enabled = true
	glow_material.emission = Color("#f4a94f")
	glow_material.emission_energy_multiplier = 2.7
	glow.material_override = glow_material
	glow.visibility_range_end = 0.0
	glow.add_to_group("persistent_lantern_glows")
	add_child(glow)
	for band_y in [-.28,-.14,0.0,.14,.28]:
		var band := TorusMesh.new()
		band.inner_radius=.275
		band.outer_radius=.292
		add_child(_make_mesh("PaperLanternRib",band,Vector3.ONE,WOOD_DARK,pos+Vector3(0,band_y,0)))
	add_child(_make_mesh("PaperLanternCap",CylinderMesh.new(),Vector3(.34,.055,.34),WOOD_DARK,pos+Vector3(0,.37,0)))
	add_child(_make_mesh("PaperLanternBase",CylinderMesh.new(),Vector3(.34,.055,.34),WOOD_DARK,pos-Vector3(0,.37,0)))

func _make_box(box_name: String, size: Vector3, pos: Vector3, color: Color, parent: Node3D = null) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.collision_layer = 4
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.add_child(_make_mesh(box_name + "Mesh", BoxMesh.new(), size, color))
	if parent:
		parent.add_child(body)
	else:
		add_child(body)
	return body

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material

func _make_mesh(mesh_name: String, mesh: Mesh, scale: Vector3, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.position = pos
	instance.mesh = mesh
	instance.scale = scale
	var material := _make_material(color)
	if mesh_name.contains("Floor") or mesh_name.contains("Path") or mesh_name.contains("Basin"):
		material.albedo_color = color.lerp(Color("#9a9690"), 0.18)
		material.roughness = 0.9
	if mesh_name.contains("Counter") or mesh_name.contains("Post") or mesh_name.contains("Backboard") or mesh_name.contains("Beam") or mesh_name.contains("Rope"):
		material.albedo_color = color.lerp(WOOD_DARK, 0.28)
		material.roughness = 0.82
	if mesh_name.contains("Canopy") or mesh_name.contains("Curtain") or mesh_name.contains("Rug"):
		material.albedo_color = color.lerp(WORN_CANVAS, 0.12)
		material.roughness = 0.95
	if mesh_name.contains("Glass") or mesh_name.contains("Water") or mesh_name.contains("Rain"):
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.72
		material.roughness = 0.25
		material.metallic = 0.12
	instance.material_override = material
	return instance

func _show_message(text: String, duration: float) -> void:
	if ui_message:
		_show_dialogue("Market", text, duration)
