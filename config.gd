extends Node

var is_server := false
var is_local := true

var client:Client = null
var server:Server = null


func setup():
	if is_local:
		server = Server.new()
		client = LocalClient.new()
	elif is_server:
		server = Server.new()
	else:
		client = Client.new()
