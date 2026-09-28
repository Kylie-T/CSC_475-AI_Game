extends RefCounted
## Visual-only quality example. No physics, interaction, or camera changes.

const CREAM := Color("#eeeade")
const SAGE := Color("#99a69a")
const ROSE := Color("#b99c90")
const BLUE := Color("#899ea1")
const INK := Color("#435158")
const TIMBER := Color("#705447")
const HONEY := Color("#c69c6b")
var outline: ShaderMaterial
var material_cache: Dictionary = {}
var canopy_color := BLUE

func material(color: Color, edged := false) -> StandardMaterial3D:
	var key := color.to_html() + str(edged)
	if material_cache.has(key):
		return material_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.78
	if edged:
		if not outline:
			outline = ShaderMaterial.new()
			var shader := Shader.new()
			shader.code = "shader_type spatial; render_mode unshaded, cull_front; void vertex(){ VERTEX += NORMAL * 0.009; } void fragment(){ ALBEDO = vec3(0.18,0.20,0.23); }"
			outline.shader = shader
		mat.next_pass = outline
	material_cache[key] = mat
	return mat

func mesh(parent: Node3D, title: String, shape: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = title
	instance.mesh = shape
	instance.position = pos
	instance.material_override = mat
	parent.add_child(instance)
	return instance

func box(parent: Node3D, title: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	# Rounded chamfers catch light: bevels are geometry, never texture noise.
	var half := size * .5
	var bevel := minf(.028, minf(size.x,minf(size.y,size.z))*.18)
	var core := half - Vector3.ONE*bevel
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in 3:
		for side in [-1.0,1.0]:
			for row in 3:
				for col in 3:
					var points: Array[Vector3] = []
					for entry in [[col,row],[col+1,row],[col+1,row+1],[col,row+1]]:
						var p := Vector3.ZERO
						p[axis] = half[axis]*side
						var u := (axis+1)%3
						var v := (axis+2)%3
						p[u] = [-half[u],-core[u],core[u],half[u]][entry[0]]
						p[v] = [-half[v],-core[v],core[v],half[v]][entry[1]]
						var c := p.clamp(-core,core)
						points.append(c+(p-c).normalized()*bevel)
					for index in ([0,2,1,0,3,2] if side>0 else [0,1,2,0,2,3]):
						st.add_vertex(points[index])
	st.generate_normals()
	return mesh(parent, title, st.commit(), pos, material(color))

func oval(parent: Node3D, title: String, pos: Vector3, radius: Vector3, color: Color, edged := false) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radial_segments = 24 if maxf(radius.x,maxf(radius.y,radius.z))>.12 else 16
	shape.rings = 12 if shape.radial_segments==24 else 8
	var instance := mesh(parent, title, shape, pos, material(color, edged))
	instance.scale = radius * 2.0
	return instance

func tube(parent: Node3D, title: String, points: Array[Vector3], radius: float, color: Color) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size() - 1):
		var tangent := (points[i + 1] - points[i]).normalized()
		var axis := Vector3.UP if abs(tangent.y) < 0.95 else Vector3.RIGHT
		var u := tangent.cross(axis).normalized()
		var v := tangent.cross(u).normalized()
		for j in 10:
			var a := TAU * float(j) / 10.0
			var b := TAU * float(j + 1) / 10.0
			var ra := radius * (cos(a) * u + sin(a) * v)
			var rb := radius * (cos(b) * u + sin(b) * v)
			for p in [points[i]+ra, points[i+1]+rb, points[i]+rb, points[i]+ra, points[i+1]+ra, points[i+1]+rb]:
				st.add_vertex(p)
	st.generate_normals()
	return mesh(parent, title, st.commit(), Vector3.ZERO, material(color))

func ring(parent: Node3D, title: String, center: Vector3, rx: float, rz: float, thickness: float, color: Color) -> void:
	var points: Array[Vector3] = []
	for i in 49:
		var a := TAU * float(i) / 48.0
		points.append(center + Vector3(cos(a)*rx, 0, sin(a)*rz))
	tube(parent, title, points, thickness, color)

func garment(parent: Node3D, title: String, rows: Array, color: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(rows.size() - 1):
		for j in 64:
			var corners: Array[Vector3] = []
			for entry in [[row,j],[row,j+1],[row+1,j+1],[row+1,j]]:
				var r: Vector3 = rows[entry[0]]
				var a := TAU * float(entry[1]) / 64.0
				corners.append(Vector3(sin(a)*r.y, r.x, cos(a)*r.z + 0.012*cos(a*10.0)))
			for index in [0,2,1,0,3,2]:
				st.add_vertex(corners[index])
	st.generate_normals()
	var mat := material(color, true)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh(parent, title, st.commit(), Vector3.ZERO, mat)

func dress_mira(root: Node3D) -> void:
	root.name = "MiraPremiumVisual"
	root.rotation.y = .30
	var body: MeshInstance3D = root.get_child(0)
	var mat: StandardMaterial3D = body.material_override
	mat.albedo_color = Color.WHITE
	mat.next_pass = material(CREAM, true).next_pass
	garment(root, "TailoredSageCoat", [Vector3(-0.78,.37,.31),Vector3(-.67,.40,.33),Vector3(-.45,.37,.32),Vector3(-.25,.31,.28)], SAGE)
	garment(root, "LayeredShoulderMantle", [Vector3(-.42,.47,.35),Vector3(-.34,.45,.34),Vector3(-.22,.34,.29)], BLUE)
	ring(root,"MantleCreamPiping",Vector3(0,-.42,0),.47,.35,.013,CREAM)
	ring(root, "CoatHemPiping", Vector3(0,-.76,0), .375,.32,.014, CREAM)
	garment(root, "CreamLinenApron", [Vector3(-.72,.27,.345),Vector3(-.60,.25,.35),Vector3(-.35,.23,.33)], CREAM)
	# Scarf wraps below the cheeks; the draped ends stay below the face.
	ring(root, "PlumScarfLower", Vector3(0,-.23,0), .34,.30,.065, Color("#796378"))
	ring(root, "PlumScarfUpper", Vector3(0,-.15,0), .33,.29,.047, Color("#978199"))
	oval(root,"ScarfKnot",Vector3(.22,-.23,.29),Vector3(.10,.09,.065),Color("#796378"))
	tube(root,"ScarfTail",[Vector3(.23,-.25,.31),Vector3(.28,-.42,.35),Vector3(.20,-.55,.36)],.062,Color("#978199"))
	for side in [-1.0,1.0]:
		for i in 5:
			box(root,"ApronStitch",Vector3(side*.22,-.66+i*.058,.34),Vector3(.024,.012,.014),HONEY)
		# Warm cream eyes with amber irises and dark pupils, embedded in the head.
		var center := Vector3(side*.255,.37,.443)
		oval(root,"KawaiiBlackEye",center+Vector3(0,.006,.044),Vector3(.145,.163,.072),Color("#252b31"),true)
		oval(root,"WhiteEyeShine",center+Vector3(-.040,.055,.122),Vector3(.029,.034,.012),Color.WHITE)
		oval(root,"SmallWhiteEyeShine",center+Vector3(.030,-.034,.122),Vector3(.011,.014,.009),Color.WHITE)
		tube(root,"ExpressiveBrow",[Vector3(side*.13,.58,.40),Vector3(side*.24,.615,.40),Vector3(side*.34,.59,.39)],.019,Color("#62443c"))
		for i in 3:
			oval(root,"MuzzleFreckle",Vector3(side*(.20+i*.046),.08+(i%2)*.04,.59-i*.025),Vector3(.012,.012,.008),TIMBER)
	oval(root,"FoxNose",Vector3(0,.15,.616),Vector3(.078,.050,.031),INK)
	tube(root,"LittleSmile",[Vector3(-.15,.015,.58),Vector3(-.07,-.014,.60),Vector3(0,.01,.615),Vector3(.07,-.014,.60),Vector3(.15,.015,.58)],.012,Color("#6b4742"))
	# A copper moon brooch and fitted little leather collecting pouch.
	oval(root,"CopperBrooch",Vector3(-.19,-.24,.32),Vector3(.047,.05,.018),HONEY)
	oval(root,"Satchel",Vector3(-.35,-.63,.12),Vector3(.16,.17,.09),TIMBER,true)
	tube(root,"SatchelStrap",[Vector3(-.27,-.26,.24),Vector3(-.33,-.43,.27),Vector3(-.35,-.58,.22)],.018,HONEY)
	box(root,"SatchelBuckle",Vector3(-.35,-.59,.21),Vector3(.05,.055,.016),HONEY)

func basket(parent: Node3D, center: Vector3, radius: float) -> void:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius*.75
	shape.height = radius*.85
	mesh(parent,"BasketBody",shape,center,material(Color("#937858")))
	for i in 6:
		ring(parent,"WovenBasketRib",center+Vector3(0,-radius*.36+i*radius*.14,0),radius*(.80+i*.037),radius*(.80+i*.037),.017,HONEY)
	for i in 18:
		var a := TAU*float(i)/18.0
		tube(parent,"BasketWeave",[center+Vector3(cos(a)*radius*.77,-radius*.39,sin(a)*radius*.77),center+Vector3(cos(a)*radius,radius*.40,sin(a)*radius)],.013,CREAM.darkened(.28))
	var handle: Array[Vector3] = []
	for i in 25:
		var a := PI*float(i)/24.0
		handle.append(center+Vector3(cos(a)*radius,radius*.4+sin(a)*radius*.85,0))
	tube(parent,"BasketHandle",handle,.028,HONEY)

func mushroom(parent: Node3D, p: Vector3, size: float, color: Color) -> void:
	oval(parent,"MushroomStem",p+Vector3(0,size*.3,0),Vector3(size*.17,size*.35,size*.17),CREAM)
	oval(parent,"MushroomCap",p+Vector3(0,size*.64,0),Vector3(size*.52,size*.26,size*.52),color,true)
	for i in 5:
		var a := TAU*float(i)/5.0
		oval(parent,"CapCreamSpot",p+Vector3(cos(a)*size*.29,size*.85,sin(a)*size*.29),Vector3(size*.063,size*.025,size*.063),CREAM)

func flower(parent: Node3D, p: Vector3, color: Color) -> void:
	tube(parent,"FlowerStem",[p,p+Vector3(.02,.23,0)],.012,SAGE.darkened(.25))
	for i in 5:
		var a := TAU*float(i)/5.0
		oval(parent,"FlowerPetal",p+Vector3(cos(a)*.07,.24+sin(a)*.07,0),Vector3(.056,.056,.025),color)
	oval(parent,"FlowerPollen",p+Vector3(0,.24,.026),Vector3(.034,.034,.020),HONEY)
	var leaf := oval(parent,"Leaf",p+Vector3(.065,.10,0),Vector3(.065,.024,.030),SAGE)
	leaf.rotation.z = .4

func lantern(parent: Node3D, p: Vector3) -> void:
	tube(parent,"LanternHanger",[p+Vector3(0,.44,0),p+Vector3(0,.18,0)],.017,INK)
	var glow := material(Color("#e6a856"))
	glow.emission_enabled = true
	glow.emission = Color("#e6ad59")
	glow.emission_energy_multiplier = 1.65
	var shape := CylinderMesh.new()
	shape.top_radius = .13
	shape.bottom_radius = .13
	shape.height = .31
	mesh(parent,"GoldenLanternPane",shape,p,glow)
	for side in [-1.0,1.0]:
		box(parent,"LanternFrame",p+Vector3(side*.13,0,0),Vector3(.025,.34,.025),INK)
	for h in [-.17,.17]:
		box(parent,"LanternCap",p+Vector3(0,h,0),Vector3(.32,.05,.27),INK)
	var light := OmniLight3D.new()
	light.name = "WarmGoldenPool"
	light.position = p+Vector3(0,-.12,.16)
	light.light_color = Color("#ffc57b")
	light.light_energy = 2.25
	light.omni_range = 5.6
	light.distance_fade_enabled = false
	light.add_to_group("persistent_stall_lights")
	# The moon supplies the shared soft shadows. Avoid six shadow maps per
	# decorative point light as the premium style expands to the whole town.
	light.shadow_enabled = false
	light.shadow_blur = 1.6
	parent.add_child(light)

func canopy(parent: Node3D, world) -> void:
	# Sculpted canvas strips: pitched crown, sag, folds and scalloped front edge.
	for strip in 12:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for row in 12:
			for col in 6:
				var points: Array[Vector3] = []
				for entry in [[col,row],[col+1,row],[col+1,row+1],[col,row+1]]:
					var u := float(entry[0])/6.0
					var v := float(entry[1])/12.0
					var x := -2.32+(float(strip)+u)*4.64/12.0
					var z := -1.12+v*1.12
					var y: float = 3.25+.24*(1.0-absf(x)/2.32)-.075*sin(v*PI)+.012*cos(u*TAU)
					if v > .90:
						y -= (v-.90)*(.9+.45*sin(u*PI))
					points.append(Vector3(x,y,z))
				for index in [0,2,1,0,3,2]:
					st.add_vertex(points[index])
		st.generate_normals()
		var mat := material(canopy_color if strip%3 != 0 else CREAM.darkened(.10))
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var fabric := mesh(parent,"FoldedCanvas",st.commit(),Vector3.ZERO,mat)
		world.stall_roofs.append(fabric)
		# Geometry stitching along each fabric seam, attached to the canvas.
		var seam: Array[Vector3] = []
		var x := -2.32+float(strip)*4.64/12.0
		for j in 13:
			var v := float(j)/12.0
			seam.append(Vector3(x,3.263+.24*(1.0-abs(x)/2.32)-.075*sin(v*PI)-max(v-.9,0)*.9,-1.12+v*1.12))
		world.stall_roofs.append(tube(parent,"CanvasSeam",seam,.010,CREAM))

func build_stall(stall: Node3D, world) -> void:
	# The existing invisible StaticBody3D nodes stay exactly where they were.
	for child in stall.get_children():
		if child is StaticBody3D:
			continue
		if child is MeshInstance3D:
			world.stall_roofs.erase(child)
		stall.remove_child(child)
		child.queue_free()
	var details := Node3D.new()
	details.name = "PremiumForagerStall"
	stall.add_child(details)
	for i in 9:
		box(details,"IndividualCounterPlank",Vector3(-1.96+i*.49,.245,0),Vector3(.465,.46,1.02),TIMBER.lightened(float(i%3)*.035))
	box(details,"CounterTop",Vector3(0,.51,0),Vector3(4.55,.12,1.12),HONEY)
	for x in [-2.2,2.2]:
		box(details,"CarvedPillar",Vector3(x,1.67,-.72),Vector3(.18,3.34,.18),TIMBER)
		for y in [.20,.80,2.78,3.14]:
			box(details,"PillarCarvedCollar",Vector3(x,y,-.72),Vector3(.25,.08,.25),HONEY)
		var bracket := tube(details,"CurvedTimberBracket",[Vector3(x,2.71,-.72),Vector3(x*.95,2.98,-.72),Vector3(x*.80,3.19,-.72),Vector3(x*.65,3.25,-.72)],.060,TIMBER)
		world.stall_roofs.append(bracket)
	canopy(details,world)
	# Thin carved vines on the front counter, far below the face.
	for side in [-1.0,1.0]:
		var vine: Array[Vector3] = []
		for i in 14:
			var x: float = side*(1.16+i*.065)
			vine.append(Vector3(x,.24+.065*sin(i*.42),.525))
		tube(details,"CarvedBotanicalVine",vine,.012,HONEY)
		for i in 4:
			var leaf := oval(details,"CarvedLeaf",Vector3(side*(1.24+i*.21),.30+.045*sin(i),.53),Vector3(.066,.026,.010),HONEY)
			leaf.rotation.z = side*.6
	box(details,"ShopSignBoard",Vector3(0,.28,.57),Vector3(2.18,.38,.055),INK)
	for side in [-1.0,1.0]:
		oval(details,"SignCopperPin",Vector3(side*1.01,.28,.607),Vector3(.025,.025,.011),HONEY)
	var sign := Label3D.new()
	sign.name = "ReadableShopSign"
	sign.text = "MIRA'S MOONCAPS"
	sign.font_size = 54
	sign.pixel_size = .0034
	sign.position = Vector3(0,.29,.608)
	sign.modulate = CREAM
	sign.outline_size = 3
	sign.outline_modulate = TIMBER
	details.add_child(sign)
	for side in [-1.0,1.0]:
		lantern(details,Vector3(side*1.96,2.38,-.31))
		basket(details,Vector3(side*1.64,.74,.04),.30)
		for i in 5:
			mushroom(details,Vector3(side*1.64+.13*cos(i*2.4),.85,.04+.12*sin(i*2.4)),.21,ROSE if i%2==0 else Color("#95819b"))
		box(details,"FlowerPlanter",Vector3(side*2.03,.20,.66),Vector3(.55,.32,.44),TIMBER)
		for i in 5:
			flower(details,Vector3(side*2.03-.19+i*.095,.35,.68+.035*sin(i)),ROSE if i%2==0 else CREAM)
	# Stacked herb drawers, labelled ceramic jars, tied parcels and tiny price cards.
	for i in 3:
		box(details,"HerbDrawer",Vector3(-1.08,.62+i*.13,-.22),Vector3(.49,.12,.39),TIMBER.lightened(.1))
		oval(details,"DrawerPull",Vector3(-1.08,.62+i*.13,.0),Vector3(.035,.025,.022),HONEY)
	for i in 3:
		var p := Vector3(.91+i*.19,.69,.04)
		oval(details,"CeramicSporeJar",p,Vector3(.095,.13,.095),SAGE if i%2==0 else CREAM)
		box(details,"JarPaperLabel",p+Vector3(0,0,.09),Vector3(.09,.075,.012),CREAM)
		oval(details,"CorkStopper",p+Vector3(0,.135,0),Vector3(.065,.03,.065),HONEY)
	for side in [-1.0,1.0]:
		var card := Label3D.new()
		card.text = "HERBS" if side<0 else "SPORES"
		card.font_size = 26
		card.pixel_size = .0025
		card.position = Vector3(side*1.12,.59,.50)
		card.modulate = INK
		card.outline_size = 0
		details.add_child(card)
	# Soft local blue-purple fill, bounded to the quality example.
	var fill := OmniLight3D.new()
	fill.name = "LocalTwilightFill"
	fill.position = Vector3(0,2.65,1.8)
	fill.light_color = Color("#aaa5dd")
	fill.light_energy = .45
	fill.omni_range = 3.2
	details.add_child(fill)

func batch_geometry(parent: Node3D, world = null, preserve_first := false) -> void:
	# Combine static parts by material while retaining moving roots and roof fades.
	var groups: Dictionary = {}
	for child in parent.get_children():
		if not child is MeshInstance3D or (preserve_first and child == parent.get_child(0)):
			continue
		var roof: bool = world != null and world.stall_roofs.has(child)
		var key := str(child.material_override.get_instance_id()) + str(roof)
		if not groups.has(key):
			groups[key] = {"parts":[],"roof":roof,"material":child.material_override}
		groups[key].parts.append(child)
	for key in groups:
		var group: Dictionary = groups[key]
		if group.parts.size()<2:
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part in group.parts:
			st.append_from(part.mesh,0,part.transform)
			if group.roof:
				world.stall_roofs.erase(part)
			parent.remove_child(part)
			part.queue_free()
		var combined := mesh(parent,"RoofBatch" if group.roof else "SculptedDetailBatch",st.commit(),Vector3.ZERO,group.material)
		if group.roof:
			world.stall_roofs.append(combined)
