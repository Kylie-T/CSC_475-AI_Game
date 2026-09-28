extends RefCounted
## Six reciprocal clues yield exactly three exclusive, disjoint trading pairs.
const VENDORS := {
	"Mira": {"sells":"mooncaps","needs":"jars","wares":"mooncap mushrooms","need":"a sturdy jar","note":"Mooncaps / needs jars","greeting":"Welcome! I grow glowing mooncaps. A sturdy jar would keep my spores safe."},
	"Pip": {"sells":"jars","needs":"mooncaps","wares":"sturdy jars","need":"glowing mooncaps","note":"Jars / needs mooncaps","greeting":"Lovely to see you! I make sturdy jars, but I need glowing mooncaps to warm my furnace."},
	"Juniper": {"sells":"tea","needs":"buns","wares":"calming dream tea","need":"cinnamon buns","note":"Dream tea / needs buns","greeting":"Come warm your hands! I blend dream tea and need cinnamon buns for my tea guests."},
	"Bramble": {"sells":"buns","needs":"tea","wares":"cinnamon buns","need":"calming dream tea","note":"Buns / needs dream tea","greeting":"Hello, friend! I bake cinnamon buns. Some calming dream tea would soothe me after baking."},
	"Cloud": {"sells":"rain","needs":"maps","wares":"bottled rain","need":"weather maps","note":"Bottled rain / needs maps","greeting":"Welcome, little wanderer! I bottle rain and need weather maps to guide my clouds."},
	"Tula": {"sells":"maps","needs":"rain","wares":"weather maps","need":"bottled rain","note":"Weather maps / needs rain","greeting":"Glad you stopped by! I draw weather maps, but need bottled rain to reveal their hidden ink."}
}

static func matches(first: String, second: String) -> bool:
	if first==second or not VENDORS.has(first) or not VENDORS.has(second):
		return false
	return VENDORS[first].needs==VENDORS[second].sells and VENDORS[second].needs==VENDORS[first].sells

static func pair_key(first: String,second: String) -> String:
	return first+"|"+second if first<second else second+"|"+first

static func conversation(first: String,second: String) -> Array:
	match pair_key(first,second):
		"Mira|Pip":
			return [["Mira","Pip, could one of your jars keep my spores safe?"],["Pip","Gladly! Your mooncaps will warm my little furnace."],["Mira","Then a jar for mooncaps. What a lovely trade!"]]
		"Bramble|Juniper":
			return [["Juniper","Your cinnamon buns would make my tea guests smile."],["Bramble","And your dream tea is just what I need after baking."],["Juniper","Tea for buns, then. There's always a seat for you!"]]
		"Cloud|Tula":
			return [["Cloud","Tula, could your weather maps guide my clouds?"],["Tula","Of course! A little of your rain will wake their hidden ink."],["Cloud","Rain for a map. Let's make the skies a little kinder!"]]
	return []
