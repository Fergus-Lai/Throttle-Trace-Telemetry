extends Node

enum SessionState {
	Prepare,
	WaitingForHost,
	Countdown,
	Active,
	Finished
}

enum TrackState {
	Prepare,
	WaitingForHost,
	Countdown,
	Active,
	Finished
}


const LOG_NAME := "TelemetryMod:Main"

# TODO: Configurable
const UDP_HOST := "127.0.0.1"
const UDP_PORT := 5005

var udp := PacketPeerUDP.new()
var udp_ready := false

var track_data: Node = null
var track_name: String
var player: Node = null
var params: RefCounted = null
var ordered_cars: Array = []
var teams: Array = []
var running: bool = false
var track_length: float
var pps_to_kph: float
var pixel_to_meter: float

var _session_active := false
var _session_id := ""


func _ready() -> void:
	ModLoaderLog.info("Running Mod", LOG_NAME)
	_setup_udp()
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
	ordered_cars = track_data.get("ordered_cars")
	pps_to_kph = track_data.get("_pps_to_kph")
	pixel_to_meter = track_data.get("_pixels_to_meters")
	var raw_teams = track_data.get("teams")
	var surface: Node = track_data.get("surface") as Node
	
	if raw_teams is Array:
		teams.assign(raw_teams)
		
	if params == null or player == null or len(teams) == 0 or len(ordered_cars) == 0 or pps_to_kph == null or pixel_to_meter == null or surface == null:
		await get_tree().process_frame
		_check_telemetry_ready_loop()
		return

	
	var profile = params.get("profile")
	var total_length = surface.get("total_length")
	if profile == null or total_length == null:
		await get_tree().process_frame
		_check_telemetry_ready_loop()
		return
	track_name = profile.get("track_name")
	track_length = total_length * pixel_to_meter
	
		
	if params.session.type != 2:
		ModLoaderLog.debug("Not Race", LOG_NAME)
		return
		
	_send_session_data()

func _send_session_data() -> void:
	if track_data == null:
		await get_tree().process_frame
		_check_for_game_data_loop()
		return
		
	var current_state = track_data.get("state")
	var has_started = bool(track_data.get("has_session_started"))
	var session_is_active = has_started and current_state != TrackState.Finished
	if session_is_active and not _session_active:
		_session_id = "%s-%s" % [str(Time.get_unix_time_from_system()), str(Time.get_ticks_usec())]
	_session_active = session_is_active

	var cars_data: Dictionary[String, Dictionary] = {}
	var completed_laps := 0
	var sector_number := 1
	var fastest_lap = track_data.get("fastest_lap")

	if has_started:
		for i in ordered_cars.size():
			var current_car = CarData.from_car(ordered_cars[i], i + 1, pps_to_kph, pixel_to_meter)
			cars_data[current_car.id] = current_car.to_dict()

		var raw_player_laps = player.get("laps")
		var player_laps: Array = raw_player_laps if raw_player_laps is Array else []
		var current_lap = player.get("current_lap")
		var raw_sector_times = current_lap.get("sector_times") if current_lap != null else null
		var sector_times: Dictionary = raw_sector_times if raw_sector_times is Dictionary else {}

		completed_laps = player_laps.size()
		sector_number = sector_times.size() + 1

		
	var session_time = track_data.get("session_time")

	_send_telemetry(
		{
			"Version": 1,
			"SessionType": "Race",
			"SessionState": current_state,
			"PlayerID": player.id,
			"SessionId": _session_id,
			"CompletedLaps": completed_laps,
			"SectorNumber": sector_number,
			"Cars": cars_data,
			"SessionTime": session_time,
			"TrackName": track_name,
			"NumberOfLaps": params.get("laps"),
			"TrackLength": track_length,
			"FastestLap": fastest_lap
		}
	)

	await get_tree().create_timer(0.1).timeout
	_send_session_data()
	return

func _setup_udp() -> void:
	var err := udp.set_dest_address(UDP_HOST, UDP_PORT)

	if err != OK:
		ModLoaderLog.error("Failed to configure UDP: %s" % err, LOG_NAME)
		return

	udp_ready = true
	ModLoaderLog.info("UDP sender ready", LOG_NAME)

func _send_telemetry(data: Dictionary) -> void:
	if not udp_ready:
		return

	var packet := JSON.stringify(data).to_utf8_buffer()
	var err := udp.put_packet(packet)

	if err != OK:
		ModLoaderLog.error("UDP send failed: %s" % err, LOG_NAME)