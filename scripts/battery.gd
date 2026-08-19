extends Area2D

@onready var plr = get_node("/root/game/plr")
@onready var sprite = get_node("../Battery")
@onready var coll1 = get_node("../CollisionShape2D")
var can_interact = true 

func interact():
	plr.battery_f = 6.0 
	queue_free()
	sprite.queue_free()
	coll1.queue_free()
	print("battery")

func _ready():
	if plr:
		print("plr found")
