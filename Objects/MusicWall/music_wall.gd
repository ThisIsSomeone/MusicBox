@tool
class_name MusicWall
extends StaticBody2D

signal wall_hit(ratio: float, intensity: float)

@export var wall_size: Vector2 = Vector2(400, 20):
	set(value):
		wall_size = value
		if is_node_ready():
			_update_wall_dimensions()

@export_group("Audio Configuration")
@export var music_manager: MusicManager:
	set(value):
		music_manager = value
		queue_redraw()

@export var octave_shift: int = 0  # -1 for bass, +1 for treble
@export var custom_scale: ScaleResource:
	set(value):
		custom_scale = value
		queue_redraw()

@export_group("Visuals")
@export var base_color: Color = Color.CYAN
@export var flash_color: Color = Color.WHITE
@export var show_segments: bool = true:
	set(value):
		show_segments = value
		queue_redraw()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visuals

func _ready() -> void:
	_update_wall_dimensions()
	if visual:
		visual.color = base_color
	if not Engine.is_editor_hint():
		wall_hit.connect(_on_wall_hit)

func _update_wall_dimensions() -> void:
	var vis: ColorRect = visual if visual else get_node_or_null("Visuals") as ColorRect
	var col: CollisionShape2D = collision_shape if collision_shape else get_node_or_null("CollisionShape2D") as CollisionShape2D

	if vis:
		vis.size = wall_size
		vis.position = -wall_size / 2.0

	if col:
		var rect_shape: RectangleShape2D
		if col.shape is RectangleShape2D:
			rect_shape = col.shape as RectangleShape2D
		else:
			rect_shape = RectangleShape2D.new()
			col.shape = rect_shape
		rect_shape.size = wall_size

	queue_redraw()

# Add this near the top of music_wall.gd with your other variables
var active_segment_flashes: Dictionary = {} # segment_index: int -> alpha: float

func _draw() -> void:
	if not show_segments:
		return

	var total_notes: int = _get_total_notes()
	if total_notes <= 1:
		return

	var half_w: float = wall_size.x / 2.0
	var half_h: float = wall_size.y / 2.0
	var step_w: float = wall_size.x / float(total_notes)

	for i in range(total_notes):
		var x_start: float = -half_w + (i * step_w)
		var segment_rect := Rect2(Vector2(x_start, -half_h), Vector2(step_w, wall_size.y))

		# 1. Subtle alternating stripes for adjacent notes
		if i % 2 == 1:
			draw_rect(segment_rect, Color(0, 0, 0, 0.12))

		# 2. Flash highlight ONLY on this hit segment
		if active_segment_flashes.has(i) and active_segment_flashes[i] > 0.0:
			var flash_overlay: Color = flash_color
			flash_overlay.a *= active_segment_flashes[i] # Fade out with tween
			draw_rect(segment_rect, flash_overlay)

		# 3. Vertical divider lines
		if i > 0:
			draw_line(
				Vector2(x_start, -half_h),
				Vector2(x_start, half_h),
				Color(0, 0, 0, 0.4),
				1.5
			)

func _on_wall_hit(ratio: float, _intensity: float) -> void:
	if Engine.is_editor_hint():
		return

	var total_notes: int = _get_total_notes()
	if total_notes <= 0:
		return

	# Calculate exact segment index that was struck (0 to total_notes - 1)
	var seg_index: int = clampi(int(ratio * total_notes), 0, total_notes - 1)

	# Tween alpha of ONLY this specific segment from 1.0 back down to 0.0
	var tween := create_tween()
	active_segment_flashes[seg_index] = 1.0
	queue_redraw()

	tween.tween_method(
		func(alpha: float) -> void:
			active_segment_flashes[seg_index] = alpha
			queue_redraw(),
		1.0,
		0.0,
		0.18
	)

func _get_total_notes() -> int:
	var scale: ScaleResource = custom_scale
	if not scale and music_manager:
		scale = music_manager.active_scale

	if scale and scale.scale_intervals.size() > 0:
		return scale.scale_intervals.size() * scale.octaves
	return 8  # Default preview fallback (8 segments)

func handle_impact(global_hit_pos: Vector2, impact_speed: float, ball: CharacterBody2D = null) -> void:
	if Engine.is_editor_hint():
		return

	var health_ratio: float = 1.0
	if ball and "health" in ball and "starting_health" in ball:
		if ball.starting_health > 0:
			health_ratio = float(ball.health) / float(ball.starting_health)

	var local_hit: Vector2 = to_local(global_hit_pos)
	var half_width: float = wall_size.x / 2.0
	var ratio: float = remap(local_hit.x, -half_width, half_width, 0.0, 1.0)
	ratio = clampf(ratio, 0.0, 1.0)

	var intensity: float = clampf(impact_speed / 600.0, 0.2, 1.0)
	wall_hit.emit(ratio, intensity)

	if music_manager:
		music_manager.play_wall_hit(
			ratio, 
			intensity, 
			octave_shift, 
			custom_scale, 
			health_ratio
		)
