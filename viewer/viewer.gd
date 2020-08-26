extends Node
class_name Viewer

# Enumerations
enum select_state_type{NONE, SLCT}

# Types
const Board := preload("res://board/board.gd")
const Highlight := preload("res://viewer/select_highlight.tscn")
const MAX_HIGHLIGHTS := 5

# Constants
const dice_images := [
	preload("res://viewer/dice/dice_0.svg"),
	preload("res://viewer/dice/dice_1.svg"),
	preload("res://viewer/dice/dice_2.svg"),
	preload("res://viewer/dice/dice_3.svg"),
	preload("res://viewer/dice/dice_4.svg"),
	preload("res://viewer/dice/dice_5.svg"),
	preload("res://viewer/dice/dice_6.svg"),
]

# Nodes
onready var board_viewport := find_node("board_viewport") as Viewport
onready var board := find_node("board") as Board
onready var camera := find_node("camera") as Camera
onready var test_idx_label := find_node("test_idx_label")
onready var world := find_node("world") as Spatial
onready var selector := find_node("selector") as Node2D
onready var selector_highlight := find_node("selector_highlight") as Node2D
onready var pass_own_position_checkbox := find_node("pass_own_position_checkbox") as CheckBox
onready var idx_label := find_node("idx_label") as Label
onready var valid_move_highlights := find_node("valid_move_highlights") as Node2D
onready var roll_dice_button := find_node("roll_dice_button") as Button
onready var pass_button := find_node("pass_button") as Button
onready var dice_texturerect := find_node("dice_texturerect") as TextureRect
onready var player_status_list := find_node("player_status_list") as Container

# Members
var select_state:int = select_state_type.NONE
var select_index := -1
var valid_moves := []
var state := GameState.new()

func _ready():
	randomize()
	# Temporary dice buttons
	for i in range(6):
		var dice_val := i + 1
		var b := find_node("dice_button%d" % dice_val) as Button
		b.connect("pressed", self, "_on_dice_button_pressed", [dice_val])
	
	# Creat valid move highlights
	for _i in range(MAX_HIGHLIGHTS):
		var new_h := Highlight.instance() as Node2D
		new_h.visible = false
		new_h.scale = Vector2(0.7, 0.7)
		new_h.self_modulate = Color.green
		valid_move_highlights.add_child(new_h)
	
	# Connect Controls
	roll_dice_button.connect("pressed", self, "_on_roll_dice_button_pressed")
	pass_button.connect("pressed", self, "_on_pass_button_pressed")
	pass_own_position_checkbox.connect("toggled", self, "_on_pass_own_position_marbles_toggled")
	
	# Connect board controls
	board.connect_areas("input_event", self, "_on_area_clicked")
	board.connect_areas("mouse_entered", self, "_on_area_entered")
	board.connect_areas("mouse_exited", self, "_on_area_exited")
	board.connect_bounds("input_event", self, "_on_bounds_clicked")
	
	update_selectors()

func _on_pass_own_position_marbles_toggled(pressed:bool):
	Logic.pass_own_position_marbles = pressed

func update_ui(game_state:GameState):
	deselect()
	state.set_from(game_state)
	
	assert(state.dice_value >= 0 and state.dice_value <= 6)
	dice_texturerect.texture = dice_images[state.dice_value]
	
	var this_players_turn := (Connection.get_player() == state.player_turn) as bool
	if this_players_turn:
		roll_dice_button.disabled = state.player_has_rolled
		pass_button.disabled = false
	else:
		roll_dice_button.disabled = true
		pass_button.disabled = true
	
	var colors := []
	for i in range(Logic.player.COUNT):
		colors.append((game_state.custom_clients[i] as CustomClientInfo).color)
	board.set_player_colors(colors)
	
	set_board_state(game_state.board)
	update_selectors()

func update_selectors():
	match select_state:
		select_state_type.NONE:
			selector.visible = false
			selector_highlight.visible = false
			for c in valid_move_highlights.get_children():
				(c as Node2D).visible = false
			if state.player_has_rolled:
				update_valid_move_highlights(state.board.marbles[state.player_turn])
		
		select_state_type.SLCT:
			selector.visible = true
			var sel_pos := camera.unproject_position(board.all_positions[select_index])
			selector.position = sel_pos
			update_valid_move_highlights(valid_moves)

func update_valid_move_highlights(valid_moves_in:Array):
	for i in range(valid_move_highlights.get_child_count()):
		var highlight := (valid_move_highlights.get_child(i) as Node2D)
		if i < len(valid_moves_in):
			highlight.visible = true
			highlight.position = camera.unproject_position(board.all_positions[valid_moves_in[i]])
		else:
			highlight.visible = false

func _on_area_entered(idx:int):
	if can_select(idx):
		selector_highlight.visible = true
		selector_highlight.position = camera.unproject_position(board.all_positions[idx])
		idx_label.text = str(idx)
		if not idx in valid_moves:
			update_valid_move_highlights(Logic.calc_valid_movements(state.board, state.dice_value, Connection.get_player(), idx))

func _on_area_exited(_idx:int):
	selector_highlight.visible = false
	update_selectors()

func _on_area_clicked(_camera, event, _click_position, _click_normal, _shape_idx, idx):
	if event is InputEventMouseButton:
		var e := (event as InputEventMouseButton)
		if e.button_index == BUTTON_LEFT:
			if e.pressed:
				idx_pressed(idx)
				update_selectors()
	_on_area_entered(idx)

func _on_bounds_clicked(_camera, event, _click_position, _click_normal, _shape_idx):
	if event is InputEventMouseButton:
		var e := (event as InputEventMouseButton)
		if e.button_index == BUTTON_LEFT:
			if e.pressed:
				idx_pressed(-1)
				update_selectors()

func _on_dice_button_pressed(dice_value_in:int):
	Connection.server.send_player_roll_result(dice_value_in)
	if select_state == select_state_type.SLCT:
		select(select_index)
	else:
		deselect()

func _on_roll_dice_button_pressed():
	Connection.client.send_player_roll_request()

func _on_pass_button_pressed()->void:
	Connection.client.send_player_pass_request()

func _on_client_send_button_pressed() -> void:
	Connection.client.send_command_print_text()

# Control Interaction
func set_board_state(board_state_in:BoardState):
	state.board.set_from(board_state_in)
	board.set_board_state(state.board)

func deselect():
	select_index = -1
	select_state = select_state_type.NONE
	valid_moves.clear()
	update_selectors()

func select(idx:int):
	select_index = idx
	select_state = select_state_type.SLCT
	valid_moves = Logic.calc_valid_movements(state.board, state.dice_value, Connection.get_player(), idx)
	update_selectors()

func can_select(idx:int)->bool:
	var ret := (idx in state.board.marbles[Connection.get_player()]) as bool
	match select_state:
		select_state_type.NONE:
			ret = ret and state.player_has_rolled
		select_state_type.SLCT:
			ret = ret or (idx in valid_moves)
	return ret

func idx_pressed(idx:int):
	if idx == -1:
		deselect()
	else:
		match select_state:
			select_state_type.NONE:
				if can_select(idx):
					select(idx)
			select_state_type.SLCT:
				if idx == select_index:
					deselect()
				elif idx in valid_moves:
					Connection.client.send_player_move_request(select_index, idx)
					deselect()
				elif idx in state.board.marbles[Connection.get_player()]:
					select(idx)
				else:
					deselect()


















