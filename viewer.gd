extends Node

onready var board_viewport := find_node("board_viewport") as Viewport
onready var test_pos := find_node("test_pos") as Control
onready var test_pos_label := find_node("test_pos_label") as Label
onready var board := find_node("board") as Spatial
onready var camera := find_node("camera") as Camera
onready var test_left_button := find_node("test_left_button") as Button
onready var test_right_button := find_node("test_right_button") as Button

var current_idx := 0

func _ready():
	test_left_button.connect("pressed", self, "_on_test_button_pressed", [0])
	test_right_button.connect("pressed", self, "_on_test_button_pressed", [1])
	
	yield(get_tree(), "idle_frame")
	update_test_pos()

func _on_test_button_pressed(id):
	var idx := current_idx
	if id > 0:
		idx = current_idx + 1
		if idx >= len(board.positions):
			idx = 0
	else:
		idx = current_idx - 1
		if idx < 0:
			idx = len(board.positions) - 1
	current_idx = idx
	update_test_pos()

func update_test_pos():
	test_pos.rect_position = camera.unproject_position((board.positions[current_idx] as Spatial).to_global(Vector3.ZERO))
	test_pos_label.text = "%d,%d" % [test_pos.rect_position.x, test_pos.rect_position.y]

func _on_Timer_timeout():
	pass # Replace with function body.
