extends Spatial

onready var main_track_section := find_node("main_track_section")
onready var marbles_container := find_node("marbles_container")

var all_positions := []
var all_areas := []

# 4 arrays: player n's 5 marbles indexes for n = 0, 1, 2, 3
# corresponding to player a, b, c, d
var _marbles := []
var marbles_indices := []

var _tmp_array := []

func _ready() -> void:
	_positions_recurse(self)
	all_positions = _tmp_array.duplicate(true)
	_tmp_array.clear()
	
	_clickables_recurse(self)
	all_areas = _tmp_array.duplicate(true)
	_tmp_array.clear()
	
	setup_marbles()

func _positions_recurse(node:Node)->void:
	for N in node.get_children():
		if N.name == "positions":
			_get_positions(N)
		elif N.get_child_count() > 0:
			_positions_recurse(N)

func _get_positions(node:Node)->void:
	for c in node.get_children():
		_tmp_array.append(c.to_global(Vector3.ZERO))

func _clickables_recurse(node:Node)->void:
	for N in node.get_children():
		if N.name == "clickables":
			_get_clickables(N)
		elif N.get_child_count() > 0:
			_clickables_recurse(N)

func _get_clickables(node:Node)->void:
	for c in node.get_children():
		_tmp_array.append(c)

func connect_areas(signal_name:String, node:Node, function_name:String):
	var any_err := false
	var err := OK
	for i in range(len(all_areas)):
		err = (all_areas[i] as Area).connect(signal_name, node, function_name, [i])
		any_err = (err != OK)
	if any_err:
		print("Could not connect signal: %s to node: %s function: %s last err: %d" % [signal_name, node, function_name, err])

func _on_mouse_entered(idx:int)->void:
	print("Entered %d" % idx)

func setup_marbles():
	for i in range(4):
		_marbles.append([]) # append an empty array
		marbles_indices.append([]) # append an empty array
		var home_indices := [
			Logic.a_home_indices, 
			Logic.b_home_indices, 
			Logic.c_home_indices, 
			Logic.d_home_indices
			]
		var color := [Factory.marble_color.RED, Factory.marble_color.BLUE, Factory.marble_color.GREEN, Factory.marble_color.YELLOW]
		for idx in home_indices[i]:
			var p := all_positions[idx] as Vector3
			var new_marble := Factory.marble(color[i]) as Spatial
			new_marble.translate(p)
			self.add_child(new_marble)
			_marbles[i].append(new_marble)
			marbles_indices[i].append(idx)

func set_board_state(marbles_in):
	assert(len(marbles_in) == 4)
	for player in range(len(marbles_in)):
		assert(marbles_in[player] is Array)
		assert(len(marbles_in[player]) == 5)
		for marble in range(len(marbles_in[player])):
			assert(marbles_in[player][marble] is int)
			(_marbles[player][marble] as Spatial).translation = all_positions[marbles_in[player][marble]]
			marbles_indices[player][marble] = marbles_in[player][marble]

func get_board_state():
	return marbles_indices.duplicate(true)















