extends Node

enum player {A, B, C, D}

onready var board_viewport := find_node("board_viewport") as Viewport
onready var test_pos := find_node("test_pos") as Control
onready var test_pos_label := find_node("test_pos_label") as Label
onready var board := find_node("board") as Spatial
onready var camera := find_node("camera") as Camera
onready var test_left_button := find_node("test_left_button") as Button
onready var test_right_button := find_node("test_right_button") as Button
onready var test_idx_label := find_node("test_idx_label")
onready var factory := find_node("factory") as Node
onready var world := find_node("world") as Spatial
onready var selector := find_node("selector") as Node2D

onready var current_arr := board.main_track_indices as Array

var current_idx := 0
var selected_idx := 0

func _ready():
	test_left_button.connect("pressed", self, "_on_test_button_pressed", [0])
	test_right_button.connect("pressed", self, "_on_test_button_pressed", [1])
	
	board.connect_areas("input_event", self, "_on_area_clicked")
	
	setup_marbles()
	
	yield(get_tree(), "idle_frame")
	update_test_pos()

func _on_test_button_pressed(id):
	var idx := current_idx
	if id > 0:
		idx = current_idx + 1
		if idx >= len(current_arr):
			idx = 0
	else:
		idx = current_idx - 1
		if idx < 0:
			idx = len(current_arr) - 1
	current_idx = idx
	test_idx_label.text = "%d" % current_idx
	update_test_pos()

func update_test_pos():
	var pos := camera.unproject_position(board.all_positions[current_arr[current_idx]])
	var sel_pos := camera.unproject_position(board.all_positions[selected_idx])
	
	test_pos.rect_position = pos
	test_pos_label.text = "%d,%d" % [test_pos.rect_position.x, test_pos.rect_position.y]
	
	selector.position = sel_pos

func setup_marbles():
	for i in range(4):
		var home_indices := [board.a_home_indices, board.b_home_indices, board.c_home_indices, board.d_home_indices]
		var color := [factory.marble_color.RED, factory.marble_color.BLUE, factory.marble_color.GREEN, factory.marble_color.YELLOW]
		for idx in home_indices[i]:
			var p := board.all_positions[idx] as Vector3
			var new_marble := factory.marble(color[i]) as Spatial
			new_marble.translate(p)
			world.add_child(new_marble)

func _on_area_clicked(camera, event, click_position, click_normal, shape_idx, idx):
	print("Clicked: %d" % idx)
	pass
