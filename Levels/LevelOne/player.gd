extends CharacterBody3D

@export var cam : Camera3D
@export var label : Label3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var authority : int = -1


# what is there left to do?
# -refactor to be less ass on integration. 
#  () change gamestate file and autoload name to be more descriptive
#  () figure out how to do lobby better, those lambdas suck and cause crazy problems on scene change
#  () GameLayer necessity? might be a necessary spaghetti pit. Need special code for getting the game running anyway might as well have it there
#  () find opportunities for more abstraction/cleanup. Maybe less code is needed if the shit is organized better.
# STEAM TESTING!!! gotta test that bullshit somehow


func _ready():
	if authority != -1:
		set_multiplayer_authority(authority)
		if is_multiplayer_authority():
			cam.make_current()
	else:
		print("fr*cked up auth")


func _physics_process(delta):
	if !is_multiplayer_authority():
		move_and_slide()
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	# sync_position.rpc(position)


@rpc("call_remote")
func sync_position(pos : Vector3) -> void:
	position = pos


@rpc("any_peer", "call_local")
func teleport(pos : Vector3) -> void:
	position = pos


@rpc("any_peer", "call_local")
func set_player_name(p_name : String) -> void:
	label.text = p_name


@rpc("any_peer", "call_local")
func set_authority(id : int) -> void:
	authority = id
