extends Node
class_name GameState

var game_phase := Logic.game_phase.COUNT as int
var player_turn := Logic.player.COUNT as int
var controls_players_marbles := Logic.player.COUNT as int
var player_has_rolled := false
var dice_value := 0
var board := BoardState.new()

func _init() -> void:
	pass

func fmt()->Dictionary:
	var pkt :=  {
		'game_phase': game_phase, 
		'player_turn': player_turn,
		'control_marbles': controls_players_marbles,
		'player_has_rolled': player_has_rolled, 
		'dice_value': dice_value, 
		'board': board.marbles.duplicate()
		}
	return pkt

func defmt(data:Dictionary)->void:
	assert('game_phase' in data)
	assert('player_turn' in data)
	assert('control_marbles' in data)
	assert('player_has_rolled' in data)
	assert('dice_value' in data)
	assert('board' in data)
	game_phase = data['game_phase']
	player_turn = data['player_turn']
	controls_players_marbles = data['control_marbles']
	player_has_rolled = data['player_has_rolled']
	dice_value = data['dice_value']
	board.set_all(data['board'])

func set_from(game_state:GameState)->void:
	game_phase = game_state.game_phase
	player_turn = game_state.player_turn
	controls_players_marbles = game_state.controls_players_marbles
	player_has_rolled = game_state.player_has_rolled
	dice_value = game_state.dice_value
	board.set_from(game_state.board)
