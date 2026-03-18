class_name SceneSwitcher extends Node

var _stack : Array[Node]

static var _instance : SceneSwitcher

func _ready() -> void:
	_instance = self
	call_deferred("push_scene", load("res://lobby.tscn").instantiate())

static func push_scene(scene : Node) -> void:
	if _instance._stack.size() > 0:
		_instance.get_tree().root.remove_child(_instance._stack.back())

	_instance._stack.append(scene)
	_instance.get_tree().root.add_child(scene)

static func pop_scene() -> void:
	if _instance._stack.size() > 0:
		_instance.get_tree().root.remove_child(_instance._stack.back())
		_instance._stack.pop_back()
