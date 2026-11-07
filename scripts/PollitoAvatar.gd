extends TextureRect
class_name PollitoAvatar

const EXPRESSIONS: Dictionary = {
	"explicando": preload("res://assets/ui/pollito_explicando.png"),
	"pensando": preload("res://assets/ui/pollito_pensando.png"),
	"celebrando": preload("res://assets/ui/pollito_celebrando.png"),
	"animando": preload("res://assets/ui/pollito_animando.png")
}

const GALLO_PROFE_SCENE: PackedScene = preload("res://scenes/GalloProfe.tscn")

var visual_sprite: TextureRect
var gallo_puppet: GalloProfe
var current_expression: String = ""
var current_tween: Tween

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false

	# El nodo padre no dibuja textura directa; delega en el títere o en el hijo
	texture = null

	_setup_visual_child()
	_setup_gallo_puppet()

	# Precalentamiento de texturas en VRAM en el arranque
	_warm_up_textures()

	set_expression("explicando", false)

func _set(property: StringName, value: Variant) -> bool:
	if property == &"texture":
		if value == null:
			return false
		for expr_key: String in EXPRESSIONS:
			if EXPRESSIONS[expr_key] == value:
				set_expression(expr_key, false)
				return true
		if visual_sprite:
			visual_sprite.texture = value as Texture2D
			if not gallo_puppet:
				visual_sprite.visible = true
		return true
	return false

func _warm_up_textures() -> void:
	var dummy_ci: RID = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(dummy_ci, get_canvas_item())
	for expr_key: String in EXPRESSIONS:
		var tex: Texture2D = EXPRESSIONS[expr_key] as Texture2D
		if tex:
			RenderingServer.canvas_item_add_texture_rect(dummy_ci, Rect2(0, 0, 1, 1), tex.get_rid())

	get_tree().process_frame.connect(func() -> void:
		if dummy_ci.is_valid():
			RenderingServer.free_rid(dummy_ci)
	, CONNECT_ONE_SHOT)

func _setup_visual_child() -> void:
	if has_node("Visual"):
		visual_sprite = $Visual
	else:
		visual_sprite = TextureRect.new()
		visual_sprite.name = "Visual"
		add_child(visual_sprite)

	visual_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE

	resized.connect(_on_parent_resized)
	_on_parent_resized()

func _setup_gallo_puppet() -> void:
	if GALLO_PROFE_SCENE:
		var inst: Node = GALLO_PROFE_SCENE.instantiate()
		if inst is GalloProfe:
			gallo_puppet = inst as GalloProfe
			add_child(gallo_puppet)
			if visual_sprite:
				visual_sprite.visible = false
			_on_parent_resized()

func _on_parent_resized() -> void:
	if visual_sprite:
		visual_sprite.pivot_offset = size / 2.0
	if gallo_puppet:
		var target_dim: float = min(size.x, size.y)
		var s: float = target_dim / 500.0
		gallo_puppet.scale = Vector2(s, s)
		# Centrado visual exacto del cuerpo (439x437 px) evitando cualquier recorte
		gallo_puppet.position = Vector2(size.x * 0.5 + 5.0 * s, size.y * 0.5 + 206.0 * s)

func set_expression(expr_name: String, animate: bool = true) -> void:
	current_expression = expr_name

	if gallo_puppet:
		match expr_name:
			"explicando":
				gallo_puppet.explicar(5.0)
			"pensando":
				gallo_puppet.pensar()
			"celebrando":
				gallo_puppet.celebrar(4.0)
			"animando":
				gallo_puppet.hablar(4.0)
			"sorprendido":
				gallo_puppet.sorprendido(3.0)
			_:
				gallo_puppet.idle()
		return

	if not visual_sprite:
		return

	if EXPRESSIONS.has(expr_name):
		visual_sprite.texture = EXPRESSIONS[expr_name]

	if not animate:
		return

	_kill_tween()

	# Asegurar pivote centrado y escala base en el hijo visual
	visual_sprite.pivot_offset = size / 2.0
	visual_sprite.scale = Vector2.ONE

	# Rebote elástico aplicado ÚNICAMENTE al nodo hijo
	current_tween = create_tween()
	current_tween.tween_property(visual_sprite, "scale", Vector2(1.08, 0.92), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(visual_sprite, "scale", Vector2(0.96, 1.04), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	current_tween.tween_property(visual_sprite, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _kill_tween() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()

# Métodos semánticos auxiliares
func play_celebration() -> void:
	set_expression("celebrando", true)

func play_thinking() -> void:
	set_expression("pensando", true)

func play_encouragement() -> void:
	set_expression("animando", true)

func play_greeting() -> void:
	if gallo_puppet:
		gallo_puppet.hablar(3.5)
	else:
		set_expression("explicando", false)

func start_talking() -> void:
	if gallo_puppet:
		gallo_puppet.on_tts_started()

func stop_talking() -> void:
	if gallo_puppet:
		gallo_puppet.on_tts_finished()
	elif visual_sprite:
		visual_sprite.scale = Vector2.ONE
