extends Node
class_name GameState

var game_phase := 2
var player_turn := 4
var controls_players_marbles := 4
var player_has_rolled := false
var dice_value := 0
var board := BoardState.new()
var custom_clients := {}

func _init() -> void:
	for player in range(4):
		custom_clients[player] = CustomClientInfo.new()

func fmt()->Dictionary:
	var pkt :=  {
		'game_phase': game_phase, 
		'player_turn': player_turn,
		'control_marbles': controls_players_marbles,
		'player_has_rolled': player_has_rolled, 
		'dice_value': dice_value, 
		'board': board.marbles.duplicate(),
		'custom_clients': {}
		}
	# Fill in custom client data
	for player in custom_clients.keys():
		var cci := custom_clients[player] as CustomClientInfo
		pkt['custom_clients'][player] = {
			'display_name': cci.display_name,
			'color': cci.color_id
		}
		
	return pkt

func defmt(data:Dictionary)->void:
	assert('game_phase' in data)
	assert('player_turn' in data)
	assert('control_marbles' in data)
	assert('player_has_rolled' in data)
	assert('dice_value' in data)
	assert('board' in data)
	assert('custom_clients' in data)
	assert(data['custom_clients'] is Dictionary)
	game_phase = data['game_phase']
	player_turn = data['player_turn']
	controls_players_marbles = data['control_marbles']
	player_has_rolled = data['player_has_rolled']
	dice_value = data['dice_value']
	board.set_all(data['board'])
	for player in data['custom_clients'].keys():
		custom_clients[player].display_name = data['custom_clients'][player]['display_name']
		custom_clients[player].color_id = data['custom_clients'][player]['color']

func set_from(game_state:GameState)->void:
	game_phase = game_state.game_phase
	player_turn = game_state.player_turn
	controls_players_marbles = game_state.controls_players_marbles
	player_has_rolled = game_state.player_has_rolled
	dice_value = game_state.dice_value
	board.set_from(game_state.board)
	for player in game_state.custom_clients.keys():
		var incoming_cci := game_state.custom_clients[player] as CustomClientInfo
		custom_clients[player].display_name = incoming_cci.display_name
		custom_clients[player].color_id = incoming_cci.color_id
