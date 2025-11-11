extends Node

var _registry := {}

func register(reg_name: String, node: Node):
	_registry[reg_name] = node

func get_reg(reg_name: String) -> Node:
	return _registry.get(reg_name)

func unregister(reg_name: String):
	_registry.erase(reg_name)

func has(reg_name: String) -> bool:
	return _registry.has(reg_name)

func _get(property: StringName) -> Variant:
	return _registry.get(property)
