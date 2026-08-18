extends CharacterBody2D

@onready var plr_anim = $anim
@onready var ox = $bubble
@onready var lt = $left
@onready var rt = $right
@onready var o2_lab = $labels/o2
@onready var dft_lab = $labels/dft
@onready var hp_lab = $labels/hp
@onready var atm_lab = $labels/press
@export var water_sur: Node2D
@export var water_btm: Node2D

var hp: float = 10.0
var o2: float = 100.0
var dft: float = 0.0
var atm: float = 1.0
const max_speed: int = 110
const acceleration: int = 5
const friction: int = 8

func _ready():
	if !water_sur: water_sur = get_tree().current_scene.find_child("water_sur", true, false)
	if !water_btm: water_btm = get_tree().current_scene.find_child("water_btm", true, false)

func _physics_process(delta: float) -> void:
	var input = Vector2(Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")).normalized()
	if input:
		plr_anim.play("dive")
		if input.x != 0: plr_anim.flip_h = input.x < 0
		plr_anim.speed_scale = (velocity/max_speed).length() + 0.5
	else:
		plr_anim.play("idle")
		plr_anim.speed_scale = 1.0
	velocity = velocity.lerp(input * max_speed, delta * (acceleration if input else friction))
	move_and_slide()
	if Input.is_action_pressed("ui_left"): ox.position = lt.position
	elif Input.is_action_pressed("ui_right"): ox.position = rt.position

func _process(delta: float) -> void:
	if water_sur and water_btm:
		var cur_v = global_position.y - water_sur.global_position.y
		var total_v = water_btm.global_position.y - water_sur.global_position.y
		dft = max(0.0, cur_v * 0.05)
		atm = 1.0 + (max(0.0, cur_v / total_v) * 19.0)
	
	if dft > 0.1: 
		o2 -= 0.2 * atm * delta
	else: 
		o2 += 25.0 * delta
	o2 = clamp(o2, 0.0, 100.0)
	
	if o2 <= 0: 
		hp -= 1.5 * delta * (atm * 0.5)
	hp = clamp(hp, 0.0, 10.0)
	dft_lab.text = str(snapped(dft, 0.1))
	o2_lab.text = str(snapped(o2, 0.1))
	hp_lab.text = str(snapped(hp, 0.1))
	atm_lab.text = str(snapped(atm, 0.1))
	
	if hp <= 0: 
		get_tree().reload_current_scene()
