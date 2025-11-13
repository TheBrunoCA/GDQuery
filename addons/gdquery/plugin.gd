@tool
extends EditorPlugin

const bridge_autoload_name := "GDBridge"
const bridge_autoload_path := "res://addons/gdquery/GDQueryBridge.gd"

const gdquery_autoload_name := "GDQuery"
const gdquery_autoload_path := "res://addons/gdquery/GDQuery.gd"


func _enable_plugin() -> void:
	add_autoload_singleton(bridge_autoload_name, bridge_autoload_path)
	add_autoload_singleton(gdquery_autoload_name, gdquery_autoload_path)

func _disable_plugin() -> void:
	remove_autoload_singleton(bridge_autoload_name)
	remove_autoload_singleton(gdquery_autoload_name)


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
