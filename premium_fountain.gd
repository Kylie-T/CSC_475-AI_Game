extends "res://premium_forager.gd"

func lathe(parent: Node3D,title: String,profile: Array[Vector2],color: Color,start := 0.0,end := TAU) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 72 if end-start>6.0 else 8
	for row in range(profile.size()-1):
		for segment in segments:
			var a := lerpf(start,end,float(segment)/segments)
			var b := lerpf(start,end,float(segment+1)/segments)
			var low: Vector2 = profile[row]
			var high: Vector2 = profile[row+1]
			var points := [Vector3(sin(a)*low.x,low.y,cos(a)*low.x),Vector3(sin(b)*low.x,low.y,cos(b)*low.x),Vector3(sin(b)*high.x,high.y,cos(b)*high.x),Vector3(sin(a)*high.x,high.y,cos(a)*high.x)]
			for index in [0,2,1,0,3,2]:
				st.add_vertex(points[index])
	st.generate_normals()
	return mesh(parent,title,st.commit(),Vector3.ZERO,material(color))

func build(world: Node3D,position: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "StorybookFountain"
	root.position = position
	root.scale = Vector3.ONE*1.10
	root.set_meta("detailed_fountain",true)
	root.set_meta("enlarged_fountain",true)
	world.add_child(root)
	var fountain_blocker := StaticBody3D.new()
	fountain_blocker.name="FountainCollision"
	fountain_blocker.collision_layer=4
	var fountain_shape := CollisionShape3D.new()
	var fountain_cylinder := CylinderShape3D.new()
	# Enclose the basin, coping, lantern pedestals, planters and moonstones so
	# character physics cannot enter any visible part of the fountain ensemble.
	fountain_cylinder.radius=2.05
	fountain_cylinder.height=.72
	fountain_shape.shape=fountain_cylinder
	fountain_shape.position.y=.31
	fountain_blocker.add_child(fountain_shape)
	root.add_child(fountain_blocker)
	var stone := Color("#b8b7aa")
	var edge := Color("#d6cdb7")
	lathe(root,"SculptedFoundation",[Vector2(.01,-.045),Vector2(1.20,-.045),Vector2(1.30,.09),Vector2(1.30,.15),Vector2(1.24,.22),Vector2(.01,.22),Vector2(.01,-.045)],stone.darkened(.14))
	lathe(root,"HollowCarvedBasin",[Vector2(1.10,.15),Vector2(1.22,.20),Vector2(1.27,.34),Vector2(1.26,.46),Vector2(1.20,.51),Vector2(1.08,.51),Vector2(1.02,.43),Vector2(.99,.28),Vector2(.01,.25),Vector2(.01,.15),Vector2(1.10,.15)],stone)
	# Individual coping stones and small leaf reliefs, not a flat cylinder rim.
	for i in 16:
		var a := TAU*float(i)/16.0
		lathe(root,"BeveledCopingStone",[Vector2(1.27,.49),Vector2(1.24,.535),Vector2(1.08,.535),Vector2(1.065,.48),Vector2(1.27,.49)],edge.lightened(float(i%3)*.015),a+.012,a+TAU/16.0-.012)
		if i%2==0:
			var p := Vector3(sin(a)*1.251,.345,cos(a)*1.251)
			var leaf := oval(root,"CarvedBasinLeaf",p,Vector3(.045,.092,.022),edge)
			leaf.rotation.y=a
			leaf.rotation.z=.24
	lathe(root,"FlutedStoneColumn",[Vector2(.28,.26),Vector2(.32,.32),Vector2(.32,.40),Vector2(.24,.46),Vector2(.18,.62),Vector2(.19,.98),Vector2(.29,1.06),Vector2(.31,1.12),Vector2(.01,1.12),Vector2(.01,.26),Vector2(.28,.26)],stone)
	for i in 10:
		var a := TAU*float(i)/10.0
		tube(root,"ColumnFluting",[Vector3(sin(a)*.227,.49,cos(a)*.227),Vector3(sin(a)*.19,.65,cos(a)*.19),Vector3(sin(a)*.20,.98,cos(a)*.20)],.013,edge)
	lathe(root,"UpperPetalBowl",[Vector2(.17,1.10),Vector2(.32,1.12),Vector2(.47,1.20),Vector2(.57,1.33),Vector2(.58,1.40),Vector2(.52,1.43),Vector2(.47,1.38),Vector2(.38,1.26),Vector2(.16,1.20),Vector2(.17,1.10)],edge)
	lathe(root,"FlowerCrownStem",[Vector2(.09,1.06),Vector2(.10,1.10),Vector2(.075,1.25),Vector2(.075,1.45),Vector2(.06,1.67),Vector2(.035,1.74),Vector2(.01,1.74),Vector2(.01,1.06),Vector2(.09,1.06)],stone)
	for i in 8:
		var a := TAU*float(i)/8.0
		var petal := oval(root,"CrownStonePetal",Vector3(sin(a)*.115,1.60,cos(a)*.115),Vector3(.046,.19,.078),stone)
		petal.rotation.y=a
		petal.rotation.z=.15
	oval(root,"CopperFlowerHeart",Vector3(0,1.72,0),Vector3(.061,.083,.061),HONEY)
	# Clean glossy water, fine concentric ripples and continuous curved cascades.
	var water := material(Color("#76a5a7"))
	water.roughness=.27
	water.metallic=.10
	for entry in [[1.01,.289],[.45,1.351]]:
		var disk := CylinderMesh.new()
		disk.top_radius=entry[0]
		disk.bottom_radius=entry[0]
		disk.height=.012
		mesh(root,"StillWaterPool",disk,Vector3(0,entry[1],0),water)
	for radius in [.35,.65,.89]:
		ring(root,"FineWaterRipple",Vector3(0,.300,0),radius,radius,.006,Color("#bed2cd"))
	for i in 6:
		var a := TAU*float(i)/6.0
		var stream: Array[Vector3] = []
		for j in 25:
			var t := float(j)/24.0
			var r := lerpf(.54,.88,t)
			stream.append(Vector3(sin(a)*r,lerpf(1.405,.302,t)+.19*sin(t*PI),cos(a)*r))
		tube(root,"FlowingWaterRibbon",stream,.016,Color("#8fc2c2"))
		oval(root,"LittleSplash",Vector3(sin(a)*.88,.307,cos(a)*.88),Vector3(.04,.022,.04),Color("#c4dad3"))
	for i in 4:
		var a := TAU*float(i)/4.0
		var spray: Array[Vector3] = []
		for j in 17:
			var t := float(j)/16.0
			spray.append(Vector3(sin(a)*.37*t,1.72+.16*sin(t*PI)-.363*t,cos(a)*.37*t))
		tube(root,"FlowerHeartJet",spray,.010,Color("#accfc9"))
	# Warm garden lanterns and flowers soften the sculpted fountain surround.
	for side in [-1.0,1.0]:
		box(root,"GardenLanternPedestal",Vector3(side*1.43,.285,.05),Vector3(.25,.63,.25),stone)
		tube(root,"GardenLanternCrook",[Vector3(side*1.43,.56,-.07),Vector3(side*1.43,1.25,-.07),Vector3(side*1.43,1.32,-.01),Vector3(side*1.43,1.29,.05)],.022,INK)
		lantern(root,Vector3(side*1.43,.85,.05))
		for zz in [-1.0,1.0]:
			var center := Vector3(side*1.18,-.03,zz)
			lathe_pot(root,center,stone.darkened(.12))
			oval(root,"PlanterEarth",center+Vector3(0,.18,0),Vector3(.17,.012,.17),Color("#625c4c"))
			for i in 4:
				flower(root,center+Vector3(.08*cos(i*2.4),.18,.08*sin(i*2.4)),ROSE if i%2==0 else CREAM)
	# Four hand-cut moonstones form a softly glowing compass around the water.
	for i in 4:
		var a := PI*.25+TAU*float(i)/4.0
		var p := Vector3(cos(a)*1.66,.12,sin(a)*1.66)
		box(root,"MoonstonePlinth",p-Vector3(0,.075,0),Vector3(.22,.16,.22),stone.darkened(.18))
		var crystal_mat := material(Color("#9fbfbd"),true)
		crystal_mat.emission_enabled=true
		crystal_mat.emission=Color("#719f9f")
		crystal_mat.emission_energy_multiplier=.75
		var crystal := oval(root,"GlowingMoonstone",p,Vector3(.075,.20,.075),Color("#9fbfbd"),true)
		crystal.material_override=crystal_mat
		crystal.rotation_degrees.z=9.0 if i%2==0 else -9.0
	var light := OmniLight3D.new()
	light.name="GentleWaterGlow"
	light.position=Vector3(0,1.55,0)
	light.light_color=Color("#afd5ce")
	light.light_energy=.42
	light.omni_range=3.7
	light.distance_fade_enabled=false
	root.add_child(light)
	var key := OmniLight3D.new()
	key.name="SoftGoldenFountainFill"
	key.position=Vector3(.65,2.35,1.4)
	key.light_color=Color("#e6c69b")
	key.light_energy=1.65
	key.omni_range=4.5
	key.distance_fade_enabled=false
	root.add_child(key)
	batch_geometry(root)
	_add_animated_water(root)
	return root

func _add_animated_water(root: Node3D) -> void:
	var flow:=Node3D.new()
	flow.name="AnimatedFountainWater"
	flow.set_meta("continuous_flow",true)
	flow.set_script(preload("res://fountain_water_animation.gd"))
	root.add_child(flow)
	var water_mat:=material(Color("#a9d8d5"),true)
	water_mat.emission_enabled=true
	water_mat.emission=Color("#6faeae")
	water_mat.emission_energy_multiplier=.62
	# Staggered beads trace six continuous arcing streams from the flower crown.
	for stream in 6:
		var angle:=TAU*float(stream)/6.0
		for bead in 7:
			var drop:=mesh(flow,"FlowingWaterDrop",SphereMesh.new(),Vector3.ZERO,water_mat)
			drop.set_meta("water_phase",float(bead)/7.0+float(stream)*.027)
			drop.set_meta("water_angle",angle)
	# Expanding solid rings make the basin react where the streams land.
	for index in 3:
		var torus:=TorusMesh.new(); torus.inner_radius=.82; torus.outer_radius=.84; torus.rings=32; torus.ring_segments=8
		var ripple:=mesh(flow,"MovingWaterRipple",torus,Vector3(0,.306,0),water_mat)
		ripple.set_meta("ripple_phase",float(index)/3.0)

func lathe_pot(parent: Node3D,p: Vector3,color: Color) -> void:
	var pot := lathe(parent,"GardenStonePlanter",[Vector2(.12,0),Vector2(.18,.06),Vector2(.22,.20),Vector2(.22,.25),Vector2(.19,.25),Vector2(.17,.12),Vector2(.12,0)],color)
	pot.position=p
