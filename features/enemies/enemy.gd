extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy)

# Expected to set a unique instance of EnemyData 
@export var data: EnemyData:
	set(value):
		data = value
		_rescale_sprite()

@export var target_size: Vector2 = Vector2(32, 32)

@onready var nav_agent := $NavigationAgent2D
@onready var detection_area := $DetectionArea
@onready var damage_zone := $DamageZone

var _nearby_towers: Array[SmallTower] = []
var _damage_timer: Timer
var _damaging_towers: Array[SmallTower] = []
var _is_damaging_main_tower: bool

const DAMAGE_DELAY: float = 1

func _ready() -> void:
	_rescale_sprite()

	_damage_timer = Timer.new()
	_damage_timer.timeout.connect(_on_damage_timeout)
	add_child(_damage_timer)

	damage_zone.body_entered.connect(_on_damage_zone_entered)
	damage_zone.body_exited.connect(_on_damage_zone_exited)
	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)
	visibility_changed.connect(_on_visibility_changed)

func _physics_process(delta: float) -> void:
	_move(delta)

func damage(value: float) -> void:
	data.health -= value
	if data.health <= 0:
		died.emit(self )

func _move(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		return
		
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	
	velocity = direction * data.speed

	global_position += velocity * delta

func _on_damage_timeout() -> void:
	print("damage timeout")
	if _is_damaging_main_tower:
		Game.main_tower.damage(data.damage)
	for tower in _damaging_towers:
		tower.damage(data.damage)

func _on_damage_zone_entered(body: Node2D) -> void:
	print(body)
	if body is SmallTower:
		var tower = body as SmallTower
		if tower not in _damaging_towers:
			_damaging_towers.append(tower)
			if _damage_timer.is_stopped():
				_damage_timer.start(DAMAGE_DELAY)
	if body is MainTower:
		_is_damaging_main_tower = true
		if _damage_timer.is_stopped():
			_damage_timer.start(DAMAGE_DELAY)

func _on_damage_zone_exited(body: Node2D) -> void:
	if body is SmallTower:
		var tower = body as SmallTower
		_damaging_towers.erase(tower)
	if body is MainTower:
		_is_damaging_main_tower = false

	if _damaging_towers.is_empty() and not _is_damaging_main_tower:
		_damage_timer.stop()

func _on_detection_area_entered(body: Node2D) -> void:
	if not (body is SmallTower):
		return

	var tower = body as SmallTower
	if _nearby_towers.has(tower):
		return

	_nearby_towers.append(tower)
	_update_target()

func _on_detection_area_exited(body: Node2D) -> void:
	if not (body is SmallTower):
		return
	
	var tower = body as SmallTower
	if not _nearby_towers.has(tower):
		return

	_nearby_towers.erase(tower)
	_update_target()

# ObjectPool implementation
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_set_destination(Game.main_tower.global_position)

func _update_target() -> void:
	if _nearby_towers.is_empty():
		_set_destination(Game.main_tower.global_position)
		return
	
	var closest_tower: SmallTower
	var closest_distance: float = INF
	for tower in _nearby_towers:
		var distance = global_position.distance_squared_to(tower.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_tower = tower
	
	var distance_to_main_tower = Game.main_tower.global_position.distance_squared_to(closest_tower.global_position)
	if distance_to_main_tower < closest_distance:
		_set_destination(Game.main_tower.global_position)
	else:
		_set_destination(closest_tower.global_position)

func _set_destination(target: Vector2) -> void:
	nav_agent.target_position = target

func _rescale_sprite() -> void:
	scale = target_size / data.sprite.get_size()
