class_name ChessPiece
extends Control

## Pieza de ajedrez física protegida contra recalculado nativo de textura

@onready var sprite: TextureRect = $Sprite

var piece_type: String = ""
var is_white: bool = true
var current_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	if not sprite:
		sprite = get_node_or_null("Sprite")
	if sprite:
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	resized.connect(_on_resized)
	call_deferred("_setup_pivot")

func _on_resized() -> void:
	if sprite:
		sprite.pivot_offset = size / 2.0

func _setup_pivot() -> void:
	if sprite:
		sprite.pivot_offset = size / 2.0
		sprite.scale = Vector2.ONE

func set_piece_size(new_size: Vector2) -> void:
	custom_minimum_size = new_size
	size = new_size
	if sprite:
		sprite.pivot_offset = new_size / 2.0

func set_piece_data(type: String, white: bool, tex: Texture2D = null) -> void:
	piece_type = type.to_upper()
	is_white = white
	if not sprite:
		sprite = get_node_or_null("Sprite")

	if tex != null:
		if sprite:
			sprite.texture = tex
			sprite.scale = Vector2.ONE
		visible = true
		return

	var prefix = "w_" if white else "b_"
	var path = "res://assets/pieces/%s%s.svg" % [prefix, type.to_lower()]

	if ResourceLoader.exists(path):
		if sprite:
			sprite.texture = load(path)
			sprite.scale = Vector2.ONE
		visible = true
	else:
		push_warning("Falta archivo de pieza: " + path)

func set_piece_key(key: String, tex: Texture2D = null) -> void:
	if key.is_empty():
		clear_piece()
		return
	var white: bool = (key == key.to_upper())
	set_piece_data(key.to_upper(), white, tex)

func set_texture(new_texture: Texture2D) -> void:
	if not sprite:
		sprite = get_node_or_null("Sprite")
	if sprite:
		sprite.texture = new_texture
	elif has_node("Visual"):
		$Visual.texture = new_texture

func clear_piece() -> void:
	piece_type = ""
	_kill_tween()
	if not sprite:
		sprite = get_node_or_null("Sprite")
	if sprite:
		sprite.texture = null
		sprite.scale = Vector2.ONE
	visible = false

func play_pickup() -> void:
	_kill_tween()
	z_index = 50
	if not sprite:
		sprite = get_node_or_null("Sprite")
	if sprite:
		sprite.pivot_offset = sprite.size / 2.0
		current_tween = create_tween()
		# Estiramiento vertical ligero al despegarse
		current_tween.tween_property(sprite, "scale", Vector2(0.88, 1.14), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func play_landing() -> void:
	_kill_tween()
	z_index = 1
	if not sprite:
		sprite = get_node_or_null("Sprite")
	if sprite:
		sprite.pivot_offset = sprite.size / 2.0
		sprite.scale = Vector2.ONE
		current_tween = create_tween()
		# 1. Aplastamiento elástico marcado al impactar (Squash)
		current_tween.tween_property(sprite, "scale", Vector2(1.18, 0.82), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# 2. Rebote elástico compensatorio (Stretch)
		current_tween.tween_property(sprite, "scale", Vector2(0.92, 1.08), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		# 3. Asentamiento final
		current_tween.tween_property(sprite, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		current_tween.finished.connect(func(): z_index = 0)

# Función para viaje autónomo (solo para Click-to-Move)
func animate_move_to(target_global_pos: Vector2, on_complete: Callable = Callable()) -> void:
	_kill_tween()
	z_index = 40
	current_tween = create_tween()
	current_tween.tween_property(self, "global_position", target_global_pos, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	current_tween.finished.connect(func():
		play_landing()
		if on_complete.is_valid():
			on_complete.call()
	)

func play_bounce_back(origin_global_pos: Vector2) -> void:
	_kill_tween()
	z_index = 40
	if not sprite:
		sprite = get_node_or_null("Sprite")
	current_tween = create_tween().set_parallel(true)
	current_tween.tween_property(self, "global_position", origin_global_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if sprite:
		current_tween.tween_property(sprite, "scale", Vector2.ONE, 0.15)
	current_tween.finished.connect(func(): z_index = 0)

func _kill_tween() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
