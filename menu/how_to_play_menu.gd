extends VBoxContainer

@onready @export_node_path(TabContainer) var how_to_play_tabs_path
@onready @export_node_path(Label) var page_counter_path

@onready var how_to_play_tabs:TabContainer = get_node(how_to_play_tabs_path)
@onready var page_counter:Label = get_node(page_counter_path)

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
