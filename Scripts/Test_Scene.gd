extends Node2D


var clockStarted = false
var player


#960 x 540
func _ready():
	player = get_node("Player")


func _process(delta):
	if Input.is_key_pressed(KEY_R) or player.alive == false:
		if clockStarted == false:
			restart()


func restart():
	$Timer.start()
	clockStarted = true


func _on_timer_timeout():
	get_tree().reload_current_scene()
	clockStarted = false
