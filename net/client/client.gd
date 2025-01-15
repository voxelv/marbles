extends Node
class_name Client

var _socket := WebSocketPeer.new()
var info := ClientInfo.new()
var viewer: Viewer = null

var con_timer := Timer.new()
var connected := false
var con_count := 0

func _ready():
	
	if not Config.is_local:
		con_timer.wait_time = 1
		_attempt_connection()
		con_timer.timeout.connect(_on_con_timer_timeout)
		add_child(con_timer)
		con_timer.start()

func _on_con_timer_timeout()->void:
	_attempt_connection()

func _attempt_connection()->void:
	print("Attempting connection... %d" % con_count)
	con_count += 1
	var err := (_socket as WebSocketPeer).connect_to_url("%s:%d" % [Config.URL, Config.PORT])
	if err != OK:
		print("Could not connect...")

func _closed(was_clean:bool=false):
	print("Connection closed (%d), clean: %s" % [info.peer_id, was_clean])
	con_count = 0
	con_timer.start()

func _connected_to_server():
#	info.peer_id = _socket.id
	con_timer.stop()
	print("Connected.")
	Connection.client.send_player_join_game_request(Config.game_key)

func process_socket():
	_socket.poll()
	var state = _socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while _socket.get_available_packet_count():
			var pkt = _socket.get_var(true)
			if pkt != null:
				_handle_pkt(pkt)
		if not connected:
			connected = true
			_connected_to_server()
	elif state == WebSocketPeer.STATE_CLOSING:
		connected = false
		print("Connection closing...")
	elif state == WebSocketPeer.STATE_CLOSED:
		connected = false
		var code = _socket.get_close_code()
		var reason = _socket.get_close_reason()
		_closed(code != -1)
	else:
		connected = false

func _process(_delta):
	if not Config.is_local:
		process_socket()

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
				if Connection.client.viewer != null:
					Connection.client.viewer.update_ui(state)
		
		PKT.type.SET_CLIENTINFO:
			info.id = pkt.get('peer_id', -1)
			info.player = pkt.get('player', Logic.player.COUNT)
			DisplayServer.window_set_title({
				Logic.player.A: "[A]",
				Logic.player.B: "[B]",
				Logic.player.C: "[C]",
				Logic.player.D: "[D]",
				Logic.player.COUNT: "UNKNOWN",
			}[info.player])

func _send_pkt(pkt:Dictionary)->void:
	if pkt.is_empty():
		return
	
	if Config.is_local:
		Connection.server._handle_pkt(info.id, pkt)
	else:
		_socket.put_var(pkt)

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

func send_player_join_game_request(game_key:=""):
	_send_pkt(PKT.fmt_player_join_game_request(game_key))
