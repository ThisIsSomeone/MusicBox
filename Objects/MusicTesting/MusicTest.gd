extends MidiPlayer

func _ready() -> void:
	super._ready()

	_play_note(60, 100)

func _play_note(note: int, velocity: int) -> void:
	var event := InputEventMIDI.new()
	event.message = MIDI_MESSAGE_NOTE_ON
	event.channel = 0
	event.pitch = note
	event.velocity = velocity

	receive_raw_midi_message(event)
