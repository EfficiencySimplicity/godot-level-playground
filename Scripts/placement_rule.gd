class_name PlacementRule extends Resource

# target layer, method name
@export var tests: Dictionary[String, String]
@export var target: String

@export var place_method: PLACE_METHOD

enum PLACE_METHOD {
	IGNORE,
	PLACE,
	STAMP
}

func test(tester: MapLayer, dest: MapLayerStack, placement: Placement):
	for test_target in tests:
		# This is sorta fun to say
		if !tester[tests[test_target]].call(dest.layers[test_target], placement):
			return false
	return true

func place(tester: MapLayer, dest: MapLayerStack, placement: Placement):
	if target == null or target.is_empty(): return
	match place_method:
		PLACE_METHOD.IGNORE:
			return
		PLACE_METHOD.PLACE:
			tester.place_on(dest.layers[target], placement)
		PLACE_METHOD.STAMP:
			tester.stamp_on(dest.layers[target], placement)
		
