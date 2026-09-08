class_name MusicManager
extends Node

@export var midi_player: Node
@export var active_scale: ScaleResource
@export var midi_channel: int = 0

func _ready() -> void:
	if active_scale:
		apply_scale(active_scale)

func apply_scale(new_scale: ScaleResource) -> void:
	active_scale = new_scale
	if midi_player:
		if midi_player.has_method("program_change"):
			midi_player.program_change(midi_channel, active_scale.program_number)
		elif midi_player.has_method("send_program_change"):
			midi_player.send_program_change(midi_channel, active_scale.program_number)

func play_wall_hit(
	ratio: float, 
	intensity: float = 1.0, 
	octave_shift: int = 0, 
	scale_override: ScaleResource = null
) -> void:
	var scale_to_use: ScaleResource = scale_override if scale_override else active_scale
	
	if not scale_to_use:
		print_orphan_nodes()
		push_warning("MusicManager: No ScaleResource assigned!")
		return
		
	if not midi_player:
		push_warning("MusicManager: No MidiPlayer assigned!")
		return
	
	var base_note: int = scale_to_use.get_note_for_ratio(ratio)
	var final_note: int = clampi(base_note + (octave_shift * 12), 0, 127)
	var velocity: int = clampi(int(intensity * 127), 30, 127)
	
	# Handle varying MIDI plugin method signatures
	if midi_player.has_method("note_on"):
		midi_player.note_on(midi_channel, final_note, velocity)
	elif midi_player.has_method("send_note_on"):
		midi_player.send_note_on(midi_channel, final_note, velocity)
	elif midi_player.has_method("play_note"):
		midi_player.play_note(final_note, velocity)
