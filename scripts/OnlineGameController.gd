class_name OnlineGameController
extends Control

## OnlineGameController: Controlador exclusivo para el modo Versus Online / LAN.
## Interfaz limpia, competitiva, sin elementos didácticos ni Profe Pollito.
## Incluye: Chat integrado, Reacciones rápidas, Relojes duales, Historial de jugadas,
## Capturas y balance material (+N), Rendición, Oferta de tablas y Revancha.

const NetworkManagerScript = preload("res://scripts/NetworkManager.gd")

# Referencias principales
@onready var chess_board: ChessBoard = %ChessBoard if has_node("%ChessBoard") else find_child("ChessBoard", true, false)

# Layout Adaptativo (Modo Vertical / Horizontal para Móvil y Escritorio)
@onready var main_layout: BoxContainer = %MainLayout if has_node("%MainLayout") else find_child("MainLayout", true, false)
@onready var board_container: Control = %BoardContainer if has_node("%BoardContainer") else find_child("BoardContainer", true, false)
@onready var versus_panel_container: Control = %VersusPanelContainer if has_node("%VersusPanelContainer") else find_child("VersusPanelContainer", true, false)
@onready var content_vbox: VBoxContainer = %ContentVBox if has_node("%ContentVBox") else find_child("ContentVBox", true, false)
# Modo Revisión de Partida
var match_history_fens: Array[String] = []
var review_move_index: int = 0
var is_in_review_mode: bool = false
var is_current_match_saved: bool = false
var is_review_autoplay_active: bool = false
var review_autoplay_timer: float = 0.0
const REVIEW_AUTOPLAY_INTERVAL: float = 0.85

# Nodos de Revisión
@onready var btn_review_match_overlay: Button = %BtnReviewMatchOnline if has_node("%BtnReviewMatchOnline") else find_child("BtnReviewMatchOnline", true, false)
@onready var btn_review_match_panel: Button = %BtnReviewMatchOnlinePanel if has_node("%BtnReviewMatchOnlinePanel") else find_child("BtnReviewMatchOnlinePanel", true, false)
@onready var review_header: HBoxContainer = %ReviewHeader if has_node("%ReviewHeader") else find_child("ReviewHeader", true, false)
@onready var review_title: Label = %ReviewTitle if has_node("%ReviewTitle") else find_child("ReviewTitle", true, false)
@onready var review_status_label: Label = %ReviewStatusLabel if has_node("%ReviewStatusLabel") else find_child("ReviewStatusLabel", true, false)
@onready var btn_exit_review_online: Button = %BtnExitReviewOnline if has_node("%BtnExitReviewOnline") else find_child("BtnExitReviewOnline", true, false)
@onready var review_controls_bar: HBoxContainer = %ReviewControlsBar if has_node("%ReviewControlsBar") else find_child("ReviewControlsBar", true, false)
@onready var btn_review_first: Button = %BtnReviewFirst if has_node("%BtnReviewFirst") else find_child("BtnReviewFirst", true, false)
@onready var btn_review_prev: Button = %BtnReviewPrev if has_node("%BtnReviewPrev") else find_child("BtnReviewPrev", true, false)
@onready var btn_review_play: Button = %BtnReviewPlay if has_node("%BtnReviewPlay") else find_child("BtnReviewPlay", true, false)
@onready var btn_review_next: Button = %BtnReviewNext if has_node("%BtnReviewNext") else find_child("BtnReviewNext", true, false)
@onready var btn_review_last: Button = %BtnReviewLast if has_node("%BtnReviewLast") else find_child("BtnReviewLast", true, false)

@onready var opponent_card_wrapper: Control = %OpponentCardWrapper if has_node("%OpponentCardWrapper") else find_child("OpponentCardWrapper", true, false)
@onready var opponent_card: Control = %OpponentCard if has_node("%OpponentCard") else find_child("OpponentCard", true, false)
@onready var player_card: Control = %PlayerCard if has_node("%PlayerCard") else find_child("PlayerCard", true, false)
@onready var history_panel: Control = %HistoryPanel if has_node("%HistoryPanel") else find_child("HistoryPanel", true, false)
@onready var chat_section: Control = %ChatSection if has_node("%ChatSection") else find_child("ChatSection", true, false)
@onready var sep1: Control = %Sep1 if has_node("%Sep1") else find_child("Sep1", true, false)
@onready var sep2: Control = %Sep2 if has_node("%Sep2") else find_child("Sep2", true, false)
@onready var btn_swap_layout_online: Button = %BtnSwapLayoutOnline if has_node("%BtnSwapLayoutOnline") else find_child("BtnSwapLayoutOnline", true, false)
@onready var btn_swap_layout_review_online: Button = %BtnSwapLayoutReviewOnline if has_node("%BtnSwapLayoutReviewOnline") else find_child("BtnSwapLayoutReviewOnline", true, false)


# Ficha del Rival (Arriba)
@onready var opponent_name_label: Label = %OpponentNameLabel if has_node("%OpponentNameLabel") else find_child("OpponentNameLabel", true, false)
@onready var opponent_status_label: Label = %OpponentStatusLabel if has_node("%OpponentStatusLabel") else find_child("OpponentStatusLabel", true, false)
@onready var opponent_color_badge: Label = %OpponentColorBadge if has_node("%OpponentColorBadge") else find_child("OpponentColorBadge", true, false)
@onready var opponent_clock_panel: PanelContainer = %OpponentClockPanel if has_node("%OpponentClockPanel") else find_child("OpponentClockPanel", true, false)
@onready var opponent_time_label: Label = %OpponentTimeLabel if has_node("%OpponentTimeLabel") else find_child("OpponentTimeLabel", true, false)
@onready var opponent_captured_label: RichTextLabel = %OpponentCapturedLabel if has_node("%OpponentCapturedLabel") else find_child("OpponentCapturedLabel", true, false)
@onready var opponent_score_label: Label = %OpponentScoreLabel if has_node("%OpponentScoreLabel") else find_child("OpponentScoreLabel", true, false)

# Estado central e Historial de Jugadas
@onready var turn_status_badge: Label = %TurnStatusBadge if has_node("%TurnStatusBadge") else find_child("TurnStatusBadge", true, false)
@onready var move_history_label: RichTextLabel = %MoveHistoryLabel if has_node("%MoveHistoryLabel") else find_child("MoveHistoryLabel", true, false)
@onready var move_history_scroll: ScrollContainer = %MoveHistoryScroll if has_node("%MoveHistoryScroll") else find_child("MoveHistoryScroll", true, false)

# Chat Integrado y Reacciones Rápidas
@onready var chat_history_label: RichTextLabel = %ChatHistoryLabel if has_node("%ChatHistoryLabel") else find_child("ChatHistoryLabel", true, false)
@onready var chat_history_scroll: ScrollContainer = %ChatHistoryScroll if has_node("%ChatHistoryScroll") else find_child("ChatHistoryScroll", true, false)
@onready var chat_input: LineEdit = %ChatInput if has_node("%ChatInput") else find_child("ChatInput", true, false)
@onready var btn_chat_send: Button = %BtnChatSend if has_node("%BtnChatSend") else find_child("BtnChatSend", true, false)
@onready var btn_quick_hello: Button = %BtnQuickHello if has_node("%BtnQuickHello") else find_child("BtnQuickHello", true, false)
@onready var btn_quick_good: Button = %BtnQuickGood if has_node("%BtnQuickGood") else find_child("BtnQuickGood", true, false)
@onready var btn_quick_oops: Button = %BtnQuickOops if has_node("%BtnQuickOops") else find_child("BtnQuickOops", true, false)
@onready var btn_quick_gg: Button = %BtnQuickGG if has_node("%BtnQuickGG") else find_child("BtnQuickGG", true, false)

# Ficha del Jugador Local (Abajo)
@onready var player_name_label: Label = %PlayerNameLabel if has_node("%PlayerNameLabel") else find_child("PlayerNameLabel", true, false)
@onready var player_color_badge: Label = %PlayerColorBadge if has_node("%PlayerColorBadge") else find_child("PlayerColorBadge", true, false)
@onready var player_clock_panel: PanelContainer = %PlayerClockPanel if has_node("%PlayerClockPanel") else find_child("PlayerClockPanel", true, false)
@onready var player_time_label: Label = %PlayerTimeLabel if has_node("%PlayerTimeLabel") else find_child("PlayerTimeLabel", true, false)
@onready var player_captured_label: RichTextLabel = %PlayerCapturedLabel if has_node("%PlayerCapturedLabel") else find_child("PlayerCapturedLabel", true, false)
@onready var player_score_label: Label = %PlayerScoreLabel if has_node("%PlayerScoreLabel") else find_child("PlayerScoreLabel", true, false)
@onready var btn_resign: Button = %BtnResign if has_node("%BtnResign") else find_child("BtnResign", true, false)
@onready var btn_offer_draw: Button = %BtnOfferDraw if has_node("%BtnOfferDraw") else find_child("BtnOfferDraw", true, false)
@onready var btn_pause_menu: Button = %BtnPauseMenu if has_node("%BtnPauseMenu") else find_child("BtnPauseMenu", true, false)

# Modales de interacción
@onready var resign_confirm_overlay: Control = %ResignConfirmOverlay if has_node("%ResignConfirmOverlay") else find_child("ResignConfirmOverlay", true, false)
@onready var btn_confirm_resign_yes: Button = %BtnConfirmResignYes if has_node("%BtnConfirmResignYes") else find_child("BtnConfirmResignYes", true, false)
@onready var btn_confirm_resign_no: Button = %BtnConfirmResignNo if has_node("%BtnConfirmResignNo") else find_child("BtnConfirmResignNo", true, false)

@onready var draw_offer_overlay: Control = %DrawOfferOverlay if has_node("%DrawOfferOverlay") else find_child("DrawOfferOverlay", true, false)
@onready var draw_offer_message: Label = %DrawOfferMessage if has_node("%DrawOfferMessage") else find_child("DrawOfferMessage", true, false)
@onready var btn_accept_draw: Button = %BtnAcceptDraw if has_node("%BtnAcceptDraw") else find_child("BtnAcceptDraw", true, false)
@onready var btn_decline_draw: Button = %BtnDeclineDraw if has_node("%BtnDeclineDraw") else find_child("BtnDeclineDraw", true, false)

@onready var game_over_overlay: Control = %GameOverOverlay if has_node("%GameOverOverlay") else find_child("GameOverOverlay", true, false)
@onready var game_over_title: Label = %GameOverTitle if has_node("%GameOverTitle") else find_child("GameOverTitle", true, false)
@onready var game_over_detail: Label = %GameOverDetail if has_node("%GameOverDetail") else find_child("GameOverDetail", true, false)
@onready var btn_rematch: Button = %BtnRematch if has_node("%BtnRematch") else find_child("BtnRematch", true, false)
@onready var btn_leave_match: Button = %BtnLeaveMatch if has_node("%BtnLeaveMatch") else find_child("BtnLeaveMatch", true, false)

# Menú de Pausa
@onready var pause_menu_overlay: Control = %PauseMenuOverlay if has_node("%PauseMenuOverlay") else find_child("PauseMenuOverlay", true, false)
@onready var btn_resume_game: Button = %BtnResumeGame if has_node("%BtnResumeGame") else find_child("BtnResumeGame", true, false)
@onready var btn_exit_to_main_menu: Button = %BtnExitToMainMenu if has_node("%BtnExitToMainMenu") else find_child("BtnExitToMainMenu", true, false)

# Variables de Estado de Juego
var chess_clock: ChessClock = ChessClock.new()
var is_my_turn: bool = false
var my_color: String = "w"
var opponent_color: String = "b"
var my_name: String = "Jugador"
var opponent_name: String = "Rival"
var is_game_over: bool = false
var match_moves: Array[String] = []
var move_count: int = 0
var draw_offer_pending_by_me: bool = false
var rematch_offered_by_me: bool = false
var rematch_offered_by_opponent: bool = false
var chat_log: String = ""
var match_duration_seconds: float = 0.0

# Variables para Compensación por Tiempo Real de Pensamiento (Lag Compensation)
var turn_start_ticks: int = 0
var turn_start_clock_time: float = 0.0
var _opponent_timeout_pending: bool = false
var _is_portrait_mode: bool = false
var style_card_portrait: StyleBoxFlat

# Estilos visuales de reloj
var style_clock_active: StyleBoxFlat
var style_clock_inactive: StyleBoxFlat
var style_clock_critical: StyleBoxFlat

func _ready() -> void:
	_init_clock_styles()
	_setup_black_text_styles()
	_setup_overlay_z_indices()
	_setup_network_connections()
	_setup_ui_signals()
	_setup_responsive_layout()
	_start_versus_game()

func _process(delta: float) -> void:
	if is_in_review_mode and is_review_autoplay_active:
		review_autoplay_timer += delta
		if review_autoplay_timer >= REVIEW_AUTOPLAY_INTERVAL:
			review_autoplay_timer = 0.0
			if review_move_index < match_moves.size():
				_jump_to_review_move(review_move_index + 1)
			else:
				_stop_review_autoplay()

	if not is_game_over:
		if chess_clock.is_enabled and chess_clock.is_running:
			chess_clock.update(delta)
		elif not chess_clock.is_enabled:
			match_duration_seconds += delta
			_update_stopwatch_display(match_duration_seconds)

# =========================================================================
# INICIALIZACIÓN DE LA PARTIDA VERSUS
# =========================================================================

func _start_versus_game() -> void:
	is_current_match_saved = false
	var nm = _get_nm()
	if nm:
		my_name = nm.my_player_name
		opponent_name = nm.opponent_name
		my_color = nm.my_color
		opponent_color = nm.opponent_color
		var time_mins = nm.time_control_minutes
		if time_mins > 0:
			chess_clock.is_enabled = true
			chess_clock.reset(float(time_mins) * 60.0)
		else:
			chess_clock.is_enabled = false
	else:
		# Fallback modo pruebas si se corre directo la escena
		my_name = "Jugador 1"
		opponent_name = "Jugador 2"
		my_color = "w"
		opponent_color = "b"
		chess_clock.is_enabled = true
		chess_clock.reset(300.0)

	is_game_over = false
	match_moves.clear()
	match_history_fens.clear()
	if is_in_review_mode:
		_exit_versus_review_mode()
	if btn_review_match_overlay:
		btn_review_match_overlay.visible = false
		btn_review_match_overlay.disabled = true
	if btn_review_match_panel:
		btn_review_match_panel.visible = false
		btn_review_match_panel.disabled = true
	if chess_board and chess_board.rules:
		match_history_fens.append(chess_board.rules.to_fen())
	move_count = 0
	match_duration_seconds = 0.0
	draw_offer_pending_by_me = false
	rematch_offered_by_me = false
	rematch_offered_by_opponent = false

	# Nombres y Colores en UI
	if player_name_label:
		player_name_label.text = my_name
	if opponent_name_label:
		opponent_name_label.text = opponent_name
	if opponent_status_label:
		opponent_status_label.text = "🟢 En línea"

	if player_color_badge:
		player_color_badge.text = "⚪ Blancas" if my_color == "w" else "⚫ Negras"
	if opponent_color_badge:
		opponent_color_badge.text = "⚫ Negras" if my_color == "w" else "⚪ Blancas"

	# Orientación del tablero: Si eres Negras, el tablero se voltea
	if chess_board:
		chess_board.set_flipped(my_color == "b")
		chess_board.player_is_white = (my_color == "w")
		if chess_board.has_method("set_player_color"):
			chess_board.set_player_color(my_color)
		chess_board.reset_board()

	# El turno inicial siempre es de Blancas
	is_my_turn = (my_color == "w")
	_opponent_timeout_pending = false
	if is_my_turn:
		turn_start_ticks = Time.get_ticks_msec()
		turn_start_clock_time = chess_clock.white_time
	else:
		turn_start_ticks = 0
		turn_start_clock_time = chess_clock.black_time

	if chess_board:
		chess_board.set_interactive(is_my_turn)

	if chess_clock.is_enabled:
		chess_clock.set_turn(true) # Blancas mueven primero
		chess_clock.start()
		_update_clock_display(chess_clock.white_time, chess_clock.black_time)
	else:
		_update_stopwatch_display(0.0)

	_update_turn_status_ui()
	_update_material_and_captures()
	_render_move_history()

	# Mensaje de bienvenida al chat
	_add_system_chat("Partida iniciada. ¡Que gane el mejor! ♟️")

	if nm and nm.has_method("flush_pending_moves"):
		nm.call_deferred("flush_pending_moves")

# =========================================================================
# VINCULACIÓN DE RED Y EVENTOS
# =========================================================================

func _get_nm() -> Node:
	if has_node("/root/NetworkManager"):
		return get_node("/root/NetworkManager")
	if NetworkManagerScript.instance:
		return NetworkManagerScript.instance
	return null

func _setup_network_connections() -> void:
	var nm = _get_nm()
	if not nm:
		return

	nm.move_received.connect(_on_network_move_received)
	nm.chat_received.connect(_on_network_chat_received)
	nm.action_received.connect(_on_network_action_received)
	nm.opponent_disconnected.connect(_on_opponent_disconnected)

func _setup_ui_signals() -> void:
	if chess_board:
		if not chess_board.turn_completed.is_connected(_on_board_turn_completed):
			chess_board.turn_completed.connect(_on_board_turn_completed)

	if chess_clock:
		chess_clock.time_updated.connect(_on_clock_time_updated)
		chess_clock.timeout.connect(_on_clock_timeout)

	# Chat
	if btn_chat_send and not btn_chat_send.pressed.is_connected(_on_send_chat_pressed):
		btn_chat_send.pressed.connect(_on_send_chat_pressed)
	if chat_input and not chat_input.text_submitted.is_connected(_on_chat_text_submitted):
		chat_input.text_submitted.connect(_on_chat_text_submitted)

	# Reacciones Rápidas
	if btn_quick_hello and not btn_quick_hello.pressed.is_connected(func(): _send_quick_reaction("¡Hola! 👋")):
		btn_quick_hello.pressed.connect(func(): _send_quick_reaction("¡Hola! 👋"))
	if btn_quick_good and not btn_quick_good.pressed.is_connected(func(): _send_quick_reaction("¡Buena jugada! 👏")):
		btn_quick_good.pressed.connect(func(): _send_quick_reaction("¡Buena jugada! 👏"))
	if btn_quick_oops and not btn_quick_oops.pressed.is_connected(func(): _send_quick_reaction("¡Ups! 😅")):
		btn_quick_oops.pressed.connect(func(): _send_quick_reaction("¡Ups! 😅"))
	if btn_quick_gg and not btn_quick_gg.pressed.is_connected(func(): _send_quick_reaction("GG / ¡Bien jugado! 🤝")):
		btn_quick_gg.pressed.connect(func(): _send_quick_reaction("GG / ¡Bien jugado! 🤝"))

	# Botones de Partida
	if btn_resign and not btn_resign.pressed.is_connected(_open_resign_confirm):
		btn_resign.pressed.connect(_open_resign_confirm)
	if btn_offer_draw and not btn_offer_draw.pressed.is_connected(_on_offer_draw_pressed):
		btn_offer_draw.pressed.connect(_on_offer_draw_pressed)
	if btn_pause_menu and not btn_pause_menu.pressed.is_connected(_toggle_pause_menu):
		btn_pause_menu.pressed.connect(_toggle_pause_menu)

	# Modal Rendición
	if btn_confirm_resign_yes and not btn_confirm_resign_yes.pressed.is_connected(_on_confirm_resign):
		btn_confirm_resign_yes.pressed.connect(_on_confirm_resign)
	if btn_confirm_resign_no and not btn_confirm_resign_no.pressed.is_connected(_close_resign_confirm):
		btn_confirm_resign_no.pressed.connect(_close_resign_confirm)

	# Modal Tablas
	if btn_accept_draw and not btn_accept_draw.pressed.is_connected(_on_accept_draw):
		btn_accept_draw.pressed.connect(_on_accept_draw)
	if btn_decline_draw and not btn_decline_draw.pressed.is_connected(_on_decline_draw):
		btn_decline_draw.pressed.connect(_on_decline_draw)

	# Modal Fin de Partida
	if btn_rematch and not btn_rematch.pressed.is_connected(_on_rematch_pressed):
		btn_rematch.pressed.connect(_on_rematch_pressed)
	if btn_leave_match and not btn_leave_match.pressed.is_connected(_on_leave_match_pressed):
		btn_leave_match.pressed.connect(_on_leave_match_pressed)
	var swap_tex = load("res://assets/icons/swap_layout.svg")
	if btn_swap_layout_online:
		btn_swap_layout_online.icon = swap_tex
		btn_swap_layout_online.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_swap_layout_online.expand_icon = true
		btn_swap_layout_online.text = ""
		if not btn_swap_layout_online.pressed.is_connected(_on_swap_layout_pressed):
			btn_swap_layout_online.pressed.connect(_on_swap_layout_pressed)
	if btn_swap_layout_review_online:
		btn_swap_layout_review_online.icon = swap_tex
		btn_swap_layout_review_online.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_swap_layout_review_online.expand_icon = true
		btn_swap_layout_review_online.text = ""
		if not btn_swap_layout_review_online.pressed.is_connected(_on_swap_layout_pressed):
			btn_swap_layout_review_online.pressed.connect(_on_swap_layout_pressed)
	# Botones del Modo Revisión
	if btn_review_match_overlay and not btn_review_match_overlay.pressed.is_connected(_enter_versus_review_mode):
		btn_review_match_overlay.pressed.connect(_enter_versus_review_mode)
	if btn_review_match_panel and not btn_review_match_panel.pressed.is_connected(_enter_versus_review_mode):
		btn_review_match_panel.pressed.connect(_enter_versus_review_mode)
	if btn_exit_review_online and not btn_exit_review_online.pressed.is_connected(_exit_versus_review_mode):
		btn_exit_review_online.pressed.connect(_exit_versus_review_mode)

	if btn_review_first and not btn_review_first.pressed.is_connected(_on_review_first_pressed):
		btn_review_first.pressed.connect(_on_review_first_pressed)
	if btn_review_prev and not btn_review_prev.pressed.is_connected(_on_review_prev_pressed):
		btn_review_prev.pressed.connect(_on_review_prev_pressed)
	if btn_review_play and not btn_review_play.pressed.is_connected(_toggle_review_autoplay):
		btn_review_play.pressed.connect(_toggle_review_autoplay)
	if btn_review_next and not btn_review_next.pressed.is_connected(_on_review_next_pressed):
		btn_review_next.pressed.connect(_on_review_next_pressed)
	if btn_review_last and not btn_review_last.pressed.is_connected(_on_review_last_pressed):
		btn_review_last.pressed.connect(_on_review_last_pressed)

	if move_history_label and not move_history_label.meta_clicked.is_connected(_on_history_meta_clicked):
		move_history_label.meta_clicked.connect(_on_history_meta_clicked)

	# Menú Pausa
	if btn_resume_game and not btn_resume_game.pressed.is_connected(_toggle_pause_menu):
		btn_resume_game.pressed.connect(_toggle_pause_menu)
	if btn_exit_to_main_menu and not btn_exit_to_main_menu.pressed.is_connected(_on_leave_match_pressed):
		btn_exit_to_main_menu.pressed.connect(_on_leave_match_pressed)

var _swap_tween: Tween = null

func _on_screen_orientation_changed(_is_p: bool) -> void:
	_update_responsive_layout()

func _on_swap_layout_pressed() -> void:
	var active_btn = btn_swap_layout_online if (btn_swap_layout_online and btn_swap_layout_online.is_visible_in_tree()) else btn_swap_layout_review_online
	if is_instance_valid(active_btn):
		active_btn.pivot_offset = active_btn.size * 0.5
		var btn_tw = active_btn.create_tween()
		btn_tw.tween_property(active_btn, "rotation", active_btn.rotation + PI, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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

	style_card_portrait = StyleBoxFlat.new()
	style_card_portrait.bg_color = Color(1.0, 1.0, 1.0, 0.98)
	style_card_portrait.border_width_left = 2
	style_card_portrait.border_width_top = 2
	style_card_portrait.border_width_right = 2
	style_card_portrait.border_width_bottom = 3
	style_card_portrait.border_color = Color(0.96, 0.82, 0.89, 1.0)
	style_card_portrait.corner_radius_top_left = 16
	style_card_portrait.corner_radius_top_right = 16
	style_card_portrait.corner_radius_bottom_right = 16
	style_card_portrait.corner_radius_bottom_left = 16
	style_card_portrait.content_margin_left = 12.0
	style_card_portrait.content_margin_top = 8.0
	style_card_portrait.content_margin_right = 12.0
	style_card_portrait.content_margin_bottom = 8.0
	style_card_portrait.shadow_color = Color(0.85, 0.4, 0.65, 0.12)
	style_card_portrait.shadow_size = 8
	style_card_portrait.shadow_offset = Vector2(0, 3)

	var vp = get_viewport()
	if vp:
		if not vp.size_changed.is_connected(_on_viewport_size_changed):
			vp.size_changed.connect(_on_viewport_size_changed)

	call_deferred("_update_responsive_layout")

func _on_viewport_size_changed() -> void:
	_update_responsive_layout()

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
	if not is_instance_valid(main_layout) or not is_instance_valid(versus_panel_container):
		return

	var safe_top: float = 0.0
	if has_node("/root/ScreenManager"):
		safe_top = get_node("/root/ScreenManager").get_safe_top_margin()
	main_layout.offset_top = safe_top + 12.0

	_is_portrait_mode = is_portrait

	var is_swapped: bool = false
	var is_mob: bool = false
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if "is_board_swapped" in sm:
			is_swapped = sm.is_board_swapped
		if sm.has_method("is_mobile"):
			is_mob = sm.is_mobile()

	if is_portrait:
		# MODO VERTICAL (Portrait - Teléfono en vertical)
		main_layout.vertical = true
		main_layout.add_theme_constant_override("separation", 8)

		# 1. Reparentar la ficha del rival a MainLayout
		if is_instance_valid(opponent_card_wrapper):
			if opponent_card_wrapper.get_parent() != main_layout:
				opponent_card_wrapper.reparent(main_layout)
			opponent_card_wrapper.add_theme_stylebox_override("panel", style_card_portrait)
			opponent_card_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			opponent_card_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		# 2. Tablero en el centro adaptado a la pantalla vertical
		if is_instance_valid(board_container):
			board_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			board_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
			board_container.size_flags_stretch_ratio = 1.0
			var vp = get_viewport()
			if vp:
				var vp_size = vp.get_visible_rect().size
				var max_board_dim = minf(vp_size.x - 24.0, vp_size.y * (0.42 if is_mob else 0.44))
				if max_board_dim > 100.0:
					board_container.custom_minimum_size = Vector2(0, max_board_dim)

		# 3. Panel versus
		versus_panel_container.custom_minimum_size = Vector2(0, 0)
		versus_panel_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		versus_panel_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		versus_panel_container.size_flags_stretch_ratio = 1.0

		# 4. En el panel: ficha del jugador, turno, historial y chat
		if is_instance_valid(content_vbox):
			content_vbox.add_theme_constant_override("separation", 6)
			if is_instance_valid(player_card) and player_card.get_parent() == content_vbox:
				content_vbox.move_child(player_card, 0)
			if is_instance_valid(turn_status_badge) and turn_status_badge.get_parent() == content_vbox:
				content_vbox.move_child(turn_status_badge, 1)
			if is_instance_valid(sep1) and sep1.get_parent() == content_vbox:
				content_vbox.move_child(sep1, 2)
			if is_instance_valid(history_panel) and history_panel.get_parent() == content_vbox:
				content_vbox.move_child(history_panel, 3)
				if not is_in_review_mode: history_panel.custom_minimum_size = Vector2(0, 72 if is_mob else 65)
			if is_instance_valid(chat_section) and chat_section.get_parent() == content_vbox:
				content_vbox.move_child(chat_section, 4)

		# Orden en MainLayout vertical según swap (Arriba/Abajo)
		if is_instance_valid(opponent_card_wrapper) and is_instance_valid(board_container) and is_instance_valid(versus_panel_container):
			if animate and is_inside_tree() and board_container.is_visible_in_tree():
				_animate_swap_slide_portrait(is_swapped)
			else:
				if not is_swapped:
					if opponent_card_wrapper.get_parent() == main_layout:
						main_layout.move_child(opponent_card_wrapper, 0)
					main_layout.move_child(board_container, 1)
					main_layout.move_child(versus_panel_container, 2)
				else:
					main_layout.move_child(versus_panel_container, 0)
					main_layout.move_child(board_container, 1)
					if opponent_card_wrapper.get_parent() == main_layout:
						main_layout.move_child(opponent_card_wrapper, 2)
	else:
		# MODO HORIZONTAL (Landscape - Escritorio o teléfono apaisado)
		main_layout.vertical = false
		main_layout.add_theme_constant_override("separation", 16)

		# 1. Regresar la ficha del rival a su lugar original dentro de ContentVBox
		if is_instance_valid(opponent_card_wrapper) and is_instance_valid(content_vbox):
			if opponent_card_wrapper.get_parent() != content_vbox:
				opponent_card_wrapper.reparent(content_vbox)
			content_vbox.move_child(opponent_card_wrapper, 0)
			opponent_card_wrapper.remove_theme_stylebox_override("panel")
			opponent_card_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			opponent_card_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		# 2. Restaurar orden original en ContentVBox
		if is_instance_valid(content_vbox):
			content_vbox.add_theme_constant_override("separation", 8)
			if is_instance_valid(sep1) and sep1.get_parent() == content_vbox:
				content_vbox.move_child(sep1, 1)
			if is_instance_valid(turn_status_badge) and turn_status_badge.get_parent() == content_vbox:
				content_vbox.move_child(turn_status_badge, 2)
			if is_instance_valid(history_panel) and history_panel.get_parent() == content_vbox:
				content_vbox.move_child(history_panel, 3)
				if not is_in_review_mode: history_panel.custom_minimum_size = Vector2(0, 118 if is_mob else 110)
			if is_instance_valid(chat_section) and chat_section.get_parent() == content_vbox:
				content_vbox.move_child(chat_section, 4)
			if is_instance_valid(sep2) and sep2.get_parent() == content_vbox:
				content_vbox.move_child(sep2, 5)
			if is_instance_valid(player_card) and player_card.get_parent() == content_vbox:
				content_vbox.move_child(player_card, 6)

		# 3. Tablero
		if is_instance_valid(board_container):
			board_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			board_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
			board_container.size_flags_stretch_ratio = 1.35
			board_container.custom_minimum_size = Vector2(0, 0)

		# 4. Panel lateral
		var panel_w = 510.0 if is_mob else 460.0
		versus_panel_container.custom_minimum_size = Vector2(panel_w, 0)
		versus_panel_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		versus_panel_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		versus_panel_container.size_flags_stretch_ratio = 1.0

		# Orden en MainLayout horizontal según swap (Izq/Der)
		if is_instance_valid(board_container) and is_instance_valid(versus_panel_container):
			var target_board_idx = 1 if is_swapped else 0
			if board_container.get_index() != target_board_idx:
				if animate and is_inside_tree() and board_container.is_visible_in_tree():
					_animate_swap_slide(board_container, versus_panel_container, target_board_idx)
				else:
					main_layout.move_child(board_container, target_board_idx)

	_apply_mobile_scaling(is_mob)

	# Notificar al tablero para que recalcule casillas según nuevas dimensiones
	if is_instance_valid(chess_board) and chess_board.has_method("_update_board_layout"):
		chess_board._update_board_layout()

func _apply_mobile_scaling(is_mob: bool) -> void:
	# Botones de acción principales
	var act_btns = [btn_resign, btn_offer_draw, btn_pause_menu, btn_review_match_panel]
	var act_h = 46.0 if is_mob else 34.0
	var act_font = 15 if is_mob else 12
	for b in act_btns:
		if is_instance_valid(b):
			b.custom_minimum_size.y = act_h
			b.add_theme_font_size_override("font_size", act_font)

	# Botones de swap
	if is_instance_valid(btn_swap_layout_online):
		btn_swap_layout_online.custom_minimum_size = Vector2(38, 34) if is_mob else Vector2(34, 30)
		btn_swap_layout_online.add_theme_font_size_override("font_size", 18 if is_mob else 16)
	if is_instance_valid(btn_swap_layout_review_online):
		btn_swap_layout_review_online.custom_minimum_size = Vector2(38, 30) if is_mob else Vector2(34, 26)
		btn_swap_layout_review_online.add_theme_font_size_override("font_size", 16 if is_mob else 14)

	# Reacciones rápidas
	var reaction_container = find_child("ReactionGrid", true, false)
	if is_instance_valid(reaction_container):
		for child in reaction_container.get_children():
			if child is Button:
				child.custom_minimum_size = Vector2(40, 36) if is_mob else Vector2(30, 26)
				child.add_theme_font_size_override("font_size", 18 if is_mob else 14)

	# Input de chat y botón enviar
	var chat_input = find_child("ChatInput", true, false) as LineEdit
	if is_instance_valid(chat_input):
		chat_input.custom_minimum_size.y = 44.0 if is_mob else 32.0
		chat_input.add_theme_font_size_override("font_size", 15 if is_mob else 13)
	var chat_send_btn = find_child("BtnSendChat", true, false) as Button
	if is_instance_valid(chat_send_btn):
		chat_send_btn.custom_minimum_size.y = 44.0 if is_mob else 32.0
		chat_send_btn.add_theme_font_size_override("font_size", 15 if is_mob else 13)

	# Controles de revisión
	var rev_btns = [btn_review_first, btn_review_prev, btn_review_play, btn_review_next, btn_review_last, btn_exit_review_online]
	for rb in rev_btns:
		if is_instance_valid(rb):
			rb.custom_minimum_size.y = 44.0 if is_mob else 30.0
			rb.add_theme_font_size_override("font_size", 16 if is_mob else 13)

	# Relojes
	var clock_font = 28 if is_mob else 20
	if is_instance_valid(player_time_label):
		player_time_label.add_theme_font_size_override("font_size", clock_font)
	if is_instance_valid(opponent_time_label):
		opponent_time_label.add_theme_font_size_override("font_size", clock_font)
	if is_instance_valid(player_clock_panel):
		player_clock_panel.custom_minimum_size = Vector2(85, 36) if is_mob else Vector2(70, 28)
	if is_instance_valid(opponent_clock_panel):
		opponent_clock_panel.custom_minimum_size = Vector2(85, 36) if is_mob else Vector2(70, 28)

	# Historial de jugadas
	if is_instance_valid(move_history_label):
		var hist_font = (20 if is_mob else 16) if is_in_review_mode else (16 if is_mob else 12)
		move_history_label.add_theme_font_size_override("normal_font_size", hist_font)
	if is_instance_valid(review_title):
		var title_font = (20 if is_mob else 16) if is_in_review_mode else (16 if is_mob else 12)
		review_title.add_theme_font_size_override("font_size", title_font)
	if is_instance_valid(review_status_label):
		review_status_label.add_theme_font_size_override("font_size", 16 if is_mob else 12)

	# Puntuación y ventaja de material
	var score_font = 20 if is_mob else 14
	if is_instance_valid(player_score_label):
		player_score_label.add_theme_font_size_override("font_size", score_font)
	if is_instance_valid(opponent_score_label):
		opponent_score_label.add_theme_font_size_override("font_size", score_font)

	if is_instance_valid(player_captured_label):
		player_captured_label.add_theme_font_size_override("normal_font_size", 16 if is_mob else 12)
		player_captured_label.custom_minimum_size.y = 28.0 if is_mob else 24.0
	if is_instance_valid(opponent_captured_label):
		opponent_captured_label.add_theme_font_size_override("normal_font_size", 16 if is_mob else 12)
		opponent_captured_label.custom_minimum_size.y = 28.0 if is_mob else 24.0

	var p_name = find_child("PlayerNameLabel", true, false) as Label
	if is_instance_valid(p_name):
		p_name.add_theme_font_size_override("font_size", 20 if is_mob else 18)
	var opp_name = find_child("OpponentNameLabel", true, false) as Label
	if is_instance_valid(opp_name):
		opp_name.add_theme_font_size_override("font_size", 20 if is_mob else 18)

	if is_instance_valid(turn_status_badge):
		turn_status_badge.add_theme_font_size_override("font_size", 16 if is_mob else 13)
	if is_instance_valid(player_color_badge):
		player_color_badge.add_theme_font_size_override("font_size", 15 if is_mob else 13)
	if is_instance_valid(opponent_color_badge):
		opponent_color_badge.add_theme_font_size_override("font_size", 15 if is_mob else 13)

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

	# Elevación visual del tablero para que se deslice limpiamente
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

func _animate_swap_slide_portrait(is_swapped: bool) -> void:
	if _swap_tween and _swap_tween.is_valid():
		_swap_tween.kill()
		if is_instance_valid(opponent_card_wrapper): opponent_card_wrapper.scale = Vector2.ONE
		if is_instance_valid(versus_panel_container): versus_panel_container.scale = Vector2.ONE
		if is_instance_valid(board_container): board_container.scale = Vector2.ONE

	var start_pos_opp = opponent_card_wrapper.global_position if is_instance_valid(opponent_card_wrapper) else Vector2.ZERO
	var start_pos_panel = versus_panel_container.global_position if is_instance_valid(versus_panel_container) else Vector2.ZERO

	if not is_swapped:
		if opponent_card_wrapper.get_parent() == main_layout:
			main_layout.move_child(opponent_card_wrapper, 0)
		main_layout.move_child(board_container, 1)
		main_layout.move_child(versus_panel_container, 2)
	else:
		main_layout.move_child(versus_panel_container, 0)
		main_layout.move_child(board_container, 1)
		if opponent_card_wrapper.get_parent() == main_layout:
			main_layout.move_child(opponent_card_wrapper, 2)

	await get_tree().process_frame

	if not is_instance_valid(opponent_card_wrapper) or not is_instance_valid(versus_panel_container):
		return

	var target_pos_opp = opponent_card_wrapper.global_position
	var target_pos_panel = versus_panel_container.global_position

	opponent_card_wrapper.global_position = start_pos_opp
	versus_panel_container.global_position = start_pos_panel

	opponent_card_wrapper.pivot_offset = opponent_card_wrapper.size * 0.5
	versus_panel_container.pivot_offset = versus_panel_container.size * 0.5
	opponent_card_wrapper.scale = Vector2(0.95, 0.95)
	versus_panel_container.scale = Vector2(0.95, 0.95)

	if is_instance_valid(board_container):
		board_container.pivot_offset = board_container.size * 0.5
		board_container.scale = Vector2(0.97, 0.97)

	_swap_tween = create_tween()
	_swap_tween.set_parallel(true)
	_swap_tween.tween_property(opponent_card_wrapper, "global_position", target_pos_opp, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_swap_tween.tween_property(versus_panel_container, "global_position", target_pos_panel, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_swap_tween.tween_property(opponent_card_wrapper, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_swap_tween.tween_property(versus_panel_container, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_instance_valid(board_container):
		_swap_tween.tween_property(board_container, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_swap_tween.finished.connect(func():
		if is_instance_valid(opponent_card_wrapper): opponent_card_wrapper.scale = Vector2.ONE
		if is_instance_valid(versus_panel_container): versus_panel_container.scale = Vector2.ONE
		if is_instance_valid(board_container): board_container.scale = Vector2.ONE
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if resign_confirm_overlay and resign_confirm_overlay.visible:
			_close_resign_confirm()
		elif is_in_review_mode:
			_exit_versus_review_mode()
		elif not is_game_over:
			_toggle_pause_menu()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if resign_confirm_overlay and resign_confirm_overlay.visible:
				_close_resign_confirm()
				get_viewport().set_input_as_handled()
			elif not is_game_over:
				_toggle_pause_menu()
				get_viewport().set_input_as_handled()

# =========================================================================
# LÓGICA DE MOVIMIENTOS Y SINCRONIZACIÓN
# =========================================================================

func _on_board_turn_completed(move_data: Dictionary, game_state: String) -> void:
	if is_game_over:
		return

	var from_pos: Vector2i = move_data.get("from", Vector2i(-1, -1))
	var to_pos: Vector2i = move_data.get("to", Vector2i(-1, -1))
	var from_sq = ChessRules.vec_to_sq(from_pos)
	var to_sq = ChessRules.vec_to_sq(to_pos)
	var promo_piece = str(move_data.get("promotion_piece", "")).to_lower()
	var moved_piece = str(move_data.get("piece", ""))
	if moved_piece == "":
		return

	var mover_color = "w" if ChessRules.is_white_piece(moved_piece) else "b"
	var was_my_move = (mover_color == my_color)

	# Agregar al historial
	_record_move_in_history(move_data)

	# Sincronizar el turno real según ChessRules
	if chess_board:
		is_my_turn = (chess_board.rules.white_to_move == (my_color == "w"))
		chess_board.set_interactive(is_my_turn)
	else:
		is_my_turn = not was_my_move

	# Si el movimiento fue realizado por el jugador local: enviarlo por red
	if was_my_move:
		var think_duration: float = 0.0
		if turn_start_ticks > 0:
			think_duration = maxf(0.05, float(Time.get_ticks_msec() - turn_start_ticks) / 1000.0)

		# Descontar con precisión quirúrgica el tiempo real de pensamiento del jugador
		if chess_clock.is_enabled:
			if my_color == "w":
				chess_clock.white_time = maxf(0.0, turn_start_clock_time - think_duration)
			else:
				chess_clock.black_time = maxf(0.0, turn_start_clock_time - think_duration)
			_update_clock_display(chess_clock.white_time, chess_clock.black_time)

		var nm = _get_nm()
		if nm:
			var w_t = chess_clock.white_time if chess_clock.is_enabled else match_duration_seconds
			var b_t = chess_clock.black_time if chess_clock.is_enabled else match_duration_seconds
			nm.send_move(from_sq, to_sq, promo_piece, w_t, b_t, think_duration)

		# Cambiar turno en el reloj
		if chess_clock.is_enabled:
			chess_clock.set_turn(my_color == "b") # Si moví con Blancas, ahora es el turno de Negras

	else:
		# El movimiento vino del rival (ya ejecutado en el tablero)
		_opponent_timeout_pending = false

		if chess_clock.is_enabled:
			chess_clock.set_turn(my_color == "w") # Ahora es mi turno
			turn_start_clock_time = chess_clock.white_time if my_color == "w" else chess_clock.black_time

		turn_start_ticks = Time.get_ticks_msec()

	_update_turn_status_ui()
	_update_material_and_captures()

	# Verificar fin de partida según ChessRules
	if game_state == "checkmate":
		var winner_color = "w" if not chess_board.rules.white_to_move else "b"
		var winner_name = my_name if winner_color == my_color else opponent_name
		_end_game("¡Jaque Mate! 🏆", "Victoria para %s" % winner_name)
	elif game_state == "stalemate":
		_end_game("¡Tablas por Ahogado! 🤝", "El rey no tiene jugadas legales.")
	elif game_state == "draw_50_moves":
		_end_game("¡Tablas! 🤝", "Empate por regla de los 50 movimientos.")
	elif game_state == "draw_repetition":
		_end_game("¡Tablas! 🤝", "Empate por triple repetición de posición.")
	elif game_state.begins_with("draw"):
		_end_game("¡Tablas! 🤝", "Empate por material insuficiente.")

func _on_network_move_received(from_sq: String, to_sq: String, promotion: String, white_time: float, black_time: float, _think_time: float = 0.0) -> void:
	if is_game_over or not chess_board:
		return

	if chess_board.has_method("_flush_pending_animation"):
		chess_board._flush_pending_animation()

	var from_pos = ChessRules.sq_to_vec(from_sq)
	var to_pos = ChessRules.sq_to_vec(to_sq)
	if from_pos.x < 0 or from_pos.x >= 8 or from_pos.y < 0 or from_pos.y >= 8 or to_pos.x < 0 or to_pos.x >= 8 or to_pos.y < 0 or to_pos.y >= 8:
		return

	var origin_piece = chess_board.rules.get_piece_at(from_pos)
	if origin_piece == "":
		push_warning("OnlineGameController: ignorando movimiento remoto desde casilla vacía (%s -> %s)" % [from_sq, to_sq])
		return

	var is_piece_white = ChessRules.is_white_piece(origin_piece)
	if is_piece_white != chess_board.rules.white_to_move or is_piece_white == (my_color == "w"):
		push_warning("OnlineGameController: ignorando movimiento remoto fuera de turno (%s -> %s)" % [from_sq, to_sq])
		return

	var legal_moves = chess_board.rules.get_legal_moves(from_pos)
	if not legal_moves.has(to_pos):
		push_warning("OnlineGameController: ignorando movimiento remoto ilegal (%s -> %s)" % [from_sq, to_sq])
		return

	_opponent_timeout_pending = false

	# Sincronizar tiempos de reloj o cronómetro
	if chess_clock.is_enabled:
		chess_clock.white_time = white_time
		chess_clock.black_time = black_time
		_update_clock_display(white_time, black_time)
	else:
		match_duration_seconds = maxf(match_duration_seconds, white_time)
		_update_stopwatch_display(match_duration_seconds)

	# Ejecutar jugada del rival en el tablero con animación (is_bot = true para coronación directa sin abrir popup local)
	var promo_arg = promotion if promotion != "" else "q"
	chess_board.make_move(from_sq, to_sq, true, true, promo_arg)

# =========================================================================
# CHAT Y REACCIONES RÁPIDAS
# =========================================================================

func _on_send_chat_pressed() -> void:
	if not chat_input:
		return
	var text = chat_input.text.strip_edges()
	if text == "":
		return
	chat_input.text = ""
	_send_and_display_chat(text)

func _on_chat_text_submitted(text: String) -> void:
	var msg = text.strip_edges()
	if msg == "":
		return
	if chat_input:
		chat_input.text = ""
	_send_and_display_chat(msg)

func _send_quick_reaction(reaction: String) -> void:
	_send_and_display_chat(reaction)

func _send_and_display_chat(msg: String) -> void:
	var nm = _get_nm()
	if nm:
		nm.send_chat(msg)
	_add_chat_bubble(my_name, msg, true)

func _on_network_chat_received(sender: String, message: String) -> void:
	_add_chat_bubble(sender, message, false)

func _add_chat_bubble(sender: String, message: String, is_local: bool) -> void:
	if not chat_history_label:
		return

	var color_tag = "#db2777" if is_local else "#0284c7"
	var sender_display = "Tú" if is_local else sender
	var line = "[b][color=%s]%s:[/color][/b] [color=#000000]%s[/color]\n" % [color_tag, sender_display, message]
	chat_log += line
	chat_history_label.text = chat_log

	# Auto-scroll hacia abajo
	call_deferred("_scroll_chat_to_bottom")

func _add_system_chat(text: String) -> void:
	if not chat_history_label:
		return
	var line = "[color=#111827][i]ℹ️ %s[/i][/color]\n" % text
	chat_log += line
	chat_history_label.text = chat_log
	call_deferred("_scroll_chat_to_bottom")

func _scroll_chat_to_bottom() -> void:
	if chat_history_scroll:
		var v_bar = chat_history_scroll.get_v_scroll_bar()
		if v_bar:
			chat_history_scroll.scroll_vertical = int(v_bar.max_value)

# =========================================================================
# ACCIONES DE PARTIDA (RENDIRSE, TABLAS, REVANCHA)
# =========================================================================

func _open_resign_confirm() -> void:
	if is_game_over:
		return
	if resign_confirm_overlay:
		resign_confirm_overlay.visible = true

func _close_resign_confirm() -> void:
	if resign_confirm_overlay:
		resign_confirm_overlay.visible = false

func _on_confirm_resign() -> void:
	_close_resign_confirm()
	if is_game_over:
		return

	var nm = _get_nm()
	if nm:
		nm.send_action("resign")

	_end_game("Te has rendido 🏳️", "Victoria para %s" % opponent_name)

func _on_offer_draw_pressed() -> void:
	if is_game_over or draw_offer_pending_by_me:
		return

	draw_offer_pending_by_me = true
	if btn_offer_draw:
		btn_offer_draw.text = "⏳ Tablas ofrecidas"
		btn_offer_draw.disabled = true

	var nm = _get_nm()
	if nm:
		nm.send_action("draw_offer")

	_add_system_chat("Has ofrecido tablas a %s..." % opponent_name)

func _on_accept_draw() -> void:
	if draw_offer_overlay:
		draw_offer_overlay.visible = false

	var nm = _get_nm()
	if nm:
		nm.send_action("draw_accept")

	_end_game("¡Tablas acordadas! 🤝", "Ambos jugadores acordaron el empate.")

func _on_decline_draw() -> void:
	if draw_offer_overlay:
		draw_offer_overlay.visible = false

	var nm = _get_nm()
	if nm:
		nm.send_action("draw_decline")

	_add_system_chat("Rechazaste la oferta de tablas.")

func _on_rematch_pressed() -> void:
	if rematch_offered_by_opponent:
		rematch_offered_by_opponent = false
		rematch_offered_by_me = false
		var nm_acc = _get_nm()
		if nm_acc:
			nm_acc.send_action("rematch_accept")
		_add_system_chat("¡Revancha aceptada! Intercambiando bandos...")
		_swap_colors_and_restart()
		return

	if rematch_offered_by_me:
		return

	rematch_offered_by_me = true
	if btn_rematch:
		btn_rematch.text = "⏳ Esperando rival..."
		btn_rematch.disabled = true

	var nm = _get_nm()
	if nm:
		nm.send_action("rematch_offer")

	_add_system_chat("Has propuesto una revancha a %s..." % opponent_name)

func _on_leave_match_pressed() -> void:
	var nm = _get_nm()
	if nm:
		nm.leave_current_session()
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_network_action_received(action_type: String, sender: String) -> void:
	match action_type:
		"resign":
			_end_game("¡%s se ha rendido! 🏳️" % sender, "¡Victoria para ti, %s!" % my_name)

		"draw_offer":
			if not is_game_over and draw_offer_overlay:
				if draw_offer_message:
					draw_offer_message.text = "¡%s te ofrece tablas (empate)! ¿Aceptas?" % sender
				draw_offer_overlay.visible = true

		"draw_accept":
			if draw_offer_pending_by_me:
				draw_offer_pending_by_me = false
				_end_game("¡Tablas acordadas! 🤝", "%s aceptó la oferta de tablas." % sender)

		"draw_decline":
			if draw_offer_pending_by_me:
				draw_offer_pending_by_me = false
				if btn_offer_draw:
					btn_offer_draw.text = "🤝 Ofrecer Tablas"
					btn_offer_draw.disabled = false
				_add_system_chat("%s rechazó la oferta de tablas." % sender)

		"rematch_offer":
			if is_game_over:
				if rematch_offered_by_me:
					rematch_offered_by_me = false
					rematch_offered_by_opponent = false
					_add_system_chat("¡Revancha acordada! Intercambiando bandos...")
					_swap_colors_and_restart()
				else:
					rematch_offered_by_opponent = true
					_add_system_chat("¡%s propuso revancha! Presiona 'Aceptar Revancha' para jugar." % sender)
					if btn_rematch:
						btn_rematch.text = "🔄 Aceptar Revancha"
						btn_rematch.disabled = false

		"rematch_accept":
			_add_system_chat("¡Revancha aceptada! Intercambiando bandos...")
			_swap_colors_and_restart()

		"player_left":
			_add_system_chat("%s ha abandonado la sala." % sender)
			if opponent_status_label:
				opponent_status_label.text = "🔴 Desconectado"
			if not is_game_over:
				_end_game("Rival desconectado", "Victoria por abandono para %s." % my_name)

func _swap_colors_and_restart() -> void:
	if game_over_overlay:
		game_over_overlay.visible = false

	# Intercambiar colores
	var old_my_color = my_color
	my_color = "b" if old_my_color == "w" else "w"
	opponent_color = "w" if my_color == "b" else "b"

	var nm = _get_nm()
	if nm:
		nm.my_color = my_color
		nm.opponent_color = opponent_color
		if nm.has_method("reset_for_rematch"):
			nm.reset_for_rematch()

	_start_versus_game()

func _on_opponent_disconnected() -> void:
	if opponent_status_label:
		opponent_status_label.text = "🔴 Desconectado"
	_add_system_chat("Se ha perdido la conexión con %s." % opponent_name)

# =========================================================================
# GESTIÓN DE RELOJES
# =========================================================================

func _init_clock_styles() -> void:
	style_clock_active = StyleBoxFlat.new()
	style_clock_active.bg_color = Color("#fdf2f8")
	style_clock_active.border_color = Color("#ec4899")
	style_clock_active.set_border_width_all(3)
	style_clock_active.set_corner_radius_all(10)

	style_clock_inactive = StyleBoxFlat.new()
	style_clock_inactive.bg_color = Color("#f3f4f6")
	style_clock_inactive.border_color = Color("#d1d5db")
	style_clock_inactive.set_border_width_all(2)
	style_clock_inactive.set_corner_radius_all(10)

	style_clock_critical = StyleBoxFlat.new()
	style_clock_critical.bg_color = Color("#fef2f2")
	style_clock_critical.border_color = Color("#ef4444")
	style_clock_critical.set_border_width_all(3)
	style_clock_critical.set_corner_radius_all(10)

func _setup_black_text_styles() -> void:
	if chat_history_label:
		chat_history_label.add_theme_color_override("default_color", Color.BLACK)
	if move_history_label:
		move_history_label.add_theme_color_override("default_color", Color.BLACK)
	if chat_input:
		chat_input.add_theme_color_override("font_color", Color.BLACK)
		chat_input.add_theme_color_override("font_selected_color", Color.BLACK)
		chat_input.add_theme_color_override("placeholder_color", Color("#4b5563"))
		chat_input.add_theme_color_override("caret_color", Color.BLACK)
	for btn in [btn_quick_hello, btn_quick_good, btn_quick_oops, btn_quick_gg]:
		if btn:
			btn.add_theme_color_override("font_color", Color.BLACK)
			btn.add_theme_color_override("font_hover_color", Color.BLACK)
			btn.add_theme_color_override("font_pressed_color", Color.BLACK)
			btn.add_theme_color_override("font_focus_color", Color.BLACK)

func _on_clock_time_updated(white_sec: float, black_sec: float) -> void:
	_update_clock_display(white_sec, black_sec)

func _on_clock_timeout(loser_color: String) -> void:
	if is_game_over:
		return

	# Si el jugador local se quedó sin tiempo en su propia pantalla: derrota inmediata
	if loser_color == my_color:
		var winner_name = opponent_name
		_end_game("¡Tiempo agotado! ⏱️", "Victoria para %s por tiempo" % winner_name)
		return

	# Si en local el reloj del rival llega a 0: margen de gracia por latencia de red (1.5s)
	if not _opponent_timeout_pending:
		_opponent_timeout_pending = true
		get_tree().create_timer(1.5).timeout.connect(func():
			if not is_game_over and _opponent_timeout_pending and not is_my_turn:
				_opponent_timeout_pending = false
				var winner_name = my_name
				_end_game("¡Tiempo agotado! ⏱️", "Victoria para %s por tiempo" % winner_name)
		)

func _update_clock_display(white_sec: float, black_sec: float) -> void:
	var my_sec = white_sec if my_color == "w" else black_sec
	var opp_sec = black_sec if my_color == "w" else white_sec

	if player_time_label:
		player_time_label.text = ChessClock.format_time(my_sec)
	if opponent_time_label:
		opponent_time_label.text = ChessClock.format_time(opp_sec)

	# Resaltado activo e inactivo
	if player_clock_panel:
		if is_my_turn:
			player_clock_panel.add_theme_stylebox_override("panel", style_clock_critical if my_sec < 30.0 else style_clock_active)
		else:
			player_clock_panel.add_theme_stylebox_override("panel", style_clock_inactive)

	if opponent_clock_panel:
		if not is_my_turn:
			opponent_clock_panel.add_theme_stylebox_override("panel", style_clock_critical if opp_sec < 30.0 else style_clock_active)
		else:
			opponent_clock_panel.add_theme_stylebox_override("panel", style_clock_inactive)

func _update_stopwatch_display(total_seconds: float) -> void:
	var formatted = ChessClock.format_time(total_seconds)
	if player_time_label:
		player_time_label.text = formatted
	if opponent_time_label:
		opponent_time_label.text = formatted

	if player_clock_panel:
		if is_my_turn:
			player_clock_panel.add_theme_stylebox_override("panel", style_clock_active)
		else:
			player_clock_panel.add_theme_stylebox_override("panel", style_clock_inactive)

	if opponent_clock_panel:
		if not is_my_turn:
			opponent_clock_panel.add_theme_stylebox_override("panel", style_clock_active)
		else:
			opponent_clock_panel.add_theme_stylebox_override("panel", style_clock_inactive)

# =========================================================================
# MATERIAL Y PIEZAS CAPTURADAS (+N)
# =========================================================================

func _update_material_and_captures() -> void:
	if not chess_board or not chess_board.rules:
		return

	var r = chess_board.rules
	var piece_values: Dictionary = {"p": 1, "n": 3, "b": 3, "r": 5, "q": 9}
	var start_counts: Dictionary = {"q": 1, "r": 2, "b": 2, "n": 2, "p": 8}
	var piece_symbols_white: Dictionary = {"p": "♙", "n": "♘", "b": "♗", "r": "♖", "q": "♕"}
	var piece_symbols_black: Dictionary = {"p": "♟", "n": "♞", "b": "♝", "r": "♜", "q": "♛"}

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
				if ChessRules.is_white_piece(p):
					cur_w[pt] = cur_w.get(pt, 0) + 1
					w_material += val
				else:
					cur_b[pt] = cur_b.get(pt, 0) + 1
					b_material += val

	# Capturas de Blancas (piezas negras que faltan)
	var w_captures_str = ""
	for pt in ["q", "r", "b", "n", "p"]:
		var lost = max(0, start_counts.get(pt, 0) - cur_b.get(pt, 0))
		for i in range(lost):
			w_captures_str += piece_symbols_black.get(pt, "")

	# Capturas de Negras (piezas blancas que faltan)
	var b_captures_str = ""
	for pt in ["q", "r", "b", "n", "p"]:
		var lost = max(0, start_counts.get(pt, 0) - cur_w.get(pt, 0))
		for i in range(lost):
			b_captures_str += piece_symbols_white.get(pt, "")

	var advantage_white = w_material - b_material
	var my_captures = w_captures_str if my_color == "w" else b_captures_str
	var opp_captures = b_captures_str if my_color == "w" else w_captures_str
	var my_adv = advantage_white if my_color == "w" else -advantage_white
	var opp_adv = -my_adv

	if player_captured_label:
		player_captured_label.text = my_captures
	if opponent_captured_label:
		opponent_captured_label.text = opp_captures

	if player_score_label:
		player_score_label.text = ("+%d" % my_adv) if my_adv > 0 else ""
	if opponent_score_label:
		opponent_score_label.text = ("+%d" % opp_adv) if opp_adv > 0 else ""

# =========================================================================
# HISTORIAL DE JUGADAS (NOTACIÓN ALGEBRAICA)
# =========================================================================

func _record_move_in_history(move_data: Dictionary) -> void:
	move_count += 1
	var from_sq = ChessRules.vec_to_sq(move_data.get("from", Vector2i(-1, -1)))
	var to_sq = ChessRules.vec_to_sq(move_data.get("to", Vector2i(-1, -1)))
	var is_capture = move_data.get("is_capture", false)
	var is_castling = move_data.get("is_castling", false)
	var promo_piece = str(move_data.get("promotion_piece", "")).to_upper()
	var piece_char = str(move_data.get("piece", "p")).to_upper()

	var san = ""
	if is_castling:
		san = "O-O" if move_data.get("to", Vector2i(0,0)).x == 6 else "O-O-O"
	else:
		var prefix = ""
		match piece_char:
			"N": prefix = "C" # Caballo en español
			"B": prefix = "A" # Alfil
			"R": prefix = "T" # Torre
			"Q": prefix = "D" # Dama
			"K": prefix = "R" # Rey
			"P":
				if is_capture:
					prefix = from_sq.substr(0, 1) # Ej: exd5
		var sep = "x" if is_capture else ""
		san = "%s%s%s" % [prefix, sep, to_sq]
		if promo_piece != "":
			san += "=%s" % promo_piece

	if chess_board and chess_board.rules:
		var st = chess_board.rules.get_game_state()
		if st == "checkmate":
			san += "#"
		elif st == "check":
			san += "+"

	match_moves.append(san)
	if chess_board and chess_board.rules:
		match_history_fens.append(chess_board.rules.to_fen())
	_render_move_history()

func _render_move_history() -> void:
	if not move_history_label:
		return

	if match_moves.is_empty():
		move_history_label.text = "[color=#111827]Sin movimientos aún...[/color]"
		return

	var text_out = ""
	var turn_num = 1
	var i = 0
	var total_moves = match_moves.size()

	while i < total_moves:
		var w_idx = i + 1
		var w_move = match_moves[i]
		var w_str = ""
		if is_in_review_mode and review_move_index == w_idx:
			w_str = "[url=%d][bgcolor=#fbcfe8][b][color=#be185d]•%s•[/color][/b][/bgcolor][/url]" % [w_idx, w_move]
		elif is_in_review_mode:
			w_str = "[url=%d][color=#111827]%s[/color][/url]" % [w_idx, w_move]
		else:
			w_str = "[color=#111827]%s[/color]" % w_move

		var b_str = ""
		if i + 1 < total_moves:
			var b_idx = i + 2
			var b_move = match_moves[i + 1]
			if is_in_review_mode and review_move_index == b_idx:
				b_str = "[url=%d][bgcolor=#fbcfe8][b][color=#be185d]•%s•[/color][/b][/bgcolor][/url]" % [b_idx, b_move]
			elif is_in_review_mode:
				b_str = "[url=%d][color=#111827]%s[/color][/url]" % [b_idx, b_move]
			else:
				b_str = "[color=#111827]%s[/color]" % b_move

		text_out += "[b][color=#64748b]%d.[/color][/b]  %-7s  %-7s\n" % [turn_num, w_str, b_str]
		turn_num += 1
		i += 2

	move_history_label.text = text_out
	if not is_in_review_mode:
		call_deferred("_scroll_history_to_bottom")

# =========================================================================
# MODO REVISIÓN DE PARTIDA (VERSUS)
# =========================================================================


const MatchHistoryManagerScript = preload("res://scripts/MatchHistoryManager.gd")

func _get_history_mgr() -> Node:
	if is_inside_tree() and has_node("/root/MatchHistoryManager"):
		return get_node("/root/MatchHistoryManager")
	return MatchHistoryManagerScript.instance

func _save_current_versus_match_to_history(title: String, detail: String) -> void:
	if is_current_match_saved:
		return
	if match_moves.is_empty():
		return
	is_current_match_saved = true

	var full_reason = title
	if not detail.is_empty():
		full_reason += " - " + detail

	var result = "draw"
	var result_title = "Tablas"

	var low_title = title.to_lower()
	var low_detail = detail.to_lower()
	var my_low = my_name.to_lower()
	var opp_low = opponent_name.to_lower()

	if "victoria para ti" in low_detail or ("victoria para " + my_low) in low_detail or ("victoria por abandono para " + my_low) in low_detail:
		result = "victory"
		result_title = "Victoria"
	elif "te has rendido" in low_title or ("victoria para " + opp_low) in low_detail:
		result = "defeat"
		result_title = "Derrota"
	elif "tablas" in low_title or "empate" in low_detail or "tablas" in low_detail:
		result = "draw"
		result_title = "Tablas"
	elif "¡jaque mate!" in low_title:
		if ("victoria para " + my_low) in low_detail:
			result = "victory"
			result_title = "Victoria"
		else:
			result = "defeat"
			result_title = "Derrota"

	var match_data: Dictionary = {
		"mode": "versus",
		"player_name": my_name,
		"player_color": my_color,
		"opponent_name": opponent_name,
		"opponent_color": opponent_color,
		"result": result,
		"result_title": result_title,
		"reason": full_reason,
		"moves": match_moves.duplicate(),
		"fens": match_history_fens.duplicate(),
		"moves_count": match_moves.size(),
		"duration_seconds": int(match_duration_seconds)
	}

	var mhm = _get_history_mgr()
	if mhm:
		mhm.save_match(match_data)


func _enter_versus_review_mode() -> void:
	if match_moves.is_empty():
		return

	is_in_review_mode = true
	review_move_index = match_moves.size()
	_stop_review_autoplay()

	# 1. Ocultar modal flotante si estaba abierto
	if game_over_overlay:
		game_over_overlay.visible = false

	# 2. Ocultar el resto de los componentes para que el historial ocupe TODO el panel lateral
	if opponent_card_wrapper:
		opponent_card_wrapper.visible = false
	if sep1:
		sep1.visible = false
	if turn_status_badge:
		turn_status_badge.visible = false
	if chat_section:
		chat_section.visible = false
	if sep2:
		sep2.visible = false
	if player_card:
		player_card.visible = false

	# 3. Expandir HistoryPanel a todo el alto disponible
	if history_panel:
		history_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		history_panel.custom_minimum_size = Vector2(0, 0)

	# 4. Activar controles y tipografía ampliada
	var is_mob_rev: bool = false
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if sm.has_method("is_mobile"):
			is_mob_rev = sm.is_mobile()

	if review_title:
		review_title.text = "🔍 MODO REVISIÓN"
		review_title.add_theme_font_size_override("font_size", 20 if is_mob_rev else 16)
		review_title.add_theme_color_override("font_color", Color("#db2777"))

	if review_status_label:
		review_status_label.visible = true
		review_status_label.text = "Jugada %d / %d" % [review_move_index, match_moves.size()]
		review_status_label.add_theme_font_size_override("font_size", 16 if is_mob_rev else 13)

	if btn_exit_review_online:
		btn_exit_review_online.visible = true
		var mhm = _get_history_mgr()
		if mhm and mhm.open_history_on_main_menu:
			btn_exit_review_online.text = "🔙 Volver al Historial"
		else:
			btn_exit_review_online.text = "✖ Salir de Revisión"

	if btn_swap_layout_review_online:
		btn_swap_layout_review_online.visible = true

	if move_history_label:
		move_history_label.add_theme_font_size_override("normal_font_size", 20 if is_mob_rev else 16)

	if review_controls_bar:
		review_controls_bar.visible = true

	_update_versus_review_buttons_state()
	_render_move_history()
	_jump_to_review_move(review_move_index)

func _exit_versus_review_mode() -> void:
	var mhm = _get_history_mgr()
	if mhm and mhm.open_history_on_main_menu:
		mhm.clear_review_match()
		get_tree().change_scene_to_file("res://MainMenu.tscn")
		return

	is_in_review_mode = false
	_stop_review_autoplay()

	# 1. Restaurar componentes normales del panel lateral
	if opponent_card_wrapper:
		opponent_card_wrapper.visible = true
	if sep1:
		sep1.visible = true
	if turn_status_badge:
		turn_status_badge.visible = true
	if chat_section:
		chat_section.visible = true
	if sep2:
		sep2.visible = true
	if player_card:
		player_card.visible = true

	# 2. Restaurar HistoryPanel a su tamaño normal
	if history_panel:
		history_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		history_panel.custom_minimum_size = Vector2(0, 110)

	# 3. Ocultar controles de revisión
	var is_mob_exit: bool = false
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if sm.has_method("is_mobile"):
			is_mob_exit = sm.is_mobile()

	if review_title:
		review_title.text = "📜 Historial:"
		review_title.add_theme_font_size_override("font_size", 16 if is_mob_exit else 12)
		review_title.remove_theme_color_override("font_color")

	if review_status_label:
		review_status_label.visible = false

	if btn_exit_review_online:
		btn_exit_review_online.visible = false

	if btn_swap_layout_review_online:
		btn_swap_layout_review_online.visible = false

	if move_history_label:
		move_history_label.add_theme_font_size_override("normal_font_size", 16 if is_mob_exit else 12)

	if review_controls_bar:
		review_controls_bar.visible = false

	# 4. Volver a mostrar pantalla de fin de partida si la partida ya finalizó
	if is_game_over and game_over_overlay:
		game_over_overlay.visible = true

	# 5. Restaurar tablero a la posición final
	if match_history_fens.size() > 0 and is_instance_valid(chess_board):
		chess_board.set_fen(match_history_fens[match_history_fens.size() - 1])
		chess_board.set_interactive(false)

	_render_move_history()

func _jump_to_review_move(target_idx: int) -> void:
	target_idx = clampi(target_idx, 0, match_moves.size())
	review_move_index = target_idx

	if target_idx >= 0 and target_idx < match_history_fens.size():
		var target_fen = match_history_fens[target_idx]
		if chess_board:
			chess_board.set_fen(target_fen)
			chess_board.set_interactive(false)

	if review_status_label:
		if review_move_index == 0:
			review_status_label.text = "Posición inicial"
		else:
			review_status_label.text = "Jugada %d / %d" % [review_move_index, match_moves.size()]

	_update_versus_review_buttons_state()
	_render_move_history()
	_scroll_history_to_active_review_move()

func _update_versus_review_buttons_state() -> void:
	var total = match_moves.size()
	if btn_review_first:
		btn_review_first.disabled = (review_move_index <= 0)
	if btn_review_prev:
		btn_review_prev.disabled = (review_move_index <= 0)
	if btn_review_next:
		btn_review_next.disabled = (review_move_index >= total)
	if btn_review_last:
		btn_review_last.disabled = (review_move_index >= total)

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
	_jump_to_review_move(match_moves.size())

func _start_review_autoplay() -> void:
	if review_move_index >= match_moves.size():
		_jump_to_review_move(0)
	is_review_autoplay_active = true
	review_autoplay_timer = 0.0
	if btn_review_play:
		btn_review_play.text = "⏸ Pausa"

func _stop_review_autoplay() -> void:
	is_review_autoplay_active = false
	review_autoplay_timer = 0.0
	if btn_review_play:
		btn_review_play.text = "▶ Ver"

func _toggle_review_autoplay() -> void:
	if is_review_autoplay_active:
		_stop_review_autoplay()
	else:
		_start_review_autoplay()

func _scroll_history_to_active_review_move() -> void:
	if not move_history_scroll or not is_in_review_mode or match_moves.is_empty():
		return
	var vsb = move_history_scroll.get_v_scroll_bar()
	if not vsb or vsb.max_value <= move_history_scroll.size.y:
		return
	if review_move_index <= 0:
		move_history_scroll.set_v_scroll(0)
		return
	var total_lines: float = maxf(1.0, ceil(float(match_moves.size()) / 2.0))
	var active_line: float = float(int((review_move_index - 1) / 2))
	var ratio: float = clampf(active_line / total_lines, 0.0, 1.0)
	var max_scroll: float = maxf(0.0, vsb.max_value - move_history_scroll.size.y)
	move_history_scroll.set_v_scroll(int(ratio * max_scroll))

func _scroll_history_to_bottom() -> void:
	if move_history_scroll:
		var v_bar = move_history_scroll.get_v_scroll_bar()
		if v_bar:
			move_history_scroll.scroll_vertical = int(v_bar.max_value)

# =========================================================================
# ESTADO DEL TURNO Y FIN DE PARTIDA
# =========================================================================

func _update_turn_status_ui() -> void:
	if not turn_status_badge:
		return

	if is_game_over:
		return

	if is_my_turn:
		var col_name = "Blancas" if my_color == "w" else "Negras"
		turn_status_badge.text = "⚪ Tu Turno (%s)" % col_name if my_color == "w" else "⚫ Tu Turno (%s)" % col_name
		turn_status_badge.add_theme_color_override("font_color", Color("#db2777"))
	else:
		var col_name = "Negras" if my_color == "w" else "Blancas"
		turn_status_badge.text = "Pensando %s (%s)..." % [opponent_name, col_name]
		turn_status_badge.add_theme_color_override("font_color", Color("#6b7280"))

	if not chess_clock.is_enabled:
		_update_stopwatch_display(match_duration_seconds)

func _end_game(title: String, detail: String) -> void:
	is_game_over = true
	_save_current_versus_match_to_history(title, detail)
	if chess_clock.is_enabled:
		chess_clock.pause()
	if chess_board:
		chess_board.set_interactive(false)

	if turn_status_badge:
		turn_status_badge.text = title
		turn_status_badge.add_theme_color_override("font_color", Color("#15803d"))

	if game_over_overlay:
		if game_over_title:
			game_over_title.text = title
		if game_over_detail:
			game_over_detail.text = detail
		if btn_rematch:
			btn_rematch.text = "🔄 Pedir Revancha"
			btn_rematch.disabled = false
		if btn_review_match_overlay:
			btn_review_match_overlay.visible = true
			btn_review_match_overlay.disabled = false
		if btn_review_match_panel:
			btn_review_match_panel.visible = true
			btn_review_match_panel.disabled = false
		game_over_overlay.visible = true

	_add_system_chat("%s - %s" % [title, detail])

# =========================================================================
# MENÚ DE PAUSA Y PERSONALIZACIÓN
# =========================================================================

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

func _setup_overlay_z_indices() -> void:
	for overlay in [pause_menu_overlay, resign_confirm_overlay, draw_offer_overlay, game_over_overlay]:
		if overlay:
			overlay.z_index = 1000
			overlay.z_as_relative = false
			if overlay is ColorRect:
				(overlay as ColorRect).color = Color(0.09, 0.04, 0.14, 0.72)
			var p = overlay.find_child("Panel", true, false) as Control
			if p:
				_apply_uniform_modal_card_style(p)

func _toggle_pause_menu() -> void:
	if not pause_menu_overlay:
		return
	pause_menu_overlay.visible = not pause_menu_overlay.visible
	if pause_menu_overlay.visible:
		pause_menu_overlay.move_to_front()
		var p = pause_menu_overlay.find_child("Panel", true, false) as Control
		if p:
			p.pivot_offset = p.size * 0.5
			p.scale = Vector2(0.85, 0.85)
			var tw := create_tween()
			tw.tween_property(p, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if chess_board:
		chess_board.set_interactive(is_my_turn and not pause_menu_overlay.visible)
