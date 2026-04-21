extends CharacterBody2D
class_name Bullet

signal hit(bullet: Bullet, hit: Node2D, hit_count: int)

var direction: Vector2i
var hit_count: int

@export var speed: float = 100

@onready var damage_area := $DamageArea

func _ready():
	damage_area.body_entered.connect(_on_body_entered)
	visibility_changed.connect(_on_visibility_changed)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	hit_count += 1
	hit.emit(self , body, hit_count)

# ObjectPool implementation
func _on_visibility_changed() -> void:
	hit_count = 0