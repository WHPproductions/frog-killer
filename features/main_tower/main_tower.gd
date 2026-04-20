extends StaticBody2D
class_name MainTower

signal destroyed
signal health_changed(new_value)

@export var health: float = 100:
    set(value):
        health = value
        health_changed.emit(value)

func _ready():
    Game.main_tower = self

func damage(value: float) -> void:
    if health == 0:
        return
    
    health = max(0, health - value)
    if health == 0:
        destroyed.emit()
