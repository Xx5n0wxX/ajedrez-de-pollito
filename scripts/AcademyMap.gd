extends Control

## AcademyMap: Selector visual de Grados Oficiales (48 lecciones x 3 etapas = 144 retos)
## y del Gimnasio de Movimientos y Táctica (7 cuadernos x 10 ejercicios = 70 ejercicios).

const AcademyManagerScript = preload("res://scripts/AcademyManager.gd")
const ProfileManagerScript = preload("res://scripts/ProfileManager.gd")

const SFX_CLICK = preload("res://assets/sounds/click.wav")
const FONT_CHERRY = preload("res://assets/fonts/CherryBombOne-Regular.ttf")

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
	
	var am = _get_am()
	if am:
		if not am.progress_updated.is_connected(_refresh_view):
			am.progress_updated.connect(_refresh_view)
		current_mode = am.current_mode
		current_grade_num = am.current_grade_num
		current_pack_id = am.current_pack_id
	
	_refresh_view()

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

func _build_mode_buttons() -> void:
	if not mode_selector_bar:
		return
	for c in mode_selector_bar.get_children():
		c.queue_free()
	
	var modes = [
		{"id": "grades", "label": "🎓 Grados de la Academia (48 Lecciones · 144 Retos)"},
		{"id": "practice", "label": "🏋️ Gimnasio de Movimientos (7 Cuadernos · 70 Ejercicios)"}
	]
	for m in modes:
		var m_id: String = m.id
		var is_sel = (current_mode == m_id)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(360, 42)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_override("font", FONT_CHERRY)
		btn.add_theme_font_size_override("font_size", 14)
		btn.text = m.label
		
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(12)
		sb.border_width_bottom = 3
		if is_sel:
			sb.bg_color = Color("#7c3aed") if m_id == "practice" else Color("#db2777")
			sb.border_color = Color("#4c1d95") if m_id == "practice" else Color("#9d174d")
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			sb.bg_color = Color("#f3e8ff") if m_id == "practice" else Color("#fce7f3")
			sb.border_color = Color("#c084fc") if m_id == "practice" else Color("#f472b6")
			btn.add_theme_color_override("font_color", Color("#4c1d95") if m_id == "practice" else Color("#831843"))
		
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

func _update_header() -> void:
	var am = _get_am()
	var pm = _get_pm()
	
	var player_name = "Lyanna"
	var gender_icon = "👧"
	if pm:
		player_name = pm.get_player_name()
		gender_icon = pm.get_gender_icon()
	
	lbl_player_info.text = "%s %s" % [gender_icon, player_name]
	
	var total_stars = am.get_total_stars() if am else 0
	lbl_total_stars.text = "⭐ %d Estrellas" % total_stars
	
	var advice = ""
	if current_mode == "practice":
		advice = "¡{bienvenida/bienvenido} al Gimnasio de Movimientos, %s! Aquí tienes 70 ejercicios libres separados por pieza para practicar cada movimiento a tu ritmo." % player_name
	else:
		advice = "¡Hola, %s! Cada lección tiene 3 etapas progresivas y retos de varias jugadas. ¡Elige una lección y a jugar!" % player_name
	if am:
		advice = am.adapt_text(advice)
	lbl_pollito_advice.text = advice

func _build_grade_tabs() -> void:
	var am = _get_am()
	if not am:
		return
	
	for c in grades_tab_container.get_children():
		c.queue_free()
	
	var all_grades = am.get_all_grades()
	for g in all_grades:
		var g_num = int(g.get("number", 1))
		var is_unlocked = am.is_grade_unlocked(g_num)
		var is_selected = (g_num == current_grade_num)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(165, 48)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_override("font", FONT_CHERRY)
		btn.add_theme_font_size_override("font_size", 14)
		
		var icon = g.get("badge_icon", "🎓")
		if not is_unlocked:
			icon = "🔒"
		
		btn.text = "%s Grado %d" % [icon, g_num]
		
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(14)
		sb.border_width_bottom = 3
		
		if is_selected:
			sb.bg_color = Color("#db2777")
			sb.border_color = Color("#9d174d")
			btn.add_theme_color_override("font_color", Color.WHITE)
		elif is_unlocked:
			sb.bg_color = Color("#ffffff")
			sb.border_color = Color("#f472b6")
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			btn.add_theme_color_override("font_color", Color("#831843"))
		else:
			sb.bg_color = Color("#e5e7eb")
			sb.border_color = Color("#9ca3af")
			btn.add_theme_color_override("font_color", Color("#6b7280"))
		
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
	
	var packs = am.get_all_practice_packs()
	for p in packs:
		var p_id: String = p.get("id", "")
		var is_selected = (p_id == current_pack_id)
		var icon: String = p.get("icon", "♟️")
		var short_name: String = p.get("name", "").replace("Gimnasio de la ", "").replace("Gimnasio del ", "").replace("Gimnasio de ", "").replace(" en 2 Jugadas", "")
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(142, 48)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_override("font", FONT_CHERRY)
		btn.add_theme_font_size_override("font_size", 13)
		btn.text = "%s %s" % [icon, short_name]
		
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(14)
		sb.border_width_bottom = 3
		if is_selected:
			sb.bg_color = Color("#7c3aed")
			sb.border_color = Color("#4c1d95")
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			sb.bg_color = Color("#ffffff")
			sb.border_color = Color("#c084fc")
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			btn.add_theme_color_override("font_color", Color("#4c1d95"))
		
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
	
	var g_icon = g.get("badge_icon", "🎓")
	var g_name = g.get("name", "")
	var g_sub = g.get("subtitle", "")
	var g_src = g.get("source", "")
	var badge_name = g.get("badge_name", "")
	var has_badge = am.has_medal(g.get("badge_id", ""))
	
	lbl_selected_grade_title.text = "%s Grado %d: %s (%s)" % [g_icon, g_num, g_name, g_sub]
	var badge_status = "🏅 Medalla: " + badge_name + (" (¡Conseguida! 🎉)" if has_badge else " (Completa las 8 lecciones)")
	lbl_selected_grade_source.text = "📚 Fuente pedagógica: %s\n%s" % [g_src, badge_status]
	
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
	
	var p_icon = p.get("icon", "♟️")
	var p_name = p.get("name", "")
	var p_sub = p.get("subtitle", "")
	var exs: Array = p.get("exercises", [])
	var done_count = 0
	for ex in exs:
		if am.is_lesson_completed(ex.get("id", "")):
			done_count += 1
	
	lbl_selected_grade_title.text = "%s %s" % [p_icon, p_name]
	lbl_selected_grade_source.text = "🏋️ %s\n✅ Progreso del cuaderno: %d / %d ejercicios completados (¡Todos abiertos para practicar libremente!)" % [p_sub, done_count, exs.size()]
	
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

func _create_lesson_card(idx: int, prefix: String, l_data: Dictionary, badge_tag: String, is_unlocked: bool, is_completed: bool, stars: int, is_practice: bool) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 72)
	
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(14)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 3
	
	if is_completed:
		sb.bg_color = Color("#f0fdf4")
		sb.border_color = Color("#86efac")
	elif is_unlocked:
		sb.bg_color = Color("#ffffff")
		sb.border_color = Color("#e9d5ff") if is_practice else Color("#fbcfe8")
	else:
		sb.bg_color = Color("#f3f4f6")
		sb.border_color = Color("#d1d5db")
	
	card.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)
	
	var status_lbl = Label.new()
	status_lbl.custom_minimum_size = Vector2(36, 0)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 22)
	if is_completed:
		status_lbl.text = "✅"
	elif is_unlocked:
		status_lbl.text = "🏋️" if is_practice else "♟️"
	else:
		status_lbl.text = "🔒"
	hbox.add_child(status_lbl)
	
	var vbox_text = VBoxContainer.new()
	vbox_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_text.add_theme_constant_override("separation", 2)
	
	var title_lbl = Label.new()
	title_lbl.text = "%s %s   [%s]" % [prefix, l_data.get("title", ""), badge_tag]
	title_lbl.add_theme_font_override("font", FONT_CHERRY)
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color("#1f2937") if is_unlocked else Color("#9ca3af"))
	vbox_text.add_child(title_lbl)
	
	var sub_lbl = Label.new()
	sub_lbl.text = l_data.get("subtitle", "")
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color("#4b5563") if is_unlocked else Color("#9ca3af"))
	vbox_text.add_child(sub_lbl)
	hbox.add_child(vbox_text)
	
	var stars_lbl = Label.new()
	var stars_text = ""
	for s in range(3):
		stars_text += "⭐" if s < stars else "☆"
	stars_lbl.text = stars_text
	stars_lbl.add_theme_font_size_override("font_size", 18)
	stars_lbl.add_theme_color_override("font_color", Color("#eab308") if is_unlocked else Color("#9ca3af"))
	hbox.add_child(stars_lbl)
	
	if is_unlocked:
		var btn_play = Button.new()
		btn_play.custom_minimum_size = Vector2(130, 42)
		btn_play.focus_mode = Control.FOCUS_NONE
		btn_play.add_theme_font_override("font", FONT_CHERRY)
		btn_play.add_theme_font_size_override("font_size", 14)
		btn_play.text = "¡Practicar! ▶️" if (is_practice and not is_completed) else ("¡Jugar! ▶️" if not is_completed else "Repetir 🔄")
		
		var btn_sb = StyleBoxFlat.new()
		btn_sb.set_corner_radius_all(12)
		btn_sb.border_width_bottom = 3
		if is_completed:
			btn_sb.bg_color = Color("#0ea5e9")
			btn_sb.border_color = Color("#0284c7")
		elif is_practice:
			btn_sb.bg_color = Color("#7c3aed")
			btn_sb.border_color = Color("#4c1d95")
		else:
			btn_sb.bg_color = Color("#db2777")
			btn_sb.border_color = Color("#9d174d")
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
