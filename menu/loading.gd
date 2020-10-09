extends Node

func _ready() -> void:
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	get_tree().change_scene(Omni.scene_for_loading_to_load)
