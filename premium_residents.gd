extends "res://premium_forager.gd"
## Fitted anatomy details and role-specific outfits; no physics or NPC AI.

func dress(root: Node3D, species: String, resident: String, tint: Color, walking: bool) -> void:
	root.set_meta("kawaii_eye_style","black_with_white_shine")
	root.set_meta("readable_species",species)
	if resident == "You":
		_dress_classic_ghost(root)
		return
	if resident == "Mira":
		dress_mira(root)
		_apply_species_surface(root,species,tint)
		_add_species_details(root,species)
		return
	root.rotation.y = PI if walking else .25
	root.set_meta("premium_resident", true)
	var body: MeshInstance3D = root.get_child(0)
	_apply_species_surface(root,species,tint)
	var coat := SAGE
	match species:
		"Moon Moth", "Mothkin": coat = BLUE
		"Pebble Golem", "Cyclops": coat = Color("#80738d")
		"Forest Dragon", "Kobold", "Salamander": coat = ROSE
		"Star Sprite", "Halfling": coat = Color("#958571")
		"Leaf Deer", "Dryad": coat = SAGE
		"Frogfolk", "Trollkin": coat = INK.lightened(.14)
		"Catfolk", "Satyr": coat = Color("#9a849a")
	garment(root,"TailoredCoat",[Vector3(-.77,.38,.32),Vector3(-.63,.405,.34),Vector3(-.43,.38,.33),Vector3(-.24,.32,.28)],coat)
	garment(root,"LayeredCapelet",[Vector3(-.43,.46,.35),Vector3(-.32,.42,.33),Vector3(-.19,.34,.29)],coat.lightened(.12))
	ring(root,"CapeletPiping",Vector3(0,-.43,0),.46,.35,.015,CREAM)
	ring(root,"CoatHem",Vector3(0,-.76,0),.38,.32,.013,HONEY)
	garment(root,"LinenVest",[Vector3(-.71,.245,.35),Vector3(-.48,.24,.35),Vector3(-.29,.22,.32)],CREAM)
	for i in 3:
		oval(root,"CopperButton",Vector3(0,-.35-i*.105,.35),Vector3(.026,.027,.014),HONEY)
	for side in [-1.0,1.0]:
		for i in 4:
			box(root,"TailoredStitch",Vector3(side*.21,-.66+i*.055,.345),Vector3(.024,.012,.012),HONEY)
	var positions := [-.24,.24] if species != "Cyclops" else [0.0]
	for x in positions:
		var center := Vector3(x,.38,.449)
		if species == "Frogfolk":
			center = Vector3(signf(x)*.38,.69,.331)
		if species == "Pebble Golem":
			center.z = .502
		if species == "Cyclops":
			center = Vector3(0,.37,.482)
		var scale_eye := 1.18 if species == "Cyclops" else 1.0
		oval(root,"KawaiiBlackEye",center+Vector3(0,0,.045),Vector3(.132,.151,.064)*scale_eye,Color("#252b31"),true)
		oval(root,"WhiteEyeShine",center+Vector3(-.035,.052,.108),Vector3(.027,.032,.011)*scale_eye,Color.WHITE)
		oval(root,"SmallWhiteEyeShine",center+Vector3(.030,-.032,.108),Vector3(.011,.014,.009),Color.WHITE)
		tube(root,"SoftBrow",[center+Vector3(-.10,.19,-.040),center+Vector3(0,.218,-.032),center+Vector3(.10,.19,-.044)],.015,INK.lightened(.1))
	var smile_z := .474
	if species in ["Forest Dragon","Salamander","Kobold","Catfolk"]:
		smile_z = .619
		oval(root,"LittleNose",Vector3(0,.145,.642),Vector3(.060,.039,.023),INK)
	tube(root,"ContentedSmile",[Vector3(-.115,.075,smile_z),Vector3(-.060,.045,smile_z+.010),Vector3(0,.039,smile_z+.016),Vector3(.060,.045,smile_z+.010),Vector3(.115,.075,smile_z)],.011,INK)
	for side in [-1.0,1.0]:
		oval(root,"SoftCheek",Vector3(side*.41,.16,.365),Vector3(.074,.038,.015),ROSE)
		for toe in 3:
			oval(root,"PawToeDetail",Vector3(side*.23+(toe-1)*.057,-.84,.333),Vector3(.026,.020,.008),HONEY)
	# Distinct occupational accessories; fitted to clothing or held by a paw.
	match resident:
		"Pip":
			garment(root,"LeatherWorkApron",[Vector3(-.72,.27,.37),Vector3(-.49,.25,.36),Vector3(-.30,.24,.34)],TIMBER)
			tube(root,"ApronGoldenSeam",[Vector3(-.21,-.67,.38),Vector3(-.21,-.48,.37),Vector3(-.21,-.32,.35)],.011,HONEY)
			oval(root,"CopperToolClip",Vector3(.22,-.45,.36),Vector3(.033,.054,.020),HONEY)
		"Juniper":
			ring(root,"TeaWitchShawl",Vector3(0,-.20,0),.35,.31,.058,Color("#89759b"))
			oval(root,"MoonBrooch",Vector3(-.20,-.26,.32),Vector3(.050,.05,.018),HONEY)
			tube(root,"TeaSachetTie",[Vector3(.31,-.37,.20),Vector3(.34,-.54,.24)],.018,HONEY)
			oval(root,"HerbalSachet",Vector3(.34,-.60,.24),Vector3(.10,.12,.06),CREAM)
		"Bramble":
			garment(root,"BakerApron",[Vector3(-.73,.28,.37),Vector3(-.53,.27,.38),Vector3(-.30,.24,.34)],CREAM)
			for side in [-1.0,1.0]:
				oval(root,"QuiltedOvenCuff",Vector3(side*.39,-.42,.12),Vector3(.14,.075,.14),ROSE)
		"Cloud":
			ring(root,"CloudScarf",Vector3(0,-.18,0),.35,.31,.059,BLUE)
			oval(root,"RainDropBrooch",Vector3(-.20,-.27,.32),Vector3(.036,.052,.019),Color("#c4d6d4"))
		"Tula":
			tube(root,"CartographerStrap",[Vector3(-.25,-.22,.25),Vector3(0,-.45,.37),Vector3(.30,-.66,.22)],.027,TIMBER)
			oval(root,"CompassPendant",Vector3(0,-.40,.38),Vector3(.063,.063,.022),HONEY)
			box(root,"CompassNeedle",Vector3(0,-.40,.405),Vector3(.014,.075,.011),INK)
			oval(root,"MapSatchel",Vector3(.34,-.65,.13),Vector3(.14,.14,.08),TIMBER)
		_:
			var ribbon := ROSE if resident in ["Pella","Faye","Lio"] else BLUE
			ring(root,"ResidentScarf",Vector3(0,-.19,0),.34,.30,.046,ribbon)
			oval(root,"ScarfKnot",Vector3(.22,-.23,.29),Vector3(.075,.07,.047),ribbon)
			oval(root,"CollectingPouch",Vector3(-.34,-.63,.12),Vector3(.12,.14,.07),TIMBER)
			box(root,"PouchClasp",Vector3(-.34,-.60,.193),Vector3(.039,.045,.012),HONEY)
			oval(root,"PersonalBrooch",Vector3(-.20,-.25,.31),Vector3(.038,.042,.015),HONEY)
	_add_species_details(root,species)

func _dress_classic_ghost(root: Node3D) -> void:
	root.name = "ClassicChibiGhostVisual"
	root.rotation.y = .18
	root.set_meta("premium_resident",true)
	root.set_meta("species_pattern",7)
	root.set_meta("classic_ghost",true)
	root.set_meta("classic_sheet_silhouette",true)
	root.set_meta("white_ghost",true)
	# Replace the imported resident body entirely with a continuous draped-sheet
	# surface: a spherical crown, soft taper, side arms, and a scalloped hem.
	var imported_body: MeshInstance3D = root.get_child(0)
	imported_body.visible=false
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Closely spaced crown rings form a true dome in profile. The earlier crown
	# widened in one large step, which read as pointed wedges from front and back.
	var profile := [
		Vector2(.94,.012),Vector2(.925,.09),Vector2(.89,.17),Vector2(.83,.25),
		Vector2(.75,.34),Vector2(.64,.43),Vector2(.51,.50),Vector2(.36,.54),
		Vector2(.18,.55),Vector2(-.03,.53),Vector2(-.25,.52),Vector2(-.48,.56),
		Vector2(-.70,.60)
	]
	var segments := 72
	for row in profile.size()-1:
		for segment in segments:
			var points: Array[Vector3] = []
			for entry in [[row,segment],[row,segment+1],[row+1,segment+1],[row+1,segment]]:
				var ring_index: int = entry[0]
				var a := TAU*float(entry[1])/segments
				var y: float = profile[ring_index].x
				var radius: float = profile[ring_index].y
				var arm_height := exp(-pow((y-.05)*3.2,2.0))
				# x uses sin(a), so the arm mass belongs on the left and right.
				# Keep the front/back depth smooth to preserve the round crown.
				var arm_lobe := pow(abs(sin(a)),12.0)*.38*arm_height
				var x_radius := radius+arm_lobe
				if ring_index==profile.size()-1:
					y += .105*sin(a*5.0)
				points.append(Vector3(sin(a)*x_radius,y,cos(a)*radius))
			for index in [0,2,1,0,3,2]:
				st.add_vertex(points[index])
	# Close the scalloped hem so the ghost remains solid from low camera angles.
	for segment in segments:
		var a := TAU*float(segment)/segments
		var b := TAU*float(segment+1)/segments
		var y_a := -.70+.105*sin(a*5.0)
		var y_b := -.70+.105*sin(b*5.0)
		st.add_vertex(Vector3.ZERO+Vector3(0,-.73,0))
		st.add_vertex(Vector3(sin(b)*.60,y_b,cos(b)*.60))
		st.add_vertex(Vector3(sin(a)*.60,y_a,cos(a)*.60))
	st.generate_normals()
	var ghost_shader := Shader.new()
	ghost_shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec3 local_pos;
void vertex(){ local_pos=VERTEX; }
void fragment(){
	float crown=smoothstep(-.72,.92,local_pos.y);
	float side=clamp(NORMAL.y*.35+.65,0.0,1.0);
	vec3 ivory=mix(vec3(.82,.85,.87),vec3(1.0,.998,.985),crown*.72+side*.18);
	ALBEDO=ivory; ROUGHNESS=.68; SPECULAR=.20;
	float rim=pow(1.0-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),3.0);
	EMISSION=vec3(.72,.82,.84)*rim*.10;
}
"""
	var ghost_material := ShaderMaterial.new()
	ghost_material.shader=ghost_shader
	ghost_material.next_pass=material(CREAM,true).next_pass
	mesh(root,"SeamlessClassicGhostBody",st.commit(),Vector3(0,.82,0),ghost_material)
	# Familiar kawaii ghost face: large dark oval eyes, tiny mouth and blush.
	for side in [-1.0,1.0]:
		oval(root,"GhostEye",Vector3(side*.22,1.22,.515),Vector3(.105,.145,.038),INK,true)
		oval(root,"GhostEyeShine",Vector3(side*.19,1.275,.554),Vector3(.026,.034,.012),Color("#fbf7e9"))
		oval(root,"GhostBlush",Vector3(side*.36,1.06,.482),Vector3(.072,.034,.012),Color("#d6a5ad"))
	oval(root,"TinyGhostMouth",Vector3(0,1.04,.555),Vector3(.047,.058,.020),INK)

func _apply_species_surface(root: Node3D,species: String,tint: Color) -> void:
	var body: MeshInstance3D = root.get_child(0)
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 base_color : source_color;
uniform vec4 accent_color : source_color;
uniform vec4 second_color : source_color;
uniform int pattern_mode = 0;
uniform float pattern_shift = 0.0;
varying vec3 model_pos;
void vertex(){ model_pos = VERTEX; }
void fragment(){
	vec3 painted = base_color.rgb * COLOR.rgb;
	float guard = 1.0-smoothstep(0.25,0.43,model_pos.z);
	float mark = 0.0;
	float second = 0.0;
	if(pattern_mode==1){
		mark = smoothstep(0.35,0.78,sin((model_pos.x*1.1+model_pos.y*.42+pattern_shift)*16.0));
		second = smoothstep(.55,.86,sin((model_pos.x-model_pos.y+pattern_shift)*9.0));
	}else if(pattern_mode==2){
		mark = smoothstep(.56,.82,sin((model_pos.x+pattern_shift)*13.0)*sin((model_pos.y-pattern_shift)*16.0));
	}else if(pattern_mode==3){
		mark = smoothstep(.20,.75,sin((model_pos.y+pattern_shift)*13.0+model_pos.x*3.0));
		second = smoothstep(.68,.92,cos((model_pos.x-model_pos.z)*17.0));
	}else if(pattern_mode==4){
		float wing_ring = abs(length(vec2(abs(model_pos.x)-.54,model_pos.y+.15))-.20);
		mark = 1.0-smoothstep(.035,.075,wing_ring);
		second = (1.0-smoothstep(.07,.13,length(vec2(abs(model_pos.x)-.54,model_pos.y+.15))))*.75;
	}else if(pattern_mode==5){
		mark = smoothstep(.62,.87,cos(model_pos.x*10.0+pattern_shift)*cos(model_pos.y*11.0));
		second = smoothstep(.78,.96,sin((model_pos.x+model_pos.y)*21.0));
	}else{
		mark = smoothstep(.54,.84,sin((model_pos.x+pattern_shift)*11.0)*sin((model_pos.y-model_pos.z)*14.0));
	}
	mark *= guard;
	second *= guard;
	vec3 patterned = mix(painted,accent_color.rgb*COLOR.rgb,mark*.58);
	patterned = mix(patterned,second_color.rgb*COLOR.rgb,second*.28);
	float vertical = smoothstep(-.95,.85,model_pos.y);
	float sculpt_light = .76+vertical*.19+clamp(NORMAL.y*.5+.5,0.0,1.0)*.07;
	ALBEDO = patterned*sculpt_light;
	ROUGHNESS = .72;
	SPECULAR = .22;
	float rim = pow(1.0-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),3.0);
	EMISSION = patterned*rim*.035;
}
"""
	var surface := ShaderMaterial.new()
	surface.shader=shader
	surface.set_shader_parameter("base_color",tint.lerp(CREAM,.18) if species!="Moss Fox" else Color.WHITE)
	var accents := species_palette(species,tint)
	surface.set_shader_parameter("accent_color",accents[0])
	surface.set_shader_parameter("second_color",accents[1])
	surface.set_shader_parameter("pattern_mode",pattern_mode(species))
	surface.set_shader_parameter("pattern_shift",float(abs(species.hash()%17))*.071)
	surface.next_pass=material(CREAM,true).next_pass
	body.material_override=surface
	root.set_meta("species_pattern",pattern_mode(species))

func pattern_mode(species: String) -> int:
	if species in ["Moss Fox","Catfolk","Kobold","Salamander"]: return 1
	if species in ["Leaf Deer","Satyr","Frogfolk","Dryad","Trollkin"]: return 2
	if species in ["Forest Dragon","Cyclops"]: return 3
	if species in ["Moon Moth","Mothkin"]: return 4
	if species in ["Pebble Golem"]: return 5
	return 6

func species_palette(species: String,tint: Color) -> Array[Color]:
	match species:
		"Moss Fox": return [Color("#635448"),Color("#789174")]
		"Moon Moth","Mothkin": return [Color("#d7c6dc"),Color("#889eb0")]
		"Pebble Golem","Cyclops": return [Color("#6d6677"),Color("#b59b79")]
		"Forest Dragon","Kobold","Salamander": return [Color("#596f58"),Color("#d1a765")]
		"Star Sprite": return [Color("#d2b968"),Color("#eee5bd")]
		"Leaf Deer","Dryad","Satyr": return [Color("#687a62"),Color("#d2b98b")]
		"Frogfolk": return [Color("#5f7f78"),Color("#d9c26f")]
		"Trollkin": return [Color("#596a61"),Color("#94a481")]
		"Halfling": return [Color("#9c715e"),Color("#d2ad79")]
		"Catfolk": return [Color("#6d596b"),Color("#d6aa78")]
		_: return [tint.darkened(.24),CREAM]

func _add_species_details(root: Node3D,species: String) -> void:
	match species:
		"Moss Fox":
			oval(root,"FoxCreamMuzzle",Vector3(0,.10,.555),Vector3(.24,.135,.055),Color("#d9c9ae"),true)
			for side in [-1.0,1.0]:
				oval(root,"FoxInnerEar",Vector3(side*.38,.78,.18),Vector3(.10,.18,.035),Color("#b9817d"))
				for stripe in 3:
					var mark := oval(root,"FoxTempleMark",Vector3(side*(.25+stripe*.055),.51-stripe*.07,.425),Vector3(.055,.018,.012),Color("#655449"))
					mark.rotation.z=side*.35
			for i in 3:
				var leaf := oval(root,"MossLeafTuft",Vector3(-.38+i*.12,.70+abs(i-1)*.025,.37),Vector3(.065,.028,.018),SAGE.darkened(.08))
				leaf.rotation.z=(i-1)*.45
		"Moon Moth","Mothkin":
			ring(root,"SoftFurRuff",Vector3(0,-.18,0),.36,.31,.043,CREAM)
			for side in [-1.0,1.0]:
				oval(root,"WingPearl",Vector3(side*.54,-.15,.29),Vector3(.068,.068,.019),Color("#c9b9d1"))
				oval(root,"VelvetAntennaTip",Vector3(side*.30,.91,.07),Vector3(.065,.085,.055),Color("#8b7b94"),true)
				ring(root,"WingEyeMark",Vector3(side*.54,-.17,.315),.125,.10,.018,Color("#6f7287"))
		"Pebble Golem","Cyclops":
			tube(root,"GoldenStoneSeam",[Vector3(-.33,.66,.40),Vector3(-.17,.53,.47),Vector3(-.24,.39,.49),Vector3(-.10,.26,.51)],.011,HONEY)
			tube(root,"StoneCheekSeam",[Vector3(.28,.24,.43),Vector3(.40,.10,.38),Vector3(.35,-.04,.36)],.009,INK.lightened(.22))
		"Forest Dragon","Kobold","Salamander":
			for i in 5:
				oval(root,"BrowScale",Vector3(-.22+i*.11,.65-abs(i-2)*.018,.395),Vector3(.050,.035,.017),HONEY if i%2==0 else SAGE)
			for side in [-1.0,1.0]:
				for row in 3:
					oval(root,"CheekScale",Vector3(side*(.27+row*.065),.31-row*.075,.46),Vector3(.052,.038,.016),Color("#718067") if row%2==0 else Color("#c39d62"))
		"Star Sprite":
			for i in 5:
				var a := -PI*.5+TAU*float(i)/5.0
				oval(root,"CelestialFreckle",Vector3(cos(a)*.17,.47+sin(a)*.16,.405),Vector3(.025,.025,.012),Color("#ead998"))
		"Leaf Deer","Dryad":
			tube(root,"WoodlandVine",[Vector3(-.34,.61,.37),Vector3(-.20,.68,.42),Vector3(-.04,.61,.45),Vector3(.11,.69,.42)],.012,SAGE.darkened(.18))
			for x in [-.26,-.04,.08]:
				var leaf := oval(root,"WoodlandLeaf",Vector3(x,.69,.43),Vector3(.052,.023,.014),SAGE)
				leaf.rotation.z=x*1.4
			for side in [-1.0,1.0]:
				oval(root,"DeerCreamCheek",Vector3(side*.33,.19,.415),Vector3(.11,.075,.018),Color("#d8ccb0"))
				for spot in 3:
					oval(root,"FawnSpot",Vector3(side*(.26+spot*.06),.49+spot*.055,.425),Vector3(.022,.030,.010),CREAM)
		"Frogfolk":
			oval(root,"FrogSoftBelly",Vector3(0,-.09,.40),Vector3(.25,.31,.025),Color("#c1c69a"),true)
			for side in [-1.0,1.0]:
				for i in 3:
					oval(root,"FrogSpot",Vector3(side*(.25+i*.09),.12+i*.1,.42),Vector3(.037,.028,.012),SAGE.darkened(.25))
		"Satyr":
			for side in [-1.0,1.0]:
				ring(root,"HornBand",Vector3(side*.29,.78,0),.10,.085,.014,HONEY)
		"Trollkin":
			for p in [Vector3(-.34,.63,.32),Vector3(.28,.55,.37),Vector3(.42,.18,.34)]:
				oval(root,"MossPatch",p,Vector3(.075,.038,.022),SAGE.darkened(.12))
		"Halfling":
			for side in [-1.0,1.0]:
				for i in 3:
					oval(root,"WarmFreckle",Vector3(side*(.17+i*.045),.16+(i%2)*.035,.47),Vector3(.010,.010,.006),TIMBER)
		"Catfolk":
			oval(root,"CatCreamMuzzle",Vector3(0,.10,.605),Vector3(.205,.115,.045),Color("#d9c7b2"),true)
			for side in [-1.0,1.0]:
				oval(root,"CatInnerEar",Vector3(side*.37,.76,.18),Vector3(.09,.16,.03),Color("#b98791"))
				for i in 3:
					tube(root,"FineWhisker",[Vector3(side*.15,.10-i*.035,.55),Vector3(side*(.32+i*.04),.11-i*.055,.58)],.006,CREAM)
			for stripe in 3:
				var forehead := box(root,"CatForeheadStripe",Vector3((stripe-1)*.075,.58-abs(stripe-1)*.03,.455),Vector3(.035,.16,.014),Color("#665567"))
				forehead.rotation.z=(stripe-1)*-.16
		_:
			oval(root,"SpeciesCloakPin",Vector3(-.19,-.24,.33),Vector3(.045,.045,.016),species_palette(species,CREAM)[0])
