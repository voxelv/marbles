extends Node

enum marble_color {BLACK, BLUE, CYAN, GREEN, MAGENTA, RED, WHITE, YELLOW}

const marble_preload = preload("res://board/marble.tscn")
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

func marble(marble_color:int)->Spatial:#		var new_marble = marble_preload.instance()
	var new_marble = marble_preload.instance()
	var mesh_instance = new_marble.find_node("MeshInstance")
	mesh_instance.mesh = mesh_instance.mesh.duplicate()
	mesh_instance.mesh.material = materials[marble_color]
	return new_marble
