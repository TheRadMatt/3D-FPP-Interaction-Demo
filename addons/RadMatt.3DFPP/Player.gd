
extends KinematicBody

var carried_object = null
var throw_power = 0

var interactor = null

# this was supposedd to be for fall damage, not sure if works
var last_floor_height
var can_change_last_floor_height = true

# Movement
const IDLE = 0

const RUN = 1 # default movement
const SPRINT = 2
const WALK = 3

var movement_state = IDLE

const STAND = 0
const CROUCH = 1

var posture_state = STAND

var run_speed = 8
var sprint_speed = 10
var walk_speed = 2.7

var move_speed = run_speed

# Controls
var velocity = Vector3()
var yaw = 0
var pitch = 0
var is_moving = false
var view_sensitivity = 0.15

var look_vector = Vector3()

# Physics
var gravity = -40

const ACCEL = 0.5
const DEACCEL = 0.8

const JUMP_STR = 15

# Ladder
var on_ladder = false
const LADDER_SPEED = 8
const LADDER_ACCEL = 2

#slope variables
const MAX_SLOPE_ANGLE = 60

#stair variables
const MAX_STAIR_SLOPE = 20
const STAIR_JUMP_HEIGHT = 6


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(d):

#######################################################################################################
# INTERACTIONS

	if $Yaw/Camera/InteractionRay.is_colliding():
		var x = $Yaw/Camera/InteractionRay.get_collider()
		if x.has_method("pick_up"):
			$interaction_text.set_text("[F]  Pick up: " + x.get_name())
		elif x.has_method("interact"):
			$interaction_text.set_text("[E]  Interact with: " + x.get_name())
		else:
			$interaction_text.set_text("")
	else:
		$interaction_text.set_text("")


#######################################################################################################
# VECTOR 3 for where the player is currently looking

	var dir = (get_node("Yaw/Camera/look_at").get_global_transform().origin - get_node("Yaw/Camera").get_global_transform().origin).normalized()
	look_vector = dir


func _physics_process(delta): #IS PLAYER MOVING NORMALLY OR ON LADDER?
	if on_ladder:
		_process_on_ladder(delta)
	else:
		_process_movements(delta)

#######################################################################################################
# NORMAL MOVEMENT
#######################################################################################################

var direction = Vector3()
func _process_movements(delta):

	var up = Input.is_action_pressed("ui_up")
	var down = Input.is_action_pressed("ui_down")
	var left = Input.is_action_pressed("ui_left")
	var right = Input.is_action_pressed("ui_right")

	var jump = Input.is_action_pressed("jump")

	var sprint = Input.is_action_pressed("sprint")
	var walk = Input.is_action_pressed("walk")

	var aim = $Yaw/Camera.get_camera_transform().basis

	direction = Vector3()

	if up:
		direction -= aim[2]
	if down:
		direction += aim[2]
	if left:
		direction -= aim[0]
	if right:
		direction += aim[0]

	if up or right or left or down: # IS MOVING?
		if posture_state == STAND:
			movement_state = RUN
			move_speed = run_speed
			if !on_ladder:
				if up or right or left: # IS MOVING FORWARDS?
					if sprint:
						movement_state = SPRINT
						move_speed = sprint_speed
					elif walk:
						movement_state = WALK
						move_speed = walk_speed
		else:
			movement_state = WALK
			move_speed = walk_speed
	else: # IS NOT MOVING?
		movement_state = IDLE

	var normal = $floor_check.get_collision_normal()

	if is_on_floor():
		if can_change_last_floor_height == false:                           # FALL DAMAGE | Not sure if works properly
			var height_difference = last_floor_height - get_translation().y
			if height_difference > 0.4:
				print("OUCH!")
		can_change_last_floor_height = true

		velocity = velocity - velocity.dot(normal) * normal

		if jump:
			if movement_state == SPRINT:
				velocity.y += JUMP_STR * 1.1 # Jump higher if sprinting
			else:
				velocity.y += JUMP_STR

	else:
		_apply_gravity(delta)
		if can_change_last_floor_height:
			last_floor_height = get_translation().y
			can_change_last_floor_height = false

	if velocity.x > 0 or velocity.x < 0 and is_moving == false:
		is_moving = true
	else:
		is_moving = false
	if velocity.y > 0 or velocity.y < 0 and is_moving == false:
		is_moving = true
	else:
		is_moving = false
	if velocity.z > 0 or velocity.z < 0 and is_moving == false:
		is_moving = true
	else:
		is_moving = false
		pass

	direction.y = 0
	#Normalize direction
	direction = direction.normalized()

	if (direction.length() > 0 and $Yaw/stair_check.is_colliding()):
		var stair_normal = $Yaw/stair_check.get_collision_normal()
		var stair_angle = rad2deg(acos(stair_normal.dot(Vector3(0, 1, 0))))
		if stair_angle < MAX_STAIR_SLOPE:
			print("STAIR")
			velocity.y = STAIR_JUMP_HEIGHT

	var hvel = velocity
	hvel.y = 0
	var target = direction * move_speed
	var accel
	if(direction.dot(hvel) > 0):
		accel = ACCEL
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel * move_speed * delta)
	velocity.x = hvel.x
	velocity.z = hvel.z

	velocity = move_and_slide(velocity, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))

	throwing(delta)

#######################################################################################################
# MOVEMENT ON LADDER
#######################################################################################################

func _process_on_ladder(delta):

	var up = Input.is_action_pressed("ui_up")
	var down = Input.is_action_pressed("ui_down")
	var left = Input.is_action_pressed("ui_left")
	var right = Input.is_action_pressed("ui_right")

	var jump = Input.is_action_pressed("jump")

	var sprint = Input.is_action_pressed("sprint")
	var walk = Input.is_action_pressed("walk")

	#read camera basis (rotation)
	var aim = $Yaw/Camera.get_camera_transform().basis

	#calculate direction where the player wants to move
	direction = Vector3()

	if up:
		direction -= aim[2]
	if down:
		direction += aim[2]
	if left:
		direction -= aim[0]
	if right:
		direction += aim[0]

	direction = direction.normalized()

	# where would the player go at max speed
	var target = direction * LADDER_SPEED

	# calculate a portion of the distance to go
	velocity = velocity.linear_interpolate(target, LADDER_ACCEL * delta)

	if jump:
		velocity += look_vector * Vector3(5, 5, 5)

	# move
	move_and_slide(velocity)

	throwing(delta)


#######################################################################################################
# GRAVITY

func _apply_gravity(delta):
	velocity.y += delta * gravity

#######################################################################################################
# CAMERA MOVEMENTS

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		yaw = fmod(yaw - event.relative.x * view_sensitivity, 360)
		pitch = max(min(pitch - event.relative.y * view_sensitivity, 89), -89)
		$Yaw.rotation = Vector3(0, deg2rad(yaw), 0)
		$Yaw/Camera.rotation = Vector3(deg2rad(pitch), 0, 0)


#######################################################################################################
# BUTTON PRESSING
#######################################################################################################
func _input(event):

	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()

	# If already carries an object - release it, otherwise (if ray is colliding) pick an object up
	if Input.is_action_just_pressed("pick_up"):
		if carried_object != null:
			carried_object.pick_up(self)
		else:
			if $Yaw/Camera/InteractionRay.is_colliding():
				var x = $Yaw/Camera/InteractionRay.get_collider()
				if x.has_method("pick_up"):
					x.pick_up(self)

	# Hold Left Mouse Button (LMB) to throw carried object
	if Input.is_action_just_released("LMB"):
		if carried_object != null:
			carried_object.throw(throw_power)
		throw_power = 0

	# Interact
	if Input.is_action_just_pressed("interact"):
		if $Yaw/Camera/InteractionRay.is_colliding():
			var x = $Yaw/Camera/InteractionRay.get_collider()
			print("COLLIDING")
			print(x.get_name())
			if x.has_method("interact"):
				x.interact(self)


	# Crouching

	# Already crouching?
		# Is there ceiling above me? If not then stand. If yes, then display a message.

	if Input.is_action_pressed("crouch"):
		if posture_state == STAND:
			$crouching.play("crouch")
			move_speed = walk_speed
		else:
			if !($ceiling_check.is_colliding()):
				$crouching.play_backwards("crouch")
				move_speed = run_speed
			else:
				show_message("I cannot stand here.", 2)

#######################################################################################################
# OTHER
#######################################################################################################

# LADDER
func _on_Area_body_entered(body):
	if body.name == "Player":
		on_ladder = true

func _on_Area_body_exited(body):
	if body.name == "Player":
		on_ladder = false


# CROUCHING ANIM
func _on_crouching_animation_finished(anim_name):
	if posture_state == STAND:
		posture_state = CROUCH
	else:
		posture_state = STAND


# IMPULSE STUFF
func impulse(vector_towards, power, time):
	for x in range(time * 100):
		velocity += vector_towards * Vector3(power, power, power)

# THROW STUFF
func throwing(delta):
	if carried_object != null:
		if Input.is_action_pressed("LMB"):
			if throw_power <= 250:
				throw_power += 2

# SHOW A MESSAGE ON SCREEN
func show_message(text, time):
	$message.set_text(text)
	$message/Timer.set_wait_time(time)
	$message/Timer.start()
	yield($message/Timer, "timeout")
	$message.set_text("")