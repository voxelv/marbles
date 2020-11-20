extends Node
class_name Game

const TICK_MULTIPLIER = 1000

signal sync_game

var game_key := ""
var game_state : GameState
var players := {}  # Dictionary of ClientInfo (peer_id as key)
var _counter := 0
var _tick_xn000_count := -1
var close_timer : Timer

func _init():
	game_state = GameState.new()
	close_timer = Timer.new()
	close_timer.connect("timeout", self, "_on_close_timer_timeout")
	Connection.server.add_child(close_timer)

func _on_close_timer_timeout():
	print("Game: %s closing..." % [game_key])
	Connection.server.remove_child(close_timer)
	Connection.server.delete_game(game_key)
	queue_free()

func _update_marble_control():
	var teammate_map := [2, 3, 0, 1]
	if all_marbles_home_for_player(game_state.player_turn):
		game_state.controls_players_marbles = teammate_map[game_state.player_turn]
	else:
		game_state.controls_players_marbles = game_state.player_turn

func tick():
	match game_state.game_phase:
		Logic.game_phase.INIT:
			if Config.is_local:
				# Start the game immediately
				close_timer.stop()
				start_game()
			else:
				# Wait until all players are connected before starting game
				if has_all_players():
					start_game()
				if len(players) <= 0 and close_timer.time_left == 0.0:
					close_timer.start(Config.GAME_REMOVAL_TIME)
				elif len(players) > 0:
					close_timer.stop()
				
		Logic.game_phase.STARTED:
			# Reset the game if nobody is playing
			if len(players) <= 0:
				game_state.game_phase = Logic.game_phase.INIT
			else:
				close_timer.stop()
	
	if _counter % TICK_MULTIPLIER == 0:
		_counter = 0
		_tick_xn000_count += 1
		print("Game: %s tick: %d (x%d) Status: %s Players: %d Timeout: %f" % [str(game_key), _tick_xn000_count, TICK_MULTIPLIER, {Logic.game_phase.INIT: "INIT", Logic.game_phase.STARTED: "STARTED", Logic.game_phase.COUNT: "???"}[game_state.game_phase], len(players), close_timer.time_left])
	
	_counter += 1

func start_game()->void:
	game_state.game_phase = Logic.game_phase.STARTED
	game_state.player_turn = Logic.player.A
	_update_marble_control()
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
	_update_marble_control()

func get_id_from_player(player:int)->int:
	var ret_id = -1
	for id in players.keys():
		if players[id].player == player:
			ret_id = id
			break
	return ret_id

func all_marbles_home_for_player(player:int)->bool:
	var ret := true
	
	for position_idx in Logic.home_row_indices[player]:
		if not position_idx in game_state.board.marbles[player]:
			ret = false
	
	return(ret)

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
		
		# If player has won, they can help their teammate
		_update_marble_control()
		
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
#	emit_signal("sync_game")

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
#	emit_signal("sync_game")

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
	
	print("Game: %s Player Move Request: %d to %d" %[game_key, from_idx, to_idx])
	
	# Do the calculations
	# If move is valid, move the marble and broadcast the new board
		# Move is valid if in calculated valid moves, and player's turn, and from player's marble
	if not game_state.player_has_rolled:
		return
	if not player == game_state.player_turn:
		return
	if not from_idx in game_state.board.marbles[game_state.controls_players_marbles]:
		return
	var valid_moves := Logic.calc_valid_movements(
		game_state.board, game_state.dice_value, 
		game_state.controls_players_marbles, 
		from_idx)
	if not to_idx in valid_moves:
		return
	
	# Move the marble
	game_state.board.set_marble(game_state.controls_players_marbles, game_state.board.get_marble_idx(game_state.controls_players_marbles, from_idx), to_idx)
	
	# If to_idx has another player's marble, send it home
	var other_player_marble_idx := -1
	var other_player := Logic.player.COUNT as int
	for p in range(Logic.player.COUNT):
		if p == game_state.controls_players_marbles:
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

















