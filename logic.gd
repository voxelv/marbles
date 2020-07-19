extends Node

enum player{A, B, C, D}
enum select_state_type{NONE, SLCT}

const Viewer := preload("res://viewer.gd")
const NUM_MARBLES_PER_PLAYER := 5

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
var dice_value := 6
var marbles := [
	[-1, -1, -1, -1, -1],
	[-1, -1, -1, -1, -1],
	[-1, -1, -1, -1, -1],
	[-1, -1, -1, -1, -1],
	]

func set_viewer(v:Viewer):
	self.viewer = v

func player_can_select(player:int, idx:int)->bool:
	var ret := false
	match select_state:
		select_state_type.NONE:
			ret = (idx in marbles[player])
		select_state_type.SLCT:
			ret = (idx in valid_movements(player))
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
	
	# Movement from home to track
	if marble_is_at_home(player) and dice_value in [1, 6]:
		possible_moves.append(track_indices[player][0])
	# Movement on track
	else:
		# Movement from center
		if select_index == 0:
			possible_moves += position_indices
		# Movement from position
		elif select_index in position_indices:
			var i := position_indices.find(select_index)
			match dice_value:
				1:
					if i + 1 >= len(position_indices):
						i = 0
					if index_in_player_track(position_indices[i]) > index_in_player_track(select_index):
						possible_moves.append(position_indices[i])
				2:
					var increments_left = dice_value
					while increments_left > 0:
						if i + 1 >= len(position_indices):
							i = 0
						else:
							i += 1
						increments_left -= 1
					if index_in_player_track(position_indices[i]) > index_in_player_track(select_index):
						possible_moves.append(position_indices)
			
	
	# Movement to center
	# If moving dice_value results in an index one greater than position
	if track_indices[current_player][index_in_player_track(select_index) - 1] in position_indices:
		possible_moves.append(0)
	
	# Filter out own-marble passing and own-marble landing
	
	
	ret += possible_moves
	
	return ret

func idx_pressed(idx:int):
	match select_state:
		select_state_type.NONE:
			if player_can_select(current_player, idx):
				select_index = idx
				select_state = select_state_type.SLCT
		select_state_type.SLCT:
			if idx in valid_movements(current_player):
				set_player_marble_idx(current_player, selected_marble(), idx)
			select_index = -1
			select_state = select_state_type.NONE
