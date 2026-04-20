extends Resource
class_name EnemyData

@export_group("Visual")
@export var sprite: Texture2D

@export_group("Stats")
@export var speed: float = 100
@export var health: float = 1
@export var damage: float = 1
@export var score: int = 1
@export var weight: int = 1