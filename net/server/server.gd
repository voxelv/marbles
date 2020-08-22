extends Node
class_name Server

var _socket := WebSocketServer.new()

var game_phase := Logic.game_phase.INIT as int
var player_turn := Logic.player.A as int
var board_state := BoardState.new(Logic.home_indices)
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

func _process(delta:float) -> void:
	match game_phase:
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
	game_phase = Logic.game_phase.STARTED
	send_board_state(board_state)

func _get_connected_player_list()->Array:
	var connected_players := []
	for peer_id in clients.keys():
		var peer_player = clients[peer_id].player
		if peer_player >= 0 and peer_player < Logic.player.COUNT and not peer_player in connected_players:
			connected_players.append(peer_player)
	return(connected_players)

func _client_connected(id, proto):
	var s := "Client %d connected with protocol: %s" % [id, proto]
	var new_clientinfo = ClientInfo.new(id)
	
	# Determine current players
	var current_players = []
	
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
			if player >= 0 and player < Logic.player.COUNT:
				# TODO: And check that it's player's turn
				var roll_result := (range(6)[randi() % 6] + 1) as int
				send_player_roll_result(roll_result)
		
		PKT.type.PLAYER_MOVE_REQUEST:
			var player = clients[id].player
			var from_idx = pkt.get('from_idx', -1)
			var to_idx = pkt.get('to_idx', -1)
			if from_idx < 0 or to_idx < 0:
				return
			
			print("Player Move Request: %d to %d" %[from_idx, to_idx])
			
			# Do the calculations
			# If move is valid, move the marble and broadcast the new board
				# Move is valid if in calculated valid moves, and player's turn
			var player_marble

func _send_pkt(pkt:Dictionary, broadcast:bool=true, player:int=Logic.player.COUNT)->void:
	if Config.is_local:
		Connection.client._handle_pkt(pkt)
	else:
		if broadcast:
			for id in clients.keys():
				_socket.get_peer(id).put_var(pkt)
		else:
			assert(player >= 0 and player < Logic.player.COUNT)
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

func send_command_print_text()->void:
	_send_pkt(PKT.fmt_cmd_print_text())

func send_board_state(board_state_in:BoardState):
	_send_pkt(PKT.fmt_board(board_state_in))

func send_board_state_direct(board_state_in:BoardState, player:int)->void:
	_send_pkt(PKT.fmt_board(board_state), false, player)

func send_player_turn_update(player:int)->void:
	_send_pkt(PKT.fmt_player_turn_update(player))

func send_player_roll_result(roll_result:int)->void:
	_send_pkt(PKT.fmt_player_roll_result(roll_result))

func send_set_clientinfo(info:ClientInfo)->void:
	_send_pkt(PKT.fmt_set_clientinfo(info), false, info.player)










