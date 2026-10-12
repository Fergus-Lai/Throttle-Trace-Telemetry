class_name CarData
extends Resource

@export var id: String

@export var speed: float
@export var prev_speed: float
@export var rpm: float
@export var gear: int
@export var max_rpm: float

# TODO: Player
# @export var steering
@export var throttle_input: float
@export var brake_input: float
# @export var steering_input

# @export var world_pos
# @export var velocity_vector
# @export var acceleration

@export var wheel_spin: float
@export var traction: float
@export var slip_angle: float

@export var car_condition: float
@export var front_wing_condition: float
@export var rear_wing_condition: float

# Lap Data
@export var current_lap: LapData
@export var fastest_lap_index: int = -1
@export var laps: Array[LapData]
@export var track_state: String
@export var in_pit: bool
@export var fastest_sector_times: Dictionary

@export var position: int

@export var name: String
@export var number: int

@export var distance_round_track: float;
@export var world_pos: Vector3;
@export var orientation: Vector3;

# @export var brake temp

static func from_car(car: Node, p: int, pps_to_kph: float, pixel_to_meter: float) -> CarData:
	var data = CarData.new()

	data.id = car.get("id")
	
	data.speed = pps_to_kph * car.get("speed")
	data.prev_speed = pps_to_kph * car.get("previous_speed")
	data.wheel_spin = car.get("wheel_spin")
	data.traction = car.get("traction")
	data.slip_angle = car.get("slip_angle")
	data.car_condition = car.get("condition")
	data.front_wing_condition = car.get("front_wing_condition")
	data.rear_wing_condition = car.get("rear_wing_condition")
	data.distance_round_track = car.get("lap_progress") * pixel_to_meter
	data.world_pos = car.get("global_position")
	data.orientation = car.get("global_rotation")


	var pu = car.get("power_unit")

	data.rpm = pu.get("rpm")
	data.gear = pu.get("current_gear") + 1
	data.max_rpm = pu.get("rpm_maximum")

	var lapData: Array = car.get("laps")
	var fastest_lap_index_value = car.get("fastest_lap_index")
	data.fastest_lap_index = int(fastest_lap_index_value) if fastest_lap_index_value != null else -1
	for lap in lapData:
		data.laps.append(LapData.from_node(lap))
	data.current_lap = LapData.from_node(car.get("current_lap"))

	data.fastest_sector_times = car.get("fastest_sector_times")

	data.in_pit = car.get("is_in_pit_lane")
	data.track_state = car.get("track_state")

	var inputs = car.get("inputs")
	data.brake_input = inputs["brake"]
	data.throttle_input = inputs["throttle"]

	data.position = p

	var driver = car.get("driver")
	data.name = driver.get("first_name") + " " + driver.get("last_name")
	data.number = driver.get("number")


	return data


func _to_string() -> String:
	var in_pit_string = "True" if in_pit else "False"
	return (
		"[CarData Snapshot]\n" +
		"  Speed:       %.2f (Prev: %.2f)\n" % [speed, prev_speed] +
		"  Engine:      Gears: %d | RPM: %.0f / %.0f\n" % [gear, rpm, max_rpm] +
		"  Physics:     WheelSpin: %.2f | Traction: %.2f | SlipAngle: %.2f\n" % [wheel_spin, traction, slip_angle] +
		"  Condition:   Car: %.1f%% | F-Wing: %.1f%% | R-Wing: %.1f%%\n" % [car_condition * 100, front_wing_condition * 100, rear_wing_condition * 100] +
		"  Lap:         Lap Count: %.0f\n" % [len(laps)] +
		"  Track State: In Pit: %s | Track State: %s\n" % [in_pit_string, track_state] +
		"  Input:       Throttle: %.0f% | Brake: %.0f%\n" % [throttle_input * 100, brake_input * 100] +
		"  Current Lap: %s" % [current_lap._to_string()]
	)

func to_dict() -> Dictionary:
	return {
		"Id": id,
		"Speed": speed,
		"PrevSpeed": prev_speed,
		"WheelSpin": wheel_spin,
		"Traction": traction,
		"SlipAngle": slip_angle,
		"CarCondition": car_condition,
		"FrontWingCondition": front_wing_condition,
		"RearWingCondition": rear_wing_condition,
		"Rpm": rpm,
		"Gear": gear,
		"MaxRpm": max_rpm,
		"CurrentLap": current_lap.to_dict(),
		"InPit": in_pit,
		"TrackState": track_state,
		"BrakeInput": brake_input,
		"ThrottleInput": throttle_input,
		"Name": name,
		"Number": number,
		"DistanceRoundTrack": distance_round_track,
		"WorldPosition": [world_pos.x, world_pos.y, world_pos.z],
		"Orientation": [orientation.x, orientation.y, orientation.z],
		"Laps": laps.map(func(lap): return lap.to_dict()),
		"FastestLapIndex": fastest_lap_index,
		"FastestSectorTimes": fastest_sector_times,
		"Position": position
	}
