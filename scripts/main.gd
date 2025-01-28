extends Control

var game_ended : bool = false

# Images Preloaded:
const TEX_EMPTY           = preload("res://assets/images/empty.png")
const TEX_DEFAULT_CHARA   = preload("res://assets/images/default_chara.png")
const TEX_KNIFE           = preload("res://assets/images/knife.png")
const TEX_RETREAT         = preload("res://assets/images/retreat.png")
const TEX_ADVANCING       = preload("res://assets/images/advancing.png")
const TEX_WAIT            = preload("res://assets/images/wait.png")
const TEX_COUNTER         = preload("res://assets/images/counter.png")

# Sound Effects
const SE_ADVANCING       = preload("res://assets/sound/advancing.mp3")
const SE_RETREATING      = preload("res://assets/sound/retreating.mp3")
const SE_WAIT            = preload("res://assets/sound/wait.mp3")
const SE_STAB            = preload("res://assets/sound/stab_sound.mp3")
const SE_COUNTER_PUNCH   = preload("res://assets/sound/counter_punch.mp3")
const SE_KEY_CLICK       = preload("res://assets/sound/key-click.mp3")

@onready var player_1_audio: AudioStreamPlayer2D = $Player1Audio
@onready var player_2_audio: AudioStreamPlayer2D = $Player2Audio
@onready var key_click_audio: AudioStreamPlayer2D = $KeyClickAudio

# Node References
@onready var title: Label = $Title

var player1_position : int = 2
var player2_position : int = 4
var player1_charged: bool = false
var player2_charged: bool = false
var player1_energy : int = 10
var player2_energy : int = 10

var player1_action : String = ""
var player2_action : String = ""

var current_player : int = 1  # 1 or 2
var current_turn   : int = 1
var max_turns      : int = GameSettings.num_turns

@onready var wait_button:    Button = $HBoxContainer/WaitButton
@onready var retreat_button: Button = $HBoxContainer/RetreatButton
@onready var advance_button: Button = $HBoxContainer/AdvanceButton
@onready var attack_button:  Button = $HBoxContainer/AttackButton
@onready var counter_button: Button = $HBoxContainer/CounterButton
@onready var change_turn_total: Button = $ChangeTurnTotal

@onready var p_1_position: Label = $PlayerInfoContainer/Player1Info/P1Position
@onready var p_1_energy:   Label = $PlayerInfoContainer/Player1Info/P1Energy

@onready var p_2_position: Label = $PlayerInfoContainer/Player2Info/P2Position
@onready var p_2_energy:   Label = $PlayerInfoContainer/Player2Info/P2Energy

@onready var lock_in_button: Button = $LockInButton
@onready var reset_button: Button = $ResetButton
@onready var concede_button: Button = $ConcedeButton

@onready var message_label: Label   = $MessageLabel

@onready var squares = [
	$BoardContainer/Square0,
	$BoardContainer/Square1,
	$BoardContainer/Square2,
	$BoardContainer/Square3,
	$BoardContainer/Square4,
	$BoardContainer/Square5,
	$BoardContainer/Square6,
]

func _ready() -> void:
	randomize()
	AudioManager.play_game_music()
	reset_game()
	update_ui()

func _process(delta: float) -> void:
	pass

#
# SET / SHOW ACTION
#
func set_player_action(action: String) -> void:
	# Store the chosen action in the correct variable
	if current_player == 1:
		player1_action = action
		print("Player 1 chose:", action)
	else:
		player2_action = action
		print("Player 2 chose:", action)

func show_action_visual(player_id: int, action: String) -> void:
	# Determine which square belongs to which player
	var position: int
	if player_id == 1:
		position = player1_position
	else:
		position = player2_position

	# Pick the correct AudioStreamPlayer2D
	var audio_player: AudioStreamPlayer2D
	if player_id == 1:
		audio_player = player_1_audio
	else:
		audio_player = player_2_audio

	squares[position].flip_h = false

	# Assign the correct texture & sound
	match action:
		"WAIT":
			squares[position].texture = TEX_WAIT
			audio_player.stream = SE_WAIT
		"RETREAT":
			squares[position].texture = TEX_RETREAT
			audio_player.stream = SE_RETREATING
			if player_id == 2:
				squares[position].flip_h = true
		"ADVANCE":
			squares[position].texture = TEX_ADVANCING
			audio_player.stream = SE_ADVANCING
			if player_id == 2:
				squares[position].flip_h = true
		"ATTACK":
			squares[position].texture = TEX_KNIFE
			audio_player.stream = SE_STAB
			if player_id == 1:
				squares[position].flip_h = true
		"COUNTER":
			squares[position].texture = TEX_COUNTER
			audio_player.stream = SE_COUNTER_PUNCH
			if player_id == 2:
				squares[position].flip_h = true
		_:
			# fallback
			squares[position].texture = TEX_DEFAULT_CHARA
			audio_player.stream = null

	audio_player.play()

#
# BUTTON SIGNALS
#
func _on_wait_button_pressed() -> void:
	set_player_action("WAIT")
	_play_key_click()

func _on_retreat_button_pressed() -> void:
	set_player_action("RETREAT")
	_play_key_click()

func _on_advance_button_pressed() -> void:
	set_player_action("ADVANCE")
	_play_key_click()

func _on_attack_button_pressed() -> void:
	set_player_action("ATTACK")
	_play_key_click()

func _on_counter_button_pressed() -> void:
	set_player_action("COUNTER")
	_play_key_click()

#
# LOCK IN / TURN FLOW
#
func _on_lock_in_button_pressed() -> void:
	_play_key_click()
	if game_ended:
		reset_game()
		return

	if current_player == 1:
		if player1_action == "":
			message_label.text = "PLAYER 1 MUST PICK AN ACTION FIRST!"
			return
		current_player = 2
		message_label.text = "NOW IT IS PLAYER 2'S TURN."
		update_ui()
	else:
		if player2_action == "":
			message_label.text = "PLAYER 2 MUST PICK AN ACTION FIRST!"
			return
		# 1) Both players have chosen => reveal the chosen actions visually
		reveal_actions()
		# 2) Resolve both actions
		resolve_both_actions()
		# 3) Increment turn
		current_turn += 1
		check_end_conditions()

		if player1_energy > 0 and player2_energy > 0 and current_turn <= max_turns:
			player1_action = ""
			player2_action = ""
			current_player = 1
			message_label.text = "Turn %d. Player 1, Choose An Action." % current_turn
			update_ui()

func reveal_actions() -> void:
	show_action_visual(1, player1_action)
	show_action_visual(2, player2_action)

#
# RESOLVE ACTIONS
#




func resolve_both_actions() -> void:
	# 1. Handle both players attacking
	if player1_action == "ATTACK" and player2_action == "ATTACK":
		var p1_damage = 3  # Default damage
		var p2_damage = 3  # Default damage

		# Determine Player 1's attack strength
		if player1_charged:
			p1_damage = 6
		else:
			p1_damage = 3

		# Determine Player 2's attack strength
		if player2_charged:
			p2_damage = 6
		else:
			p2_damage = 3

		# Check if players are adjacent
		var distance = abs(player1_position - player2_position)
		if distance > 1:
			# Both players lose 1 energy for attacking out of range
			player1_energy = max(0, player1_energy - 1)
			player2_energy = max(0, player2_energy - 1)
			print("Both players attacked out of range. Each loses 1 energy.")
		else:
			# Compare attack strengths
			if p1_damage == p2_damage:
				# CLASH occurs, no damage
				print("Both players attacked with equal strength. CLASH occurs. No damage dealt.")
				# Optionally, add visual feedback for CLASH here
			elif p1_damage > p2_damage:
				# Player 1's attack overpowers Player 2's
				var damage = 3
				player2_energy = max(0, player2_energy - damage)
				print("Player 1's stronger attack overpowers Player 2's attack. Player 2 takes ", damage, " damage.")
			else:
				# Player 2's attack overpowers Player 1's
				var damage = 3
				player1_energy = max(0, player1_energy - damage)
				print("Player 2's stronger attack overpowers Player 1's attack. Player 1 takes ", damage, " damage.")

		# Reset charged states after attack
		player1_charged = false
		player2_charged = false

		return  # Exit early as attacks are handled

	# 2. Resolve WAIT and RETREAT actions
	resolve_wait_retreat(player1_action, 1)
	resolve_wait_retreat(player2_action, 2)

	# 3. Resolve ADVANCE actions
	resolve_advance(player1_action, 1)
	resolve_advance(player2_action, 2)

	# 4. Resolve ATTACK actions
	resolve_attack(player1_action, 1)
	resolve_attack(player2_action, 2)

	# 5. Resolve COUNTER actions
	resolve_counter(player1_action, 1, player2_action)
	resolve_counter(player2_action, 2, player1_action)

	# -- CLEAR everything not currently occupied --
	for i in range(len(squares)):
		if i != player1_position and i != player2_position:
			squares[i].texture = TEX_EMPTY
			squares[i].modulate = Color.WHITE

	# -- Re-show final actions for each player
	show_action_visual(1, player1_action)
	show_action_visual(2, player2_action)

	# Then do labeling, etc.
	update_ui()



func resolve_wait_retreat(action: String, player_id: int) -> void:
	match action:
		"WAIT":
			if player_id == 1:
				player1_energy += 1
				player1_charged = false
				print("Player 1 performed WAIT. Energy increased to", player1_energy)
			else:
				player2_energy += 1
				player2_charged = false
				print("Player 2 performed WAIT. Energy increased to", player2_energy)
		"RETREAT":
			if player_id == 1:
				if player1_position > 0:
					player1_position -= 1
					print("Player 1 retreated to position", player1_position)
				player1_energy -= 1
				player1_charged = false
				print("Player 1 performed RETREAT. Energy decreased to", player1_energy)
			else:
				if player2_position < 6:
					player2_position += 1
					print("Player 2 retreated to position", player2_position)
				player2_energy -= 1
				player2_charged = false
				print("Player 2 performed RETREAT. Energy decreased to", player2_energy)

func resolve_advance(action: String, player_id: int) -> void:
	if action == "ADVANCE":
		var distance = abs(player1_position - player2_position)
		
		if distance <= 1:
			# Players are adjacent, no movement occurs
			if player_id == 1:
				if player1_energy >= 1:
					player1_energy -= 1
					player1_charged = true
					print("Player 1 advanced but stayed in place due to adjacency. Energy decreased to", player1_energy)
				else:
					print("Player 1 attempted to advance but lacked energy.")
			else:
				if player2_energy >= 1:
					player2_energy -= 1
					player2_charged = true
					print("Player 2 advanced but stayed in place due to adjacency. Energy decreased to", player2_energy)
				else:
					print("Player 2 attempted to advance but lacked energy.")
			return  # Exit early as no movement occurs

		# Regular advance logic if players are not adjacent
		if player_id == 1:
			if player1_energy >= 1:
				if player1_position < player2_position:
					player1_position += 1
				elif player1_position > player2_position:
					player1_position -= 1
				player1_energy -= 1
				player1_charged = true
				print("Player 1 advanced to position", player1_position, "Energy decreased to", player1_energy)
			else:
				print("Player 1 does not have enough energy to ADVANCE.")
		else:
			if player2_energy >= 1:
				if player2_position > player1_position:
					player2_position -= 1
				elif player2_position < player1_position:
					player2_position += 1
				player2_energy -= 1
				player2_charged = true
				print("Player 2 advanced to position", player2_position, "Energy decreased to", player2_energy)
			else:
				print("Player 2 does not have enough energy to ADVANCE.")


func resolve_attack(action: String, player_id: int) -> void:
	if action == "ATTACK":
		print("Player ", player_id, " is performing ATTACK.")

		# Check if opponent is countering
		if (player_id == 1 and player2_action == "COUNTER") or (player_id == 2 and player1_action == "COUNTER"):
			print("Opponent is countering. Attack damage negated.")
			return  # Skip applying attack damage since COUNTER handles it

		if player_id == 1:
			if player1_energy < 1:
				print("Player 1 does not have enough energy to ATTACK.")
				return
			player1_energy -= 1
			print("Player 1 energy decreased by 1. New energy:", player1_energy)
			if abs(player1_position - player2_position) == 1:
				var damage = 0
				if player1_charged:
					damage = 6
				else:
					damage = 3
				player2_energy = max(0, player2_energy - damage)
				print("Player 1 deals ", damage, " damage to Player 2. Player 2 energy:", player2_energy)
				player1_charged = false
		else:
			if player2_energy < 1:
				print("Player 2 does not have enough energy to ATTACK.")
				return
			player2_energy -= 1
			print("Player 2 energy decreased by 1. New energy:", player2_energy)
			if abs(player2_position - player1_position) == 1:
				var damage = 0
				if player2_charged:
					damage = 6
				else:
					damage = 3
				player1_energy = max(0, player1_energy - damage)
				print("Player 2 deals ", damage, " damage to Player 1. Player 1 energy:", player1_energy)
				player2_charged = false


func resolve_counter(action: String, player_id: int, opponent_action: String) -> void:
	if action == "COUNTER":
		print("Processing COUNTER for Player ", player_id, " against opponent's action: ", opponent_action)
		var missed = true
		var damage_to_reflect = 0

		if opponent_action == "ATTACK":
			missed = false
			if player_id == 1:
				if player1_charged:
					damage_to_reflect = 6
				else:
					damage_to_reflect = 3
				# Reflect damage to Player 2 (the attacker)
				player2_energy = max(0, player2_energy - damage_to_reflect)
				player1_charged = false
				print("Player 1 countered Player 2's ATTACK for damage:", damage_to_reflect)
			else:
				if player2_charged:
					damage_to_reflect = 6
				else:
					damage_to_reflect = 3
				# Reflect damage to Player 1 (the attacker)
				player1_energy = max(0, player1_energy - damage_to_reflect)
				player2_charged = false
				print("Player 2 countered Player 1's ATTACK for damage:", damage_to_reflect)

		# Apply missed counter penalty
		if missed:
			if player_id == 1:
				player1_energy = max(0, player1_energy - 2)
				print("Player 1 missed COUNTER. Energy decreased by 2. New energy:", player1_energy)
			else:
				player2_energy = max(0, player2_energy - 2)
				print("Player 2 missed COUNTER. Energy decreased by 2. New energy:", player2_energy)























######################################
# Testing Stuff:
#####################################


#func resolve_attack(action: String, player_id: int) -> void:
	#if action == "ATTACK":
		#print("Player ", player_id, " is performing ATTACK.")
#
		## Check if opponent is countering
		#if (player_id == 1 and player2_action == "COUNTER") or (player_id == 2 and player1_action == "COUNTER"):
			#print("Opponent is countering. Attack damage negated.")
			#return  # Skip applying attack damage since COUNTER handles it
#
		#if player_id == 1:
			#if player1_energy < 1:
				#print("Player 1 does not have enough energy to ATTACK.")
				#return
			#player1_energy -= 1
			#print("Player 1 energy decreased by 1. New energy:", player1_energy)
			#if abs(player1_position - player2_position) == 1:
				#var damage = 3  # Default damage
				#if player1_charged:
					#damage = 6
				#player2_energy = max(0, player2_energy - damage)
				#print("Player 1 deals ", damage, " damage to Player 2. Player 2 energy:", player2_energy)
#
				## Optional: Deduct additional energy for a successful hit
				## Uncomment the following lines to enable
				## player1_energy -= 1
				## print("Player 1 loses an additional 1 energy for a successful hit.")
#
				#player1_charged = false
		#else:
			#if player2_energy < 1:
				#print("Player 2 does not have enough energy to ATTACK.")
				#return
			#player2_energy -= 1
			#print("Player 2 energy decreased by 1. New energy:", player2_energy)
			#if abs(player2_position - player1_position) == 1:
				#var damage = 3  # Default damage
				#if player2_charged:
					#damage = 6
				#player1_energy = max(0, player1_energy - damage)
				#print("Player 2 deals ", damage, " damage to Player 1. Player 1 energy:", player1_energy)
#
				## Optional: Deduct additional energy for a successful hit
				## Uncomment the following lines to enable
				## player2_energy -= 1
				## print("Player 2 loses an additional 1 energy for a successful hit.")
#
				#player2_charged = false
#
#func resolve_counter(action: String, player_id: int, opponent_action: String) -> void:
	#if action == "COUNTER":
		#print("Processing COUNTER for Player ", player_id, " against opponent's action: ", opponent_action)
		#var missed = true
		#var damage_to_reflect = 0
#
		#if opponent_action == "ATTACK":
			#missed = false
			#if player_id == 1:
				#if player1_charged:
					#damage_to_reflect = 6
				#else:
					#damage_to_reflect = 3
				## Reflect damage to Player 2 (the attacker)
				#player2_energy = max(0, player2_energy - damage_to_reflect)
				#player1_charged = false
				#print("Player 1 countered Player 2's ATTACK for damage:", damage_to_reflect)
			#else:
				#if player2_charged:
					#damage_to_reflect = 6
				#else:
					#damage_to_reflect = 3
				## Reflect damage to Player 1 (the attacker)
				#player1_energy = max(0, player1_energy - damage_to_reflect)
				#player2_charged = false
				#print("Player 2 countered Player 1's ATTACK for damage:", damage_to_reflect)
#
		## Apply missed counter penalty
		#if missed:
			#if player_id == 1:
				#player1_energy = max(0, player1_energy - 2)
				#print("Player 1 missed COUNTER. Energy decreased by 2. New energy:", player1_energy)
			#else:
				#player2_energy = max(0, player2_energy - 2)
				#print("Player 2 missed COUNTER. Energy decreased by 2. New energy:", player2_energy)
#
#func resolve_both_actions() -> void:
	## 1. Handle both players attacking simultaneously
	#if player1_action == "ATTACK" and player2_action == "ATTACK":
		#var p1_damage = 3  # Default damage
		#var p2_damage = 3  # Default damage
#
		## Determine Player 1's attack strength
		#if player1_charged:
			#p1_damage = 6
		#else:
			#p1_damage = 3
#
		## Determine Player 2's attack strength
		#if player2_charged:
			#p2_damage = 6
		#else:
			#p2_damage = 3
#
		#var distance = abs(player1_position - player2_position)
		#if distance > 1:
			#player1_energy = max(0, player1_energy - 1)
			#player2_energy = max(0, player2_energy - 1)
			#print("Both players attacked out of range. Each loses 1 energy.")
		#else:
			#if p1_damage == p2_damage:
				#print("Both players attacked with equal strength. CLASH occurs. No damage dealt.")
				## Optionally, add visual feedback for CLASH here
			#else:
				#if p1_damage > p2_damage:
					## Player 1's attack overpowers Player 2's
					#player2_energy = max(0, player2_energy - p1_damage)
					#print("Player 1's stronger attack overpowers Player 2's attack. Player 2 takes ", p1_damage, " damage.")
				#else:
					## Player 2's attack overpowers Player 1's
					#player1_energy = max(0, player1_energy - p2_damage)
					#print("Player 2's stronger attack overpowers Player 1's attack. Player 1 takes ", p2_damage, " damage.")
#
		## Reset charged states after attack
		#player1_charged = false
		#player2_charged = false
#
		#return  # Exit early as attacks are handled
#
	## 2. Resolve WAIT and RETREAT actions
	#resolve_wait_retreat(player1_action, 1)
	#resolve_wait_retreat(player2_action, 2)
#
	## 3. Resolve ADVANCE actions
	#resolve_advance(player1_action, 1)
	#resolve_advance(player2_action, 2)
#
	## 4. Resolve COUNTER actions **before** ATTACK actions
	#resolve_counter(player1_action, 1, player2_action)
	#resolve_counter(player2_action, 2, player1_action)
#
	## 5. Resolve ATTACK actions
	#resolve_attack(player1_action, 1)
	#resolve_attack(player2_action, 2)
#
	## -- CLEAR everything not currently occupied --
	#for i in range(len(squares)):
		#if i != player1_position and i != player2_position:
			#squares[i].texture = TEX_EMPTY
			#squares[i].modulate = Color.WHITE
#
	## -- Re-show final actions for each player
	#show_action_visual(1, player1_action)
	#show_action_visual(2, player2_action)
#
	## Then do labeling, etc.
	#update_ui()





















#######################################
#
#######################################


#
# CHECK END CONDITIONS
#
func check_end_conditions() -> void:
	if player1_energy <= 0 or player2_energy <= 0 or current_turn > max_turns:
		print("Concluding game. Player1 Energy:", player1_energy, "Player2 Energy:", player2_energy, "Turn:", current_turn)
		conclude_game()

#
# CONCLUDE GAME
#
func conclude_game() -> void:
	if player1_energy > player2_energy:
		message_label.text = "PLAYER 1 WINS!".to_upper()
		message_label.add_theme_color_override("font_color", Color.RED)
	elif player2_energy > player1_energy:
		message_label.text = "PLAYER 2 WINS!".to_upper()
		message_label.add_theme_color_override("font_color", Color.BLUE)
	else:
		message_label.text = "IT'S A DRAW!".to_upper()
		message_label.add_theme_color_override("font_color", Color.YELLOW)

	# Disable all action buttons
	wait_button.disabled    = true
	retreat_button.disabled = true
	advance_button.disabled = true
	attack_button.disabled  = true
	counter_button.disabled = true

	# Update lock_in_button for replay
	lock_in_button.text = "PLAY AGAIN?".to_upper()
	lock_in_button.disabled = false

	game_ended = true
	update_ui()

#
# UPDATE UI
#
func update_ui() -> void:
	# Update position & energy labels
	p_1_position.text = "P1 Position: %d" % player1_position
	p_1_energy.text   = "P1 Energy: %d" % player1_energy

	p_2_position.text = "P2 Position: %d" % player2_position
	p_2_energy.text   = "P2 Energy: %d" % player2_energy

	
	# -- Only apply color highlighting to the squares at each player's position
	squares[player1_position].modulate = Color.RED
	squares[player2_position].modulate = Color.BLUE

	# If both players overlap, make it stand out
	if player1_position == player2_position:
		squares[player1_position].modulate = Color(1, 1, 0)

#
# RESET GAME
#
func reset_game() -> void:
	# Reset state
	player1_position = 2
	player2_position = 4
	player1_energy   = 10
	player2_energy   = 10
	player1_action   = ""
	player2_action   = ""

	current_player = 1
	current_turn   = 1
	game_ended     = false
	max_turns = GameSettings.num_turns

	wait_button.disabled    = false
	retreat_button.disabled = false
	advance_button.disabled = false
	attack_button.disabled  = false
	counter_button.disabled = false

	lock_in_button.text = "Lock In\n (Space)"
	lock_in_button.disabled = false

	message_label.remove_theme_color_override("font_color")
	message_label.text = "Turn 1. Player 1, Choose an action."

	for i in range(len(squares)):
		squares[i].texture = TEX_EMPTY
		squares[i].modulate = Color.WHITE

	# 3) Place the default sprite at each player's starting position
	squares[player1_position].texture = TEX_DEFAULT_CHARA
	squares[player2_position].texture = TEX_DEFAULT_CHARA

	# 4) Color-highlight those positions
	squares[player1_position].modulate = Color.RED
	squares[player2_position].modulate = Color.BLUE
	update_ui()

#
# RESET BUTTON SIGNAL
#
func _on_reset_button_pressed() -> void:
	randomize()
	_play_key_click()
	reset_game()

#
# CHANGE TURN TOTAL BUTTON SIGNAL
#
func _on_change_turn_total_pressed() -> void:
	_play_key_click()
	get_tree().change_scene_to_file("res://scenes/setup.tscn")

#
# CONCEDE BUTTON SIGNAL
#
func _on_concede_button_pressed() -> void:
	_play_key_click()
	if game_ended:
		return
	if current_player == 1:
		message_label.text = "Player 1 GAVE UP!"
	else:
		message_label.text = "Player 2 GAVE UP!"

#
# INPUT HANDLING
#
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("1_Key"):
		_play_key_click()
		_on_wait_button_pressed()
	
	if event.is_action_pressed("2_Key"):
		_play_key_click()
		_on_retreat_button_pressed()
	
	if event.is_action_pressed("3_Key"):
		_play_key_click()
		_on_advance_button_pressed()
	
	if event.is_action_pressed("4_Key"):
		_play_key_click()
		_on_attack_button_pressed()
	
	if event.is_action_pressed("5_Key"):
		_play_key_click()
		_on_counter_button_pressed()
	
	if event.is_action_pressed("Space"):
		_play_key_click()
		_on_lock_in_button_pressed()

#
# PLAY KEY CLICK SOUND
#
func _play_key_click() -> void:
	key_click_audio.play()


func _on_exit_pressed() -> void:
	get_tree().quit()	
