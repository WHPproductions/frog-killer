extends Node

signal score_changed(new_score)

@export var main_tower: MainTower

var score: int = 0:
    set(value):
        score = value
        score_changed.emit(score)

func add_score(value: int) -> void:
    score += value