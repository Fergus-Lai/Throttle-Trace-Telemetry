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
@export var last_lap: LapData
@export var lap_count: int
@export var lap_progress: float
@export var track_state: String
@export var in_pit: bool

@export var position: int
@export var track_position: int

@export var name: String
@export var number: int

# @export var brake temp

static func from_car(car: Node, p: int, pps_to_kph: float) -> CarData:
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


	var pu = car.get("power_unit")

	data.rpm = pu.get("rpm")
	data.gear = pu.get("current_gear")
	data.max_rpm = pu.get("rpm_maximum")

	var laps: Array = car.get("laps")
	data.lap_count = len(laps)
	data.current_lap = LapData.from_node(car.get("current_lap"))
	if len(laps) > 0:
		data.last_lap = LapData.from_node(laps[-1])
	var fastest_lap_index = car.get("fastest_lap_index")
	if fastest_lap_index != null and len(laps) > fastest_lap_index:
		data._fastest_lap = LapData.from_node(laps[fastest_lap_index])

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
		"  Lap:         Lap Count: %.0f | Lap Progress: %.2f%%\n" % [lap_count, lap_progress * 100] +
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
		"LapCount": lap_count,
		"CurrentLap": current_lap.to_dict(),
		"InPit": in_pit,
		"TrackState": track_state,
		"BrakeInput": brake_input,
		"ThrottleInput": throttle_input,
		"Name": name,
		"Number": number
	}
