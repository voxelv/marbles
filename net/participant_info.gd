class_name ParticipantInfo

var id := Logic.player.COUNT as int
var name := ""
var color_id := Palette.color.GRAY as int

func fmt()->Dictionary:
	return({'id': self.id, 'name': self.name, 'color_id': self.color_id})

func defmt(data:Dictionary)->void:
	assert(data != null)
	assert('id' in data)
	assert('name' in data)
	assert('color_id' in data)

func copy(other:ParticipantInfo)->void:
	self.defmt(other.fmt())
