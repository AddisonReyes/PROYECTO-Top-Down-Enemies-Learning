extends CharacterBody2D
class_name Enemy3

@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
const ArrowPath = preload("res://Scenes/arrow.tscn")
const SPEED = 150.0
var state = "Idle"
var player

var player_position
var target_position

var lookingRight = true
var lookingDown = true

var maxHealth = 20
var health = maxHealth
var damageRange = 15
var damageMelee = 5

var healthBar
var healPoints = 5
var canHealAgain = true

var can_shoot = true
var fireRate = 0.9

var damageColor = Color(1, 0, 0, 1)
var healColor = Color(0, 1, 0, 1)
var defaultColor = Color(1, 1, 1, 1)

var AttackRayCast = false
var RayCast1 = false
var RayCast2 = false
var RayCast3 = false

var ClockStarted = false
var ForceIdle = false


func _ready():
	player = get_parent().get_node("Player")
	
	healthBar = $HealthBar
	healthBar.max_value = maxHealth


func _physics_process(delta):
	$RayCastsAttack.look_at(player.position)
	$RayCastsChase.look_at(player.position)
	update_health()
	
	if RayCast1 or RayCast2 or RayCast3:
		if state == "Idle":
			state = "Chase"
		
		ForceIdle = false
		
	else:
		if ClockStarted != true:
			$ChaseTimer.start()
			ClockStarted = true
			
		if state == "Chase":
			if ForceIdle:
				state = "Idle"
	
	if AttackRayCast:
		if state == "Chase":
			state = "AttackRange"
		
	else:
		if state == "AttackRange":
			state = "Chase"
	
	if state == "Idle":
		if canHealAgain:
			heals(healPoints)
			
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
	
	if state == "AttackMelee":
		player.take_damage(damageMelee)
		
		if lookingDown:
			$Anims.play("Idle")
		else:
			$Anims.play("Idle2")
			
	if state == "Run":
		player_position = player.position
		target_position = (player_position - position).normalized()

		if position.distance_to(player_position) > 3:
			var new_position = Vector2(-target_position.x, -target_position.y)
			velocity = Vector2(new_position * SPEED)

			move_and_slide()
		
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
	self.modulate = damageColor
	$Timer.start()


func heals(healPoints):
	if health < maxHealth:
		canHealAgain = false
		health += healPoints
		
		self.modulate = healColor
		$HealTimer.start()


func update_health():
	if health >= maxHealth:
		health = maxHealth
		
	healthBar.value = health
	
	if health >= maxHealth:
		healthBar.visible = false
	
	else:
		healthBar.visible = true


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
	if body == player and state == "Run":
		state = "AttackMelee"


func _on_melee_range_body_exited(body):
	if body == player and state == "AttackMelee":
		state = "Run"


func _on_fire_rate_timeout():
	can_shoot = true


func _on_navegation_timer_timeout():
	makepath()


func _on_escape_area_body_entered(body):
	if body == player and state == "AttackRange":
		state = "Run"


func _on_escape_area_body_exited(body):
	if body == player and state == "Run":
		state = "AttackRange"


func _on_timer_timeout():
	self.modulate = defaultColor


func _on_chase_timer_timeout():
	ClockStarted = false
	ForceIdle = true


func _on_heal_timer_timeout():
	self.modulate = defaultColor
	canHealAgain = true
