extends Control

var effect
var recording


func _ready():
	# We get the index of the "Record" bus.
	var idx = AudioServer.get_bus_index("Record")
	# And use it to retrieve its first effect, which has been defined
	# as an "AudioEffectRecord" resource.
	effect = AudioServer.get_bus_effect(idx, 0)


func _on_record_button_pressed():
	if effect.is_recording_active():
		recording = effect.get_recording()
		$Play.disabled = false
		$Done.disabled = false
		effect.set_recording_active(false)
		$Record.text = "Record"
		$Label.text = ""
	else:
		$Play.disabled = true
		$Done.disabled = true
		effect.set_recording_active(true)
		$Record.text = "Stop"
		$Label.text = "Recording..."


func _on_play_button_pressed():
	print(recording)
	print(recording.format)
	print(recording.mix_rate)
	print(recording.stereo)
	var data = recording.get_data()
	print(data.size())
	$AudioStreamRecord.stream = recording
	$AudioStreamRecord.play()
	recording.save_to_wav("user://recording" + Time.get_datetime_string_from_system() + ".wav")
