extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var packed: PackedScene=load("res://main.tscn")
	var scene=packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	var fountain: Node3D=scene.get_node("StorybookFountain")
	var flow: Node3D=fountain.get_node("AnimatedFountainWater")
	assert(flow.get_meta("continuous_flow",false))
	assert(flow.get_child_count()==45)
	var drop: Node3D=flow.get_child(0)
	var before:=drop.position
	flow._process(.5)
	assert(drop.position.distance_to(before)>.1)
	assert(drop.position.y>.3 and drop.position.y<2.1)
	scene.player.global_position=scene.SUDOKU_DOOR_POSITION+Vector3(0,0,1.4)
	scene._update_nearby_npc()
	assert(scene.interaction_label.text.contains("Town Hall"))
	scene._open_sudoku()
	await process_frame
	assert(scene.sudoku_open and scene.sudoku_layer!=null)
	var popup=scene.sudoku_layer.get_node("MiniSudokuBrowser")
	assert(popup.cells.size()==36 and popup.values.size()==36)
	assert(popup.get_node("BrowserWindow/SudokuGrid").columns==6)
	var editable:int=popup.puzzle.find(0)
	assert(editable>=0 and popup._count_solutions(popup.puzzle.duplicate(),2)==1)
	var unselected_color:Color=popup.cells[editable].get_theme_stylebox("normal").bg_color
	popup.select_cell(editable)
	var selected_color:Color=popup.cells[editable].get_theme_stylebox("normal").bg_color
	assert(selected_color.get_luminance()<unselected_color.get_luminance())
	popup.enter_number(popup.solution[editable])
	assert(popup.values[editable]==popup.solution[editable])
	popup.reset_board()
	assert(popup.values[editable]==0 and popup.cells[editable].text=="")
	assert(popup.get_node("BrowserWindow/BrowserChrome/BrowserCloseButton")!=null)
	assert(popup.get_node("BrowserWindow/NewPuzzleButton")!=null)
	assert(popup.find_child("CloseBrowserButton",true,false)==null)
	popup.generate_new_puzzle()
	assert(popup.puzzle.size()==36 and popup.puzzle.count(0)>=16)
	popup.close()
	await process_frame
	assert(not scene.sudoku_open and scene.sudoku_layer==null)
	print("PASS: animated fountain flow and playable, closable Town Hall mini Sudoku browser")
	quit()
