extends Node

func _ready() -> void:
	await(get_tree().process_frame)
	await(get_tree().process_frame)
	get_tree().change_scene(Omni.scene_for_loading_to_load)
