extends Node
class_name Game

signal sync_game

var game_name := ""
var game_state : GameState
var players := {}  # Dictionary of ClientInfo (peer_id as key)

func _init():
	game_state = GameState.new()

func tick():
	match game_state.game_phase:
		Logic.game_phase.INIT:
			if Config.is_local:
				# Start the game immediately
				start_game()
			else:
				# Wait until all players are connected before starting game
				if has_all_players():
					start_game()
		Logic.game_phase.STARTED:
			pass

func start_game()->void:
	game_state.game_phase = Logic.game_phase.STARTED
	game_state.player_turn = Logic.player.A
	game_state.board.set_all(Logic.home_indices)
	
	for player in game_state.custom_clients.keys():
		game_state.custom_clients[player].color_id = Palette.initial_colors[player]
	
	emit_signal("sync_game")

func has_all_players()->bool:
	# If Local game, there's only one player (client)
	if Config.is_local and len(players) >= 1:
		var found_a_player := false
		for i in range(Logic.player.COUNT):
			var found := false
			for ci in players.values():
				if ci.player == i:
					found_a_player = true
					found = true
			if found:
				break
		return(found_a_player)
	
	# There's no way if there's not enough players
	if len(players) < 4:
		return(false)
	
	# Check all players
	var all_found := true
	for i in range(Logic.player.COUNT):
		var found := false
		for ci in players.values():
			if (ci as ClientInfo).player == i:
				found = true
		if not found:
			all_found = false
	return(all_found)

func next_open_player()->int:
	var ret := Logic.player.COUNT as int
	for i in range(Logic.player.COUNT):
		var found := false
		for ci in players.values():
			if (ci as ClientInfo).player == i:
				found = true
		if not found:
			ret = i
			break
	return(ret)

func validate_player(id:int, reported_player:int)->bool:
	var player = players[id].player
	if reported_player != player:
		return false
	if not Logic.valid_player(player):
		return false
	return true

func increment_player_turn():
	game_state.player_has_rolled = false
	if not game_state.dice_value == 6:
		var prev_player_turn = game_state.player_turn
		game_state.player_turn += 1
		if game_state.player_turn >= Logic.player.COUNT:
			game_state.player_turn = 0
		if Config.is_local:
			players[get_id_from_player(prev_player_turn)].player = game_state.player_turn

func get_id_from_player(player:int)->int:
	var ret_id = -1
	for id in players.keys():
		if players[id].player == player:
			ret_id = id
			break
	return ret_id
	
func player_roll_request(id:int, pkt:Dictionary):
	if not game_state.game_phase == Logic.game_phase.STARTED:
		return
	
	if not has_all_players():
		return
	
	var player := (players[id].player as int)
	if Logic.valid_player(player):
		var roll_result := 0
		if game_state.player_has_rolled:
			roll_result = game_state.dice_value
		else:
			# TODO: And check that it's player's turn
			roll_result = (range(6)[randi() % 6] + 1) as int
		
		game_state.dice_value = roll_result
		game_state.player_has_rolled = true
		emit_signal("sync_game")

func player_set_name_request(id:int, pkt:Dictionary):
	var reported_player = pkt.get('player', Logic.player.COUNT)
	if not validate_player(id, reported_player):
		return
	
	var player = players[id].player
	
	var requested_name := pkt.get('name', "?") as String
	var already_used := false
	for p in range(Logic.player.COUNT):
		if p == player:
			continue
		if game_state.custom_clients[p].display_name == requested_name:
			already_used = true
	if already_used:
		return
	
	game_state.custom_clients[player].display_name = requested_name
	emit_signal("sync_game")

func player_set_color_request(id:int, pkt:Dictionary):
	var reported_player = pkt.get('player', Logic.player.COUNT)
	if not validate_player(id, reported_player):
		return
	
	var player = players[id].player
	
	var request_color_id = pkt.get('color', Palette.color.GRAY)
	var already_used := false
	for p in range(Logic.player.COUNT):
		if p == player:
			continue
		if game_state.custom_clients[p].color_id == request_color_id:
			already_used = true
	if already_used:
		return
	game_state.custom_clients[player].color_id = request_color_id
	emit_signal("sync_game")

func player_pass_request(id:int, pkt:Dictionary):
	increment_player_turn()
	game_state.dice_value = 0
	emit_signal("sync_game")

func player_move_request(id:int, pkt:Dictionary):
			var player = players[id].player
			var from_idx = pkt.get('from_idx', -1)
			var to_idx = pkt.get('to_idx', -1)
			if from_idx < 0 or to_idx < 0:
				return
			
			print("Player Move Request: %d to %d" %[from_idx, to_idx])
			
			# Do the calculations
			# If move is valid, move the marble and broadcast the new board
				# Move is valid if in calculated valid moves, and player's turn, and from player's marble
			if not game_state.player_has_rolled:
				return
			if not player == game_state.player_turn:
				return
			if not from_idx in game_state.board.marbles[player]:
				return
			var valid_moves := Logic.calc_valid_movements(game_state.board, game_state.dice_value, player, from_idx)
			if not to_idx in valid_moves:
				return
			
			# Move the marble
			game_state.board.set_marble(player, game_state.board.get_marble_idx(player, from_idx), to_idx)
			
			# If to_idx has another player's marble, send it home
			var other_player_marble_idx := -1
			var other_player := Logic.player.COUNT as int
			for p in range(Logic.player.COUNT):
				if p == player:
					continue
				if to_idx in game_state.board.marbles[p]:
					other_player = p
					other_player_marble_idx = game_state.board.get_marble_idx(p, to_idx)
			if Logic.valid_player(other_player) and other_player_marble_idx >= 0:
				# Move other player's marble home
				game_state.board.set_marble(other_player, other_player_marble_idx, Logic.get_first_empty_home_idx(game_state.board, other_player))
			
			# Handle end of roll
			increment_player_turn()
			if not game_state.dice_value == 6:
				game_state.dice_value = 0
			emit_signal("sync_game")
			
			if Config.is_local:
				players[id].player = game_state.player_turn
















