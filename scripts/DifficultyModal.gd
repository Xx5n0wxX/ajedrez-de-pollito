extends CanvasLayer

signal level_selected(new_level: int)
signal cancelled()

const CHERRY_FONT = preload("res://assets/fonts/CherryBombOne-Regular.ttf")
const POLLITO_AVATAR = preload("res://assets/ui/pollito_explicando.png")

var current_level: int = 3
var selected_level: int = 3

var overlay: ColorRect
var modal_card: PanelContainer
var cards_scroll: ScrollContainer
var cards_vbox: VBoxContainer
var card_panels: Array[PanelContainer] = []
var header_avatar: TextureRect
var header_title: Label
var header_subtitle: Label
var confirm_btn: Button
var cancel_btn: Button

const DIFF_DATA = [
	{
		"id": 1,
		"icon": "🐣",
		"name": "Fácil",
		"sub": "Pollito Principiante",
		"elo": "~700 ELO",
		"color": "#15803d",
		"bg": "#f0fdf4",
		"border": "#86efac",
		"desc": "Comete descuidos frecuentes y no calcula lejos. ¡Ideal para aprender jaques y mates!"
	},
	{
		"id": 2,
		"icon": "🐥",
		"name": "Medio",
		"sub": "Pollito Aprendiz",
		"elo": "~1200 ELO",
		"color": "#0369a1",
		"bg": "#f0f9ff",
		"border": "#7dd3fc",
		"desc": "Conoce los movimientos básicos y defiende sus piezas. Buen desafío para niños que ya saben jugar."
	},
	{
		"id": 3,
		"icon": "🐔",
		"name": "Intermedio",
		"sub": "Profe Pollito",
		"elo": "~1700 ELO",
		"color": "#be185d",
		"bg": "#fff1f6",
		"border": "#db2777",
		"desc": "¡El Profesor juega con estrategia seria! Conoce buenas aperturas y castiga errores tácticos."
	},
	{
		"id": 4,
		"icon": "🦅",
		"name": "Maestro",
		"sub": "Pollito Avanzado",
		"elo": "~2200 ELO",
		"color": "#7e22ce",
		"bg": "#faf5ff",
		"border": "#d8b4fe",
		"desc": "Cálculo profundo y gran precisión táctica. ¡Un verdadero desafío para ajedrecistas experimentados!"
	},
	{
		"id": 5,
		"icon": "👑",
		"name": "Gran Maestro",
		"sub": "Pollito GM",
		"elo": "~2600+ ELO",
		"color": "#a16207",
		"bg": "#fefce8",
		"border": "#fde047",
		"desc": "Máxima potencia táctica (Stockfish profundo). Juega prácticamente sin cometer fallos."
	}
]

func _ready() -> void:
	layer = 100
	visible = false
	_build_ui()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _is_mobile() -> bool:
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if sm.has_method("is_mobile"):
			return sm.is_mobile()
	var vp_size = get_viewport().get_visible_rect().size
	return vp_size.y > vp_size.x

func _on_viewport_size_changed() -> void:
	if visible:
		_apply_responsive_sizing(_is_mobile())

func open(initial_level: int = 3) -> void:
	current_level = clampi(initial_level, 1, 5)
	selected_level = current_level
	_apply_responsive_sizing(_is_mobile())
	_update_cards_state()
	visible = true

func close() -> void:
	visible = false
	cancelled.emit()

func _confirm() -> void:
	visible = false
	level_selected.emit(selected_level)

func _style_box(bg: Color, border: Color, bw: int = 1, rad: int = 14, shadow: bool = false, shadow_sz: int = 12) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(bw)
	sb.border_color = border
	sb.set_corner_radius_all(rad)
	if shadow:
		sb.shadow_color = Color(0.85, 0.4, 0.65, 0.22)
		sb.shadow_size = shadow_sz
		sb.shadow_offset = Vector2(0, 3)
	return sb

func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	card_panels.clear()

	overlay = ColorRect.new()
	overlay.color = Color(0.08, 0.1, 0.16, 0.78)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	modal_card = PanelContainer.new()
	modal_card.add_theme_stylebox_override("panel", _style_box(Color.WHITE, Color("#fbcfe8"), 3, 24, true, 28))
	add_child(modal_card)

	var margin = MarginContainer.new()
	margin.name = "CardMargin"
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# --- 1. Header ---
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(header_hbox)

	var av = TextureRect.new()
	av.name = "PollitoAvatar"
	av.texture = POLLITO_AVATAR
	av.custom_minimum_size = Vector2(72, 72)
	av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_hbox.add_child(av)
	header_avatar = av

	var title_vbox = VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	title_vbox.add_theme_constant_override("separation", 2)
	header_hbox.add_child(title_vbox)

	var title = Label.new()
	title.name = "ModalTitle"
	title.text = "🎯 Nivel de Dificultad"
	title.add_theme_font_override("font", CHERRY_FONT)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#be185d"))
	title_vbox.add_child(title)
	header_title = title

	var subtitle = Label.new()
	subtitle.name = "ModalSubtitle"
	subtitle.text = "Elige a qué nivel quieres que juegue Profe Pollito:"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#64748b"))
	title_vbox.add_child(subtitle)
	header_subtitle = subtitle

	vbox.add_child(HSeparator.new())

	# --- 2. Container de Tarjetas con Scroll ---
	cards_scroll = ScrollContainer.new()
	cards_scroll.name = "CardsScroll"
	cards_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cards_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(cards_scroll)

	cards_vbox = VBoxContainer.new()
	cards_vbox.name = "CardsVBox"
	cards_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_vbox.add_theme_constant_override("separation", 8)
	cards_scroll.add_child(cards_vbox)

	for d in DIFF_DATA:
		var d_id: int = d["id"]
		var d_card = PanelContainer.new()
		d_card.name = "CardLevel_%d" % d_id
		d_card.mouse_filter = Control.MOUSE_FILTER_PASS
		d_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards_vbox.add_child(d_card)
		card_panels.append(d_card)

		# Botón transparente que cubre la tarjeta para capturar clics/toques
		var click_btn = Button.new()
		click_btn.flat = true
		click_btn.focus_mode = Control.FOCUS_NONE
		click_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		click_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		click_btn.pressed.connect(func(): _on_card_clicked(d_id))
		d_card.add_child(click_btn)

		var d_margin = MarginContainer.new()
		d_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d_margin.add_theme_constant_override("margin_left", 14)
		d_margin.add_theme_constant_override("margin_top", 10)
		d_margin.add_theme_constant_override("margin_right", 14)
		d_margin.add_theme_constant_override("margin_bottom", 10)
		d_card.add_child(d_margin)

		var d_hbox = HBoxContainer.new()
		d_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d_hbox.add_theme_constant_override("separation", 14)
		d_margin.add_child(d_hbox)

		var icon_lbl = Label.new()
		icon_lbl.name = "Icon"
		icon_lbl.text = d["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 42)
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		d_hbox.add_child(icon_lbl)

		var text_col = VBoxContainer.new()
		text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.alignment = BoxContainer.ALIGNMENT_CENTER
		text_col.add_theme_constant_override("separation", 4)
		d_hbox.add_child(text_col)

		var top_row = HBoxContainer.new()
		top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_row.add_theme_constant_override("separation", 8)
		text_col.add_child(top_row)

		var name_lbl = Label.new()
		name_lbl.name = "Name"
		name_lbl.text = d["name"] + " — " + d["sub"]
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color("#0f172a"))
		top_row.add_child(name_lbl)

		var elo_badge = Label.new()
		elo_badge.name = "EloBadge"
		elo_badge.text = " " + d["elo"] + " "
		elo_badge.add_theme_font_size_override("font_size", 12)
		elo_badge.add_theme_color_override("font_color", Color(d["color"]))
		var badge_sb = StyleBoxFlat.new()
		badge_sb.bg_color = Color.WHITE
		badge_sb.set_corner_radius_all(6)
		badge_sb.set_border_width_all(1)
		badge_sb.border_color = Color(d["color"]).lerp(Color.WHITE, 0.4)
		badge_sb.content_margin_left = 6
		badge_sb.content_margin_right = 6
		badge_sb.content_margin_top = 2
		badge_sb.content_margin_bottom = 2
		elo_badge.add_theme_stylebox_override("normal", badge_sb)
		top_row.add_child(elo_badge)

		var sel_badge = Label.new()
		sel_badge.name = "SelBadge"
		sel_badge.text = " ✓ Seleccionado "
		sel_badge.add_theme_font_size_override("font_size", 12)
		sel_badge.add_theme_color_override("font_color", Color.WHITE)
		var sel_sb = StyleBoxFlat.new()
		sel_sb.bg_color = Color("#db2777")
		sel_sb.set_corner_radius_all(6)
		sel_sb.content_margin_left = 6
		sel_sb.content_margin_right = 6
		sel_sb.content_margin_top = 2
		sel_sb.content_margin_bottom = 2
		sel_badge.add_theme_stylebox_override("normal", sel_sb)
		sel_badge.visible = false
		top_row.add_child(sel_badge)

		var desc_lbl = Label.new()
		desc_lbl.name = "Desc"
		desc_lbl.text = d["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.add_theme_color_override("font_color", Color("#334155"))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_col.add_child(desc_lbl)

	# --- 3. Botonera Inferior ---
	var bot_hbox = HBoxContainer.new()
	bot_hbox.name = "ButtonsRow"
	bot_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(bot_hbox)

	cancel_btn = Button.new()
	cancel_btn.name = "BtnCancel"
	cancel_btn.text = "✖ Cancelar"
	cancel_btn.focus_mode = Control.FOCUS_NONE
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.add_theme_color_override("font_color", Color("#475569"))
	var csb = StyleBoxFlat.new()
	csb.bg_color = Color("#f1f5f9")
	csb.border_color = Color("#cbd5e1")
	csb.border_width_bottom = 4
	csb.set_corner_radius_all(12)
	cancel_btn.add_theme_stylebox_override("normal", csb)
	cancel_btn.pressed.connect(close)
	bot_hbox.add_child(cancel_btn)

	confirm_btn = Button.new()
	confirm_btn.name = "BtnConfirm"
	confirm_btn.text = "✅ Confirmar Nivel"
	confirm_btn.focus_mode = Control.FOCUS_NONE
	confirm_btn.add_theme_font_override("font", CHERRY_FONT)
	confirm_btn.add_theme_font_size_override("font_size", 18)
	confirm_btn.add_theme_color_override("font_color", Color.WHITE)
	var oksb = StyleBoxFlat.new()
	oksb.bg_color = Color("#db2777")
	oksb.border_color = Color("#9d174d")
	oksb.border_width_bottom = 4
	oksb.set_corner_radius_all(12)
	confirm_btn.add_theme_stylebox_override("normal", oksb)
	confirm_btn.pressed.connect(_confirm)
	bot_hbox.add_child(confirm_btn)

func _on_card_clicked(level_id: int) -> void:
	selected_level = level_id
	_update_cards_state()

func _update_cards_state() -> void:
	for i in range(card_panels.size()):
		var d = DIFF_DATA[i]
		var d_card = card_panels[i]
		var is_sel: bool = (d["id"] == selected_level)
		var border_color = Color("#db2777") if is_sel else Color(d["border"])
		var card_bg = Color(d["bg"])
		d_card.add_theme_stylebox_override("panel", _style_box(card_bg, border_color, 3 if is_sel else 2, 14, is_sel, 12))

		var sel_badge = d_card.find_child("SelBadge", true, false)
		if sel_badge:
			sel_badge.visible = is_sel

func _apply_responsive_sizing(is_mob: bool) -> void:
	var vp_size = get_viewport().get_visible_rect().size
	var is_portrait: bool = vp_size.y > vp_size.x

	if is_portrait:
		# Modo Vertical (Móvil vertical o ventana vertical)
		modal_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		modal_card.offset_left = 12
		modal_card.offset_right = -12
		modal_card.offset_top = 16
		modal_card.offset_bottom = -16
		modal_card.custom_minimum_size = Vector2(0, 0)
		modal_card.size_flags_vertical = Control.SIZE_EXPAND_FILL

		if is_instance_valid(header_avatar):
			header_avatar.custom_minimum_size = Vector2(68, 68)
		if is_instance_valid(header_title):
			header_title.add_theme_font_size_override("font_size", 28)
		if is_instance_valid(header_subtitle):
			header_subtitle.add_theme_font_size_override("font_size", 14)

		cancel_btn.custom_minimum_size = Vector2(0, 56)
		cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		confirm_btn.custom_minimum_size = Vector2(0, 56)
		confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		for card in card_panels:
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			card.custom_minimum_size = Vector2(0, 108)
	else:
		# Modo Landscape / Horizontal (Desktop y Móvil horizontal)
		var is_compact_landscape: bool = vp_size.y < 540.0
		var card_w: float = minf(vp_size.x - 32.0, 700.0 if not is_compact_landscape else 640.0)
		var card_h: float = minf(vp_size.y - (16.0 if is_compact_landscape else 28.0), 620.0)

		modal_card.anchor_left = 0.5
		modal_card.anchor_right = 0.5
		modal_card.anchor_top = 0.5
		modal_card.anchor_bottom = 0.5
		modal_card.offset_left = -card_w * 0.5
		modal_card.offset_right = card_w * 0.5
		modal_card.offset_top = -card_h * 0.5
		modal_card.offset_bottom = card_h * 0.5
		modal_card.custom_minimum_size = Vector2(card_w, card_h)
		modal_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		if is_instance_valid(header_avatar):
			header_avatar.custom_minimum_size = Vector2(44, 44) if is_compact_landscape else Vector2(58, 58)
		if is_instance_valid(header_title):
			header_title.add_theme_font_size_override("font_size", 22 if is_compact_landscape else 26)
		if is_instance_valid(header_subtitle):
			header_subtitle.add_theme_font_size_override("font_size", 12 if is_compact_landscape else 13)

		var btn_h = 42.0 if is_compact_landscape else 48.0
		cancel_btn.custom_minimum_size = Vector2(160, btn_h)
		cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		confirm_btn.custom_minimum_size = Vector2(230, btn_h)
		confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_END

		for card in card_panels:
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			card.custom_minimum_size = Vector2(0, 74 if is_compact_landscape else 84)
