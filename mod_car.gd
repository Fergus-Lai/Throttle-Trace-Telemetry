class_name CarData
extends Resource

@export var speed: float
@export var prev_speed: float
@export var rpm: float
@export var gear: int
@export var max_rpm: float

# TODO: Player
# @export var steering
# @export var throttle_input
# @export var brake_input
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

# @export var brake temp

static func from_car(car: Node) -> CarData:
	var data = CarData.new()
	
	data.speed = car.get("speed")
	data.prev_speed = car.get("previous_speed")
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
	
	return data


func _to_string() -> String:
	return (
		"[CarData Snapshot]\n" +
		"  Speed:       %.2f (Prev: %.2f)\n" % [speed, prev_speed] +
		"  Engine:      Gears: %d | RPM: %.0f / %.0f\n" % [gear, rpm, max_rpm] +
		"  Physics:     WheelSpin: %.2f | Traction: %.2f | SlipAngle: %.2f\n" % [wheel_spin, traction, slip_angle] +
		"  Condition:   Car: %.1f%% | F-Wing: %.1f%% | R-Wing: %.1f%%" % [car_condition, front_wing_condition, rear_wing_condition]
	)