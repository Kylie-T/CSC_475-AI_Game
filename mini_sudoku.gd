extends Control
signal dismissed

const TEAL:=Color("#97b3ae")
const SAGE:=Color("#d3e1d3")
const BLUSH:=Color("#f0ddd6")
const PEACH:=Color("#efbdb1")
const SAND:=Color("#d5ccbf")
const INK:=Color("#596361")

var solution:Array[int]=[]
var puzzle:Array[int]=[]
var values:Array[int]=[]
var cells:Array[Button]=[]
var selected:=-1
var status:Label

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); mouse_filter=Control.MOUSE_FILTER_STOP
	var shade:=ColorRect.new(); shade.color=Color(0.08,0.11,0.12,.78); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(shade)
	var browser:=Panel.new(); browser.name="BrowserWindow"; browser.position=Vector2(285,30); browser.size=Vector2(710,660); add_child(browser)
	var frame:=StyleBoxFlat.new(); frame.bg_color=Color("#fffaf5"); frame.border_color=TEAL.darkened(.18); frame.set_border_width_all(3); frame.corner_radius_top_left=14; frame.corner_radius_top_right=14; frame.corner_radius_bottom_left=14; frame.corner_radius_bottom_right=14; browser.add_theme_stylebox_override("panel",frame)
	var chrome:=ColorRect.new(); chrome.name="BrowserChrome"; chrome.color=TEAL; chrome.position=Vector2(3,3); chrome.size=Vector2(704,58); browser.add_child(chrome)
	var tab:=Label.new(); tab.text="  Mini Sudoku  ❀"; tab.position=Vector2(22,17); tab.size=Vector2(190,38); tab.add_theme_font_size_override("font_size",18); tab.add_theme_color_override("font_color",Color("#fffaf5")); chrome.add_child(tab)
	var address:=Label.new(); address.text="  cozy.market/games/mini-sudoku"; address.position=Vector2(215,14); address.size=Vector2(390,35); address.add_theme_color_override("font_color",INK)
	var address_bg:=StyleBoxFlat.new(); address_bg.bg_color=SAGE; address_bg.corner_radius_top_left=13; address_bg.corner_radius_top_right=13; address_bg.corner_radius_bottom_left=13; address_bg.corner_radius_bottom_right=13; address.add_theme_stylebox_override("normal",address_bg); chrome.add_child(address)
	var x:=Button.new(); x.name="BrowserCloseButton"; x.text="×"; x.position=Vector2(652,10); x.size=Vector2(40,38); x.add_theme_font_size_override("font_size",24); x.pressed.connect(close); chrome.add_child(x)
	var title:=Label.new(); title.text="MINI SUDOKU"; title.position=Vector2(0,78); title.size=Vector2(710,38); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size",27); title.add_theme_color_override("font_color",INK); browser.add_child(title)
	var subtitle:=Label.new(); subtitle.text="Fill each row, column, and 2 × 3 box with 1–6"; subtitle.position=Vector2(0,114); subtitle.size=Vector2(710,26); subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; subtitle.add_theme_color_override("font_color",TEAL.darkened(.32)); browser.add_child(subtitle)
	var grid:=GridContainer.new(); grid.name="SudokuGrid"; grid.columns=6; grid.position=Vector2(149,154); grid.add_theme_constant_override("h_separation",3); grid.add_theme_constant_override("v_separation",3); browser.add_child(grid)
	for index in 36:
		var cell:=Button.new(); cell.custom_minimum_size=Vector2(66,58); cell.focus_mode=Control.FOCUS_NONE; cell.add_theme_font_size_override("font_size",23); cell.pressed.connect(select_cell.bind(index)); cells.append(cell); grid.add_child(cell)
	var keypad:=HBoxContainer.new(); keypad.position=Vector2(145,527); keypad.add_theme_constant_override("separation",7); browser.add_child(keypad)
	for number in 6:
		var key:=Button.new(); key.text=str(number+1); key.custom_minimum_size=Vector2(49,43); key.pressed.connect(enter_number.bind(number+1)); _style_action(key,BLUSH); keypad.add_child(key)
	var erase:=Button.new(); erase.text="Erase"; erase.custom_minimum_size=Vector2(74,43); erase.pressed.connect(enter_number.bind(0)); _style_action(erase,SAND); keypad.add_child(erase)
	status=Label.new(); status.position=Vector2(42,590); status.size=Vector2(435,42); status.add_theme_font_size_override("font_size",16); status.add_theme_color_override("font_color",INK); browser.add_child(status)
	var new_button:=Button.new(); new_button.name="NewPuzzleButton"; new_button.text="New puzzle"; new_button.position=Vector2(520,584); new_button.size=Vector2(145,43); new_button.pressed.connect(generate_new_puzzle); _style_action(new_button,PEACH); browser.add_child(new_button)
	generate_new_puzzle()

func _style_action(button:Button,color:Color)->void:
	var style:=StyleBoxFlat.new(); style.bg_color=color; style.border_color=TEAL.darkened(.2); style.set_border_width_all(1); style.corner_radius_top_left=8; style.corner_radius_top_right=8; style.corner_radius_bottom_left=8; style.corner_radius_bottom_right=8; button.add_theme_stylebox_override("normal",style); button.add_theme_color_override("font_color",INK)

func _base_solution()->Array[int]:
	var digits:=[1,2,3,4,5,6]; digits.shuffle(); var bands:=[0,1,2]; bands.shuffle(); var stacks:=[0,1]; stacks.shuffle()
	var rows:Array[int]=[]; var columns:Array[int]=[]
	for band in bands:
		var inside:=[0,1]; inside.shuffle()
		for offset in inside: rows.append(band*2+offset)
	for stack in stacks:
		var inside:=[0,1,2]; inside.shuffle()
		for offset in inside: columns.append(stack*3+offset)
	var result:Array[int]=[]
	for row in rows:
		for column in columns: result.append(digits[(row*3+int(row/2)+column)%6])
	return result

func generate_new_puzzle()->void:
	solution=_base_solution(); puzzle.assign(solution)
	var spaces:Array[int]=[]
	for index in 36: spaces.append(index)
	spaces.shuffle()
	for index in spaces:
		if puzzle.count(0)>=18: break
		var saved:=puzzle[index]; puzzle[index]=0; var probe:Array[int]=[]; probe.assign(puzzle)
		if _count_solutions(probe,2)!=1: puzzle[index]=saved
	values.assign(puzzle); selected=-1
	for index in 36:
		cells[index].text="" if puzzle[index]==0 else str(puzzle[index]); cells[index].disabled=puzzle[index]>0; _style_cell(index)
	status.text="New puzzle ready. Choose an empty square."; status.add_theme_color_override("font_color",INK)

func _count_solutions(board:Array[int],limit:int)->int:
	var empty:=board.find(0)
	if empty<0: return 1
	var total:=0
	for number in range(1,7):
		if _valid_at(board,empty,number):
			board[empty]=number; total+=_count_solutions(board,limit-total); board[empty]=0
			if total>=limit: return total
	return total

func _valid_at(board:Array[int],index:int,number:int)->bool:
	var row:=int(index/6); var column:=index%6
	for offset in 6:
		if board[row*6+offset]==number or board[offset*6+column]==number: return false
	var box_row:=int(row/2)*2; var box_column:=int(column/3)*3
	for yy in 2:
		for xx in 3:
			if board[(box_row+yy)*6+box_column+xx]==number: return false
	return true

func _style_cell(index:int)->void:
	var base_color:=SAGE if puzzle[index]>0 else (BLUSH if (int(index/3)+int(index/12))%2==0 else Color("#fffaf5"))
	var box:=StyleBoxFlat.new(); box.bg_color=base_color.darkened(.16) if index==selected else base_color; box.border_color=TEAL.darkened(.28)
	box.border_width_left=3 if index%6 in [0,3] else 1; box.border_width_top=3 if int(index/6) in [0,2,4] else 1; box.border_width_right=3 if index%6==5 else 1; box.border_width_bottom=3 if int(index/6)==5 else 1
	cells[index].add_theme_stylebox_override("normal",box); cells[index].add_theme_stylebox_override("disabled",box); cells[index].add_theme_color_override("font_disabled_color",INK.darkened(.18)); cells[index].add_theme_color_override("font_color",TEAL.darkened(.35))

func select_cell(index:int)->void:
	if puzzle[index]>0: return
	var previous:=selected
	selected=index
	if previous>=0: _style_cell(previous)
	_style_cell(selected)
	status.text="Selected row %d, column %d" % [int(index/6)+1,index%6+1]

func enter_number(number:int)->void:
	if selected<0: status.text="Choose an empty square first."; return
	values[selected]=number; cells[selected].text="" if number==0 else str(number)
	if number>0 and number!=solution[selected]: status.text="That number conflicts with the puzzle. Try another."; cells[selected].add_theme_color_override("font_color",Color("#a65f61"))
	else: cells[selected].add_theme_color_override("font_color",TEAL.darkened(.35)); status.text="Good placement." if number>0 else "Square cleared."
	if values==solution: status.text="Puzzle complete! The market bells chime for you. ❀"; status.add_theme_color_override("font_color",TEAL.darkened(.4))

func reset_board()->void:
	var previous:=selected
	values.assign(puzzle); selected=-1
	for index in 36: cells[index].text="" if puzzle[index]==0 else str(puzzle[index])
	if previous>=0: _style_cell(previous)
	status.text="Puzzle reset. Choose an empty square."

func close()->void:
	dismissed.emit(); queue_free()
