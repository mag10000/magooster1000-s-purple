extends Node

var stars := 0
var spawn_level := "starting_zone"
var spawn_point := Vector2.ZERO

func register_fields():
	Talo.register_field("stars", stars)
	Talo.register_field("spawn_point", spawn_point)
	Talo.register_field("spawn_level", spawn_level)
