extends CharacterBody3D

#Simple minimal first person controller that just does the job.
#No fancy head bobbing atm

##Can be controlled using the keyboard and the mouse
@export var supports_keyboard : bool = true
##Can be controlled using a controller
@export var supports_controller : bool = true
##The higher the value, the faster it is to look around
@export var controller_sensitivity : float = 1
##Only use with some controllers (notably the snes) so that you don't have to spam the looking around keys
@export var snes_debugger : bool = false
##If true, makes the character fly
@export var is_flying : bool = false
##The base speed of the character
@export var speed : float = 5
##The sprint speed of the character
@export var sprint_speed : float = 8
##The crouched speed of the character
@export var crouched_speed : float = 3
##The flying speed
@export var flying_speed : float = 10
##The sprint flying speed
@export var sprint_flying_speed : float = 15
##The jump force of the character
@export var jump_force : float = 7
##The mouse sensitivity
@export var sensitivity : float = 0.005
##If true, enables to move the character in the air
@export var air_movement : bool = false
##If true, the sprint key will not have to be held
@export var toggleable_sprint : bool = false
##If true, the crouch key will not have to be held
@export var toggleable_crouch : bool = false
##If true, the flying key will not have to be held
@export var toggleable_fly : bool = true
##The speed at which the character switches between the standing and crouched view. Setting it to 0 will delete the easing
@export var crouch_easing : float = 0.3
##The bigger, the nearer the ground the camera will be when crouched
@export var crouch_deepness : float = 1

@export var label : Label3D

@export_group("Inputs")
##Name of the action for going left
@export var left : String = "left"
##Name of the action for going right
@export var right : String = "right"
##Name of the action for going forward
@export var forward : String = "forward"
##Name of the action for going backward
@export var backward : String = "backward"
##Name of the action for sprinting
@export var sprint : String = "sprint"
##Name of the action for jumping
@export var jump : String = "jump"
##Name of the action for crouching
@export var crouch : String = "crouch"
##Name of the action for flying
@export var flying : String = "flying"
##Name of the action for going up
@export var up : String = "up"
##Name of the action for going down
@export var down : String = "down"
##Name of the input to look right
@export var look_left : String = "look_left"
@export var look_right : String = "look_right"
@export var look_up : String = "look_up"
@export var look_down : String = "look_down"


@onready var head = $Head
@onready var camera = $Head/Camera


var is_sprinting : bool = false
var is_crouching : bool = false

var head_original_height : float

var button_pressed : Array

## ------ added stuff -------------
var authority : int = -1

## --------------------------------

# func _enter_tree():
# 	if authority != -1:
# 		set_multiplayer_authority(authority)


func _ready():
	if is_multiplayer_authority():
		camera.make_current()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		head_original_height = head.position.y


func _input(_event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return
	
	if Input.is_action_pressed("look_down"):
		print("look down")
	if supports_controller:
		if snes_debugger:
			if Input.is_action_just_pressed("look_right"):
				button_pressed.append("right")
			elif Input.is_action_just_released("look_right"):
				if button_pressed.has("right"):
					button_pressed.erase("right")
			if Input.is_action_just_pressed("look_left"):
				button_pressed.append("left")
			elif Input.is_action_just_released("look_left"):
				if button_pressed.has("left"):
					button_pressed.erase("left")
			if Input.is_action_just_pressed("look_up"):
				button_pressed.append("up")
			elif Input.is_action_just_released("look_up"):
				if button_pressed.has("up"):
					button_pressed.erase("up")
			if Input.is_action_just_pressed("look_down"):
				button_pressed.append("down")
			elif Input.is_action_just_released("look_down"):
				if button_pressed.has("down"):
					button_pressed.erase("down")
	
	
	if is_on_floor():
		if toggleable_sprint:
			if Input.is_action_just_pressed(sprint):
				is_sprinting = !is_sprinting
		else:
			if Input.is_action_pressed(sprint):
				is_sprinting = true
			else:
				is_sprinting = false

		if toggleable_crouch:
			if Input.is_action_just_pressed(crouch):
				if is_crouching:
					_uncrouch()
				else:
					_crouch()
		else:
			if Input.is_action_just_pressed(crouch):
				_crouch()
			elif Input.is_action_just_released(crouch):
				_uncrouch()
	else:
		if is_flying:
			if toggleable_sprint:
				if Input.is_action_just_pressed(sprint):
					is_sprinting = !is_sprinting
			else:
				if Input.is_action_pressed(sprint):
					is_sprinting = true
				else:
					is_sprinting = false

	if toggleable_fly:
		if Input.is_action_just_pressed(flying):
			is_flying = !is_flying
			print(is_flying)
	else:
		if Input.is_action_just_pressed(flying):
			is_flying = true
		elif Input.is_action_just_released(flying):
			is_flying = false

func _crouch():
	var target_head_pos = head_original_height - crouch_deepness
	if crouch_easing == 0:
		head.position.y = target_head_pos
	else:
		var tween = create_tween()
		tween.tween_property(head, "position", Vector3(head.position.x, target_head_pos, head.position.z), crouch_easing)
		await tween.finished
	is_crouching = true

func _uncrouch():
	if crouch_easing == 0:
		head.position.y = head_original_height
	else:
		var tween = create_tween()
		tween.tween_property(head, "position", Vector3(head.position.x, head_original_height, head.position.z), crouch_easing)
		await tween.finished
	is_crouching = false


func _unhandled_input(event):
	if !is_multiplayer_authority():
		return
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if supports_keyboard:
		if event is InputEventMouseMotion:
			head.rotate_y(-event.relative.x * sensitivity)
			camera.rotate_x(-event.relative.y * sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		move_and_slide()
		return
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	#add gravity
	if not is_on_floor():
		if !is_flying:
			velocity += get_gravity() * delta
	#handle jumping
	if Input.is_action_just_pressed(jump):
			if is_on_floor():
				velocity.y = jump_force
	#handle basic movement
	var input_dir := Input.get_vector(left, right, forward, backward)
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_flying:
		if direction:
			_set_speed(direction)

		if Input.is_action_pressed(up) and Input.is_action_pressed(down):
			velocity.y = 0
		elif Input.is_action_pressed(up):
			if is_sprinting:
				velocity.y = sprint_flying_speed
			else:
				velocity.y = flying_speed
		elif Input.is_action_pressed(down):
			if is_sprinting:
				velocity.y = sprint_flying_speed * -1
			else:
				velocity.y = flying_speed * -1

		if !direction:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
		if !Input.is_action_pressed(up) and !Input.is_action_pressed(down):
			velocity.y = move_toward(velocity.y, 0, speed)
	else:
		if direction:
			if air_movement:
				_set_speed(direction)
			else:
				if is_on_floor():
					_set_speed(direction)
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
	is_sprinting = false

	move_and_slide()
	
	#Controller input check
	if supports_controller:
		if Input.is_action_pressed("look_right"):
			head.rotation_degrees.y -= controller_sensitivity
		if Input.is_action_pressed("look_left"):
			head.rotation_degrees.y += controller_sensitivity
		if Input.is_action_pressed("look_up"):
			if camera.rotation_degrees.x < 90:
				camera.rotation_degrees.x += controller_sensitivity
		if Input.is_action_pressed("look_down"):
			if camera.rotation_degrees.x > -90:
				camera.rotation_degrees.x -= controller_sensitivity
		
		#Add debugging function for bugged controllers, such as the snes
		if snes_debugger:
			if button_pressed.has("right"):
				head.rotation_degrees.y -= controller_sensitivity
			if button_pressed.has("left"):
				head.rotation_degrees.y += controller_sensitivity
			if button_pressed.has("up"):
				if camera.rotation_degrees.x < 90:
					camera.rotation_degrees.x += controller_sensitivity
			if button_pressed.has("down"):
				if camera.rotation_degrees.x > -90:
					camera.rotation_degrees.x -= controller_sensitivity



func set_authority(id : int) -> void:
	authority = id


func set_player_name(p_name : String) -> void:
	label.text = p_name


func _set_speed(dir):
	var a : float
	if is_flying:
		if is_sprinting:
			a = sprint_flying_speed
		else:
			a = flying_speed
	elif is_crouching:
		a = crouched_speed
	elif is_sprinting:
		a = sprint_speed
	else:
		a = speed
	velocity.x = dir.x * a
	velocity.z = dir.z * a
