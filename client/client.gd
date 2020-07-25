extends Node

var _socket := WebSocketClient.new()

func _ready():
			_socket.connect("connection_closed", self, "_closed")
			_socket.connect("connection_error", self, "_closed")
			_socket.connect("connection_established", self, "_connected_to_server")
			_socket.connect("data_received", self, "_on_data_from_server")

func _closed():
	pass

func _connected_to_server():
	pass

func _on_data_from_server():
	pass



