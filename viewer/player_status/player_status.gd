extends PanelContainer

onready var arrow = find_node("arrow") as TextureRect

func _ready() -> void:
	set_active(false)

func set_active(active:bool):
	if active:
		arrow.self_modulate = Color.white
	else:
		arrow.self_modulate = Color(0)

