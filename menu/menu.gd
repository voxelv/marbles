extends Node

var viewer:Node = null

func _ready() -> void:
	var cli_args = OS.get_cmdline_args()
	if "SERVER" in cli_args:
		Config.is_server = true
	
	call_deferred("_load_viewer")

func _on_local_game_button_pressed():
	Config.is_local = true
	Config.is_server = false
	
	Connection.setup()
	
	if viewer != null:
		var root = get_tree().get_root()
		for c in root.get_children():
			root.remove_child(c)
		root.add_child(viewer)
		Connection.local_viewer = viewer

func _load_viewer():
	viewer = load("res://viewer.tscn").instance()


