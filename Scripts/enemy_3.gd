extends CharacterBody2D
class_name Enemy3

@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var player = get_parent().get_node("Player")
const ArrowPath = preload("res://Scenes/arrow.tscn")

const SPEED = 150.0
var state = "Idle"

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
var canAttack = false

#neural network variables
var i_see_the_player = 0
var attack_range = 0
var melee_range = 0
var run_range = 0

#neural_network(attack_range, i_see_the_player, sigmoid(-health), melee_range, run_range)
var weights = [[0.1, 0.1, 0.9, 0.2, 0.1], #Idle weights
			   [0.3, 0.4, 0.1, 0.1, 0.1], #Chase weights
			   [0.5, 0.2, 0.8, 0.1, 0.9], #Run weights
			   [0.8, 0.4, -0.2, 0.1, 0.1], #AttackRange weights
			   [0.1, 0.3, 0.1, 0.9, 0.4]] #AttackMelee weights
var bias = [0.2, 0.2, 0.2, 0.1, 0.1]


func _ready():
	healthBar = $HealthBar
	healthBar.max_value = maxHealth


func _physics_process(delta):
	$RayCastsAttack.look_at(player.position)
	$RayCastsChase.look_at(player.position)
	update_health()
	
	if RayCast1 or RayCast2 or RayCast3:
		i_see_the_player = 1
		
	else:
		if ClockStarted != true:
			$ChaseTimer.start()
			ClockStarted = true
	
	if AttackRayCast:
		attack_range = 1
		
	else:
		attack_range = 0
	
	neural_network(attack_range, i_see_the_player, sigmoid(-health), melee_range, run_range)
	update_state()


func neural_network(attack_range, player_seen, health, melee_range, run_range):
	var outputs = [0, 0, 0, 0, 0]
	
	for i in range(0, len(weights)):
		outputs[i] = calculate_output(attack_range, player_seen, health, melee_range, run_range, weights[i], bias[i])
		#print(weights,": ",outputs[i],"\n")
	
	var max_output = outputs[0]
	var max_index = 0
	
	for i in range(1, outputs.size()):
		if outputs[i] > max_output:
			max_output = outputs[i]
			max_index = i
	
	var next_state
	if max_index == 0: next_state = "Idle"
	elif max_index == 1: next_state = "Chase"
	elif max_index == 2: next_state = "Run"
	elif max_index == 3: next_state = "AttackRange"
	else: next_state = "AttackMelee"

	if next_state != state:
		state = next_state
		#print(next_state)


func sigmoid(x):
	return 1 / (1 + exp(-x))


func calculate_output(attack_range, player_seen, health, melee_range, run_range, weights, bias):
	var input = attack_range * weights[0] + player_seen * weights[1] + health * weights[2] + melee_range * weights[3] + run_range * weights[4] + bias
	return sigmoid(input)


func update_state():
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
		if canAttack:
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


func _process(delta):
	pass


func take_damage(damage):
	if i_see_the_player == 0:
		i_see_the_player = 1
	
	if health <= 0:
		queue_free()

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


func _on_melee_range_body_entered(body):
	if body == player:
		canAttack = true
		melee_range = 1


func _on_melee_range_body_exited(body):
	if body == player:
		canAttack = false
		melee_range = 0


func _on_fire_rate_timeout():
	can_shoot = true


func _on_navegation_timer_timeout():
	makepath()


func _on_escape_area_body_entered(body):
	if body == player:
		run_range = 1


func _on_escape_area_body_exited(body):
	if body == player:
		run_range = 0


func _on_timer_timeout():
	self.modulate = defaultColor


func _on_chase_timer_timeout():
	i_see_the_player = 0
	ClockStarted = false
	ForceIdle = true


func _on_heal_timer_timeout():
	self.modulate = defaultColor
	canHealAgain = true
