extends Node

onready var status_label := find_node("status_label") as Label

var colors := []

func _ready() -> void:
	for c in "abcd":
		colors.append(find_node("%s_color" % c) as ColorRect)

func _process(delta: float) -> void:
	if Connection.server != null:
		status_label.text = {
			Logic.game_phase.INIT: 		"INIT",
			Logic.game_phase.STARTED: 	"STARTED",
			Logic.game_phase.COUNT: 	"INVALID..."
		}[Connection.server.state.game_phase]
		
		for i in range(Logic.player.COUNT):
			var found := false
			for id in Connection.server.clients.keys():
				if Connection.server.clients[id].player == i:
					found = true
			if found:
				(colors[i] as ColorRect).color = Color.green
			else:
				(colors[i] as ColorRect).color = Color.red








