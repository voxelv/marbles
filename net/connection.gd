extends Node

var client:Client = null
var server:Server = null


func setup():
	if Config.is_local:
		server = Server.new()
		client = LocalClient.new()
		add_child(server)
		add_child(client)
	elif Config.is_server:
		server = Server.new()
		add_child(server)
	else:
		client = Client.new()
		add_child(client)
