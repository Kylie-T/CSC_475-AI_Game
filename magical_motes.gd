extends RefCounted
## Quiet visual ambience only. One bounded particle system, no lights or collision.

func build(world: Node3D) -> GPUParticles3D:
	var motes := GPUParticles3D.new()
	motes.name = "TinyMagicalMotes"
	motes.position = Vector3(0,3.0,0)
	motes.amount = 72
	motes.lifetime = 11.0
	motes.randomness = .72
	motes.preprocess = 11.0
	motes.fixed_fps = 20
	motes.visibility_aabb = AABB(Vector3(-18,-3,-12),Vector3(36,7,24))
	motes.set_meta("subtle_world_particles",true)
	motes.set_meta("minimum_size",.018)
	motes.set_meta("maximum_size",.052)
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(16.2,2.8,10.2)
	process.direction = Vector3.UP
	process.spread = 52.0
	process.initial_velocity_min = .025
	process.initial_velocity_max = .105
	process.gravity = Vector3.ZERO
	process.scale_min = .018
	process.scale_max = .052
	process.hue_variation_min = -.035
	process.hue_variation_max = .045
	motes.process_material = process
	var mote_mesh := SphereMesh.new()
	mote_mesh.radius = 1.0
	mote_mesh.height = 2.0
	mote_mesh.radial_segments = 8
	mote_mesh.rings = 4
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("#f7db93")
	glow.emission_enabled = true
	glow.emission = Color("#e7c87e")
	glow.emission_energy_multiplier = 1.25
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mote_mesh.material = glow
	motes.draw_pass_1 = mote_mesh
	world.add_child(motes)
	return motes
