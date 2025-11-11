extends Control
@onready var score_label = $ScoreLabel
@onready var segments_label = $SegmentsLabel
@onready var stamina_bar = $staminaBar/TextureProgressBar
@onready var chaser = $staminaBar/TextureProgressBar2

@onready var tier_label = $TierLabel/Label
var score: int = 0
var segments: int = 0

var target_stamina := 0.0
var target_max_stamina := 10.0
var chaser_speed = 1.0

func _ready():
	Handler.score_manager.connect("score_changed", set_score)
	Handler.snake_head.connect("segments_update", set_segments)
	Handler.snake_head.connect("stamina_changed", _update_stamina_bar)
	Handler.game_master.connect("tier_change", _tier_warning)
	set_score(0)
	stamina_bar.max_value = Handler.snake_head.max_stamina
	chaser.max_value = Handler.snake_head.max_stamina
	tier_label.modulate.a = 0.0
	
func _process(delta):
	#print("player stam ", target_stamina)
	#print("chaser value ", chaser.value)
	
	if chaser.value > stamina_bar.value:
		#print("decrease called")
		chaser.value -= 10.0 * delta
	if  stamina_bar.value > chaser.value:
		#print("increase called")
		chaser.value = stamina_bar.value
	
func set_score(value: int):
	score = value
	score_label.text = "Score: " + str(score)

func set_segments(value: int):
	segments = value
	segments_label.text = "Segments: " + str(segments)
	
	#var stam_ratio = stamina_bar.value / stamina_bar.max_value
	stamina_bar.max_value = Handler.snake_head.max_stamina
	#stamina_bar.value = stamina_bar.max_value * stam_ratio

func _update_stamina_bar(stamina, max_stamina):
	target_stamina = stamina  # Store the target, don't set chaser directly
	
	var ratio = chaser.value / chaser.max_value
	chaser.max_value = max_stamina
	chaser.value = chaser.max_value * ratio
	
	stamina_bar.max_value = max_stamina 
	stamina_bar.value = stamina

func _tier_warning(tier: int):
	tier_label.modulate.a = 0.15
	tier_label.text = str(tier)
	var tween = create_tween()
	tween.tween_property(tier_label, "modulate:a", 0.0, 0.5)
	
