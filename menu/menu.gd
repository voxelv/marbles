extends Node

func _ready() -> void:
	var cli_args = OS.get_connected_midi_inputs()
	if "SERVER" in cli_args:
		Config.is_server = true
	
	Config.setup()

func _on_local_game_button_pressed():
	get_tree().change_scene("res://viewer.tscn")




