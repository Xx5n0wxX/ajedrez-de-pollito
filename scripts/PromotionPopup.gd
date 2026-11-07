class_name PromotionPopup
extends Control

## Ventana emergente (Popup Modal) para la coronación de peón en ajedrez.
## Permite al jugador elegir entre Dama, Torre, Alfil y Caballo con estética 2.5D de plastilina.

signal piece_selected(piece_type: String) # "q", "r", "b", "n"

const COORD_FONT = preload("res://assets/fonts/CherryBombOne-Regular.ttf")

var backdrop: ColorRect
var panel_box: PanelContainer
var title_lbl: Label
var subtitle_lbl: Label
var buttons_hbox: HBoxContainer

var btn_queen: Button
var btn_rook: Button
var btn_bishop: Button
var btn_knight: Button

var tex_queen: TextureRect
var tex_rook: TextureRect
var tex_bishop: TextureRect
var tex_knight: TextureRect

var current_tween: Tween
var _is_selecting: bool = false

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchors_preset = Control.PRESET_FULL_RECT
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# 1. Fondo oscurecedor translúcido (Backdrop)
	backdrop = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.anchors_preset = Control.PRESET_FULL_RECT
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.08, 0.04, 0.12, 0.55)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	# 2. Caja Central (Panel de Plastilina)
	var center_container = CenterContainer.new()
	center_container.anchors_preset = Control.PRESET_FULL_RECT
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center_container)

	panel_box = PanelContainer.new()
	panel_box.name = "DialogPanel"
	panel_box.custom_minimum_size = Vector2(340, 190)
	panel_box.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color("#FFF6ED") # Crema suave plastilina
	style_panel.border_width_left = 3
	style_panel.border_width_top = 3
	style_panel.border_width_right = 3
	style_panel.border_width_bottom = 6
	style_panel.border_color = Color("#E4D2C1")
	style_panel.set_corner_radius_all(20)
	style_panel.shadow_color = Color(0.3, 0.1, 0.2, 0.25)
	style_panel.shadow_size = 14
	style_panel.shadow_offset = Vector2(0, 6)
	style_panel.anti_aliasing = true
	panel_box.add_theme_stylebox_override("panel", style_panel)
	center_container.add_child(panel_box)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel_box.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	# Título llamativo
	title_lbl = Label.new()
	title_lbl.text = "👑 ¡CORONACIÓN DE PEÓN!"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", COORD_FONT)
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color("#db2777")) # Rosa Profe Pollito
	vbox.add_child(title_lbl)

	# Subtítulo explicativo
	subtitle_lbl = Label.new()
	subtitle_lbl.text = "¡Tu peón cruzó el tablero! Elige su nueva pieza:"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 13)
	subtitle_lbl.add_theme_color_override("font_color", Color("#701a35"))
	vbox.add_child(subtitle_lbl)

	# Fila de 4 piezas
	buttons_hbox = HBoxContainer.new()
	buttons_hbox.add_theme_constant_override("separation", 12)
	buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(buttons_hbox)

	btn_queen = _create_piece_button("q", "Dama", "w_q")
	btn_rook = _create_piece_button("r", "Torre", "w_r")
	btn_bishop = _create_piece_button("b", "Alfil", "w_b")
	btn_knight = _create_piece_button("n", "Caballo", "w_n")

	buttons_hbox.add_child(btn_queen)
	buttons_hbox.add_child(btn_rook)
	buttons_hbox.add_child(btn_bishop)
	buttons_hbox.add_child(btn_knight)

func _create_piece_button(type_key: String, label_text: String, _default_tex_key: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(68, 82)
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.focus_mode = Control.FOCUS_NONE

	# Estilos 2.5D de plastilina rosa pastel
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color("#FCE7F3")
	sb_normal.border_width_left = 2
	sb_normal.border_width_top = 2
	sb_normal.border_width_right = 2
	sb_normal.border_width_bottom = 5
	sb_normal.border_color = Color("#F472B6")
	sb_normal.set_corner_radius_all(14)
	sb_normal.anti_aliasing = true

	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color("#FFF1F2")
	sb_hover.border_width_left = 2
	sb_hover.border_width_top = 2
	sb_hover.border_width_right = 2
	sb_hover.border_width_bottom = 5
	sb_hover.border_color = Color("#EC4899")
	sb_hover.set_corner_radius_all(14)
	sb_hover.anti_aliasing = true

	var sb_pressed = StyleBoxFlat.new()
	sb_pressed.bg_color = Color("#FBCFE8")
	sb_pressed.border_width_left = 2
	sb_pressed.border_width_top = 4
	sb_pressed.border_width_right = 2
	sb_pressed.border_width_bottom = 2
	sb_pressed.border_color = Color("#DB2777")
	sb_pressed.set_corner_radius_all(14)
	sb_pressed.anti_aliasing = true

	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)

	var inner_vbox = VBoxContainer.new()
	inner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.anchors_preset = Control.PRESET_FULL_RECT
	inner_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(inner_vbox)

	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_vbox.add_child(icon_rect)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color("#831843"))
	inner_vbox.add_child(lbl)

	match type_key:
		"q": tex_queen = icon_rect
		"r": tex_rook = icon_rect
		"b": tex_bishop = icon_rect
		"n": tex_knight = icon_rect

	btn.pressed.connect(func():
		_on_piece_button_pressed(btn, type_key)
	)

	return btn

func _on_piece_button_pressed(btn: Button, type_key: String) -> void:
	if _is_selecting:
		return
	_is_selecting = true
	btn.pivot_offset = (btn.size if btn.size != Vector2.ZERO else btn.custom_minimum_size) / 2.0
	# Microrebote de plastilina al presionar
	var tw = create_tween()
	tw.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.06).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_ELASTIC)
	tw.finished.connect(func():
		piece_selected.emit(type_key)
	)

## Abre el menú modal para el color correspondiente y devuelve la pieza elegida ("q", "r", "b", "n")
func open_promotion(is_white: bool, textures: Dictionary = {}) -> String:
	_is_selecting = false
	var prefix = "w_" if is_white else "b_"
	
	if not textures.is_empty():
		var q_key = "Q" if is_white else "q"
		var r_key = "R" if is_white else "r"
		var b_key = "B" if is_white else "b"
		var n_key = "N" if is_white else "n"
		if tex_queen: tex_queen.texture = textures.get(q_key, null)
		if tex_rook: tex_rook.texture = textures.get(r_key, null)
		if tex_bishop: tex_bishop.texture = textures.get(b_key, null)
		if tex_knight: tex_knight.texture = textures.get(n_key, null)
	else:
		if tex_queen:
			tex_queen.texture = load("res://assets/pieces/%sq.png" % prefix)
		if tex_rook:
			tex_rook.texture = load("res://assets/pieces/%sr.png" % prefix)
		if tex_bishop:
			tex_bishop.texture = load("res://assets/pieces/%sb.png" % prefix)
		if tex_knight:
			tex_knight.texture = load("res://assets/pieces/%sn.png" % prefix)

	# Animación de entrada suave con Squash & Stretch
	visible = true
	if panel_box:
		panel_box.scale = Vector2(0.7, 0.7)
		panel_box.pivot_offset = (panel_box.size if panel_box.size != Vector2.ZERO else panel_box.custom_minimum_size) / 2.0
		if current_tween: current_tween.kill()
		current_tween = create_tween()
		current_tween.tween_property(panel_box, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var chosen: String = await piece_selected

	# Animación de salida
	if panel_box:
		if current_tween: current_tween.kill()
		current_tween = create_tween()
		current_tween.tween_property(panel_box, "scale", Vector2(0.8, 0.8), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await current_tween.finished

	visible = false
	return chosen
