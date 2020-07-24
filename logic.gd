extends Node

enum player{A, B, C, D, COUNT}
enum select_state_type{NONE, SLCT}

const Viewer := preload("res://viewer.gd")
const DAGNode := preload("res://dag/dag_node.gd")
const NUM_MARBLES_PER_PLAYER := 5

var dag := []

var main_track_indices := range(21, 21+48)

var a_home_row_indices := range(1, 6)
var b_home_row_indices := range(6, 11)
var c_home_row_indices := range(11, 16)
var d_home_row_indices := range(16, 21)
var home_row_indices := [a_home_row_indices, b_home_row_indices, c_home_row_indices, d_home_row_indices]

var a_track_indices := range(21, 21+48) + a_home_row_indices
var b_track_indices := range(21+12, 21+48) + range(21, 21+12) + b_home_row_indices
var c_track_indices := range(21+24, 21+48) + range(21, 21+24) + c_home_row_indices
var d_track_indices := range(21+36, 21+48) + range(21, 21+36) + d_home_row_indices
var track_indices := [a_track_indices, b_track_indices, c_track_indices, d_track_indices]

var a_home_indices := range(21+48, 21+48+5)
var b_home_indices := range(21+48+5, 21+48+10)
var c_home_indices := range(21+48+10, 21+48+15)
var d_home_indices := range(21+48+15, 21+48+20)
var home_indices := [a_home_indices, b_home_indices, c_home_indices, d_home_indices]

var position_indices := [26, 26+12, 26+24, 26+36]

var viewer:Viewer
var select_state:int = select_state_type.NONE
var select_index := -1
var current_player = player.A
var dice_value := 1 setget _set_dice_value
var valid_moves := []
var pass_own_position_marbles := true
var marbles := [
	[-1, -1, -1, -1, -1],
	[-1, -1, -1, -1, -1],
	[-1, -1, -1, -1, -1],
	[-1, -1, -1, -1, -1],
	]

func _ready():
	call_deferred("setup_dag")

func _set_dice_value(value:int):
	dice_value = value
	valid_moves = valid_movements(current_player)

func setup_dag():
	for i in range(len(viewer.board.all_positions)):
		dag.append(DAGNode.new(i))
	
	# Main Track
	for i in range(len(main_track_indices)):
		if i == len(main_track_indices) - 1:
			(dag[main_track_indices[i]] as DAGNode).next_main_track_node = dag[main_track_indices[0]]
		else:
			(dag[main_track_indices[i]] as DAGNode).next_main_track_node = dag[main_track_indices[i+1]]
	
	# Positions to Positions
	for i in range(len(position_indices)):
		if i == len(position_indices) - 1:
			(dag[position_indices[i]] as DAGNode).next_position_node = dag[position_indices[0]]
		else:
			(dag[position_indices[i]] as DAGNode).next_position_node = dag[position_indices[i+1]]
	
	# Positions to Center
	for i in range(len(position_indices)):
		(dag[position_indices[i]] as DAGNode).next_center_node = dag[0]
	
	# Home Rows
	for p in range(len(home_row_indices)):
		var h_indices = home_row_indices[p]
		for i in range(len(h_indices)):
			(dag[h_indices[i]] as DAGNode).home_row_owner = p
			if i == len(h_indices) - 1:
				# Last home row node has nowhere to go, so use the slot to set the entering edge
				(dag[track_indices[p][-6]] as DAGNode).next_home_row_node = dag[h_indices[0]]
			else:
				(dag[h_indices[i]] as DAGNode).next_home_row_node = dag[h_indices[i+1]]

func set_viewer(v:Viewer):
	self.viewer = v

func player_can_select(player:int, idx:int)->bool:
	var ret := false
	match select_state:
		select_state_type.NONE:
			ret = (idx in marbles[player])
		select_state_type.SLCT:
			ret = (idx in valid_moves)
	return ret

func set_player_marble_idx(player:int, marble:int, idx:int):
	marbles[player][marble] = idx
	
	yield(get_tree(), "idle_frame")
	viewer.board.set_board_state(marbles)

func get_idx_info(idx:int)->Dictionary:
	var ret := {}
	var player := -1
	var marble := -1
	var found := false
	
	for p in player:
		for m in range(NUM_MARBLES_PER_PLAYER):
			if marbles[p][m] == idx:
				found = true
				player = p
				marble = m
	
	if found:
		ret['player'] = player
		ret['marble'] = marble
	
	return ret

func marble_is_at_home(player:int)->bool:
	return (select_index in home_indices[player])

func selected_marble()->int:
	return marbles[current_player].find(select_index)

func index_in_player_track(idx:int)->int:
	return track_indices[current_player].find(idx)

func valid_movements(player:int)->Array:
	var ret := []
	var idx := select_index
	
	var marble := selected_marble()
	
	# Find all movements, regardless of contents
	var possible_moves := []
	
	possible_moves += _movements_recurser(dice_value, marbles[current_player][marble], [marbles[current_player][marble]])
	
	ret += possible_moves
	
	return ret

func _movements_recurser(dice_value_in:int, from_idx:int, path_here:Array)->Array:
	var ret := []
	
	if from_idx in home_indices[current_player] and dice_value_in in [1, 6] and not track_indices[current_player][0] in marbles[current_player]:
		ret.append(track_indices[current_player][0])
	
	if dice_value_in == 1:
		var node := (dag[from_idx] as DAGNode)
		var ending_indices := []
		if node.next_main_track_node != null:
			ending_indices.append(node.next_main_track_node.idx)
		if node.next_position_node != null and select_index in position_indices:
			ending_indices.append(node.next_position_node.idx)
		if node.next_center_node != null:
			if dice_value == 1 and select_index in position_indices:
				ending_indices.append(node.next_center_node.idx)
			elif dice_value != 1 and not select_index in position_indices:
				ending_indices.append(node.next_center_node.idx)
		if node.next_home_row_node != null and node.next_home_row_node.home_row_owner == current_player:
			ending_indices.append(node.next_home_row_node.idx)
		if from_idx == 0 and dice_value == 1:
			for i in range(len(position_indices)):
				ending_indices.append(position_indices[i])
		for idx in ending_indices:
			if not idx in marbles[current_player]:
				print("%d: %s" % [idx, str(path_here)])
				ret.append(idx)
	else:
		assert(dice_value_in in [2, 3, 4, 5, 6])
		var node := (dag[from_idx] as DAGNode)
		var recurse_indices := []
		if node.next_main_track_node != null:
			recurse_indices.append(node.next_main_track_node.idx)
		if node.next_position_node != null and select_index in position_indices:
			recurse_indices.append(node.next_position_node.idx)
		if node.next_center_node != null:
			recurse_indices.append(node.next_center_node.idx)
		if node.next_home_row_node != null and node.next_home_row_node.home_row_owner == current_player:
			recurse_indices.append(node.next_home_row_node.idx)
		
		for idx in recurse_indices:
			if (not idx in path_here 
				and (not idx in marbles[current_player] 
					or (idx in position_indices 
						and pass_own_position_marbles
						)
					)
				):
				var path = path_here.duplicate()
				path.append(idx)
				ret += _movements_recurser(dice_value_in - 1, idx, path)
	
	return ret

func idx_pressed(idx:int):
	if true:
		var node := (dag[idx] as DAGNode)
		var next_nodes := []
		var s := "%d -> " % node.idx
		if node.next_main_track_node != null:
			s += "T%d "% (node.next_main_track_node as DAGNode).idx
		if node.next_position_node != null:
			s += "P%d "% (node.next_position_node as DAGNode).idx
		if node.next_center_node != null:
			s += "C%d "% (node.next_center_node as DAGNode).idx
		if node.next_home_row_node != null:
			s += "H%d "% (node.next_home_row_node as DAGNode).idx
		if node.home_row_owner != Logic.player.COUNT:
			s += "owner: %d" % node.home_row_owner
		print(s)
	
	match select_state:
		select_state_type.NONE:
			if player_can_select(current_player, idx):
				select_index = idx
				select_state = select_state_type.SLCT
				valid_moves = valid_movements(current_player)
		select_state_type.SLCT:
			if idx in valid_moves:
				set_player_marble_idx(current_player, selected_marble(), idx)
			select_index = -1
			select_state = select_state_type.NONE
			valid_moves.clear()

func generate_graph():
	
	pass













