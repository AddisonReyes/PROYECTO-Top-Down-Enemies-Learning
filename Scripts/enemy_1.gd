extends CharacterBody2D
class_name Enemy1


@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var player = get_parent().get_node("Player")

const SPEED = 185.5
var state = "Idle"

var lookingRight = true
var lookingDown = true

var health = 30
var damage = 10


func _physics_process(delta):
	if state == "Idle":
		if lookingDown:
			$Anims.play("Idle")
		else:
			$Anims.play("Idle2")
	
	if state == "Chase":
		var dir = to_local(nav_agent.get_next_path_position()).normalized()
		
		if dir[0] > 0: lookingRight = true
		else: lookingRight = false
		
		if dir[1] > 0: lookingDown = true
		else: lookingDown = false
		
		if lookingDown: $Anims.play("Walk")
		else: $Anims.play("Walk2")
				
		if lookingRight: $Anims.flip_h = false
		else: $Anims.flip_h = true
		
		velocity = dir * SPEED
		move_and_slide()
		
	if state == "Attack":
		player.take_damage(damage)
		
	if state == "Killed":
		queue_free()


func makepath() -> void:
	nav_agent.target_position = player.position


func take_damage(damage):
	if health <= 0:
		state = "Killed"
	
	if state == "Idle":
		state = "Chase"

	health -= damage


func _on_area_2d_body_entered(body):
	if body == player and state == "Idle":
		state = "Chase"
		makepath()


func _on_area_2d_body_exited(body):
	if body == player and state == "Chase":
		state = "Idle"


func _on_attack_range_body_entered(body):
	if body == player and state == "Chase":
		state = "Attack"


func _on_attack_range_body_exited(body):
	if body == player and state == "Attack":
		state = "Chase"
		makepath()


func _on_navegation_timer_timeout():
	if state != "Attack":
		makepath()
