extends CharacterBody2D


const SPEED = 325.0
var player_position
var target_position
var state = "Idle"
var player

var health = 30
var damage = 10


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
		
	if state == "Attack":
		player.take_damage(damage)


func _process(delta):
	pass

func _on_area_2d_body_entered(body):
	if body == player and state == "Idle":
		state = "Chase"


func _on_area_2d_body_exited(body):
	if body == player and state == "Chase":
		state = "Idle"


func _on_attack_range_body_entered(body):
	if body == player and state == "Chase":
		state = "Attack"


func _on_attack_range_body_exited(body):
	if body == player and state == "Attack":
		state = "Chase"
