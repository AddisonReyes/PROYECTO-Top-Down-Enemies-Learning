extends CharacterBody2D
class_name Enemy2

@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var player = get_parent().get_node("Player")
const ArrowPath = preload("res://Scenes/arrow.tscn")
const HeartPath = preload("res://Scenes/heart.tscn")
var rng = RandomNumberGenerator.new()

const SPEED = 170.5
var player_position
var target_position
var state = "Idle"

var lookingRight = true
var lookingDown = true

var alive = true
var maxHealth = 60
var health = maxHealth
var damageRange = 15

var healthBar
var healPoints = 5
var canHealAgain = true

var can_shoot = true
var canChase = false
var fireRate = 0.9

var damageColor = Color(1, 0, 0, 1)
var healColor = Color(0, 1, 0, 1)
var defaultColor = Color(1, 1, 1, 1)

var AttackRayCast = false
var RayCast1 = false
var RayCast2 = false
var RayCast3 = false

var ClockStarted = false
var useShield = false

#neural network variables
var i_see_the_player = 0
var attack_range = 0
var melee_range = 0

var mutation_rate = 0.5
var heart_drop = 0.2

var generation
var weights
var bias

var timeAlive = 0
var IKillThePlayer = false
var damageToPlayer = 0

var disableFitness = false
var mutate = false


func _ready():
	deactivate_shield()
	
	healthBar = $HealthBar
	healthBar.max_value = maxHealth
	
	load_data()
	if mutate:
		mutation()


func _physics_process(delta):
	if alive:
		$RayCastsAttack.look_at(player.position)
		$RayCastsChase.look_at(player.position)
		$Shield.look_at(player.position)
		update_health()
		
		if RayCast1 or RayCast2 or RayCast3:
			i_see_the_player = 1
			canChase = true
			
		else:
			if ClockStarted != true:
				$ChaseTimer.start()
				ClockStarted = true
		
		if AttackRayCast:
			attack_range = 1
			
		else:
			attack_range = 0
		
		neural_network(attack_range, i_see_the_player, sigmoid(-health), melee_range)
		update_state()
		
		if IKillThePlayer:
			self.modulate =  Color(1, 1, 0, 1)


func neural_network(attack_range, player_seen, health, melee_range):
	var outputs = [0, 0, 0, 0, 0]
	
	for i in range(0, len(weights)):
		outputs[i] = calculate_output(attack_range, player_seen, health, melee_range, weights[i], bias[i])
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
	else: next_state = "ShieldRange"
	if next_state != state:
		state = next_state
		#print(next_state)


func sigmoid(x):
	return 1 / (1 + exp(-x))


func calculate_output(attack_range, player_seen, health, melee_range, weights, bias):
	var input = attack_range * weights[0] + player_seen * weights[1] + health * weights[2] + melee_range * weights[3] + bias
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
	
	if state == "Chase" and canChase:
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
	
	if state == "Run":
		var target_position = (player.position - position).normalized()

		if position.distance_to(player.position) > 3:
			var new_position = Vector2(-target_position.x, -target_position.y)
			velocity = Vector2(new_position * SPEED)

			move_and_slide()
	
	if state == "AttackRange" and player.alive:
		player_position = player.position
		$Node2D.look_at(player_position)
		
		if lookingDown:
			$Anims.play("Idle")
		else:
			$Anims.play("Idle2")
		
		if can_shoot and AttackRayCast:
			shoot()
	
	if state == "ShieldRange":
		useShield = true
		activate_shield()
		
		if lookingDown:
			$Anims.play("Idle")
		else:
			$Anims.play("Idle2")
	
	else:
		deactivate_shield()
		useShield = false


func take_damage(damage):
	$EnemyHurt.play()
	if canChase == false:
		canChase = true
		
	if i_see_the_player == 0:
		i_see_the_player = 1
	
	if health <= 0:
		death()

	self.modulate = damageColor
	health -= damage
	$Timer.start()


func death():
	$EnemyDeath.play()
	$CollisionShape2D.queue_free()
	alive = false
	
	self.hide()
	
	var num = rng.randf_range(0.0, 1.0)
	if num < heart_drop:
		var new_item = HeartPath.instantiate()
		
		new_item.position = self.position
		get_parent().add_child(new_item)


func heals(healPoints):
	if health < maxHealth:
		$Heal.play()
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
	$bow.play()
	var arrow = ArrowPath.instantiate()
	get_parent().add_child(arrow)
	
	arrow.parent = self
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
	if alive and useShield:
		$Shield.activate_shield()


func makepath() -> void:
	nav_agent.target_position = player.position


func mutation():
	var num = rng.randf_range(0.0, 1.0)
	if num < mutation_rate:
		#print("\n\nAntes: \nPesos: ",weights, "\nBias: ", bias)
		
		var state = rng.randf_range(0, len(weights))
		var weight = rng.randf_range(0, len(weights[state]))
		weights[state][weight] = rng.randf_range(-0.9, 0.9)
		
		state = rng.randf_range(0, len(weights))
		weight = rng.randf_range(0, len(weights[state]))
		weights[state][weight] = rng.randf_range(-0.9, 0.9)
		
		state = rng.randf_range(0, len(weights))
		weight = rng.randf_range(0, len(weights[state]))
		weights[state][weight] = rng.randf_range(-0.9, 0.9)
		
		var bias_pos = rng.randf_range(0, len(bias))
		bias[bias_pos] = rng.randf_range(-0.9, 0.9)
		
		#print("\nDespues: \nPesos: ",weights, "\nBias: ", bias)


func fitness():
	var points = 0
	
	if damageToPlayer == 0:
		points += timeAlive / 2
	
	else:
		points += timeAlive
		points += damageToPlayer
		
	if IKillThePlayer:
		points += 200
	
	if disableFitness:
		points = 0
	
	return points


func load_data():
	var file = FileAccess.open("res://Variables/Enemy_2_data.dat", FileAccess.READ)
	var data = file.get_var()
	
	generation = data["Generation"]
	weights = data["Weights"]
	bias = data["Bias"]
	
	#print(data)


func _on_melee_range_body_entered(body):
	if body == player:
		useShield = true
		can_shoot = false
		melee_range = 1


func _on_melee_range_body_exited(body):
	if body == player:
		useShield = false
		can_shoot = true
		melee_range = 0


func _on_fire_rate_timeout():
	can_shoot = true


func _on_navegation_timer_timeout():
	makepath()


func _on_timer_timeout():
	self.modulate = defaultColor


func _on_chase_timer_timeout():
	i_see_the_player = 0
	ClockStarted = false
	canChase = false


func _on_heal_timer_timeout():
	self.modulate = defaultColor
	canHealAgain = true


func _on_time_alive_timeout():
	if alive:
		timeAlive += 1

	if health <= 0:
		$timeAlive.autostart = false


func _on_enemy_death_finished():
	if mutate == false:
		queue_free()
