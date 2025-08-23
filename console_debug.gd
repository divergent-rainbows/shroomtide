# Debug.gd
extends Node

func log(msg: String) -> void:
	if OS.is_debug_build():
		print(msg)

func log_var(name: String, value) -> void:
	if OS.is_debug_build():
		print(name, ": ", value)

func log_message(prefix: String, text: String) -> void:
	if OS.is_debug_build():
		print("[DEBUG] ", prefix, text)

# Special case: name + formatted string
func log_format(name: Variant, fmt: String, values: Array) -> void:
	if OS.is_debug_build():
		print(name, " ", fmt % values)
