extends Node

func _ready() -> void:
	await(get_tree().process_frame)
	await(get_tree().process_frame)
	get_tree().change_scene_to_file(Omni.scene_for_loading_to_load)
