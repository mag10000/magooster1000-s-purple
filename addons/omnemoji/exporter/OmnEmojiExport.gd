@tool
extends EditorExportPlugin
## OmnEmoji Export Plugin
##
## Minimal export plugin that logs export status. Font resources (.tres) with
## embedded data are automatically included by Godot's dependency system when
## they're referenced in project.godot (theme/custom_font).
##
## The raw TTF files are NOT added to exports - the fonts are already embedded
## as Base64 data in OmnEmojiMerged.tres, making them self-contained and
## fully cross-platform (Web, Mobile, Desktop).

const PLUGIN_NAME := "OmnEmojiExport"


func _get_name() -> String:
	return PLUGIN_NAME


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	print("[OmnEmoji Export] ✓ Font resources will be included via Godot's dependency system")
	print("[OmnEmoji Export]   (fonts embedded in OmnEmojiMerged.tres)")


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	pass


func _export_end() -> void:
	print("[OmnEmoji Export] ✓ Export complete")
