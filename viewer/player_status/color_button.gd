extends Button

var hover_style:StyleBoxFlat
var non_hover_style:StyleBoxFlat

func _ready() -> void:
	hover_style = (get("custom_styles/hover") as StyleBoxFlat).duplicate()
	non_hover_style = (get("custom_styles/normal") as StyleBoxFlat).duplicate()

func set_color(color:Color):
	hover_style.bg_color = color
	non_hover_style.bg_color = color
	for s in ["normal", "disabled", "focus", "pressed"]:
		self.set("custom_styles/%s" % s, non_hover_style)
	self.set("custom_styles/hover", hover_style)
	
