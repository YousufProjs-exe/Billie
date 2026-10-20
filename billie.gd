
extends Node2D

var speed = 300.0
var direction = Vector2(1, 0)
var screen_size = Vector2.ZERO
var window_size = Vector2(200, 200)
var idle_timer = 0.0
var is_idling = false
var is_dragging = false
var drag_offset = Vector2.ZERO

@onready var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D

func _ready():
	randomize()
	screen_size = Vector2(DisplayServer.screen_get_size())
	animated_sprite.play("walk")
	area.input_event.connect(_on_area_input)

func maybe_idle():
	if randf() < 0.3:
		is_idling = true
		idle_timer = randf_range(1.0, 3.0)
		speed = 0.0
		animated_sprite.play("meow")

func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var tween = create_tween()
			tween.tween_property(animated_sprite, "offset:y", -30.0, 0.15)
			tween.parallel().tween_property(animated_sprite, "scale", Vector2(1.15, 0.85), 0.15)
			tween.tween_property(animated_sprite, "offset:y", 0.0, 0.15)
			tween.parallel().tween_property(animated_sprite, "scale", Vector2(1.0, 1.0), 0.15)
			
			is_dragging = true
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			var win_pos = Vector2(DisplayServer.window_get_position())
			drag_offset = mouse_pos - win_pos
		else:
			is_dragging = false

func _physics_process(delta: float) -> void:
	if is_dragging:
		var mouse_pos = Vector2(DisplayServer.mouse_get_position())
		var new_win_pos = mouse_pos - drag_offset
		DisplayServer.window_set_position(Vector2i(new_win_pos))
		return

	if is_idling:
		idle_timer -= delta
		if idle_timer <= 0.0:
			is_idling = false
			speed = 300.0
			animated_sprite.play("walk")
		return

	var window_position = Vector2(DisplayServer.window_get_position())
	var max_x = maxf(0.0, screen_size.x - window_size.x)
	var max_y = maxf(0.0, screen_size.y - window_size.y)

	window_position += direction * speed * delta

	if window_position.x <= 0.0:
		window_position.x = 0.0
		direction.x = 1.0
		animated_sprite.flip_h = false
		maybe_idle()
	elif window_position.x >= max_x:
		window_position.x = max_x
		direction.x = -1.0
		animated_sprite.flip_h = true
		maybe_idle()
		
	if window_position.y <= 0.0:
		window_position.y = 0.0
		direction.y = 1.0
	elif window_position.y >= max_y:
		window_position.y = max_y
		direction.y = -1.0
		
	DisplayServer.window_set_position(Vector2i(window_position))
