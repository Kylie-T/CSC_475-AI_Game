extends RefCounted
## Opaque, compact storybook fireworks used only by the fountain finale.

func build(world: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name="FountainFireworks"
	root.set_meta("firework_bursts",4)
	world.add_child(root)
	var entries := [
		[Vector3(-4.2,7.0,-1.6),Color("#f2b85b")],
		[Vector3(3.7,7.8,-2.2),Color("#d98ca5")],
		[Vector3(-1.2,8.5,-3.0),Color("#91c6c3")],
		[Vector3(5.8,6.8,1.2),Color("#b7a0d6")]
	]
	for i in entries.size():
		var burst := GPUParticles3D.new()
		burst.name="StorybookBurst%02d" % i
		burst.position=entries[i][0]
		burst.amount=56
		burst.lifetime=3.1
		burst.one_shot=true
		burst.explosiveness=.96
		burst.randomness=.42
		burst.emitting=false
		burst.visibility_aabb=AABB(Vector3(-6,-6,-6),Vector3(12,12,12))
		var process := ParticleProcessMaterial.new()
		process.direction=Vector3.UP
		process.spread=180.0
		process.initial_velocity_min=1.9
		process.initial_velocity_max=4.1
		process.gravity=Vector3(0,-.78,0)
		process.scale_min=.043
		process.scale_max=.090
		burst.process_material=process
		var spark := SphereMesh.new()
		spark.radius=1.0
		spark.height=2.0
		spark.radial_segments=8
		spark.rings=4
		var mat := StandardMaterial3D.new()
		mat.albedo_color=entries[i][1]
		mat.emission_enabled=true
		mat.emission=entries[i][1]
		mat.emission_energy_multiplier=3.35
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
		spark.material=mat
		burst.draw_pass_1=spark
		root.add_child(burst)
	return root

func celebrate(root: Node3D) -> void:
	for child in root.get_children():
		if child is GPUParticles3D:
			child.restart()
			child.emitting=true
