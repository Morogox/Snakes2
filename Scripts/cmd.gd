extends CanvasLayer
@onready var output = $Control/ColorRect/RichTextLabel
@onready var textLine =$Control/ColorRect/LineEdit
var awaiting_confirmation = false
var confirmation_callback: Callable
var commands := {
	"help": cmd_help,
	"echo": cmd_echo,
	"inv": cmd_toggle_inv,
	"ammo": cmd_toggle_ammo,
	"stam": cmd_toggle_stam,
	"addseg": cmd_add_segments,
	"destroyseg": cmd_destroy_segment,
	"kill": cmd_kill,
	"speed": cmd_set_speed,
	"boost": cmd_set_boost_multi,
	"spawnenemy": cmd_spawn_enemy,
	"editstam": cmd_edit_stamina_property,
	"setdiff": cmd_set_diff,
	"spawning": cmd_set_spawning,
	"DoG": cmd_dog
}

var command_help := {
	"help": "Syntax: help (command: String) \nDisplay additional information about specific commands",
	"echo": "Syntax: echo (param: String) \nEchos param",
	"inv": "Syntax: inv \nToggles invincibility",
	"ammo": "Syntax: ammo \nToggles infinite ammo",
	"stam": "Syntax: stam \nToggles infinite stamina",
	"addseg": "Syntax: addseg (amount: int) \nAdds amount segments",
	"destroyseg": "Syntax: destroyseg (amount: int) \nDestroy amount segments",
	"kill": "Syntax: kill (amount: int) \nKills amount of enemies
'all' will kill enemies on screen
'self' will kill the snake",
	"speed": "Syntax: speed (value: float) \nSet speed of snake in seconds per square" ,
	"boost": "Syntax: boost (value: float) \nSet boost multiplier of snake",
	"spawnenemy": "Syntax: spawnenemy (type: string) (amount: int) \nSpawns amount of type enemies",
	"editstam": "Syntax: editstam (property: String) (value: float) \nAdjust stamina property to value
Valid properties are: \nregen\ncap\nmax\ncons",
	"setdiff": "Syntax: setdiff (value: float) \n Sets diffculty multiplier to float",
	"spawning": "Syntax: spawning (bool) \nSets enemy spawning",
	"DoG": "Start DoGing all over the place"

}
var enabled = true
func _ready():
	visible = false

func _on_line_edit_text_submitted(cmd: String) -> void:
	if not enabled:
		_log("cmd disabled!")
		return
	output.append_text("> " + cmd + "\n")
	run_command(cmd)
	textLine.clear()
	textLine.grab_focus()
	

func _log(text: String):
	output.append_text(text + "\n")
	

func run_command(cmd: String):
	var parts = cmd.split(" ")
	var cmd_name = parts[0]
	var args = parts.slice(1)

	# Handle confirmation input
	if awaiting_confirmation:
		handle_confirmation(cmd)
		textLine.clear()
		textLine.grab_focus()
		return

	if commands.has(cmd_name):
		commands[cmd_name].call(args)
	else:
		_log("Unknown command: " + cmd_name)
func handle_confirmation(response: String):
	var normalized = response.to_lower().strip_edges()
	awaiting_confirmation = false
	
	if normalized in ["y", "yes"]:
		confirmation_callback.call(true)
	elif normalized in ["n", "no"]:
		confirmation_callback.call(false)
	else:
		_log("Invalid response. Command cancelled.")
		confirmation_callback.call(false)
	
	confirmation_callback = Callable()  # Clear callback

func await_confirmation(prompt: String, callback: Callable):
	awaiting_confirmation = true
	confirmation_callback = callback
	_log(prompt + " (Y/N)")

func check_arg(args: Array, amt: int):
	if args.is_empty():
		_log("Error: this command require %d parameter(s)" % amt)
		return false
	elif args.size() != amt:
		_log("Error: this command require %d parameter(s)" % amt)
		return false
	return true

func cmd_help(args):
	if check_arg(args, 1):
		if(args[0] not in command_help):
			_log("Error: unknown command " + args[0])
		else:
			_log(command_help[args[0]])
			
	else:
		_log("Commands:")
		for c in commands.keys():
			_log("  " + c)
		_log("Type help (command: String) for more information about specific commands")


func cmd_echo(args):
	_log(" ".join(args))


func cmd_toggle_inv(_args):
	if Handler.snake_head.invulnerable:
		Handler.snake_head.invulnerable = false
	else:
		Handler.snake_head.invulnerable = true
	_log(str("Invulnerable: ", Handler.snake_head.invulnerable))
	
func cmd_toggle_ammo(_args):
	if Handler.snake_head.inf_ammo:
		Handler.snake_head.inf_ammo = false
	else:
		Handler.snake_head.inf_ammo = true
	_log(str("infinite ammo: ", Handler.snake_head.inf_ammo))
	
func cmd_toggle_stam(_args):
	if Handler.snake_head.inf_stamina:
		Handler.snake_head.inf_stamina = false
	else:
		Handler.snake_head.inf_stamina = true
		Handler.snake_head.stamina += 1000
	_log(str("infinite stamina: ", Handler.snake_head.inf_stamina))

func cmd_add_segments(args):
	if not check_arg(args, 1): return
	var param = parse_arg(args[0], "int", false)
	if param == null:
		return
	Handler.snake_head._grow(int(param))
	_log(str("Added ", param, " segment(s)"))
	
func cmd_kill(args):
	if not check_arg(args, 1): return
	var param = args[0]
	if args.is_empty():
		_log("Error: invalid parameter")
		return
	
	if param == null:
		return
	match param.to_lower():
		"all":
			for e in get_tree().get_nodes_in_group("Enemies"):
				if e:
					e.take_hit(99999999)
			_log("Killed all enemies.")
		"self":
			Handler.snake_head._game_over()
		_:
			if param.is_valid_int():
				var count := int(param)

				if count <= 0:
					_log("Count must be > 0")
					return

				var enemies := get_tree().get_nodes_in_group("Enemies")

				# kill min(count, enemies.size()) enemies
				var to_kill = min(count, enemies.size())

				for i in range(to_kill):
					var e = enemies[i]
					if e:
						e.take_hit(99999999)

				_log("Killed %d enemies." % to_kill)
				return

			_log("Unknown parameter: %s" % param)
			
func cmd_set_speed(args):
	if not check_arg(args, 1): return
	var param = parse_arg(args[0], "float", false)
	if param == null:
		return
	param = float(param)
	Handler.snake_head.move_delay_default = float(param)
	_log("Set speed to %f" % param)

func cmd_set_boost_multi(args):
	if not check_arg(args, 1): return
	var param = parse_arg(args[0], "float", false)
	if param == null:
		return
	Handler.snake_head.boost_multi = float(param)
	_log("Set boost multiplier to %f" % param)

func cmd_spawn_enemy(args):
	if not check_arg(args, 2): return
	var param1 = parse_arg(args[0], "string", false)
	var param2 = parse_arg(args[1], "int", false)
	if param1 == null or param2 == null:
		return
	match param1:
		"basic":
			pass
		"rager":
			pass
		"elite":
			pass
		"heavy":
			pass
		"primal":
			pass
		_:
			_log("Error: invalid enemy type " + param1)
			return
	Handler.enemy_handler._spawn_enemy(param1, int(param2))
	_log("Spawned %d %s enemies" % [param2, param1])

func cmd_destroy_segment(args):
	if not check_arg(args, 1): return
	var param = parse_arg(args[0], "int", false)
	if param == null:
		return
	var i = max(0, Handler.snake_head.segments.size() - param)
	var target =  Handler.snake_head.segments[i]
	_log("Destroyed %d segments" % min(param, Handler.snake_head.segments.size()))
	Handler.snake_head._remove_segment(target)
	

func cmd_edit_stamina_property(args):
	if not check_arg(args, 2): return
	var param = parse_arg(args[0], "string", false)
	var param2 = parse_arg(args[1], "float", false)
	if param == null or param2 == null:
		return
	
	match param:
		"regen":
			Handler.snake_head.stamina_regen_rate = param2
			_log("Set stamina regeneraton rate to %f" % param2)
		"cap":
			Handler.snake_head.stamina_cap = param2
			_log("Set stamina cap to %f" % param2)
		"max":
			Handler.snake_head.max_stamina = min(param2, Handler.snake_head.stamina_cap)
			_log("Set max stamina to %f" % param2)
		"cons":
			Handler.snake_head.stamina_consumption_rate = param2
			_log("Set stamina consumption rate to %f" % param2)
		_:
			_log("Error: invalid paramter 2. Valid parameters are: \nregen\ncap\nmax\ncons")



func parse_arg(args: String, expected_type: String, negative: bool):
	var param = args

	match expected_type:
		"int":
			if not param.is_valid_int():
				_log("Error: expected int")
				return null
			elif not negative and int(param) < 0:
				_log("Error: cannot be negative")
			return int(param)

		"float":
			if not param.is_valid_float():
				_log("Error: expected float")
				return null
			elif not negative and float(param) < 0.0:
				_log("Error: cannot be negative")
			return float(param)

		"string":
			# strings are always valid
			return str(param)
		
		"boolean":
			var lower = param.to_lower()

			if lower == "true" or lower == "1" or lower == "yes":
				return true
			elif lower == "false" or lower == "0" or lower == "no":
				return false
			else:
				_log("Error: must be bool")
				return null 
		_:
			_log("Error: unknown expected_type '%s'" % expected_type)
			return null

func cmd_set_diff(args):
	if not check_arg(args, 1): return
	var param = parse_arg(args[0], "float", false)
	if param == null:
		return
	Handler.game_master.score_diff_scale = false
	Handler.game_master.difficulty = param
	_log("Set difficulty to %f" % param)

func cmd_set_spawning(args):
	if not check_arg(args, 1): return
	var param = parse_arg(args[0], "boolean", false)
	if param == null:
		return
	Handler.game_master.spawning_enabled = param
	_log(str("Enemy spawning: ", Handler.game_master.spawning_enabled))

func cmd_disable_cmd(_args):
	enabled = false
	_log("cmd disabled! this cannot be undone.")
































func cmd_dog(_args):
	_log("WARNING: What you're about to access is intended as a JOKE and highly UNSTABLE SPAGHETTI CODE\nTHERE IS NO GOING BACK FROM THIS")
	await_confirmation("Are you sure you want to continue?", func(confirmed):
		if not confirmed:
			_log("Command cancelled.")
		else:
			var new_script = load("res://DoG/Scripts/snake_DoG.gd")
			cmd_destroy_segment(["999999999999999999"])
			Handler.snake_head.set_script(new_script)

			Handler.snake_head._ready()
			
			Handler.snake_head.bullet_scene = preload("res://Bullets/Scenes/bullet_player_1.tscn")
			Handler.snake_head.segment_scene = preload("res://DoG/Scenes/snake_DoG_segment.tscn")
			#under construction
			
			cmd_toggle_inv(_args)
			cmd_toggle_stam(_args)
			cmd_toggle_ammo(_args)
			cmd_add_segments(["10"])
			cmd_set_speed(["0.08"])
			
			var root = get_tree().current_scene
			var player = root.get_node("Game").get_node("Game_Music")
			player.stream = preload("res://DoG/Sound/793443_Universal-Collapse.mp3")
			player.volume_db = -15.0
			player.play()
			cmd_disable_cmd(_args)
	
	
	)
	
	
	pass
