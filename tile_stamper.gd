class_name TileStamper extends Area2D

@export var source_id: int
@export var tile_pos: Vector2i

@export var dest_name: String

# Yes, the dest_name is not used by ourselves to get the map!
func stamp(dest: TileMapLayer):
	MapLayer.from_shapes2d(self).inverted().stamp_on_tilemap(dest, source_id, tile_pos)
