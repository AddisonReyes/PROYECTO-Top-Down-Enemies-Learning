extends Node2D


var HealthPoints = 25


func _ready():
	$Heart.play("default")


func _process(delta):
	pass


func _on_area_2d_body_entered(body):
	if body is Player:
		body.heals(HealthPoints)
	
	queue_free()
