extends Node
class_name Client

var _socket := WebSocketClient.new()
var info := ClientInfo.new()
var con_timer:Timer

var con_count := 0

func _ready():
	_socket.connect("connection_closed", self, "_closed")
	_socket.connect("connection_error", self, "_connection_error")
	_socket.connect("connection_established", self, "_connected_to_server")
	_socket.connect("data_received", self, "_on_data_from_server")
	
	if not Config.is_local:
		_attempt_connection()
		con_timer = Timer.new()
		con_timer.wait_time = 1
		con_timer.connect("timeout", self, "_on_con_timer_timeout")
		add_child(con_timer)
		con_timer.start()

func _on_con_timer_timeout()->void:
	_attempt_connection()

func _attempt_connection()->void:
	print("Attempting connection... %d" % con_count)
	con_count += 1
	if _socket.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED:
		var err := (_socket as WebSocketClient).connect_to_url("%s:%d" % [Config.URL, Config.PORT])
		if err != OK:
			print("Could not connect...")

func _closed(was_clean:bool=false):
	print("Connection closed (%d), clean: %s" % [info.peer_id, was_clean])
	con_count = 0
	con_timer.start()

func _connected_to_server(proto:String):
#	info.peer_id = _socket.id
	con_timer.stop()
	print("Connected (%s)." % proto)
	Connection.client.send_player_join_game_request(Config.game_key)

func _connection_error():
	print("Connection error...")

func _on_data_from_server():
	var pkt := _socket.get_peer(1).get_var() as Dictionary
	_handle_pkt(pkt)

func _process(_delta):
#	if _socket.get_connection_status() != NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED:
	_socket.poll()

func disconnect_from_server():
	_socket.disconnect_from_host()

func _handle_pkt(pkt:Dictionary):
	var type := pkt.get('type', PKT.type.NONE) as int
	if type == PKT.type.NONE:
		return
	
	match type:
		# Command
		PKT.type.CMD:
			var cmd = pkt.get('cmd', PKT.cmd.NONE)
			if cmd == PKT.cmd.NONE:
				return
			match cmd:
				PKT.cmd.PRINT_TEXT:
					print("CLIENT: PRINT_TEXT COMMAND RX")
		
		PKT.type.GAME_STATE:
			var state := GameState.new()
			state.defmt(pkt)
			if Config.is_local:
				info.player = state.player_turn
			if Connection.local_viewer != null:
				Connection.local_viewer.update_ui(state)
		
		PKT.type.SET_CLIENTINFO:
			info.peer_id = pkt.get('peer_id', -1)
			info.player = pkt.get('player', Logic.player.COUNT)
			OS.set_window_title({
				Logic.player.A: "[A]",
				Logic.player.B: "[B]",
				Logic.player.C: "[C]",
				Logic.player.D: "[D]",
				Logic.player.COUNT: "UNKNOWN",
			}[info.player])

func _send_pkt(pkt:Dictionary)->void:
	if pkt.empty():
		return
	
	if Config.is_local:
		Connection.server._handle_pkt(info.peer_id, pkt)
	else:
		_socket.get_peer(1).put_var(pkt)

func send_command_print_text()->void:
	_send_pkt(PKT.fmt_cmd_print_text())

func send_player_roll_request()->void:
	_send_pkt(PKT.fmt_player_roll_request())

func send_player_pass_request()->void:
	_send_pkt(PKT.fmt_player_pass_request())

func send_player_move_request(from_idx:int, to_idx:int)->void:
	_send_pkt(PKT.fmt_player_move_request(from_idx, to_idx))

func send_player_set_color_request(player:int, color_id:int):
	_send_pkt(PKT.fmt_player_set_color_request(player, color_id))

func send_player_set_name_request(player:int, new_name:String):
	_send_pkt(PKT.fmt_player_set_name_request(player, new_name))

func send_player_join_game_request(game_key:=""):
	_send_pkt(PKT.fmt_player_join_game_request(game_key))







