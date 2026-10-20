
extends Node2D

var speed = 300.0
var direction = Vector2(1, 0)
var screen_size = Vector2.ZERO
var window_size = Vector2(200, 200)
var idle_timer = 0.0
var idle_cooldown = 0.0
var is_idling = false
var is_dragging = false
var drag_offset = Vector2.ZERO
var is_sitting = false
var is_turning = false
var tap_count = 0
var idle_chance = 0.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D

func _ready():
	randomize()
	screen_size = Vector2(DisplayServer.screen_get_size())
	animated_sprite.play("walk")
	area.input_event.connect(_on_area_input)
	idle_cooldown = randf_range(4.0, 8.0)

func maybe_idle():
	if not is_idling and randf() < 0.3:
		is_idling = true
		idle_timer = randf_range(2.0, 4.0)
		speed = 0.0
		animated_sprite.play("turn_around")

func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_sitting:
				is_sitting = false
				is_idling = false
				speed = 300.0
				animated_sprite.play("walk")
			else:
				is_sitting = true
				is_idling = false
				speed = 0.0
				animated_sprite.stop()

func _physics_process(delta: float) -> void:
	
	if is_sitting:
		return
		
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
			idle_cooldown = randf_range(4.0, 8.0)
		return
		
	idle_cooldown -= delta
	if idle_cooldown <= 0.0:
		maybe_idle()
		if is_idling:
			return
		idle_cooldown = randf_range(4.0, 8.0)
		
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
