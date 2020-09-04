extends PanelContainer
class_name PlayerStatus

signal color_set
signal name_set

const color_button_preload := preload("res://viewer/player_status/color_button.tscn")

onready var arrow = find_node("arrow") as TextureRect
onready var player_color_button = find_node("player_color_button") as Button
onready var player_name = find_node("player_name") as ToolButton
onready var name_popup = find_node("name_popup") as Popup
onready var name_entry = find_node("name_entry") as LineEdit
onready var color_popup = find_node("color_popup") as Popup
onready var color_popup_buttons = find_node("color_popup_buttons")

var non_hover_style:StyleBoxFlat
var hover_style:StyleBoxFlat

func _ready() -> void:
	set_active(false)
	
#	color_popup.popup(get_global_rect()) # TODO remove
	
	for c in Palette.avail_colors.keys():
		var color := Palette.avail_colors[c] as Color
		var new_color_button = color_button_preload.instance()
		new_color_button.connect("pressed", self, "_on_color_button_pressed", [c])
		color_popup_buttons.add_child(new_color_button)
		new_color_button.set_color(color)
	
	non_hover_style = (player_color_button.get('custom_styles/normal') as StyleBoxFlat).duplicate()
	hover_style = (player_color_button.get('custom_styles/hover') as StyleBoxFlat).duplicate()
	
	player_color_button.connect("pressed", self, "_on_player_color_button_pressed")

func set_color(color:Color)->void:
	hover_style.bg_color = color
	non_hover_style.bg_color = color
	for s in ["normal", "disabled", "focus", "pressed"]:
		player_color_button.set("custom_styles/%s" % s, non_hover_style)
	player_color_button.set("custom_styles/hover", hover_style)

func set_active(active:bool):
	if active:
		arrow.self_modulate = Color.white
	else:
		arrow.self_modulate = Color(0)

func set_enabled(enabled:bool):
	player_name.disabled = not enabled
	player_color_button.disabled = not enabled

func _on_color_button_pressed(color_id:int):
	color_popup.hide()
	emit_signal("color_set", Palette.avail_colors[color_id] as Color)

func _on_player_color_button_pressed():
	color_popup.popup(get_global_rect())

func _on_player_name_pressed():
	name_popup.popup(get_global_rect())
	name_entry.text = player_name.text
	name_entry.select_all()

func _on_LineEdit_text_entered(new_text):
	player_name.text = new_text
	player_name.release_focus()
	name_popup.hide()
	emit_signal("name_set", new_text)


