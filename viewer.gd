extends Node

const Board := preload("res://board.gd")
const Highlight := preload("res://select_highlight.tscn")
const MAX_HIGHLIGHTS := 4

const dice_images := []

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
onready var dice_texturerect := find_node("dice_texturerect") as TextureRect

func _ready():
	# Temporary dice buttons
	for i in range(6):
		var dice_val := i + 1
		var b := find_node("dice_button%d" % dice_val) as Button
		b.connect("pressed", self, "_on_dice_button_pressed", [dice_val])
	
	dice_images.append(null)
	for i in range(6):
		var new_tex := load("res://dice/dice_%d.png" % (i+1)) as StreamTexture
		dice_images.append(new_tex)
	
	# Creat valid move highlights
	for i in range(MAX_HIGHLIGHTS):
		var new_h := Highlight.instance() as Node2D
		new_h.visible = false
		new_h.scale = Vector2(0.7, 0.7)
		new_h.self_modulate = Color.green
		valid_move_highlights.add_child(new_h)
	
	# Connect Controls
	roll_dice_button.connect("pressed", self, "_on_roll_dice_button_pressed")
	pass_own_position_checkbox.connect("toggled", self, "_on_pass_own_position_marbles_toggled")
	
	Logic.set_viewer(self)
	
	# Connect board controls
	board.connect_areas("input_event", self, "_on_area_clicked")
	board.connect_areas("mouse_entered", self, "_on_area_entered")
	board.connect_areas("mouse_exited", self, "_on_area_exited")
	board.connect_bounds("input_event", self, "_on_bounds_clicked")
	
	update_selector()

func _on_pass_own_position_marbles_toggled(pressed:bool):
	Logic.pass_own_position_marbles = pressed

func update_selector():
	match Logic.select_state:
		Logic.select_state_type.NONE:
			selector.visible = false
			for c in valid_move_highlights.get_children():
				(c as Node2D).visible = false
		
		Logic.select_state_type.SLCT:
			selector.visible = true
			var sel_pos := camera.unproject_position(board.all_positions[Logic.select_index])
			selector.position = sel_pos
			update_valid_move_highlights(Logic.valid_moves)

func update_valid_move_highlights(valid_moves:Array):
	for i in range(valid_move_highlights.get_child_count()):
		var highlight := (valid_move_highlights.get_child(i) as Node2D)
		if i < len(valid_moves):
			highlight.visible = true
			highlight.position = camera.unproject_position(board.all_positions[valid_moves[i]])
		else:
			highlight.visible = false

func _on_area_entered(idx:int):
	if Logic.player_can_select(Logic.player.A, idx):
		selector_highlight.visible = true
		var sel_pos := camera.unproject_position(board.all_positions[idx])
		selector_highlight.position = sel_pos
		idx_label.text = str(idx)
		update_valid_move_highlights(Logic.calc_valid_movements(Logic.player.A, idx))

func _on_area_exited(_idx:int):
	selector_highlight.visible = false
	update_selector()

func _on_area_clicked(_camera, event, _click_position, _click_normal, _shape_idx, idx):
	if event is InputEventMouseButton:
		var e := (event as InputEventMouseButton)
		if e.button_index == BUTTON_LEFT:
			if e.pressed:
				Logic.idx_pressed(idx)
				update_selector()

func _on_bounds_clicked(_camera, event, _click_position, _click_normal, _shape_idx):
	if event is InputEventMouseButton:
		var e := (event as InputEventMouseButton)
		if e.button_index == BUTTON_LEFT:
			if e.pressed:
				Logic.idx_pressed(-1)
				update_selector()

func _on_dice_button_pressed(dice_val:int):
	Logic.dice_value = dice_val
	update_selector()

func _on_roll_dice_button_pressed():
	var new_val = range(6)[randi() % 6] + 1
	Logic.dice_value = new_val
	dice_texturerect.texture = dice_images[new_val]
	update_selector()
