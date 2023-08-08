extends CharacterBody2D
class_name Enemy1


@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var player = get_parent().get_node("Player")

const SPEED = 185.5
var state = "Idle"

var lookingRight = true
var lookingDown = true

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
var ForceIdle = false


func _ready():
	healthBar = $HealthBar
	healthBar.max_value = maxHealth


func _physics_process(delta):
	$RayCasts.look_at(player.position)
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
	
	if state == "Idle":
		if canHealAgain:
			heals(healPoints)
			
		if lookingDown:
			$Anims.play("Idle")
		else:
			$Anims.play("Idle2")
	
	if state == "Chase":
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


func _on_timer_timeout():
	self.modulate = defaultColor


func _on_chase_timer_timeout():
	ClockStarted = false
	ForceIdle = true


func _on_heal_timer_timeout():
	self.modulate = defaultColor
	canHealAgain = true
