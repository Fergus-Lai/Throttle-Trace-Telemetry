extends Node

const LOG_NAME := "TelemetryMod:Main"

var track_data: Node = null
var player: Node = null

func _ready() -> void:
	ModLoaderLog.info("Running Mod", LOG_NAME)
	find_game_data()

func find_game_data() -> void:
	while track_data == null:
		track_data = get_node_or_null("/root/Main/GameLayer/Track")

		if track_data == null:
			await get_tree().create_timer(0.5).timeout

	ModLoaderLog.info("Game data node found!", LOG_NAME)
	start_telemetry()

func start_telemetry() -> void:
	# Read the live data after the node exists.
	player = track_data.get("player")
	ModLoaderLog.info(str(player.track_position_index), LOG_NAME)
