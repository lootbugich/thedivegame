extends CharacterBody2D

@onready var plr_anim = $anim
@onready var ox = $bubble
@onready var lt = $left
@onready var rt = $right
@onready var o2_lab = $labels/o2
@onready var o2_inf = $labels/hp2
@onready var dft_lab = $labels/dft
@onready var hp_lab = $labels/hp
@onready var atm_lab = $labels/press
@export var water_sur: Node2D
@export var water_btm: Node2D

@onready var arrow = $labels/Arrow
@onready var interact = $interact
@onready var int_hint = $interact/int

@onready var map_scanner = $mapper # area2d для исследования карты
@onready var map = $Map
@onready var battery = $Map/TextureProgressBar
@onready var battery_f: float = 6.0 

var active_zones: Array[Area2D] = []
var interactable_areas: Array[Area2D] = []
var hp: float = 10.0
var o2: float = 100.0
var dft: float = 0.0
var atm: float = 1.0
var pressure_mult: float = 1.0
const max_speed: int = 110
const acceleration: int = 5
const friction: int = 8

func _ready():
	print(self.get_path())
	o2_inf.visible = false
	int_hint.visible = false
	if !water_sur: water_sur = get_tree().current_scene.find_child("water_sur", true, false)
	if !water_btm: water_btm = get_tree().current_scene.find_child("water_btm", true, false)
	var detector = get_node_or_null("detector")
	if detector:
		detector.area_entered.connect(_on_area_entered)
		detector.area_exited.connect(_on_area_exited)
		interact.area_entered.connect(_on_interact_entered)
		interact.area_exited.connect(_on_interact_exited)

func update_hint():
	int_hint.visible = interactable_areas.size() > 0

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
	
	scan_environment()
	
	if Input.is_action_pressed("ui_left"):
		ox.position = lt.position
	elif Input.is_action_pressed("ui_right"):
		ox.position = rt.position


func scan_environment():
	if not map.visible or battery.value <= 0: 
		return 

	var num_rays = 20 
	var scan_radius = 150
	var space_state = get_world_2d().direct_space_state

	for i in range(num_rays):
		var angle = deg_to_rad(i * (360.0 / num_rays))
		var target_pos = global_position + Vector2(cos(angle), sin(angle)) * scan_radius
		var query = PhysicsRayQueryParameters2D.create(global_position, target_pos)
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		
		if result:
			map.add_point(result.position)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("inter"):
		execute_interaction()

	if map.visible:
		if battery_f > 0:
			battery_f -= 0.13 * delta
			battery.value = int(ceil(battery_f))
			map.is_powered = true
		else:
			battery_f = 0
			battery.value = 0
			map.is_powered = false
	if Input.is_action_just_pressed("map"):
		map.visible = !map.visible
	if map.visible and map.is_powered:
		scan_environment()
		
	if Input.is_action_just_pressed("inf_ox") and o2_inf.visible == false:
		o2 = INF
		o2_lab.visible = false
		o2_inf.visible = true
	elif Input.is_action_just_pressed("inf_ox") and o2_inf.visible == true:
		o2 = 100
		o2_lab.visible = true
		o2_inf.visible = false
		
	if water_sur and water_btm:
		var cur_v = global_position.y - water_sur.global_position.y
		var total_v = water_btm.global_position.y - water_sur.global_position.y
		var base_atm = 1.0 + (max(0.0, cur_v / total_v) * 19.0)
		atm = base_atm * pressure_mult
		dft = max(0.0, cur_v * 0.05)
	
	if dft > 0.1 and o2_inf.visible == false: 
		o2 -= 0.15 * atm * delta
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
	
	var target_deg = remap(atm, 1.0, 30.0, -79.0, 79.0)
	target_deg = clamp(target_deg, -79.0, 79.0) 
	arrow.rotation = lerp(arrow.rotation, deg_to_rad(target_deg), delta * 5.0)
	
	if hp <= 0: 
		get_tree().reload_current_scene()
		
func _on_area_entered(area: Area2D) -> void:
	if "zone_multiplier" in area:
		active_zones.append(area)
		update_pressure()
		
func _on_area_exited(area: Area2D) -> void:
	if area in active_zones:
		active_zones.erase(area)
		update_pressure()

func update_pressure() -> void:
	if active_zones.size() > 0:
		pressure_mult = active_zones.back().zone_multiplier
	else:
		pressure_mult = 1.0
		
func _on_interact_entered(area: Area2D):
	if "can_interact" in area:
		interactable_areas.append(area)
		update_hint()

func _on_interact_exited(area: Area2D):
	if area in interactable_areas:
		interactable_areas.erase(area)
		update_hint()
		
func execute_interaction():
	if interactable_areas.size() > 0:
		var target = interactable_areas.back()
		if target.has_method("interact"):
			target.interact()
		_interact()
		
func _interact():
	print("plr interact")
