class_name OmnEmoji
extends RefCounted
## OmnEmoji - Runtime API for accessing plugin information
##
## This class provides runtime access to OmnEmoji plugin data.
## Use OmnEmoji.VERSION to get the current version string.

## Current plugin version - updated automatically by release script
const VERSION := "1.0.34"

## Plugin name
const NAME := "OmnEmoji"

## Path to the addon
const ADDON_PATH := "res://addons/omnemoji/"

## Path to the merged font resource
const FONT_RESOURCE := "res://addons/omnemoji/resources/OmnEmojiMerged.tres"


## Get the merged emoji font resource
static func get_font() -> Font:
	if ResourceLoader.exists(FONT_RESOURCE):
		return load(FONT_RESOURCE) as Font
	return null


## Check if OmnEmoji is properly installed
static func is_installed() -> bool:
	return ResourceLoader.exists(FONT_RESOURCE)
