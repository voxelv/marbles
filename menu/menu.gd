extends Node

onready var local_game_button := find_node("local_game_button") as Button
onready var text_output := find_node("text_output") as TextEdit

var viewer:Node = null
var _peers := []

func _ready() -> void:
	var cli_args = OS.get_cmdline_args()
	if "SERVER" in cli_args:
		print("I am SERVER...")
		Config.is_server = true
		Config.is_local = false
		local_game_button.disabled = true
		_on_serve_game_button_pressed()
	else:
		call_deferred("_load_viewer")

func _load_viewer():
	viewer = load("res://viewer/viewer.tscn").instance()
	local_game_button.disabled = false

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
		queue_free()

func _on_join_game_button_pressed() -> void:
	Config.is_local = false
	Config.is_server = false
	
	var peers = Connection.setup()
	
	if viewer != null:
		var root = get_tree().get_root()
		root.add_child(viewer)
		Connection.local_viewer = viewer
		for p in peers:
			viewer.add_child(p)
		queue_free()

func _on_serve_game_button_pressed() -> void:
	Config.is_local = false
	Config.is_server = true
	OS.set_window_title("[SERVER]")
	var serve_game_load = load("res://menu/serve_game/serve_game.tscn")
	
	_peers = Connection.setup()
	call_deferred("_add_peers_to_root")
	
	get_tree().change_scene_to(serve_game_load)

func _add_peers_to_root():
	for p in _peers:
		get_tree().get_root().add_child(p)


