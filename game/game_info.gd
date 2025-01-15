extends Node
class_name GameInfoUI

signal close_game_pressed

@onready var status_label := %status_label as Label
@onready var game_key_label := %game_key_label as Label

var colors := []

func _ready() -> void:
	for c in "abcd":
		colors.append(Omni.find_node(self, "%s_color" % c) as ColorRect)

func get_key() -> String:
	return game_key_label.text

func update(game:Game):
	game_key_label.text = game.game_key
	%timeout.text = "%1.0fs" % game.close_timer.get_time_left()

	
	if game.game_state != null:
		status_label.text = {
			Logic.game_phase.INIT: 		"INIT",
			Logic.game_phase.STARTED: 	"STARTED",
			Logic.game_phase.COUNT: 	"INVALID..."
		}[game.game_state.game_phase]
		
		for i in range(Logic.player.COUNT):
			var found := false
			for ci in game.players.values():
				if ci.player == i:
					found = true
			if found:
				(colors[i] as ColorRect).color = Color.GREEN
			else:
				(colors[i] as ColorRect).color = Color.RED

func _on_close_game_pressed():
	close_game_pressed.emit(game_key_label.text)
