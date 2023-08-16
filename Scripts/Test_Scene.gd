extends Node2D


func _ready():
	#960 x 540
	pass


func _process(delta):
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
