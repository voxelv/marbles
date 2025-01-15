extends Node
class_name ClientInfo

var connected := false
var socket : WebSocketPeer = null
var id : int
var game_key := ""
var player := 4

func _init(id:int=-1) -> void:
	self.id = id
