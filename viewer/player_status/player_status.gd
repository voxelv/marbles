extends PanelContainer
class_name PlayerStatus

signal color_set
signal name_set

const color_button_preload := preload("res://viewer/player_status/color_button.tscn")
const hover_style := preload("res://viewer/player_status/hover_style.tres")
const normal_style := preload("res://viewer/player_status/normal_style.tres")

onready var arrow = find_node("arrow") as TextureRect
onready var player_color = find_node("player_color") as ColorRect
onready var player_name = find_node("player_name") as Label
onready var color_popup = find_node("color_popup") as Popup
onready var color_popup_buttons = find_node("color_popup_buttons")

var enabled := false

func _ready() -> void:
	set_active(false)

func set_color(color:Color)->void:
	player_color.color = color

func set_active(active:bool):
	if active:
		arrow.self_modulate = Color.white
	else:
		arrow.self_modulate = Color(0)

func set_enabled(enabled:bool):
	self.enabled = enabled

func set_name(name_str:String):
	player_name.text = name_str

func _on_color_button_pressed(color_id:int):
	color_popup.hide()
	emit_signal("color_set", color_id)

func _on_player_color_button_pressed():
	color_popup.popup(get_global_rect())
	
	# Remove previous color buttons
	for b in color_popup_buttons.get_children():
		(b as Node).queue_free()
	
	# Set color buttons
	for c in Palette.avail_colors.keys():
		var color := Palette.avail_colors[c] as Color
		
		# Gather used colors
		var used_colors := []
		for player in range(Logic.player.COUNT):
			used_colors.append(Connection.local_viewer.state.custom_clients[player].color_id)
		
		if not c in used_colors:
			var new_color_button = color_button_preload.instance()
			new_color_button.connect("pressed", self, "_on_color_button_pressed", [c])
			color_popup_buttons.add_child(new_color_button)
			new_color_button.set_color(color)

func _on_button_pressed() -> void:
	_on_player_color_button_pressed()
