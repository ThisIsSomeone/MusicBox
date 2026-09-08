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
	if midi_player and midi_player.has_method("program_change"):
		midi_player.program_change(midi_channel, active_scale.program_number)

func play_hit(ratio: float, velocity_factor: float = 1.0) -> void:
	if not active_scale or not midi_player:
		return
	
	var note: int = active_scale.get_note_for_ratio(ratio)
	var vel: int = clampi(int(velocity_factor * 127), 30, 127)
	
	if midi_player.has_method("note_on"):
		midi_player.note_on(midi_channel, note, vel)
