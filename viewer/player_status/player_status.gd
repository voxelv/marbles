extends PanelContainer
class_name PlayerStatus

signal color_set
signal name_set

onready var arrow = find_node("arrow") as TextureRect
onready var color_picker = find_node("color_picker") as ColorPickerButton
onready var player_name = find_node("player_name") as ToolButton
onready var name_popup = find_node("name_popup") as Popup
onready var name_entry = find_node("name_entry") as LineEdit

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

func _on_player_name_pressed():
	name_popup.popup(get_global_rect())
	name_entry.text = player_name.text
	name_entry.select_all()

func _on_LineEdit_text_entered(new_text):
	player_name.text = new_text
	player_name.release_focus()
	name_popup.visible = false
	emit_signal("name_set", new_text)


