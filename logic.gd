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

var viewer:Viewer
var select_state:int = select_state_type.NONE
var select_index := -1
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
	return select_index in home_indices[player]

func valid_movements(player:int)->Array:
	var ret := []
	var idx := select_index
	
	var possible_moves := []
	# Find all movements, regardless of contents
	if marble_is_at_home(player) and dice_value in [1, 6]:
		possible_moves.append(track_indices[player][0])
	
	# Filter out own-marble passing and own-marble landing
	
	
	ret += possible_moves
	
	return ret


