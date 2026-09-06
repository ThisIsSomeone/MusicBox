@tool
extends CharacterBody2D

@export var speed: float = 400.0
@export var max_balls: int = 30

@export var launch_target: Vector2 = Vector2(100, 100):
	set(value):
		launch_target = value
		queue_redraw()

var split_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("balls")
	
	if not Engine.is_editor_hint():
		if velocity == Vector2.ZERO:
			if launch_target != Vector2.ZERO:
				velocity = launch_target.normalized() * speed
			else:
				velocity = Vector2(1, 1).normalized() * speed

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	if split_cooldown > 0.0:
		split_cooldown -= delta
		
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		
		# If hitting a wall (not another ball)
		if not collider.is_in_group("balls"):
			var total_balls = get_tree().get_nodes_in_group("balls").size()
			if split_cooldown <= 0.0 and total_balls < max_balls:
				_split_ball(collision)
			else:
				velocity = velocity.bounce(collision.get_normal())
		else:
			_handle_ball_collision(collider, collision)

func _handle_ball_collision(collider: Node, collision: KinematicCollision2D) -> void:
	# Calculate normal vector directly from center-point to center-point
	var center_normal = (global_position - collider.global_position).normalized()
	if center_normal == Vector2.ZERO:
		center_normal = collision.get_normal()
		
	# Bounce velocity along the exact center-line axis
	velocity = velocity.bounce(center_normal).normalized() * speed
	
	# Micro-nudge outward so their hitboxes un-overlap instantly
	global_position += center_normal * 2.0

func _split_ball(collision: KinematicCollision2D) -> void:
	var normal = collision.get_normal()
	var base_bounce_dir = velocity.bounce(normal).normalized()
	
	var dir1 = base_bounce_dir.rotated(deg_to_rad(45))
	var dir2 = base_bounce_dir.rotated(deg_to_rad(-45))
	
	var spawn_pos = collision.get_position() + (normal * 6.0)
	global_position = spawn_pos
	
	velocity = dir1 * speed
	split_cooldown = 0.15
	
	var new_ball = load(scene_file_path).instantiate() as CharacterBody2D
	new_ball.global_position = spawn_pos
	new_ball.velocity = dir2 * speed
	new_ball.split_cooldown = 0.15
	
	add_collision_exception_with(new_ball)
	new_ball.add_collision_exception_with(self)
	
	get_parent().call_deferred("add_child", new_ball)

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(Vector2.ZERO, launch_target, Color.GREEN, 3.0)
		draw_circle(launch_target, 5.0, Color.RED)
