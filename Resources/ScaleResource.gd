class_name ScaleResource
extends Resource

@export var scale_name: String = "Major Pentatonic"
@export var root_note: int = 60 # C4
@export var scale_intervals: Array[int] = [0, 2, 4, 7, 9] # Semitone offsets
@export var octaves: int = 2
@export var program_number: int = 0 # General MIDI Instrument (0 = Piano, 11 = Vibraphone, etc.)

func get_note_for_ratio(ratio: float) -> int:
	var total_notes: int = scale_intervals.size() * octaves
	var index: int = clampi(int(ratio * total_notes), 0, total_notes - 1)
	var octave_offset: int = (index / scale_intervals.size()) * 12
	var interval: int = scale_intervals[index % scale_intervals.size()]
	return root_note + octave_offset + interval
