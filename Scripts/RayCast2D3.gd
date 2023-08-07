extends RayCast2D


var target: Player = null
var node = get_parent()


func _ready():
	pass


func _process(delta):
	if is_colliding():
		if get_collider() is Player:
			get_parent().get_parent().RayCast3 = true
		
		else:
			get_parent().get_parent().RayCast3 = false
		
	else:
		get_parent().get_parent().RayCast3 = false
