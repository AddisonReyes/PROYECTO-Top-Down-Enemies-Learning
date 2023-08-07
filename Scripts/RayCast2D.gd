extends RayCast2D


var target: Player = null
var node = get_parent()
var can_attack = false


func _ready():
	pass


func _process(delta):
	if $Ray1.is_colliding() or $Ray2.is_colliding() or $Ray3.is_colliding() or $Ray4.is_colliding():
		can_attack = false
		if $Ray1.get_collider() is Player or $Ray2.get_collider() is Player or $Ray3.get_collider() is Player or $Ray4.get_collider() is Player:
			can_attack = true
		
	else:
		can_attack = true
	
	if is_colliding():
		if get_collider() is Player:
			if can_attack:
				get_parent().get_parent().AttackRayCast = true
			
			else:
				get_parent().get_parent().AttackRayCast = false
			
		else:
			get_parent().get_parent().AttackRayCast = false
		
	else:
		get_parent().get_parent().AttackRayCast = false
