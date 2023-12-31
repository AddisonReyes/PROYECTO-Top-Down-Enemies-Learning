extends CharacterBody2D
class_name Player


const ArrowPath = preload("res://Scenes/arrow.tscn")

const PIXELS_TO_MOVE = 1.6
const TP_MULTIPLIER = 46
const SPEED = 110.0
var can_tp = true

var lookingRight = true
var lookingDown = true

var invulnerable = false
var alive = true
var damage = 8.6
var health = 60

var maxHealth = health
var healthBar

var can_shoot = true

var fireRate = 0.8
var TPtime = 2

var damageColor = Color(1, 0, 0, 1)
var healColor = Color(0, 1, 0, 1)
var defaultColor = Color(1, 1, 1, 1)

func _ready():
	healthBar = $HealthBar
	healthBar.max_value = maxHealth


func _physics_process(delta):
	update_health()
	
	if health <= 0 and alive:
		death()
	
	if alive:
		var direction = _player_movement()
		
		if Input.is_key_pressed(KEY_SPACE) and can_tp:
			direction = _player_teleport(direction)
		
		if direction[0]:
			velocity.x = direction[0] * SPEED
			
			if direction[0] == PIXELS_TO_MOVE: lookingRight = true
			else: lookingRight = false
			
			$Anims.play("Walk")
			if lookingRight:
				$Anims.flip_h = false
				
			else:
				$Anims.flip_h = true
		
		else: 
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
		if direction[1]:
			velocity.y = direction[1] * SPEED
			
			if direction[1] == PIXELS_TO_MOVE: lookingDown = true
			else: lookingDown = false
				
			if lookingDown:
				$Anims.play("Walk")
				
			else:
				$Anims.play("Walk2")
		
		else: 
			velocity.y = move_toward(velocity.y, 0, SPEED)
		
		$Arco.look_at(get_global_mouse_position())
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_shoot:
			singleShoot()
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and can_shoot:
			multiShoot()
		
		if direction[0] == 0 and direction[1] == 0:
			if lookingDown:
				$Anims.play("Idle")
			else:
				$Anims.play("Idle2")

		move_and_slide()


func take_damage(damage):
	if invulnerable != true and alive:
		$PlayerHurt.play()
		self.modulate = damageColor
		health -= damage
		
		invulnerable = true
		$InvulnerableTimer.start()
		
		if health <= 0:
			return true
		
		else:
			return false


func death():
	$Arco.hide()
	
	$PlayerDeath.play()
	$Anims.play("Death")
	alive = false


func heals(healPoints):
	if health < maxHealth:
		$Heal.play()
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


func singleShoot():
	$bow.play()
	var arrow = ArrowPath.instantiate()
	get_parent().add_child(arrow)
		
	arrow.parent = self
	arrow.disableFitness = true
	arrow.position = $Arco/Node2D/Marker2D.global_position
	arrow.direction = $Arco/Node2D/direction.global_position
	arrow.arrowVelocity = $Arco/Marker2D.global_position - arrow.position
	arrow.damage = damage * 2
	
	can_shoot = false
	$FireRate.wait_time = fireRate
	$FireRate.start()

func multiShoot():
	$bow.play()
	var arrow1 = ArrowPath.instantiate()
	var arrow2 = ArrowPath.instantiate()
	var arrow3 = ArrowPath.instantiate()
		
	var arrows = [arrow1, arrow2, arrow3]
	var arrowsPositions = [$Arco/Node2D/Marker2D.global_position, $Arco/Node2D2/Marker2D.global_position, $Arco/Node2D3/Marker2D.global_position]
	var arrowsDirections = [$Arco/Node2D/direction.global_position, $Arco/Node2D2/direction.global_position, $Arco/Node2D3/direction.global_position]
		
	for i in range(3):
		get_parent().add_child(arrows[i])
		arrows[i].parent = self
		arrows[i].position = arrowsPositions[i]
		arrows[i].direction = arrowsDirections[i]
		arrows[i].arrowVelocity = $Arco/Marker2D.global_position - arrows[i].position
		arrows[i].damage = damage
	
	can_shoot = false
	$FireRate.wait_time = fireRate *  2
	$FireRate.start()


func _player_teleport(direction):
	can_tp = false
	
	if direction[0] or direction[1]: 
		if direction[0]:
			var tp_movement = direction[0] * TP_MULTIPLIER
			direction[0] += tp_movement
			
		if direction[1]:
			var tp_movement = direction[1] * TP_MULTIPLIER
			direction[1] += tp_movement
	
	elif direction[0] and direction[1]:
		var tp_movement1 = direction[0] * TP_MULTIPLIER
		var tp_movement2 = direction[1] * TP_MULTIPLIER
		
		direction[0] += tp_movement1/2
		direction[1] += tp_movement2/2
		
	else:
		pass
	
	$TP.play()
	$TPTimer.wait_time = TPtime
	$TPTimer.start()
	return direction


func _player_movement():
	var directionx = 0
	var directiony = 0
	
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): 
		directionx = -PIXELS_TO_MOVE
		if Input.is_key_pressed(KEY_SHIFT):
			directionx = -PIXELS_TO_MOVE/2
			
	elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): 
		directionx = PIXELS_TO_MOVE
		if Input.is_key_pressed(KEY_SHIFT):
			directionx = PIXELS_TO_MOVE/2
			
	else: directionx = 0
		
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): 
		directiony = -PIXELS_TO_MOVE
		if Input.is_key_pressed(KEY_SHIFT):
			directiony = -PIXELS_TO_MOVE/2
			
	elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): 
		directiony = PIXELS_TO_MOVE
		if Input.is_key_pressed(KEY_SHIFT):
			directiony = PIXELS_TO_MOVE/2
			
	else: directiony = 0
	
	var direction = [directionx, directiony]
	return direction


func _on_timer_timeout():
	can_tp = true


func _on_invulnerable_timer_timeout():
	self.modulate = defaultColor
	invulnerable = false


func _on_fire_rate_timeout():
	can_shoot = true


func _on_heal_timer_timeout():
	self.modulate = defaultColor
