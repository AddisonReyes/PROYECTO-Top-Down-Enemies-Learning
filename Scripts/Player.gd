extends CharacterBody2D
class_name Player


const ArrowPath = preload("res://Scenes/arrow.tscn")
const PIXELS_TO_MOVE = 1.6
const TP_MULTIPLIER = 26
const SPEED = 110.0
var can_tp = true

var lookingRight = true
var lookingDown = true

var invulnerable = false
var alive = true
var damage = 10
var health = 100

var can_shoot = true

var fireRate = 0.9
var TPtime = 2


func _physics_process(delta):
	if health <= 0 and alive:
		print("Moriste")
		alive = false
		hide()
	
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
		
		$Node2D.look_at(get_global_mouse_position())
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_shoot:
			shoot()
		
		if direction[0] == 0 and direction[1] == 0:
			if lookingDown:
				$Anims.play("Idle")
			else:
				$Anims.play("Idle2")

		move_and_slide()


func take_damage(damage):
	if invulnerable != true and alive:
		print("Te han atacado -", damage)
		health -= damage
			
		invulnerable = true
		$InvulnerableTimer.start()


func shoot():
	var arrow = ArrowPath.instantiate()
	get_parent().add_child(arrow)
	
	arrow.position = $Node2D/Marker2D.global_position
	arrow.direction = $Node2D/direction.global_position
	arrow.arrowVelocity = get_global_mouse_position() - arrow.position
	arrow.damage = damage
	
	can_shoot = false
	$FireRate.wait_time = fireRate
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
		
	$TPTimer.wait_time = TPtime
	$TPTimer.start()
	return direction


func _player_movement():
	var directionx = 0
	var directiony = 0
	
	if Input.is_key_pressed(KEY_A): 
		directionx = -PIXELS_TO_MOVE
		if Input.is_key_pressed(KEY_SHIFT):
			directionx = -PIXELS_TO_MOVE/2
			
	elif Input.is_key_pressed(KEY_D): 
		directionx = PIXELS_TO_MOVE
		if Input.is_key_pressed(KEY_SHIFT):
			directionx = PIXELS_TO_MOVE/2
			
	else: directionx = 0
		
	if Input.is_key_pressed(KEY_W): 
		directiony = -PIXELS_TO_MOVE
		if Input.is_key_pressed(KEY_SHIFT):
			directiony = -PIXELS_TO_MOVE/2
			
	elif Input.is_key_pressed(KEY_S): 
		directiony = PIXELS_TO_MOVE
		if Input.is_key_pressed(KEY_SHIFT):
			directiony = PIXELS_TO_MOVE/2
			
	else: directiony = 0
	
	var direction = [directionx, directiony]
	return direction


func _on_timer_timeout():
	can_tp = true


func _on_invulnerable_timer_timeout():
	invulnerable = false


func _on_fire_rate_timeout():
	can_shoot = true
