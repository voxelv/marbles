extends Node

const Board := preload("res://board.gd")

onready var board_viewport := find_node("board_viewport") as Viewport
onready var board := find_node("board") as Board
onready var camera := find_node("camera") as Camera
onready var test_idx_label := find_node("test_idx_label")
onready var world := find_node("world") as Spatial
onready var selector := find_node("selector") as Node2D
onready var selector_highlight := find_node("selector_highlight") as Node2D

func _ready():
	# Temporary dice buttons
	for i in range(6):
		var dice_val := i + 1
		var b := find_node("dice_button%d" % dice_val) as Button
		b.connect("pressed", self, "_on_dice_button_pressed", [dice_val])
	
	Logic.set_viewer(self)
	board.connect_areas("input_event", self, "_on_area_clicked")
	board.connect_areas("mouse_entered", self, "_on_area_entered")
	board.connect_areas("mouse_exited", self, "_on_area_exited")
	
	update_selector()

func update_selector():
	match Logic.select_state:
		Logic.select_state_type.NONE:
			selector.visible = false
		
		Logic.select_state_type.SLCT:
			selector.visible = true
			var sel_pos := camera.unproject_position(board.all_positions[Logic.select_index])
			selector.position = sel_pos

func _on_area_entered(idx:int):
	if Logic.player_can_select(Logic.player.A, idx):
		selector_highlight.visible = true
		var sel_pos := camera.unproject_position(board.all_positions[idx])
		selector_highlight.position = sel_pos

func _on_area_exited(_idx:int):
	selector_highlight.visible = false
	pass

func _on_area_clicked(_camera, event, _click_position, _click_normal, _shape_idx, idx):
	if event is InputEventMouseButton:
		var e := (event as InputEventMouseButton)
		if e.button_index == BUTTON_LEFT:
			if e.pressed:
				Logic.idx_pressed(idx)
				update_selector()

func _on_dice_button_pressed(dice_val:int):
	Logic.dice_value = dice_val
