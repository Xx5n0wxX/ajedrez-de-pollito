extends Control

const MAIN_MENU_PATH: String = "res://MainMenu.tscn"
const GALLO_SCENE: PackedScene = preload("res://scenes/GalloProfe.tscn")
const BADGE_BG_TEX: Texture2D = preload("res://assets/ui/splash_badge_bg.png")
const CHERRY_FONT: FontFile = preload("res://assets/fonts/CherryBombOne-Regular.ttf")

const PIECE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/pieces/w_k.svg"),
	preload("res://assets/pieces/b_q.svg"),
	preload("res://assets/pieces/w_n.svg"),
	preload("res://assets/pieces/b_r.svg")
]

const TOTAL_DURATION: float = 3.5
const PHASE_GREET_TIME: float = 1.75

var _elapsed: float = 0.0
var _phase: int = 0 # 0 = celebrando, 1 = saludando, 2 = completado
var _transitioning: bool = false
var _threaded_requested: bool = false

var _bg_canvas: Control
var _card_panel: PanelContainer
var _content_box: BoxContainer
var _badge_holder: Control
var _badge_rect: TextureRect
var _gallo: GalloProfe
var _right_vbox: VBoxContainer
var _lbl_subtitle: Label
var _lbl_title: Label
var _pill_panel: PanelContainer
var _lbl_greeting: Label
var _progress_bar: ProgressBar
var _lbl_percent: Label
var _floating_pieces: Array[TextureRect] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true

	if ResourceLoader.exists(MAIN_MENU_PATH):
		ResourceLoader.load_threaded_request(MAIN_MENU_PATH)
		_threaded_requested = true

	_build_ui()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_play_intro_choreography()

func _build_ui() -> void:
	# 1. Lienzo de fondo de tablero pastel a juego con el icono
	_bg_canvas = Control.new()
	_bg_canvas.name = "PastelChessBg"
	_bg_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_canvas.draw.connect(_on_draw_bg)
	add_child(_bg_canvas)

	# Piezas decorativas flotantes suaves en las esquinas
	for i in range(4):
		var p_tex := TextureRect.new()
		p_tex.texture = PIECE_TEXTURES[i]
		p_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p_tex.modulate = Color(0.75, 0.15, 0.42, 0.10)
		p_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p_tex)
		_floating_pieces.append(p_tex)

	# 2. Contenedor central
	var center := CenterContainer.new()
	center.name = "CenterStage"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# 3. Tarjeta principal con doble borde (Rosa intenso #BE185D + Dorado #FDE047 como el icono)
	_card_panel = PanelContainer.new()
	_card_panel.name = "SplashCard"
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1.0, 0.985, 0.992, 0.97)
	card_style.border_width_left = 5
	card_style.border_width_top = 5
	card_style.border_width_right = 5
	card_style.border_width_bottom = 8
	card_style.border_color = Color(0.745, 0.094, 0.365, 1.0) # #BE185D
	card_style.corner_radius_top_left = 36
	card_style.corner_radius_top_right = 36
	card_style.corner_radius_bottom_right = 36
	card_style.corner_radius_bottom_left = 36
	card_style.shadow_color = Color(0.745, 0.094, 0.365, 0.22)
	card_style.shadow_size = 24
	card_style.shadow_offset = Vector2(0, 10)
	card_style.content_margin_left = 32
	card_style.content_margin_right = 32
	card_style.content_margin_top = 28
	card_style.content_margin_bottom = 28
	_card_panel.add_theme_stylebox_override("panel", card_style)
	center.add_child(_card_panel)

	_content_box = BoxContainer.new()
	_content_box.name = "ContentBox"
	_content_box.vertical = true
	_content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_box.add_theme_constant_override("separation", 16)
	_card_panel.add_child(_content_box)

	# 4. Insignia central (idéntica al nuevo icono) + Profe Pollito animado en vivo
	var badge_center := CenterContainer.new()
	_content_box.add_child(badge_center)

	_badge_holder = Control.new()
	_badge_holder.name = "BadgeHolder"
	_badge_holder.custom_minimum_size = Vector2(230, 230)
	badge_center.add_child(_badge_holder)

	_badge_rect = TextureRect.new()
	_badge_rect.name = "IconBadgeBg"
	_badge_rect.texture = BADGE_BG_TEX
	_badge_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_badge_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_badge_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_badge_holder.add_child(_badge_rect)

	_gallo = GALLO_SCENE.instantiate() as GalloProfe
	_badge_holder.add_child(_gallo)

	# 5. Bloque de Título, Saludo y Barra de Carga
	_right_vbox = VBoxContainer.new()
	_right_vbox.name = "TitleAndProgressBox"
	_right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_right_vbox.add_theme_constant_override("separation", 10)
	_content_box.add_child(_right_vbox)

	_lbl_subtitle = Label.new()
	_lbl_subtitle.text = "El Mundo de Ajedrez"
	_lbl_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_subtitle.add_theme_font_override("font", CHERRY_FONT)
	_lbl_subtitle.add_theme_color_override("font_color", Color(0.616, 0.09, 0.302, 1.0)) # #9D174D
	_lbl_subtitle.add_theme_color_override("font_outline_color", Color(1, 0.96, 0.93, 1))
	_lbl_subtitle.add_theme_constant_override("outline_size", 8)
	_right_vbox.add_child(_lbl_subtitle)

	_lbl_title = Label.new()
	_lbl_title.text = "del Profe Pollito 👑"
	_lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_title.add_theme_font_override("font", CHERRY_FONT)
	_lbl_title.add_theme_color_override("font_color", Color(0.859, 0.153, 0.467, 1.0)) # #DB2777
	_lbl_title.add_theme_color_override("font_outline_color", Color(1, 0.96, 0.93, 1))
	_lbl_title.add_theme_constant_override("outline_size", 10)
	_lbl_title.add_theme_color_override("font_shadow_color", Color(0.745, 0.094, 0.365, 0.25))
	_lbl_title.add_theme_constant_override("shadow_offset_x", 0)
	_lbl_title.add_theme_constant_override("shadow_offset_y", 4)
	_right_vbox.add_child(_lbl_title)

	# Píldora de estado de animación (Celebrando -> Saludando)
	var pill_center := CenterContainer.new()
	_right_vbox.add_child(pill_center)

	_pill_panel = PanelContainer.new()
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = Color(1.0, 0.965, 0.929, 1.0) # #FFF6ED crema del icono
	pill_style.border_width_left = 2
	pill_style.border_width_top = 2
	pill_style.border_width_right = 2
	pill_style.border_width_bottom = 3
	pill_style.border_color = Color(0.953, 0.608, 0.69, 1.0) # #F39BB0 rosa tablero del icono
	pill_style.corner_radius_top_left = 20
	pill_style.corner_radius_top_right = 20
	pill_style.corner_radius_bottom_right = 20
	pill_style.corner_radius_bottom_left = 20
	pill_style.content_margin_left = 18
	pill_style.content_margin_right = 18
	pill_style.content_margin_top = 6
	pill_style.content_margin_bottom = 6
	_pill_panel.add_theme_stylebox_override("panel", pill_style)
	pill_center.add_child(_pill_panel)

	_lbl_greeting = Label.new()
	_lbl_greeting.text = "🎉 ¡Bienvenido a la Academia! 🎉"
	_lbl_greeting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_greeting.add_theme_color_override("font_color", Color(0.616, 0.09, 0.302, 1.0))
	_pill_panel.add_child(_lbl_greeting)

	# Barra de progreso estilizada a juego con el icono
	var prog_vbox := VBoxContainer.new()
	prog_vbox.add_theme_constant_override("separation", 4)
	_right_vbox.add_child(prog_vbox)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(320, 22)

	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color = Color(1.0, 0.965, 0.929, 1.0) # #FFF6ED
	sb_bg.border_width_left = 3
	sb_bg.border_width_top = 3
	sb_bg.border_width_right = 3
	sb_bg.border_width_bottom = 3
	sb_bg.border_color = Color(0.745, 0.094, 0.365, 1.0) # #BE185D
	sb_bg.corner_radius_top_left = 12
	sb_bg.corner_radius_top_right = 12
	sb_bg.corner_radius_bottom_right = 12
	sb_bg.corner_radius_bottom_left = 12

	var sb_fill := StyleBoxFlat.new()
	sb_fill.bg_color = Color(0.859, 0.153, 0.467, 1.0) # #DB2777
	sb_fill.border_width_left = 2
	sb_fill.border_width_top = 2
	sb_fill.border_width_right = 2
	sb_fill.border_width_bottom = 2
	sb_fill.border_color = Color(0.992, 0.878, 0.278, 1.0) # #FDE047 Dorado
	sb_fill.corner_radius_top_left = 10
	sb_fill.corner_radius_top_right = 10
	sb_fill.corner_radius_bottom_right = 10
	sb_fill.corner_radius_bottom_left = 10

	_progress_bar.add_theme_stylebox_override("background", sb_bg)
	_progress_bar.add_theme_stylebox_override("fill", sb_fill)
	prog_vbox.add_child(_progress_bar)

	_lbl_percent = Label.new()
	_lbl_percent.text = "Cargando... 0%"
	_lbl_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_percent.add_theme_color_override("font_color", Color(0.55, 0.22, 0.38, 0.9))
	prog_vbox.add_child(_lbl_percent)

func _apply_responsive_layout() -> void:
	if not is_inside_tree():
		return
	var vp: Vector2 = get_viewport_rect().size
	var is_short_landscape: bool = (vp.x > vp.y and vp.y < 520.0)
	var is_mobile: bool = false
	if has_node("/root/ScreenManager"):
		is_mobile = get_node("/root/ScreenManager").is_mobile()

	_content_box.vertical = not is_short_landscape

	var badge_dim: float = 230.0
	if is_short_landscape:
		badge_dim = clamp(vp.y * 0.62, 165.0, 220.0)
		_content_box.add_theme_constant_override("separation", 26)
	elif vp.x < 500.0: # Móvil vertical
		badge_dim = clamp(vp.x * 0.56, 190.0, 240.0)
		_content_box.add_theme_constant_override("separation", 16)
	else:
		badge_dim = 240.0
		_content_box.add_theme_constant_override("separation", 16)

	_badge_holder.custom_minimum_size = Vector2(badge_dim, badge_dim)
	_badge_holder.pivot_offset = Vector2(badge_dim * 0.5, badge_dim * 0.5)

	if _gallo:
		var s: float = badge_dim / 500.0
		_gallo.scale = Vector2(s, s)
		_gallo.position = Vector2(badge_dim * 0.5 + 5.0 * s, badge_dim * 0.5 + 206.0 * s)

	var sub_size: int = 26
	var title_size: int = 42
	var greet_size: int = 16
	var pct_size: int = 14
	var bar_w: float = 340.0

	if is_short_landscape:
		sub_size = 22
		title_size = 34
		greet_size = 16
		pct_size = 14
		bar_w = clamp(vp.x * 0.42, 260.0, 380.0)
	elif vp.x < 500.0:
		sub_size = 24
		title_size = 34
		greet_size = 16
		pct_size = 14
		bar_w = clamp(vp.x - 100.0, 240.0, 340.0)
	elif is_mobile:
		sub_size = 28
		title_size = 44
		greet_size = 18
		pct_size = 15
		bar_w = 380.0

	_lbl_subtitle.add_theme_font_size_override("font_size", sub_size)
	_lbl_title.add_theme_font_size_override("font_size", title_size)
	_lbl_greeting.add_theme_font_size_override("font_size", greet_size)
	_lbl_percent.add_theme_font_size_override("font_size", pct_size)
	_progress_bar.custom_minimum_size = Vector2(bar_w, 22 if not is_mobile else 26)

	# Posicionar piezas decorativas en las 4 esquinas
	var piece_sz: float = clamp(min(vp.x, vp.y) * 0.16, 56.0, 110.0)
	var margins: float = 28.0
	var coords: Array[Vector2] = [
		Vector2(margins, margins),
		Vector2(vp.x - piece_sz - margins, margins),
		Vector2(margins, vp.y - piece_sz - margins),
		Vector2(vp.x - piece_sz - margins, vp.y - piece_sz - margins)
	]
	for i in range(_floating_pieces.size()):
		_floating_pieces[i].size = Vector2(piece_sz, piece_sz)
		_floating_pieces[i].position = coords[i]

	# En modo vertical (Portrait), agrandar la tarjeta para aprovechar el ancho de pantalla móvil
	await get_tree().process_frame
	if is_instance_valid(_card_panel):
		_card_panel.pivot_offset = _card_panel.size * 0.5
		if vp.y > vp.x:
			var max_scale: float = clamp((vp.x * 0.90) / max(_card_panel.size.x, 1.0), 1.0, 1.32)
			_card_panel.scale = Vector2(max_scale, max_scale)
		else:
			_card_panel.scale = Vector2.ONE

	_bg_canvas.queue_redraw()

func _play_intro_choreography() -> void:
	# Fase 1 inmediata: Pollito hace la animación de CELEBRAR
	_phase = 0
	if _gallo:
		_gallo.celebrar(PHASE_GREET_TIME)

	# Animación elástica de entrada para la insignia y el título
	_badge_holder.scale = Vector2(0.65, 0.65)
	_lbl_subtitle.modulate.a = 0.0
	_lbl_title.modulate.a = 0.0
	_pill_panel.modulate.a = 0.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_badge_holder, "scale", Vector2.ONE, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_lbl_subtitle, "modulate:a", 1.0, 0.38).set_delay(0.10)
	tw.tween_property(_lbl_title, "modulate:a", 1.0, 0.42).set_delay(0.18)
	tw.tween_property(_pill_panel, "modulate:a", 1.0, 0.35).set_delay(0.28)

func _process(delta: float) -> void:
	_elapsed += delta
	_bg_canvas.queue_redraw()

	# Flotación suave de piezas decorativas
	for i in range(_floating_pieces.size()):
		var fp: TextureRect = _floating_pieces[i]
		fp.rotation = sin(_elapsed * 1.8 + float(i) * 1.4) * 0.08

	# Transición de Fase 1 (Celebrar) -> Fase 2 (Saludar)
	if _phase == 0 and _elapsed >= PHASE_GREET_TIME:
		_phase = 1
		if _gallo:
			_gallo.saludar(TOTAL_DURATION - PHASE_GREET_TIME + 0.5)
		_lbl_greeting.text = "👋 ¡Hola! Preparando el tablero..."
		_pill_panel.pivot_offset = _pill_panel.size * 0.5
		var p_tw := create_tween()
		p_tw.tween_property(_pill_panel, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		p_tw.tween_property(_pill_panel, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	# Progreso de la barra de carga
	var pct: float = clamp((_elapsed / TOTAL_DURATION) * 100.0, 0.0, 100.0)
	_progress_bar.value = pct
	if pct < 100.0:
		_lbl_percent.text = "Cargando el Mundo de Ajedrez... %d%%" % int(pct)
	else:
		_lbl_percent.text = "✨ ¡Listo para jugar! 100% ✨"

	if _elapsed >= TOTAL_DURATION and not _transitioning:
		_finish_and_go_to_menu()

func _finish_and_go_to_menu() -> void:
	_transitioning = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(_change_to_main_menu)

func _change_to_main_menu() -> void:
	if _threaded_requested:
		var status := ResourceLoader.load_threaded_get_status(MAIN_MENU_PATH)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed := ResourceLoader.load_threaded_get(MAIN_MENU_PATH) as PackedScene
			if packed:
				get_tree().change_scene_to_packed(packed)
				return
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _on_draw_bg() -> void:
	var vp: Vector2 = _bg_canvas.size
	if vp.x <= 0 or vp.y <= 0:
		return

	# Damero pastel suave inspirado directamente en el nuevo icono (#FFF6ED y #FDE2EB)
	var cell_size: float = clamp(max(vp.x, vp.y) / 10.0, 72.0, 140.0)
	var cols: int = int(ceil(vp.x / cell_size)) + 2
	var rows: int = int(ceil(vp.y / cell_size)) + 2
	var drift: float = fmod(_elapsed * 14.0, cell_size * 2.0)

	var c_light := Color(1.0, 0.965, 0.929, 1.0) # #FFF6ED
	var c_dark := Color(0.988, 0.882, 0.918, 1.0) # Rosa pastel suave

	for r in range(-1, rows):
		for c in range(-1, cols):
			var col: Color = c_light if ((r + c) % 2 == 0) else c_dark
			var rect := Rect2(
				float(c) * cell_size - drift * 0.5,
				float(r) * cell_size - drift * 0.5,
				cell_size + 1.0,
				cell_size + 1.0
			)
			_bg_canvas.draw_rect(rect, col)
