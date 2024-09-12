extends Node

var scene_for_loading_to_load := ""

func change_scene_with_loading(new_scene:String):
	scene_for_loading_to_load = new_scene
	get_tree().change_scene("res://menu/loading.tscn")

func find_node(from:Node, name:String)->Node:
	for c in from.get_children(true):
		if c.name == name:
			return c
		else:
			var found = find_node(c, name)
			if found != null:
				return found
	return null
