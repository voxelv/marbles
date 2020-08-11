extends Node
class_name Client

var _socket := WebSocketClient.new()
var info := ClientInfo.new()

func _ready():
	_socket.connect("connection_closed", self, "_closed")
	_socket.connect("connection_error", self, "_closed")
	_socket.connect("connection_established", self, "_connected_to_server")
	_socket.connect("data_received", self, "_on_data_from_server")
	
	if not Config.is_local:
		var err := (_socket as WebSocketClient).connect_to_url("%s:%d" % [Config.URL, Config.PORT])
		if err != OK:
			print("Could not connect...")

func _closed(was_clean:bool=false):
	print("Client %d closed, clean: " % info.peer_id, was_clean)

func _connected_to_server(proto:String):
	info.peer_id = _socket.id
	print("Connected.")

func _on_data_from_server():
	var pkt := _socket.get_peer(1).get_var() as Dictionary
	_handle_pkt(pkt)

func _process(_delta):
	if _socket.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED:
		_socket.poll()

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
		PKT.type.BOARD:
			var board_state := BoardState.new(pkt.get('board', []) as Array)
			Connection.local_viewer.set_board_state(board_state)

func _send_pkt(pkt:Dictionary)->void:
	if Config.is_local:
		Connection.server._handle_pkt(pkt)
	else:
		_socket.put_var(pkt)

func send_command_print_text()->void:
	_send_pkt(PKT.fmt_cmd_print_text())















