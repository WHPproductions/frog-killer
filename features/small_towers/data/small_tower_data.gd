extends Resource
class_name SmallTowerData

@export_category("Identifier")
@export var name: String
@export var sprite: Texture2D
@export var bullet_sprite: Texture2D

@export_category("Stats")
@export var damage: float = 2
@export var attack_range: float = 48 # I think default tile size is 16px
@export var health: float = 8
@export var hit_count: int = 1
@export var shoot_delay: float = 1
@export var attack_directions: Array[AttackDirection]
@export var weight: float = 1

enum AttackDirection {Vertical, Horizontal}