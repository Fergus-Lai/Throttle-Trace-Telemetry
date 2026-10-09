class_name UDP_Data
extends Resource

@export var cars: Array[CarData]
@export var playerId: String

func to_dict() -> Dictionary:
    return {
        cars: cars.map(func(car): return car.to_dict()),
        playerId: playerId
    }