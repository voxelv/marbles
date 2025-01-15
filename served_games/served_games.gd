extends Node

const GameInfoUIPreload := preload("res://game/game_info.tscn")

func _ready():
	Connection.server.game_closed.connect(game_closed)

func _process(delta):
	if Connection.server != null:
		var games = Connection.server.get_games()
		
		var games_keys = games.keys()
		for i in range(len(games_keys)):
			var g = null
			var games_container = %game_infos_container
			if (games_container.get_child_count() - 1) < i:
				g = GameInfoUIPreload.instantiate()
				games_container.add_child(g)
				g.close_game_pressed.connect(close_game)
			else:
				g = games_container.get_child(i)
			
			var game := (games[games_keys[i]] as Game)
			g.update(game)

func _on_create_game_button_pressed():
	Connection.server.create_game()

func _on_exit_button_pressed():
	# TODO Delete all games
	get_tree().change_scene_to_file("res://menu/menu.tscn")

func close_game(game_key:String):
	Connection.server.delete_game(game_key)

func game_closed(game_key:String):
	for c in %game_infos_container.get_children():
		if c.get_key() == game_key:
			c.queue_free()
