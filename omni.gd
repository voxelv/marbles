extends Node

var scene_for_loading_to_load := ""

func change_scene_with_loading(new_scene:String):
	scene_for_loading_to_load = new_scene
	get_tree().change_scene("res://menu/loading.tscn")
