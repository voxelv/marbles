extends Spatial

enum marble_color {BLACK, BLUE, CYAN, GREEN, MAGENTA, RED, WHITE, YELLOW}

const marble_preload = preload("res://marble.tscn")
const materials = [
	preload("res://marble_materials/black.tres"),
	preload("res://marble_materials/blue.tres"),
	preload("res://marble_materials/cyan.tres"),
	preload("res://marble_materials/green.tres"),
	preload("res://marble_materials/magenta.tres"),
	preload("res://marble_materials/red.tres"),
	preload("res://marble_materials/white.tres"),
	preload("res://marble_materials/yellow.tres")
]

onready var center := (find_node("center") as Spatial).to_global(Vector3.ZERO)

onready var a_home_row := (find_node("a_home_row") as Spatial).to_global(Vector3.ZERO)
onready var b_home_row := (find_node("b_home_row") as Spatial).to_global(Vector3.ZERO)
onready var c_home_row := (find_node("c_home_row") as Spatial).to_global(Vector3.ZERO)
onready var d_home_row := (find_node("d_home_row") as Spatial).to_global(Vector3.ZERO)

onready var main_track_section := find_node("main_track_section")

var main_track = []

func _ready() -> void:
	randomize()
	trecurse(main_track_section)
	for p in main_track:
		var new_marble = marble_preload.instance()
		new_marble.translate(p.to_global(Vector3.ZERO))
		var mesh_instance = new_marble.find_node("MeshInstance")
		mesh_instance.mesh = mesh_instance.mesh.duplicate()
		mesh_instance.mesh.material = materials[randi() % materials.size()]
		self.add_child(new_marble)
	pass

func trecurse(node):
	for N in node.get_children():
		if N.name == "positions":
			put_positions(N)
		elif N.get_child_count() > 0:
			trecurse(N)

func put_positions(node):
	for c in node.get_children():
		positions.append(c)
