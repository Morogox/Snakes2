extends Node

var _registry := {}

func register(name: String, node: Node):
	_registry[name] = node

func get_reg(name: String) -> Node:
	return _registry.get(name)

func unregister(name: String):
	_registry.erase(name)

func has(name: String) -> bool:
	return _registry.has(name)

func _get(property: StringName) -> Variant:
	return _registry.get(property)
