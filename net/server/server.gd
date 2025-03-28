extends Node
class_name Server

signal game_closed

var _tcp : TCPServer = null

var clients := {}
var games := {}

func _ready() -> void:
	randomize()
	
	if not Config.is_local:
		# Initiate Connection
		_tcp = TCPServer.new()
		var err = _tcp.listen(Config.PORT)
		if err != OK:
			print("Server could not listen...")
		
		if Config.number_of_games > 0:
			print("Creating %d games..." % [Config.number_of_games])
			for i in range(Config.number_of_games):
				create_game(str(i))
	else:
		create_game()

func process_client(client:ClientInfo):
	var s = client.socket
	if s == null:
		return
	s.poll()
	var state = s.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not client.connected:
			client.connected = true
			_client_connected(client.id, s.get_selected_protocol())
		while s.get_available_packet_count():
			var pkt = s.get_var(true)
			if pkt != null:
				_handle_pkt(client.id, pkt)
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = s.get_close_code()
		var reason = s.get_close_reason()
		var clean = code != -1
		print("Client %d closed with code: %d, reason %s. Clean: %s" % [client.id, code, reason, clean])
		_disconnected(client.id, clean)
		client.connected = false

func process_tcp():
	# Accept incoming connections
	while _tcp.is_connection_available():
		# id
		var id = randi()
		while id in clients:
			id = randi()
		var client = ClientInfo.new(id)
		
		# socket
		client.socket = WebSocketPeer.new()
		client.socket.accept_stream(_tcp.take_connection())
		
		clients[id] = client

func _process(_delta:float) -> void:
	if not Config.is_local:
		process_tcp()
	
	# Process connected clients
	for client_id in clients.keys():
		process_client(clients[client_id])
	
	# Process games
	for game in games.values():
		game.tick()

func close_all_connections():
	for id in clients.keys():
		if id == -1 and Config.is_local:
			continue
		clients[id].socket.close(0, "Server closed the connection")

func _client_connected(id, proto):
	print("Client %d connected with protocol: \"%s\"" % [id, proto])
	
	# Sync-up ClientInfo
	send_set_clientinfo(clients[id])

func remove_client(id:int):
	for game in games.values():
		if id in (game as Game).players:
			(game as Game).players.erase(id)
	if id in clients:
		clients.erase(id)
	
func _close_request(id, code, reason):
	var s := "Client %d disconnecting with code: %d, reason: %s" % [id, code, reason]
	print(s)
	remove_client(id)
	
func _disconnected(id, was_clean = false):
	var s := "Client %d disconnected, clean: %s" % [id, str(was_clean)]
	print(s)
	remove_client(id)

func _handle_pkt(id:int, pkt:Dictionary):
	if not id in clients:
		return
	
	var type := pkt.get('type', PKT.type.NONE) as int
	if type == PKT.type.NONE:
		return
	
	# Server handles some packets
	var server_handled := false
	match type:
		PKT.type.PLAYER_JOIN_GAME_REQUEST:
			var game_key = pkt.get('game_key', "")
			if not typeof(game_key) == TYPE_STRING:
				return
			
			if game_key in games:
				pass
			elif game_key.is_empty():
				game_key = find_game()
				if game_key.is_empty():
					game_key = create_game()
			else:
				game_key = create_game(game_key)
			
			var game := games[game_key] as Game
			var player := game.next_open_player()
			
			(clients[id] as ClientInfo).game_key = game_key
			(clients[id] as ClientInfo).player = player
			game.players[id] = clients[id]
			
			# Sync-up client info
			send_set_clientinfo(clients[id])
	
			print("Added client %d to game %s" % [id, str(game_key)])
			
			# Sync-up game_state
			send_game_state_direct(game.game_state, id)
			
			server_handled = true
			
		PKT.type.CMD:
			var cmd = pkt.get('cmd', PKT.cmd.NONE)
			if cmd == PKT.type.NONE:
				return
			match pkt.get('cmd', PKT.cmd.NONE):
				PKT.cmd.PRINT_TEXT:
					print("SERVER: PRINT_TEXT COMMAND RX")
			server_handled = true
	
	if server_handled:
		return
	
	var game := (games.get(clients[id].game_key, null) as Game)
	if game == null:
		return
	
	# Handle the packet
	match type:
		PKT.type.PLAYER_ROLL_REQUEST:
			game.player_roll_request(id, pkt)
			
		PKT.type.PLAYER_SET_COLOR_REQUEST:
			game.player_set_color_request(id, pkt)
			
		PKT.type.PLAYER_PASS_REQUEST:
			game.player_pass_request(id, pkt)
		
		PKT.type.PLAYER_MOVE_REQUEST:
			game.player_move_request(id, pkt)

func _send_pkt(pkt:Dictionary, broadcast:bool=true, id:int=-1)->void:
	if pkt.is_empty():
		return
	
	if Config.is_local:
		Connection.client._handle_pkt(pkt)
	else:
		if broadcast:
			for client_id in clients.keys():
				clients[client_id].socket.put_var(pkt)
		else:
			if id != -1:
				clients[id].socket.put_var(pkt)

func get_games()->Dictionary:
	return(games)

func create_game(key:String="")->String:
	if key in games:
		return(key)  # This game is already created
	
	var new_game := Game.new()
	
	if key.is_empty():
		# Create a game with next available integer
		var games_key := 0
		while str(games_key) in games.keys():
			games_key += 1
		key = str(games_key)
	
	new_game.game_state.game_phase = Logic.game_phase.INIT
	games[key] = new_game
	new_game.game_key = key
	new_game.sync_game.connect(_on_game_sync_game.bind(key))
	return(key)

func find_game()->String:
	var game_key := ""
	
	if len(games) <= 0:
		return(game_key)
	
	# Find a game with an open player slot
	var games_keys = games.keys()
	var game:Game = null
	game_key = games_keys[0]
	for i in range(len(games_keys)):
		game_key = games_keys[i]
		game = (games[game_key] as Game)
		if not game.has_all_players():
			game_key = games_keys[i]
			break
	
	return(game_key)

func delete_game(game_key:String):
	if not game_key in games:
		return
	
	var game := games[game_key] as Game
	var player_ids := []
	for ci in game.players.values():
		player_ids.append((ci as ClientInfo).peer_id)
	for id in player_ids:
		remove_client(id)
	game.queue_free()
	games.erase(game_key)
	game_closed.emit(game_key)

func _on_game_sync_game(games_key):
	if not games_key in games.keys():
		return
	var game := (games.get(games_key, null) as Game)
	for p in game.players.values():
		var client_info := (p as ClientInfo)
		send_game_state_direct(game.game_state, client_info.id)

func send_command_print_text()->void:
	_send_pkt(PKT.fmt_cmd_print_text())

func send_set_clientinfo(info:ClientInfo)->void:
	_send_pkt(PKT.fmt_set_clientinfo(info), false, info.id)

func send_player_roll_result(result:int)->void:
	assert(Config.is_local)
	var game := games.values()[0] as Game
	game.game_state.dice_value = result
	send_game_state(game.game_state)

func send_game_state(game_state:GameState)->void:
	if Config.is_local:
		var game := games.values()[0] as Game
		game.game_state.dice_value = game_state.dice_value
	_send_pkt(PKT.fmt_game_state(game_state))

func send_game_state_direct(game_state:GameState, peer_id:int)->void:
	if Config.is_local:
		var game := games.values()[0] as Game
		game.game_state.dice_value = game_state.dice_value
	_send_pkt(PKT.fmt_game_state(game_state), false, peer_id)

func win_player_game_0(player:int):
	if not "0" in games:
		return
	var game := games["0"] as Game
	game.game_state.board.marbles[player] = Logic.home_row_indices[player]
	_on_game_sync_game("0")
