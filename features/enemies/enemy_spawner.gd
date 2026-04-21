extends Node2D
class_name EnemySpawner

@export var play_area: ReferenceRect
@export var enemies: Array[EnemyData]

@export var spawn_rate_curve: Curve
@export var speed_rate_curve: Curve
@export var health_rate_curve: Curve

@onready var _enemy_pool := $EnemyPool

var _start_time: float
var _spawn_timer: Timer

func _ready():
	_start_time = Time.get_ticks_msec()

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_on_timer_timeout)
	add_child(_spawn_timer)
	_schedule_spawn(0)

func _on_timer_timeout() -> void:
	var minute = (Time.get_ticks_msec() - _start_time) / 60_000 # 60 000 msecs / min
	_spawn_enemy(minute)
	_schedule_spawn(minute)

func _spawn_enemy(minute: float) -> void:
	var enemy_instance = await _enemy_pool.get_object() as Enemy
	var enemy_data = _get_enemy_data(minute)
	var spawn_position = _get_spawn_position(play_area, enemy_instance.target_size)
	enemy_instance.global_position = spawn_position
	enemy_instance.data = enemy_data
	enemy_instance.died.connect(_on_enemy_died)

func _on_enemy_died(enemy: Enemy) -> void:
	Game.add_score(enemy.data.score)
	enemy.died.disconnect(_on_enemy_died)
	_enemy_pool.return_object(enemy)

func _schedule_spawn(minute: float) -> void:
	var spawn_rate = spawn_rate_curve.sample(minute)
	var time = 1 / spawn_rate
	_spawn_timer.start(time)

## Returns a global position on the outer edge of the given ReferenceRect
func _get_spawn_position(rect_node: ReferenceRect, offset_buffer: Vector2) -> Vector2:
	# 1. Get the boundaries in global space
	var rect_pos = rect_node.global_position
	var rect_size = rect_node.size
	
	# Pick a random side: 0=Top, 1=Bottom, 2=Left, 3=Right
	var side = randi() % 4
	var spawn_pos = Vector2.ZERO
	
	match side:
		0: # Top
			spawn_pos.x = randf_range(rect_pos.x, rect_pos.x + rect_size.x)
			spawn_pos.y = rect_pos.y - offset_buffer.y
		1: # Bottom
			spawn_pos.x = randf_range(rect_pos.x, rect_pos.x + rect_size.x)
			spawn_pos.y = rect_pos.y + rect_size.y + offset_buffer.y
		2: # Left
			spawn_pos.x = rect_pos.x - offset_buffer.x
			spawn_pos.y = randf_range(rect_pos.y, rect_pos.y + rect_size.y)
		3: # Right
			spawn_pos.x = rect_pos.x + rect_size.x + offset_buffer.x
			spawn_pos.y = randf_range(rect_pos.y, rect_pos.y + rect_size.y)
			
	return spawn_pos

## Returns a scaled random EnemyData
func _get_enemy_data(minute: float) -> EnemyData:
	var random_enemy = _get_weighted_enemy()
	var new_enemy = random_enemy.duplicate()
	new_enemy.health *= health_rate_curve.sample(minute)
	new_enemy.speed *= speed_rate_curve.sample(minute)
	return new_enemy

## Returns a random EnemyData from the array based on their weight properties
func _get_weighted_enemy() -> EnemyData:
	if enemies.is_empty():
		return null
		
	# 1. Calculate the total weight
	var total_weight: float = 0.0
	for enemy in enemies:
		total_weight += enemy.weight
		
	# 2. Pick a random number in that range
	var roll: float = randf_range(0.0, total_weight)
	
	# 3. Step through the list to find the "winner"
	var cursor: float = 0.0
	for enemy in enemies:
		cursor += enemy.weight
		if roll <= cursor:
			return enemy
			
	return enemies.back() # Fallback
