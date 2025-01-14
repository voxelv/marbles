extends VBoxContainer

@onready var how_to_play_tabs = %how_to_play_tabs
@onready var page_counter = %page_counter

func _ready():
	update_page_counter()

func update_page_counter():
	page_counter.text = "{current}/{max}".format({
		"current": how_to_play_tabs.current_tab+1, 
		"max": how_to_play_tabs.get_child_count()
		})

func _on_Previous_pressed():
	var tab = how_to_play_tabs.current_tab - 1
	if tab >= 0:
		how_to_play_tabs.current_tab = tab
	update_page_counter()

func _on_Next_pressed():
	var tab = how_to_play_tabs.current_tab + 1
	if tab < how_to_play_tabs.get_child_count():
		how_to_play_tabs.current_tab = tab
	update_page_counter()
