extends CharacterBody2D


const PIXELS_TO_MOVE = 1.6
const TP_MULTIPLIER = 26
const SPEED = 260.0

var can_tp = true


func _physics_process(delta):
	var direction = _player_movement()
	
	if Input.is_key_pressed(KEY_SPACE) and can_tp:
		direction = _player_teleport(direction)
	
	if direction[0]: velocity.x = direction[0] * SPEED
	else: velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if direction[1]: velocity.y = direction[1] * SPEED
	else: velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()


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
