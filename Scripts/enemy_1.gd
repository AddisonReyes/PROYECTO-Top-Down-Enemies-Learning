extends CharacterBody2D
class_name Enemy1


@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var player = get_parent().get_node("Player")
var rng = RandomNumberGenerator.new()

const SPEED = 185.5
var state = "Idle"

var lookingRight = true
var lookingDown = true

var alive = true
var maxHealth = 30
var health = maxHealth
var damage = 10

var healthBar
var healPoints = 5
var canHealAgain = true

var damageColor = Color(1, 0, 0, 1)
var healColor = Color(0, 1, 0, 1)
var defaultColor = Color(1, 1, 1, 1)

var RayCast1 = false
var RayCast2 = false
var RayCast3 = false

var ClockStarted = false
var canAttack = false
var canChase = false

#neural network variables
var i_see_the_player = 0
var attack_range = 0

var mutation_rate = 0.5

var generation
var weights
var bias

var timeAlive = 0
var IKillThePlayer = false
var damageToPlayer = 0


func _ready():
	healthBar = $HealthBar
	healthBar.max_value = maxHealth
	
	load_data()
	mutation()


func _physics_process(delta):
	if alive:
		$RayCasts.look_at(player.position)
		update_health()
		
		if RayCast1 or RayCast2 or RayCast3:
			i_see_the_player = 1
			canChase = true
			
		else:
			if ClockStarted != true:
				$ChaseTimer.start()
				ClockStarted = true
		
		neural_network(attack_range, i_see_the_player, sigmoid(-health))
		update_state()
		
		#print(timeAlive)
		if IKillThePlayer:
			self.modulate =  Color(1, 1, 0, 1)


func neural_network(attack_range, player_seen, health):
	var outputs = [0, 0, 0, 0] # Índice 0: Idle, Índice 1: Chase, Índice 2: Attack
	
	for i in range(0, len(weights)):
		outputs[i] = calculate_output(attack_range, player_seen, health, weights[i], bias[i])
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
	else: next_state = "Attack"

	if next_state != state:
		state = next_state
		#print(next_state)


func sigmoid(x):
	return 1 / (1 + exp(-x))


func calculate_output(attack_range, player_seen, health, weights, bias):
	var input = attack_range * weights[0] + player_seen * weights[1] + health * weights[2] + bias
	return sigmoid(input)


func update_state():
	if state == "Idle":
		if canHealAgain:
			heals(healPoints)
			
		if lookingDown:
			$Anims.play("Idle")
		else:
			$Anims.play("Idle2")
	
	if state == "Run":
		var target_position = (player.position - position).normalized()

		if position.distance_to(player.position) > 3:
			var new_position = Vector2(-target_position.x, -target_position.y)
			velocity = Vector2(new_position * SPEED)

			move_and_slide()
	
	if state == "Chase" and canChase:
		makepath()
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
		if canAttack:
			IKillThePlayer = player.take_damage(damage)
			damageToPlayer += damage
			
		if lookingDown:
			$Anims.play("Idle")
		else:
			$Anims.play("Idle2")


func makepath() -> void:
	nav_agent.target_position = player.position


func take_damage(damage):
	if canChase == false:
		canChase = true
		
	if i_see_the_player == 0:
		i_see_the_player = 1
	
	if health <= 0:
		death()

	health -= damage
	self.modulate = damageColor
	$Timer.start()


func death():
	$CollisionShape2D.queue_free()
	alive = false
	
	self.hide()


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


func mutation():
	var num = rng.randf_range(0.0, 1.0)
	if num < mutation_rate:
		#print("\n\nAntes: \nPesos: ",weights, "\nBias: ", bias)
		
		var state = rng.randf_range(0, len(weights))
		var weight = rng.randf_range(0, len(weights[state]))
		weights[state][weight] = rng.randf_range(-0.9, 0.9)
		
		var bias_pos = rng.randf_range(0, len(bias))
		bias[bias_pos] = rng.randf_range(-0.9, 0.9)
		
		#print("\nDespues: \nPesos: ",weights, "\nBias: ", bias)


func fitness():
	var points = 0
	
	points += timeAlive
	points += damageToPlayer * 3
	if IKillThePlayer:
		points += 1600
	
	return points


func load_data():
	var file = FileAccess.open("res://Variables/Enemy_1_data.dat", FileAccess.READ)
	var data = file.get_var()
	
	generation = data["Generation"]
	weights = data["Weights"]
	bias = data["Bias"]
	
	#print(data)


func _on_attack_range_body_entered(body):
	if body == player:
		canAttack = true
		attack_range = 1


func _on_attack_range_body_exited(body):
	if body == player:
		canAttack = false
		attack_range = 0
		makepath()


func _on_navegation_timer_timeout():
	if state != "Attack":
		makepath()


func _on_timer_timeout():
	self.modulate = defaultColor


func _on_chase_timer_timeout():
	i_see_the_player = 0
	canChase = false


func _on_heal_timer_timeout():
	self.modulate = defaultColor
	canHealAgain = true


func _on_time_alive_timeout():
	if alive:
		timeAlive += 1
	
	if health <= 0:
		$timeAlive.autostart = false
