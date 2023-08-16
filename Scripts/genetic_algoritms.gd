extends Node2D


var player

var Enemy_1 = preload("res://Scenes/enemy_1.tscn")
var Enemy_2 = preload("res://Scenes/enemy_2.tscn")
var Enemy_3 = preload("res://Scenes/enemy_3.tscn")

var enemy1 = Enemy_1.instantiate()
var enemy2 = Enemy_2.instantiate()
var enemy3 = Enemy_3.instantiate()

var played_is_alive = true
var spawn_position

var population_size = 10
var population = []
var enemy

var WeightAndBias_Start = {
	1: {"weights": [[0.1, 0.1, 0.1], 
					[0.1, 0.1, 0.1], 
					[0.1, 0.1, 0.1], 
					[0.1, 0.1, 0.1]],
		"bias": [0.1, 0.1, 0.1, 0.1],
		"Generation": 0,
		"fitness": 0},
				
	2: {"weights": [[0.1, 0.1, 0.1, 0.1], 
					[0.1, 0.1, 0.1, 0.1], 
					[0.1, 0.1, 0.1, 0.1], 
					[0.1, 0.1, 0.1, 0.1], 
					[0.1, 0.1, 0.1, 0.1]],
		"bias": [0.1, 0.1, 0.1, 0.1, 0.1],
		"Generation": 0,
		"fitness": 0},
				
	3: {"weights": [[0.1, 0.1, 0.1, 0.1, 0.1],
					[0.1, 0.1, 0.1, 0.1, 0.1],
					[0.1, 0.1, 0.1, 0.1, 0.1],
					[0.1, 0.1, 0.1, 0.1, 0.1],
					[0.1, 0.1, 0.1, 0.1, 0.1]],
		"bias": [0.1, 0.1, 0.1, 0.1, 0.1],
		"Generation": 0,
		"fitness": 0}
	}


func _ready():
	#reset_enemy_data(3)
	#reset_data()
	
	spawn_position = $Node2D/Marker2D.global_position
	player = get_node("Player")
	
	$Node2D/Marker2D.global_position = spawn_position
	
	create_population(enemy3)
	enemy = 3


func _process(delta):
	if player.alive == false and played_is_alive:
		played_is_alive = false
		search_best_gen()
	
	if Input.is_key_pressed(KEY_R):
		search_best_gen()


func reset_data():
	for enemy in range(1, 4):
		var weights = WeightAndBias_Start[enemy]["weights"]
		var bias = WeightAndBias_Start[enemy]["bias"]
		var gen = WeightAndBias_Start[enemy]["Generation"]
		var fitness = WeightAndBias_Start[enemy]["fitness"]
		
		save_data(weights, bias, gen, fitness, enemy)
	
	print("\nDATOS RESETEADOS")


func reset_enemy_data(num):
	var weights = WeightAndBias_Start[num]["weights"]
	var bias = WeightAndBias_Start[num]["bias"]
	var gen = WeightAndBias_Start[num]["Generation"]
	var fitness = WeightAndBias_Start[num]["fitness"]
	
	save_data(weights, bias, gen, fitness, num)
	print("\nENEMIGO RESETEADO")


func create_population(enemy):
	for i in range(population_size):
		var enemy_aux = enemy.duplicate()
		
		enemy_aux.position = $Node2D/Marker2D.global_position
		$Node2D/Marker2D.global_position += Vector2(0, 16)
		
		population.append(enemy_aux)
		enemy_aux.mutate = true
		
		add_child(enemy_aux)
	
	#print(population)


func generation():
	var path = "res://Variables/Enemy_" + str(enemy) + "_data.dat"
	var file = FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
	
	print("\n\nGENERACION # ",data["Generation"] + 1,"\n")


func last_generation_fitness():
	var path = "res://Variables/Enemy_" + str(enemy) + "_data.dat"
	var file = FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
	
	return data["fitness"] / 2


func save_data(weights, bias, gen, fitness, enemy):
	var data = {
		"Weights": weights,
		"Bias": bias,
		"Generation": gen,
		"fitness": fitness
	}

	var path = "res://Variables/Enemy_" + str(enemy) + "_data.dat"
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_var(data)


func load_data(enemy):
	var path = "res://Variables/Enemy_" + str(enemy) + "_data.dat"
	var file = FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()


func search_best_gen():
	var best_gen_fitness = 0
	var best_gen = population[0]
	
	for gen in population:
		if gen.fitness() > best_gen_fitness:
			best_gen_fitness = gen.fitness()
			best_gen = gen
	
	if best_gen_fitness >= last_generation_fitness():
		save_data(best_gen.weights, best_gen.bias, best_gen.generation + 1, best_gen_fitness, enemy)
		print("\n\nMEJOR GEN GUARDADO!!!\nPesos: ",best_gen.weights, "\nBias: ", best_gen.bias)
		
	get_tree().reload_current_scene()


func _on_timer_timeout():
	generation()
	
	print("\nFitnes de la poblacion")
	var population_died = 0
	var gen_num = 1
	var vivos = 0
	
	for gen in population:
		print("Gen #",gen_num,", Vivo: ",gen.alive,", Fitness: ",gen.fitness())
		gen_num += 1
		
		if gen.alive == false:
			population_died += 1
		
	vivos = abs(population_died - population_size)
	if population_died == population_size and vivos == 0:
		print("\nTODOS HAN MUERTO!!!!!!\nREINICIANDO........................")
		search_best_gen()
	
	else:
		print("\nQUEDAN ", vivos, " ENEMIGOS VIVOS")
