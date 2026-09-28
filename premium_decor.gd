extends "res://premium_forager.gd"
## Curated visual dressing only: no collisions, scripts, labels, or gameplay state.

const RUGS := [
	[Vector3(-6.2,-.012,-6.9),-8.0,Vector2(9.6,5.10),Color("#854f61"),Color("#d4a45e")],
	[Vector3(6.5,-.012,-6.7),11.0,Vector2(8.5,4.70),Color("#526f78"),Color("#d3a46f")],
	[Vector3(-7.0,-.012,.2),7.0,Vector2(7.3,4.40),Color("#68755d"),Color("#d7bd83")],
	[Vector3(7.1,-.012,.4),-12.0,Vector2(9.1,5.10),Color("#765471"),Color("#b9a7ca")],
	[Vector3(-6.2,-.012,7.8),10.0,Vector2(8.7,4.90),Color("#8b624a"),Color("#d8b267")],
	[Vector3(6.4,-.012,8.1),-7.0,Vector2(7.6,4.30),Color("#486d70"),Color("#d09c86")]
]

const GARDENS := [
	Vector3(-15.2,0,-7.6),Vector3(-14.7,0,-4.1),Vector3(-15.5,0,.8),Vector3(-14.9,0,7.9),
	Vector3(15.1,0,-8.4),Vector3(14.6,0,-2.7),Vector3(15.35,0,3.8),Vector3(14.8,0,9.3),
	Vector3(-8.7,0,-9.45),Vector3(-2.3,0,-9.85),Vector3(4.1,0,-9.35),Vector3(9.4,0,-9.7),
	Vector3(-13.7,0,9.7),Vector3(13.4,0,8.2),Vector3(-13.9,0,5.2),Vector3(13.8,0,5.9)
]

func build(world: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "FantasyMarketDecor"
	root.set_meta("curated_rugs",RUGS.size())
	root.set_meta("plant_clusters",GARDENS.size())
	root.set_meta("minimum_rug_length",7.3)
	root.set_meta("tall_potted_plants",GARDENS.size())
	root.set_meta("plant_varieties",4)
	world.add_child(root)
	for i in RUGS.size():
		_add_rug(root,i,RUGS[i])
	for i in GARDENS.size():
		_add_garden(root,i,GARDENS[i])
	return root

func _add_rug(parent: Node3D,index: int,data: Array) -> void:
	var rug := Node3D.new()
	rug.name = "PatternedRug%02d" % index
	rug.position = data[0]
	rug.rotation_degrees.y = data[1]
	rug.set_meta("hand_woven_pattern",true)
	parent.add_child(rug)
	var size: Vector2 = data[2]
	var base: Color = data[3]
	var accent: Color = data[4]
	box(rug,"SoftBeveledWeave",Vector3.ZERO,Vector3(size.x,.032,size.y),base)
	# Broad borders, nested lozenges, checker bands and asymmetric medallions
	# evoke several hand-woven traditions without copying a specific artifact.
	for stripe in [-.42,-.32,0.0,.32,.42]:
		box(rug,"WovenBorder",Vector3(stripe*size.x,.022,0),Vector3(.045 if stripe!=0 else .075,.018,size.y*.88),accent.darkened(.08))
	for z in [-.30,0.0,.30]:
		var diamond := box(rug,"NestedDiamond",Vector3((index%2)*.11-.055,.026,z*size.y),Vector3(.48,.022,.48),accent.lightened(.08 if z==0 else 0.0))
		diamond.rotation.y=PI*.25
		var center := box(rug,"DiamondCore",diamond.position+Vector3(0,.014,0),Vector3(.22,.018,.22),base.lightened(.20))
		center.rotation.y=PI*.25
	for side in [-1.0,1.0]:
		box(rug,"GeometricEndBand",Vector3(side*size.x*.455,.027,0),Vector3(.10,.020,size.y*.92),accent.lightened(.10))
	for side in [-1.0,1.0]:
		for tassel in 9:
			box(rug,"BraidedFringe",Vector3((-0.42+tassel*.105)*size.x,0,side*(size.y*.5+.055)),Vector3(.025,.018,.12),accent.lightened(.08))
	batch_geometry(rug)

func _add_garden(parent: Node3D,index: int,position: Vector3) -> void:
	var cluster := Node3D.new()
	cluster.name = "FantasyPlantCluster%02d" % index
	cluster.position = position
	cluster.rotation.y = index*.71
	cluster.scale = Vector3.ONE*(1.18+float((index*7)%5)*.075)
	parent.add_child(cluster)
	var pot_height := .72+float(index%3)*.12
	var pot_color: Color = [Color("#9b6652"),Color("#667d7e"),Color("#887090"),Color("#a08a65")][index%4]
	var pot_shape := CylinderMesh.new()
	pot_shape.top_radius=.34+float(index%2)*.05
	pot_shape.bottom_radius=.43+float(index%2)*.05
	pot_shape.height=pot_height
	mesh(cluster,"TallOutdoorPot",pot_shape,Vector3(0,pot_height*.5,0),material(pot_color,true))
	var blocker := StaticBody3D.new()
	blocker.name="PlanterCollision"
	blocker.collision_layer=4
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius=pot_shape.bottom_radius
	shape.height=pot_height
	collision.shape=shape
	collision.position.y=pot_height*.5
	blocker.add_child(collision)
	cluster.add_child(blocker)
	ring(cluster,"ThickPotRim",Vector3(0,pot_height,0),pot_shape.top_radius+.035,pot_shape.top_radius+.035,.035,pot_color.lightened(.16))
	oval(cluster,"RichPottingSoil",Vector3(0,pot_height+.012,0),Vector3(pot_shape.top_radius*.9,.025,pot_shape.top_radius*.9),Color("#51473d"))
	var crown_y := pot_height
	match index%4:
		0: _add_tropical_fan(cluster,crown_y,index)
		1: _add_flowering_spires(cluster,crown_y,index)
		2: _add_small_tree(cluster,crown_y,index)
		_: _add_trailing_fern(cluster,crown_y,index)
	if index%4==1:
		var mote_mat := material(Color("#e3c887"))
		mote_mat.emission_enabled=true
		mote_mat.emission=Color("#e3c887")
		mote_mat.emission_energy_multiplier=1.35
		mesh(cluster,"GentleGlowMote",SphereMesh.new(),Vector3(-.14,.55,.08),mote_mat).scale=Vector3.ONE*.035
	batch_geometry(cluster)

func _add_tropical_fan(root: Node3D,y: float,seed: int) -> void:
	for i in 8:
		var a := TAU*float(i)/8.0
		var reach := .58+float((seed+i)%3)*.08
		tube(root,"LeafStem",[Vector3(0,y,0),Vector3(cos(a)*reach*.35,y+.58,sin(a)*reach*.35),Vector3(cos(a)*reach,y+.86,sin(a)*reach)],.018,Color("#526d59"))
		var leaf := oval(root,"BroadVeinedLeaf",Vector3(cos(a)*reach,y+.86,sin(a)*reach),Vector3(.15,.045,.36),Color("#718a6c") if i%2==0 else Color("#91a276"),true)
		leaf.rotation.y=-a
		leaf.rotation.z=.16

func _add_flowering_spires(root: Node3D,y: float,seed: int) -> void:
	for i in 7:
		var a := TAU*float(i)/7.0
		var height := .75+float((seed+i)%3)*.18
		var base := Vector3(cos(a)*.19,y,sin(a)*.19)
		tube(root,"FloweringStem",[base,base+Vector3(cos(a)*.08,height,sin(a)*.08)],.018,Color("#58705a"))
		for bloom in 4:
			oval(root,"ColorfulSpireBloom",base+Vector3(cos(a)*.08,height-.08*bloom,sin(a)*.08),Vector3(.085,.055,.085),[Color("#bd7896"),Color("#b297cb"),Color("#d6a75e")][(seed+i)%3],true)

func _add_small_tree(root: Node3D,y: float,seed: int) -> void:
	tube(root,"MiniatureTreeTrunk",[Vector3(0,y,0),Vector3(.03,y+.65,0),Vector3(-.04,y+1.22,.02)],.055,Color("#6d5040"))
	for i in 9:
		var a := TAU*float(i)/9.0
		var h := y+1.03+float(i%3)*.16
		oval(root,"TreeLeafCluster",Vector3(cos(a)*(.28+float(i%2)*.12),h,sin(a)*(.28+float(i%2)*.12)),Vector3(.25,.18,.22),Color("#647d65") if i%2==0 else Color("#859477"),true)
		if i%3==0:
			oval(root,"TreeBlossom",Vector3(cos(a)*.42,h+.08,sin(a)*.42),Vector3(.065,.065,.055),Color("#d3a1ad"))

func _add_trailing_fern(root: Node3D,y: float,seed: int) -> void:
	for i in 10:
		var a := TAU*float(i)/10.0
		var tip := Vector3(cos(a)*.62,y+.30-float(i%3)*.12,sin(a)*.62)
		tube(root,"ArchingFernStem",[Vector3(0,y+.05,0),Vector3(cos(a)*.30,y+.52,sin(a)*.30),tip],.014,Color("#55715e"))
		for leaflet in 4:
			var t := .30+leaflet*.17
			var p := Vector3.ZERO.lerp(tip-Vector3(0,y,0),t)+Vector3(0,y+.12*sin(t*PI),0)
			oval(root,"FernLeaflet",p,Vector3(.10,.025,.045),Color("#729074") if leaflet%2==0 else Color("#91a185"))
