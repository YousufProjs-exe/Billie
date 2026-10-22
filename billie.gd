
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
var drag_offset = Vector2.ZERO
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
	animated_sprite.play("walk")
	area.input_event.connect(_on_area_input)
	idle_cooldown = randf_range(4.0, 8.0)

func maybe_idle():
	if not is_idling and not is_sleeping and not is_action_animation and randf() < 0.3:
		is_idling = true
		idle_timer = randf_range(2.0, 4.0)
		action_timer = idle_timer
		speed = 0.0
		animated_sprite.play("turn_around")

func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_sleeping:
			is_sleeping = false
			speed = 300.0
			animated_sprite.play("walk")
			idle_cooldown = randf_range(4.0, 8.0)
			click_count = 0
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
		#animated_sprite.play("walk")
		#_on_animation_finished()
	elif click_count == 2:
		is_action_animation = true
		action_timer = 2.5
		animated_sprite.play("turn_around")
	elif click_count >= 3:
		is_sleeping = true
		animated_sprite.play("sleep")
		
	click_count = 0

func _physics_process(delta: float) -> void:
	if click_count > 0:
		click_timer -= delta
		if click_timer <= 0.0:
			handle_clicks()
			
	if is_dragging or is_sleeping:
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
			
	var window_position := Vector2(DisplayServer.window_get_position())
	var max_x := maxf(0.0, screen_size.x - window_size.x)
	var bottom_y := maxf(0.0, screen_size.y - window_size.y - 15.0)
	
	window_position.y = bottom_y
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
