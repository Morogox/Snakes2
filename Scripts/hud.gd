extends Control
@onready var score_label = $ScoreLabel
@onready var segments_label = $SegmentsLabel
var score: int = 0
var segments: int = 0
func _ready():
	Handler.score_manager.connect("score_changed", set_score)
	Handler.snake_head.connect("segments_update", set_segments)
	set_score(0)
	
func set_score(value: int):
	score = value
	score_label.text = "Score: " + str(score)

func set_segments(value: int):
	segments = value
	segments_label.text = "Segments: " + str(segments)
	
