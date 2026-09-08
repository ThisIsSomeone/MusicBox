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
@export var music_manager: MusicManager
@export var octave_shift: int = 0  # -1 for bass, +1 for treble
@export var custom_scale: ScaleResource

@export_group("Visuals")
@export var base_color: Color = Color.CYAN
@export var flash_color: Color = Color.WHITE

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visuals

func _ready() -> void:
	_update_wall_dimensions()
	if visual:
		visual.color = base_color
	if not Engine.is_editor_hint():
		wall_hit.connect(_on_wall_hit)

func _update_wall_dimensions() -> void:
	# Safe node references for tool mode
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

func handle_impact(global_hit_pos: Vector2, impact_speed: float) -> void:
	if Engine.is_editor_hint():
		return

	var local_hit: Vector2 = to_local(global_hit_pos)
	var half_width: float = wall_size.x / 2.0
	var ratio: float = remap(local_hit.x, -half_width, half_width, 0.0, 1.0)
	ratio = clampf(ratio, 0.0, 1.0)

	var intensity: float = clampf(impact_speed / 600.0, 0.2, 1.0)
	wall_hit.emit(ratio, intensity)

	if music_manager:
		music_manager.play_wall_hit(ratio, intensity, octave_shift, custom_scale)

func _on_wall_hit(_ratio: float, _intensity: float) -> void:
	if visual and not Engine.is_editor_hint():
		var tween: Tween = create_tween()
		visual.color = flash_color
		tween.tween_property(visual, "color", base_color, 0.15)
