extends Node

onready var local_game_button := find_node("local_game_button") as Button
onready var text_output := find_node("text_output") as TextEdit

var viewer:Node = null

func _ready() -> void:
	var cli_args = OS.get_cmdline_args()
	if "SERVER" in cli_args:
		Config.is_server = true
		local_game_button.focus_mode = Control.FOCUS_NONE
		local_game_button.disabled = true
	
	call_deferred("_load_viewer")

func _on_local_game_button_pressed():
	Config.is_local = true
	Config.is_server = false
	
	var peers = Connection.setup()
	
	if viewer != null:
		var root = get_tree().get_root()
		for c in root.get_children():
			root.remove_child(c)
		root.add_child(viewer)
		Connection.local_viewer = viewer
		for p in peers:
			viewer.add_child(p)
		Connection.server._client_connected(Connection.client.info.peer_id, null)

func _on_serve_game_button_pressed() -> void:
	pass # TODO

func _load_viewer():
	viewer = load("res://viewer.tscn").instance()



