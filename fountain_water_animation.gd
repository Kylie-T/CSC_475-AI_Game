extends Node3D

var elapsed := 0.0

func _process(delta: float) -> void:
	elapsed += delta
	for child in get_children():
		if child.has_meta("water_phase"):
			var phase: float = child.get_meta("water_phase")
			var angle: float = child.get_meta("water_angle")
			var t := fmod(elapsed * .48 + phase, 1.0)
			var radius := lerpf(.07, .91, t)
			var height := lerpf(1.69, .34, t) + sin(t * PI) * .34
			child.position = Vector3(sin(angle)*radius,height,cos(angle)*radius)
			var size := .032 + sin(t*PI)*.018
			child.scale = Vector3.ONE*size
		elif child.has_meta("ripple_phase"):
			var ripple_t := fmod(elapsed*.34+float(child.get_meta("ripple_phase")),1.0)
			child.scale = Vector3.ONE*lerpf(.42,1.0,ripple_t)
			child.position.y = .306 + sin(ripple_t*PI)*.006

