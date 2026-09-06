extends Label

func _process(_delta: float) -> void:
	var ball_count := get_tree().get_nodes_in_group("balls").size()
	text = "Balls: " + str(ball_count)
