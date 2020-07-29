extends Node

var viewer_scene:PackedScene

func _ready() -> void:
	var cli_args = OS.get_cmdline_args()
	if "SERVER" in cli_args:
		Config.is_server = true
	
	call_deferred("_load_viewer")

func _on_local_game_button_pressed():
	Config.is_local = true
	Config.is_server = false
	
	Connection.setup()
	
	if viewer_scene != null:
		get_tree().change_scene_to(viewer_scene)

func _load_viewer():
	viewer_scene = load("res://viewer.tscn")


