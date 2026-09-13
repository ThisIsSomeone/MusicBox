class_name MusicManager
extends Node

@export var midi_player: Node
@export var active_scale: ScaleResource
@export var midi_channel: int = 0

@export_group("Thinning Strategies")

## Strategy 1: Limits overall note count when too many balls strike simultaneously
@export var enable_rate_limiting: bool = true
## Time window (in seconds) to measure note density (e.g. 0.05 = 50ms)
@export var thinning_window: float = 0.05
## Maximum notes permitted to play within the thinning_window
@export var max_notes_in_window: int = 3

## Strategy 2: Suppresses triggering the exact same pitch in rapid succession
@export var enable_pitch_cooldown: bool = true
## Minimum time (in seconds) required before the exact same pitch can re-trigger
@export var pitch_cooldown_duration: float = 0.08

## Strategy 3 (Wall String): Batches simultaneous hits on a wall and plays the median (middle) note
@export var enable_wall_representative_note: bool = true
## Time window (in seconds) to collect hits per wall (0.016s ≈ 1 physics frame at 60Hz)
@export var wall_batch_window: float = 0.016

@export_group("Health Sound Options")
@export var shorten_notes_by_health: bool = true
## Reduces note volume as health drops so short notes don't choke loudly
@export var soften_notes_by_health: bool = true
## Minimum note length in seconds (keep above ~0.12s so the note attack finishes naturally)
@export var min_note_duration: float = 0.12
@export var max_note_duration: float = 0.5

## Other variables
var current_program: int = -1
var _recent_note_times: Array[float] = []
var _last_pitch_times: Dictionary = {} # Pitch (int) -> Timestamp (float)
var _wall_hit_buffers: Dictionary = {}   # Wall ID (String) -> Array[Dictionary]

func _ready() -> void:
	if midi_player and not midi_player.is_node_ready():
		await midi_player.ready

	if active_scale:
		apply_scale(active_scale)

func apply_scale(new_scale: ScaleResource) -> void:
	active_scale = new_scale
	if not active_scale or not midi_player:
		return
		
	# Convert 1-based GM program numbers (1-128) to 0-based MIDI range (0-127)
	var prog: int = clampi(active_scale.program_number - 1, 0, 127)
	
	if prog == current_program:
		return
		
	current_program = prog
	
	var change_event := InputEventMIDI.new()
	change_event.channel = midi_channel
	change_event.message = MIDI_MESSAGE_PROGRAM_CHANGE
	change_event.instrument = prog # arlez80's MidiPlayer checks 'instrument'
	
	if midi_player.has_method("receive_raw_midi_message"):
		midi_player.receive_raw_midi_message(change_event)

func play_wall_hit(
	ratio: float, 
	intensity: float = 1.0, 
	octave_shift: int = 0, 
	scale_override: ScaleResource = null,
	health_ratio: float = 1.0,
	wall_id: String = ""
) -> void:
	# Strategy 3: Buffer hit if enabled, otherwise play directly
	if enable_wall_representative_note and wall_id != "":
		_buffer_wall_hit(wall_id, ratio, intensity, octave_shift, scale_override, health_ratio)
		return

	_execute_wall_hit(ratio, intensity, octave_shift, scale_override, health_ratio)

func _execute_wall_hit(
	ratio: float, 
	intensity: float, 
	octave_shift: int, 
	scale_override: ScaleResource,
	health_ratio: float
) -> void:
	var scale_to_use: ScaleResource = scale_override if scale_override else active_scale
	
	if not scale_to_use or not midi_player:
		return

	var base_note: int = scale_to_use.get_note_for_ratio(ratio)
	var final_note: int = clampi(base_note + (octave_shift * 12), 0, 127)

	# Strategy 2: Pitch Cooldown
	if enable_pitch_cooldown and _is_pitch_cooldowned(final_note):
		return

	# Strategy 1: Rate Limiting
	if enable_rate_limiting and _is_rate_limited():
		return

	if scale_override and scale_override != active_scale:
		apply_scale(scale_override)
	
	var clamped_health: float = clampf(health_ratio, 0.0, 1.0)
	
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

## Thinnning Strategies

func _is_rate_limited() -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	
	# Keep only timestamps that occurred within our sliding window
	_recent_note_times = _recent_note_times.filter(func(t: float) -> bool: return now - t < thinning_window)
	
	if _recent_note_times.size() >= max_notes_in_window:
		return true
		
	_recent_note_times.append(now)
	return false

func _is_pitch_cooldowned(pitch: int) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	
	if _last_pitch_times.has(pitch):
		if now - _last_pitch_times[pitch] < pitch_cooldown_duration:
			return true
			
	_last_pitch_times[pitch] = now
	return false

func _schedule_wall_batch_resolution(wall_id: String) -> void:
	await get_tree().create_timer(wall_batch_window).timeout
	
	if not _wall_hit_buffers.has(wall_id):
		return
		
	var hits: Array = _wall_hit_buffers[wall_id]
	_wall_hit_buffers.erase(wall_id)
	
	if hits.is_empty():
		return
		
	# Sort hits by ratio to find the median pitch position on the wall
	hits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["ratio"] < b["ratio"]
	)
	
	# Pick the middle element (median)
	var median_index: int = hits.size() / 2
	var rep_hit: Dictionary = hits[median_index]
	
	_execute_wall_hit(
		rep_hit["ratio"], 
		rep_hit["intensity"], 
		rep_hit["octave_shift"], 
		rep_hit["scale_override"], 
		rep_hit["health_ratio"]
	)

func _buffer_wall_hit(
	wall_id: String, 
	ratio: float, 
	intensity: float, 
	octave_shift: int, 
	scale_override: ScaleResource, 
	health_ratio: float
) -> void:
	var hit_data := {
		"ratio": ratio,
		"intensity": intensity,
		"octave_shift": octave_shift,
		"scale_override": scale_override,
		"health_ratio": health_ratio
	}
	
	if not _wall_hit_buffers.has(wall_id):
		_wall_hit_buffers[wall_id] = []
		_wall_hit_buffers[wall_id].append(hit_data)
		_schedule_wall_batch_resolution(wall_id)
	else:
		_wall_hit_buffers[wall_id].append(hit_data)
