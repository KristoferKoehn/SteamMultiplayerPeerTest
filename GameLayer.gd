extends Node

var game_active : bool = false

var peer_dict : Dictionary[int, Array] = {}


func start_game_host(level_path : String) -> void:
	SceneSwitcher._instance.pop_scene.rpc()
	SceneSwitcher._instance.push_scene_from_path.rpc(level_path)
	game_active = true
	var spawn_index = 0

	for peer_id in GameState.players:
		SceneSwitcher.multiplayer_spawner.spawn({
			0 : peer_id,
			1 : "%s" % peer_id,
			2 : Vector3(spawn_index, spawn_index, spawn_index - 5)
		})

		spawn_index += 5


	GameState.peer_connected.connect(func (id):
		start_game_client.rpc_id(id, level_path)
	)
	GameState.peer_connected.connect(spawn_player)
	multiplayer.peer_disconnected.connect(func(id):
		for n in GameLayer.peer_dict[id]:
			n.queue_free()
	)


	


@rpc("any_peer")
func start_game_client(level_path : String) -> void:
	SceneSwitcher._instance.pop_scene.rpc()
	SceneSwitcher._instance.push_scene_from_path.rpc(level_path)

func spawn_player(peer_id : int) -> void:

	SceneSwitcher.multiplayer_spawner.spawn({
		0 : peer_id,
		1 : "%s" % peer_id,
		2 : Vector3(0, 10, 0)
	})

