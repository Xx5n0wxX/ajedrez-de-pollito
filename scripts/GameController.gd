class_name GameController

extends Control



## Controlador Principal del Aula de Ajedrez de Pollito

## Soporta Modo Partida Completa contra IA (Free Play) y Modo Lecciones.



@warning_ignore("shadowed_global_identifier")

const ChessBoard = preload("res://scripts/ChessBoard.gd")

@warning_ignore("shadowed_global_identifier")

const ChessRules = preload("res://scripts/ChessRules.gd")

@warning_ignore("shadowed_global_identifier")

const ChessBot = preload("res://scripts/ChessBot.gd")

@warning_ignore("shadowed_global_identifier")

const ChessClock = preload("res://scripts/ChessClock.gd")

@warning_ignore("shadowed_global_identifier")

const PollitoAvatar = preload("res://scripts/PollitoAvatar.gd")

const ProfileManagerScript = preload("res://scripts/ProfileManager.gd")

const ChessTutorConcepts = preload("res://scripts/ChessTutorConcepts.gd")

const ChessSparringEngine = preload("res://scripts/ChessSparringEngine.gd")
const MatchEndEffectsOverlay = preload("res://scripts/MatchEndEffectsOverlay.gd")
const CHERRY_FONT: FontFile = preload("res://assets/fonts/CherryBombOne-Regular.ttf")



@export var game_mode: String = "free_play"

@export var current_lesson_id: String = "b1_l1"



# Referencias seguras mediante Scene Unique Nodes (%)

@onready var chess_board: ChessBoard = (%ChessBoard as ChessBoard) if has_node("%ChessBoard") else (find_child("ChessBoard", true, false) as ChessBoard)
# Layout Responsivo (Modo Vertical / Horizontal)
@onready var main_layout: BoxContainer = %MainLayout if has_node("%MainLayout") else find_child("MainLayout", true, false)
@onready var left_column: Control = %LeftColumn if has_node("%LeftColumn") else find_child("LeftColumn", true, false)
@onready var right_column: Control = %RightColumn if has_node("%RightColumn") else find_child("RightColumn", true, false)


@onready var avatar_rect: PollitoAvatar = (%AvatarRect as PollitoAvatar) if has_node("%AvatarRect") else (find_child("AvatarRect", true, false) as PollitoAvatar)

@onready var lesson_badge: Label = %LessonBadge if has_node("%LessonBadge") else find_child("LessonBadge", true, false)

@onready var lesson_title: Label = %LessonTitle if has_node("%LessonTitle") else find_child("LessonTitle", true, false)

@onready var lesson_subtitle: Label = %LessonSubtitle if has_node("%LessonSubtitle") else find_child("LessonSubtitle", true, false)

@onready var dialogue_text: RichTextLabel = %DialogueText if has_node("%DialogueText") else find_child("DialogueText", true, false)

@onready var instruction_label: Label = %InstructionLabel if has_node("%InstructionLabel") else find_child("InstructionLabel", true, false)

@onready var progress_bar: ProgressBar = %ProgressBar if has_node("%ProgressBar") else find_child("ProgressBar", true, false)

@onready var progress_label: Label = %ProgressLabel if has_node("%ProgressLabel") else find_child("ProgressLabel", true, false)

@onready var match_stats_section: Control = %MatchStatsSection if has_node("%MatchStatsSection") else find_child("MatchStatsSection", true, false)

@onready var match_timer_label: Label = %MatchTimerLabel if has_node("%MatchTimerLabel") else find_child("MatchTimerLabel", true, false)

@onready var advantage_label: Label = %AdvantageLabel if has_node("%AdvantageLabel") else find_child("AdvantageLabel", true, false)

@onready var white_captured_text: RichTextLabel = %WhiteCapturedText if has_node("%WhiteCapturedText") else find_child("WhiteCapturedText", true, false)

@onready var white_score_label: Label = %WhiteScoreLabel if has_node("%WhiteScoreLabel") else find_child("WhiteScoreLabel", true, false)

@onready var black_captured_text: RichTextLabel = %BlackCapturedText if has_node("%BlackCapturedText") else find_child("BlackCapturedText", true, false)

@onready var black_score_label: Label = %BlackScoreLabel if has_node("%BlackScoreLabel") else find_child("BlackScoreLabel", true, false)



# Cronómetro de duración total de la partida

var match_duration_seconds: float = 0.0

var is_match_timer_active: bool = false

@onready var continue_button: Button = %ContinueButton if has_node("%ContinueButton") else find_child("ContinueButton", true, false)

@onready var mute_button: Button = %MuteButton if has_node("%MuteButton") else find_child("MuteButton", true, false)
@onready var btn_swap_layout: Button = %BtnSwapLayout if has_node("%BtnSwapLayout") else find_child("BtnSwapLayout", true, false)
@onready var btn_pause_menu: Button = %BtnPauseMenu if has_node("%BtnPauseMenu") else find_child("BtnPauseMenu", true, false)

@onready var replay_voice_btn: Button = mute_button






# Reloj de Ajedrez opcional

var chess_clock: ChessClock = ChessClock.new()

@onready var clock_section: VBoxContainer = %ClockSection if has_node("%ClockSection") else find_child("ClockSection", true, false)

@onready var clock_toggle: CheckButton = %ClockToggle if has_node("%ClockToggle") else find_child("ClockToggle", true, false)
@onready var clock_time_option: OptionButton = %ClockTimeOption if has_node("%ClockTimeOption") else find_child("ClockTimeOption", true, false)
var selected_clock_duration: float = 300.0 # 5 min por defecto

const CLOCK_TIME_PRESETS = [
	{"label": "1 min", "seconds": 60.0},
	{"label": "2 min", "seconds": 120.0},
	{"label": "3 min", "seconds": 180.0},
	{"label": "5 min", "seconds": 300.0},
	{"label": "10 min", "seconds": 600.0},
	{"label": "15 min", "seconds": 900.0},
	{"label": "20 min", "seconds": 1200.0},
	{"label": "30 min", "seconds": 1800.0}
]

@onready var white_clock_panel: PanelContainer = %WhiteClockPanel if has_node("%WhiteClockPanel") else find_child("WhiteClockPanel", true, false)

@onready var black_clock_panel: PanelContainer = %BlackClockPanel if has_node("%BlackClockPanel") else find_child("BlackClockPanel", true, false)

@onready var white_time_label: Label = %WhiteTimeLabel if has_node("%WhiteTimeLabel") else find_child("WhiteTimeLabel", true, false)

@onready var black_time_label: Label = %BlackTimeLabel if has_node("%BlackTimeLabel") else find_child("BlackTimeLabel", true, false)



# Menú de Pausa (Tecla Escape)

@onready var pause_menu_overlay: Control = %PauseMenuOverlay if has_node("%PauseMenuOverlay") else find_child("PauseMenuOverlay", true, false)

@onready var resume_button: Button = %ResumeButton if has_node("%ResumeButton") else find_child("ResumeButton", true, false)

@onready var back_to_menu_button: Button = %BackToMenuButton if has_node("%BackToMenuButton") else find_child("BackToMenuButton", true, false)

var is_game_paused: bool = false



var style_clock_active: StyleBoxFlat

var style_clock_inactive: StyleBoxFlat

var style_clock_waiting_press: StyleBoxFlat

var is_waiting_for_clock_press: bool = false

var _pending_bot_move_info: Dictionary = {}

var _pending_bot_game_state: String = ""

var _clock_pulse_tween: Tween

var white_player_label: Label = null

var black_player_label: Label = null



# Control de Partida, Diálogos y Seguros

var is_match_started: bool = false

var is_player_turn: bool = true

var current_turn_number: int = 1

@onready var diff_button: Button = %DifficultyButton if has_node("%DifficultyButton") else find_child("DifficultyButton", true, false)
const DifficultyModalScene = preload("res://scenes/DifficultyModal.tscn")
var difficulty_modal: CanvasLayer = null

@onready var undo_button: Button = %UndoButton if has_node("%UndoButton") else find_child("UndoButton", true, false)

@onready var new_game_button: Button = %NewGameButton if has_node("%NewGameButton") else find_child("NewGameButton", true, false)

@onready var resign_button: Button = %ResignButton if has_node("%ResignButton") else find_child("ResignButton", true, false)

var match_buttons_row: HBoxContainer = null



# Popup de confirmación estilizado (Mismo estilo visual que Menú de Pausa)

@onready var confirm_modal_overlay: Control = %ConfirmModalOverlay if has_node("%ConfirmModalOverlay") else find_child("ConfirmModalOverlay", true, false)

@onready var confirm_header: Label = %ConfirmHeader if has_node("%ConfirmHeader") else find_child("ConfirmHeader", true, false)

@onready var confirm_subtitle: Label = %ConfirmSubtitle if has_node("%ConfirmSubtitle") else find_child("ConfirmSubtitle", true, false)

@onready var confirm_action_button: Button = %ConfirmActionButton if has_node("%ConfirmActionButton") else find_child("ConfirmActionButton", true, false)

@onready var confirm_cancel_button: Button = %ConfirmCancelButton if has_node("%ConfirmCancelButton") else find_child("ConfirmCancelButton", true, false)

var _pending_confirm_callback: Callable = Callable()

var _pending_cancel_callback: Callable = Callable()

@onready var hint_button: Button = %HintButton if has_node("%HintButton") else find_child("HintButton", true, false)



# Controles de Repaso / Reproducción de partida terminada

@onready var replay_controls_bar: HBoxContainer = %ReplayControlsBar if has_node("%ReplayControlsBar") else find_child("ReplayControlsBar", true, false)

@onready var replay_first_btn: Button = %ReplayFirstBtn if has_node("%ReplayFirstBtn") else find_child("ReplayFirstBtn", true, false)

@onready var replay_prev_btn: Button = %ReplayPrevBtn if has_node("%ReplayPrevBtn") else find_child("ReplayPrevBtn", true, false)

@onready var replay_play_btn: Button = %ReplayPlayBtn if has_node("%ReplayPlayBtn") else find_child("ReplayPlayBtn", true, false)

@onready var replay_next_btn: Button = %ReplayNextBtn if has_node("%ReplayNextBtn") else find_child("ReplayNextBtn", true, false)

@onready var replay_last_btn: Button = %ReplayLastBtn if has_node("%ReplayLastBtn") else find_child("ReplayLastBtn", true, false)

@onready var history_review_hint: Label = %HistoryReviewHint if has_node("%HistoryReviewHint") else find_child("HistoryReviewHint", true, false)

@onready var history_title: Label = %HistoryTitle if has_node("%HistoryTitle") else find_child("HistoryTitle", true, false)
@onready var bottom_split_hbox: HBoxContainer = %BottomSplitHBox if has_node("%BottomSplitHBox") else find_child("BottomSplitHBox", true, false)
@onready var btn_review_match: Button = %BtnReviewMatch if has_node("%BtnReviewMatch") else find_child("BtnReviewMatch", true, false)
@onready var btn_exit_review: Button = %BtnExitReview if has_node("%BtnExitReview") else find_child("BtnExitReview", true, false)



var match_history_fens: Array[String] = []

var is_in_review_mode: bool = false

var is_current_match_saved: bool = false

var review_move_index: int = 0

var is_review_autoplay_active: bool = false

var review_autoplay_timer: float = 0.0

const REVIEW_AUTOPLAY_INTERVAL: float = 0.85



# Historial de jugadas con notación algebraica

@onready var move_history_section: PanelContainer = %MoveHistorySection if has_node("%MoveHistorySection") else find_child("MoveHistorySection", true, false)

@onready var move_history_label: RichTextLabel = %MoveHistoryText if has_node("%MoveHistoryText") else find_child("MoveHistoryText", true, false)

@onready var move_history_scroll: ScrollContainer = %MoveHistoryScroll if has_node("%MoveHistoryScroll") else find_child("MoveHistoryScroll", true, false)

var history_label: RichTextLabel:

	get:

		return move_history_label

	set(val):

		move_history_label = val

var move_history: Array[String] = []



# Referencia directa al motor de reglas

var chess_rules: ChessRules:

	get:

		if chess_board and chess_board.rules:

			return chess_board.rules

		return null



# Motor de IA para partida contra bot

var bot: ChessBot = ChessBot.new()

var bot_difficulty: int = 1 # 1: Fácil, 2: Medio, 3: Difícil

var is_bot_thinking: bool = false

var _bot_think_generation: int = 0

var last_speech_text: String = ""

var current_match_opening: String = ""

var current_sparring_session: Dictionary = {}
var match_effects_overlay: MatchEndEffectsOverlay = null



# Estructura de datos (Modo Lecciones)

var all_lessons_data: Dictionary = {}

var current_lesson: Dictionary = {}

var current_stages: Array = []

var current_stage_index: int = 0

var stage_completed: bool = false



func _ready() -> void:

	_resolve_node_references()

	_setup_confirmation_dialogs()

	_setup_responsive_layout()

	match_effects_overlay = MatchEndEffectsOverlay.new()
	match_effects_overlay.name = "MatchEndEffectsOverlay"
	add_child(match_effects_overlay)



	if undo_button and not undo_button.pressed.is_connected(_on_undo_pressed):

		undo_button.pressed.connect(_on_undo_pressed)



	if game_mode == "free_play":

		if move_history_section:

			move_history_section.visible = true

		_init_free_play_mode()

	else:

		if move_history_section:

			move_history_section.visible = false

		if undo_button:

			undo_button.visible = false

		_load_lessons_json()

		_connect_signals()

		_load_lesson(current_lesson_id)



func _resolve_node_references() -> void:

	if not chess_board:

		var board_node = %ChessBoard if has_node("%ChessBoard") else find_child("ChessBoard", true, false)

		if board_node:

			if not board_node.get_script():

				board_node.set_script(load("res://scripts/ChessBoard.gd"))

			chess_board = board_node as ChessBoard

	if not avatar_rect:

		var av_node = %AvatarRect if has_node("%AvatarRect") else find_child("AvatarRect", true, false)

		if av_node:

			if not av_node.get_script():

				av_node.set_script(load("res://scripts/PollitoAvatar.gd"))

			avatar_rect = av_node as PollitoAvatar

	if not lesson_badge:

		lesson_badge = find_child("LessonBadge", true, false)

	if not lesson_title:

		lesson_title = find_child("LessonTitle", true, false)

	if not lesson_subtitle:

		lesson_subtitle = find_child("LessonSubtitle", true, false)

	if not dialogue_text:

		dialogue_text = find_child("DialogueText", true, false)

	if dialogue_text:

		dialogue_text.fit_content = false

		dialogue_text.custom_minimum_size = Vector2(0, 98)

		dialogue_text.scroll_active = true

		dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if not instruction_label:

		instruction_label = find_child("InstructionLabel", true, false)

	if not progress_bar:

		progress_bar = find_child("ProgressBar", true, false)

	if not progress_label:

		progress_label = find_child("ProgressLabel", true, false)

	if not match_stats_section:

		match_stats_section = find_child("MatchStatsSection", true, false)

	if not match_timer_label:

		match_timer_label = find_child("MatchTimerLabel", true, false)

	if not advantage_label:

		advantage_label = find_child("AdvantageLabel", true, false)

	if not white_captured_text:

		white_captured_text = find_child("WhiteCapturedText", true, false)

	if not white_score_label:

		white_score_label = find_child("WhiteScoreLabel", true, false)

	if not black_captured_text:

		black_captured_text = find_child("BlackCapturedText", true, false)

	if not black_score_label:

		black_score_label = find_child("BlackScoreLabel", true, false)

	if not continue_button:

		continue_button = find_child("ContinueButton", true, false)

	if not replay_voice_btn:

		replay_voice_btn = find_child("ReplayVoiceButton", true, false)


	if not clock_section:

		clock_section = find_child("ClockSection", true, false)

	if not clock_toggle:

		clock_toggle = find_child("ClockToggle", true, false)

	if not clock_time_option:
		clock_time_option = find_child("ClockTimeOption", true, false)

	if not white_clock_panel:

		white_clock_panel = find_child("WhiteClockPanel", true, false)

	if not black_clock_panel:

		black_clock_panel = find_child("BlackClockPanel", true, false)

	if not white_time_label:

		white_time_label = find_child("WhiteTimeLabel", true, false)

	if not black_time_label:

		black_time_label = find_child("BlackTimeLabel", true, false)

	if not white_player_label and white_clock_panel:

		white_player_label = white_clock_panel.find_child("WhitePlayerLabel", true, false)

	if not black_player_label and black_clock_panel:

		black_player_label = black_clock_panel.find_child("BlackPlayerLabel", true, false)

	if not move_history_section:

		move_history_section = find_child("MoveHistorySection", true, false)

	if not move_history_label:

		move_history_label = find_child("MoveHistoryText", true, false)

	if not move_history_scroll:

		move_history_scroll = find_child("MoveHistoryScroll", true, false)

	if move_history_scroll:

		move_history_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

		move_history_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS

		var vsb = move_history_scroll.get_v_scroll_bar()

		if vsb:

			vsb.custom_minimum_size = Vector2(10, 0)

	if move_history_label:

		move_history_label.fit_content = true

		move_history_label.scroll_active = false

	if not mute_button:

		mute_button = find_child("MuteButton", true, false)

	if not hint_button:

		hint_button = find_child("HintButton", true, false)

	if not replay_voice_btn:

		replay_voice_btn = mute_button

	if not diff_button:

		diff_button = find_child("DifficultyButton", true, false)

	if not undo_button:

		undo_button = find_child("UndoButton", true, false)

	if not new_game_button:

		new_game_button = find_child("NewGameButton", true, false)

	if not resign_button:

		resign_button = find_child("ResignButton", true, false)

	if not replay_controls_bar:

		replay_controls_bar = find_child("ReplayControlsBar", true, false)

	if not replay_first_btn:

		replay_first_btn = find_child("ReplayFirstBtn", true, false)

	if not replay_prev_btn:

		replay_prev_btn = find_child("ReplayPrevBtn", true, false)

	if not replay_play_btn:

		replay_play_btn = find_child("ReplayPlayBtn", true, false)

	if not replay_next_btn:

		replay_next_btn = find_child("ReplayNextBtn", true, false)

	if not replay_last_btn:

		replay_last_btn = find_child("ReplayLastBtn", true, false)

	if not history_review_hint:

		history_review_hint = find_child("HistoryReviewHint", true, false)

	if not pause_menu_overlay:

		pause_menu_overlay = find_child("PauseMenuOverlay", true, false)

	if not resume_button:

		resume_button = find_child("ResumeButton", true, false)

	if not back_to_menu_button:

		back_to_menu_button = find_child("BackToMenuButton", true, false)

	if not confirm_modal_overlay:

		confirm_modal_overlay = find_child("ConfirmModalOverlay", true, false)

	if not confirm_header:

		confirm_header = find_child("ConfirmHeader", true, false)

	if not confirm_subtitle:

		confirm_subtitle = find_child("ConfirmSubtitle", true, false)

	if not confirm_action_button:

		confirm_action_button = find_child("ConfirmActionButton", true, false)

	if not confirm_cancel_button:

		confirm_cancel_button = find_child("ConfirmCancelButton", true, false)



	# =========================================================

	# ESTABILIZACIÓN ANTI-MOVIMIENTO Y DIMENSIONES FIJAS

	# =========================================================

	# Las dimensiones responsivas se configuran en _apply_responsive_layout()



	var header_node = find_child("Header", true, false)

	if header_node:

		header_node.custom_minimum_size = Vector2(0, 88)



	if lesson_badge:

		lesson_badge.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

		lesson_badge.clip_text = true

	if lesson_title:

		lesson_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

		lesson_title.clip_text = true

	if lesson_subtitle:

		lesson_subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

		lesson_subtitle.clip_text = true



	var bubble = find_child("DialogueBubble", true, false)

	if bubble:

		bubble.custom_minimum_size = Vector2(0, 156)



	if dialogue_text:

		dialogue_text.fit_content = false

		dialogue_text.custom_minimum_size = Vector2(0, 98)

		dialogue_text.scroll_active = true

		dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART



	if instruction_label:

		instruction_label.custom_minimum_size = Vector2(0, 20)

		instruction_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

		instruction_label.clip_text = true



	var controls_split = find_child("ControlsSplitRow", true, false)

	if controls_split:

		controls_split.custom_minimum_size = Vector2(0, 68)

	var actions_box = find_child("ActionButtonsContainer", true, false)

	if actions_box:

		actions_box.custom_minimum_size = Vector2(0, 68)

	if clock_section:

		clock_section.custom_minimum_size = Vector2(0, 68)



	var w_name_lbl = find_child("WhiteNameLabel", true, false)

	if w_name_lbl:

		w_name_lbl.text = "⚪ " + _get_player_name()



	var w_card = find_child("WhiteCard", true, false)

	if w_card:

		w_card.custom_minimum_size = Vector2(0, 48)

	var b_card = find_child("BlackCard", true, false)

	if b_card:

		b_card.custom_minimum_size = Vector2(0, 48)



	if white_captured_text:

		white_captured_text.custom_minimum_size = Vector2(0, 22)

		white_captured_text.fit_content = false

		white_captured_text.scroll_active = false

		white_captured_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if black_captured_text:

		black_captured_text.custom_minimum_size = Vector2(0, 22)

		black_captured_text.fit_content = false

		black_captured_text.scroll_active = false

		black_captured_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART



	if match_timer_label:

		match_timer_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

		match_timer_label.clip_text = true

	if advantage_label:

		advantage_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

		advantage_label.clip_text = true



func _exit_tree() -> void:
	var vm = _get_voice_manager()
	if vm and vm.has_method("stop"):
		vm.stop()
	if bot:
		bot.shutdown()



func set_dialogue(text: String) -> void:

	if not dialogue_text:

		dialogue_text = find_child("DialogueText", true, false)

	if dialogue_text:

		dialogue_text.text = _adapt_text(text)

		dialogue_text.scroll_to_line(0)

		var vsb = dialogue_text.get_v_scroll_bar()

		if vsb:

			vsb.value = 0.0



# =============================================================

# MODO PARTIDA COMPLETA VS IA (FREE PLAY)

# =============================================================



func _process(delta: float) -> void:

	if is_game_paused or (confirm_modal_overlay and confirm_modal_overlay.visible):

		return

	if game_mode == "free_play":

		if chess_clock and chess_clock.is_enabled and is_match_started:

			chess_clock.update(delta)

		if is_match_timer_active and not is_in_review_mode:

			match_duration_seconds += delta

			_update_match_timer_label()

		_update_undo_button_state()



		# Autoplay en modo repaso

		if is_in_review_mode and is_review_autoplay_active:

			review_autoplay_timer += delta

			if review_autoplay_timer >= REVIEW_AUTOPLAY_INTERVAL:

				review_autoplay_timer = 0.0

				if review_move_index < move_history.size():

					_jump_to_review_move(review_move_index + 1)

				else:

					_stop_review_autoplay()



func _update_match_timer_label() -> void:

	if not match_timer_label:

		match_timer_label = find_child("MatchTimerLabel", true, false)

	if match_timer_label:

		var total_sec: int = int(match_duration_seconds)

		var mins: int = total_sec / 60

		var secs: int = total_sec % 60

		if mins >= 60:

			var hrs: int = mins / 60

			mins = mins % 60

			match_timer_label.text = "⏱️ Tiempo: %02d:%02d:%02d" % [hrs, mins, secs]

		else:

			match_timer_label.text = "⏱️ Tiempo: %02d:%02d" % [mins, secs]



func _update_material_and_captures_ui() -> void:

	if not chess_board or not chess_board.rules:

		return



	var r = chess_board.rules

	var piece_values: Dictionary = {"p": 1, "n": 3, "b": 3, "r": 5, "q": 9}

	var start_counts: Dictionary = {"q": 1, "r": 2, "b": 2, "n": 2, "p": 8}



	var cur_w: Dictionary = {"q": 0, "r": 0, "b": 0, "n": 0, "p": 0}

	var cur_b: Dictionary = {"q": 0, "r": 0, "b": 0, "n": 0, "p": 0}

	var w_material: int = 0

	var b_material: int = 0



	for y in range(8):

		for x in range(8):

			var p = r.get_piece_at(Vector2i(x, y))

			if p != "" and p.to_lower() != "k":

				var pt = p.to_lower()

				var val = piece_values.get(pt, 0)

				if r.is_white_piece(p):

					cur_w[pt] = cur_w.get(pt, 0) + 1

					w_material += val

				else:

					cur_b[pt] = cur_b.get(pt, 0) + 1

					b_material += val



	# Piezas capturadas por las Blancas (piezas negras que faltan)

	var w_captured: Array = []

	var w_captured_pts: int = 0

	var b_extra_promoted: int = 0

	for pt in ["q", "r", "b", "n"]:

		var diff: int = start_counts[pt] - cur_b.get(pt, 0)

		if diff > 0:

			for i in range(diff):

				w_captured.append(pt)

				w_captured_pts += piece_values[pt]

		elif diff < 0:

			b_extra_promoted += abs(diff)



	var b_pawns_lost: int = start_counts["p"] - cur_b.get("p", 0) - b_extra_promoted

	if b_pawns_lost > 0:

		for i in range(b_pawns_lost):

			w_captured.append("p")

			w_captured_pts += piece_values["p"]



	# Piezas capturadas por las Negras (piezas blancas que faltan)

	var b_captured: Array = []

	var b_captured_pts: int = 0

	var w_extra_promoted: int = 0

	for pt in ["q", "r", "b", "n"]:

		var diff: int = start_counts[pt] - cur_w.get(pt, 0)

		if diff > 0:

			for i in range(diff):

				b_captured.append(pt)

				b_captured_pts += piece_values[pt]

		elif diff < 0:

			w_extra_promoted += abs(diff)



	var w_pawns_lost: int = start_counts["p"] - cur_w.get("p", 0) - w_extra_promoted

	if w_pawns_lost > 0:

		for i in range(w_pawns_lost):

			b_captured.append("p")

			b_captured_pts += piece_values["p"]



	# Actualizar Ventaja

	var advantage: int = w_material - b_material

	if not advantage_label:

		advantage_label = find_child("AdvantageLabel", true, false)

	if advantage_label:

		if advantage > 0:

			advantage_label.text = "✨ +%d %s" % [advantage, _get_player_name()]

			advantage_label.add_theme_color_override("font_color", Color("#db2777"))

		elif advantage < 0:

			advantage_label.text = "✨ +%d Profe" % abs(advantage)

			advantage_label.add_theme_color_override("font_color", Color("#4f46e5"))

		else:

			advantage_label.text = "⚖️ Igualado"

			advantage_label.add_theme_color_override("font_color", Color("#6b7280"))



	# Extensión de iconos según tema

	var ext: String = "svg"



	# Formatear capturas de Blancas (piezas negras capturadas)

	if not white_captured_text:

		white_captured_text = find_child("WhiteCapturedText", true, false)

	if white_captured_text:

		if w_captured.is_empty():

			white_captured_text.text = "[color=#9ca3af]Sin capturas[/color]"

		else:

			var bb_w = ""

			for pt in w_captured:

				bb_w += "[img=15x15]res://assets/pieces/b_%s.%s[/img] " % [pt, ext]

			white_captured_text.text = bb_w.strip_edges()



	if not white_score_label:

		white_score_label = find_child("WhiteScoreLabel", true, false)

	if white_score_label:

		var p_text = "pieza" if w_captured.size() == 1 else "piezas"

		white_score_label.text = "%d pts (%d %s)" % [w_captured_pts, w_captured.size(), p_text]



	# Formatear capturas de Negras (piezas blancas capturadas)

	if not black_captured_text:

		black_captured_text = find_child("BlackCapturedText", true, false)

	if black_captured_text:

		if b_captured.is_empty():

			black_captured_text.text = "[color=#9ca3af]Sin capturas[/color]"

		else:

			var bb_b = ""

			for pt in b_captured:

				bb_b += "[img=15x15]res://assets/pieces/w_%s.%s[/img] " % [pt, ext]

			black_captured_text.text = bb_b.strip_edges()



	if not black_score_label:

		black_score_label = find_child("BlackScoreLabel", true, false)

	if black_score_label:

		var p_text = "pieza" if b_captured.size() == 1 else "piezas"

		black_score_label.text = "%d pts (%d %s)" % [b_captured_pts, b_captured.size(), p_text]



func _init_free_play_mode() -> void:

	_setup_mute_button()

	_setup_hint_button()

	_setup_difficulty_button()

	_setup_match_control_buttons()

	_setup_review_controls()

	_setup_pause_menu()

	_setup_clock()



	if chess_board:

		chess_board.move_interceptor = _on_player_move_attempted

		if chess_board.has_signal("turn_completed") and not chess_board.turn_completed.is_connected(_on_free_play_turn_completed):

			chess_board.turn_completed.connect(_on_free_play_turn_completed)

		if chess_board.has_signal("move_failed") and not chess_board.move_failed.is_connected(_on_free_play_move_failed):

			chess_board.move_failed.connect(_on_free_play_move_failed)



	if continue_button and not continue_button.pressed.is_connected(_on_new_game_button_pressed):

		continue_button.pressed.connect(_on_new_game_button_pressed)



	if lesson_badge:

		lesson_badge.mouse_filter = Control.MOUSE_FILTER_STOP

		if not lesson_badge.gui_input.is_connected(_on_difficulty_badge_gui_input):

			lesson_badge.gui_input.connect(_on_difficulty_badge_gui_input)



	_connect_voice_manager()



	if _get_history_mgr() and not _get_history_mgr().active_review_match.is_empty():
		call_deferred("_load_and_review_saved_match", _get_history_mgr().active_review_match)
	else:
		call_deferred("start_new_free_play_game")



func _apply_uniform_modal_card_style(card: Control, border_col: Color = Color("#F472B6"), bg_col: Color = Color("#FFF9FB")) -> void:
	if not card:
		return
	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = bg_col
	card_sb.border_width_left = 5
	card_sb.border_width_top = 5
	card_sb.border_width_right = 5
	card_sb.border_width_bottom = 10
	card_sb.border_color = border_col
	card_sb.set_corner_radius_all(34)
	card_sb.content_margin_left = 28
	card_sb.content_margin_right = 28
	card_sb.content_margin_top = 24
	card_sb.content_margin_bottom = 28
	card_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	card_sb.shadow_size = 24
	card_sb.shadow_offset = Vector2(0, 10)
	card_sb.anti_aliasing = true
	card.add_theme_stylebox_override("panel", card_sb)

func _setup_confirmation_dialogs() -> void:
	if not confirm_modal_overlay:
		confirm_modal_overlay = %ConfirmModalOverlay if has_node("%ConfirmModalOverlay") else find_child("ConfirmModalOverlay", true, false)
	if not confirm_header:
		confirm_header = %ConfirmHeader if has_node("%ConfirmHeader") else find_child("ConfirmHeader", true, false)
	if not confirm_subtitle:
		confirm_subtitle = %ConfirmSubtitle if has_node("%ConfirmSubtitle") else find_child("ConfirmSubtitle", true, false)
	if not confirm_action_button:
		confirm_action_button = %ConfirmActionButton if has_node("%ConfirmActionButton") else find_child("ConfirmActionButton", true, false)
	if not confirm_cancel_button:
		confirm_cancel_button = %ConfirmCancelButton if has_node("%ConfirmCancelButton") else find_child("ConfirmCancelButton", true, false)

	if confirm_modal_overlay:
		confirm_modal_overlay.z_index = 1000
		confirm_modal_overlay.z_as_relative = false
		confirm_modal_overlay.visible = false
		if confirm_modal_overlay is ColorRect:
			(confirm_modal_overlay as ColorRect).color = Color(0.09, 0.04, 0.14, 0.72)
		if not confirm_modal_overlay.gui_input.is_connected(_on_confirm_overlay_gui_input):
			confirm_modal_overlay.gui_input.connect(_on_confirm_overlay_gui_input)

		var card = confirm_modal_overlay.find_child("ConfirmCard", true, false) as Control
		if card:
			_apply_uniform_modal_card_style(card)

	if confirm_header:
		confirm_header.add_theme_font_override("font", CHERRY_FONT)
		confirm_header.add_theme_font_size_override("font_size", 28)
		confirm_header.add_theme_color_override("font_color", Color("#BE185D"))
		confirm_header.add_theme_color_override("font_outline_color", Color.WHITE)
		confirm_header.add_theme_constant_override("outline_size", 8)
		confirm_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if confirm_subtitle:
		confirm_subtitle.add_theme_font_size_override("font_size", 15)
		confirm_subtitle.add_theme_color_override("font_color", Color("#701A75"))
		confirm_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if confirm_cancel_button:
		confirm_cancel_button.custom_minimum_size = Vector2(0, 48)
		var cancel_sb := StyleBoxFlat.new()
		cancel_sb.bg_color = Color("#F1F5F9")
		cancel_sb.border_width_bottom = 4
		cancel_sb.border_color = Color("#CBD5E1")
		cancel_sb.set_corner_radius_all(18)
		var cancel_hov := cancel_sb.duplicate()
		cancel_hov.bg_color = Color("#E2E8F0")
		confirm_cancel_button.add_theme_stylebox_override("normal", cancel_sb)
		confirm_cancel_button.add_theme_stylebox_override("hover", cancel_hov)
		confirm_cancel_button.add_theme_stylebox_override("pressed", cancel_sb)
		confirm_cancel_button.add_theme_color_override("font_color", Color("#475569"))
		confirm_cancel_button.add_theme_font_size_override("font_size", 16)

	if confirm_action_button and not confirm_action_button.pressed.is_connected(_on_confirm_action_pressed):
		confirm_action_button.pressed.connect(_on_confirm_action_pressed)
	if confirm_cancel_button and not confirm_cancel_button.pressed.is_connected(_on_confirm_cancel_pressed):
		confirm_cancel_button.pressed.connect(_on_confirm_cancel_pressed)

func _on_confirm_overlay_gui_input(ev: InputEvent) -> void:
	if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
		_on_confirm_cancel_pressed()

func _set_confirm_button_color(is_green: bool) -> void:
	if not confirm_action_button:
		return

	confirm_action_button.custom_minimum_size = Vector2(0, 52)
	confirm_action_button.add_theme_font_override("font", CHERRY_FONT)
	confirm_action_button.add_theme_font_size_override("font_size", 19)

	var norm := StyleBoxFlat.new()
	norm.set_corner_radius_all(18)
	norm.anti_aliasing = true

	if is_green:
		norm.bg_color = Color("#10B981")
		norm.border_width_bottom = 5
		norm.border_color = Color("#047857")
		var hov := norm.duplicate()
		hov.bg_color = Color("#34D399")
		confirm_action_button.add_theme_stylebox_override("normal", norm)
		confirm_action_button.add_theme_stylebox_override("hover", hov)
		confirm_action_button.add_theme_stylebox_override("pressed", norm)
		confirm_action_button.add_theme_color_override("font_color", Color.WHITE)
	else:
		norm.bg_color = Color("#F59E0B")
		norm.border_width_bottom = 5
		norm.border_color = Color("#D97706")
		var hov := norm.duplicate()
		hov.bg_color = Color("#FBBF24")
		confirm_action_button.add_theme_stylebox_override("normal", norm)
		confirm_action_button.add_theme_stylebox_override("hover", hov)
		confirm_action_button.add_theme_stylebox_override("pressed", norm)
		confirm_action_button.add_theme_color_override("font_color", Color.WHITE)



func _show_confirm_dialog(title: String, message: String, action_text: String, cancel_text: String, on_confirm: Callable, is_green: bool = false, on_cancel: Callable = Callable()) -> void:

	_pending_confirm_callback = on_confirm

	_pending_cancel_callback = on_cancel

	if confirm_header:

		confirm_header.text = _adapt_text(title)

	if confirm_subtitle:

		confirm_subtitle.text = _adapt_text(message)

	if confirm_action_button:

		confirm_action_button.text = _adapt_text(action_text)

		_set_confirm_button_color(is_green)

	if confirm_cancel_button:

		confirm_cancel_button.text = _adapt_text(cancel_text)

	if confirm_modal_overlay:
		confirm_modal_overlay.visible = true
		confirm_modal_overlay.move_to_front()
		var card = confirm_modal_overlay.find_child("ConfirmCard", true, false) as Control
		if card:
			card.pivot_offset = card.size * 0.5
			card.scale = Vector2(0.85, 0.85)
			var tw := create_tween()
			tw.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if chess_board:

		chess_board.set_interactive(false)

	if is_instance_valid(history_review_hint):
		if review_move_index == 0:
			history_review_hint.text = "Posición inicial"
		else:
			history_review_hint.text = "Jugada %d / %d" % [review_move_index, move_history.size()]



func _on_confirm_action_pressed() -> void:

	if confirm_modal_overlay:

		confirm_modal_overlay.visible = false

	var cb = _pending_confirm_callback

	_pending_confirm_callback = Callable()

	_pending_cancel_callback = Callable()

	if cb.is_valid():

		cb.call()



func _on_confirm_cancel_pressed() -> void:

	if confirm_modal_overlay:

		confirm_modal_overlay.visible = false

	_pending_confirm_callback = Callable()

	var cancel_cb = _pending_cancel_callback

	_pending_cancel_callback = Callable()

	if cancel_cb.is_valid():

		cancel_cb.call()

	if chess_board:

		var can_interact: bool = is_player_turn and not is_in_review_mode and not is_bot_thinking and not is_game_paused and not is_waiting_for_clock_press

		chess_board.set_interactive(can_interact)



func _setup_mute_button() -> void:

	if not mute_button:

		mute_button = %MuteButton if has_node("%MuteButton") else find_child("MuteButton", true, false)

	if mute_button:

		if not mute_button.pressed.is_connected(_on_mute_button_pressed):

			mute_button.pressed.connect(_on_mute_button_pressed)

		_update_mute_button_ui()



func _on_mute_button_pressed() -> void:

	var vm = _get_voice_manager()

	if vm and vm.has_method("toggle_mute"):

		vm.toggle_mute()

	elif vm and "is_muted" in vm:

		vm.is_muted = not vm.is_muted

	_update_mute_button_ui()



func _update_mute_button_ui() -> void:

	if not mute_button:

		return

	var vm = _get_voice_manager()

	var muted: bool = vm.is_muted if (vm and "is_muted" in vm) else false

	mute_button.text = "🔇" if muted else "🔊"

	mute_button.tooltip_text = "Activar voz del Profe Pollito" if muted else "Silenciar voz del Profe Pollito"



func _setup_hint_button() -> void:

	if not hint_button:

		hint_button = %HintButton if has_node("%HintButton") else find_child("HintButton", true, false)

	if hint_button:

		if not hint_button.pressed.is_connected(_on_hint_button_pressed):

			hint_button.pressed.connect(_on_hint_button_pressed)

		_update_hint_button_state()



func _update_hint_button_state() -> void:

	if not is_instance_valid(hint_button):

		return

	var is_profe = (bot_difficulty == 3)

	hint_button.visible = is_profe

	hint_button.disabled = not is_profe or not is_player_turn or is_in_review_mode or is_bot_thinking



func _on_hint_button_pressed() -> void:

	if not is_player_turn or is_bot_thinking or not chess_rules:

		return

	var req_gen: int = _bot_think_generation
	var req_fen: String = chess_rules.to_fen()
	bot.get_best_move_async(chess_rules, 5, func(best_m: Dictionary):

		if req_gen != _bot_think_generation or not is_inside_tree() or best_m.is_empty() or not is_player_turn or not chess_rules or chess_rules.to_fen() != req_fen:

			return

		var from_sq = ChessRules.vec_to_sq(best_m["from"])

		var to_sq = ChessRules.vec_to_sq(best_m["to"])

		if chess_board:

			chess_board.show_piece_hint(from_sq)

		var concept = ChessTutorConcepts.analyze_move_concept(chess_rules, from_sq, to_sq, current_match_opening)

		if avatar_rect and avatar_rect.has_method("set_expression"):

			avatar_rect.set_expression("explicando", true)

		set_dialogue("[color=#f59e0b][b]💡 Pista del Profe Pollito (%s):[/b][/color] Fíjate en tu casilla [b]%s[/b]... %s" % [concept["tag"], from_sq.to_upper(), concept["l2"]])

	)



func _setup_match_control_buttons() -> void:

	if not diff_button:

		diff_button = %DifficultyButton if has_node("%DifficultyButton") else find_child("DifficultyButton", true, false)

	if diff_button:
		if diff_button.pressed.is_connected(cycle_difficulty):
			diff_button.pressed.disconnect(cycle_difficulty)
		if not diff_button.pressed.is_connected(open_difficulty_modal):
			diff_button.pressed.connect(open_difficulty_modal)



	if not undo_button:

		undo_button = %UndoButton if has_node("%UndoButton") else find_child("UndoButton", true, false)

	if undo_button and not undo_button.pressed.is_connected(_on_undo_pressed):

		undo_button.pressed.connect(_on_undo_pressed)



	if not new_game_button:

		new_game_button = %NewGameButton if has_node("%NewGameButton") else find_child("NewGameButton", true, false)

	if new_game_button and not new_game_button.pressed.is_connected(_on_new_game_button_pressed):

		new_game_button.pressed.connect(_on_new_game_button_pressed)



	if not resign_button:

		resign_button = %ResignButton if has_node("%ResignButton") else find_child("ResignButton", true, false)

	if resign_button and not resign_button.pressed.is_connected(_on_resign_button_pressed):

		resign_button.pressed.connect(_on_resign_button_pressed)



	if continue_button:

		continue_button.visible = false



	_update_match_control_buttons()

	_update_undo_button_state()



func _setup_review_controls() -> void:

	if not replay_controls_bar:

		replay_controls_bar = %ReplayControlsBar if has_node("%ReplayControlsBar") else find_child("ReplayControlsBar", true, false)

	if not replay_first_btn:

		replay_first_btn = %ReplayFirstBtn if has_node("%ReplayFirstBtn") else find_child("ReplayFirstBtn", true, false)

	if not replay_prev_btn:

		replay_prev_btn = %ReplayPrevBtn if has_node("%ReplayPrevBtn") else find_child("ReplayPrevBtn", true, false)

	if not replay_play_btn:

		replay_play_btn = %ReplayPlayBtn if has_node("%ReplayPlayBtn") else find_child("ReplayPlayBtn", true, false)

	if not replay_next_btn:

		replay_next_btn = %ReplayNextBtn if has_node("%ReplayNextBtn") else find_child("ReplayNextBtn", true, false)

	if not replay_last_btn:

		replay_last_btn = %ReplayLastBtn if has_node("%ReplayLastBtn") else find_child("ReplayLastBtn", true, false)

	if not history_review_hint:

		history_review_hint = %HistoryReviewHint if has_node("%HistoryReviewHint") else find_child("HistoryReviewHint", true, false)



	if replay_first_btn and not replay_first_btn.pressed.is_connected(_on_review_first_pressed):

		replay_first_btn.pressed.connect(_on_review_first_pressed)

	if replay_prev_btn and not replay_prev_btn.pressed.is_connected(_on_review_prev_pressed):

		replay_prev_btn.pressed.connect(_on_review_prev_pressed)

	if replay_play_btn and not replay_play_btn.pressed.is_connected(_toggle_review_autoplay):

		replay_play_btn.pressed.connect(_toggle_review_autoplay)

	if replay_next_btn and not replay_next_btn.pressed.is_connected(_on_review_next_pressed):

		replay_next_btn.pressed.connect(_on_review_next_pressed)

	if replay_last_btn and not replay_last_btn.pressed.is_connected(_on_review_last_pressed):

		replay_last_btn.pressed.connect(_on_review_last_pressed)



	if move_history_label and not move_history_label.meta_clicked.is_connected(_on_history_meta_clicked):

		move_history_label.meta_clicked.connect(_on_history_meta_clicked)



	if replay_controls_bar:

		replay_controls_bar.visible = false

	if history_review_hint:

		history_review_hint.visible = false

	if not btn_review_match:
		btn_review_match = %BtnReviewMatch if has_node("%BtnReviewMatch") else find_child("BtnReviewMatch", true, false)
	if btn_review_match and not btn_review_match.pressed.is_connected(_on_review_match_button_pressed):
		btn_review_match.pressed.connect(_on_review_match_button_pressed)

	if not btn_exit_review:
		btn_exit_review = %BtnExitReview if has_node("%BtnExitReview") else find_child("BtnExitReview", true, false)
	if btn_exit_review and not btn_exit_review.pressed.is_connected(_exit_review_mode):
		btn_exit_review.pressed.connect(_exit_review_mode)



# =============================================================

# MENÚ DE PAUSA (TECLA ESCAPE)

# =============================================================



func _setup_pause_menu() -> void:
	if not pause_menu_overlay:
		pause_menu_overlay = %PauseMenuOverlay if has_node("%PauseMenuOverlay") else find_child("PauseMenuOverlay", true, false)
	if not resume_button:
		resume_button = %ResumeButton if has_node("%ResumeButton") else find_child("ResumeButton", true, false)
	if not back_to_menu_button:
		back_to_menu_button = %BackToMenuButton if has_node("%BackToMenuButton") else find_child("BackToMenuButton", true, false)
	if not is_instance_valid(btn_pause_menu):
		btn_pause_menu = %BtnPauseMenu if has_node("%BtnPauseMenu") else find_child("BtnPauseMenu", true, false)

	if is_instance_valid(btn_pause_menu) and not btn_pause_menu.pressed.is_connected(_toggle_pause_menu):
		btn_pause_menu.pressed.connect(_toggle_pause_menu)
	if resume_button and not resume_button.pressed.is_connected(_resume_game):
		resume_button.pressed.connect(_resume_game)
	if back_to_menu_button and not back_to_menu_button.pressed.is_connected(_on_back_to_menu_pressed):
		back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)

	if pause_menu_overlay:
		pause_menu_overlay.z_index = 1000
		pause_menu_overlay.z_as_relative = false
		pause_menu_overlay.visible = false
		if pause_menu_overlay is ColorRect:
			(pause_menu_overlay as ColorRect).color = Color(0.09, 0.04, 0.14, 0.72)
		if not pause_menu_overlay.gui_input.is_connected(_on_pause_overlay_gui_input):
			pause_menu_overlay.gui_input.connect(_on_pause_overlay_gui_input)

		var card = pause_menu_overlay.find_child("PauseCard", true, false) as Control
		if card:
			_apply_uniform_modal_card_style(card)

		var p_header = pause_menu_overlay.find_child("PauseHeader", true, false) as Label
		if p_header:
			p_header.add_theme_font_override("font", CHERRY_FONT)
			p_header.add_theme_font_size_override("font_size", 30)
			p_header.add_theme_color_override("font_color", Color("#BE185D"))
			p_header.add_theme_color_override("font_outline_color", Color.WHITE)
			p_header.add_theme_constant_override("outline_size", 8)
			p_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var p_sub = pause_menu_overlay.find_child("PauseSubtitle", true, false) as Label
		if p_sub:
			p_sub.add_theme_font_size_override("font_size", 15)
			p_sub.add_theme_color_override("font_color", Color("#701A75"))
			p_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		if resume_button:
			resume_button.text = "▶️ Continuar Partida"
			resume_button.custom_minimum_size = Vector2(0, 52)
			resume_button.add_theme_font_override("font", CHERRY_FONT)
			resume_button.add_theme_font_size_override("font_size", 19)
			var res_sb := StyleBoxFlat.new()
			res_sb.bg_color = Color("#10B981")
			res_sb.border_width_bottom = 5
			res_sb.border_color = Color("#047857")
			res_sb.set_corner_radius_all(18)
			var res_hov := res_sb.duplicate()
			res_hov.bg_color = Color("#34D399")
			resume_button.add_theme_stylebox_override("normal", res_sb)
			resume_button.add_theme_stylebox_override("hover", res_hov)
			resume_button.add_theme_stylebox_override("pressed", res_sb)
			resume_button.add_theme_color_override("font_color", Color.WHITE)

		if back_to_menu_button:
			back_to_menu_button.text = "🏠 Volver al Menú"
			back_to_menu_button.custom_minimum_size = Vector2(0, 48)
			back_to_menu_button.add_theme_font_override("font", CHERRY_FONT)
			back_to_menu_button.add_theme_font_size_override("font_size", 17)
			var back_sb := StyleBoxFlat.new()
			back_sb.bg_color = Color("#F43F5E")
			back_sb.border_width_bottom = 5
			back_sb.border_color = Color("#BE123C")
			back_sb.set_corner_radius_all(18)
			var back_hov := back_sb.duplicate()
			back_hov.bg_color = Color("#FB7185")
			back_to_menu_button.add_theme_stylebox_override("normal", back_sb)
			back_to_menu_button.add_theme_stylebox_override("hover", back_hov)
			back_to_menu_button.add_theme_stylebox_override("pressed", back_sb)
			back_to_menu_button.add_theme_color_override("font_color", Color.WHITE)

func _on_pause_overlay_gui_input(ev: InputEvent) -> void:
	if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
		_resume_game()

func _input(event: InputEvent) -> void:

	if event is InputEventKey and event.pressed and not event.echo:

		if event.keycode == KEY_ESCAPE:

			if confirm_modal_overlay and confirm_modal_overlay.visible:

				_on_confirm_cancel_pressed()

				get_viewport().set_input_as_handled()

				return

			_toggle_pause_menu()

			get_viewport().set_input_as_handled()

			return

		elif event.keycode == KEY_SPACE:

			if is_waiting_for_clock_press and not is_game_paused and (confirm_modal_overlay == null or not confirm_modal_overlay.visible):

				_on_player_clock_pressed()

				get_viewport().set_input_as_handled()

				return



func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if confirm_modal_overlay and confirm_modal_overlay.visible:
			_on_confirm_cancel_pressed()
		elif is_game_paused and pause_menu_overlay and pause_menu_overlay.visible:
			_resume_game()
		elif is_in_review_mode:
			_exit_review_mode()
		else:
			_toggle_pause_menu()

func _toggle_pause_menu() -> void:
	_play_swap_sound()
	if is_game_paused:
		_resume_game()
	else:
		_pause_game()



func _pause_game() -> void:
	if is_game_paused:
		return
	is_game_paused = true
	if pause_menu_overlay:
		pause_menu_overlay.visible = true
		pause_menu_overlay.move_to_front()
		var card = pause_menu_overlay.find_child("PauseCard", true, false) as Control
		if card:
			card.pivot_offset = card.size * 0.5
			card.scale = Vector2(0.85, 0.85)
			var tw := create_tween()
			tw.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if chess_board:

		chess_board.set_interactive(false)



func _resume_game() -> void:

	if not is_game_paused:

		return

	is_game_paused = false

	if pause_menu_overlay:

		pause_menu_overlay.visible = false

	if chess_board:

		var can_interact: bool = is_player_turn and not is_in_review_mode and not is_bot_thinking and not is_waiting_for_clock_press

		chess_board.set_interactive(can_interact)




func _on_back_to_menu_pressed() -> void:

	is_game_paused = false

	var vm = _get_voice_manager()

	if vm and vm.has_method("stop"):

		vm.stop()

	get_tree().change_scene_to_file("res://MainMenu.tscn")



func _unlock_review_button() -> void:
	is_match_started = false
	if not btn_review_match:
		btn_review_match = %BtnReviewMatch if has_node("%BtnReviewMatch") else find_child("BtnReviewMatch", true, false)
	if btn_review_match:
		btn_review_match.visible = true
		btn_review_match.disabled = false
		btn_review_match.text = "🔍 Revisar Partida"
	if resign_button:
		resign_button.visible = false
	if instruction_label:
		instruction_label.text = "🏁 Partida finalizada • Presiona 'Revisar Partida' para repasar las jugadas"

	_update_match_control_buttons()

func _on_review_match_button_pressed() -> void:
	if is_in_review_mode:
		_exit_review_mode()
	else:
		_enter_review_mode()


const MatchHistoryManagerScript = preload("res://scripts/MatchHistoryManager.gd")

func _get_history_mgr() -> Node:
	if is_inside_tree() and has_node("/root/MatchHistoryManager"):
		return get_node("/root/MatchHistoryManager")
	return MatchHistoryManagerScript.instance

func _save_current_match_to_history(result: String, result_title: String, reason: String) -> void:
	if is_current_match_saved:
		return
	if move_history.is_empty():
		return
	is_current_match_saved = true

	var p_name = "Lyanna"
	var pm = _get_pm()
	if pm and pm.has_method("get_active_profile"):
		var prof = pm.get_active_profile()
		if prof is Dictionary and prof.has("name") and not str(prof["name"]).is_empty():
			p_name = str(prof["name"])
	elif pm and pm.has_method("get_player_name"):
		var n = pm.get_player_name()
		if not n.is_empty():
			p_name = n

	var bot_name = "Profe Pollito"
	match bot_difficulty:
		1: bot_name = "Pollito Principiante (~700)"
		2: bot_name = "Pollito Aprendiz (~1200)"
		3: bot_name = "Profe Pollito (~1700)"
		4: bot_name = "Pollito Maestro (~2200)"
		5: bot_name = "Pollito GM (~2600+)"

	var match_data: Dictionary = {
		"mode": "bot",
		"difficulty": bot_difficulty,
		"difficulty_name": _get_difficulty_name(),
		"player_name": p_name,
		"player_color": "w",
		"opponent_name": bot_name,
		"opponent_color": "b",
		"result": result,
		"result_title": result_title,
		"reason": reason,
		"moves": move_history.duplicate(),
		"fens": match_history_fens.duplicate(),
		"moves_count": move_history.size(),
		"duration_seconds": int(match_duration_seconds)
	}

	var mhm = _get_history_mgr()
	if mhm:
		mhm.save_match(match_data)

func _load_and_review_saved_match(match_data: Dictionary) -> void:
	_reset_clock_press_state()
	_bot_think_generation += 1
	is_bot_thinking = false
	is_match_started = false
	is_match_timer_active = false
	is_current_match_saved = true

	if chess_clock:
		chess_clock.pause()
		chess_clock.is_enabled = false
	if is_instance_valid(clock_toggle):
		clock_toggle.visible = false

	var moves: Array = match_data.get("moves", [])
	var fens: Array = match_data.get("fens", [])

	move_history.clear()
	for m in moves:
		move_history.append(str(m))

	match_history_fens.clear()
	for f in fens:
		match_history_fens.append(str(f))

	if match_history_fens.is_empty():
		match_history_fens.append(ChessRules.STARTING_FEN)

	var p_color = match_data.get("player_color", "w")
	if chess_board:
		chess_board.set_flipped(p_color == "b")
		chess_board.set_interactive(false)

	var opp_name = match_data.get("opponent_name", "Rival")
	var res_title = match_data.get("result_title", "Partida")
	var mode_name = "Contra Bots" if match_data.get("mode", "") == "bot" else "Versus"
	var date_str = match_data.get("date", "")

	if lesson_title:
		lesson_title.text = "Revisión: %s" % res_title

	set_dialogue("[color=#db2777][b]Historial de Partidas:[/b][/color] Revisando partida de %s contra [b]%s[/b] (%s). Puedes navegar libremente con los controles de reproducción abajo." % [mode_name, opp_name, date_str])

	if instruction_label:
		instruction_label.text = "🔍 Revisando partida guardada • %d jugadas" % move_history.size()

	_unlock_review_button()
	_enter_review_mode()


func _enter_review_mode() -> void:
	if move_history.is_empty():
		return

	is_in_review_mode = true
	review_move_index = move_history.size()
	_stop_review_autoplay()

	# 1. Ocultar widgets no relacionados en el panel lateral para dar todo el espacio al repaso
	var header = find_child("Header", true, false)
	if is_instance_valid(header):
		header.visible = false

	var dialogue_bubble = find_child("DialogueBubble", true, false)
	if is_instance_valid(dialogue_bubble):
		dialogue_bubble.visible = false

	var controls_row = find_child("ControlsSplitRow", true, false)
	if is_instance_valid(controls_row):
		controls_row.visible = false

	var stats_sec = find_child("MatchStatsSection", true, false)
	if is_instance_valid(stats_sec):
		stats_sec.visible = false

	# 2. Expandir el contenedor de historial para ocupar TODO el panel lateral
	if is_instance_valid(bottom_split_hbox):
		bottom_split_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if is_instance_valid(move_history_section):
		move_history_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		move_history_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
		move_history_section.custom_minimum_size = Vector2(0, 0)

	# 3. Cabecera y botón de salida en el modo revisión
	var is_mob_rev: bool = false
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if sm.has_method("is_mobile"):
			is_mob_rev = sm.is_mobile()

	if is_instance_valid(history_title):
		history_title.text = "🔍 MODO REVISIÓN"
		history_title.add_theme_font_size_override("font_size", 20 if is_mob_rev else 16)
		history_title.add_theme_color_override("font_color", Color("#db2777"))

	if is_instance_valid(history_review_hint):
		history_review_hint.visible = true
		history_review_hint.text = "Jugada %d / %d" % [review_move_index, move_history.size()]
		history_review_hint.add_theme_font_size_override("font_size", 16 if is_mob_rev else 13)

	if is_instance_valid(btn_exit_review):
		btn_exit_review.visible = true
		if _get_history_mgr() and _get_history_mgr().open_history_on_main_menu:
			btn_exit_review.text = "🔙 Volver al Historial"
		else:
			btn_exit_review.text = "✖ Salir de Revisión"

	# 4. Agrandar fuente del texto del historial para ocupar cómodamente el espacio
	if is_instance_valid(move_history_label):
		move_history_label.add_theme_font_size_override("normal_font_size", 20 if is_mob_rev else 16)

	# 5. Agrandar barra de controles de reproducción y botones
	if is_instance_valid(replay_controls_bar):
		replay_controls_bar.visible = true
		replay_controls_bar.custom_minimum_size = Vector2(0, 48)
		for btn in [replay_first_btn, replay_prev_btn, replay_next_btn, replay_last_btn]:
			if is_instance_valid(btn):
				btn.custom_minimum_size = Vector2(52, 44)
				btn.add_theme_font_size_override("font_size", 18)
		if is_instance_valid(replay_play_btn):
			replay_play_btn.custom_minimum_size = Vector2(100, 44)
			replay_play_btn.add_theme_font_size_override("font_size", 14)

	_update_review_buttons_state()
	_rebuild_history_ui()
	_update_review_ui()
	_scroll_history_to_active_review_move()
	_jump_to_review_move(review_move_index)

func _exit_review_mode() -> void:
	if _get_history_mgr() and _get_history_mgr().open_history_on_main_menu:
		_get_history_mgr().clear_review_match()
		get_tree().change_scene_to_file("res://MainMenu.tscn")
		return

	is_in_review_mode = false
	_stop_review_autoplay()

	# 1. Restaurar paneles laterales
	var header = find_child("Header", true, false)
	if is_instance_valid(header):
		header.visible = true

	var dialogue_bubble = find_child("DialogueBubble", true, false)
	if is_instance_valid(dialogue_bubble):
		dialogue_bubble.visible = true

	var controls_row = find_child("ControlsSplitRow", true, false)
	if is_instance_valid(controls_row):
		controls_row.visible = true

	var stats_sec = find_child("MatchStatsSection", true, false)
	if is_instance_valid(stats_sec):
		stats_sec.visible = true

	# 2. Restaurar tamaños del historial
	if is_instance_valid(move_history_section) and not is_in_review_mode:
		move_history_section.custom_minimum_size = Vector2(0, 130)

	# 3. Restaurar cabecera
	var is_mob_exit: bool = false
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if sm.has_method("is_mobile"):
			is_mob_exit = sm.is_mobile()

	if is_instance_valid(history_title):
		history_title.text = "📜 Historial:"
		history_title.add_theme_font_size_override("font_size", 15 if is_mob_exit else 11)
		history_title.remove_theme_color_override("font_color")

	if is_instance_valid(history_review_hint):
		history_review_hint.visible = false

	if is_instance_valid(btn_exit_review):
		btn_exit_review.visible = false

	# 4. Restaurar fuente del historial
	if is_instance_valid(move_history_label):
		move_history_label.add_theme_font_size_override("normal_font_size", 16 if is_mob_exit else 12)

	# 5. Ocultar barra de replay
	if is_instance_valid(replay_controls_bar):
		replay_controls_bar.visible = false

	# 6. Tablero a la posición final
	if match_history_fens.size() > 0 and is_instance_valid(chess_board):
		chess_board.set_fen(match_history_fens[match_history_fens.size() - 1])
		chess_board.set_interactive(false)

	_rebuild_history_ui()
	_update_material_and_captures_ui()
	_update_match_control_buttons()


func _on_history_meta_clicked(meta: Variant) -> void:

	if not is_in_review_mode:

		return

	_stop_review_autoplay()

	var idx = str(meta).to_int()

	_jump_to_review_move(idx)



func _on_review_first_pressed() -> void:

	_stop_review_autoplay()

	_jump_to_review_move(0)



func _on_review_prev_pressed() -> void:

	_stop_review_autoplay()

	_jump_to_review_move(review_move_index - 1)



func _on_review_next_pressed() -> void:

	_stop_review_autoplay()

	_jump_to_review_move(review_move_index + 1)



func _on_review_last_pressed() -> void:

	_stop_review_autoplay()

	_jump_to_review_move(move_history.size())



func _start_review_autoplay() -> void:

	if review_move_index >= move_history.size():

		_jump_to_review_move(0)

	is_review_autoplay_active = true

	review_autoplay_timer = 0.0

	if replay_play_btn:

		replay_play_btn.text = "⏸ Pausa"



func _stop_review_autoplay() -> void:

	is_review_autoplay_active = false

	review_autoplay_timer = 0.0

	if replay_play_btn:

		replay_play_btn.text = "▶ Ver"



func _toggle_review_autoplay() -> void:

	if is_review_autoplay_active:

		_stop_review_autoplay()

	else:

		_start_review_autoplay()



func _jump_to_review_move(target_idx: int) -> void:

	target_idx = clampi(target_idx, 0, move_history.size())

	review_move_index = target_idx



	if target_idx >= 0 and target_idx < match_history_fens.size():

		var target_fen = match_history_fens[target_idx]

		if chess_board:

			chess_board.set_fen(target_fen)

			chess_board.set_interactive(false)



	_update_review_buttons_state()

	_rebuild_history_ui()

	_update_review_ui()

	_scroll_history_to_active_review_move()



func _update_review_buttons_state() -> void:

	var total_moves = move_history.size()

	if replay_first_btn:

		replay_first_btn.disabled = (review_move_index <= 0)

	if replay_prev_btn:

		replay_prev_btn.disabled = (review_move_index <= 0)

	if replay_next_btn:

		replay_next_btn.disabled = (review_move_index >= total_moves)

	if replay_last_btn:

		replay_last_btn.disabled = (review_move_index >= total_moves)



func _update_review_ui() -> void:

	var total_moves = move_history.size()

	if instruction_label:

		if review_move_index == 0:

			instruction_label.text = "🔍 Repaso: Posición inicial (antes de la jugada 1 / %d)" % total_moves

		else:

			var is_white = (review_move_index % 2 == 1)

			var move_num = int((review_move_index - 1) / 2) + 1

			var player_str = ("Blancas (%s)" % _get_player_name()) if is_white else "Negras (Profe Pollito)"

			var san_str = move_history[review_move_index - 1] if (review_move_index - 1 < move_history.size()) else ""

			instruction_label.text = "🔍 Repaso: Jugada %d (%d/%d) • %s: %s" % [move_num, review_move_index, total_moves, player_str, san_str]



	_update_material_and_captures_ui()



func _update_match_control_buttons() -> void:
	if undo_button:
		undo_button.visible = true
		_update_undo_button_state()

	_update_hint_button_state()

	if diff_button:
		diff_button.disabled = is_match_started

	if clock_toggle:
		clock_toggle.disabled = is_match_started

	if clock_time_option:
		clock_time_option.disabled = is_match_started

	if resign_button:
		resign_button.disabled = not is_match_started
		if not is_match_started and move_history.size() > 0:
			resign_button.visible = false
		else:
			resign_button.visible = true

	if btn_review_match:
		if not is_match_started and move_history.size() > 0:
			btn_review_match.visible = true
			btn_review_match.disabled = false
		else:
			btn_review_match.visible = false
			btn_review_match.disabled = true


	if new_game_button:
		if is_match_started:
			new_game_button.text = "🔄 Reiniciar Partida"
			new_game_button.disabled = false
		elif is_in_review_mode or (chess_rules and chess_rules.history.size() > 0 and chess_board and not chess_board.is_interactive):
			new_game_button.text = "🔄 Nueva Partida"
			new_game_button.disabled = false
		else:
			new_game_button.text = "🔄 Reiniciar Partida"
			new_game_button.disabled = true

func _update_undo_button_state() -> void:

	if not is_instance_valid(undo_button): return

	var board_busy: bool = (chess_board != null and (chess_board.is_animating or (chess_board.promotion_popup != null and chess_board.promotion_popup.visible)))
	# Activo SOLO si es nivel Fácil (1) o Medio (2), hay al menos 2 jugadas en el historial, es el turno de blancas, la partida está en marcha y no es modo repaso
	if bot_difficulty <= 2 and chess_rules and chess_rules.history.size() >= 2 and chess_rules.white_to_move and not is_bot_thinking and not is_waiting_for_clock_press and not board_busy and is_match_started and not is_in_review_mode:

		undo_button.disabled = false

	else:

		undo_button.disabled = true



func _on_new_game_button_pressed() -> void:
	if not is_match_started:
		if is_in_review_mode or (chess_rules and chess_rules.history.size() > 0 and chess_board and not chess_board.is_interactive):
			_execute_new_game()
		return

	_show_confirm_dialog(
		"🔄 Reiniciar Partida",
		"¿Deseas reiniciar la partida actual?\nSe reiniciará el tablero desde el principio.",
		"Sí, reiniciar",
		"Cancelar",
		_execute_new_game,
		true
	)

func _on_confirm_new_game() -> void:

	_execute_new_game()



func _execute_new_game() -> void:

	if match_effects_overlay:
		match_effects_overlay.clear_effects()

	_bot_think_generation += 1

	is_bot_thinking = false

	is_match_started = false

	is_player_turn = true

	current_turn_number = 1

	if diff_button:

		diff_button.disabled = false

	if chess_rules:

		chess_rules.reset()

	move_history.clear()

	_rebuild_history_ui()

	start_new_free_play_game()

	_update_match_control_buttons()

	_update_undo_button_state()



func _on_resign_button_pressed() -> void:

	if not is_match_started or is_in_review_mode:

		return

	_show_confirm_dialog(

		"🏳️ Rendirse",

		"¿Estás segura de que quieres rendirte?\nSe declarará la victoria del Profe Pollito.",

		"Sí, rendirme",

		"Seguir jugando",

		_execute_resign,

		false

	)



func _on_confirm_resign() -> void:

	_execute_resign()



func _execute_resign() -> void:

	_reset_clock_press_state()

	_bot_think_generation += 1

	is_bot_thinking = false

	is_match_started = false

	is_match_timer_active = false

	if chess_board:

		chess_board.set_interactive(false)

	if chess_clock:

		chess_clock.pause()

	if diff_button:

		diff_button.disabled = false



	if lesson_title:

		lesson_title.text = "Partida Finalizada (Rendición)"

	set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] ¡Buen intento Lyanna! Saber cuándo rendirse también es de grandes maestras. ¡Analicemos lo aprendido y vamos por la revancha!")

	if instruction_label:

		instruction_label.text = "🏁 Te has rendido. ¡Presiona NUEVA PARTIDA para volver a jugar!"

	if avatar_rect and avatar_rect.has_method("set_expression"):

		avatar_rect.set_expression("celebrando", true)

	if match_effects_overlay:
		match_effects_overlay.play_defeat_effect("feathers")

	_update_match_control_buttons()

	_update_undo_button_state()

	_save_current_match_to_history("defeat", "Derrota", "Rendición")
	_unlock_review_button()

	last_speech_text = "¡Buen intento Lyanna! Vamos por la revancha."

	_speak_voice(last_speech_text)

func _on_undo_pressed() -> void:

	if match_effects_overlay:
		match_effects_overlay.clear_effects()

	if not chess_rules or chess_rules.history.size() < 2: return

	if is_in_review_mode or is_bot_thinking or is_waiting_for_clock_press or not chess_rules.white_to_move: return
	if chess_board and (chess_board.is_animating or (chess_board.promotion_popup and chess_board.promotion_popup.visible)): return

	_bot_think_generation += 1



	# Deshacer 2 veces: la respuesta del Bot y la última jugada del Jugador

	chess_rules.undo_turn()

	chess_rules.undo_turn()



	if match_history_fens.size() > 2:

		match_history_fens.pop_back()

		match_history_fens.pop_back()



	# Sincronizar piezas visuales sin animación

	if chess_board.has_method("sync_board_to_rules"):

		chess_board.sync_board_to_rules(chess_rules)

	if bot_difficulty == 1 and not current_sparring_session.is_empty():
		current_sparring_session["book_step_index"] = clampi(int(current_sparring_session.get("book_step_index", 0)) - 1, 0, 10)
		var book_sz = current_sparring_session.get("opening", {}).get("book", []).size()
		if current_sparring_session["book_step_index"] < book_sz:
			current_sparring_session["opening_completed"] = false
			current_sparring_session["opening_deviated"] = false
		current_sparring_session["last_sparring_tip"] = ""

	# Ajustar variables de turno

	is_player_turn = chess_rules.white_to_move

	_update_turn_ui()

	_update_undo_button_state()



	# Borrar la última jugada del historial visual (ScrollContainer/RichTextLabel)

	if current_turn_number > 1:

		current_turn_number -= 1

		_rebuild_history_ui()

	else:

		_rebuild_history_ui()



	if chess_rules.history.is_empty():

		is_match_started = false

		is_match_timer_active = false

		match_duration_seconds = 0.0

		_update_match_timer_label()

		if diff_button:

			diff_button.disabled = false



	_update_match_control_buttons()



	set_dialogue("[color=#2563eb][b]Profe Pollito:[/b][/color] ¡Jugada deshecha! Tómate tu tiempo y busca un movimiento mejor, Lyanna.")

	last_speech_text = "¡Jugada deshecha! Piensa bien tu siguiente movimiento."

	_speak_voice(last_speech_text)

	_apply_turn_coaching()



func _on_undo_button_pressed() -> void:

	_on_undo_pressed()



func _update_turn_ui() -> void:

	if is_in_review_mode:

		_update_review_ui()

		return



	if lesson_title:

		lesson_title.text = "Tu Turno (Blancas)" if is_player_turn else "Turno del Profe Pollito (Negras)"

	if instruction_label:

		instruction_label.text = "🎯 Arrastra o toca una pieza blanca para mover" if is_player_turn else "⏳ Esperando jugada..."

	if avatar_rect and avatar_rect.has_method("set_expression"):

		avatar_rect.set_expression("explicando" if is_player_turn else "pensando", true)



	_update_material_and_captures_ui()



	if chess_clock and chess_clock.is_enabled:

		chess_clock.set_turn(is_player_turn)

		_update_active_clock_style()



func _get_pm() -> Node:

	if has_node("/root/ProfileManager"):

		return get_node("/root/ProfileManager")

	if ProfileManagerScript.instance:

		return ProfileManagerScript.instance

	return null



func _adapt_text(text: String) -> String:

	var pm = _get_pm()

	if pm and pm.has_method("adapt_text"):

		return pm.adapt_text(text)

	return text



func _get_player_name() -> String:

	var pm = _get_pm()

	if pm and pm.has_method("get_player_name"):

		return pm.get_player_name()

	return "Lyanna"



func _get_voice_manager() -> Node:

	return get_node_or_null("/root/VoiceManager")



func _connect_voice_manager() -> void:

	var vm = _get_voice_manager()

	if vm:

		if not vm.speech_started.is_connected(_on_pollito_start_talking):

			vm.speech_started.connect(_on_pollito_start_talking)

		if not vm.speech_finished.is_connected(_on_pollito_stop_talking):

			vm.speech_finished.connect(_on_pollito_stop_talking)



func _speak_voice(text: String, delay: float = 0.22) -> void:

	if text.is_empty() or not is_inside_tree() or not get_tree():

		return

	var adapted = _adapt_text(text)

	if delay > 0.0:

		get_tree().create_timer(delay).timeout.connect(func():
			if not is_inside_tree():
				return
			var vm = _get_voice_manager()

			if vm and vm.has_method("speak"):

				vm.speak(adapted)

		)

	else:

		var vm = _get_voice_manager()

		if vm and vm.has_method("speak"):

			vm.speak(adapted)



func _setup_difficulty_modal() -> void:
	if not is_instance_valid(difficulty_modal):
		difficulty_modal = DifficultyModalScene.instantiate()
		add_child(difficulty_modal)
		difficulty_modal.level_selected.connect(_on_difficulty_selected)

func open_difficulty_modal() -> void:
	if is_match_started:
		return
	_setup_difficulty_modal()
	if is_instance_valid(difficulty_modal):
		difficulty_modal.open(bot_difficulty)

func _on_difficulty_selected(new_level: int) -> void:
	bot_difficulty = clampi(new_level, 1, 5)
	_update_difficulty_ui()
	if bot_difficulty >= 4 and clock_toggle and clock_toggle.button_pressed:
		set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] ¡Dificultad ajustada a [b]%s[/b]! ⏱️ Modo torneo activo: tras mover tu pieza, deberás pulsar tu reloj o presionar [b][Espacio][/b] para pasar el turno." % _get_difficulty_name())
	else:
		set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] ¡Dificultad ajustada a [b]%s[/b]!" % _get_difficulty_name())

	if chess_board:
		chess_board.clear_suggestion()

	if is_player_turn and not is_match_started:
		_apply_turn_coaching()

func _setup_difficulty_button() -> void:
	if not diff_button:
		diff_button = %DifficultyButton if has_node("%DifficultyButton") else find_child("DifficultyButton", true, false)
	if diff_button:
		if diff_button.pressed.is_connected(cycle_difficulty):
			diff_button.pressed.disconnect(cycle_difficulty)
		if not diff_button.pressed.is_connected(open_difficulty_modal):
			diff_button.pressed.connect(open_difficulty_modal)

	_setup_difficulty_modal()
	_update_difficulty_ui()



func _setup_clock() -> void:

	style_clock_active = StyleBoxFlat.new()

	style_clock_active.bg_color = Color("#FFF6ED")

	style_clock_active.border_width_left = 2

	style_clock_active.border_width_top = 2

	style_clock_active.border_width_right = 2

	style_clock_active.border_width_bottom = 5

	style_clock_active.border_color = Color("#EC4899")

	style_clock_active.set_corner_radius_all(12)

	style_clock_active.shadow_color = Color(0.9, 0.3, 0.6, 0.25)

	style_clock_active.shadow_size = 6

	style_clock_active.shadow_offset = Vector2(0, 3)

	style_clock_active.anti_aliasing = true



	style_clock_inactive = StyleBoxFlat.new()

	style_clock_inactive.bg_color = Color("#F8FAFC")

	style_clock_inactive.border_width_left = 1

	style_clock_inactive.border_width_top = 1

	style_clock_inactive.border_width_right = 1

	style_clock_inactive.border_width_bottom = 3

	style_clock_inactive.border_color = Color("#E2E8F0")

	style_clock_inactive.set_corner_radius_all(12)

	style_clock_inactive.anti_aliasing = true



	style_clock_waiting_press = StyleBoxFlat.new()

	style_clock_waiting_press.bg_color = Color("#FFF1F2")

	style_clock_waiting_press.border_width_left = 2

	style_clock_waiting_press.border_width_top = 2

	style_clock_waiting_press.border_width_right = 2

	style_clock_waiting_press.border_width_bottom = 5

	style_clock_waiting_press.border_color = Color("#E11D48")

	style_clock_waiting_press.set_corner_radius_all(12)

	style_clock_waiting_press.shadow_color = Color(0.88, 0.11, 0.28, 0.4)

	style_clock_waiting_press.shadow_size = 8

	style_clock_waiting_press.shadow_offset = Vector2(0, 3)

	style_clock_waiting_press.anti_aliasing = true



	if white_clock_panel:

		if not white_clock_panel.gui_input.is_connected(_on_white_clock_gui_input):

			white_clock_panel.gui_input.connect(_on_white_clock_gui_input)

		white_clock_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	if white_time_label:

		white_time_label.mouse_filter = Control.MOUSE_FILTER_PASS

	if white_player_label:

		white_player_label.mouse_filter = Control.MOUSE_FILTER_PASS

	if black_clock_panel:

		black_clock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE



	if clock_toggle and not clock_toggle.toggled.is_connected(_on_clock_toggle_changed):
		clock_toggle.toggled.connect(_on_clock_toggle_changed)

	if not clock_time_option:
		clock_time_option = %ClockTimeOption if has_node("%ClockTimeOption") else find_child("ClockTimeOption", true, false)

	if clock_time_option:
		clock_time_option.clear()
		var default_idx = 3 # 5 min
		for i in range(CLOCK_TIME_PRESETS.size()):
			var p = CLOCK_TIME_PRESETS[i]
			clock_time_option.add_item(p.label, i)
			if absf(p.seconds - selected_clock_duration) < 1.0:
				default_idx = i
		clock_time_option.select(default_idx)
		if not clock_time_option.item_selected.is_connected(_on_clock_time_option_selected):
			clock_time_option.item_selected.connect(_on_clock_time_option_selected)
		clock_time_option.disabled = is_match_started

		var opt_normal = StyleBoxFlat.new()
		opt_normal.bg_color = Color("#F8FAFC")
		opt_normal.border_width_left = 1
		opt_normal.border_width_top = 1
		opt_normal.border_width_right = 1
		opt_normal.border_width_bottom = 2
		opt_normal.border_color = Color("#CBD5E1")
		opt_normal.set_corner_radius_all(6)
		opt_normal.content_margin_left = 6
		opt_normal.content_margin_right = 6

		var opt_hover = opt_normal.duplicate()
		opt_hover.bg_color = Color("#FFFFFF")
		opt_hover.border_color = Color("#EC4899")

		var opt_disabled = opt_normal.duplicate()
		opt_disabled.bg_color = Color("#E2E8F0")
		opt_disabled.border_color = Color("#CBD5E1")

		clock_time_option.add_theme_stylebox_override("normal", opt_normal)
		clock_time_option.add_theme_stylebox_override("hover", opt_hover)
		clock_time_option.add_theme_stylebox_override("pressed", opt_hover)
		clock_time_option.add_theme_stylebox_override("disabled", opt_disabled)
		clock_time_option.add_theme_color_override("font_color", Color("#334155"))
		clock_time_option.add_theme_color_override("font_hover_color", Color("#0F172A"))
		clock_time_option.add_theme_color_override("font_disabled_color", Color("#94A3B8"))

	if chess_clock:
		if not chess_clock.time_updated.is_connected(_on_clock_time_updated):
			chess_clock.time_updated.connect(_on_clock_time_updated)
		if not chess_clock.timeout.is_connected(_on_clock_timeout):
			chess_clock.timeout.connect(_on_clock_timeout)

	_update_active_clock_style()

func _on_clock_time_option_selected(idx: int) -> void:
	if is_match_started:
		return
	if idx >= 0 and idx < CLOCK_TIME_PRESETS.size():
		selected_clock_duration = CLOCK_TIME_PRESETS[idx].seconds
		if chess_clock:
			chess_clock.reset(selected_clock_duration)
		_update_active_clock_style()
		if clock_toggle and clock_toggle.button_pressed:
			var mins_str = CLOCK_TIME_PRESETS[idx].label
			set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] ⏱️ Tiempo configurado a [b]%s[/b] por jugador." % mins_str)

func _on_clock_toggle_changed(toggled_on: bool) -> void:
	if is_match_started:
		if clock_toggle:
			clock_toggle.set_pressed_no_signal(not toggled_on)
		return

	if not chess_clock:
		return

	chess_clock.is_enabled = toggled_on
	if toggled_on:
		chess_clock.reset(selected_clock_duration)
		chess_clock.set_turn(chess_board.rules.white_to_move if (chess_board and chess_board.rules) else true)
		if is_match_started:
			chess_clock.start()
		else:
			chess_clock.pause()
		var mins_label = "%d min" % int(round(selected_clock_duration / 60.0))
		set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] ⏱️ ¡Modo Reloj activado! Tienen %s por jugador. ¡Piensa rápido y diviértete!" % mins_label)
		last_speech_text = "¡Modo reloj activado! Tienes %s." % mins_label
		_speak_voice(last_speech_text)
	else:
		chess_clock.pause()
		set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] Reloj desactivado. Tómate todo el tiempo que quieras para pensar cada jugada.")

	_update_active_clock_style()

func _update_active_clock_style() -> void:

	if is_waiting_for_clock_press:

		if white_clock_panel: white_clock_panel.add_theme_stylebox_override("panel", style_clock_waiting_press)

		if black_clock_panel: black_clock_panel.add_theme_stylebox_override("panel", style_clock_inactive)

		if white_time_label: white_time_label.add_theme_color_override("font_color", Color("#db2777"))

		if black_time_label: black_time_label.add_theme_color_override("font_color", Color("#6b7280"))

		return



	if not chess_clock or not chess_clock.is_enabled:

		if white_clock_panel: white_clock_panel.add_theme_stylebox_override("panel", style_clock_inactive)

		if black_clock_panel: black_clock_panel.add_theme_stylebox_override("panel", style_clock_inactive)

		if white_time_label: white_time_label.add_theme_color_override("font_color", Color("#9ca3af"))

		if black_time_label: black_time_label.add_theme_color_override("font_color", Color("#9ca3af"))

		return



	if chess_clock.white_turn:

		if white_clock_panel: white_clock_panel.add_theme_stylebox_override("panel", style_clock_active)

		if black_clock_panel: black_clock_panel.add_theme_stylebox_override("panel", style_clock_inactive)

		if white_time_label: white_time_label.add_theme_color_override("font_color", Color("#db2777"))

		if black_time_label: black_time_label.add_theme_color_override("font_color", Color("#6b7280"))

	else:

		if white_clock_panel: white_clock_panel.add_theme_stylebox_override("panel", style_clock_inactive)

		if black_clock_panel: black_clock_panel.add_theme_stylebox_override("panel", style_clock_active)

		if white_time_label: white_time_label.add_theme_color_override("font_color", Color("#6b7280"))

		if black_time_label: black_time_label.add_theme_color_override("font_color", Color("#db2777"))



func _on_clock_time_updated(w_time: float, b_time: float) -> void:

	if white_time_label:

		white_time_label.text = ChessClock.format_time(w_time)

		if w_time <= 30.0 and chess_clock.is_enabled:

			white_time_label.add_theme_color_override("font_color", Color("#dc2626"))

	if black_time_label:

		black_time_label.text = ChessClock.format_time(b_time)

		if b_time <= 30.0 and chess_clock.is_enabled:

			black_time_label.add_theme_color_override("font_color", Color("#dc2626"))



func _on_clock_timeout(loser_color: String) -> void:

	_reset_clock_press_state()

	is_match_started = false

	is_match_timer_active = false

	if diff_button:

		diff_button.disabled = false

	_update_match_control_buttons()



	if chess_board:

		chess_board.set_interactive(false)



	if loser_color == "w":

		# Jugador perdió por tiempo

		if lesson_title: lesson_title.text = "¡Tiempo Agotado! ⏱️"

		set_dialogue("[color=#dc2626][b]¡Se acabó el tiempo Lyanna![/b][/color] En el ajedrez con reloj hay que pensar ágilmente. ¡Muy buen intento! Presiona NUEVA PARTIDA para volver a jugar.")

		if instruction_label: instruction_label.text = "⏱️ Partida finalizada por tiempo"

		if avatar_rect and avatar_rect.has_method("set_expression"):

			avatar_rect.set_expression("animando", true)

		if match_effects_overlay:

			match_effects_overlay.play_defeat_effect("feathers")

		last_speech_text = "¡Se acabó el tiempo Lyanna! Buen intento, la próxima saldrá mejor."

		_speak_voice(last_speech_text)

	else:

		# Bot perdió por tiempo -> ¡Ganó Lyanna!

		if lesson_title: lesson_title.text = "¡Victoria por Tiempo! 🏆"

		set_dialogue("[color=#15803d][b]¡VICTORIA POR TIEMPO! 🌟[/b][/color]\n¡Se me agotó el tiempo Lyanna! Me hiciste pensar tanto que mi reloj llegó a cero. ¡Eres muy rápida y ganaste la partida!")

		if instruction_label: instruction_label.text = "🏆 ¡GANASTE LA PARTIDA POR TIEMPO!"

		if avatar_rect and avatar_rect.has_method("set_expression"):

			avatar_rect.set_expression("celebrando", true)

		if chess_board:

			chess_board.play_victory_sound()

		if match_effects_overlay:

			match_effects_overlay.play_victory_effect()

		last_speech_text = "¡Se me agotó el tiempo! Me ganaste por tiempo Lyanna, ¡felicidades!"

		_speak_voice(last_speech_text)



	if loser_color == "w":
		_save_current_match_to_history("defeat", "Derrota", "Tiempo Agotado")
	else:
		_save_current_match_to_history("victory", "Victoria", "Tiempo Agotado del Rival")
	_unlock_review_button()



func start_new_free_play_game() -> void:
	is_current_match_saved = false
	if is_in_review_mode:
		_exit_review_mode()

	if match_effects_overlay:
		match_effects_overlay.clear_effects()

	_reset_clock_press_state()

	is_match_started = false

	is_bot_thinking = false

	is_player_turn = true

	current_turn_number = 1

	is_in_review_mode = false

	review_move_index = 0

	_stop_review_autoplay()

	if replay_controls_bar:

		replay_controls_bar.visible = false

	if history_review_hint:

		history_review_hint.visible = false

	if bot_difficulty == 1:
		current_sparring_session = ChessSparringEngine.create_session()
		current_match_opening = current_sparring_session.get("opening_id", "italiana")
	else:
		current_sparring_session.clear()
		current_match_opening = ChessTutorConcepts.pick_random_opening()

	move_history.clear()

	_rebuild_history_ui()



	if chess_board:

		if chess_board.rules:

			chess_board.rules.reset()

		chess_board.reset_to_starting_position()

		chess_board.set_interactive(true)



	match_history_fens.clear()

	if chess_rules:

		match_history_fens.append(chess_rules.to_fen())



	if diff_button:

		diff_button.disabled = false



	_update_difficulty_ui()

	_update_turn_ui()

	_update_match_control_buttons()

	_update_undo_button_state()



	if lesson_title:

		lesson_title.text = "Tu Turno (Blancas)"



	set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] ¡Hola Lyanna! Juguemos una partida de ajedrez completa. Tú llevas las piezas blancas. ¡Mueve un peón o un caballo para iniciar!")



	if instruction_label:

		instruction_label.text = "🎯 Arrastra o toca una pieza blanca para mover"



	if continue_button:

		continue_button.text = "NUEVA PARTIDA 🔄"

		continue_button.disabled = false



	var w_name_lbl = find_child("WhiteNameLabel", true, false)

	if w_name_lbl:

		w_name_lbl.text = "⚪ " + _get_player_name()



	match_duration_seconds = 0.0

	is_match_timer_active = false

	_update_match_timer_label()

	_update_material_and_captures_ui()



	if chess_clock:
		chess_clock.reset(selected_clock_duration)
		if clock_toggle and clock_toggle.button_pressed:
			chess_clock.is_enabled = true
			chess_clock.set_turn(true)
			chess_clock.pause()
		else:
			chess_clock.is_enabled = false
		_update_active_clock_style()



	if avatar_rect and avatar_rect.has_method("set_expression"):

		avatar_rect.set_expression("explicando", false)



	last_speech_text = "¡Hola Lyanna! Juguemos una partida completa. ¡Tú juegas con las blancas!"

	_speak_voice(last_speech_text)

	_apply_turn_coaching()



func _get_difficulty_name() -> String:

	match bot_difficulty:

		1: return "Fácil (Pollito Principiante ~700)"

		2: return "Medio (Pollito Aprendiz ~1200)"

		3: return "Intermedio (Profe Pollito ~1700)"

		4: return "Maestro (Pollito Maestro ~2200)"

		5: return "Gran Maestro (Pollito GM ~2600+)"

	return "Intermedio"



func _update_difficulty_ui() -> void:

	if diff_button:
		var btn_label = "🎯 Nivel: 🐔 Profe Pollito (~1700) ▾"
		match bot_difficulty:
			1: btn_label = "🎯 Nivel: 🐣 Fácil (~700) ▾"
			2: btn_label = "🎯 Nivel: 🐥 Medio (~1200) ▾"
			3: btn_label = "🎯 Nivel: 🐔 Profe Pollito (~1700) ▾"
			4: btn_label = "🎯 Nivel: 🦅 Maestro (~2200) ▾"
			5: btn_label = "🎯 Nivel: 👑 Gran Maestro (~2600+) ▾"
		diff_button.text = btn_label

	if lesson_badge:

		var badge_str = "🐣 FÁCIL (PRINCIPIANTE)"

		match bot_difficulty:

			1: badge_str = "🐣 FÁCIL (PRINCIPIANTE)"

			2: badge_str = "🐥 MEDIO (APRENDIZ)"

			3: badge_str = "🐔 PROFE (INTERMEDIO)"

			4: badge_str = "🦅 MAESTRO (AVANZADO)"

			5: badge_str = "👑 GRAN MAESTRO (ÉLITE)"

		lesson_badge.text = badge_str

	if lesson_subtitle:

		var turn_num = chess_board.rules.fullmove_number if chess_board and chess_board.rules else 1

		var diff_short = "Fácil"

		match bot_difficulty:

			1: diff_short = "Fácil"

			2: diff_short = "Medio"

			3: diff_short = "Profe"

			4: diff_short = "Maestro"

			5: diff_short = "Gran Maestro"

		lesson_subtitle.text = "Nivel: %s • Turno %d" % [diff_short, turn_num]

	_update_hint_button_state()

	_update_match_control_buttons()



func cycle_difficulty() -> void:
	if is_match_started:
		return

	bot_difficulty += 1
	if bot_difficulty > 5:
		bot_difficulty = 1

	_update_difficulty_ui()

	if bot_difficulty >= 4 and clock_toggle and clock_toggle.button_pressed:
		set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] ¡Dificultad ajustada a [b]%s[/b]! ⏱️ Modo torneo activo: tras mover tu pieza, deberás pulsar tu reloj o presionar [b][Espacio][/b] para pasar el turno." % _get_difficulty_name())
	else:
		set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] ¡Dificultad ajustada a [b]%s[/b]!" % _get_difficulty_name())

	if chess_board:

		chess_board.clear_suggestion()

	if is_player_turn and not is_match_started:

		_apply_turn_coaching()



func _on_difficulty_badge_gui_input(event: InputEvent) -> void:
	if is_match_started:
		return
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		open_difficulty_modal()



func format_algebraic_move(move_info: Dictionary, game_state: String = "") -> String:

	if move_info.is_empty():

		return ""



	if move_info.get("is_castling", false):

		var to_pos: Vector2i = move_info.get("to", Vector2i(-1, -1))

		var san = "O-O" if to_pos.x == 6 else "O-O-O"

		if game_state == "checkmate":

			san += "#"

		elif game_state == "check":

			san += "+"

		return san



	var from_pos: Vector2i = move_info.get("from", Vector2i(-1, -1))

	var to_pos: Vector2i = move_info.get("to", Vector2i(-1, -1))

	var raw_piece: String = move_info.get("piece", "")

	var is_promo: bool = move_info.get("is_promotion", false)

	var piece_type: String = "p" if is_promo else raw_piece.to_lower()

	var is_capture: bool = move_info.get("is_capture", false)

	var to_sq: String = ChessRules.vec_to_sq(to_pos)

	var from_sq: String = ChessRules.vec_to_sq(from_pos)



	var piece_letters: Dictionary = {

		"p": "",

		"n": "C",

		"b": "A",

		"r": "T",

		"q": "D",

		"k": "R"

	}



	var san: String = ""



	if piece_type == "p":

		if is_capture:

			var from_file = from_sq.substr(0, 1)

			san = from_file + "x" + to_sq

		else:

			san = to_sq



		if is_promo:

			var promo: String = move_info.get("promotion_piece", "q").to_lower()

			var promo_letter = piece_letters.get(promo, "D")

			san += "=" + promo_letter

	else:

		var p_letter: String = piece_letters.get(piece_type, "")

		san = p_letter

		if is_capture:

			san += "x" + to_sq

		else:

			san += to_sq



	if game_state == "checkmate":

		san += "#"

	elif game_state == "check":

		san += "+"



	return san



func _rebuild_history_ui() -> void:

	if not history_label: return

	history_label.text = ""

	current_turn_number = 1



	if chess_rules and not chess_rules.history_notation.is_empty() and not is_in_review_mode:

		move_history = chess_rules.history_notation.duplicate()

	elif not is_in_review_mode:

		var target_size = chess_rules.history.size() if chess_rules else 0

		while move_history.size() > target_size:

			move_history.pop_back()



	current_turn_number = int(float(move_history.size()) / 2.0) + 1



	if move_history.is_empty():

		history_label.text = "[color=#94a3b8][i]Sin movimientos aún...[/i][/color]"

		return



	var text = ""

	var i = 0

	var total_moves = move_history.size()



	while i < total_moves:

		var move_number = int(float(i) / 2.0) + 1

		text += "[color=#64748b][b]%d.[/b][/color] " % move_number



		# Jugada de blancas

		var w_idx = i + 1

		var white_san = move_history[i]

		var w_is_current = (is_in_review_mode and review_move_index == w_idx)

		if w_is_current:

			text += "[url=%d][bgcolor=#fbcfe8][color=#be185d][b]•%s•[/b][/color][/bgcolor][/url]" % [w_idx, white_san]

		elif i == total_moves - 1 and not is_in_review_mode:

			text += "[url=%d][b][color=#db2777]%s[/color][/b][/url]" % [w_idx, white_san]

		else:

			text += "[url=%d][color=#1e293b]%s[/color][/url]" % [w_idx, white_san]



		# Jugada de negras (si existe)

		if i + 1 < total_moves:

			var b_idx = i + 2

			var black_san = move_history[i + 1]

			var b_is_current = (is_in_review_mode and review_move_index == b_idx)

			if b_is_current:

				text += "   [url=%d][bgcolor=#fbcfe8][color=#be185d][b]•%s•[/b][/color][/bgcolor][/url]\n" % [b_idx, black_san]

			elif i + 1 == total_moves - 1 and not is_in_review_mode:

				text += "   [url=%d][b][color=#db2777]%s[/color][/b][/url]\n" % [b_idx, black_san]

			else:

				text += "   [url=%d][color=#1e293b]%s[/color][/url]\n" % [b_idx, black_san]

		else:

			text += "\n"



		i += 2



	history_label.text = text



	if move_history_scroll and not is_in_review_mode:

		_scroll_history_to_bottom()



func _update_move_history_display() -> void:

	_rebuild_history_ui()



func _scroll_history_to_bottom() -> void:

	if not move_history_scroll or is_in_review_mode:

		return

	await get_tree().process_frame

	if is_instance_valid(move_history_scroll):

		var vsb = move_history_scroll.get_v_scroll_bar()

		if vsb:

			move_history_scroll.set_v_scroll(int(vsb.max_value))



func _scroll_history_to_active_review_move() -> void:

	if not move_history_scroll or not is_in_review_mode or move_history.is_empty():

		return

	await get_tree().process_frame

	if not is_instance_valid(move_history_scroll):

		return

	var vsb = move_history_scroll.get_v_scroll_bar()

	if not vsb or vsb.max_value <= move_history_scroll.size.y:

		return

	if review_move_index <= 0:

		move_history_scroll.set_v_scroll(0)

		return

	var total_lines: float = maxf(1.0, ceil(float(move_history.size()) / 2.0))

	var active_line: float = float(int((review_move_index - 1) / 2))

	var line_height: float = vsb.max_value / total_lines

	var target_y: float = active_line * line_height

	var view_h: float = move_history_scroll.size.y

	var desired_scroll: int = clampi(int(target_y - (view_h * 0.4)), 0, int(vsb.max_value))

	move_history_scroll.set_v_scroll(desired_scroll)



func _on_free_play_turn_completed(move_info: Dictionary, game_state: String) -> void:

	if not chess_board or not chess_board.rules:

		return

	is_player_turn = chess_board.rules.white_to_move

	# Registrar la jugada de las Blancas en la sesión de Sparring didáctico (Nivel 1)
	if bot_difficulty == 1 and not current_sparring_session.is_empty():
		if move_info.get("is_white", true):
			var from_str = ChessRules.vec_to_sq(move_info["from"]) if move_info.get("from") is Vector2i else str(move_info.get("from", ""))
			var to_str = ChessRules.vec_to_sq(move_info["to"]) if move_info.get("to") is Vector2i else str(move_info.get("to", ""))
			current_sparring_session["last_white_move"] = from_str + to_str



	if not is_match_started:

		is_match_started = true

		if diff_button:

			diff_button.disabled = true

		_update_match_control_buttons()



	# Registrar jugada en el historial con notación algebraica y snapshot FEN

	var san = format_algebraic_move(move_info, game_state)

	if not san.is_empty():

		move_history.append(san)

		if chess_rules:

			chess_rules.history_notation.append(san)

			match_history_fens.append(chess_rules.to_fen())

		_rebuild_history_ui()



	# Iniciar cronómetro de partida y actualizar estadísticas de material y capturas

	is_match_timer_active = true

	_update_material_and_captures_ui()



	_update_difficulty_ui()



	# 1. EVALUAR ESTADOS DE FIN DE PARTIDA

	if game_state == "checkmate":

		if chess_board.rules.white_to_move:

			# Las blancas están en jaque mate -> Ganó el bot

			if lesson_title: lesson_title.text = "Jaque Mate 👑"

			set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] ¡Jaque Mate! Excelente partida Lyanna, aprendiste mucho hoy. ¡Presiona NUEVA PARTIDA para la revancha!")

			if instruction_label: instruction_label.text = "🏁 Partida finalizada"

			if avatar_rect and avatar_rect.has_method("set_expression"):

				avatar_rect.set_expression("celebrando", true)

			chess_board.set_interactive(false)

			if match_effects_overlay:

				match_effects_overlay.play_defeat_effect("feathers")

			last_speech_text = "¡Jaque Mate! Muy buena partida Lyanna. ¿Jugamos la revancha?"

			_speak_voice(last_speech_text)

			_save_current_match_to_history("defeat", "Derrota", "Jaque Mate del Rival")

		else:

			# Las negras están en jaque mate -> ¡Ganó Lyanna!

			if lesson_title: lesson_title.text = "¡JAQUE MATE! 🏆"

			set_dialogue("[color=#15803d][b]¡VICTORIA MAGISTRAL! 🌟[/b][/color]\n¡Increíble Lyanna! ¡Me diste Jaque Mate con una jugada brillante! ¡Eres una campeona del ajedrez!")

			if instruction_label: instruction_label.text = "🏆 ¡GANASTE LA PARTIDA!"

			if avatar_rect and avatar_rect.has_method("set_expression"):

				avatar_rect.set_expression("animando", true)

			chess_board.set_interactive(false)

			chess_board.play_victory_sound()

			if match_effects_overlay:

				match_effects_overlay.play_victory_effect()

			if chess_clock: chess_clock.pause()

			last_speech_text = "¡Felicidades Lyanna! ¡Me diste Jaque Mate, eres increíble!"

			_speak_voice(last_speech_text)

			_save_current_match_to_history("victory", "Victoria", "Jaque Mate a favor")

		is_match_started = false

		is_match_timer_active = false

		if diff_button:

			diff_button.disabled = false

		_update_match_control_buttons()

		if chess_clock: chess_clock.pause()

		_reset_clock_press_state()

		_unlock_review_button()

		return



	if game_state in ["stalemate", "draw_50_moves", "draw_repetition", "draw_insufficient_material"]:

		var reason_txt = "Material Insuficiente"
		if game_state == "stalemate":
			reason_txt = "Ahogado"
		elif game_state == "draw_50_moves":
			reason_txt = "Regla de 50 Movimientos"
		elif game_state == "draw_repetition":
			reason_txt = "Triple Repetición"

		if lesson_title: lesson_title.text = "¡Tablas (Empate)! 🤝"

		set_dialogue("[color=#2563eb][b]Profe Pollito:[/b][/color] ¡Empate por %s! Ninguno de los dos puede dar mate. ¡Una partida fantástica y reñida!" % reason_txt)

		if instruction_label: instruction_label.text = "🤝 Partida empatada"

		if avatar_rect and avatar_rect.has_method("set_expression"):

			avatar_rect.set_expression("explicando", true)

		chess_board.set_interactive(false)

		is_match_started = false

		is_match_timer_active = false

		if diff_button:

			diff_button.disabled = false

		_update_match_control_buttons()

		if chess_clock: chess_clock.pause()

		_reset_clock_press_state()

		_unlock_review_button()

		last_speech_text = "¡Empate! Una partida muy pareja, bien jugado Lyanna."

		_speak_voice(last_speech_text)

		_save_current_match_to_history("draw", "Tablas", "Empate por %s" % reason_txt)

		return



	# 2. CONTINUACIÓN DE PARTIDA

	if not chess_board.rules.white_to_move:
		# Acaban de mover las Blancas -> Le toca al Bot (Negras)
		if game_state == "check":
			if chess_board:
				chess_board.play_check_sound()
			if match_effects_overlay:
				match_effects_overlay.show_check_banner(true)
			if avatar_rect and avatar_rect.has_method("set_expression"):
				avatar_rect.set_expression("animando", true)

		if _is_clock_turn_press_required():
			# En Maestro / Gran Maestro: el jugador DEBE pulsar el reloj o barra espaciadora para pasar el turno
			if chess_clock and chess_clock.is_enabled:
				chess_clock.set_turn(true) # El reloj de blancas continúa corriendo
			_start_waiting_for_player_clock_press(move_info, game_state)
		else:
			# Niveles 1-3 o reloj desactivado: paso automático de turno
			if chess_clock and chess_clock.is_enabled:
				chess_clock.set_turn(false)
				_update_active_clock_style()
			_execute_bot_turn_after_clock(move_info, game_state)
	else:
		# Acaba de mover el Bot -> Le toca a Lyanna (Blancas)
		if _is_clock_turn_press_required():
			# El bot simula pulsar su reloj al terminar su movimiento
			if chess_board:
				chess_board.play_click_sound()
			_animate_clock_press(black_clock_panel)

		if chess_clock and chess_clock.is_enabled:
			chess_clock.set_turn(true)
			_update_active_clock_style()

		is_bot_thinking = false
		if not is_game_paused and not (confirm_modal_overlay and confirm_modal_overlay.visible):
			chess_board.set_interactive(true)
		_update_match_control_buttons()

		if game_state == "check":
			if chess_board:
				chess_board.play_check_sound()
			if match_effects_overlay:
				match_effects_overlay.show_check_banner(false)
			if lesson_title: lesson_title.text = "¡Estás en Jaque! ⚠️"
			set_dialogue("⚠️ [color=#dc2626][b]¡Cuidado Lyanna! Tu Rey está en jaque.[/b][/color]\nRecuerda la regla de oro del manual [b](C-P-R)[/b]:\n🗡️ [b]C[/b]apturar a la pieza atacante\n🛡️ [b]P[/b]roteger poniendo un escudo\n🏃 [b]R[/b]etirar al Rey a una casilla segura")
			if avatar_rect and avatar_rect.has_method("set_expression"):
				avatar_rect.set_expression("explicando", true)
		else:
			if lesson_title: lesson_title.text = "Tu Turno (Blancas)"
			var comment = _get_bot_commentary(move_info)
			set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] " + comment)
			if avatar_rect and avatar_rect.has_method("set_expression"):
				avatar_rect.set_expression("explicando", true)



		_update_undo_button_state()

		_apply_turn_coaching()



func _on_turn_completed(move_info: Dictionary = {}, game_state: String = "") -> void:

	_on_free_play_turn_completed(move_info, game_state)



func _is_clock_turn_press_required() -> bool:

	return bot_difficulty >= 4 and game_mode == "free_play" and (chess_clock != null and chess_clock.is_enabled)



func _start_waiting_for_player_clock_press(move_info: Dictionary, game_state: String) -> void:

	is_waiting_for_clock_press = true

	_pending_bot_move_info = move_info

	_pending_bot_game_state = game_state



	if chess_board:

		chess_board.set_interactive(false)



	if white_clock_panel:

		white_clock_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if white_player_label:

		white_player_label.text = "⏱️ ¡PULSAR!"

		white_player_label.add_theme_color_override("font_color", Color("#E11D48"))



	if instruction_label:

		instruction_label.text = "⏱️ ¡Pulsa tu reloj o presiona [Espacio] para pasar el turno!"



	var move_desc = "¡Jugada realizada!"

	if game_state == "check":

		move_desc = "¡Pusiste a mi Rey en jaque!"

	elif move_info.get("is_castling", false):

		move_desc = "¡Gran enroque!"

	elif move_info.get("is_capture", false):

		move_desc = "¡Buena captura!"



	set_dialogue("[color=#e11d48][b]⏱️ ¡Pasa el turno![/b][/color] %s Tu reloj sigue corriendo. Pulsa tu reloj o presiona la [b]Barra Espaciadora[/b] para detener tu tiempo." % move_desc)

	if avatar_rect and avatar_rect.has_method("set_expression"):

		avatar_rect.set_expression("animando", true)



	_update_active_clock_style()

	_start_clock_pulse_tween()



func _on_player_clock_pressed() -> void:

	if not is_waiting_for_clock_press:

		return

	is_waiting_for_clock_press = false



	_reset_clock_press_state()



	if chess_board:

		chess_board.play_click_sound()

	_animate_clock_press(white_clock_panel)



	if chess_clock and chess_clock.is_enabled:

		chess_clock.set_turn(false) # Pasa el tiempo a las Negras

	_update_active_clock_style()



	var move_info = _pending_bot_move_info

	var game_state = _pending_bot_game_state

	_pending_bot_move_info = {}

	_pending_bot_game_state = ""



	_execute_bot_turn_after_clock(move_info, game_state)



func _on_white_clock_gui_input(event: InputEvent) -> void:

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		if is_waiting_for_clock_press and not is_game_paused and (confirm_modal_overlay == null or not confirm_modal_overlay.visible):

			_on_player_clock_pressed()

			get_viewport().set_input_as_handled()



func _start_clock_pulse_tween() -> void:

	if _clock_pulse_tween and _clock_pulse_tween.is_valid():

		_clock_pulse_tween.kill()

	if not white_clock_panel:

		return

	white_clock_panel.pivot_offset = white_clock_panel.size / 2.0

	_clock_pulse_tween = create_tween().set_loops()

	_clock_pulse_tween.tween_property(white_clock_panel, "modulate", Color(1.15, 0.9, 0.95), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_clock_pulse_tween.tween_property(white_clock_panel, "modulate", Color.WHITE, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)



func _animate_clock_press(panel: PanelContainer) -> void:

	if not is_instance_valid(panel):

		return

	panel.pivot_offset = panel.size / 2.0

	var tw = panel.create_tween()

	tw.tween_property(panel, "scale", Vector2(0.93, 0.93), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tw.tween_property(panel, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)



func _reset_clock_press_state() -> void:

	is_waiting_for_clock_press = false

	_pending_bot_move_info.clear()

	_pending_bot_game_state = ""

	if _clock_pulse_tween and _clock_pulse_tween.is_valid():

		_clock_pulse_tween.kill()

	if white_clock_panel:

		white_clock_panel.modulate = Color.WHITE

		white_clock_panel.scale = Vector2.ONE

		white_clock_panel.mouse_default_cursor_shape = Control.CURSOR_ARROW

	if white_player_label:

		white_player_label.text = "⚪ Blancas"

		white_player_label.remove_theme_color_override("font_color")



func _execute_bot_turn_after_clock(move_info: Dictionary, game_state: String) -> void:

	is_bot_thinking = true

	_update_match_control_buttons()

	if lesson_title: lesson_title.text = "Profe Pollito está pensando..."

	if chess_board:

		chess_board.set_interactive(false)

	if avatar_rect and avatar_rect.has_method("set_expression"):

		avatar_rect.set_expression("pensando", true)



	if game_state == "check":

		set_dialogue("[color=#15803d][b]¡JAQUE! ⚡[/b][/color] ¡Uy Lyanna, me tienes en jaque! Déjame buscar una buena salida...")

	elif move_info.get("is_castling", false):

		var castle_type = "corto" if move_info.get("to", Vector2i(-1, -1)).x == 6 else "largo"

		set_dialogue("[color=#15803d][b]¡ENROQUE! 🏰[/b][/color] ¡Gran jugada Lyanna! Hiciste enroque %s. Tu Rey está protegido en su castillo y tu Torre lista para jugar." % castle_type)

		if avatar_rect and avatar_rect.has_method("set_expression"):

			avatar_rect.set_expression("celebrando", true)

		last_speech_text = "¡Excelente enroque Lyanna! Tu Rey está protegido."

		_speak_voice(last_speech_text)

	elif move_info.get("is_promotion", false):

		var promo_name = "Dama"

		var pr = str(move_info.get("promotion_piece", "q")).to_lower()

		match pr:

			"q":

				promo_name = "Dama"

			"r":

				promo_name = "Torre"

			"b":

				promo_name = "Alfil"

			"n":

				promo_name = "Caballo"

		set_dialogue("[color=#15803d][b]¡CORONACIÓN! 👑[/b][/color] ¡Felicidades Lyanna! Tu peón cruzó todo el tablero y ahora es una flamante %s. ¡Gran jugada!" % promo_name)

		if avatar_rect and avatar_rect.has_method("set_expression"):

			avatar_rect.set_expression("celebrando", true)

		last_speech_text = "¡Felicidades Lyanna! Coronaste tu peón en una %s." % promo_name

		_speak_voice(last_speech_text)

	elif move_info.get("is_capture", false):

		set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] ¡Buena captura! Ahora me toca responder...")

	else:

		var think_msg = "Interesante jugada... estoy calculando mi respuesta."

		match bot_difficulty:

			1: think_msg = "Mmm... déjame ver qué pieza muevo..."

			2: think_msg = "¡Interesante! Analizando mis mejores opciones..."

			3: think_msg = "Calculando la respuesta más sólida en el tablero..."

			4: think_msg = "Evaluando planes y líneas estratégicas..."

			5: think_msg = "Calculando variantes tácticas de Gran Maestro..."

		set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] " + think_msg)



	# Cálculo asíncrono del bot en worker thread (0ms de bloqueo en hilo UI)

	if chess_board and chess_board.rules:
		var req_gen: int = _bot_think_generation
		if bot_difficulty == 1:
			ChessSparringEngine.get_sparring_move(chess_board.rules, current_sparring_session, bot, func(chosen_move: Dictionary):
				_on_bot_move_calculated(chosen_move, req_gen)
			)
		else:
			bot.get_best_move_async(chess_board.rules, bot_difficulty, func(chosen_move: Dictionary):
				_on_bot_move_calculated(chosen_move, req_gen)
			)



func _calculate_humanized_think_time(chosen_move: Dictionary) -> float:

	var base_time: float = 1.8



	# 1. Rango orgánico según el nivel / personalidad del bot

	match bot_difficulty:

		1: # 🐣 Pollito Principiante (~600-800 ELO): ritmo juguetón, pausas espontáneas

			base_time = randf_range(1.2, 2.4)

		2: # 🐥 Pollito Aprendiz (~1100-1300 ELO): ritmo tranquilo y curioso

			base_time = randf_range(1.4, 2.6)

		3: # 🐔 Profe Pollito (~1600-1800 ELO): maestro reflexivo y analítico

			base_time = randf_range(1.6, 2.8)

		4: # 🦅 Pollito Maestro (~2100-2300 ELO): ágil, seguro, buen sentido del tiempo

			base_time = randf_range(1.0, 2.0)

		5: # 👑 Pollito Gran Maestro (~2600+ ELO): relámpago de gran maestro

			base_time = randf_range(0.8, 1.5)



	# 2. Moduladores situacionales del tablero

	if chess_board and chess_board.rules:

		var rules = chess_board.rules



		# A) Apertura temprana (primeros 2 turnos completos): jugadas conocidas

		if rules.fullmove_number <= 2:

			base_time *= 0.65



		# B) Salida obligada de Jaque: decisión acotada y urgente

		elif rules.is_in_check(rules.white_to_move):

			base_time *= 0.70



		# C) Recaptura inmediata: cuando la jugada captura una pieza

		elif chosen_move.has("to"):

			var target_p = rules.get_piece_at(chosen_move["to"])

			if target_p != "":

				base_time *= 0.75



		# D) Final de partida con muy pocas piezas (<= 6 piezas totales en el tablero)

		var piece_count: int = 0

		for p in rules.board:

			if p != "":

				piece_count += 1

		if piece_count <= 6:

			base_time *= 0.80



	return clampf(base_time, 0.6, 3.2)



func _on_bot_move_calculated(chosen_move: Dictionary, req_gen: int = -1) -> void:
	var expected_gen: int = req_gen if req_gen != -1 else _bot_think_generation
	if expected_gen != _bot_think_generation:
		return

	if chosen_move.is_empty():

		is_bot_thinking = false

		return

	var delay = _calculate_humanized_think_time(chosen_move)

	# Pausa humana natural simulando pensamiento y lectura de jugada

	get_tree().create_timer(delay).timeout.connect(func():

		if expected_gen != _bot_think_generation or not is_inside_tree() or not is_instance_valid(chess_board):

			return

		while is_game_paused or (confirm_modal_overlay and confirm_modal_overlay.visible):
			await get_tree().process_frame
			if expected_gen != _bot_think_generation or not is_inside_tree() or not is_instance_valid(chess_board):
				return

		var from_sq = ChessRules.vec_to_sq(chosen_move["from"])

		var to_sq = ChessRules.vec_to_sq(chosen_move["to"])
		var promo_str = str(chosen_move.get("promo", "q"))
		if promo_str == "":
			promo_str = "q"

		if chess_board:

			chess_board.execute_bot_move(from_sq, to_sq, promo_str)

	)



# =============================================================

# ENTRENAMIENTO DIDÁCTICO Y ASISTENCIA ESCALONADA (NIVELES 1-3)

# =============================================================



func _get_piece_display_name(p: String) -> String:

	match p.to_lower():

		"p": return "Peón"

		"n": return "Caballo"

		"b": return "Alfil"

		"r": return "Torre"

		"q": return "Dama"

		"k": return "Rey"

	return "Pieza"



func _apply_turn_coaching() -> void:

	if not is_inside_tree() or not is_player_turn or is_in_review_mode or is_bot_thinking or not chess_rules:

		return



	if chess_board:

		chess_board.clear_suggestion()



	_update_hint_button_state()



	match bot_difficulty:

		1:

			_apply_level_1_guidance()

		2:

			_apply_level_2_guidance()

		3:

			_apply_level_3_guidance()

		_:

			pass



func _apply_level_1_guidance() -> void:

	if not is_inside_tree() or not is_player_turn or not chess_rules:

		return

	var req_gen: int = _bot_think_generation
	var req_fen: String = chess_rules.to_fen()
	ChessSparringEngine.get_player_guidance_step(chess_rules, current_sparring_session, bot, func(coaching: Dictionary):

		if req_gen != _bot_think_generation or not is_inside_tree() or not is_player_turn or coaching.is_empty() or not chess_rules or chess_rules.to_fen() != req_fen:

			return

		var from_sq = coaching.get("from_sq", "")
		var to_sq = coaching.get("to_sq", "")

		if chess_board and from_sq != "" and to_sq != "":

			chess_board.show_suggestion(from_sq, to_sq)

		var dialogue_text = ""
		var bot_tip = current_sparring_session.get("last_sparring_tip", "")
		if bot_tip != "":
			dialogue_text = "[color=#db2777][b]🐥 Pollito:[/b][/color] \"%s\"\n\n" % bot_tip
			current_sparring_session["last_sparring_tip"] = ""

		dialogue_text += "[color=#10b981][b]%s:[/b][/color] %s" % [coaching.get("tag", "✨ Jugada Sugerida"), coaching.get("l1", "")]
		set_dialogue(dialogue_text)

		if avatar_rect and avatar_rect.has_method("set_expression"):

			avatar_rect.set_expression("explicando", true)

	)



func _apply_level_2_guidance() -> void:

	if not is_inside_tree() or not is_player_turn or not chess_rules:

		return

	# En Nivel 2 (Aprendiz), la sugerencia es EXCLUSIVAMENTE POR TEXTO (sin flechas ni pieza fantasma)
	var req_gen: int = _bot_think_generation
	var req_fen: String = chess_rules.to_fen()
	bot.get_best_move_async(chess_rules, 4, func(best_m: Dictionary):

		if req_gen != _bot_think_generation or not is_inside_tree() or not is_player_turn or best_m.is_empty() or not chess_rules or chess_rules.to_fen() != req_fen:

			return

		var from_sq = ChessRules.vec_to_sq(best_m["from"])

		var to_sq = ChessRules.vec_to_sq(best_m["to"])

		var concept = ChessTutorConcepts.analyze_move_concept(chess_rules, from_sq, to_sq, current_match_opening)

		set_dialogue("[color=#3b82f6][b]%s (Consejo):[/b][/color] %s" % [concept["tag"], concept["l2"]])

		if avatar_rect and avatar_rect.has_method("set_expression"):

			avatar_rect.set_expression("explicando", true)

	)



func _apply_level_3_guidance() -> void:

	if not is_inside_tree() or not is_player_turn or not chess_rules:

		return

	# En Nivel 3 (Profe Pollito), modo Socrático: Pollito detecta la misma oportunidad táctica/estratégica,
	# pero NO revela la pieza ni la casilla. Solo le recuerda el concepto o pregunta socrática.
	var req_gen: int = _bot_think_generation
	var req_fen: String = chess_rules.to_fen()
	bot.get_best_move_async(chess_rules, 4, func(best_m: Dictionary):

		if req_gen != _bot_think_generation or not is_inside_tree() or not is_player_turn or best_m.is_empty() or not chess_rules or chess_rules.to_fen() != req_fen:

			return

		var from_sq = ChessRules.vec_to_sq(best_m["from"])

		var to_sq = ChessRules.vec_to_sq(best_m["to"])

		var concept = ChessTutorConcepts.analyze_move_concept(chess_rules, from_sq, to_sq, current_match_opening)

		set_dialogue("[color=#8b5cf6][b]🐔 Profe Pollito (Pista Socrática):[/b][/color] %s" % concept["l3"])

		if avatar_rect and avatar_rect.has_method("set_expression"):

			avatar_rect.set_expression("explicando", true)

	)



func _get_move_pedagogical_explanation(from_sq: String, to_sq: String) -> String:

	if not chess_rules:

		return "¡Mueve tu pieza a una casilla con ventaja!"



	var from_v = ChessRules.sq_to_vec(from_sq)

	var to_v = ChessRules.sq_to_vec(to_sq)

	var p = chess_rules.get_piece_at(from_v)

	var p_type = p.to_lower()

	var p_name = _get_piece_display_name(p_type)

	var target_p = chess_rules.get_piece_at(to_v)



	var sim = chess_rules.clone()

	var m_res = sim.make_move(from_v, to_v)



	if sim.get_game_state() == "checkmate":

		return "¡Mueve tu %s a %s para dar JAQUE MATE y ganar la partida! 🏆" % [p_name, to_sq.to_upper()]



	if sim.is_in_check(false):

		return "¡Mueve tu %s a %s para dar jaque al Rey negro! Ponlo bajo presión." % [p_name, to_sq.to_upper()]



	if m_res.get("is_castling", false):

		return "¡Enróctate a %s! Así tu Rey queda seguro y tu Torre entra activa al juego." % to_sq.to_upper()



	if target_p != "" or m_res.get("is_en_passant", false):

		var target_name = _get_piece_display_name(target_p.to_lower()) if target_p != "" else "peón al paso"

		return "¡Captura el %s en %s con tu %s! Ganarás material valioso." % [target_name, to_sq.to_upper(), p_name]



	var fullmove = chess_rules.fullmove_number

	if fullmove <= 7:

		if p_type == "p" and (to_sq in ["e4", "d4", "c4", "e3", "d3"]):

			return "Avanza tu peón a %s para controlar el centro del tablero y abrir paso a tus piezas." % to_sq.to_upper()

		elif p_type == "n":

			return "Desarrolla tu caballo a %s para luchar por el centro y proteger tus posiciones." % to_sq.to_upper()

		elif p_type == "b":

			return "Activa tu alfil a %s con una gran diagonal apuntando hacia el territorio rival." % to_sq.to_upper()



	match p_type:

		"p":

			return "Avanza tu peón a %s para ganar espacio y reforzar tu estructura." % to_sq.to_upper()

		"n":

			return "Coloca tu caballo en %s, una casilla activa y centralizada." % to_sq.to_upper()

		"b":

			return "Ubica tu alfil en %s dominando casillas clave del tablero." % to_sq.to_upper()

		"r":

			return "Mueve tu torre a %s buscando columnas abiertas." % to_sq.to_upper()

		"q":

			return "Centraliza tu dama en %s aumentando el alcance de tus ataques." % to_sq.to_upper()

		"k":

			return "Mueve tu rey a %s buscando mayor seguridad." % to_sq.to_upper()



	return "Te sugiero mover tu %s a %s para mejorar tu posición." % [p_name, to_sq.to_upper()]



func _get_level_3_strategic_tip() -> String:

	if not chess_rules:

		return ""



	var fullmove = chess_rules.fullmove_number



	if fullmove == 1:

		return "En la apertura, la clave es luchar por las 4 casillas centrales (e4, d4, e5, d5). ¡El control del centro da libertad de maniobra!"

	elif fullmove == 2:

		return "Regla de oro: desarrolla caballos antes que los alfiles y evita mover la misma pieza dos veces seguidas."

	elif fullmove == 3 or fullmove == 4:

		return "Prepara el enroque temprano. Un Rey en el centro es un blanco fácil para las piezas rivales."

	elif fullmove == 5 or fullmove == 6:

		return "No saques tu Dama demasiado pronto; si sale antes de tiempo, el rival ganará tiempos atacándola con piezas menores."



	if chess_rules.is_in_check(true):

		return "¡Estás en jaque! Recuerda el principio CPR: 1. Capturar al atacante, 2. Proteger interponiendo una pieza, o 3. Retirar el Rey."



	var bal: int = int(round(float(chess_rules.evaluate_material_balance()) / 100.0))

	if bal >= 3:

		return "Llevas ventaja material significativa (+%d). En esta posición, simplificar cambiando piezas equivalentes facilita la victoria." % bal

	elif bal <= -3:

		return "Tienes desventaja de material. Evita cambios pasivos y busca contrajuego activo atacando puntos débiles del rival."



	var total_pieces = 0

	for y in range(8):

		for x in range(8):

			var p = chess_rules.get_piece_at(Vector2i(x, y))

			if p != "" and p.to_lower() != "k":

				total_pieces += 1

	if total_pieces <= 8:

		return "¡Estamos en el final! Aquí el Rey ya no debe esconderse: debe avanzar activamente hacia el centro para guiar a los peones pasados."



	var midgame_tips = [

		"Ubica tus Torres en columnas abiertas o semiabiertas donde sus rayos tengan largo alcance.",

		"Antes de mover, pregúntate: ¿Qué amenaza la última jugada de mi oponente? La prevención evita sorpresas.",

		"Los caballos adoran los 'puestos avanzados': casillas centrales que ningún peón rival puede expulsar.",

		"Una cadena de peones sana es tu mejor escudo defensivo. Evita crear peones aislados o doblados sin compensación.",

		"Identifica cuál es tu pieza menos activa y busca la casilla ideal para incorporarla al ataque."

	]

	return midgame_tips[fullmove % midgame_tips.size()]



func _on_player_move_attempted(from_sq: String, to_sq: String, on_allow: Callable, on_cancel: Callable) -> void:

	if not chess_rules:

		on_allow.call()

		return



	# Solo en los niveles con Blunder Shield (Nivel 1 y Nivel 2)

	if bot_difficulty > 2:

		on_allow.call()

		return



	var blunder = _detect_blunder(chess_rules, from_sq, to_sq)

	if blunder.get("is_blunder", false):

		_handle_blunder_warning(from_sq, to_sq, blunder, on_allow, on_cancel)

	else:

		on_allow.call()



func _detect_blunder(rules: ChessRules, from_sq: String, to_sq: String) -> Dictionary:

	var result = {"is_blunder": false, "warning": "", "type": ""}

	if not rules:

		return result



	var from_v = ChessRules.sq_to_vec(from_sq)

	var to_v = ChessRules.sq_to_vec(to_sq)

	var moved_piece = rules.get_piece_at(from_v)

	var p_type = moved_piece.to_lower()

	var p_name = _get_piece_display_name(p_type)

	var target_piece = rules.get_piece_at(to_v)



	var piece_values = {"p": 1, "n": 3, "b": 3, "r": 5, "q": 9, "k": 1000}

	var mover_val = piece_values.get(p_type, 0)

	var is_promo = (p_type == "p" and to_v.y == 7)

	if is_promo:

		p_type = "q"

		mover_val = 9

		p_name = "Dama (coronada)"



	var captured_val = piece_values.get(target_piece.to_lower(), 0) if target_piece != "" else 0



	# Simular el movimiento del jugador

	var sim = rules.clone()

	var _move_res = sim.make_move(from_v, to_v)



	# 1. ¿Permite Mate en 1 del rival?

	var black_moves = sim.get_all_legal_moves(false)

	for bm in black_moves:

		var sim_mate = sim.clone()

		sim_mate.make_move(bm["from"], bm["to"])

		if sim_mate.get_game_state() == "checkmate":

			result["is_blunder"] = true

			result["type"] = "mate_in_1"

			result["warning"] = "⚠️ ¡Cuidado! Si juegas ahí, las piezas negras tienen un jaque mate directo en su siguiente turno."

			return result



	# 2. ¿La pieza jugada queda colgada (atacada y sin defensa suficiente)?

	var net_exchange = mover_val - captured_val

	var is_attacked_by_black = sim.is_square_attacked(to_v, false)

	var is_defended_by_white = sim.is_square_attacked(to_v, true)



	if is_attacked_by_black:

		# Caso A: Pieza de valor >= 3 completamente desprotegida

		if not is_defended_by_white and mover_val >= 3 and net_exchange >= 3:

			result["is_blunder"] = true

			result["type"] = "hanging_piece"

			result["warning"] = "⚠️ ¡Cuidado con tu %s! En %s queda desprotegida y las piezas negras pueden capturarla gratis." % [p_name, to_sq.to_upper()]

			return result



		# Caso B: Dama (9) atacada por peón o pieza menor aunque esté defendida

		if p_type == "q" and net_exchange >= 4:

			var attacked_by_pawn_or_minor = false

			# Chequear peones negros atacando to_v

			for dx in [-1, 1]:

				var p_sq = Vector2i(to_v.x + dx, to_v.y + 1)

				if ChessRules.is_on_board(p_sq) and sim.get_piece_at(p_sq) == "p":

					attacked_by_pawn_or_minor = true

					break

			if not attacked_by_pawn_or_minor:

				# Chequear caballos negros

				var knight_offsets = [

					Vector2i(1, 2), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(-2, 1),

					Vector2i(1, -2), Vector2i(2, -1), Vector2i(-1, -2), Vector2i(-2, -1)

				]

				for d in knight_offsets:

					var n_sq = to_v + d

					if ChessRules.is_on_board(n_sq) and sim.get_piece_at(n_sq) == "n":

						attacked_by_pawn_or_minor = true

						break

			if attacked_by_pawn_or_minor:

				result["is_blunder"] = true

				result["type"] = "queen_attacked_by_minor"

				result["warning"] = "⚠️ ¡Cuidado con tu Dama! En %s el rival puede capturarla con una pieza de menor valor." % to_sq.to_upper()

				return result

			elif not is_defended_by_white:

				result["is_blunder"] = true

				result["type"] = "hanging_queen"

				result["warning"] = "⚠️ ¡Cuidado con tu Dama! En %s queda sin protección frente al ataque rival." % to_sq.to_upper()

				return result



		# Caso C: Torre (5) atacada por peón

		if p_type == "r" and net_exchange >= 3:

			for dx in [-1, 1]:

				var p_sq = Vector2i(to_v.x + dx, to_v.y + 1)

				if ChessRules.is_on_board(p_sq) and sim.get_piece_at(p_sq) == "p":

					result["is_blunder"] = true

					result["type"] = "rook_attacked_by_pawn"

					result["warning"] = "⚠️ ¡Cuidado con tu Torre! En %s un peón negro puede capturarla ganando material." % to_sq.to_upper()

					return result



	# 3. ¿El movimiento desprotege a la Dama en otra casilla? (Abandono de defensa)

	if p_type != "q":

		for y in range(8):

			for x in range(8):

				var pos = Vector2i(x, y)

				if rules.get_piece_at(pos) == "Q": # Dama blanca

					var was_attacked = rules.is_square_attacked(pos, false)

					var was_defended = rules.is_square_attacked(pos, true)

					var now_attacked = sim.is_square_attacked(pos, false)

					var now_defended = sim.is_square_attacked(pos, true)

					if now_attacked and not now_defended and not (was_attacked and not was_defended):

						result["is_blunder"] = true

						result["type"] = "abandoned_queen"

						result["warning"] = "⚠️ Al mover esa pieza, dejas a tu Dama en %s desprotegida y bajo ataque." % ChessRules.vec_to_sq(pos).to_upper()

						return result



	return result



func _handle_blunder_warning(from_sq: String, to_sq: String, blunder_info: Dictionary, on_allow: Callable, on_cancel: Callable) -> void:

	if avatar_rect and avatar_rect.has_method("set_expression"):

		avatar_rect.set_expression("animando", true)



	var msg = blunder_info.get("warning", "Esta jugada parece peligrosa.")

	msg += "\n\n¿Deseas corregirla o estás jugando un sacrificio planeado?"



	var wrapped_allow = func():

		set_dialogue("[color=#ec4899][b]Profe Pollito:[/b][/color] ¡Valiente jugada! Veamos cómo se desarrolla tu estrategia.")

		on_allow.call()



	var wrapped_cancel = func():

		set_dialogue("[color=#10b981][b]Profe Pollito:[/b][/color] ¡Muy bien hecho! Es muy sabio reconsiderar antes de arriesgar una pieza.")

		on_cancel.call()



	_show_confirm_dialog(

		"⚠️ Advertencia del Profe Pollito",

		msg,

		"✨ Estoy segura de mi jugada",

		"↩️ Corregir jugada",

		wrapped_allow,

		false,

		wrapped_cancel

	)



func _get_bot_commentary(move_info: Dictionary) -> String:

	var piece_name = "mi pieza"

	var p = str(move_info.get("piece", "")).to_lower()

	match p:

		"p":

			piece_name = "mi peón"

		"n":

			piece_name = "mi caballo"

		"b":

			piece_name = "mi alfil"

		"r":

			piece_name = "mi torre"

		"q":

			piece_name = "mi dama"

		"k":

			piece_name = "mi rey"



	if move_info.get("is_castling", false):

		return "¡Me he enrocado para poner a mi Rey a salvo! Tu turno Lyanna."

	elif move_info.get("is_capture", false):

		return "He capturado con %s. ¡Tu turno, piensa tu mejor jugada!" % piece_name

	elif move_info.get("is_promotion", false):

		return "¡Mi peón ha coronado una Dama! Tu turno Lyanna."

	else:

		var to_sq = ChessRules.vec_to_sq(move_info.get("to", Vector2i(-1, -1)))

		if randf() < 0.35:

			var compliments = [

				"¡%s, eres muy {graciosa/gracioso}! Me encanta jugar ajedrez contigo. He movido %s a [b]%s[/b]." % [_get_player_name(), piece_name, to_sq.to_upper()],

				"¡Qué partida tan {divertida/divertido}, %s! He jugado %s hacia [b]%s[/b]." % [_get_player_name(), piece_name, to_sq.to_upper()],

				"¡Eres {una campeona/un campeón} pensando tus jugadas, %s! Mi respuesta es %s a [b]%s[/b]." % [_get_player_name(), piece_name, to_sq.to_upper()]

			]

			return compliments[randi() % compliments.size()]

		return "He movido %s hacia [b]%s[/b]. ¿Qué harás ahora?" % [piece_name, to_sq.to_upper()]



func _on_free_play_move_failed(from_sq: String, to_sq: String) -> void:

	var explanation = "¡Ese movimiento no está permitido por las reglas! Recuerda no dejar a tu Rey en jaque."



	# Detección y explicación pedagógica de intentos de enroque inválidos

	if chess_board and chess_board.rules:

		var r = chess_board.rules

		var is_attempting_castle = false

		var is_kingside = false



		if from_sq == "e1" and to_sq in ["g1", "h1"]:

			is_attempting_castle = true

			is_kingside = true

		elif from_sq == "e1" and to_sq in ["c1", "a1"]:

			is_attempting_castle = true

			is_kingside = false

		elif from_sq in ["h1", "a1"] and to_sq == "e1":

			is_attempting_castle = true

			is_kingside = (from_sq == "h1")



		if is_attempting_castle:

			if r.is_in_check(true):

				explanation = "¡No puedes enrocar mientras tu Rey esté en jaque! Primero debes defenderlo."

			elif is_kingside and not r.castling_rights.get("K", false):

				explanation = "¡No puedes hacer ese enroque porque tu Rey o tu Torre derecha ya se habían movido antes!"

			elif not is_kingside and not r.castling_rights.get("Q", false):

				explanation = "¡No puedes enrocar largo porque tu Rey o tu Torre izquierda ya se habían movido!"

			elif is_kingside and (r.get_piece_at_sq("f1") != "" or r.get_piece_at_sq("g1") != ""):

				explanation = "¡Para enrocar, las casillas intermedias (f1 y g1) deben estar completamente vacías!"

			elif not is_kingside and (r.get_piece_at_sq("b1") != "" or r.get_piece_at_sq("c1") != "" or r.get_piece_at_sq("d1") != ""):

				explanation = "¡Para el enroque largo, las casillas b1, c1 y d1 deben estar completamente libres!"

			elif is_kingside and (r.is_square_attacked(ChessRules.sq_to_vec("f1"), false) or r.is_square_attacked(ChessRules.sq_to_vec("g1"), false)):

				explanation = "¡El Rey no puede pasar por una casilla amenazada por el rival durante el enroque!"

			elif not is_kingside and (r.is_square_attacked(ChessRules.sq_to_vec("d1"), false) or r.is_square_attacked(ChessRules.sq_to_vec("c1"), false)):

				explanation = "¡El Rey no puede cruzar por casillas atacadas por las piezas del rival!"



	set_dialogue("[color=#dc2626][b]Profe Pollito:[/b][/color] " + explanation)

	if avatar_rect and avatar_rect.has_method("set_expression"):

		avatar_rect.set_expression("pensando", true)

	last_speech_text = explanation

	_speak_voice(last_speech_text)



# =============================================================

# MODO LECCIONES CLÁSICAS (COMPATIBILIDAD)

# =============================================================

func _load_lessons_json() -> void:

	var path = "res://data/lessons.json"

	if not FileAccess.file_exists(path):

		return

	var file = FileAccess.open(path, FileAccess.READ)

	if not file: return

	var json_text = file.get_as_text()

	file.close()

	var json = JSON.new()

	if json.parse(json_text) == OK and json.data is Dictionary:

		all_lessons_data = json.data



func _connect_signals() -> void:

	if chess_board:

		if not chess_board.move_failed.is_connected(_on_stage_error):

			chess_board.move_failed.connect(_on_stage_error)

		if not chess_board.square_clicked.is_connected(_on_board_square_clicked):

			chess_board.square_clicked.connect(_on_board_square_clicked)



	if continue_button and not continue_button.pressed.is_connected(_on_continue_button_pressed):

		continue_button.pressed.connect(_on_continue_button_pressed)



	if replay_voice_btn and not replay_voice_btn.pressed.is_connected(_on_replay_voice_pressed):

		replay_voice_btn.pressed.connect(_on_replay_voice_pressed)



	_connect_voice_manager()



func _load_lesson(lesson_id: String) -> void:

	var lessons_map: Dictionary = all_lessons_data.get("lessons", {})

	if not lessons_map.has(lesson_id):

		return

	current_lesson = lessons_map[lesson_id]

	current_stages = current_lesson.get("stages", [])

	current_stage_index = 0

	stage_completed = false

	_load_current_stage()



func _load_current_stage() -> void:

	if current_stages.is_empty() or current_stage_index >= current_stages.size():

		return



	stage_completed = false

	var stage: Dictionary = current_stages[current_stage_index]

	var initial_fen: String = stage.get("initialFen", "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")



	if chess_board:

		chess_board.set_interactive(true)

		chess_board.set_fen(initial_fen)



	var step_text: String = stage.get("pollitoSpeech", "").replace("{nombre}", "Lyanna")

	set_dialogue("[color=#db2777][b]Profe Pollito:[/b][/color] " + step_text)



	last_speech_text = step_text

	_speak_voice(step_text)



func _on_board_square_clicked(sq_name: String) -> void:

	if stage_completed: return

	var stage: Dictionary = current_stages[current_stage_index]

	var goal_type: String = stage.get("goalType", "")

	var target_square: String = stage.get("targetSquare", "")



	if goal_type == "click_square" and target_square != "":

		if sq_name == target_square:

			if chess_board:

				chess_board.highlight_square(sq_name, Color(0.06, 0.72, 0.50, 0.6))

			get_tree().create_timer(0.22).timeout.connect(func():

				_on_stage_success("", sq_name, "")

			)



func _on_stage_success(_from_sq: String, _to_sq: String, _reason: String) -> void:

	stage_completed = true

	var stage: Dictionary = current_stages[current_stage_index]

	if chess_board:

		chess_board.set_interactive(false)

		chess_board.play_victory_sound()

	if avatar_rect and avatar_rect.has_method("set_expression"):

		avatar_rect.set_expression("celebrando", true)

	var success_speech: String = stage.get("pollitoSuccess", "¡Excelente control del centro!").replace("{nombre}", "Lyanna")

	last_speech_text = success_speech

	_speak_voice(success_speech)



func _on_stage_error(_from_sq: String, _to_sq: String) -> void:

	if stage_completed: return

	if chess_board: chess_board.play_check_sound()

	if avatar_rect and avatar_rect.has_method("set_expression"):

		avatar_rect.set_expression("pensando", true)



func _on_continue_button_pressed() -> void:

	if game_mode == "free_play":

		start_new_free_play_game()

	elif stage_completed:

		current_stage_index += 1

		_load_current_stage()



func _on_replay_voice_pressed() -> void:

	_on_mute_button_pressed()



func _on_pollito_start_talking() -> void:

	if avatar_rect and avatar_rect.has_method("start_talking"):
		avatar_rect.start_talking()



func _on_pollito_stop_talking() -> void:

	if avatar_rect and avatar_rect.has_method("stop_talking"):

		avatar_rect.stop_talking()

	elif avatar_rect:

		avatar_rect.scale = Vector2.ONE

# =========================================================================
# LAYOUT RESPONSIVO Y GIRO DE PANTALLA (MOBILE PORTRAIT / LANDSCAPE)
# =========================================================================

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

	if not is_instance_valid(btn_swap_layout):
		btn_swap_layout = %BtnSwapLayout if has_node("%BtnSwapLayout") else find_child("BtnSwapLayout", true, false)
	if is_instance_valid(btn_swap_layout):
		if not btn_swap_layout.pressed.is_connected(_on_swap_layout_pressed):
			btn_swap_layout.pressed.connect(_on_swap_layout_pressed)
		btn_swap_layout.icon = load("res://assets/icons/swap_layout.svg")
		btn_swap_layout.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_swap_layout.expand_icon = true
		btn_swap_layout.text = ""

	var vp = get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)
	call_deferred("_update_responsive_layout")

var _swap_tween: Tween = null

func _on_swap_layout_pressed() -> void:
	if is_instance_valid(btn_swap_layout):
		btn_swap_layout.pivot_offset = btn_swap_layout.size * 0.5
		var btn_tw = btn_swap_layout.create_tween()
		btn_tw.tween_property(btn_swap_layout, "rotation", btn_swap_layout.rotation + PI, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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

func _on_safe_area_changed(_top: float) -> void:
	_update_responsive_layout()

func _on_viewport_size_changed() -> void:
	_update_responsive_layout()

func _update_responsive_layout(animate: bool = false) -> void:
	var vp = get_viewport()
	if not vp:
		return
	var vp_size = vp.get_visible_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		return
	var is_portrait = vp_size.y > vp_size.x
	_apply_responsive_layout(is_portrait, animate)

func _apply_responsive_layout(is_portrait: bool, animate: bool = false) -> void:
	if not is_instance_valid(main_layout):
		main_layout = %MainLayout if has_node("%MainLayout") else find_child("MainLayout", true, false)
	if not is_instance_valid(left_column):
		left_column = %LeftColumn if has_node("%LeftColumn") else find_child("LeftColumn", true, false)
	if not is_instance_valid(right_column):
		right_column = %RightColumn if has_node("%RightColumn") else find_child("RightColumn", true, false)
	if not is_instance_valid(dialogue_text):
		dialogue_text = %DialogueText if has_node("%DialogueText") else find_child("DialogueText", true, false)
	if not is_instance_valid(move_history_section):
		move_history_section = %MoveHistorySection if has_node("%MoveHistorySection") else find_child("MoveHistorySection", true, false)
	if not is_instance_valid(chess_board):
		chess_board = (%ChessBoard as ChessBoard) if has_node("%ChessBoard") else (find_child("ChessBoard", true, false) as ChessBoard)

	if not is_instance_valid(main_layout):
		return

	var safe_top: float = 0.0
	if has_node("/root/ScreenManager"):
		safe_top = get_node("/root/ScreenManager").get_safe_top_margin()
	main_layout.offset_top = safe_top + 12.0

	var is_swapped: bool = false
	var is_mob: bool = false
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if "is_board_swapped" in sm:
			is_swapped = sm.is_board_swapped
		if sm.has_method("is_mobile"):
			is_mob = sm.is_mobile()

	# Intercambio de tablero y panel (en horizontal: Izq/Der; en vertical: Arriba/Abajo)
	if is_instance_valid(left_column) and is_instance_valid(right_column):
		var target_left_idx = 1 if is_swapped else 0
		if left_column.get_index() != target_left_idx:
			if animate and is_inside_tree() and left_column.is_visible_in_tree():
				_animate_swap_slide(left_column, right_column, target_left_idx)
			else:
				main_layout.move_child(left_column, target_left_idx)

	if is_portrait:
		# MODO VERTICAL (Portrait - Teléfono en vertical)
		main_layout.vertical = true
		main_layout.add_theme_constant_override("separation", 10)

		# 1. Tablero adaptado a proporción vertical
		if is_instance_valid(left_column):
			left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
			left_column.size_flags_stretch_ratio = 1.0
			var vp = get_viewport()
			if vp:
				var vp_size = vp.get_visible_rect().size
				var max_board_dim = minf(vp_size.x - 24.0, vp_size.y * (0.44 if is_mob else 0.46))
				if max_board_dim > 100.0:
					left_column.custom_minimum_size = Vector2(0, max_board_dim)

		# 2. Panel inferior con avatar, diálogo y controles
		if is_instance_valid(right_column):
			right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
			right_column.size_flags_stretch_ratio = 1.0
			right_column.custom_minimum_size = Vector2(0, 0)

		var dialogue_bubble = find_child("DialogueBubble", true, false)
		if is_instance_valid(dialogue_bubble):
			dialogue_bubble.custom_minimum_size = Vector2(0, 110 if is_mob else 96)
		if is_instance_valid(dialogue_text):
			dialogue_text.custom_minimum_size = Vector2(0, 70 if is_mob else 60)
		var avatar_cont_p = find_child("AvatarContainer", true, false) as Control
		if is_instance_valid(avatar_cont_p):
			avatar_cont_p.custom_minimum_size = Vector2(74, 74) if is_mob else Vector2(96, 96)
		if is_instance_valid(move_history_section) and not is_in_review_mode:
			move_history_section.custom_minimum_size = Vector2(0, 80 if is_mob else 75)
		var stats_sec = right_column.find_child("MatchStatsSection", true, false) if is_instance_valid(right_column) else null
		if is_instance_valid(stats_sec):
			stats_sec.custom_minimum_size = Vector2(0, 95 if is_mob else 90)
	else:
		# MODO HORIZONTAL (Landscape - Escritorio o teléfono apaisado)
		main_layout.vertical = false
		main_layout.add_theme_constant_override("separation", 20)

		var avatar_cont_l = find_child("AvatarContainer", true, false) as Control
		if is_instance_valid(avatar_cont_l):
			avatar_cont_l.custom_minimum_size = Vector2(96, 96)

		# 1. Tablero
		if is_instance_valid(left_column):
			left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
			left_column.size_flags_stretch_ratio = 1.15
			left_column.custom_minimum_size = Vector2(0, 0)

		# 2. Panel lateral
		if is_instance_valid(right_column):
			right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
			right_column.size_flags_stretch_ratio = 0.85
			var panel_w = 520.0 if is_mob else 480.0
			right_column.custom_minimum_size = Vector2(panel_w, 0)

		var dialogue_bubble_l = find_child("DialogueBubble", true, false)
		if is_instance_valid(dialogue_bubble_l):
			dialogue_bubble_l.custom_minimum_size = Vector2(0, 168 if is_mob else 156)
		if is_instance_valid(dialogue_text):
			dialogue_text.custom_minimum_size = Vector2(0, 105 if is_mob else 95)
		if is_instance_valid(move_history_section) and not is_in_review_mode:
			move_history_section.custom_minimum_size = Vector2(0, 140 if is_mob else 130)
		var stats_sec_l = right_column.find_child("MatchStatsSection", true, false) if is_instance_valid(right_column) else null
		if is_instance_valid(stats_sec_l):
			stats_sec_l.custom_minimum_size = Vector2(0, 145 if is_mob else 140)

	_apply_mobile_scaling(is_mob)

	if is_instance_valid(chess_board) and chess_board.has_method("_update_board_layout"):
		chess_board.call_deferred("_update_board_layout")

func _apply_mobile_scaling(is_mob: bool) -> void:
	# Ajuste de tamaño de fuente para diálogo
	if is_instance_valid(dialogue_text):
		dialogue_text.add_theme_font_size_override("normal_font_size", 15 if is_mob else 14)

	# Título de turno / lección
	if is_instance_valid(lesson_title):
		lesson_title.add_theme_font_override("font", CHERRY_FONT)
		lesson_title.add_theme_font_size_override("font_size", 24 if is_mob else 20)
		lesson_title.add_theme_color_override("font_color", Color("#be185d"))

	# Botones de acción
	var act_btns = [diff_button, undo_button, new_game_button, resign_button, btn_review_match]
	var act_h = 52.0 if is_mob else 42.0
	var act_font = 16 if is_mob else 13
	for b in act_btns:
		if is_instance_valid(b):
			b.custom_minimum_size.y = act_h
			b.add_theme_font_size_override("font_size", act_font)

	if is_instance_valid(btn_review_match):
		btn_review_match.custom_minimum_size.y = 52.0 if is_mob else 44.0
		btn_review_match.add_theme_font_override("font", CHERRY_FONT)
		btn_review_match.add_theme_font_size_override("font_size", 18 if is_mob else 15)

	# Botones superiores (Pista, Silencio, Swap, Pausa)
	var top_btns = [hint_button, mute_button, btn_swap_layout, btn_pause_menu]
	var top_sz = Vector2(44, 44) if is_mob else Vector2(38, 38)
	var top_font = 20 if is_mob else 18
	for tb in top_btns:
		if is_instance_valid(tb):
			tb.custom_minimum_size = top_sz
			tb.add_theme_font_size_override("font_size", top_font)

	# Botones de revisión
	var rev_btns = [replay_first_btn, replay_prev_btn, replay_play_btn, replay_next_btn, replay_last_btn, btn_exit_review]
	var rev_h = 48.0 if is_mob else 38.0
	var rev_font = 16 if is_mob else 14
	for rb in rev_btns:
		if is_instance_valid(rb):
			rb.custom_minimum_size.y = rev_h
			rb.add_theme_font_size_override("font_size", rev_font)

	# Reloj de Ajedrez y tiempo
	var time_font = 24 if is_mob else 20
	var player_lbl_font = 13 if is_mob else 11
	if is_instance_valid(white_time_label):
		white_time_label.add_theme_font_override("font", CHERRY_FONT)
		white_time_label.add_theme_font_size_override("font_size", time_font)
	if is_instance_valid(black_time_label):
		black_time_label.add_theme_font_override("font", CHERRY_FONT)
		black_time_label.add_theme_font_size_override("font_size", time_font)
	if is_instance_valid(white_player_label):
		white_player_label.add_theme_font_size_override("font_size", player_lbl_font)
	if is_instance_valid(black_player_label):
		black_player_label.add_theme_font_size_override("font_size", player_lbl_font)
	if is_instance_valid(match_timer_label):
		match_timer_label.add_theme_font_size_override("font_size", 14 if is_mob else 11)
	if is_instance_valid(clock_toggle):
		clock_toggle.add_theme_font_size_override("font_size", 14 if is_mob else 12)
	if is_instance_valid(clock_time_option):
		clock_time_option.add_theme_font_size_override("font_size", 14 if is_mob else 12)
	if is_instance_valid(white_clock_panel):
		white_clock_panel.custom_minimum_size = Vector2(0, 48 if is_mob else 40)
	if is_instance_valid(black_clock_panel):
		black_clock_panel.custom_minimum_size = Vector2(0, 48 if is_mob else 40)

	# Historial de jugadas
	if is_instance_valid(move_history_label):
		var hist_font = (20 if is_mob else 16) if is_in_review_mode else (16 if is_mob else 12)
		move_history_label.add_theme_font_size_override("normal_font_size", hist_font)
	if is_instance_valid(history_title):
		var title_font = (20 if is_mob else 16) if is_in_review_mode else (15 if is_mob else 11)
		history_title.add_theme_font_size_override("font_size", title_font)
	if is_instance_valid(history_review_hint):
		history_review_hint.add_theme_font_size_override("font_size", 16 if is_mob else 13)

	# Puntuación y estadísticas (MatchStatsSection)
	var score_font = 16 if is_mob else 11
	var name_font = 15 if is_mob else 11
	var capt_font = 14 if is_mob else 11
	if is_instance_valid(white_score_label):
		white_score_label.add_theme_font_size_override("font_size", score_font)
	if is_instance_valid(black_score_label):
		black_score_label.add_theme_font_size_override("font_size", score_font)
	if is_instance_valid(advantage_label):
		advantage_label.add_theme_font_size_override("font_size", 15 if is_mob else 11)

	var w_name = find_child("WhiteNameLabel", true, false) as Label
	if is_instance_valid(w_name):
		w_name.add_theme_font_size_override("font_size", name_font)
	var b_name = find_child("BlackNameLabel", true, false) as Label
	if is_instance_valid(b_name):
		b_name.add_theme_font_size_override("font_size", name_font)

	var w_card = find_child("WhiteCard", true, false) as Control
	if is_instance_valid(w_card):
		w_card.custom_minimum_size = Vector2(0, 56 if is_mob else 48)
	var b_card = find_child("BlackCard", true, false) as Control
	if is_instance_valid(b_card):
		b_card.custom_minimum_size = Vector2(0, 56 if is_mob else 48)

	if is_instance_valid(white_captured_text):
		white_captured_text.add_theme_font_size_override("normal_font_size", capt_font)
		white_captured_text.custom_minimum_size.y = 26.0 if is_mob else 22.0
	if is_instance_valid(black_captured_text):
		black_captured_text.add_theme_font_size_override("normal_font_size", capt_font)
		black_captured_text.custom_minimum_size.y = 26.0 if is_mob else 22.0

	# Menú de Pausa (Escape)
	var pause_card = find_child("PauseCard", true, false) as Control
	if is_instance_valid(pause_card):
		var vp = get_viewport()
		if vp:
			var vp_sz = vp.get_visible_rect().size
			if is_mob:
				pause_card.custom_minimum_size = Vector2(minf(vp_sz.x - 32.0, 420.0), 380.0)
			else:
				pause_card.custom_minimum_size = Vector2(400, 380)

	var pause_hdr = find_child("PauseHeader", true, false) as Label
	if is_instance_valid(pause_hdr):
		pause_hdr.add_theme_font_size_override("font_size", 28 if is_mob else 26)

	var pause_sub = find_child("PauseSubtitle", true, false) as Label
	if is_instance_valid(pause_sub):
		pause_sub.add_theme_font_size_override("font_size", 14 if is_mob else 12)

	if is_instance_valid(resume_button):
		resume_button.custom_minimum_size.y = 52.0 if is_mob else 46.0
		resume_button.add_theme_font_size_override("font_size", 18 if is_mob else 16)

	if is_instance_valid(back_to_menu_button):
		back_to_menu_button.custom_minimum_size.y = 50.0 if is_mob else 44.0
		back_to_menu_button.add_theme_font_size_override("font_size", 16 if is_mob else 13)

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
