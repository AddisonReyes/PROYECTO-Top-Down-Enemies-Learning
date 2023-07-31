extends Node2D
class_name Shield


var collision = false


func _process(delta):
	pass


func _physics_process(delta):
	if collision:
		$CharacterBody2D/CollisionShape2D.disabled = false
	
	else:
		$CharacterBody2D/CollisionShape2D.disabled = true


func deactivate_shield():
	self.visible = false
	collision = false


func activate_shield():
	self.visible = true
	collision = true
