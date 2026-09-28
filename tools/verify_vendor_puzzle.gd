extends SceneTree
const Puzzle = preload("res://vendor_puzzle.gd")

func _initialize() -> void:
	call_deferred("verify")

func facing(npc: Node3D) -> Vector3:
	var visual: Node3D = npc.get_meta("creature_visual")
	var direction: Vector3 = visual.global_transform.basis.z
	direction.y=0
	return direction.normalized()

func has_lettering(node: Node) -> bool:
	if node is Label3D:
		return true
	for child in node.get_children():
		if has_lettering(child):
			return true
	return false

func count_named(node: Node,name_fragment: String) -> int:
	var total := 1 if str(node.name).contains(name_fragment) else 0
	for child in node.get_children():
		total += count_named(child,name_fragment)
	return total

func verify() -> void:
	var names: Array = Puzzle.VENDORS.keys()
	var degree: Dictionary = {}
	var count := 0
	for i in names.size():
		degree[names[i]]=0
	for i in names.size():
		assert(not Puzzle.matches(names[i],names[i]))
		for j in range(i+1,names.size()):
			assert(Puzzle.matches(names[i],names[j])==Puzzle.matches(names[j],names[i]))
			if Puzzle.matches(names[i],names[j]):
				count+=1
				degree[names[i]]+=1
				degree[names[j]]+=1
				var lines := Puzzle.conversation(names[i],names[j])
				assert(lines.size()==3)
				for line in lines:
					assert(line[0] in [names[i],names[j]])
	assert(count==3)
	for value in degree.values():
		assert(value==1)
	assert(not Puzzle.matches("Sol","Mira"))
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.set_physics_process(false)
	assert(not has_lettering(scene))
	assert(scene.get_node("StorybookFountain").get_meta("detailed_fountain"))
	assert(scene.get_node("StorybookFountain").get_meta("enlarged_fountain"))
	assert(scene.get_node("StorybookFountain").scale.x>1.0)
	assert(scene.get_node("StorybookFountain").get_child_count()>8)
	assert(scene.get_node("FantasyMarketDecor").get_meta("curated_rugs")==6)
	assert(scene.get_node("FantasyMarketDecor").get_meta("plant_clusters")>=16)
	assert(scene.get_node("FantasyMarketDecor").get_meta("minimum_rug_length")>=7.3)
	assert(scene.get_node("FantasyMarketDecor").get_meta("tall_potted_plants")==16)
	assert(scene.get_node("FantasyMarketDecor").get_meta("plant_varieties")>=4)
	var persistent_lights: Array[Node] = scene.get_tree().get_nodes_in_group("persistent_market_lights")
	var visible_glows: Array[Node] = scene.get_tree().get_nodes_in_group("persistent_lantern_glows")
	for light in persistent_lights:
		assert(light.visible and not light.distance_fade_enabled and light.light_energy>0.0)
	for glow in visible_glows:
		assert(glow.material_override is StandardMaterial3D and glow.material_override.emission_enabled)
	assert(persistent_lights.size()>=10 and visible_glows.size()==persistent_lights.size())
	var stall_lights: Array[Node] = scene.get_tree().get_nodes_in_group("persistent_stall_lights")
	assert(stall_lights.size()>=9)
	for light in stall_lights:
		assert(light.visible and not light.distance_fade_enabled and light.light_energy>0.0)
	# All six puzzle vendors begin and finish in the protected rear side of their stalls.
	assert(is_equal_approx(scene.forager.position.z,-3.55) and is_equal_approx(scene.glassblower.position.z,7.45))
	assert(is_equal_approx(scene.get_node("Juniper").position.z,1.75) and is_equal_approx(scene.get_node("Bramble").position.z,3.75))
	assert(is_equal_approx(scene.get_node("Cloud").position.z,6.15) and is_equal_approx(scene.get_node("Tula").position.z,-1.55))
	assert(abs(scene.forager.position.z-scene.glassblower.position.z)>8.0)
	assert(abs(scene.get_node("Cloud").position.z-scene.get_node("Tula").position.z)>6.0)
	scene._animate_creatures(1.0/60.0)
	for npc in scene.market_npcs:
		if npc.get_meta("species") in ["Moon Moth","Mothkin","Star Sprite"]:
			assert(npc.get_meta("creature_visual").position.y>=.069)
	assert(scene.get_node("StorybookFountain").has_node("FountainCollision"))
	assert(count_named(scene.get_node("FantasyMarketDecor"),"PlanterCollision")==16)
	# The player's body is physically stopped by the enlarged fountain.
	scene.player.global_position=Vector3(2.8,.9,-.5)
	for step in 60:
		scene.player.velocity=Vector3(-5.0,-.2,0)
		scene.player.move_and_slide()
	var fountain_gap := Vector2(scene.player.global_position.x,scene.player.global_position.z+.5).length()
	assert(fountain_gap>1.82)
	# A large planter and a stall counter also stop the player body.
	var plant: Node3D = scene.get_node("FantasyMarketDecor/FantasyPlantCluster08")
	scene.player.global_position=plant.global_position+Vector3(1.5,.9,0)
	for step in 45:
		scene.player.velocity=Vector3(-4.0,-.2,0)
		scene.player.move_and_slide()
	var plant_gap := Vector2(scene.player.global_position.x-plant.global_position.x,scene.player.global_position.z-plant.global_position.z).length()
	assert(plant_gap>.82)
	scene.player.global_position=Vector3(-2,.9,10.8)
	for step in 45:
		scene.player.velocity=Vector3(0,-.2,-4.0)
		scene.player.move_and_slide()
	assert(scene.player.global_position.z>9.85)
	# Grounded creature collision overlaps the fountain vertically and blocks it.
	var creature_probe: CharacterBody3D=scene.get_node("Pella")
	var creature_home:=creature_probe.global_position
	creature_probe.global_position=Vector3(3.0,1.0,-.5)
	for step in 60:
		creature_probe.velocity=Vector3(-5.0,0,0)
		creature_probe.move_and_slide()
	var creature_gap:=Vector2(creature_probe.global_position.x,creature_probe.global_position.z+.5).length()
	assert(creature_gap>1.95)
	creature_probe.global_position=creature_home
	scene.player.global_position=Vector3(0,.9,9)
	assert(scene.camera.size==22)
	assert(scene.task_labels[2].visible==false and not scene.fountain_phase_unlocked)
	# Learning does not trigger a match, and wrong guesses neither move nor lock vendors.
	scene._interact_with_npc(scene.forager)
	scene._interact_with_npc(scene.get_node("Juniper"))
	assert(scene.learned_vendors.size()==2 and scene.introduced_npcs.is_empty())
	var home: Vector3 = scene.forager.global_position
	scene._interact_with_npc(scene.forager)
	scene._interact_with_npc(scene.get_node("Juniper"))
	assert(not scene.introduced and scene.introduced_npcs==[scene.forager])
	assert(scene.forager.global_position==home and scene.matched_vendors.is_empty())
	# Choosing the same neighbor cancels rather than matching them with themselves.
	scene._interact_with_npc(scene.forager)
	assert(scene.introduced_npcs.is_empty())
	# Reverse selection order exercises home-side seating and collision-free paths.
	Engine.time_scale=12.0
	var pairs := [["Pip","Mira"],["Bramble","Juniper"],["Tula","Cloud"]]
	for i in pairs.size():
		var first: CharacterBody3D = scene.get_node(pairs[i][0])
		var second: CharacterBody3D = scene.get_node(pairs[i][1])
		for npc in [first,second]:
			if not scene.learned_vendors.has(npc):
				scene._interact_with_npc(npc)
		scene._interact_with_npc(first)
		scene._interact_with_npc(second)
		assert(scene.introduced and scene.trade_state=="approaching")
		assert(first.collision_mask==6 and second.collision_mask==6)
		for frame in 300:
			await physics_frame
			scene._update_trade(scene.get_physics_process_delta_time())
			if scene.trade_state=="talking":
				break
		if scene.trade_state!="talking":
			print("BLOCKED PAIR ",pairs[i]," positions ",first.global_position," / ",second.global_position," targets near ",scene._trade_meeting_point())
		assert(scene.trade_state=="talking")
		var direction := (second.global_position-first.global_position).normalized()
		assert(facing(first).dot(direction)>.99 and facing(second).dot(-direction)>.99)
		for line in 3:
			scene._advance_conversation()
		assert(scene.trade_state=="talking" and scene.completed_pairs.size()==i)
		scene._advance_conversation()
		assert(scene.trade_state=="returning" and scene.completed_pairs.size()==i+1)
		assert(scene.matched_vendors.size()==(i+1)*2)
		assert(not scene.dialogue_panel.visible and scene.ui_message.text=="")
		if i==0:
			var neighbor: Node3D=scene.get_node("Juniper")
			scene._interact_with_npc(neighbor)
			assert(scene.learned_vendors.has(neighbor))
			assert(not scene.ui_message.text.contains("finish their trade"))
		scene._complete_barter()
		assert(scene.completed_pairs.size()==i+1)
		for frame in 300:
			await physics_frame
			scene._update_trade(scene.get_physics_process_delta_time())
			if scene.trade_state=="idle":
				break
		assert(scene.trade_state=="idle" and not scene.introduced)
		assert(first.global_position.distance_to(scene.trade_first_home)<.08)
		assert(second.global_position.distance_to(scene.trade_second_home)<.08)
		assert(is_equal_approx(first.rotation.y,scene.trade_first_rotation))
		assert(is_equal_approx(second.rotation.y,scene.trade_second_rotation))
		assert(first.collision_layer==1 and second.collision_mask==5)
		# Completed vendors cannot be selected or paired again.
		scene._interact_with_npc(first)
		scene._interact_with_npc(second)
		assert(not scene.introduced and scene.introduced_npcs.is_empty())
	Engine.time_scale=1.0
	scene._update_tasks()
	assert(scene.barter_complete and scene.matched_vendors.size()==6 and scene.learned_vendors.size()==6)
	assert(scene.fountain_phase_unlocked and not scene.visited_fountain)
	assert(scene.task_heading_label.text=="FINAL MARKET TASK")
	assert(scene.task_labels[0].visible and not scene.task_labels[1].visible and not scene.task_labels[2].visible)
	assert(scene.task_labels[0].text.contains("Interact with the fountain"))
	scene.player.global_position=Vector3(2.7,.9,-.5)
	scene._update_tasks()
	assert(not scene.visited_fountain)
	scene._update_nearby_npc()
	assert(scene.interaction_label.text.contains("Touch the fountain"))
	scene._interact_with_fountain()
	assert(scene.visited_fountain and scene.objective_label.text.contains("MARKET COMPLETE"))
	assert(scene.fountain_celebration_timer>5.0 and scene.celebration_bubbles.size()==4)
	assert(scene.fireworks.get_meta("firework_bursts")==4)
	for burst in scene.fireworks.get_children():
		assert(burst is GPUParticles3D and burst.emitting and burst.amount>=56)
	for npc in scene.market_npcs:
		if not scene.shoppers.has(npc):
			var toward: Vector3=Vector3(0,1.2,-.5)-npc.global_position
			toward.y=0.0
			assert(facing(npc).dot(toward.normalized())>.98)
	var shopper_positions: Array[Vector3]=[]
	for shopper in scene.shoppers: shopper_positions.append(shopper.global_position)
	scene._process(.25)
	var roaming_during_fireworks:=false
	for i in scene.shoppers.size():
		if scene.shoppers[i].global_position.distance_to(shopper_positions[i])>.01: roaming_during_fireworks=true
	assert(roaming_during_fireworks)
	# Roaming and scripted motion retain a hard clearance around every visible
	# part of the fountain, even when a target lies on its opposite side.
	for shopper in scene.shoppers:
		shopper.set_meta("wander_target",Vector3(-shopper.global_position.x,1.0,-1.0-shopper.global_position.z))
	for frame in 900:
		scene._update_shoppers(1.0/60.0)
		for shopper in scene.shoppers:
			assert(Vector2(shopper.global_position.x,shopper.global_position.z+.5).length()>=2.379)
	print("PASS: free post-dialogue interaction, mixed pair locations, solid fountain collision, brighter fireworks, watching vendors and roaming shoppers")
	quit()
