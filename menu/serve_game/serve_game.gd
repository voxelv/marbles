extends Node

onready var status_label := find_node("status_label") as Label

var statuses := []
var colors := []

func _ready() -> void:
	for c in "abcd":
		statuses.append(find_node("%s_status" % c) as Label)
		colors.append(find_node("%s_color" % c) as ColorRect)

func _process(delta: float) -> void:
	status_label.text = {
		Logic.game_phase.INIT: "Game: INIT",
		Logic.game_phase.STARTED: "Game: STARTED",
		Logic.game_phase.COUNT: "INVALID..."
	}[Connection.server.state.game_phase]
	
	for i in range(Logic.player.COUNT):
		var found := false
		for id in Connection.server.clients.keys():
			if Connection.server.clients[id].player == i:
				found = true
		if found:
			statuses[i].text = "ONLINE"
			(colors[i] as ColorRect).color = Color.green
		else:
			statuses[i].text = "OFFLINE"
			(colors[i] as ColorRect).color = Color.red








