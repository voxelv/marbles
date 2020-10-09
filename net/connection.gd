extends Node

var client:Client = null
var server:Server = null

var local_viewer:Viewer = null

func setup():
	if Config.is_local:
		client = LocalClient.new()
		server = Server.new()
		add_child(client)
		add_child(server)
	elif Config.is_server:
		server = Server.new()
		add_child(server)
	else:
		client = Client.new()
		add_child(client)
	
	
	
	print("Connection setup finished...")

func get_player()->int:
	return client.info.player

func can_control_player(player:int)->bool:
	if Config.is_local:
		return true
	else:
		return get_player() == player

func local_connection_setup():
	server._client_connected(Connection.client.info.peer_id, null)

func remote_connection_setup():
	pass
