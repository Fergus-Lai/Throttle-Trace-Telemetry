extends Node

enum SessionState {
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
var player: Node = null
var params: RefCounted = null
var cars: Array = []
var teams: Array = []
var running: bool = false
var session_state: SessionState = SessionState.Prepare
var pps_to_kph: float


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
	cars = track_data.get("cars")
	pps_to_kph = track_data.get("_pps_to_kph")
	var raw_teams = track_data.get("teams")
	if raw_teams is Array:
		teams.assign(raw_teams)
		
	if params == null or player == null or len(teams) == 0 or len(cars) == 0 or pps_to_kph == null:
		await get_tree().process_frame
		_check_telemetry_ready_loop()
		return
		
	if params.session.type != 2:
		ModLoaderLog.debug("Not Race", LOG_NAME)
		return
		
	_send_session_data()

func _send_session_data() -> void:
	if track_data == null:
		await get_tree().process_frame
		_check_for_game_data_loop()
		return
		
	session_state = track_data.get("state")
	if session_state != SessionState.Active:
		ModLoaderLog.info("Session Ended", LOG_NAME)
		return

	
	var playerCar = CarData.from_car(player, pps_to_kph)
	var cars_data: Dictionary[String, Dictionary] = {}
	for car in cars:
		var current_car = CarData.from_car(car, pps_to_kph)
		cars_data[current_car.id] = current_car.to_dict()

	var session_time = track_data.get("session_time")
	_send_telemetry(
		{
			"Version": 1,
			"SessionType": "Race",
			"SessionState": session_state,
			"PlayerID": playerCar.id,
			"Cars": cars_data,
			"SessionTime": session_time
		}
	)

	await get_tree().process_frame
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