class_name MapLayerStack

var layers: Dictionary[String, MapLayer]
var size: Vector2i

static func from_layer_dict(dict: Dictionary[String, MapLayer]) -> MapLayerStack:
	var stack = MapLayerStack.new()
	stack.layers = dict
	stack.size = dict.values()[0].size
	return stack
	
func cell_to_world(cell: Vector2i):
	return layers.values()[0].cell_to_world(cell)
