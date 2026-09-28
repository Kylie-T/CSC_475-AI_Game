extends "res://premium_forager.gd"

func upgrade(stall: Node3D, world, shop: String, tint: Color) -> void:
	canopy_color = tint.lerp(CREAM,.35)
	build_stall(stall,world)
	var display: Node3D = stall.get_node("PremiumForagerStall")
	display.name = "PremiumMarketStall"
	display.set_meta("shop",shop)
	display.set_meta("merchandise_matches_trade",true)
	display.set_meta("sculpted_merchandise",true)
	display.set_meta("hero_merchandise",shop)
	var catalogs := {
		"FORAGER":["mooncap mushrooms","forest herbs","spore jars"],
		"GLASSBLOWER":["sturdy jars","sun charms"],
		"TEA WITCH":["calming dream tea","moon-sugar"],
		"BAKER":["cinnamon buns","star loaves"],
		"CLOUD HERDER":["bottled rain","soft thunder"],
		"MAPMAKER":["weather maps","wayfinding feathers"],
		"BUTTONS":["shell buttons","ribbon"],
		"LANTERNS":["paper moons","fireflies"],
		"YOUR STALL":["odd jobs","friendship"]
	}
	display.set_meta("merchandise_catalog",catalogs.get(shop,[]))
	var titles := {"FORAGER":"MIRA'S MOONCAPS","GLASSBLOWER":"PIP'S GLOWWORKS","TEA WITCH":"JUNIPER'S TEA","BAKER":"BRAMBLE'S BAKERY","CLOUD HERDER":"CLOUD'S RAIN SHOP","MAPMAKER":"TULA'S ATLAS","BUTTONS":"PELLA'S BUTTONS","LANTERNS":"SOL'S LANTERNS","YOUR STALL":"THE WANDERER"}
	display.get_node("ReadableShopSign").text = titles.get(shop,shop)
	if shop != "FORAGER":
		for child in display.get_children():
			if child.name.begins_with("Mushroom") or child.name.begins_with("CapCream") or child.name.begins_with("HerbDrawer") or child.name.begins_with("DrawerPull") or child.name.begins_with("CeramicSpore") or child.name.begins_with("JarPaper") or child.name.begins_with("CorkStopper"):
				display.remove_child(child)
				child.queue_free()
		for side in [-1.0,1.0]:
			var p := Vector3(side*1.48,.89,.05)
			match shop:
				"GLASSBLOWER":
					for i in 3:
						sturdy_jar(display,p+Vector3((i-1)*.19,0,.03*(i%2)),.16,BLUE.lightened(.08) if i%2==0 else SAGE)
					box(display,"SunCharmTray",Vector3(side*.96,.61,.17),Vector3(.44,.07,.35),TIMBER)
					for i in 3:
						sun_charm(display,Vector3(side*.96+(i-1)*.12,.68,.17),.065)
				"TEA WITCH":
					teapot(display,p,ROSE)
					for i in 2:
						cup(display,Vector3(side*.96,.64+i*.08,.17),CREAM)
					tea_tin(display,Vector3(side*1.25,.67,.18),.13,SAGE)
					for i in 4:
						oval(display,"MoonSugarCrystal",Vector3(side*.72+(i-1.5)*.055,.68+.018*(i%2),.18),Vector3(.025,.045,.022),Color("#d8d3cf"),true)
				"BAKER":
					for i in 3:
						cinnamon_bun(display,p+Vector3((i-1)*.20,.02*(i%2),0),.13)
					star_loaf(display,Vector3(side*.97,.67,.14),.22)
				"CLOUD HERDER":
					for i in 2:
						rain_bottle(display,p+Vector3((i-.5)*.23,0,0),.20)
					oval(display,"LittleCloudSculpture",Vector3(side*.95,.70,.1),Vector3(.20,.10,.12),CREAM)
					for i in 3:
						oval(display,"CloudLobe",Vector3(side*.95+(i-1)*.1,.75,.1),Vector3(.085,.085,.10),CREAM)
					lightning_token(display,Vector3(side*.95,.68,.24),.17)
				"MAPMAKER":
					for i in 3:
						rolled_weather_map(display,p+Vector3((i-1)*.13,.08*(i%2),0),(i-1)*.15)
					weather_map(display,Vector3(side*.97,.60,.16),side)
					oval(display,"BrassCompass",Vector3(side*.95,.636,.28),Vector3(.071,.019,.071),HONEY)
					wayfinding_feather(display,Vector3(side*.70,.75,.18),side)
				"BUTTONS":
					for i in 5:
						var q := p+Vector3(.12*cos(i*2.4),.025*i,.12*sin(i*2.4))
						oval(display,"ShellButton",q,Vector3(.085,.017,.085),ROSE if i%2==0 else CREAM)
						for x in [-.023,.023]:
							oval(display,"ButtonHole",q+Vector3(x,.017,0),Vector3(.009,.006,.009),TIMBER)
					for i in 3:
						box(display,"FoldedRibbon",Vector3(side*.95,.61+i*.025,.16),Vector3(.35,.023,.18),ROSE if i%2==0 else BLUE)
				"LANTERNS":
					for i in 2:
						firefly_lantern(display,p+Vector3((i-.5)*.23,0,0),.15)
					paper_moon(display,Vector3(side*.96,.75,.12),.15)
					box(display,"MoonStand",Vector3(side*.96,.6,.12),Vector3(.22,.06,.15),TIMBER)
				_:
					box(display,"CorrespondenceStack",Vector3(side*1.35,.62,.08),Vector3(.47,.11,.35),CREAM)
					oval(display,"WaxSeal",Vector3(side*1.35,.682,.08),Vector3(.046,.012,.046),ROSE)
					box(display,"WoodenInkstand",Vector3(side*.94,.61,.15),Vector3(.21,.09,.22),TIMBER)
					bottle(display,Vector3(side*.94,.70,.15),.12,INK)
		for child in display.get_children():
			if child is Label3D and child.name != "ReadableShopSign":
				child.text = {"GLASSBLOWER":"CHARMS","TEA WITCH":"DREAM TEA","BAKER":"FRESH BREAD","CLOUD HERDER":"RAIN JARS","MAPMAKER":"MAPS","BUTTONS":"RIBBONS","LANTERNS":"MOONLIGHT"}.get(shop,"ODD JOBS")
	add_hero_merchandise(display,shop)
	add_shop_emblem(display,shop)
	batch_geometry(display,world)

func add_hero_merchandise(parent: Node3D,shop: String) -> void:
	# One large, unmistakable counter silhouette makes each shop readable from
	# the fixed camera; the smaller stock around it supplies close-up detail.
	match shop:
		"FORAGER":
			basket(parent,Vector3(0,.64,.12),.34)
			for i in 5:
				mushroom(parent,Vector3(-.28+i*.14,.82+.025*(i%2),.12),.18,[ROSE,Color("#8f769f"),Color("#b98772")][i%3])
		"GLASSBLOWER":
			box(parent,"JarDisplayRack",Vector3(0,.62,.08),Vector3(1.18,.11,.46),TIMBER)
			for i in 4:
				sturdy_jar(parent,Vector3(-.42+i*.28,.78+.035*(i%2),.09),.21,[BLUE,SAGE,Color("#a58c9d")][i%3])
		"TEA WITCH":
			teapot(parent,Vector3(-.18,.79,.10),Color("#88749b"))
			for i in 3:
				tea_tin(parent,Vector3(.16+i*.18,.72+i*.06,.10),.15,[SAGE,ROSE,BLUE][i])
		"BAKER":
			box(parent,"BunServingBoard",Vector3(0,.64,.10),Vector3(1.30,.10,.52),TIMBER)
			for i in 5:
				cinnamon_bun(parent,Vector3(-.48+i*.24,.75+.025*(i%2),.10),.17)
		"CLOUD HERDER":
			for i in 3:
				rain_bottle(parent,Vector3(-.34+i*.34,.78+.03*(i%2),.10),.25)
			lightning_token(parent,Vector3(.57,.84,.13),.27)
		"MAPMAKER":
			weather_map(parent,Vector3(0,.67,.10),1.0)
			for i in 3:
				rolled_weather_map(parent,Vector3(-.42+i*.42,.88,.10),(i-1)*.22)
			wayfinding_feather(parent,Vector3(.62,.88,.12),1.0)
		"BUTTONS":
			for i in 7:
				var a:=TAU*float(i)/7.0
				var q:=Vector3(cos(a)*.46,.73+.02*(i%3),.10+sin(a)*.16)
				oval(parent,"LargeDistinctButton",q,Vector3(.13,.035,.13),[ROSE,BLUE,HONEY,SAGE][i%4],true)
				for hole in [-.035,.035]: oval(parent,"ButtonStitchHole",q+Vector3(hole,.035,0),Vector3(.012,.008,.012),INK)
		"LANTERNS":
			for i in 3:
				firefly_lantern(parent,Vector3(-.38+i*.38,.79+.04*(i%2),.10),.22)
			paper_moon(parent,Vector3(.62,.84,.12),.23)
		_:
			for i in 3:
				box(parent,"OddJobParcel",Vector3(-.38+i*.38,.69+.07*i,.10),Vector3(.30,.16,.34),[CREAM,ROSE,BLUE][i])
				tube(parent,"ParcelTwine",[Vector3(-.38+i*.38,.78+.07*i,-.05),Vector3(-.38+i*.38,.78+.07*i,.25)],.012,HONEY)

func add_shop_emblem(parent: Node3D,shop: String) -> void:
	# Small sculpted product plaques replace text on the map.
	var p := Vector3(0,.28,.645)
	match shop:
		"FORAGER": mushroom(parent,p-Vector3(0,.13,0),.25,ROSE)
		"GLASSBLOWER": bottle(parent,p,.17,BLUE)
		"TEA WITCH": teapot(parent,p,SAGE)
		"BAKER": loaf(parent,p,.20)
		"CLOUD HERDER":
			for i in 3:
				oval(parent,"CloudPlaque",p+Vector3((i-1)*.1,.03*(i%2),0),Vector3(.085,.085,.036),CREAM)
		"MAPMAKER":
			box(parent,"MapPlaque",p,Vector3(.44,.25,.025),CREAM)
			tube(parent,"PlaqueMapRoute",[p+Vector3(-.16,-.07,.02),p+Vector3(-.07,.04,.02),p+Vector3(.06,-.02,.02),p+Vector3(.17,.07,.02)],.009,BLUE)
		"BUTTONS":
			for i in 3:
				oval(parent,"ShellButtonPlaque",p+Vector3((i-1)*.15,0,0),Vector3(.070,.070,.018),CREAM if i%2==0 else ROSE)
		"LANTERNS":
			oval(parent,"GoldenLanternPlaque",p,Vector3(.085,.115,.030),HONEY)
			for side in [-1.0,1.0]:
				box(parent,"PlaqueLanternFrame",p+Vector3(side*.09,0,.025),Vector3(.02,.25,.02),CREAM)
		_:
			for i in 3:
				var leaf := oval(parent,"LeafPlaque",p+Vector3((i-1)*.1,.045*(i%2),0),Vector3(.068,.11,.018),SAGE)
				leaf.rotation.z=(i-1)*.5

func bottle(parent: Node3D,p: Vector3,size: float,color: Color) -> void:
	oval(parent,"GlazedBottle",p,Vector3(size*.42,size*.70,size*.42),color,true)
	oval(parent,"BottleNeck",p+Vector3(0,size*.72,0),Vector3(size*.21,size*.32,size*.21),color)
	oval(parent,"BottleCork",p+Vector3(0,size*1.02,0),Vector3(size*.23,size*.10,size*.23),HONEY)
	box(parent,"BottleLinenLabel",p+Vector3(0,0,size*.42),Vector3(size*.5,size*.48,.012),CREAM)

func cup(parent: Node3D,p: Vector3,color: Color) -> void:
	oval(parent,"CupBody",p,Vector3(.10,.07,.10),color)
	ring(parent,"CupRim",p+Vector3(0,.053,0),.091,.091,.012,CREAM)
	oval(parent,"DarkTea",p+Vector3(0,.058,0),Vector3(.078,.010,.078),TIMBER)
	tube(parent,"CupHandle",[p+Vector3(.08,.04,0),p+Vector3(.15,.045,0),p+Vector3(.16,-.02,0),p+Vector3(.085,-.03,0)],.020,color)

func teapot(parent: Node3D,p: Vector3,color: Color) -> void:
	oval(parent,"GlazedTeapot",p,Vector3(.18,.14,.16),color,true)
	oval(parent,"TeapotLid",p+Vector3(0,.13,0),Vector3(.12,.034,.11),CREAM)
	oval(parent,"LidKnob",p+Vector3(0,.17,0),Vector3(.037,.03,.037),HONEY)
	tube(parent,"TeapotSpout",[p+Vector3(.13,-.03,0),p+Vector3(.22,.025,0),p+Vector3(.27,.12,0)],.037,color)
	tube(parent,"TeapotHandle",[p+Vector3(-.13,.07,0),p+Vector3(-.25,.08,0),p+Vector3(-.27,-.04,0),p+Vector3(-.14,-.06,0)],.025,color)

func loaf(parent: Node3D,p: Vector3,size: float) -> void:
	oval(parent,"GoldenLoaf",p,Vector3(size,size*.60,size*.70),HONEY,true)
	for i in 3:
		tube(parent,"SculptedBreadScore",[p+Vector3((i-1)*size*.45-.025,size*.48,-size*.26),p+Vector3((i-1)*size*.45,size*.59,0),p+Vector3((i-1)*size*.45+.025,size*.48,size*.26)],.009,CREAM)

func sturdy_jar(parent: Node3D,p: Vector3,size: float,color: Color) -> void:
	var jar := CylinderMesh.new()
	jar.top_radius=size*.66
	jar.bottom_radius=size*.72
	jar.height=size*1.25
	mesh(parent,"SturdyTradeJar",jar,p,material(color,true))
	ring(parent,"ThickJarRim",p+Vector3(0,size*.64,0),size*.72,size*.72,size*.035,CREAM)
	oval(parent,"FittedJarLid",p+Vector3(0,size*.73,0),Vector3(size*.72,size*.12,size*.72),TIMBER,true)
	tube(parent,"JarCarryHandle",[p+Vector3(-size*.62,size*.65,0),p+Vector3(-size*.45,size*1.12,0),p+Vector3(size*.45,size*1.12,0),p+Vector3(size*.62,size*.65,0)],size*.055,HONEY)

func sun_charm(parent: Node3D,p: Vector3,size: float) -> void:
	oval(parent,"SunCharmHeart",p,Vector3(size,size*.28,size),HONEY,true)
	for i in 8:
		var a := TAU*float(i)/8.0
		box(parent,"SunCharmRay",p+Vector3(cos(a)*size*1.25,.002,sin(a)*size*1.25),Vector3(size*.18,size*.10,size*.48),HONEY)

func tea_tin(parent: Node3D,p: Vector3,size: float,color: Color) -> void:
	var tin := CylinderMesh.new()
	tin.top_radius=size
	tin.bottom_radius=size
	tin.height=size*1.5
	mesh(parent,"DreamTeaTin",tin,p,material(color,true))
	oval(parent,"TeaTinLid",p+Vector3(0,size*.78,0),Vector3(size*1.03,size*.09,size*1.03),HONEY)
	for i in 3:
		var leaf := oval(parent,"SculptedTeaLeaf",p+Vector3((i-1)*size*.38,.02,size*1.01),Vector3(size*.16,size*.28,size*.05),SAGE.lightened(.08))
		leaf.rotation.z=(i-1)*.5

func cinnamon_bun(parent: Node3D,p: Vector3,size: float) -> void:
	oval(parent,"CinnamonBun",p,Vector3(size,size*.55,size),HONEY,true)
	var spiral: Array[Vector3] = []
	for i in 25:
		var t := float(i)/24.0
		var a := t*TAU*2.35
		var r := size*(.72-.57*t)
		spiral.append(p+Vector3(cos(a)*r,size*.56,sin(a)*r))
	tube(parent,"CinnamonSpiral",spiral,size*.055,Color("#765044"))

func star_loaf(parent: Node3D,p: Vector3,size: float) -> void:
	oval(parent,"StarLoafCenter",p,Vector3(size*.65,size*.42,size*.65),HONEY,true)
	for i in 5:
		var a := TAU*float(i)/5.0-PI*.5
		var point := oval(parent,"StarLoafPoint",p+Vector3(cos(a)*size*.62,0,sin(a)*size*.62),Vector3(size*.42,size*.34,size*.22),HONEY,true)
		point.rotation.y=-a

func rain_bottle(parent: Node3D,p: Vector3,size: float) -> void:
	bottle(parent,p,size,Color("#779fa8"))
	for i in 3:
		oval(parent,"CapturedRainDrop",p+Vector3((i-1)*size*.18,-size*.20+i*size*.18,size*.43),Vector3(size*.055,size*.09,size*.035),Color("#bad4d1"))

func lightning_token(parent: Node3D,p: Vector3,size: float) -> void:
	tube(parent,"SoftThunderBolt",[p+Vector3(-size*.18,size*.50,0),p+Vector3(size*.10,size*.08,0),p-Vector3(size*.03,size*.08,0),p+Vector3(size*.20,-size*.52,0)],size*.075,Color("#d4b96f"))

func rolled_weather_map(parent: Node3D,p: Vector3,tilt: float) -> void:
	var scroll := oval(parent,"RolledWeatherMap",p,Vector3(.055,.22,.055),CREAM,true)
	scroll.rotation.z=tilt
	ring(parent,"MapRibbon",p,.062,.062,.012,BLUE)

func weather_map(parent: Node3D,p: Vector3,side: float) -> void:
	box(parent,"OpenedWeatherMap",p,Vector3(.48,.020,.35),CREAM)
	tube(parent,"WeatherFrontRoute",[p+Vector3(-.17,.018,-.08),p+Vector3(-.07,.020,.08),p+Vector3(.05,.018,.02),p+Vector3(.18,.020,.11)],.011,BLUE)
	for i in 3:
		oval(parent,"MapCloudSymbol",p+Vector3(-.13+i*.13,.026,-.02+.055*(i%2)),Vector3(.028,.010,.022),Color("#8da1a3"))

func wayfinding_feather(parent: Node3D,p: Vector3,side: float) -> void:
	tube(parent,"FeatherQuill",[p-Vector3(0,.22,0),p+Vector3(0,.24,0)],.014,HONEY)
	for i in 5:
		var y := -.13+i*.075
		var barb := oval(parent,"WayfindingFeatherBarb",p+Vector3(side*(.04+.012*i),y,0),Vector3(.075,.025,.018),Color("#9eaf98"))
		barb.rotation.z=side*.35

func firefly_lantern(parent: Node3D,p: Vector3,size: float) -> void:
	sturdy_jar(parent,p,size,Color("#8c917e"))
	var glow := material(Color("#f1c45f"))
	glow.emission_enabled=true
	glow.emission=Color("#f0b94f")
	glow.emission_energy_multiplier=2.0
	for i in 3:
		var firefly := oval(parent,"ContainedFirefly",p+Vector3((i-1)*size*.24,-size*.18+i*size*.18,size*.48),Vector3.ONE*size*.045,Color("#f1c45f"))
		firefly.material_override=glow

func paper_moon(parent: Node3D,p: Vector3,size: float) -> void:
	oval(parent,"PaperMoon",p,Vector3(size,size*1.08,size*.32),CREAM,true)
	oval(parent,"MoonCutout",p+Vector3(size*.075,size*.035,size*.30),Vector3(size*.72,size*.78,size*.08),Color("#778587"))
