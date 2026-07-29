class_name PlacementLayer extends MapLayer

## Handles checks on the room to tell if it can be placed

var target_layers: Dictionary[String, Callable]
var placement_layers: Dictionary[String, Callable]

# Do not garbage collect this!
var old_layer: MapLayer

func _init(layer: MapLayer, _target_layers: Dictionary[String, Callable], _placement_layers: Dictionary[String, Callable] = {}):
	size = layer.size
	data = layer.data
	cell_size = layer.cell_size
	world_bounds = layer.world_bounds
	target_layers = _target_layers
	placement_layers = _placement_layers
	
	old_layer = layer
	
	print("Placement Layer created:")
	print(old_layer)
	print("Target layers: ", target_layers)
	print("Placement layers: ", placement_layers)

func test_placeable(stack: MapLayerStack, pos: Placement) -> bool:
	for layer in target_layers:
		if !target_layers[layer].call(stack.layers[layer], pos):
			return false
	return true

func place(stack: MapLayerStack, pos: Placement):
	for layer in placement_layers:
		placement_layers[layer].call(stack.layers[layer], pos)
