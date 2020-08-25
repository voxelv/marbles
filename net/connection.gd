extends Node

var client:Client = null
var server:Server = null

var local_viewer:Viewer = null

func setup()->Array:
	var peers := []
	if Config.is_local:
		client = LocalClient.new()
		server = Server.new()
		peers.append(client)
		peers.append(server)
	elif Config.is_server:
		server = Server.new()
		peers.append(server)
	else:
		client = Client.new()
		peers.append(client)
	
	print("Connection setup finished...")
	return(peers)

func get_player()->int:
	return client.info.player
