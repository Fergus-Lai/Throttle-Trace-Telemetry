class_name LapData
extends Resource

enum Compound {
	Hard,
	Medium,
	Soft,
	Wet,
	Intermediate
}

var start_session_time: float
var end_session_time: float

var time: float:
	get: return end_session_time - start_session_time

var start_position_index: int
var position_index: int
var out_lap: bool
var in_lap: bool
var delta_to_leader: float
var condition: float
var compound: Compound
var tire_condition: float
var sector_times: Dictionary
var invalid: bool

static func from_node(source_node: RefCounted) -> LapData:
	var lap = LapData.new()
	
	# Mapping node properties directly to the data class
	lap.start_session_time = source_node.get("start_session_time")
	lap.end_session_time = source_node.get("end_session_time")
	
	lap.start_position_index = source_node.get("start_position_index")
	lap.position_index = source_node.get("position_index")
	
	lap.out_lap = source_node.get("out_lap")
	lap.in_lap = source_node.get("in_lap")
	
	lap.delta_to_leader = source_node.get("delta_to_leader")
	lap.condition = source_node.get("condition")
	lap.compound = source_node.get("compound")
	lap.tire_condition = source_node.get("tire_condition")
	lap.sector_times = source_node.get("sector_times")
	lap.invalid = source_node.get("invalid")
	
	return lap

func _to_string() -> String:
	var flags: Array[String] = []
	if out_lap: flags.append("OUT")
	if in_lap: flags.append("IN")
	if invalid: flags.append("INVALID")
	
	var flags_str = " [%s]" % ", ".join(flags) if not flags.is_empty() else ""
	var pos_str = "%d->%d" % [start_position_index, position_index] if start_position_index != -1 and position_index != -1 else "%d -> " % [start_position_index] if start_position_index != -1 else ""
	
	return "Lap(Time: %.3fs, Pos: %s, Compound: %s, Sectors: %s)%s" % [
		time,
		pos_str,
		Compound.keys()[compound] if compound in Compound.values() else str(compound),
		str(sector_times),
		flags_str
	]

func to_dict() -> Dictionary:
	return {
		"StartSessionTime": start_session_time,
		"EndSessionTime": end_session_time,
		"StartPositionIndex": start_position_index,
		"PositionIndex": position_index,
		"OutLap": out_lap,
		"InLap": in_lap,
		"DeltaToLeader": delta_to_leader,
		"Condition": condition,
		"Compound": compound,
		"TireCondition": tire_condition,
		"SectorTimes": sector_times,
		"Invalid": invalid,
	}