extends Node

onready var board_viewport := find_node("board_viewport") as Viewport

func _ready():
	
	get_viewport().connect("size_changed", self, "_root_viewport_size_changed")

func _root_viewport_size_changed():
#	var dim := 0
#	dim = min(get_viewport().size.x, get_viewport().size.y)
#	board_viewport.size = Vector2.ONE * dim
	pass
