extends Node
class_name ClientInfo

var game_key := ""
var peer_id := -1
var player := 4

func _init(peer_id_in:int=-1) -> void:
	peer_id = peer_id_in

