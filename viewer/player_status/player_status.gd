extends PanelContainer
class_name PlayerStatus

signal color_set

onready var arrow = find_node("arrow") as TextureRect
onready var color_picker = find_node("color_picker") as ColorPickerButton
onready var player_name = find_node("player_name") as ToolButton

func _ready() -> void:
	set_active(false)
	
	color_picker.connect("color_changed", self, "_color_set")

func set_active(active:bool):
	if active:
		arrow.self_modulate = Color.white
	else:
		arrow.self_modulate = Color(0)

func _color_set(color:Color):
	emit_signal("color_set", color)
