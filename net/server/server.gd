extends Node
class_name Server

var _socket := WebSocketServer.new()

var state := GameState.new()
var clients := {}

func _ready() -> void:
	randomize()
	
	if not Config.is_local:
		_socket.connect("client_connected", self, "_client_connected")
		_socket.connect("client_disconnected", self, "_disconnected")
		_socket.connect("client_close_request", self, "_close_request")
		_socket.connect("data_received", self, "_on_data_from_client")
		
		# Initiate Connection
		var err = (_socket as WebSocketServer).listen(Config.PORT)
		if err != OK:
			print("Server could not listen...")
	
	state.game_phase = Logic.game_phase.INIT

func _process(delta:float) -> void:
	match state.game_phase:
		Logic.game_phase.INIT:
			if Config.is_local:
				# Start the game immediately
				start_game()
			else:
				# Wait until all players are connected before starting game
				var connected_players := _get_connected_player_list()
				var all_players_connected = true
				for p in range(Logic.player.COUNT):
					if not p in connected_players:
						all_players_connected = false
				if all_players_connected:
					start_game()
		Logic.game_phase.STARTED:
			if Config.is_local:
				pass
			else:
				_socket.poll()

func start_game()->void:
	state.game_phase = Logic.game_phase.STARTED
	state.player_turn = Logic.player.A
	state.board.set_all(Logic.home_indices)
	
	for player in state.custom_clients.keys():
		state.custom_clients[player].color = Config.initial_colors[player]
	
	send_game_state(state)

func _get_connected_player_list()->Array:
	var connected_players := []
	for peer_id in clients.keys():
		var peer_player = clients[peer_id].player
		if Logic.valid_player(peer_player) and not peer_player in connected_players:
			connected_players.append(peer_player)
	return(connected_players)

func _client_connected(id, proto):
	var s := "Client %d connected with protocol: %s" % [id, proto]
	var new_clientinfo = ClientInfo.new(id)
	
	# Determine current players
	var current_players = _get_connected_player_list()
	
	# Choose an unused player slot, if they're all used, send COUNT to signify no player assigned
	var player = Logic.player.COUNT
	for p in range(Logic.player.COUNT):
		if not p in current_players:
			player = p
			break
	new_clientinfo.player = player
	clients[id] = new_clientinfo
	send_set_clientinfo(clients[id])
	print(s)
	
func _close_request(id, code, reason):
	var s := "Client %d disconnecting with code: %d, reason: %s" % [id, code, reason]
	clients.erase(id)
	print(s)
	
func _disconnected(id, was_clean = false):
	var s := "Client %d disconnected, clean: %s" % [id, str(was_clean)]
	clients.erase(id)
	print(s)
	
func _on_data_from_client(id):
	var pkt := _socket.get_peer(id).get_var() as Dictionary
	_handle_pkt(id, pkt)

func _handle_pkt(id:int, pkt:Dictionary):
	var type := pkt.get('type', PKT.type.NONE) as int
	if type == PKT.type.NONE:
		return
	
	match type:
		PKT.type.CMD:
			var cmd = pkt.get('cmd', PKT.cmd.NONE)
			if cmd == PKT.type.NONE:
				return
			match pkt.get('cmd', PKT.cmd.NONE):
				PKT.cmd.PRINT_TEXT:
					print("SERVER: PRINT_TEXT COMMAND RX")
		
		PKT.type.PLAYER_ROLL_REQUEST:
			var player = clients[id].player
			if Logic.valid_player(player):
				var roll_result := 0
				if state.player_has_rolled:
					roll_result = state.dice_value
				else:
					# TODO: And check that it's player's turn
					roll_result = (range(6)[randi() % 6] + 1) as int
				
				state.dice_value = roll_result
				state.player_has_rolled = true
				send_game_state(state)
			
		PKT.type.PLAYER_SET_COLOR_REQUEST:
			var player = pkt.get('player', Logic.player.COUNT)
			if not Logic.valid_player(player):
				return
			state.custom_clients[player].color = pkt.get('color', Color.white)
			send_game_state(state)
			
		PKT.type.PLAYER_PASS_REQUEST:
			increment_player_turn()
			state.dice_value = 0
			send_game_state(state)
		
		PKT.type.PLAYER_MOVE_REQUEST:
			var player = clients[id].player
			var from_idx = pkt.get('from_idx', -1)
			var to_idx = pkt.get('to_idx', -1)
			if from_idx < 0 or to_idx < 0:
				return
			
			print("Player Move Request: %d to %d" %[from_idx, to_idx])
			
			# Do the calculations
			# If move is valid, move the marble and broadcast the new board
				# Move is valid if in calculated valid moves, and player's turn, and from player's marble
			if not state.player_has_rolled:
				return
			if not player == state.player_turn:
				return
			if not from_idx in state.board.marbles[player]:
				return
			var valid_moves := Logic.calc_valid_movements(state.board, state.dice_value, player, from_idx)
			if not to_idx in valid_moves:
				return
			
			# Move the marble
			state.board.set_marble(player, state.board.get_marble_idx(player, from_idx), to_idx)
			
			# If to_idx has another player's marble, send it home
			var other_player_marble_idx := -1
			var other_player := Logic.player.COUNT as int
			for p in range(Logic.player.COUNT):
				if p == player:
					continue
				if to_idx in state.board.marbles[p]:
					other_player = p
					other_player_marble_idx = state.board.get_marble_idx(p, to_idx)
			if Logic.valid_player(other_player) and other_player_marble_idx >= 0:
				# Move other player's marble home
				state.board.set_marble(other_player, other_player_marble_idx, Logic.get_first_empty_home_idx(state.board, other_player))
			
			# Handle end of roll
			increment_player_turn()
			if not state.dice_value == 6:
				state.dice_value = 0
			send_game_state(state)
			
			if Config.is_local:
				clients[id].player = state.player_turn

func _send_pkt(pkt:Dictionary, broadcast:bool=true, player:int=Logic.player.COUNT)->void:
	if Config.is_local:
		Connection.client._handle_pkt(pkt)
	else:
		if broadcast:
			for id in clients.keys():
				_socket.get_peer(id).put_var(pkt)
		else:
			assert(Logic.valid_player(player))
			var id = get_id_from_player(player)
			if id != -1:
				_socket.get_peer(id).put_var(pkt)

func get_id_from_player(player:int)->int:
	var ret_id = -1
	for id in clients.keys():
		if clients[id].player == player:
			ret_id = id
			break
	return ret_id

func increment_player_turn():
	state.player_has_rolled = false
	if not state.dice_value == 6:
		var prev_player_turn = state.player_turn
		state.player_turn += 1
		if state.player_turn >= Logic.player.COUNT:
			state.player_turn = 0
		if Config.is_local:
			clients[get_id_from_player(prev_player_turn)].player = state.player_turn

func send_command_print_text()->void:
	_send_pkt(PKT.fmt_cmd_print_text())

func send_set_clientinfo(info:ClientInfo)->void:
	_send_pkt(PKT.fmt_set_clientinfo(info), false, info.player)

func send_player_roll_result(result:int)->void:
	state.dice_value = result
	send_game_state(state)

func send_game_state(game_state:GameState)->void:
	if Config.is_local:
		state.dice_value = game_state.dice_value
	_send_pkt(PKT.fmt_game_state(game_state))








