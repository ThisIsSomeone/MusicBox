class_name MusicManager
extends Node

@export var midi_player: Node
@export var active_scale: ScaleResource
@export var midi_channel: int = 0

@export_group("Health Sound Options")
@export var shorten_notes_by_health: bool = true
## Reduces note volume as health drops so short notes don't choke loudly
@export var soften_notes_by_health: bool = true
## Minimum note length in seconds (keep above ~0.12s so the note attack finishes naturally)
@export var min_note_duration: float = 0.12
@export var max_note_duration: float = 0.5

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
	scale_override: ScaleResource = null,
	health_ratio: float = 1.0
) -> void:
	var scale_to_use: ScaleResource = scale_override if scale_override else active_scale
	
	if not scale_to_use or not midi_player:
		return
	
	var clamped_health: float = clampf(health_ratio, 0.0, 1.0)
	var base_note: int = scale_to_use.get_note_for_ratio(ratio)
	var final_note: int = clampi(base_note + (octave_shift * 12), 0, 127)
	
	# Scale hit intensity down with health if enabled
	var adjusted_intensity: float = intensity
	if soften_notes_by_health:
		adjusted_intensity *= lerp(0.35, 1.0, clamped_health)
		
	var velocity: int = clampi(int(adjusted_intensity * 127), 25, 127)
	
	var note_on_event := InputEventMIDI.new()
	note_on_event.channel = midi_channel
	note_on_event.message = MIDI_MESSAGE_NOTE_ON
	note_on_event.pitch = final_note
	note_on_event.velocity = velocity
	
	if midi_player.has_method("receive_raw_midi_message"):
		midi_player.receive_raw_midi_message(note_on_event)
	
	if shorten_notes_by_health:
		var duration: float = lerp(min_note_duration, max_note_duration, clamped_health)
		_schedule_note_off(final_note, duration)

func _schedule_note_off(note: int, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if midi_player and midi_player.has_method("receive_raw_midi_message"):
		var note_off_event := InputEventMIDI.new()
		note_off_event.channel = midi_channel
		note_off_event.message = MIDI_MESSAGE_NOTE_OFF
		note_off_event.pitch = note
		note_off_event.velocity = 0
		midi_player.receive_raw_midi_message(note_off_event)
