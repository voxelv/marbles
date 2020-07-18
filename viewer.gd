extends Node

const Board := preload("res://board.gd")

onready var board_viewport := find_node("board_viewport") as Viewport
onready var board := find_node("board") as Board
onready var camera := find_node("camera") as Camera
onready var test_idx_label := find_node("test_idx_label")
onready var world := find_node("world") as Spatial
onready var selector := find_node("selector") as Node2D
onready var selector_highlight := find_node("selector_highlight") as Node2D
onready var idx_readout_label := find_node("idx_readout_label") as Label

func _ready():
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
			idx_readout_label.text = "%d" % Logic.select_index

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
				match Logic.select_state:
					Logic.select_state_type.NONE:
						Logic.select_index = idx
						Logic.select_state = Logic.select_state_type.SLCT
					Logic.select_state_type.SLCT:
						Logic.select_index = -1
						Logic.select_state = Logic.select_state_type.NONE
				update_selector()
