extends Node

enum game_phase {INIT, STARTED, COUNT}
enum player{A, B, C, D, COUNT}

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

var all_indices := (
	[0] 
	+ a_home_row_indices
	+ b_home_row_indices
	+ c_home_row_indices
	+ d_home_row_indices
	+ main_track_indices
	+ a_home_indices 
	+ b_home_indices 
	+ c_home_indices 
	+ d_home_indices
	)

var a_position_indices := position_indices
var b_position_indices := [position_indices[1], position_indices[2], position_indices[3], position_indices[0]]
var c_position_indices := [position_indices[2], position_indices[3], position_indices[0], position_indices[1]]
var d_position_indices := [position_indices[3], position_indices[0], position_indices[1], position_indices[2]]

var player_position_indices := [a_position_indices, b_position_indices, c_position_indices, d_position_indices]

func _ready():
	call_deferred("_setup_dag")

func valid_player(player:int)->bool:
	return(player >= 0 and player < 4)

func get_first_empty_home_idx(board_state:BoardState, player:int)->int:
	assert(valid_player(player))
	var ret := -1
	
	for home_pos in home_indices[player]:
		if not home_pos in board_state.marbles[player]:
			ret = home_pos
			break
	
	return ret

func _setup_dag():
	for i in range(len(all_indices)):
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

func calc_valid_movements(board_state:BoardState, dice_value:int, player:int, from_idx:int)->Array:
	var ret := []
	
	# Early exit on 0
	if dice_value == 0:
		return ret
	
	if from_idx in board_state.marbles[player]:
		ret += _movements_recurser(board_state, dice_value, player, dice_value, from_idx, from_idx, [from_idx])
	
	return ret

func _no_position_looping(player:int, next_position_idx:int, origin_idx:int):
	return (player_position_indices[player].find(next_position_idx) > player_position_indices[player].find(origin_idx))

func _movements_recurser(board_state:BoardState, dice_value:int, player:int, increments_left:int, origin_idx:int, from_idx:int, path_here:Array)->Array:
	var ret := []
	
	if from_idx in home_indices[player] and increments_left in [1, 6] and not track_indices[player][0] in board_state.marbles[player]:
		ret.append(track_indices[player][0])
	
	if increments_left == 1:
		var node := (dag[from_idx] as DAGNode)
		var ending_indices := []
		if node.next_main_track_node != null and node.next_main_track_node.idx != track_indices[player][0]:
			ending_indices.append(node.next_main_track_node.idx)
		if node.next_position_node != null and origin_idx in position_indices and _no_position_looping(player, node.next_position_node.idx, origin_idx):
			ending_indices.append(node.next_position_node.idx)
		if node.next_center_node != null:
			if dice_value == 1 and origin_idx in position_indices:
				ending_indices.append(node.next_center_node.idx)
			elif dice_value != 1 and not origin_idx in position_indices:
				ending_indices.append(node.next_center_node.idx)
		if node.next_home_row_node != null and node.next_home_row_node.home_row_owner == player:
			ending_indices.append(node.next_home_row_node.idx)
		if from_idx == 0 and dice_value == 1:
			for i in range(len(position_indices)):
				ending_indices.append(position_indices[i])
		for idx in ending_indices:
			if not idx in board_state.marbles[player]:
				ret.append(idx)
	else:
		assert(increments_left in [2, 3, 4, 5, 6])
		var node := (dag[from_idx] as DAGNode)
		var recurse_indices := []
		if node.next_main_track_node != null and node.next_main_track_node.idx != track_indices[player][0]:
			recurse_indices.append(node.next_main_track_node.idx)
		if node.next_position_node != null and origin_idx in position_indices and _no_position_looping(player, node.next_position_node.idx, origin_idx):
			recurse_indices.append(node.next_position_node.idx)
		if node.next_center_node != null:
			recurse_indices.append(node.next_center_node.idx)
		if node.next_home_row_node != null and node.next_home_row_node.home_row_owner == player:
			recurse_indices.append(node.next_home_row_node.idx)
		
		for idx in recurse_indices:
			if (not idx in path_here 
				and (not idx in board_state.marbles[player])):
				var path = path_here.duplicate()
				path.append(idx)
				ret += _movements_recurser(board_state, dice_value, player, increments_left - 1, origin_idx, idx, path)
	
	return ret

func _debug_dag(idx:int):
	var node := (dag[idx] as DAGNode)
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













