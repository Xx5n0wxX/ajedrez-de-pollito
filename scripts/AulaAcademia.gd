extends Control

## AulaAcademia: Controlador de la lección interactiva de ajedrez y del Gimnasio de Movimientos.
## Reutiliza exactamente el mismo tamaño, disposición y comportamiento de ChessBoard.
## Soporta:
## - Lecciones multi-etapa (3 etapas progresivas por lección)
## - Secuencias multi-jugada (continuation: el rival responde y el jugador remata)
## - Cuadernos del Gimnasio de Movimientos (70 ejercicios por pieza y combinaciones)
## - Refutación Activa (Active Refutation) y Rebobinado en el tiempo ⏪

const ChessBoardClass = preload("res://scripts/ChessBoard.gd")
const AcademyManagerScript = preload("res://scripts/AcademyManager.gd")
const ProfileManagerScript = preload("res://scripts/ProfileManager.gd")

# Texturas de emociones de Pollito
const TEX_EXPLICANDO = preload("res://assets/ui/pollito_explicando.png")
const TEX_PENSANDO = preload("res://assets/ui/pollito_pensando.png")
const TEX_CELEBRANDO = preload("res://assets/ui/pollito_celebrando.png")
const TEX_ANIMANDO = preload("res://assets/ui/pollito_animando.png")

# Efectos de audio
const SFX_VICTORY = preload("res://assets/sounds/victory.wav")
const SFX_KIKIRIKI = preload("res://assets/sounds/kikiriki.wav")
const SFX_CLICK = preload("res://assets/sounds/click.wav")

@onready var main_layout: BoxContainer = %MainLayout if has_node("%MainLayout") else find_child("MainLayout", true, false)
@onready var left_column: Control = %LeftColumn if has_node("%LeftColumn") else find_child("LeftColumn", true, false)
@onready var right_column: Control = %RightColumn if has_node("%RightColumn") else find_child("RightColumn", true, false)
@onready var btn_swap_layout_aula: Button = %BtnSwapLayoutAula if has_node("%BtnSwapLayoutAula") else find_child("BtnSwapLayoutAula", true, false)

@onready var board: ChessBoard = %ChessBoard
@onready var lbl_grade_title: Label = %LblGradeTitle
@onready var lbl_lesson_title: Label = %LblLessonTitle
@onready var btn_back_to_map: Button = %BtnBackToMap

# Panel derecho de Pollito
@onready var pollito_avatar: PollitoAvatar = %PollitoAvatar as PollitoAvatar
@onready var lbl_dialogue: RichTextLabel = %LblDialogue
@onready var lbl_objective: Label = %LblObjective
@onready var feedback_panel: PanelContainer = %FeedbackPanel
@onready var lbl_feedback: Label = %LblFeedback
@onready var btn_rewind: Button = %BtnRewind
@onready var btn_hint: Button = %BtnHint
@onready var btn_reset: Button = %BtnReset
@onready var btn_next_lesson: Button = %BtnNextLesson
@onready var stars_container: HBoxContainer = %StarsContainer
@onready var lbl_star_1: Label = %Star1
@onready var lbl_star_2: Label = %Star2
@onready var lbl_star_3: Label = %Star3

# Estado de la lección y etapa activa
var current_lesson: Dictionary = {}
var current_grade: Dictionary = {}
var current_pack: Dictionary = {}
var current_stages: Array = []
var current_stage_idx: int = 0
var active_board_data: Dictionary = {}
var starting_fen: String = ""

# Estado de continuación multi-jugada
var is_in_continuation: bool = false
var is_playing_opponent_continuation: bool = false
var is_restoring_checkpoint: bool = false
var cont_p1_from: String = ""
var cont_p1_to: String = ""
var cont_p1_promo: String = "q"
var cont_opp_from: String = ""
var cont_opp_to: String = ""
var instant_test_mode: bool = false

var hints_used: int = 0
var mistake_count: int = 0
var is_lesson_finished: bool = false
var is_stage_finished: bool = false
var is_awaiting_rewind: bool = false
var _lesson_token: int = 0
var audio_player: AudioStreamPlayer = null

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	_connect_ui_signals()
	_setup_responsive_layout()
	_load_current_lesson()

func _exit_tree() -> void:
	var vm = _get_vm()
	if vm and vm.has_method("stop"):
		vm.stop()

func _get_vm() -> Node:
	return get_node_or_null("/root/VoiceManager")

func _speak(text: String) -> void:
	if text.is_empty() or not is_inside_tree() or not get_tree():
		return
	var vm = _get_vm()
	if vm and vm.has_method("speak"):
		vm.speak(text)

func _connect_ui_signals() -> void:
	if btn_back_to_map and not btn_back_to_map.pressed.is_connected(_on_back_to_map_pressed):
		btn_back_to_map.pressed.connect(_on_back_to_map_pressed)
	if btn_rewind and not btn_rewind.pressed.is_connected(_on_rewind_pressed):
		btn_rewind.pressed.connect(_on_rewind_pressed)
	if btn_hint and not btn_hint.pressed.is_connected(_on_hint_pressed):
		btn_hint.pressed.connect(_on_hint_pressed)
	if btn_reset and not btn_reset.pressed.is_connected(_on_reset_pressed):
		btn_reset.pressed.connect(_on_reset_pressed)
	if btn_next_lesson and not btn_next_lesson.pressed.is_connected(_on_next_lesson_pressed):
		btn_next_lesson.pressed.connect(_on_next_lesson_pressed)
	if btn_swap_layout_aula:
		btn_swap_layout_aula.icon = load("res://assets/icons/swap_layout.svg")
		btn_swap_layout_aula.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_swap_layout_aula.expand_icon = true
		btn_swap_layout_aula.text = ""
		if not btn_swap_layout_aula.pressed.is_connected(_on_swap_layout_pressed):
			btn_swap_layout_aula.pressed.connect(_on_swap_layout_pressed)
	
	if board:
		if not board.move_completed.is_connected(_on_player_move_completed):
			board.move_completed.connect(_on_player_move_completed)

var _swap_tween: Tween = null

func _on_swap_layout_pressed() -> void:
	if is_instance_valid(btn_swap_layout_aula):
		btn_swap_layout_aula.pivot_offset = btn_swap_layout_aula.size * 0.5
		var btn_tw = btn_swap_layout_aula.create_tween()
		btn_tw.tween_property(btn_swap_layout_aula, "rotation", btn_swap_layout_aula.rotation + PI, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_play_swap_sound()
	if has_node("/root/ScreenManager"):
		get_node("/root/ScreenManager").toggle_board_swap()

func _play_swap_sound() -> void:
	var sfx = load("res://assets/sounds/click.wav")
	if sfx and is_inside_tree():
		var p = AudioStreamPlayer.new()
		p.stream = sfx
		add_child(p)
		p.finished.connect(p.queue_free)
		p.play()

func _on_layout_swap_toggled(_swapped: bool) -> void:
	var animate = false
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if "animate_next_swap" in sm:
			animate = sm.animate_next_swap
	_update_responsive_layout(animate)

func _on_mobile_mode_changed(_mob: bool) -> void:
	_update_responsive_layout()

func _on_screen_orientation_changed(_is_portrait: bool) -> void:
	_update_responsive_layout()

func _on_viewport_size_changed() -> void:
	_update_responsive_layout()

func _setup_responsive_layout() -> void:
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if not sm.orientation_changed.is_connected(_on_screen_orientation_changed):
			sm.orientation_changed.connect(_on_screen_orientation_changed)
		if sm.has_signal("layout_swap_toggled") and not sm.layout_swap_toggled.is_connected(_on_layout_swap_toggled):
			sm.layout_swap_toggled.connect(_on_layout_swap_toggled)
		if sm.has_signal("mobile_mode_changed") and not sm.mobile_mode_changed.is_connected(_on_mobile_mode_changed):
			sm.mobile_mode_changed.connect(_on_mobile_mode_changed)
		if sm.has_signal("safe_area_changed") and not sm.safe_area_changed.is_connected(_on_safe_area_changed):
			sm.safe_area_changed.connect(_on_safe_area_changed)

	var vp = get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)

	call_deferred("_update_responsive_layout")

func _on_safe_area_changed(_top: float) -> void:
	_update_responsive_layout()

func _update_responsive_layout(animate: bool = false) -> void:
	var vp = get_viewport()
	if not vp:
		return
	var vp_size = vp.get_visible_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		return
	var is_portrait: bool = vp_size.y > vp_size.x
	_apply_responsive_layout(is_portrait, animate)

func _apply_responsive_layout(is_portrait: bool, animate: bool = false) -> void:
	if not is_instance_valid(main_layout):
		main_layout = %MainLayout if has_node("%MainLayout") else find_child("MainLayout", true, false)
	if not is_instance_valid(left_column):
		left_column = %LeftColumn if has_node("%LeftColumn") else find_child("LeftColumn", true, false)
	if not is_instance_valid(right_column):
		right_column = %RightColumn if has_node("%RightColumn") else find_child("RightColumn", true, false)

	if not is_instance_valid(main_layout):
		return

	var safe_top: float = 0.0
	if has_node("/root/ScreenManager"):
		safe_top = get_node("/root/ScreenManager").get_safe_top_margin()
	main_layout.offset_top = safe_top + 10.0

	var is_swapped: bool = false
	var is_mob: bool = false
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if "is_board_swapped" in sm:
			is_swapped = sm.is_board_swapped
		if sm.has_method("is_mobile"):
			is_mob = sm.is_mobile()

	# Reordenar según swap
	if is_instance_valid(left_column) and is_instance_valid(right_column):
		var target_left_idx = 1 if is_swapped else 0
		if left_column.get_index() != target_left_idx:
			if animate and is_inside_tree() and left_column.is_visible_in_tree():
				_animate_swap_slide(left_column, right_column, target_left_idx)
			else:
				main_layout.move_child(left_column, target_left_idx)

	if is_portrait:
		main_layout.vertical = true
		main_layout.add_theme_constant_override("separation", 10)

		if is_instance_valid(btn_back_to_map):
			btn_back_to_map.text = "⬅️ Volver"
			btn_back_to_map.custom_minimum_size = Vector2(116, 48)
		if is_instance_valid(lbl_grade_title):
			lbl_grade_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if is_instance_valid(lbl_lesson_title):
			lbl_lesson_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		if is_instance_valid(left_column):
			left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
			left_column.size_flags_stretch_ratio = 1.0
			var vp = get_viewport()
			if vp:
				var vp_size = vp.get_visible_rect().size
				var max_board_dim = minf(vp_size.x - 24.0, vp_size.y * (0.44 if is_mob else 0.46))
				if max_board_dim > 100.0:
					var cont_tablero = find_child("ContenedorTablero", true, false) as Control
					if cont_tablero:
						cont_tablero.custom_minimum_size = Vector2(0, max_board_dim)

		if is_instance_valid(right_column):
			right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
			right_column.size_flags_stretch_ratio = 1.0
			right_column.custom_minimum_size = Vector2(0, 0)
	else:
		main_layout.vertical = false
		main_layout.add_theme_constant_override("separation", 20)

		if is_instance_valid(btn_back_to_map):
			btn_back_to_map.text = "⬅️ Volver a Grados"
			btn_back_to_map.custom_minimum_size = Vector2(165, 48)

		if is_instance_valid(left_column):
			left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
			left_column.size_flags_stretch_ratio = 1.15
			var cont_tablero = find_child("ContenedorTablero", true, false) as Control
			if cont_tablero:
				cont_tablero.custom_minimum_size = Vector2(0, 0)

		if is_instance_valid(right_column):
			right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
			right_column.size_flags_stretch_ratio = 0.85
			var panel_w = 520.0 if is_mob else 480.0
			right_column.custom_minimum_size = Vector2(panel_w, 0)

	_apply_mobile_scaling(is_mob)

	if is_instance_valid(board) and board.has_method("_update_board_layout"):
		board.call_deferred("_update_board_layout")

func _apply_mobile_scaling(is_mob: bool) -> void:
	if is_instance_valid(lbl_dialogue):
		lbl_dialogue.add_theme_font_size_override("normal_font_size", 18 if is_mob else 16)
	if is_instance_valid(lbl_objective):
		lbl_objective.add_theme_font_size_override("font_size", 17 if is_mob else 15)
	if is_instance_valid(lbl_feedback):
		lbl_feedback.add_theme_font_size_override("font_size", 16 if is_mob else 14)

	var act_btns = [btn_hint, btn_reset, btn_rewind]
	var act_h = 54.0 if is_mob else 48.0
	var act_font = 16 if is_mob else 14
	for b in act_btns:
		if is_instance_valid(b):
			b.custom_minimum_size.y = act_h
			b.add_theme_font_size_override("font_size", act_font)

	if is_instance_valid(btn_next_lesson):
		btn_next_lesson.custom_minimum_size.y = 60.0 if is_mob else 54.0
		btn_next_lesson.add_theme_font_size_override("font_size", 19 if is_mob else 17)

	if is_instance_valid(btn_back_to_map):
		btn_back_to_map.custom_minimum_size = Vector2(170 if is_mob else 160, 52.0 if is_mob else 46.0)
		btn_back_to_map.add_theme_font_size_override("font_size", 16 if is_mob else 14)

	if is_instance_valid(lbl_grade_title):
		lbl_grade_title.add_theme_font_size_override("font_size", 19 if is_mob else 17)
	if is_instance_valid(lbl_lesson_title):
		lbl_lesson_title.add_theme_font_size_override("font_size", 14 if is_mob else 13)

	for star_lbl in [lbl_star_1, lbl_star_2, lbl_star_3]:
		if is_instance_valid(star_lbl):
			star_lbl.add_theme_font_size_override("font_size", 24 if is_mob else 20)

	if is_instance_valid(btn_swap_layout_aula):
		btn_swap_layout_aula.custom_minimum_size = Vector2(50, 50) if is_mob else Vector2(44, 44)
		btn_swap_layout_aula.add_theme_font_size_override("font_size", 22 if is_mob else 18)

func _animate_swap_slide(node_a: Control, node_b: Control, target_idx_a: int) -> void:
	if _swap_tween and _swap_tween.is_valid():
		_swap_tween.kill()
		node_a.scale = Vector2.ONE
		node_b.scale = Vector2.ONE
		node_a.z_index = 0
		node_b.z_index = 0
		node_a.modulate = Color.WHITE
		node_b.modulate = Color.WHITE

	var start_pos_a = node_a.global_position
	var start_pos_b = node_b.global_position

	main_layout.move_child(node_a, target_idx_a)
	await get_tree().process_frame

	if not is_instance_valid(node_a) or not is_instance_valid(node_b):
		return

	var target_pos_a = node_a.global_position
	var target_pos_b = node_b.global_position

	node_a.global_position = start_pos_a
	node_b.global_position = start_pos_b

	# Elevación visual del tablero para que se deslice limpiamente por encima del panel
	node_a.z_index = 2
	node_b.z_index = 1

	node_a.pivot_offset = node_a.size * 0.5
	node_b.pivot_offset = node_b.size * 0.5
	node_a.scale = Vector2(0.95, 0.95)
	node_b.scale = Vector2(0.95, 0.95)
	node_b.modulate.a = 0.85

	_swap_tween = create_tween()
	_swap_tween.set_parallel(true)
	_swap_tween.tween_property(node_a, "global_position", target_pos_a, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_swap_tween.tween_property(node_b, "global_position", target_pos_b, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_swap_tween.tween_property(node_a, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_swap_tween.tween_property(node_b, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_swap_tween.tween_property(node_b, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_swap_tween.finished.connect(func():
		if is_instance_valid(node_a):
			node_a.z_index = 0
			node_a.scale = Vector2.ONE
			node_a.modulate = Color.WHITE
		if is_instance_valid(node_b):
			node_b.z_index = 0
			node_b.scale = Vector2.ONE
			node_b.modulate = Color.WHITE
	)

# =========================================================================
# CARGA Y CONFIGURACIÓN DE LA LECCIÓN / ETAPA / EJERCICIO
# =========================================================================

func _load_current_lesson() -> void:
	var am = _get_am()
	if not am:
		return
	
	hints_used = 0
	mistake_count = 0
	is_lesson_finished = false
	is_stage_finished = false
	is_awaiting_rewind = false
	_update_stars_display(0)
	
	if am.current_mode == "practice":
		current_pack = am.get_practice_pack(am.current_pack_id)
		current_lesson = am.get_practice_exercise(am.current_pack_id, am.current_exercise_idx)
		if current_lesson.is_empty():
			push_error("[AulaAcademia] No se encontró el ejercicio en pack %s, idx %d" % [am.current_pack_id, am.current_exercise_idx])
			return
		current_stages = [current_lesson]
		current_stage_idx = 0
		if btn_back_to_map:
			btn_back_to_map.text = "⬅ Volver al Gimnasio"
	else:
		current_grade = am.get_grade(am.current_grade_num)
		current_lesson = am.get_lesson(am.current_grade_num, am.current_lesson_idx)
		if current_lesson.is_empty():
			push_error("[AulaAcademia] No se encontró la lección en grado %d, idx %d" % [am.current_grade_num, am.current_lesson_idx])
			return
		current_stages = current_lesson.get("stages", [])
		if current_stages.is_empty():
			current_stages = [current_lesson]
		current_stage_idx = 0
		if btn_back_to_map:
			btn_back_to_map.text = "⬅ Volver a Grados"
	
	_load_stage(0)

func _load_stage(stage_idx: int) -> void:
	var am = _get_am()
	current_stage_idx = clampi(stage_idx, 0, current_stages.size() - 1)
	active_board_data = current_stages[current_stage_idx]
	starting_fen = active_board_data.get("fen", "")
	
	is_stage_finished = false
	is_awaiting_rewind = false
	is_in_continuation = false
	is_playing_opponent_continuation = false
	is_restoring_checkpoint = false
	_lesson_token += 1
	
	# Actualizar títulos
	if am and am.current_mode == "practice":
		var p_icon = current_pack.get("icon", "🏋️")
		var p_name = current_pack.get("name", "Gimnasio")
		var ex_total = current_pack.get("exercises", []).size()
		lbl_grade_title.text = "%s %s  ·  Ejercicio %d de %d" % [p_icon, p_name, am.current_exercise_idx + 1, ex_total]
		lbl_lesson_title.text = current_lesson.get("title", "")
	else:
		var g_icon = current_grade.get("badge_icon", "🎓")
		var g_name = current_grade.get("name", "")
		var g_num = am.current_grade_num if am else 1
		lbl_grade_title.text = "%s Grado %d: %s  ·  Etapa %d de %d" % [g_icon, g_num, g_name, current_stage_idx + 1, current_stages.size()]
		var st_title = active_board_data.get("stage_title", "")
		if not st_title.is_empty():
			lbl_lesson_title.text = "%s — %s" % [current_lesson.get("title", ""), st_title]
		else:
			lbl_lesson_title.text = current_lesson.get("title", "")
	
	lbl_objective.text = "🎯 OBJETIVO: " + active_board_data.get("objective", "")
	
	feedback_panel.visible = false
	btn_rewind.visible = false
	btn_next_lesson.visible = false
	btn_hint.visible = true
	btn_reset.visible = true
	
	var player_col = active_board_data.get("player_color", "w")
	board.set_player_color(player_col)
	board.set_flipped(player_col == "b")
	board.set_interactive(true)
	board.set_fen(starting_fen)
	board.update_check_highlight()
	
	_show_pollito_intro()

func _show_pollito_intro() -> void:
	if pollito_avatar:
		pollito_avatar.set_expression("explicando", false)
	var am = _get_am()
	var dialogues: Array = active_board_data.get("intro_dialogue", [])
	if dialogues.is_empty():
		lbl_dialogue.text = "¡Hola! ¡Resolvamos juntos este desafío de ajedrez!"
		_speak("¡Hola! ¡Resolvamos juntos este desafío de ajedrez!")
		return
	
	var full_text = ""
	for d in dialogues:
		var line = am.adapt_text(str(d)) if am else str(d)
		full_text += line + "\n\n"
	
	var clean_text: String = full_text.strip_edges()
	lbl_dialogue.text = clean_text
	_speak(clean_text)

# =========================================================================
# LÓGICA DE MOVIMIENTOS, CONTINUACIONES Y REFUTACIÓN ACTIVA
# =========================================================================

func _on_player_move_completed(from_sq: String, to_sq: String) -> void:
	if is_restoring_checkpoint:
		return
	if is_playing_opponent_continuation:
		is_playing_opponent_continuation = false
		board.update_check_highlight()
		board.set_interactive(true)
		return
	if is_lesson_finished or is_stage_finished or is_awaiting_rewind:
		return
	
	var move_str = from_sq + to_sq
	var cont: Dictionary = active_board_data.get("continuation", {})
	var winning_moves: Array = cont.get("winning_moves", []) if is_in_continuation else active_board_data.get("winning_moves", [])
	
	var is_winning = false
	var wrong_promo = false
	var actual_piece = board.get_piece_at(to_sq).to_lower() if board else "q"
	
	for wm in winning_moves:
		var clean_wm = str(wm).strip_edges().to_lower()
		if clean_wm == move_str:
			is_winning = true
			break
		elif clean_wm.length() == 5 and clean_wm.begins_with(move_str):
			var expected_promo = clean_wm.substr(4, 1)
			if actual_piece == expected_promo:
				is_winning = true
			else:
				wrong_promo = true
			break
	
	if is_winning:
		if not is_in_continuation and not cont.is_empty():
			_start_continuation_sequence(from_sq, to_sq, actual_piece, cont)
		else:
			_handle_stage_or_lesson_success()
	elif wrong_promo:
		_handle_player_mistake(move_str, "¡Coronaste el peón, pero elegiste una pieza menor! Elige a la **Dama (Reina)** 👑 para obtener el máximo poder (9 puntos). ¡Usa ⏪ Rebobinar!")
	else:
		_handle_player_mistake(move_str)

func _start_continuation_sequence(p1_from: String, p1_to: String, p1_promo: String, cont: Dictionary) -> void:
	is_in_continuation = true
	is_playing_opponent_continuation = true
	cont_p1_from = p1_from
	cont_p1_to = p1_to
	cont_p1_promo = p1_promo if not p1_promo.is_empty() else "q"
	
	var opp_move: String = cont.get("opponent_move", "")
	cont_opp_from = opp_move.substr(0, 2)
	cont_opp_to = opp_move.substr(2, 2)
	
	board.set_interactive(false)
	if pollito_avatar:
		pollito_avatar.set_expression("animando")
	
	var am = _get_am()
	var prompt_raw: String = cont.get("prompt", "¡Excelente primera jugada! Ahora remata la combinación.")
	var adapted_prompt = am.adapt_text(prompt_raw) if am else prompt_raw
	lbl_dialogue.text = "⚡ ¡BIEN JUGADO!\n\n" + adapted_prompt
	lbl_objective.text = "🎯 PASO 2: " + adapted_prompt
	_speak("¡Bien jugado! " + adapted_prompt)
	
	var token = _lesson_token
	if instant_test_mode:
		board.make_move(cont_opp_from, cont_opp_to, false, true)
	else:
		get_tree().create_timer(0.35).timeout.connect(func():
			if is_instance_valid(board) and is_playing_opponent_continuation and token == _lesson_token:
				board.make_move(cont_opp_from, cont_opp_to, true, true)
		)

func _handle_stage_or_lesson_success() -> void:
	is_stage_finished = true
	board.set_interactive(false)
	if pollito_avatar:
		pollito_avatar.set_expression("celebrando")
	
	if audio_player:
		audio_player.stream = SFX_VICTORY
		audio_player.play()
	
	var am = _get_am()
	var win_exp = active_board_data.get("explanation_win", current_lesson.get("explanation_win", "¡Brillante trabajo táctico!"))
	var adapted_win = am.adapt_text(win_exp) if am else win_exp
	
	# ¿Quedan más etapas dentro de esta lección?
	if current_stage_idx + 1 < current_stages.size():
		lbl_dialogue.text = "🎉 ¡ETAPA %d DE %d SUPERADA! 🎉\n\n%s\n\n¡Prepárate para la siguiente etapa de esta lección!" % [current_stage_idx + 1, current_stages.size(), adapted_win]
		btn_next_lesson.text = "Siguiente Etapa (%d/%d) ➡️" % [current_stage_idx + 2, current_stages.size()]
		btn_next_lesson.visible = true
		btn_hint.visible = false
		feedback_panel.visible = false
		_speak("¡Etapa superada! " + adapted_win)
		return
	
	# Lección completa o ejercicio de práctica completado
	is_lesson_finished = true
	var stars = 3
	if hints_used > 0 or mistake_count > 0:
		stars = 2
	if hints_used >= 2 or mistake_count >= 2:
		stars = 1
	
	_update_stars_display(stars)
	
	var emeralds = current_lesson.get("emeralds", 30)
	lbl_dialogue.text = "🎉 ¡EXCELENTE! 🎉\n\n" + adapted_win + "\n\n⭐ Ganaste " + str(stars) + " Estrellas y " + str(emeralds) + " Esmeraldas 💎"
	_speak("¡Excelente! " + adapted_win)
	
	if am:
		am.complete_lesson(current_lesson.get("id", ""), stars, emeralds)
		if am.current_mode == "practice":
			btn_next_lesson.text = "Siguiente Ejercicio ➡️"
		else:
			btn_next_lesson.text = "Siguiente Lección ➡️"
	
	btn_next_lesson.visible = true
	btn_hint.visible = false
	feedback_panel.visible = false

func _handle_player_mistake(move_str: String, custom_explanation: String = "") -> void:
	mistake_count += 1
	is_awaiting_rewind = true
	var token = _lesson_token
	if pollito_avatar:
		pollito_avatar.set_expression("pensando")
	
	var am = _get_am()
	var refutations: Dictionary = active_board_data.get("active_refutations", {}) if not is_in_continuation else {}
	var ref_info = refutations.get(move_str, {})
	
	var opp_move = ""
	var explanation = custom_explanation if not custom_explanation.is_empty() else "¡Esa jugada no cumple el objetivo! Observa las pistas del Profe Pollito y usa ⏪ Rebobinar."
	
	if custom_explanation.is_empty() and not ref_info.is_empty():
		opp_move = ref_info.get("opponent_move", "")
		var exp_raw = ref_info.get("pollito_explanation", "")
		if not exp_raw.is_empty():
			explanation = am.adapt_text(exp_raw) if am else exp_raw
	
	if opp_move.length() >= 4:
		var opp_from = opp_move.substr(0, 2)
		var opp_to = opp_move.substr(2, 2)
		if instant_test_mode:
			board.make_move(opp_from, opp_to, false, true)
		else:
			get_tree().create_timer(0.3).timeout.connect(func():
				if is_instance_valid(board) and is_awaiting_rewind and token == _lesson_token:
					board.make_move(opp_from, opp_to, true, true)
			)
	
	board.set_interactive(false)
	feedback_panel.visible = true
	lbl_feedback.text = "⚠️ " + explanation
	btn_rewind.visible = true
	_speak(explanation)

# =========================================================================
# BOTONES DE ACCIÓN (REBOBINAR, PISTA, REINICIAR, SIGUIENTE)
# =========================================================================

func _restore_board_to_active_checkpoint() -> void:
	is_restoring_checkpoint = true
	board.set_fen(starting_fen)
	if is_in_continuation and cont_p1_from.length() == 2 and cont_opp_from.length() == 2:
		board.make_move(cont_p1_from, cont_p1_to, false, true, cont_p1_promo)
		board.make_move(cont_opp_from, cont_opp_to, false, true)
	is_restoring_checkpoint = false
	board.update_check_highlight()
	board.set_interactive(true)

func _on_rewind_pressed() -> void:
	if audio_player:
		audio_player.stream = SFX_CLICK
		audio_player.play()
	
	_lesson_token += 1
	is_awaiting_rewind = false
	_restore_board_to_active_checkpoint()
	feedback_panel.visible = false
	btn_rewind.visible = false
	if pollito_avatar:
		pollito_avatar.set_expression("animando")
	lbl_dialogue.text = "¡Tiempo rebobinado! ⏪\n\nRespira hondo y busca la jugada que cumple el objetivo del Profe Pollito."
	_speak("¡Tiempo rebobinado! Respira hondo y busca la jugada que cumple el objetivo.")

func _on_hint_pressed() -> void:
	if is_lesson_finished or is_stage_finished:
		return
	if audio_player:
		audio_player.stream = SFX_CLICK
		audio_player.play()
	
	hints_used += 1
	if pollito_avatar:
		pollito_avatar.set_expression("pensando")
	var cont: Dictionary = active_board_data.get("continuation", {})
	var hints: Array = cont.get("hints", []) if is_in_continuation else active_board_data.get("hints", [])
	if hints.is_empty():
		lbl_dialogue.text = "💡 Pista: Revisa todas las piezas que están indefensas en el tablero."
		_speak("Pista: Revisa todas las piezas que están indefensas en el tablero.")
		return
	
	var hint_idx = mini(hints_used - 1, hints.size() - 1)
	var am = _get_am()
	var hint_text = am.adapt_text(str(hints[hint_idx])) if am else str(hints[hint_idx])
	lbl_dialogue.text = "💡 Pista del Profe Pollito (%d/%d):\n\n%s" % [hint_idx + 1, hints.size(), hint_text]
	_speak("Pista: " + hint_text)

func _on_reset_pressed() -> void:
	if audio_player:
		audio_player.stream = SFX_CLICK
		audio_player.play()
	_load_stage(current_stage_idx)

func _on_next_lesson_pressed() -> void:
	if audio_player:
		audio_player.stream = SFX_CLICK
		audio_player.play()
	
	# Si quedan etapas dentro de la lección actual, avanzar a la siguiente etapa
	if current_stage_idx + 1 < current_stages.size():
		_load_stage(current_stage_idx + 1)
		return
	
	var am = _get_am()
	if not am:
		_on_back_to_map_pressed()
		return
	
	if am.current_mode == "practice":
		var p = am.get_practice_pack(am.current_pack_id)
		var exs: Array = p.get("exercises", [])
		if am.current_exercise_idx + 1 < exs.size():
			am.current_exercise_idx += 1
			_load_current_lesson()
		else:
			_on_back_to_map_pressed()
	else:
		var g = am.get_grade(am.current_grade_num)
		var lessons: Array = g.get("lessons", [])
		if am.current_lesson_idx + 1 < lessons.size():
			am.current_lesson_idx += 1
			_load_current_lesson()
		else:
			_on_back_to_map_pressed()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_to_map_pressed()

func _on_back_to_map_pressed() -> void:
	var vm = _get_vm()
	if vm and vm.has_method("stop"):
		vm.stop()
	if audio_player:
		audio_player.stream = SFX_CLICK
		audio_player.play()
	get_tree().change_scene_to_file("res://scenes/AcademyMap.tscn")

# =========================================================================
# UTILIDADES Y DISPLAY
# =========================================================================

func _update_stars_display(stars: int) -> void:
	lbl_star_1.text = "⭐" if stars >= 1 else "☆"
	lbl_star_2.text = "⭐" if stars >= 2 else "☆"
	lbl_star_3.text = "⭐" if stars >= 3 else "☆"

func _get_am() -> Node:
	if is_inside_tree() and has_node("/root/AcademyManager"):
		return get_node("/root/AcademyManager")
	if AcademyManagerScript.instance:
		return AcademyManagerScript.instance
	return null
