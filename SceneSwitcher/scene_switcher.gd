class_name SceneSwitcher extends Node

var _stack : Array[Node]

static var _instance : SceneSwitcher
static var multiplayer_spawner : MultiplayerSpawner


func _ready() -> void:
	_instance = self
	call_deferred("push_scene", load("res://lobby.tscn").instantiate())

	multiplayer_spawner =  MultiplayerSpawner.new()
	add_child(multiplayer_spawner)

	multiplayer_spawner.spawn_function = Callable(

		func(data):
			var player : Node = load("res://addons/gremlins_first_person/gremlins_fpc.tscn").instantiate()
			player.set_multiplayer_authority(data[0])
			player.set_player_name(data[1])
			player.position = data[2]
			GameLayer.peer_dict[data[0]] = [player]
			return player

	)

	multiplayer_spawner.spawn_path = get_tree().root.get_path()
	multiplayer_spawner.add_spawnable_scene("res://addons/gremlins_first_person/gremlins_fpc.tscn")


@rpc("any_peer", "call_local")
static func push_scene(scene : Node) -> void:
	if _instance._stack.size() > 0:
		_instance.get_tree().root.remove_child(_instance._stack.back())

	_instance._stack.append(scene)
	_instance.get_tree().root.add_child(scene)


@rpc("any_peer", "call_local")
static func push_scene_from_path(path : String) -> void:
	if _instance._stack.size() > 0:
		_instance.get_tree().root.remove_child(_instance._stack.back())

	var scene = load(path).instantiate()

	_instance._stack.append(scene)
	_instance.get_tree().root.add_child(scene)


@rpc("any_peer", "call_local")
static func pop_scene() -> void:
	if _instance._stack.size() > 0:
		_instance.get_tree().root.remove_child(_instance._stack.back())
		_instance._stack.pop_back()


static func instance() -> SceneSwitcher:
	return _instance


static func get_multiplayer_spawner() -> MultiplayerSpawner:
	return multiplayer_spawner
