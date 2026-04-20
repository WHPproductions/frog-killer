extends Node
class_name ObjectPool

@export var scene_to_pool: PackedScene
@export var initial_pool_size: int = 5

var _pool: Array[Node] = []

func _ready() -> void:
	# Pre-instantiate objects and hide them
	for i in range(initial_pool_size):
		_create_new_object()

func _create_new_object() -> Node:
	var obj = scene_to_pool.instantiate()
	_pool.append(obj)
	
	# Add to tree but keep inactive
	add_child.call_deferred(obj)
	obj.process_mode = PROCESS_MODE_DISABLED
	obj.hide()
	return obj

## Returns an object from the pool. 
## If the pool is empty, it expands automatically.
func get_object() -> Node:
	var obj: Node
	
	# Find an inactive object
	for item in _pool:
		if item.process_mode == PROCESS_MODE_DISABLED:
			obj = item
			break
	
	# If none found, grow the pool
	if not obj:
		obj = _create_new_object()
		# Wait for it to be ready since it's deferred
		await obj.ready

	obj.process_mode = PROCESS_MODE_INHERIT
	obj.show()
	return obj

## Returns the object to the pool for reuse
func return_object(obj: Node) -> void:
	if obj in _pool:
		obj.process_mode = PROCESS_MODE_DISABLED
		obj.hide()
