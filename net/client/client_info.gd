extends Node
class_name ClientInfo


var peer_id:int
var display_name := ""

func _init(peer_id_in:int=-1) -> void:
	peer_id = peer_id_in

