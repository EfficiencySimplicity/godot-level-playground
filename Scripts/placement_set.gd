class_name PlacementSet extends Resource

# TODO: percentages
@export var elements: Array[PackedScene]

func get_element():
	return elements.pick_random().instantiate()
