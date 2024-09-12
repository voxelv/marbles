extends Node

var client:Client = null
var server:Server = null

func setup():
	clear_peers()
	
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

func clear_peers():
	if is_instance_valid(client):
		client.disconnect_from_server()
		client.queue_free()
	if is_instance_valid(server):
		server.close_all_connections()
		server.queue_free()

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
