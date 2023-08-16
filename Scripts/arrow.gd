extends CharacterBody2D


var arrowVelocity = Vector2(0, 0)
var direction = Vector2(0, 0)
var orientation_fixed = true
var playerKiled = false
var damage = 5
var speed = 500

var disableFitness = false
var parent


func _ready():
	$Timer.start()


func _physics_process(delta):
	var collision_info = move_and_collide(arrowVelocity.normalized() * delta * speed)
	
	if orientation_fixed:
		look_at(direction)
		orientation_fixed = false


func _process(delta):
	pass


func _on_timer_timeout():
	queue_free()


func _on_area_2d_body_entered(body):
	if body is Enemy1 or body is Enemy2 or body is Enemy3:
		body.take_damage(damage)
		if disableFitness:
			body.disableFitness = disableFitness
	
	if body is Player:
		playerKiled = body.take_damage(damage)
		
		if parent is Player:
			queue_free()
			return
			
		parent.damageToPlayer += damage
			
		if playerKiled:
			parent.IKillThePlayer = true
	
	queue_free()
