extends MidiPlayer

func _ready() -> void:
	super._ready()

	_play_note(60, 100)

	await get_tree().create_timer(0.5).timeout

	_stop_note(60)

func _play_note(note: int, velocity: int) -> void:
	var event := InputEventMIDI.new()
	event.message = MIDI_MESSAGE_NOTE_ON
	event.channel = 0
	event.pitch = note
	event.velocity = velocity

	receive_raw_midi_message(event)


func _stop_note(note: int) -> void:
	var event := InputEventMIDI.new()
	event.message = MIDI_MESSAGE_NOTE_OFF
	event.channel = 0
	event.pitch = note
	event.velocity = 0

	receive_raw_midi_message(event)
