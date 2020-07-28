extends Node
class_name Client

const URL := "localhost"
const PORT := 9080

var client_peerid := -1

var _socket := WebSocketClient.new()

func _ready():
	_socket.connect("connection_closed", self, "_closed")
	_socket.connect("connection_error", self, "_closed")
	_socket.connect("connection_established", self, "_connected_to_server")
	_socket.connect("data_received", self, "_on_data_from_server")
	var err := (_socket as WebSocketClient).connect_to_url("%s:%d" % [URL, PORT])
	if err != OK:
		print("Could not connect...")

func _closed(was_clean:bool=false):
	print("Client %d closed, clean: " % client_peerid, was_clean)

func _connected_to_server(proto:String):
	print("Connected.")

func _on_data_from_server():
	var pkt := _socket.get_peer(1).get_var() as Dictionary
	_handle_pkt(pkt)

func _process(_delta):
	if _socket.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED:
		_socket.poll()

func _handle_pkt(pkt:Dictionary):
	var type := pkt.get('type', -1) as int
	if type == -1:
		return
	
	match type:
		# Command
		0:
			print("COMMAND RX")

func _send_pkt(pkt:Dictionary)->void:
	if Config.is_local:
		Config.server._handle_packet(pkt)
















