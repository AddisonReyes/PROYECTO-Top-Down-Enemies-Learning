extends Node2D
class_name Shield

var health = 60

func _ready():
	deactivate_shield()


func _process(delta):
	pass


func take_damage(damage):
	if health <= 0:
		queue_free()

	health -= damage
	print("PLAAA")


func activate_collision():
	$CharacterBody2D/CollisionShape2D.disabled = false


func deactivate_collision():
	$CharacterBody2D/CollisionShape2D.disabled = true


func deactivate_shield():
	pass
	#self.visible = false


func activate_shield():
	pass
	#self.visible = true
