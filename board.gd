extends Spatial

onready var main_track_section := find_node("main_track_section")

var all_positions := []
var all_areas := []

var main_track_indices := []
var a_track_indices := []
var b_track_indices := []
var c_track_indices := []
var d_track_indices := []

var a_home_indices := []
var b_home_indices := []
var c_home_indices := []
var d_home_indices := []

var _tmp_array := []

func _ready() -> void:
	_positions_recurse(self)
	all_positions = _tmp_array.duplicate(true)
	_tmp_array.clear()
	
	_clickables_recurse(self)
	all_areas = _tmp_array.duplicate(true)
	_tmp_array.clear()
	
	main_track_indices = range(21, 21+48)
	
	a_track_indices += range(21, 21+48)
	a_track_indices += range(1, 6)
	
	b_track_indices += range(21+12, 21+48)
	b_track_indices += range(21, 21+12)
	b_track_indices += range(6, 11)
	
	c_track_indices += range(21+24, 21+48)
	c_track_indices += range(21, 21+24)
	c_track_indices += range(11, 16)
	
	d_track_indices += range(21+36, 21+48)
	d_track_indices += range(21, 21+36)
	d_track_indices += range(16, 21)
	
	a_home_indices += range(21+48, 21+48+5)
	b_home_indices += range(21+48+5, 21+48+10)
	c_home_indices += range(21+48+10, 21+48+15)
	d_home_indices += range(21+48+15, 21+48+20)

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

func get_all_clickables()->Dictionary:
	var ret := {}
	
	var sections := [
		"center",
		"a_home_row", "b_home_row", "c_home_row", "d_home_row",
		"a_pokey", "b_pokey", "c_pokey", "d_pokey",
		"a_runs", "b_runs", "c_runs", "d_runs",
		"a_home_entrance", "b_home_entrance", "c_home_entrance", "d_home_entrance",
		"a_home", "b_home", "c_home", "d_home"
	]
	
	for section in sections:
		_clickables_recurse(find_node(section))
		ret[section] = _tmp_array.duplicate(true)
		_tmp_array.clear()
	
	return ret

func connect_areas(signal_name:String, node:Node, function_name:String):
	for i in range(len(all_areas)):
		(all_areas[i] as Area).connect(signal_name, node, function_name, [i])

func _on_mouse_entered(idx:int)->void:
	print("Entered %d" % idx)
