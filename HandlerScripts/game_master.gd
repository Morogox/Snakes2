extends Node2D
@export var difficulty : float = 1.0
@export var max_enemy_amount := 8
var available_space = max_enemy_amount
@export var base_wave_amt := Vector2(1, 1.5)
@export var base_wave_time := Vector2(15.0, 20.0)
var wave_timer := 0.0
var next_wave_time := 0.0
@export var wave_speed_up = 0.8

@export var enemy_variation := Vector2(0.0, 0.0)

var base_enemy_weights = {
	"basic": 10.0,
	"rager": 7.0,
	"elite": 5.0,
	"heavy": 3.0,
	"primal": 4.0
}

var enemy_scenes : Dictionary


@export var basic_curve: Curve
@export var rager_curve: Curve
@export var elite_curve: Curve
@export var heavy_curve: Curve
@export var primal_curve: Curve
@export var wave_amt_curve: Curve  # Multiplier for wave size
@export var wave_time_curve: Curve  # Multiplier for wave time
@export var difficulty_curve: Curve  # Shape how difficulty ramps

@export var max_score: int = 100000  # Score at max difficulty
@export var max_difficulty : float =  10.0


@export var spawning_enabled = true
@export var score_diff_scale = true
signal tier_change(tier: int)
func _ready():
	Handler.register(name.to_snake_case(), self)
	Handler.enemy_handler.enemy_killed.connect(_update_available_space)
	Handler.score_manager.score_changed.connect(_update_difficulty)
	enemy_scenes = Handler.enemy_handler.enemy_types
	_reset_wave_timer()
	_update_available_space(0,0)

func _process(delta):
	if spawning_enabled:
		wave_timer += delta
	# Time to spawn a wave
	if wave_timer >= next_wave_time:
		var adjusted_wave_amt = get_wave_amt()
		var capped_min = min(adjusted_wave_amt.x, available_space)
		var capped_max = min(adjusted_wave_amt.y, available_space)
		#somthing here
		_generate_enemy_wave(capped_min, capped_max)
		_reset_wave_timer()
		_update_available_space(0,0)

func get_adjusted_weights() -> Dictionary:
	var weights = {}
	
	# Convert difficulty to 0.0-1.0 range for curve sampling
	var progress = (difficulty) / (max_difficulty)
	progress = clamp(progress, 0.0, 1.0)
	
	# Sample each curve
	weights["basic"] = base_enemy_weights["basic"] * basic_curve.sample(progress)
	weights["rager"] = base_enemy_weights["rager"] * rager_curve.sample(progress)
	weights["elite"] = base_enemy_weights["elite"] * elite_curve.sample(progress)
	weights["heavy"] = base_enemy_weights["heavy"] * heavy_curve.sample(progress)
	weights["primal"] = base_enemy_weights["primal"] * primal_curve.sample(progress)
	
	return weights

func get_random_enemy() -> String:
	# Calculate total weight
	var adjusted_weight = get_adjusted_weights()
	var total_weight = 0
	for weight in adjusted_weight.values():
		total_weight += weight
	
	# Pick random number between 0 and total
	var random_value = randf() * total_weight
	
	# Find which enemy this corresponds to
	var current_weight = 0
	for enemy_type in adjusted_weight.keys():
		current_weight += adjusted_weight[enemy_type]
		if random_value <= current_weight:
			return enemy_type
	
	return "basic"  # Fallback

func _generate_enemy_wave(min : int, max: int) -> void:
	if min + max <= 0:
		print("rejected")
		return
	if Handler.enemy_handler == null:
		push_warning("Enemy handler not set!")
		return
	var amt = randi_range(min, max)
	var enemy_list: Array[String] = []
	for i in range(amt):
		enemy_list.append(get_random_enemy())
	print("new wave generated: ", enemy_list)
	Handler.enemy_handler.generate_wave(enemy_list)

func _reset_wave_timer() -> void:
	wave_timer = 0.0
	var adjusted_wave_time = get_wave_time()
	next_wave_time = randf_range(adjusted_wave_time.x, adjusted_wave_time.y)
	

func _update_available_space(_s, _l):
	available_space = max_enemy_amount - Handler.enemy_handler.active_enemy_amt
	available_space = clamp(available_space, 0, max_enemy_amount)
	if available_space >= max_enemy_amount:
		wave_timer = max(wave_timer, next_wave_time * wave_speed_up)
	
func get_wave_amt() -> Vector2i:
	var progress = (difficulty) / (max_difficulty)
	var multiplier = wave_amt_curve.sample(progress)
	
	return Vector2i(
		int(base_wave_amt.x * multiplier),
		int(base_wave_amt.y * multiplier)
	)

func get_wave_time() -> Vector2:
	var progress = (difficulty - 1.0) / (max_difficulty - 1.0)
	var multiplier = wave_time_curve.sample(progress)
	
	return Vector2(
		base_wave_time.x * multiplier,
		base_wave_time.y * multiplier
	)

func _update_difficulty(player_score : int):
	var old_level = int(difficulty)
	var progress = clamp(float(player_score) / max_score, 0.0, 1.0)
	if score_diff_scale:
		difficulty = 1.0 + (max_difficulty - 1.0) * difficulty_curve.sample(progress)
	var new_level = int(difficulty)  # Get new tier
	print("diffculty rn at score " + str(player_score) + ": " + str(difficulty))
	var temp = get_adjusted_weights()
	var temp_total = 0.0
	print("enemy weights:", str(temp))
	
	for weight in temp.values():
		temp_total += weight
		
	print("total weight: ", temp_total)
	if new_level > old_level:
		tier_break()

func tier_break():
	_reset_wave_timer()
	emit_signal("tier_change", int(difficulty))
	_update_available_space(0,0)
	
