extends Node3D
class_name Board

enum marble_color {A, B, C, D, COUNT}
var main_track_section :Node3D
var marbles_container :Node3D
var bounds :Node3D
var player_markers :Node3D

var all_positions := []
var all_areas := []
var player_marker_materials := []

const marble_preload = preload("res://board/marble.tscn")
const materials = [
	preload("res://board/player_materials/A.tres"),
	preload("res://board/player_materials/B.tres"),
	preload("res://board/player_materials/C.tres"),
	preload("res://board/player_materials/D.tres")
]

# 4 arrays: player n's 5 marbles indices for n = 0, 1, 2, 3
# corresponding to player a, b, c, d
var _marbles := []

var _tmp_array := []

func _ready() -> void:
	main_track_section = get_node("interaction_board/main_track_section")
	marbles_container = get_node("marbles_container")
	bounds = get_node("bounds")
	player_markers = get_node("player_markers")
	
	_positions_recurse(self)
	all_positions = _tmp_array.duplicate(true)
	_tmp_array.clear()
	
	_clickables_recurse(self)
	all_areas = _tmp_array.duplicate(true)
	_tmp_array.clear()
	
	for i in range(len(player_markers.get_children())):
		var mat := (player_markers.get_child(i) as MeshInstance3D).get_surface_override_material(0)
		player_marker_materials.append(mat)
	
	_setup_board_materials()
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
		err = (all_areas[i] as Area3D).connect(signal_name, Callable(node, function_name), [i])
		any_err = (err != OK)
	if any_err:
		print("Could not connect signal: %s to node: %s function: %s last err: %d" % [signal_name, node, function_name, err])

func connect_bounds(signal_name:String, node:Node, function_name:String):
	for c in bounds.get_children():
		c.connect(signal_name, Callable(node, function_name))

func _on_mouse_entered(idx:int)->void:
	print("Entered %d" % idx)

func _setup_board_materials():
	for key in Palette.board_colors.keys():
		if key == 'center':
			var mi := Omni.find_node(self, key) as MeshInstance3D
			var sm = mi.get_surface_override_material(0) as Material
			sm.albedo_color = Palette.board_colors[key]
		elif key == 'edge':
			for sub_edge_key in ['home_entrance', 'pokey_hole', 'home']:
				var mi := Omni.find_node(self, '%s_edge' % sub_edge_key) as MeshInstance3D
				var sm = mi.get_surface_override_material(0) as Material
				sm.albedo_color = Palette.board_colors[key]
		elif key == '5_run':
			var mi := Omni.find_node(self, 'a_%s_1' % key) as MeshInstance3D
			var sm = mi.get_surface_override_material(0) as Material
			sm.albedo_color = Palette.board_colors[key]
		else:
			var mi := Omni.find_node(self, 'a_%s' % key) as MeshInstance3D
			var sm = mi.get_surface_override_material(0) as Material
			sm.albedo_color = Palette.board_colors[key]

func setup_marbles():
	for p in range(4):
		_marbles.append([]) # append an empty array
		var color := [marble_color.A, marble_color.B, marble_color.C, marble_color.D]
		for _m in range(len(Logic.home_indices[p])):
			var new_marble := make_marble(color[p]) as Node3D
			marbles_container.add_child(new_marble)
			new_marble.visible = false
			_marbles[p].append(new_marble)

func make_marble(color:int)->Node3D:
	assert(color >= 0 and color < marble_color.COUNT)
	var new_marble = marble_preload.instantiate()
	var mesh_instance = Omni.find_node(new_marble, "MeshInstance")
	mesh_instance.mesh = mesh_instance.mesh.duplicate()
	mesh_instance.mesh.material = materials[color]
	return new_marble

func set_board_state(board_state:BoardState):
	var marbles_in = board_state.marbles
	assert(len(marbles_in) == 4)
	for player in range(len(marbles_in)):
		assert(marbles_in[player] is Array)
		assert(len(marbles_in[player]) == 5)
		for marble in range(len(marbles_in[player])):
			assert(marbles_in[player][marble] is int)
			(_marbles[player][marble] as Node3D).visible = true
			(_marbles[player][marble] as Node3D).translation = all_positions[marbles_in[player][marble]]

func set_player_colors(colors:Array):
	assert(len(colors) == 4)
	for i in range(len(colors)):
		(player_marker_materials[i] as Material).albedo_color = colors[i]

func show_marbles(show:bool):
	marbles_container.visible = show










