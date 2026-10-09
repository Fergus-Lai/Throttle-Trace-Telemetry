extends Node

const LOG_NAME := "TelemetryMod:Main"

var track_data: Node = null
var player: Node = null
var params: RefCounted = null
var teams: Array = []
var running: bool = false
var session_started: bool = false

func _ready() -> void:
	ModLoaderLog.info("Running Mod", LOG_NAME)
	_check_for_game_data_loop()

func _check_for_game_data_loop() -> void:
	track_data = get_node_or_null("/root/Main/GameLayer/Track")
	
	if track_data == null:
		# Safely wait 0.5 seconds on the main thread and try again
		await get_tree().create_timer(0.5).timeout
		_check_for_game_data_loop()
		return

	ModLoaderLog.info("Game data node found!", LOG_NAME)
	_check_telemetry_ready_loop()

func _check_telemetry_ready_loop() -> void:
	params = track_data.get("params")
	player = track_data.get("player")
	var raw_teams = track_data.get("teams")
	if raw_teams is Array:
		teams.assign(raw_teams)
		
	if params == null or player == null or len(teams) == 0:
		await get_tree().process_frame
		_check_telemetry_ready_loop()
		return
		
	if params.session.type != 2:
		ModLoaderLog.debug("Not Race", LOG_NAME)
		return
		
	_wait_for_session_start()

func _wait_for_session_start() -> void:
	session_started = track_data.get("has_session_started")
	
	if not session_started:
		await get_tree().process_frame
		_wait_for_session_start()
		return
		
	ModLoaderLog.info("Session Started", LOG_NAME)