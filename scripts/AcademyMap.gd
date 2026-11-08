extends Control

## AcademyMap: Selector visual de Grados Oficiales (48 lecciones x 3 etapas = 144 retos)
## y del Gimnasio de Movimientos y Táctica (7 cuadernos x 10 ejercicios = 70 ejercicios).
## Rediseñado con estética Candy 3D, soporte para Notch/Barra de Notificaciones (Safe Area)
## y tipografía grande y táctil para niños.

const AcademyManagerScript = preload("res://scripts/AcademyManager.gd")
const ProfileManagerScript = preload("res://scripts/ProfileManager.gd")

const SFX_CLICK = preload("res://assets/sounds/click.wav")
const FONT_CHERRY = preload("res://assets/fonts/CherryBombOne-Regular.ttf")

@onready var root_margin: MarginContainer = %Margin if has_node("%Margin") else find_child("Margin", true, false)
@onready var btn_back_to_menu: Button = %BtnBackToMenu
@onready var lbl_player_info: Label = %LblPlayerInfo
@onready var lbl_total_stars: Label = %LblTotalStars
@onready var mode_selector_bar: HBoxContainer = %ModeSelectorBar
@onready var grades_tab_container: HBoxContainer = %GradesTabContainer
@onready var lbl_selected_grade_title: Label = %LblSelectedGradeTitle
@onready var lbl_selected_grade_source: Label = %LblSelectedGradeSource
@onready var lessons_vbox: VBoxContainer = %LessonsVBox
@onready var lbl_pollito_advice: Label = %LblPollitoAdvice

var current_mode: String = "grades" # "grades" o "practice"
var current_grade_num: int = 1
var current_pack_id: String = "pack_torre"
var audio_player: AudioStreamPlayer = null

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	if btn_back_to_menu and not btn_back_to_menu.pressed.is_connected(_on_back_to_menu_pressed):
		btn_back_to_menu.pressed.connect(_on_back_to_menu_pressed)
	
	# Conexión con ScreenManager para Notch / Safe Area y rotación
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if sm.has_signal("safe_area_changed") and not sm.safe_area_changed.is_connected(_on_safe_area_changed):
			sm.safe_area_changed.connect(_on_safe_area_changed)
		if sm.has_signal("orientation_changed") and not sm.orientation_changed.is_connected(_on_orientation_changed):
			sm.orientation_changed.connect(_on_orientation_changed)
	
	var vp = get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)

	var am = _get_am()
	if am:
		if not am.progress_updated.is_connected(_refresh_view):
			am.progress_updated.connect(_refresh_view)
		current_mode = am.current_mode
		current_grade_num = am.current_grade_num
		current_pack_id = am.current_pack_id
	
	_apply_safe_area()
	_refresh_view()

func _on_viewport_size_changed() -> void:
	_apply_safe_area()
	_refresh_view()

func _is_portrait_view() -> bool:
	var vp_size = get_viewport_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		return false
	return (vp_size.y > vp_size.x) or (vp_size.x < 680.0)

func _on_safe_area_changed(_top: float) -> void:
	_apply_safe_area()

func _on_orientation_changed(_is_port: bool) -> void:
	_apply_safe_area()
	_refresh_view()

func _apply_safe_area() -> void:
	if not root_margin:
		return
	var safe_top: float = 0.0
	if has_node("/root/ScreenManager"):
		safe_top = get_node("/root/ScreenManager").get_safe_top_margin()
	root_margin.add_theme_constant_override("margin_top", int(safe_top + 14.0))

func _refresh_view() -> void:
	var am = _get_am()
	if not am:
		return
	
	_update_header()
	_build_mode_buttons()
	if current_mode == "practice":
		_build_practice_tabs()
		_display_practice_exercises(current_pack_id)
	else:
		_build_grade_tabs()
		_display_grade_lessons(current_grade_num)

func _update_header() -> void:
	var am = _get_am()
	var pm = _get_pm()
	var is_port = _is_portrait_view()
	
	var player_name = "Lyanna"
	var gender_icon = "👧"
	if pm:
		player_name = pm.get_player_name()
		gender_icon = pm.get_gender_icon()
	
	if lbl_player_info:
		lbl_player_info.text = "%s %s" % [gender_icon, player_name]
		lbl_player_info.add_theme_font_size_override("font_size", 18 if is_port else 16)
	
	var total_stars = am.get_total_stars() if am else 0
	if lbl_total_stars:
		lbl_total_stars.text = "⭐ %d" % total_stars
		lbl_total_stars.add_theme_font_size_override("font_size", 18 if is_port else 16)
	
	if btn_back_to_menu:
		btn_back_to_menu.text = "⬅️ Menú"
		btn_back_to_menu.custom_minimum_size = Vector2(110 if is_port else 136, 52)
		btn_back_to_menu.add_theme_font_size_override("font_size", 18 if is_port else 16)

	var title_lbl = find_child("MainTitle", true, false) as Label
	if title_lbl:
		title_lbl.text = "🎓 Academia" if is_port else "🎓 Academia de Ajedrez"
		title_lbl.add_theme_font_size_override("font_size", 26 if is_port else 24)

	var subtitle_lbl = find_child("SubTitle", true, false) as Label
	if subtitle_lbl:
		subtitle_lbl.visible = not is_port
	
	var advice = ""
	if current_mode == "practice":
		advice = "¡{bienvenida/bienvenido} al Gimnasio, %s! Domina cada pieza a tu ritmo." % player_name if is_port else "¡{bienvenida/bienvenido} al Gimnasio de Movimientos, %s! Aquí tienes 70 retos para dominar cada pieza a tu ritmo." % player_name
	else:
		advice = "¡Hola, %s! ¡Supera los retos para ganar tu medalla!" % player_name if is_port else "¡Hola, %s! Cada lección tiene 3 etapas progresivas. ¡Supera todos los retos para ganar tu medalla!" % player_name
	if am:
		advice = am.adapt_text(advice)
	if lbl_pollito_advice:
		lbl_pollito_advice.text = advice
		lbl_pollito_advice.add_theme_font_size_override("font_size", 16 if is_port else 14)

func _build_mode_buttons() -> void:
	if not mode_selector_bar:
		return
	for c in mode_selector_bar.get_children():
		c.queue_free()
	
	var is_port = _is_portrait_view()
	var modes = [
		{"id": "grades", "label": "🎓 Grados" if is_port else "🎓 Grados Oficiales (48 Lecc.)"},
		{"id": "practice", "label": "⚡ Gimnasio" if is_port else "🏋️ Gimnasio Táctico (70 Ejer.)"}
	]
	for m in modes:
		var m_id: String = m.id
		var is_sel = (current_mode == m_id)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 60 if is_port else 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_override("font", FONT_CHERRY)
		btn.add_theme_font_size_override("font_size", 20 if is_port else 16)
		btn.text = m.label
		
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(20)
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 6
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 4)
		
		if is_sel:
			if m_id == "practice":
				sb.bg_color = Color("#7c3aed")
				sb.border_color = Color("#4c1d95")
				sb.shadow_color = Color(0.48, 0.22, 0.93, 0.25)
			else:
				sb.bg_color = Color("#db2777")
				sb.border_color = Color("#9d174d")
				sb.shadow_color = Color(0.85, 0.15, 0.45, 0.25)
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			sb.bg_color = Color("#ffffff")
			if m_id == "practice":
				sb.border_color = Color("#c084fc")
				sb.shadow_color = Color(0.75, 0.52, 0.98, 0.12)
				btn.add_theme_color_override("font_color", Color("#581c87"))
			else:
				sb.border_color = Color("#f472b6")
				sb.shadow_color = Color(0.96, 0.45, 0.71, 0.12)
				btn.add_theme_color_override("font_color", Color("#831843"))
		
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.pressed.connect(func(): _select_mode(m_id))
		mode_selector_bar.add_child(btn)

func _select_mode(m_id: String) -> void:
	if audio_player:
		audio_player.stream = SFX_CLICK
		audio_player.play()
	current_mode = m_id
	var am = _get_am()
	if am:
		am.current_mode = m_id
	_refresh_view()

func _build_grade_tabs() -> void:
	var am = _get_am()
	if not am:
		return
	
	for c in grades_tab_container.get_children():
		c.queue_free()
	
	var is_port = _is_portrait_view()
	var g_scroll = find_child("GradesScroll", true, false) as ScrollContainer
	if g_scroll:
		g_scroll.custom_minimum_size.y = 78.0 if is_port else 68.0

	var all_grades = am.get_all_grades()
	for g in all_grades:
		var g_num = int(g.get("number", 1))
		var is_unlocked = am.is_grade_unlocked(g_num)
		var is_selected = (g_num == current_grade_num)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(175 if is_port else 170, 62 if is_port else 56)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_override("font", FONT_CHERRY)
		btn.add_theme_font_size_override("font_size", 19 if is_port else 16)
		
		var icon = g.get("badge_icon", "🎓")
		if not is_unlocked:
			icon = "🔒"
		
		btn.text = "%s Grado %d" % [icon, g_num]
		
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(20)
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 6
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 3)
		
		if is_selected:
			sb.bg_color = Color("#db2777")
			sb.border_color = Color("#9d174d")
			sb.shadow_color = Color(0.85, 0.15, 0.45, 0.25)
			btn.add_theme_color_override("font_color", Color.WHITE)
		elif is_unlocked:
			sb.bg_color = Color("#ffffff")
			sb.border_color = Color("#f472b6")
			sb.shadow_color = Color(0.96, 0.45, 0.71, 0.12)
			btn.add_theme_color_override("font_color", Color("#831843"))
		else:
			sb.bg_color = Color("#f3f4f6")
			sb.border_color = Color("#cbd5e1")
			sb.shadow_color = Color(0, 0, 0, 0.05)
			btn.add_theme_color_override("font_color", Color("#94a3b8"))
		
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		
		if is_unlocked:
			btn.pressed.connect(func(): _select_grade(g_num))
		
		grades_tab_container.add_child(btn)

func _build_practice_tabs() -> void:
	var am = _get_am()
	if not am:
		return
	
	for c in grades_tab_container.get_children():
		c.queue_free()
	
	var is_port = _is_portrait_view()
	var g_scroll = find_child("GradesScroll", true, false) as ScrollContainer
	if g_scroll:
		g_scroll.custom_minimum_size.y = 78.0 if is_port else 68.0

	var packs = am.get_all_practice_packs()
	for p in packs:
		var p_id: String = p.get("id", "")
		var is_selected = (p_id == current_pack_id)
		var icon: String = p.get("icon", "♟️")
		var short_name: String = p.get("name", "").replace("Gimnasio de la ", "").replace("Gimnasio del ", "").replace("Gimnasio de ", "").replace(" en 2 Jugadas", "")
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(175 if is_port else 165, 62 if is_port else 56)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_override("font", FONT_CHERRY)
		btn.add_theme_font_size_override("font_size", 18 if is_port else 15)
		btn.text = "%s %s" % [icon, short_name]
		
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(20)
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 6
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 3)
		
		if is_selected:
			sb.bg_color = Color("#7c3aed")
			sb.border_color = Color("#4c1d95")
			sb.shadow_color = Color(0.48, 0.22, 0.93, 0.25)
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			sb.bg_color = Color("#ffffff")
			sb.border_color = Color("#c084fc")
			sb.shadow_color = Color(0.75, 0.52, 0.98, 0.12)
			btn.add_theme_color_override("font_color", Color("#581c87"))
		
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.pressed.connect(func(): _select_practice_pack(p_id))
		grades_tab_container.add_child(btn)

func _select_grade(g_num: int) -> void:
	if audio_player:
		audio_player.stream = SFX_CLICK
		audio_player.play()
	current_grade_num = g_num
	var am = _get_am()
	if am:
		am.current_grade_num = g_num
	_refresh_view()

func _select_practice_pack(p_id: String) -> void:
	if audio_player:
		audio_player.stream = SFX_CLICK
		audio_player.play()
	current_pack_id = p_id
	var am = _get_am()
	if am:
		am.current_pack_id = p_id
	_refresh_view()

func _display_grade_lessons(g_num: int) -> void:
	var am = _get_am()
	if not am:
		return
	
	var g = am.get_grade(g_num)
	if g.is_empty():
		return
	
	var is_port = _is_portrait_view()
	var g_icon = g.get("badge_icon", "🎓")
	var g_name = g.get("name", "")
	var g_sub = g.get("subtitle", "")
	var badge_name = g.get("badge_name", "")
	var has_badge = am.has_medal(g.get("badge_id", ""))
	
	lbl_selected_grade_title.add_theme_font_size_override("font_size", 22 if is_port else 19)
	lbl_selected_grade_title.text = "%s Grado %d: %s" % [g_icon, g_num, g_name]
	
	lbl_selected_grade_source.add_theme_font_size_override("font_size", 16 if is_port else 13)
	var badge_status = "🏅 Medalla: " + badge_name + (" (¡Conseguida! 🎉)" if has_badge else " (Completa las 8 lecciones)")
	if is_port:
		lbl_selected_grade_source.text = "%s\n%s" % [g_sub, badge_status]
	else:
		var g_src = g.get("source", "")
		lbl_selected_grade_source.text = "%s\n📚 %s • %s" % [g_sub, g_src, badge_status]
	
	for c in lessons_vbox.get_children():
		c.queue_free()
	
	var lessons: Array = g.get("lessons", [])
	for idx in range(lessons.size()):
		var l_data = lessons[idx]
		var l_id = l_data.get("id", "")
		var is_unlocked = am.is_lesson_unlocked(g_num, idx)
		var is_completed = am.is_lesson_completed(l_id)
		var stars = am.get_lesson_stars(l_id)
		var stages_count = l_data.get("stages", []).size()
		var prefix = "%d.%d" % [current_grade_num, idx + 1]
		var badge_tag = "🎯 %d Etapas" % stages_count if stages_count > 1 else "🎯 1 Etapa"
		
		var item_card = _create_lesson_card(idx, prefix, l_data, badge_tag, is_unlocked, is_completed, stars, false)
		lessons_vbox.add_child(item_card)

func _display_practice_exercises(pack_id: String) -> void:
	var am = _get_am()
	if not am:
		return
	
	var p = am.get_practice_pack(pack_id)
	if p.is_empty():
		return
	
	var is_port = _is_portrait_view()
	var p_icon = p.get("icon", "♟️")
	var p_name = p.get("name", "")
	var p_sub = p.get("subtitle", "")
	var exs: Array = p.get("exercises", [])
	var done_count = 0
	for ex in exs:
		if am.is_lesson_completed(ex.get("id", "")):
			done_count += 1
	
	lbl_selected_grade_title.add_theme_font_size_override("font_size", 22 if is_port else 19)
	lbl_selected_grade_title.text = "%s %s" % [p_icon, p_name]
	
	lbl_selected_grade_source.add_theme_font_size_override("font_size", 16 if is_port else 13)
	lbl_selected_grade_source.text = "%s\n✅ Progreso: %d de %d ejercicios completados" % [p_sub, done_count, exs.size()]
	
	for c in lessons_vbox.get_children():
		c.queue_free()
	
	for idx in range(exs.size()):
		var ex_data = exs[idx]
		var ex_id = ex_data.get("id", "")
		var is_completed = am.is_lesson_completed(ex_id)
		var stars = am.get_lesson_stars(ex_id)
		var has_cont = ex_data.has("continuation")
		var prefix = "#%d" % [idx + 1]
		var badge_tag = "⚡ 2 Jugadas" if has_cont else "🎯 1 Jugada"
		
		var item_card = _create_lesson_card(idx, prefix, ex_data, badge_tag, true, is_completed, stars, true)
		lessons_vbox.add_child(item_card)

func _create_status_icon_panel(is_completed: bool, is_unlocked: bool, is_practice: bool, size_px: float = 54.0) -> PanelContainer:
	var status_panel = PanelContainer.new()
	status_panel.custom_minimum_size = Vector2(size_px, size_px)
	status_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var status_sb = StyleBoxFlat.new()
	status_sb.set_corner_radius_all(18)
	status_sb.border_width_left = 2
	status_sb.border_width_top = 2
	status_sb.border_width_right = 2
	status_sb.border_width_bottom = 5

	if is_completed:
		status_sb.bg_color = Color("#dcfce7")
		status_sb.border_color = Color("#22c55e")
	elif is_unlocked:
		status_sb.bg_color = Color("#fce7f3") if not is_practice else Color("#f3e8ff")
		status_sb.border_color = Color("#f472b6") if not is_practice else Color("#c084fc")
	else:
		status_sb.bg_color = Color("#e2e8f0")
		status_sb.border_color = Color("#94a3b8")
	status_panel.add_theme_stylebox_override("panel", status_sb)

	var status_lbl = Label.new()
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", int(size_px * 0.48))
	if is_completed:
		status_lbl.text = "🏆"
	elif is_unlocked:
		status_lbl.text = "🏋️" if is_practice else "♟️"
	else:
		status_lbl.text = "🔒"
	status_panel.add_child(status_lbl)
	return status_panel

func _create_tag_pill(badge_tag: String, font_sz: int = 13) -> PanelContainer:
	var tag_panel = PanelContainer.new()
	var tag_sb = StyleBoxFlat.new()
	tag_sb.set_corner_radius_all(10)
	tag_sb.bg_color = Color("#f1f5f9")
	tag_sb.border_color = Color("#cbd5e1")
	tag_sb.border_width_left = 1
	tag_sb.border_width_top = 1
	tag_sb.border_width_right = 1
	tag_sb.border_width_bottom = 2
	tag_panel.add_theme_stylebox_override("panel", tag_sb)

	var tag_margin = MarginContainer.new()
	tag_margin.add_theme_constant_override("margin_left", 10)
	tag_margin.add_theme_constant_override("margin_right", 10)
	tag_margin.add_theme_constant_override("margin_top", 3)
	tag_margin.add_theme_constant_override("margin_bottom", 3)
	tag_panel.add_child(tag_margin)

	var tag_lbl = Label.new()
	tag_lbl.text = badge_tag
	tag_lbl.add_theme_font_size_override("font_size", font_sz)
	tag_lbl.add_theme_color_override("font_color", Color("#475569"))
	tag_margin.add_child(tag_lbl)
	return tag_panel

func _create_stars_label(stars: int, is_unlocked: bool, font_sz: int = 26) -> Label:
	var stars_lbl = Label.new()
	var stars_text = ""
	for s in range(3):
		stars_text += "⭐" if s < stars else "☆"
	stars_lbl.text = stars_text
	stars_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stars_lbl.add_theme_font_size_override("font_size", font_sz)
	stars_lbl.add_theme_color_override("font_color", Color("#f59e0b") if is_unlocked else Color("#cbd5e1"))
	return stars_lbl

func _create_lesson_card(idx: int, prefix: String, l_data: Dictionary, badge_tag: String, is_unlocked: bool, is_completed: bool, stars: int, is_practice: bool) -> Control:
	var is_port = _is_portrait_view()
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(24)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 7
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 4)

	if is_completed:
		sb.bg_color = Color("#f0fdf4")
		sb.border_color = Color("#4ade80")
		sb.shadow_color = Color(0.29, 0.87, 0.5, 0.16)
	elif is_unlocked:
		sb.bg_color = Color("#ffffff")
		sb.border_color = Color("#c084fc") if is_practice else Color("#f472b6")
		sb.shadow_color = Color(0.96, 0.45, 0.71, 0.14)
	else:
		sb.bg_color = Color("#f8fafc")
		sb.border_color = Color("#cbd5e1")
		sb.shadow_color = Color(0, 0, 0, 0.04)

	card.add_theme_stylebox_override("panel", sb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18 if is_port else 16)
	margin.add_theme_constant_override("margin_right", 18 if is_port else 16)
	margin.add_theme_constant_override("margin_top", 14 if is_port else 12)
	margin.add_theme_constant_override("margin_bottom", 14 if is_port else 12)
	card.add_child(margin)

	if is_port:
		# DISPOSICIÓN MÓVIL VERTICAL: Espaciosa, letras grandes y botón ancho táctil
		card.custom_minimum_size = Vector2(0, 160)
		var main_vbox = VBoxContainer.new()
		main_vbox.add_theme_constant_override("separation", 10)
		margin.add_child(main_vbox)

		# Fila 1: Icono circular + Título + Píldora de Etapas + Estrellas
		var top_hbox = HBoxContainer.new()
		top_hbox.add_theme_constant_override("separation", 12)
		main_vbox.add_child(top_hbox)

		var status_panel = _create_status_icon_panel(is_completed, is_unlocked, is_practice, 54)
		top_hbox.add_child(status_panel)

		var title_vbox = VBoxContainer.new()
		title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_vbox.add_theme_constant_override("separation", 3)
		top_hbox.add_child(title_vbox)

		var title_lbl = Label.new()
		title_lbl.text = "%s %s" % [prefix, l_data.get("title", "")]
		title_lbl.add_theme_font_override("font", FONT_CHERRY)
		title_lbl.add_theme_font_size_override("font_size", 21)
		title_lbl.add_theme_color_override("font_color", Color("#0f172a") if is_unlocked else Color("#94a3b8"))
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_vbox.add_child(title_lbl)

		var tag_panel = _create_tag_pill(badge_tag, 13)
		tag_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		title_vbox.add_child(tag_panel)

		var stars_lbl = _create_stars_label(stars, is_unlocked, 26)
		top_hbox.add_child(stars_lbl)

		# Fila 2: Descripción clara y grande
		var sub_text = l_data.get("subtitle", "")
		if not sub_text.is_empty():
			var sub_lbl = Label.new()
			sub_lbl.text = sub_text
			sub_lbl.add_theme_font_size_override("font_size", 16)
			sub_lbl.add_theme_color_override("font_color", Color("#334155") if is_unlocked else Color("#94a3b8"))
			sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			main_vbox.add_child(sub_lbl)

		# Fila 3: Botón de acción ancho (si está desbloqueado) o Barra de bloqueo
		if is_unlocked:
			var btn_action = Button.new()
			btn_action.custom_minimum_size = Vector2(0, 56)
			btn_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn_action.focus_mode = Control.FOCUS_NONE
			btn_action.add_theme_font_override("font", FONT_CHERRY)
			btn_action.add_theme_font_size_override("font_size", 19)

			var btn_sb = StyleBoxFlat.new()
			btn_sb.set_corner_radius_all(18)
			btn_sb.border_width_left = 3
			btn_sb.border_width_top = 3
			btn_sb.border_width_right = 3
			btn_sb.border_width_bottom = 6
			btn_sb.shadow_size = 10
			btn_sb.shadow_offset = Vector2(0, 4)

			if is_completed:
				btn_sb.bg_color = Color("#0284c7")
				btn_sb.border_color = Color("#0369a1")
				btn_sb.shadow_color = Color(0.01, 0.41, 0.63, 0.25)
				btn_action.text = "⭐ ¡COMPLETADA! (Repetir 🔄)"
			elif is_practice:
				btn_sb.bg_color = Color("#7c3aed")
				btn_sb.border_color = Color("#5b21b6")
				btn_sb.shadow_color = Color(0.48, 0.22, 0.93, 0.25)
				btn_action.text = "⚡ ¡ENTRENAR EJERCICIO! ▶"
			else:
				btn_sb.bg_color = Color("#10b981")
				btn_sb.border_color = Color("#047857")
				btn_sb.shadow_color = Color(0.06, 0.72, 0.5, 0.25)
				btn_action.text = "🎮 ¡JUGAR ESTA LECCIÓN! ▶"

			btn_action.add_theme_color_override("font_color", Color.WHITE)
			btn_action.add_theme_stylebox_override("normal", btn_sb)
			btn_action.add_theme_stylebox_override("hover", btn_sb)
			btn_action.add_theme_stylebox_override("pressed", btn_sb)

			if is_practice:
				btn_action.pressed.connect(func(): _start_practice_exercise(idx))
			else:
				btn_action.pressed.connect(func(): _start_lesson(idx))
			main_vbox.add_child(btn_action)
		else:
			var lock_banner = PanelContainer.new()
			lock_banner.custom_minimum_size = Vector2(0, 48)
			var l_sb = StyleBoxFlat.new()
			l_sb.set_corner_radius_all(14)
			l_sb.bg_color = Color("#f1f5f9")
			l_sb.border_width_left = 1
			l_sb.border_width_top = 1
			l_sb.border_width_right = 1
			l_sb.border_width_bottom = 2
			l_sb.border_color = Color("#cbd5e1")
			lock_banner.add_theme_stylebox_override("panel", l_sb)

			var l_lbl = Label.new()
			l_lbl.text = "🔒 Bloqueada • Supera el reto anterior para abrirla"
			l_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l_lbl.add_theme_font_size_override("font_size", 15)
			l_lbl.add_theme_color_override("font_color", Color("#64748b"))
			lock_banner.add_child(l_lbl)
			main_vbox.add_child(lock_banner)
	else:
		# DISPOSICIÓN ESCRITORIO / TABLET HORIZONTAL
		card.custom_minimum_size = Vector2(0, 108)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)
		margin.add_child(hbox)

		var status_panel = _create_status_icon_panel(is_completed, is_unlocked, is_practice, 54)
		hbox.add_child(status_panel)

		var vbox_text = VBoxContainer.new()
		vbox_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_text.add_theme_constant_override("separation", 4)

		var header_hbox = HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		vbox_text.add_child(header_hbox)

		var title_lbl = Label.new()
		title_lbl.text = "%s %s" % [prefix, l_data.get("title", "")]
		title_lbl.add_theme_font_override("font", FONT_CHERRY)
		title_lbl.add_theme_font_size_override("font_size", 20)
		title_lbl.add_theme_color_override("font_color", Color("#0f172a") if is_unlocked else Color("#94a3b8"))
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_hbox.add_child(title_lbl)

		var tag_panel = _create_tag_pill(badge_tag, 12)
		header_hbox.add_child(tag_panel)

		var sub_lbl = Label.new()
		sub_lbl.text = l_data.get("subtitle", "")
		sub_lbl.add_theme_font_size_override("font_size", 15)
		sub_lbl.add_theme_color_override("font_color", Color("#334155") if is_unlocked else Color("#94a3b8"))
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox_text.add_child(sub_lbl)
		hbox.add_child(vbox_text)

		var stars_lbl = _create_stars_label(stars, is_unlocked, 24)
		hbox.add_child(stars_lbl)

		if is_unlocked:
			var btn_play = Button.new()
			btn_play.custom_minimum_size = Vector2(148, 54)
			btn_play.focus_mode = Control.FOCUS_NONE
			btn_play.add_theme_font_override("font", FONT_CHERRY)
			btn_play.add_theme_font_size_override("font_size", 16)
			btn_play.text = "¡JUGAR! ▶" if not is_completed else "REPETIR 🔄"

			var btn_sb = StyleBoxFlat.new()
			btn_sb.set_corner_radius_all(18)
			btn_sb.border_width_left = 3
			btn_sb.border_width_top = 3
			btn_sb.border_width_right = 3
			btn_sb.border_width_bottom = 6
			btn_sb.shadow_size = 8
			btn_sb.shadow_offset = Vector2(0, 3)

			if is_completed:
				btn_sb.bg_color = Color("#0284c7")
				btn_sb.border_color = Color("#0369a1")
			elif is_practice:
				btn_sb.bg_color = Color("#7c3aed")
				btn_sb.border_color = Color("#5b21b6")
			else:
				btn_sb.bg_color = Color("#10b981")
				btn_sb.border_color = Color("#047857")

			btn_play.add_theme_stylebox_override("normal", btn_sb)
			btn_play.add_theme_stylebox_override("hover", btn_sb)
			btn_play.add_theme_stylebox_override("pressed", btn_sb)
			btn_play.add_theme_color_override("font_color", Color.WHITE)

			if is_practice:
				btn_play.pressed.connect(func(): _start_practice_exercise(idx))
			else:
				btn_play.pressed.connect(func(): _start_lesson(idx))
			hbox.add_child(btn_play)

	return card

func _start_lesson(lesson_idx: int) -> void:
	if audio_player:
		audio_player.stream = SFX_CLICK
		audio_player.play()
	
	var am = _get_am()
	if am:
		am.current_mode = "grades"
		am.current_grade_num = current_grade_num
		am.current_lesson_idx = lesson_idx
	
	get_tree().change_scene_to_file("res://scenes/AulaAcademia.tscn")

func _start_practice_exercise(ex_idx: int) -> void:
	if audio_player:
		audio_player.stream = SFX_CLICK
		audio_player.play()
	
	var am = _get_am()
	if am:
		am.current_mode = "practice"
		am.current_pack_id = current_pack_id
		am.current_exercise_idx = ex_idx
	
	get_tree().change_scene_to_file("res://scenes/AulaAcademia.tscn")

func _on_back_to_menu_pressed() -> void:
	if audio_player:
		audio_player.stream = SFX_CLICK
		audio_player.play()
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _get_am() -> Node:
	if is_inside_tree() and has_node("/root/AcademyManager"):
		return get_node("/root/AcademyManager")
	if AcademyManagerScript.instance:
		return AcademyManagerScript.instance
	return null

func _get_pm() -> Node:
	if is_inside_tree() and has_node("/root/ProfileManager"):
		return get_node("/root/ProfileManager")
	if ProfileManagerScript.instance:
		return ProfileManagerScript.instance
	return null
