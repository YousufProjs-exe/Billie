extends Node2D

var action_timer = 0.0
var speed = 300.0
var direction = 1.0
var screen_size = Vector2.ZERO
var window_size = Vector2(200, 200)
var idle_timer = 0.0
var idle_cooldown = 0.0
var is_idling = false
var is_dragging = false
var mouse_pressed_on_billie = false
var hold_timer = 0.0
var pickup_delay = 0.22
var drag_offset = Vector2.ZERO
var walk_y = -1.0
var is_sleeping = false
var is_action_animation = false
var click_count = 0
var click_timer = 0.0
var click_delay = 0.3

@onready var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D

func _ready():
	randomize()
	screen_size = Vector2(DisplayServer.screen_get_size())
	walk_y = maxf(0.0, screen_size.y - window_size.y - 15.0)
	animated_sprite.play("walk")
	area.input_event.connect(_on_area_input)
	idle_cooldown = randf_range(4.0, 8.0)
	
func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if mouse_pressed_on_billie or is_dragging:
				return
			mouse_pressed_on_billie = true
			hold_timer = 0.0
			drag_offset = (Vector2(DisplayServer.window_get_position())- Vector2(DisplayServer.mouse_get_position()))
			
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if is_dragging:
				is_dragging = false
				mouse_pressed_on_billie = false
				var pos = Vector2(DisplayServer.window_get_position())
				walk_y = clampf(pos.y, 0.0, maxf(0.0, screen_size.y - window_size.y))
				is_sleeping = false
				is_idling = false
				is_action_animation = false
				speed = 300.0
				click_count = 0
				animated_sprite.play("walk")
				idle_cooldown = randf_range(4.0, 8.0)
				return
			if mouse_pressed_on_billie:
				mouse_pressed_on_billie = false
				if is_sleeping:
					is_sleeping = false
					speed = 300.0
					click_count = 0
					animated_sprite.play("walk")
					idle_cooldown = randf_range(4.0, 8.0)
					return
				click_count += 1
				click_timer = click_delay
				
func handle_clicks():
	is_idling = false
	is_action_animation = false
	is_sleeping = false
	speed = 0.0
	if click_count == 1:
		is_action_animation = true
		action_timer = 1.0
		animated_sprite.play("meow")
	elif click_count == 2:
		is_action_animation = true
		action_timer = 2.5
		animated_sprite.play("turn_around")
	elif click_count >= 3:
		is_sleeping = true
		animated_sprite.play("sleep")
	click_count = 0
	
func maybe_idle():
	if not is_idling and not is_sleeping and not is_action_animation:
		if randf() < 0.3:
			is_idling = true
			idle_timer = randf_range(2.0, 4.0)
			speed = 0.0
			animated_sprite.play("turn_around")
			
func _physics_process(delta: float) -> void:
	# Wait briefly to distinguish a click from a pickup.
	if mouse_pressed_on_billie and not is_dragging:
		hold_timer += delta
		if hold_timer >= pickup_delay:
			is_dragging = true
			click_count = 0
			is_idling = false
			is_action_animation = false
			is_sleeping = false
			speed = 0.0
			animated_sprite.play("walk")
		return
	if is_dragging:
		var mouse_pos = Vector2(DisplayServer.mouse_get_position())
		var target = mouse_pos + drag_offset
		target.x = clampf(target.x, 0.0, maxf(0.0, screen_size.x - window_size.x))
		target.y = clampf(target.y, 0.0, maxf(0.0, screen_size.y - window_size.y))
		DisplayServer.window_set_position(Vector2i(roundi(target.x), roundi(target.y)))
		return
	if click_count > 0:
		click_timer -= delta
		if click_timer <= 0.0:
			handle_clicks()
	if is_sleeping:
		return
	if is_action_animation:
		action_timer -= delta
		if action_timer <= 0.0:
			is_action_animation = false
			speed = 300.0
			animated_sprite.play("walk")
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
		idle_cooldown = randf_range(4.0, 8.0)
		if is_idling:
			return
	var window_position = Vector2(DisplayServer.window_get_position())
	var max_x = maxf(0.0, screen_size.x - window_size.x)
	window_position.y = clampf(walk_y, 0.0, maxf(0.0, screen_size.y - window_size.y))
	window_position.x += direction * speed * delta
	if window_position.x <= 0.0:
		window_position.x = 0.0
		direction = 1.0
		animated_sprite.flip_h = false
		maybe_idle()
	elif window_position.x >= max_x:
		window_position.x = max_x
		direction = -1.0
		animated_sprite.flip_h = true
		maybe_idle()
	DisplayServer.window_set_position(Vector2i(roundi(window_position.x), roundi(window_position.y)))
