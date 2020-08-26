extends Node
class_name ClientInfo


var peer_id := -1
var player := Logic.player.COUNT as int

func _init(peer_id_in:int=-1) -> void:
	peer_id = peer_id_in

