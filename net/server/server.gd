extends Node
class_name Server

var _socket := WebSocketServer.new()

var clients := {}
var games := {}

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
	else:
		create_game()

func _process(_delta:float) -> void:
	_socket.poll()
	
	for game in games.values():
		game.tick()

func close_all_connections():
	for peer_id in clients.keys():
		_socket.disconnect_peer(peer_id)

func _get_connected_player_list()->Array:
	var connected_players := []
	for peer_id in clients.keys():
		var peer_player = clients[peer_id].player
		if Logic.valid_player(peer_player) and not peer_player in connected_players:
			connected_players.append(peer_player)
	return(connected_players)

func _client_connected(id, proto):
	print("Client %d connected with protocol: %s" % [id, proto])
	var new_clientinfo = ClientInfo.new(id)
	
	# Add player to a game that is available
	if len(games) < 1:
		# No games available
		print("No games available. Disconnecting client %d" % [id])
		_socket.disconnect_peer(id)
		return
	
	var player := Logic.player.COUNT as int
	var game:Game = null
	var games_keys = games.keys()
	var game_key = games_keys[0]
	for i in range(len(games_keys)):
		game_key = games_keys[i]
		game = (games[game_key] as Game)
		if not game.has_all_players():
			player = game.next_open_player()
			game_key = games_keys[i]
			break
	
	if player == Logic.player.COUNT:
		# Couldn't add player to game TODO
		return
	
	new_clientinfo.player = player
	new_clientinfo.game_key = game_key
	game.players[id] = new_clientinfo
	clients[id] = new_clientinfo
	
	# Sync-up ClientInfo
	send_set_clientinfo(clients[id])
	
	# Sync-up game_state
	send_game_state_direct(game.game_state, id)

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
	
func _on_data_from_client(id):
	var pkt := _socket.get_peer(id).get_var() as Dictionary
	_handle_pkt(id, pkt)

func _handle_pkt(id:int, pkt:Dictionary):
	if not id in clients:
		return
	
	var type := pkt.get('type', PKT.type.NONE) as int
	if type == PKT.type.NONE:
		return
	
	var game := (games.get(clients[id].game_key, null) as Game)
	if game == null:
		return
	
	# Handle the packet
	match type:
		PKT.type.PLAYER_ROLL_REQUEST:
			game.player_roll_request(id, pkt)
		
		PKT.type.PLAYER_SET_NAME_REQUEST:
			game.player_set_name_request(id, pkt)
			
		PKT.type.PLAYER_SET_COLOR_REQUEST:
			game.player_set_color_request(id, pkt)
			
		PKT.type.PLAYER_PASS_REQUEST:
			game.player_pass_request(id, pkt)
		
		PKT.type.PLAYER_MOVE_REQUEST:
			game.player_move_request(id, pkt)
	
	# Server handles CMD packets
	match type:
		PKT.type.CMD:
			var cmd = pkt.get('cmd', PKT.cmd.NONE)
			if cmd == PKT.type.NONE:
				return
			match pkt.get('cmd', PKT.cmd.NONE):
				PKT.cmd.PRINT_TEXT:
					print("SERVER: PRINT_TEXT COMMAND RX")

func _send_pkt(pkt:Dictionary, broadcast:bool=true, peer_id:int=-1)->void:
	if pkt.empty():
		return
	
	if Config.is_local:
		Connection.client._handle_pkt(pkt)
	else:
		if broadcast:
			for id in clients.keys():
				_socket.get_peer(id).put_var(pkt)
		else:
			if peer_id != -1:
				_socket.get_peer(peer_id).put_var(pkt)

func get_games()->Dictionary:
	return(games)

func create_game():
	var new_game := Game.new()
	new_game.game_state.game_phase = Logic.game_phase.INIT
	var games_key := 0
	while games_key in games.keys():
		games_key += 1
	games[games_key] = new_game
	new_game.connect("sync_game", self, "_on_game_sync_game", [games_key])

func _on_game_sync_game(games_key):
	if not games_key in games.keys():
		return
	var game := (games.get(games_key, null) as Game)
	for p in game.players.values():
		var client_info := (p as ClientInfo)
		send_game_state_direct(game.game_state, client_info.peer_id)

func send_command_print_text()->void:
	_send_pkt(PKT.fmt_cmd_print_text())

func send_set_clientinfo(info:ClientInfo)->void:
	_send_pkt(PKT.fmt_set_clientinfo(info), false, info.peer_id)

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
	






