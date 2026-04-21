extends StaticBody2D
class_name SmallTower

signal destroyed(tower: SmallTower)

# Expected to set a unique instance of SmallTowerData
@export var data: SmallTowerData:
	set(value):
		data = value
		if not is_inside_tree():
			return
		sprite.texture = data.sprite
		detection_shape.radius = data.attack_range
		_attack_timer.start(data.shoot_delay)

@export_group("Direction Markers")
@export var up: Marker2D
@export var down: Marker2D
@export var left: Marker2D
@export var right: Marker2D

@onready var bullet_pool := $BulletPool
@onready var sprite := $Sprite2D
@onready var detection_area := $DetectionArea
@onready var detection_shape := $DetectionArea/CollisionShape2D.shape as CircleShape2D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")

var _attack_timer: Timer
var _enemies_in_range: Array[Enemy] = []

func _ready() -> void:
	_attack_timer = Timer.new()
	_attack_timer.timeout.connect(_on_attack_timeout)
	add_child(_attack_timer)
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	
	# testing, for now need to duplicate
	data = data.duplicate()

func damage(value: float) -> void:
	data.health = max(0, data.health - value)
	if data.health == 0:
		destroyed.emit(self )
		queue_free()

func _on_attack_timeout() -> void:
	if _enemies_in_range.is_empty():
		return
	
	anim_state.travel("Shoot")
	
	for direction in data.attack_directions:
		match direction:
			SmallTowerData.AttackDirection.Vertical:
				_spawn_bullet(up, Vector2i.UP)
				_spawn_bullet(down, Vector2i.DOWN)
			SmallTowerData.AttackDirection.Horizontal:
				_spawn_bullet(left, Vector2i.LEFT)
				_spawn_bullet(right, Vector2i.RIGHT)

func _spawn_bullet(position_reference: Marker2D, direction: Vector2i) -> void:
	var bullet = await bullet_pool.get_object() as Bullet
	bullet.sprite.texture = data.bullet_sprite
	bullet.global_position = position_reference.global_position
	bullet.direction = direction
	bullet.hit.connect(_on_bullet_hit)

func _on_bullet_hit(bullet: Bullet, hit: Node2D, hit_count: int) -> void:
	if hit_count > data.hit_count:
		return
	if not (hit is Enemy):
		return
	var enemy = hit as Enemy
	enemy.damage(data.damage)
	if hit_count == data.hit_count:
		_return_bullet(bullet)

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy and body not in _enemies_in_range:
		_enemies_in_range.append(body)

func _on_body_exited(body: Node2D) -> void:
	if body is Enemy:
		_enemies_in_range.erase(body)
	# elif body is Bullet: # out of range, return to pool
		# _return_bullet(body)

func _return_bullet(bullet: Bullet) -> void:
	if bullet.hit.is_connected(_on_bullet_hit):
		bullet.hit.disconnect(_on_bullet_hit)
		bullet_pool.call_deferred("return_object", bullet)
