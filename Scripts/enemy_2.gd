extends CharacterBody2D
class_name Enemy2

@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
const ArrowPath = preload("res://Scenes/arrow.tscn")

const SPEED = 167.5
var player_position
var target_position
var state = "Idle"
var player

var lookingRight = true
var lookingDown = true

var health = 30
var damageRange = 10
var damageMelee = 5

var can_shoot = true
var fireRate = 1

var red = 255 / 255
var green = 89 / 255
var blue = 110 / 255
var alpha = 255 / 255

var color = Color(red, green, blue, alpha)
var defaultColor = Color(1, 1, 1, 1)


func _ready():
	player = get_parent().get_node("Player")
	deactivate_shield()


func _physics_process(delta):
	if state == "Idle":
		if lookingDown:
			$Anims.play("Idle")
		else:
			$Anims.play("Idle2")
			
		$Node2D.rotation = 0
	
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
	
	if state == "AttackRange":
		player_position = player.position
		$Node2D.look_at(player_position)
		
		if lookingDown:
			$Anims.play("Idle")
		else:
			$Anims.play("Idle2")
		
		if can_shoot:
			shoot()
	
	if state == "ShieldRange":
		if lookingDown:
			$Anims.play("Idle")
		else:
			$Anims.play("Idle2")
			
		player_position = player.position
		$Shield.look_at(player_position)
	
	if state == "Killed":
		queue_free()


func _process(delta):
	pass


func take_damage(damage):
	if health <= 0:
		state = "Killed"
	
	if state == "Idle":
		state = "Chase"

	if state != "ShieldRange":
		self.modulate = color
		health -= damage
		$Timer.start()


func shoot():
	var arrow = ArrowPath.instantiate()
	get_parent().add_child(arrow)
	
	arrow.position = $Node2D/Marker2D.global_position
	arrow.direction = $Node2D/direction.global_position
	arrow.arrowVelocity = player.position - arrow.position
	arrow.damage = damageRange
	
	can_shoot = false
	$FireRate.wait_time = fireRate
	$FireRate.start()


func deactivate_shield():
	$Shield.deactivate_shield()


func activate_shield():
	$Shield.activate_shield()


func makepath() -> void:
	nav_agent.target_position = player.position


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
		state = "ShieldRange"
		activate_shield()


func _on_melee_range_body_exited(body):
	if body == player and state == "ShieldRange":
		state = "AttackRange"
		deactivate_shield()


func _on_fire_rate_timeout():
	can_shoot = true


func _on_navegation_timer_timeout():
	if state != "AttackRange" or "ShieldRange":
		makepath()


func _on_timer_timeout():
	self.modulate = defaultColor
