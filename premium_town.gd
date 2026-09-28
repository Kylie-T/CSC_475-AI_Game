extends "res://premium_forager.gd"
## Bounded architectural scenery and batched, collision-free cobblestone detail.
var buildings: Array[Node3D] = []
var rng := RandomNumberGenerator.new()

func build_boundary(world: Node3D) -> void:
	rng.seed = 4752026
	var rear := [
		["Apothecary",5.6,4.2,1.65,CREAM,INK],
		["Candlemaker",7.1,5.3,1.8,Color("#ddd4c7"),BLUE],
		["Town Hall",7.8,6.5,1.7,Color("#c5bfae"),Color("#998b73")],
		["Bookseller",5.9,4.8,1.8,Color("#a8b2a9"),INK],
		["Traveler's Rest",7.4,5.7,1.7,ROSE,SAGE]
	]
	var cursor := -17.2
	for entry in rear:
		var width: float = entry[1]
		building(world,entry,Vector3(cursor+width*.5,0,-12.0+float(entry[3])*.5),0.0)
		cursor += width+.12
	var side := [
		["The Inn",5.2,5.9,1.65,Color("#ddd4c7"),INK],
		["Guild House",4.8,4.2,1.8,SAGE,BLUE],
		["Tailor",6.0,5.2,1.75,ROSE,Color("#998b73")],
		["Watchmaker",5.1,6.2,1.65,Color("#a8b2a9"),INK]
	]
	cursor = -9.8
	for entry in side:
		var width: float = entry[1]
		building(world,entry,Vector3(-18.0+float(entry[3])*.5,0,cursor+width*.5),PI*.5)
		cursor += width+.13

func building(world: Node3D,entry: Array,pos: Vector3,angle: float) -> void:
	var root := Node3D.new()
	root.name = "Detailed"+str(entry[0]).replace(" ","").replace("'","")
	root.position = pos
	root.rotation.y = angle
	world.add_child(root)
	buildings.append(root)
	var width: float = entry[1]
	var height: float = entry[2]
	var depth: float = entry[3]
	var plaster: Color = entry[4]
	var slate: Color = entry[5]
	root.set_meta("wall_height",height)
	root.set_meta("allocated_width",width)
	root.set_meta("allocated_depth",depth)
	root.set_meta("detailed_building",true)
	var face := depth*.5-.44
	var wall_depth := depth-.44
	box(root,"PlasterVolume",Vector3(0,height*.5,-.22),Vector3(width-.18,height,wall_depth),plaster)
	plaster_surface(root,width-.28,height-.18,face+.025,plaster)
	# Stone foundations and sculpted half-timber structure, inset within allocation.
	for i in int(width/.54):
		var x := -width*.5+.37+i*.54
		box(root,"WornFoundationBlock",Vector3(x,.18,face+.04),Vector3(.50,.29,.18),Color("#8f8d83").lightened(float(i%3)*.02))
	for x in [-width*.5+.17,0.0,width*.5-.17]:
		box(root,"SculptedTimberUpright",Vector3(x,height*.5,face+.068),Vector3(.16,height,.16),TIMBER)
		for y in [.42,height-.3]:
			box(root,"BeamPeg",Vector3(x,y,face+.158),Vector3(.07,.09,.035),HONEY)
	for y in [.50,3.55,height-.10]:
		box(root,"HorizontalTimber",Vector3(0,y,face+.07),Vector3(width-.20,.14,.15),TIMBER)
	for side in [-1.0,1.0]:
		tube(root,"CurvedUpperBrace",[Vector3(side*width*.48,height-1.0,face+.12),Vector3(side*width*.42,height-.60,face+.12),Vector3(side*width*.34,height-.18,face+.12)],.058,TIMBER)
	# Door planks are recessed behind a sculpted arch; window panes are inset too.
	box(root,"DoorRecess",Vector3(0,1.04,face+.075),Vector3(1.14,2.08,.045),INK)
	for i in 6:
		box(root,"DoorPlank",Vector3(-.445+i*.178,.98,face+.11),Vector3(.16,1.88,.06),TIMBER.lightened(float(i%2)*.055))
	var arch: Array[Vector3] = [Vector3(-.57,0,face+.16),Vector3(-.57,1.71,face+.16)]
	for i in 17:
		var a := PI-PI*float(i)/16.0
		arch.append(Vector3(cos(a)*.57,1.71+sin(a)*.50,face+.16))
	arch.append(Vector3(.57,0,face+.16))
	tube(root,"ArchedDoorFrame",arch,.064,HONEY)
	oval(root,"BrassDoorHandle",Vector3(.32,1.04,face+.16),Vector3(.055,.055,.025),HONEY)
	box(root,"Doorstep",Vector3(0,.035,face+.24),Vector3(1.25,.07,.35),Color("#aba99c"))
	var upper := height>5.0
	var xs: Array[float] = [-width*.29,width*.29]
	if width>6.7:
		xs = [-width*.33,-width*.17,width*.17,width*.33]
	for row in (2 if upper else 1):
		var y := 2.70+row*1.73
		for i in xs.size():
			window(root,Vector3(xs[i],y,face),.60 if xs.size()==4 else .82,plaster,i+row)
	# Layered slate shingles follow a pitched roof. Trim stays inside its footprint.
	var half_roof := width*.5-.12
	var rise := .90 if width>6.0 else .75
	var pitch := atan2(rise,half_roof)
	var columns := int(width/.55)
	for side in [-1.0,1.0]:
		for course in 5:
			var horizontal := half_roof/5.0
			var x: float = side*(course+.5)*horizontal
			var y := height+.20+rise*(1.0-absf(x)/half_roof)
			for col in 6:
				var z := -depth*.5+.055+(col+.5)*(depth-.11)/6.0
				var tile := box(root,"LayeredSlateShingle",Vector3(x,y+.035,z),Vector3(horizontal/cos(pitch)-.035,.065,(depth-.11)/6.0-.025),slate.lightened(float(rng.randi_range(0,4))*.025-.035))
				tile.rotation.z = -side*pitch
	tube(root,"RoofRidgeCap",[Vector3(0,height+rise+.25,-depth*.5+.07),Vector3(0,height+rise+.25,depth*.5-.07)],.060,slate.lightened(.12))
	for side in [-1.0,1.0]:
		tube(root,"GableSculptedFascia",[Vector3(side*half_roof,height+.20,depth*.5-.055),Vector3(0,height+rise+.20,depth*.5-.055)],.045,HONEY)
		box(root,"CarvedEave",Vector3(side*half_roof,height+.16,0),Vector3(.11,.16,depth-.10),TIMBER)
	# The chimney sits inside the roof allocation rather than hanging past an edge.
	for row in 6:
		for col in 2:
			box(root,"ChimneyBrick",Vector3(width*.28+(col-.5)*.22,height+.78+row*.16,-.18),Vector3(.205,.145,.34),Color("#9b8980").lightened(float((row+col)%3)*.035))
	box(root,"ChimneyCrown",Vector3(width*.28,height+1.72,-.18),Vector3(.52,.10,.43),INK)
	box(root,"ShopSignBacking",Vector3(0,2.36,face+.18),Vector3(1.52,.28,.06),INK)
	var sign := Label3D.new()
	sign.text = str(entry[0]).to_upper()
	sign.font_size = 35
	sign.pixel_size = .0029
	sign.position = Vector3(0,2.37,face+.217)
	sign.modulate = CREAM
	sign.outline_size = 1
	root.add_child(sign)
	lantern(root,Vector3(.84,1.86,face+.23))
	# Flush gutters and downpipes give the facades depth without changing physics.
	tube(root,"CopperDownpipe",[Vector3(width*.5-.24,height-.15,face+.15),Vector3(width*.5-.24,.25,face+.15),Vector3(width*.5-.33,.16,face+.24)],.035,Color("#97765e"))
	batch_geometry(root)

func plaster_surface(parent: Node3D,width: float,height: float,z: float,color: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 18:
		for col in 24:
			var points: Array[Vector3] = []
			for entry in [[col,row],[col+1,row],[col+1,row+1],[col,row+1]]:
				var x := (float(entry[0])/24.0-.5)*width
				var y := .09+float(entry[1])/18.0*height
				points.append(Vector3(x,y,z+.010*sin(x*2.1+y*.7)+.006*cos(y*2.3-x*.4)))
			for index in [0,2,1,0,3,2]:
				var p: Vector3 = points[index]
				var value := .97+.022*sin(p.x*1.1+p.y*.6)
				st.set_color(Color(value,value,value,1))
				st.add_vertex(p)
	st.generate_normals()
	var mat := material(color).duplicate() as StandardMaterial3D
	mat.vertex_color_use_as_albedo = true
	mesh(parent,"SculptedTrowelledPlaster",st.commit(),Vector3.ZERO,mat)

func window(parent: Node3D,p: Vector3,width: float,wall_color: Color,index: int) -> void:
	box(parent,"WindowRecess",p+Vector3(0,0,.025),Vector3(width+.22,1.29,.085),INK)
	var glow := material(Color("#caaa76").lightened(float(index%3)*.03))
	glow.emission_enabled = true
	glow.emission = Color("#dda85c")
	glow.emission_energy_multiplier = .45
	var shape := BoxMesh.new()
	shape.size = Vector3(width,1.10,.032)
	mesh(parent,"WarmWindowGlass",shape,p+Vector3(0,0,.076),glow)
	for side in [-1.0,1.0]:
		box(parent,"CarvedWindowJamb",p+Vector3(side*(width*.5+.055),0,.115),Vector3(.075,1.25,.10),HONEY)
	for y in [-.59,0.0,.59]:
		box(parent,"WindowMullion",p+Vector3(0,y,.123),Vector3(width+.12,.058,.07),TIMBER)
	box(parent,"WindowCentralMullion",p+Vector3(0,0,.126),Vector3(.050,1.20,.065),TIMBER)
	box(parent,"DeepWindowSill",p+Vector3(0,-.68,.19),Vector3(width+.25,.105,.28),wall_color.darkened(.12))
	if index%2==0:
		box(parent,"WindowHerbBox",p+Vector3(0,-.83,.22),Vector3(width+.1,.20,.27),TIMBER)
		for i in 5:
			flower(parent,p+Vector3((i-2)*width*.18,-.76,.24),ROSE if i%2==0 else CREAM)

func cobble_mesh(seed_value: int) -> ArrayMesh:
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = seed_value
	var outline_points: Array[Vector2] = [Vector2(-.38,-.5),Vector2(.34,-.5),Vector2(.5,-.32),Vector2(.5,.32),Vector2(.32,.5),Vector2(-.34,.5),Vector2(-.5,.31),Vector2(-.5,-.34)]
	for i in outline_points.size():
		outline_points[i] = Vector2(clampf(outline_points[i].x+local_rng.randf_range(-.042,.042),-.5,.5),clampf(outline_points[i].y+local_rng.randf_range(-.038,.038),-.5,.5))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := [Vector3(1.0,-.15,0),Vector3(1.0,-.065,0),Vector3(.85,-.035,0)]
	for layer in 2:
		for i in outline_points.size():
			var next := (i+1)%outline_points.size()
			var a: Vector2 = outline_points[i]*rings[layer].x
			var b: Vector2 = outline_points[next]*rings[layer].x
			var c: Vector2 = outline_points[next]*rings[layer+1].x
			var d: Vector2 = outline_points[i]*rings[layer+1].x
			for p in [Vector3(a.x,rings[layer].y,a.y),Vector3(b.x,rings[layer].y,b.y),Vector3(c.x,rings[layer+1].y,c.y),Vector3(a.x,rings[layer].y,a.y),Vector3(c.x,rings[layer+1].y,c.y),Vector3(d.x,rings[layer+1].y,d.y)]:
				st.add_vertex(p)
	for i in outline_points.size():
		var a := outline_points[i]*.85
		var b := outline_points[(i+1)%outline_points.size()]*.85
		# A gently worn crown, with actual chamfered corners and low relief.
		for p in [Vector3(0,-.030,0),Vector3(a.x,-.035,a.y),Vector3(b.x,-.035,b.y)]:
			st.add_vertex(p)
	st.generate_normals()
	return st.commit()

func build_floor(world: Node3D) -> void:
	rng.seed = 475804
	var ground := Node3D.new()
	ground.name = "DetailedCobblestoneGround"
	world.add_child(ground)
	box(ground,"RecessedEarthMortar",Vector3(0,-.18,0),Vector3(36,.05,24),Color("#444944"))
	var palettes := [Color("#9b9a90"),Color("#aaa69b"),Color("#8d928d"),Color("#a39993"),Color("#979a9b"),Color("#b0ab9b")]
	var groups: Dictionary = {}
	var z := -12.0
	var count := 0
	while z<11.99:
		var row_depth := minf(rng.randf_range(.48,.72),12.0-z)
		var x := -18.0
		while x<17.99:
			var length := minf(rng.randf_range(.59,1.04),18.0-x)
			if length>.14 and row_depth>.12:
				var variant := rng.randi_range(0,23)
				var color := rng.randi_range(0,5)
				var key := variant*6+color
				if not groups.has(key):
					groups[key] = {"transforms":[],"variant":variant,"color":color}
				var t := Transform3D.IDENTITY
				t.basis = Basis.from_scale(Vector3(length-.065,1.0,row_depth-.060))
				t.origin = Vector3(x+length*.5,rng.randf_range(-.006,.003),z+row_depth*.5)
				groups[key].transforms.append(t)
				count += 1
			x += length
		z += row_depth
	for key in groups:
		var group: Dictionary = groups[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = cobble_mesh(group.variant+484)
		mm.instance_count = group.transforms.size()
		for i in mm.instance_count:
			mm.set_instance_transform(i,group.transforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.name = "IrregularBeveledCobbles"
		instance.multimesh = mm
		instance.material_override = material(palettes[group.color])
		ground.add_child(instance)
	ground.set_meta("cobble_count",count)
	# Sparse sculpted moss follows joints near the boundary and the fountain.
	for i in 130:
		var x := rng.randf_range(-17.7,17.7)
		var zz := rng.randf_range(-11.7,11.7)
		if absf(x)<13.8 and absf(zz)<9.2 and Vector2(x,zz).length()>2.5:
			continue
		oval(ground,"JointMoss",Vector3(x,-.11,zz),Vector3(rng.randf_range(.06,.12),.014,rng.randf_range(.028,.045)),Color("#74806b"))
	batch_geometry(ground)
