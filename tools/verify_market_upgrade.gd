extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func visual_bounds(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		if child is MeshInstance3D:
			var bounds: AABB = child.global_transform * child.get_aabb()
			result = bounds if first else result.merge(bounds)
			first = false
	return result

func verify() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.market_npcs.size()==16)
	for npc in scene.market_npcs:
		var visual: Node3D = npc.get_meta("creature_visual")
		assert(visual.get_meta("premium_resident",false))
		assert(visual.get_meta("kawaii_eye_style","")=="black_with_white_shine")
		assert(visual.get_meta("readable_species","")==str(npc.get_meta("species")))
		assert(visual.get_meta("species_pattern",0)>0)
		assert(visual.get_child_count()>5)
		for part in visual.get_children():
			if part is MeshInstance3D:
				var mat: Material = part.material_override
				assert(mat is ShaderMaterial or (mat is BaseMaterial3D and mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED))
	assert(scene.player.get_child(1).get_meta("premium_resident",false))
	assert(scene.player.get_child(1).get_meta("kawaii_eye_style","")=="black_with_white_shine")
	assert(scene.player.get_child(1).get_meta("classic_ghost",false))
	assert(scene.player.get_child(1).get_meta("classic_sheet_silhouette",false))
	assert(scene.player.get_child(1).get_meta("white_ghost",false))
	assert(scene.player.get_child(1).get_node("SculptedCreature").visible==false)
	assert(scene.player.get_child(1).has_node("SeamlessClassicGhostBody"))
	var ghost_body: MeshInstance3D = scene.player.get_child(1).get_node("SeamlessClassicGhostBody")
	assert(ghost_body.material_override is ShaderMaterial)
	assert(Vector2(scene.player.position.x,scene.player.position.z).distance_to(Vector2(0,7.0))<.30)
	assert(scene.player.position.distance_to(Vector3(0,scene.player.position.y,9.0))>1.5)
	# A rounded classic crown needs several closely spaced rings before it reaches
	# full width; this vertex count guards against the old angular two-ring cap.
	assert(ghost_body.mesh.get_surface_count()==1)
	assert(ghost_body.mesh.surface_get_array_len(0)>=4000)
	var footprints: Array[AABB] = []
	var widths: Array[float] = []
	var heights: Array[float] = []
	var stalls := 0
	var merchandise_catalogs: Array[String] = []
	for child in scene.get_children():
		if child.has_meta("detailed_building"):
			assert(child.get_meta("wall_height")>=4.2)
			var bounds := visual_bounds(child)
			assert(bounds.position.x>=-18.001 and bounds.end.x<=18.001)
			assert(bounds.position.z>=-12.001 and bounds.end.z<=12.001)
			assert(bounds.end.y>=5.7)
			for previous in footprints:
				assert(not bounds.intersects(previous))
			footprints.append(bounds)
			widths.append(child.get_meta("allocated_width"))
			heights.append(child.get_meta("wall_height"))
		if child.has_node("PremiumMarketStall"):
			stalls += 1
			var premium_stall: Node3D = child.get_node("PremiumMarketStall")
			assert(not premium_stall.has_node("ReadableShopSign"))
			assert(premium_stall.get_meta("merchandise_matches_trade",false))
			assert(premium_stall.get_meta("sculpted_merchandise",false))
			assert(premium_stall.get_meta("merchandise_catalog",[]).size()>=2)
			assert(premium_stall.get_meta("hero_merchandise","")==premium_stall.get_meta("shop",""))
			merchandise_catalogs.append(str(premium_stall.get_meta("merchandise_catalog",[])))
	assert(footprints.size()==9 and stalls==9)
	var unique_catalogs: Dictionary = {}
	for catalog in merchandise_catalogs: unique_catalogs[catalog]=true
	assert(unique_catalogs.size()==9)
	assert(widths.min()!=widths.max() and heights.min()!=heights.max())
	assert(scene.get_node("DetailedCobblestoneGround").get_meta("cobble_count")>1500)
	var motes: GPUParticles3D = scene.get_node("TinyMagicalMotes")
	assert(motes.emitting and motes.amount==72 and motes.lifetime>=10.0)
	assert(motes.get_meta("minimum_size")<motes.get_meta("maximum_size"))
	assert(motes.get_child_count()==0)
	assert(scene.camera.size==22.0)
	assert(scene.camera.projection==Camera3D.PROJECTION_ORTHOGONAL)
	var target_occupancy: Dictionary={}
	for shopper in scene.shoppers:
		var key:=str(shopper.get_meta("wander_target"))
		target_occupancy[key]=target_occupancy.get(key,0)+1
	for count in target_occupancy.values(): assert(count<=2)
	# Orthographic head/shoulder occlusion still works on batched fabric pieces.
	var roof: MeshInstance3D = scene.stall_roofs[0]
	var home: Vector3 = scene.forager.global_position
	var target: Vector3 = roof.global_transform*roof.get_aabb().get_center()
	scene.set_physics_process(false)
	scene.camera.position = target + Vector3(10,14,11)
	scene.camera.look_at(target)
	var ray: Vector3 = -scene.camera.global_transform.basis.z
	scene.forager.global_position = target + ray*2.0-Vector3(0,.35,0)
	for frame in 15:
		await process_frame
	assert(roof.transparency>0)
	scene.forager.global_position = home
	# The existing vendor introduction and trade return logic remains runnable.
	scene._interact_with_npc(scene.forager)
	scene._interact_with_npc(scene.glassblower)
	scene._interact_with_npc(scene.forager)
	scene._interact_with_npc(scene.glassblower)
	assert(scene.introduced)
	# Check transition triggers independent of variable render-frame duration;
	# movement code is also checked unchanged against the pre-upgrade snapshot.
	var meeting: Vector3 = scene._trade_meeting_point()
	scene.forager.global_position = meeting+Vector3(-1.10,0,0)
	scene.glassblower.global_position = meeting+Vector3(1.10,0,0)
	scene._update_trade(1.0/60.0)
	assert(scene.trade_state=="talking")
	for line in 4:
		scene._advance_conversation()
	scene.forager.global_position=scene.trade_first_home
	scene.glassblower.global_position=scene.trade_second_home
	scene._update_trade(1.0/60.0)
	assert(scene.trade_state=="idle")
	print("PASS: 17 detailed opaque characters, 9 detailed stalls, 9 varied buildings contained within map without overlap, irregular cobbles, roof fading, original camera, introduction and trade return")
	if DisplayServer.get_name()!="headless":
		# Review the vendors in their original standing poses after the trade test.
		scene.forager.rotation.y=0
		scene.glassblower.rotation.y=0
		scene.set_physics_process(false)
		scene.camera.global_position=Vector3(22,31,24)
		scene.camera.look_at(Vector3(0,1,0))
		scene.camera.size=39
		for frame in 30:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tools/upgraded_market_preview.png")
		for child in scene.get_children():
			if child is CanvasLayer:
				child.visible=false
		var focus: Vector3 = scene.glassblower.global_position+Vector3(0,.5,.4)
		scene.camera.position=focus+Vector3(10,14,11)
		scene.camera.look_at(focus)
		scene.camera.size=8.5
		for frame in 15:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tools/pip_stall_preview.png")
		scene.camera.position=Vector3(10,14,11)+Vector3(-5,2,-7)
		scene.camera.look_at(Vector3(-5,2,-7))
		scene.camera.size=15
		for frame in 15:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tools/architecture_cobbles_preview.png")
		var fountain_center := Vector3(0,.8,-.5)
		for npc in scene.market_npcs:
			npc.visible=false
		scene.player.visible=false
		scene.camera.position=fountain_center+Vector3(10,14,11)
		scene.camera.look_at(fountain_center)
		scene.camera.size=5.3
		for frame in 15:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tools/detailed_fountain_preview.png")
		print("Review previews saved; draw calls: ",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	quit()
