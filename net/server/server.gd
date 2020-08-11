extends Node
class_name Server

var _socket := WebSocketServer.new()

var clients := {}

func _ready() -> void:
	_socket.connect("client_connected", self, "_client_connected")
	_socket.connect("client_disconnected", self, "_disconnected")
	_socket.connect("client_close_request", self, "_close_request")
	_socket.connect("data_received", self, "_on_data_from_client")
	
	if not Config.is_local:
		var err = (_socket as WebSocketServer).listen(Config.PORT)
		if err != OK:
			print("Server could not listen...")

func _client_connected(id, proto):
	var s := "Client %d connected with protocol: %s" % [id, proto]
	clients[id] = ClientInfo.new(id)
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
	_handle_pkt(pkt)

func _handle_pkt(pkt:Dictionary):
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

func _send_pkt(pkt:Dictionary)->void:
	if Config.is_local:
		Connection.client._handle_pkt(pkt)
	else:
		for id in clients.keys():
			_socket.get_peer(id).put_var(pkt)

func send_command_print_text()->void:
	_send_pkt(PKT.fmt_cmd_print_text())

func send_board_state(board_state:BoardState):
	_send_pkt(PKT.fmt_board(board_state))
















