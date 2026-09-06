@tool
extends CharacterBody2D

@export_category("Movement")
@export var speed: float = 400.0

@export_category("Splitting")
@export var max_balls: int = 30
@export_range(0.0, 90.0) var split_angle: float = 45.0
@export var split_cooldown_duration: float = 0.15
@export var wall_separation: float = 2.0
@export var child_separation: float = 1.0

@export_category("Editor")
@export var launch_target: Vector2 = Vector2(100, 100):
	set(value):
		launch_target = value
		queue_redraw()


var split_cooldown: float = 0.0


func _ready() -> void:
	add_to_group("balls")

	if Engine.is_editor_hint():
		return

	if velocity == Vector2.ZERO:
		if launch_target != Vector2.ZERO:
			velocity = launch_target.normalized() * speed
		else:
			velocity = Vector2(1, 1).normalized() * speed


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_update_split_cooldown(delta)

	var collision := move_and_collide(velocity * delta)

	if collision == null:
		return

	var collider := collision.get_collider()

	if collider.is_in_group("balls"):
		_handle_ball_collision(collider, collision)
	else:
		_handle_wall_collision(collision)


func _update_split_cooldown(delta: float) -> void:
	if split_cooldown > 0.0:
		split_cooldown = maxf(
			split_cooldown - delta,
			0.0
		)


func _handle_wall_collision(collision: KinematicCollision2D) -> void:
	var total_balls := get_tree().get_nodes_in_group("balls").size()

	if split_cooldown <= 0.0 and total_balls < max_balls:
		_split_ball(collision)
	else:
		_bounce_off_wall(collision)


func _bounce_off_wall(collision: KinematicCollision2D) -> void:
	velocity = velocity.bounce(
		collision.get_normal()
	).normalized() * speed


func _handle_ball_collision(
	collider: Node,
	collision: KinematicCollision2D
) -> void:
	var other_ball := collider as CharacterBody2D

	if other_ball == null:
		_bounce_off_wall(collision)
		return

	# Calculate the collision axis from the two ball centers.
	var center_normal := (
		global_position - other_ball.global_position
	).normalized()

	if center_normal == Vector2.ZERO:
		center_normal = collision.get_normal()

	# Reflect along the center-to-center axis.
	velocity = velocity.bounce(center_normal).normalized() * speed

	# Separate the balls slightly so they don't remain
	# embedded in one another.
	global_position += center_normal * child_separation


func _split_ball(collision: KinematicCollision2D) -> void:
	var normal := collision.get_normal()

	# Calculate the direction the ball would have bounced
	# if it had not split.
	var base_bounce_dir := velocity.bounce(normal).normalized()

	# Create the two perfectly symmetrical directions.
	var split_radians := deg_to_rad(split_angle)

	var dir1 := base_bounce_dir.rotated(
		split_radians
	).normalized()

	var dir2 := base_bounce_dir.rotated(
		-split_radians
	).normalized()

	# IMPORTANT:
	# Keep the ball's center based on its current position.
	# collision.get_position() is the CONTACT POINT, not
	# the center of the ball.
	var spawn_pos := global_position

	# Push the split away from the wall slightly.
	spawn_pos += normal * wall_separation

	# Place the original ball.
	global_position = spawn_pos + dir1 * child_separation
	velocity = dir1 * speed
	split_cooldown = split_cooldown_duration

	# Defer creation of the second ball so we don't modify
	# the physics scene tree in the middle of a physics callback.
	_spawn_split_child.call_deferred(
		spawn_pos + dir2 * child_separation,
		dir2
	)


func _spawn_split_child(
	spawn_position: Vector2,
	direction: Vector2
) -> void:
	# Check again because other balls may have split before
	# this deferred call executes.
	var total_balls := get_tree().get_nodes_in_group("balls").size()

	if total_balls >= max_balls:
		return

	var scene := load(scene_file_path)

	if scene == null:
		push_error(
			"Could not load ball scene: " + scene_file_path
		)
		return

	var new_ball := scene.instantiate() as CharacterBody2D

	if new_ball == null:
		push_error("Ball scene root must be CharacterBody2D.")
		return

	get_parent().add_child(new_ball)

	new_ball.global_position = spawn_position
	new_ball.velocity = direction * speed

	if new_ball.has_method("set_split_cooldown"):
		new_ball.set_split_cooldown(
			split_cooldown_duration
		)

	# Prevent the two freshly-created balls from immediately
	# colliding with one another.
	add_collision_exception_with(new_ball)
	new_ball.add_collision_exception_with(self)


func set_split_cooldown(value: float) -> void:
	split_cooldown = value


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(
			Vector2.ZERO,
			launch_target,
			Color.GREEN,
			3.0
		)

		draw_circle(
			launch_target,
			5.0,
			Color.RED
		)
