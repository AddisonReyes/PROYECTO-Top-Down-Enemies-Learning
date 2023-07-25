extends CharacterBody2D
class_name Enemy2

const ArrowPath = preload("res://Scenes/arrow.tscn")
const SPEED = 290.0
var player_position
var target_position
var state = "Idle"
var player

var health = 30
var damageRange = 10
var damageMelee = 5

var can_shoot = true
var fireRate = 1.5


func _ready():
	player = get_parent().get_node("Player")


func _physics_process(delta):
	if state == "Idle":
		pass
		
	if state == "Chase":
		player_position = player.position
		target_position = (player_position - position).normalized()
		
		if position.distance_to(player_position) > 3:
			velocity = Vector2(target_position * SPEED)
			
			move_and_slide()
			look_at(player_position)
		
	if state == "AttackRange" and can_shoot:
		$Node2D.look_at(player_position)
		shoot()
		
	if state == "AttackMelee":
		player.take_damage(damageMelee)
		
	if state == "Killed":
		queue_free()


func _process(delta):
	pass


func take_damage(damage):
	if health <= 0:
		state = "Killed"
	
	if state == "Idle":
		state = "Chase"

	health -= damage


func shoot():
	var arrow = ArrowPath.instantiate()
	get_parent().add_child(arrow)
	
	arrow.position = $Node2D/Marker2D.global_position
	arrow.arrowVelocity = player.position - arrow.position
	arrow.damage = damageRange
	
	can_shoot = false
	$FireRate.wait_time = fireRate
	$FireRate.start()


func _on_area_2d_body_entered(body):
	if body == player and state == "Idle":
		state = "Chase"


func _on_area_2d_body_exited(body):
	if body == player and state == "Chase":
		state = "Idle"


func _on_attack_range_body_entered(body):
	if body == player and state == "Chase":
		state = "AttackRange"


func _on_attack_range_body_exited(body):
	if body == player and state == "AttackRange":
		state = "Chase"


func _on_melee_range_body_entered(body):
	if body == player and state == "AttackRange":
		state = "AttackMelee"


func _on_melee_range_body_exited(body):
	if body == player and state == "AttackMelee":
		state = "AttackRange"


func _on_fire_rate_timeout():
	can_shoot = true
