extends Control

## MainMenu: Menú principal con gestor completo de perfiles de jugador (Nombre y Sexo)

const ProfileManagerScript = preload("res://scripts/ProfileManager.gd")
const NetworkManagerClassScript = preload("res://scripts/NetworkManager.gd")

@onready var btn_academy: Button = %BtnAcademy if has_node("%BtnAcademy") else find_child("BtnAcademy", true, false)
@onready var btn_practice_bot: Button = %BtnPracticeBot if has_node("%BtnPracticeBot") else find_child("BtnPracticeBot", true, false)
@onready var btn_online_versus: Button = %BtnOnlineVersus if has_node("%BtnOnlineVersus") else find_child("BtnOnlineVersus", true, false)
@onready var menu_card: Control = %MenuCard if has_node("%MenuCard") else find_child("MenuCard", true, false)
@onready var btn_match_history: Button = %BtnMatchHistory if has_node("%BtnMatchHistory") else find_child("BtnMatchHistory", true, false)

const MatchHistoryManagerScript = preload("res://scripts/MatchHistoryManager.gd")

func _get_mhm() -> Node:
	if is_inside_tree() and has_node("/root/MatchHistoryManager"):
		return get_node("/root/MatchHistoryManager")
	return MatchHistoryManagerScript.instance

# Modal de Historial de Partidas
@onready var match_history_overlay: Control = %MatchHistoryOverlay if has_node("%MatchHistoryOverlay") else find_child("MatchHistoryOverlay", true, false)
@onready var history_card: Control = %HistoryCard if has_node("%HistoryCard") else find_child("HistoryCard", true, false)
@onready var history_scroll_container: ScrollContainer = %HistoryScrollContainer if has_node("%HistoryScrollContainer") else find_child("HistoryScrollContainer", true, false)
@onready var history_content: VBoxContainer = %HistoryContent if has_node("%HistoryContent") else find_child("HistoryContent", true, false)
@onready var btn_close_history_modal: Button = %BtnCloseHistoryModal if has_node("%BtnCloseHistoryModal") else find_child("BtnCloseHistoryModal", true, false)
@onready var btn_clear_all_history: Button = %BtnClearAllHistory if has_node("%BtnClearAllHistory") else find_child("BtnClearAllHistory", true, false)
@onready var btn_filter_all: Button = %BtnFilterAll if has_node("%BtnFilterAll") else find_child("BtnFilterAll", true, false)
@onready var btn_filter_bots: Button = %BtnFilterBots if has_node("%BtnFilterBots") else find_child("BtnFilterBots", true, false)
@onready var btn_filter_versus: Button = %BtnFilterVersus if has_node("%BtnFilterVersus") else find_child("BtnFilterVersus", true, false)
@onready var history_list_vbox: VBoxContainer = %HistoryListVBox if has_node("%HistoryListVBox") else find_child("HistoryListVBox", true, false)
@onready var empty_history_label: Label = %EmptyHistoryLabel if has_node("%EmptyHistoryLabel") else find_child("EmptyHistoryLabel", true, false)

var _current_history_filter: String = "all"

# Tarjeta de Perfil Activo
@onready var active_profile_name: Label = %ActiveProfileName if has_node("%ActiveProfileName") else find_child("ActiveProfileName", true, false)
@onready var btn_change_profile: Button = %BtnChangeProfile if has_node("%BtnChangeProfile") else find_child("BtnChangeProfile", true, false)
@onready var btn_edit_profile: Button = %BtnEditProfile if has_node("%BtnEditProfile") else find_child("BtnEditProfile", true, false)
@onready var btn_new_profile: Button = %BtnNewProfile if has_node("%BtnNewProfile") else find_child("BtnNewProfile", true, false)

# Modal de Selección de Perfil
@onready var profile_select_overlay: Control = %ProfileSelectOverlay if has_node("%ProfileSelectOverlay") else find_child("ProfileSelectOverlay", true, false)
@onready var select_card: Control = %SelectCard if has_node("%SelectCard") else (profile_select_overlay.find_child("SelectCard", true, false) if profile_select_overlay else null)
@onready var profiles_scroll: ScrollContainer = %ProfilesScroll if has_node("%ProfilesScroll") else find_child("ProfilesScroll", true, false)
@onready var profiles_list_vbox: VBoxContainer = %ProfilesListVBox if has_node("%ProfilesListVBox") else find_child("ProfilesListVBox", true, false)
@onready var btn_modal_new_profile: Button = %BtnModalNewProfile if has_node("%BtnModalNewProfile") else find_child("BtnModalNewProfile", true, false)
@onready var btn_close_select_modal: Button = %BtnCloseSelectModal if has_node("%BtnCloseSelectModal") else find_child("BtnCloseSelectModal", true, false)

# Sistema de Desplazamiento Táctil Nativo para Modales (Historial y Perfiles)
var _touch_scroll_modal: ScrollContainer = null
var _touch_modal_start_pos: Vector2 = Vector2.ZERO
var _touch_modal_last_pos: Vector2 = Vector2.ZERO
var _touch_modal_start_scroll_val: int = 0
var _is_touch_modal_dragging: bool = false
var _touch_modal_drag_threshold: float = 6.0
var _touch_modal_total_drag_dist: float = 0.0
var _touch_modal_last_time_ms: int = 0
var _last_modal_scroll_time_ms: int = 0
var _modal_scroll_velocity: float = 0.0
var _modal_momentum_target: ScrollContainer = null

# Modal de Edición / Creación de Perfil
@onready var profile_edit_overlay: Control = %ProfileEditOverlay if has_node("%ProfileEditOverlay") else find_child("ProfileEditOverlay", true, false)
@onready var edit_card: Control = %EditCard if has_node("%EditCard") else (profile_edit_overlay.find_child("EditCard", true, false) if profile_edit_overlay else null)
@onready var edit_modal_title: Label = %EditModalTitle if has_node("%EditModalTitle") else find_child("EditModalTitle", true, false)
@onready var edit_name_input: LineEdit = %EditNameInput if has_node("%EditNameInput") else find_child("EditNameInput", true, false)
@onready var btn_cat_child: Button = %BtnCatChild if has_node("%BtnCatChild") else find_child("BtnCatChild", true, false)
@onready var btn_cat_adult: Button = %BtnCatAdult if has_node("%BtnCatAdult") else find_child("BtnCatAdult", true, false)
@onready var child_row_hbox: HBoxContainer = %ChildRowHBox if has_node("%ChildRowHBox") else find_child("ChildRowHBox", true, false)
@onready var adult_row_hbox: HBoxContainer = %AdultRowHBox if has_node("%AdultRowHBox") else find_child("AdultRowHBox", true, false)
@onready var btn_gender_girl: Button = %BtnGenderGirl if has_node("%BtnGenderGirl") else find_child("BtnGenderGirl", true, false)
@onready var btn_gender_boy: Button = %BtnGenderBoy if has_node("%BtnGenderBoy") else find_child("BtnGenderBoy", true, false)
@onready var btn_adult_female: Button = %BtnAdultFemale if has_node("%BtnAdultFemale") else find_child("BtnAdultFemale", true, false)
@onready var btn_adult_male: Button = %BtnAdultMale if has_node("%BtnAdultMale") else find_child("BtnAdultMale", true, false)
@onready var btn_save_profile: Button = %BtnSaveProfile if has_node("%BtnSaveProfile") else find_child("BtnSaveProfile", true, false)
@onready var btn_cancel_edit_profile: Button = %BtnCancelEditProfile if has_node("%BtnCancelEditProfile") else find_child("BtnCancelEditProfile", true, false)
@onready var btn_delete_profile: Button = %BtnDeleteProfile if has_node("%BtnDeleteProfile") else find_child("BtnDeleteProfile", true, false)

# Modal Lobby Online / Versus
@onready var online_lobby_overlay: Control = %OnlineLobbyOverlay if has_node("%OnlineLobbyOverlay") else find_child("OnlineLobbyOverlay", true, false)
@onready var lobby_card: Control = %LobbyCard if has_node("%LobbyCard") else (online_lobby_overlay.find_child("LobbyCard", true, false) if online_lobby_overlay else null)
@onready var btn_close_lobby: Button = %BtnCloseLobby if has_node("%BtnCloseLobby") else find_child("BtnCloseLobby", true, false)
@onready var btn_tab_create: Button = %BtnTabCreate if has_node("%BtnTabCreate") else find_child("BtnTabCreate", true, false)
@onready var btn_tab_join: Button = %BtnTabJoin if has_node("%BtnTabJoin") else find_child("BtnTabJoin", true, false)
@onready var btn_tab_lan: Button = %BtnTabLan if has_node("%BtnTabLan") else find_child("BtnTabLan", true, false)
@onready var create_room_view: Control = %CreateRoomView if has_node("%CreateRoomView") else find_child("CreateRoomView", true, false)
@onready var join_room_view: Control = %JoinRoomView if has_node("%JoinRoomView") else find_child("JoinRoomView", true, false)
@onready var lan_room_view: Control = %LanRoomView if has_node("%LanRoomView") else find_child("LanRoomView", true, false)

@onready var btn_color_white: Button = %BtnColorWhite if has_node("%BtnColorWhite") else find_child("BtnColorWhite", true, false)
@onready var btn_color_black: Button = %BtnColorBlack if has_node("%BtnColorBlack") else find_child("BtnColorBlack", true, false)
@onready var btn_color_random: Button = %BtnColorRandom if has_node("%BtnColorRandom") else find_child("BtnColorRandom", true, false)

@onready var btn_time_none: Button = %BtnTimeNone if has_node("%BtnTimeNone") else find_child("BtnTimeNone", true, false)
@onready var btn_time_3m: Button = %BtnTime3m if has_node("%BtnTime3m") else find_child("BtnTime3m", true, false)
@onready var btn_time_5m: Button = %BtnTime5m if has_node("%BtnTime5m") else find_child("BtnTime5m", true, false)
@onready var btn_time_10m: Button = %BtnTime10m if has_node("%BtnTime10m") else find_child("BtnTime10m", true, false)

@onready var btn_do_create_room: Button = %BtnDoCreateRoom if has_node("%BtnDoCreateRoom") else find_child("BtnDoCreateRoom", true, false)
@onready var waiting_container: Control = %WaitingContainer if has_node("%WaitingContainer") else find_child("WaitingContainer", true, false)
@onready var room_code_label: Label = %RoomCodeLabel if has_node("%RoomCodeLabel") else find_child("RoomCodeLabel", true, false)
@onready var btn_copy_code: Button = %BtnCopyCode if has_node("%BtnCopyCode") else find_child("BtnCopyCode", true, false)
@onready var waiting_status_label: Label = %WaitingStatusLabel if has_node("%WaitingStatusLabel") else find_child("WaitingStatusLabel", true, false)
@onready var btn_cancel_created_room: Button = %BtnCancelCreatedRoom if has_node("%BtnCancelCreatedRoom") else find_child("BtnCancelCreatedRoom", true, false)

@onready var join_code_input: LineEdit = %JoinCodeInput if has_node("%JoinCodeInput") else find_child("JoinCodeInput", true, false)
@onready var btn_do_join_room: Button = %BtnDoJoinRoom if has_node("%BtnDoJoinRoom") else find_child("BtnDoJoinRoom", true, false)
@onready var join_status_label: Label = %JoinStatusLabel if has_node("%JoinStatusLabel") else find_child("JoinStatusLabel", true, false)

@onready var btn_do_lan_host: Button = %BtnDoLanHost if has_node("%BtnDoLanHost") else find_child("BtnDoLanHost", true, false)
@onready var lan_ip_input: LineEdit = %LanIpInput if has_node("%LanIpInput") else find_child("LanIpInput", true, false)
@onready var btn_do_lan_join: Button = %BtnDoLanJoin if has_node("%BtnDoLanJoin") else find_child("BtnDoLanJoin", true, false)
@onready var lan_status_label: Label = %LanStatusLabel if has_node("%LanStatusLabel") else find_child("LanStatusLabel", true, false)

var _is_editing_existing: bool = false
var _target_edit_profile_id: String = ""
var _selected_gender: String = "f" # "f": Femenino / "m": Masculino
var _selected_category: String = "child" # "child": Infantil / "adult": Adulto
var _selected_online_color: String = "white"
var _selected_online_time: int = 5
var _current_lobby_tab: String = "create"

# Nodos del nuevo Menú Principal exclusivo para Android
const GALLO_SCENE_MOB: PackedScene = preload("res://scenes/GalloProfe.tscn")
const CHERRY_FONT_MOB: FontFile = preload("res://assets/fonts/CherryBombOne-Regular.ttf")

var _mobile_root: Control = null
var _mobile_bg_canvas: Control = null
var _mobile_gallo: GalloProfe = null
var _mob_top_bar: HBoxContainer = null
var _mob_lbl_stars: Label = null
var _mob_lbl_wins: Label = null
var _mob_greeting_box: VBoxContainer = null
var _mob_lbl_hello: Label = null
var _mob_lbl_player_name: Label = null
var _mob_btn_new_game: Button = null
var _mob_btn_gloss: Panel = null
var _mob_bottom_bar: PanelContainer = null
var _mob_nav_btns: Array[Button] = []
var _mob_nav_labels: Array[Label] = []
var _mob_nav_icons: Array[Control] = []
var _mobile_mode_popup: Control = null
var _mob_popup_card: PanelContainer = null
var _mob_cloud_time: float = 0.0
var _mob_btn_update: Button = null
var _pc_btn_update: Button = null
var _update_popup_overlay: Control = null
var _update_popup_card: PanelContainer = null
var _upd_lbl_status: Label = null
var _upd_lbl_notes: Label = null
var _upd_progress_box: VBoxContainer = null
var _upd_progress_bar: ProgressBar = null
var _upd_lbl_progress: Label = null
var _upd_btn_ota: Button = null
var _upd_btn_apk: Button = null

func _ready() -> void:
	if btn_academy and not btn_academy.pressed.is_connected(_on_academy_pressed):
		btn_academy.pressed.connect(_on_academy_pressed)
	if btn_practice_bot and not btn_practice_bot.pressed.is_connected(_on_practice_bot_pressed):
		btn_practice_bot.pressed.connect(_on_practice_bot_pressed)

	_build_mobile_scenic_menu()
	_build_mobile_mode_popup()
	_build_update_popup_ui()
	_setup_updater_connections()

	_setup_profile_ui()
	_setup_online_lobby_ui()
	_setup_responsive_menu()

	if btn_match_history and not btn_match_history.pressed.is_connected(_open_history_overlay):
		btn_match_history.pressed.connect(_open_history_overlay)

	_setup_match_history_ui()

	var mhm = _get_mhm()
	if mhm and mhm.open_history_on_main_menu:
		mhm.open_history_on_main_menu = false
		call_deferred("_open_history_overlay")

	var pm = _get_pm()
	if pm and pm.is_first_time:
		call_deferred("_open_first_time_profile_modal")
	call_deferred("_trigger_auto_update_check")

func _process(delta: float) -> void:
	if _mobile_root and _mobile_root.visible and _mobile_bg_canvas:
		_mob_cloud_time += delta
		_mobile_bg_canvas.queue_redraw()

	# Inercia cinética para ScrollContainers de modales (Historial y Perfiles)
	if _modal_momentum_target and is_instance_valid(_modal_momentum_target) and abs(_modal_scroll_velocity) > 10.0:
		_last_modal_scroll_time_ms = Time.get_ticks_msec()
		var vbar = _modal_momentum_target.get_v_scroll_bar()
		var max_val = max(0, int(vbar.max_value - vbar.page))
		var new_val = clamp(int(_modal_momentum_target.scroll_vertical + _modal_scroll_velocity * delta), 0, max_val)
		if new_val == _modal_momentum_target.scroll_vertical or new_val == 0 or new_val == max_val:
			_modal_scroll_velocity = 0.0
			_modal_momentum_target = null
		else:
			_modal_momentum_target.scroll_vertical = new_val
			_modal_scroll_velocity = lerp(_modal_scroll_velocity, 0.0, delta * 7.0)
	else:
		_modal_scroll_velocity = 0.0
		_modal_momentum_target = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _handle_back_or_escape():
			get_viewport().set_input_as_handled()

func _handle_back_or_escape() -> bool:
	if _update_popup_overlay and _update_popup_overlay.visible:
		_close_update_popup()
		return true
	if _mobile_mode_popup and _mobile_mode_popup.visible:
		_close_mobile_mode_popup()
		return true
	if match_history_overlay and match_history_overlay.visible:
		_close_history_overlay()
		return true
	if online_lobby_overlay and online_lobby_overlay.visible:
		_close_online_lobby()
		return true
	if profile_edit_overlay and profile_edit_overlay.visible:
		var pm = _get_pm()
		if pm and pm.is_first_time:
			return true
		_close_edit_modal()
		return true
	if profile_select_overlay and profile_select_overlay.visible:
		_close_select_modal()
		return true
	return false

func _can_interact_modal_buttons() -> bool:
	if _is_touch_modal_dragging:
		return false
	if _touch_modal_total_drag_dist > 6.0:
		return false
	if abs(_modal_scroll_velocity) > 15.0:
		return false
	if (Time.get_ticks_msec() - _last_modal_scroll_time_ms) < 350:
		return false
	return true

func _on_modal_scroll_value_changed(_val: float) -> void:
	_last_modal_scroll_time_ms = Time.get_ticks_msec()

func _reset_modal_drag_flag() -> void:
	_is_touch_modal_dragging = false
	_touch_modal_total_drag_dist = 0.0

func _handle_modal_scroll_gui_input(scroll_container: ScrollContainer, event: InputEvent) -> void:
	if not scroll_container or not is_instance_valid(scroll_container):
		return

	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			var was_moving = (abs(_modal_scroll_velocity) > 15.0) or ((Time.get_ticks_msec() - _last_modal_scroll_time_ms) < 250)
			_modal_scroll_velocity = 0.0
			_modal_momentum_target = null
			_touch_scroll_modal = scroll_container
			_touch_modal_start_pos = event.position
			_touch_modal_last_pos = event.position
			_touch_modal_start_scroll_val = scroll_container.scroll_vertical
			_touch_modal_total_drag_dist = 0.0
			_touch_modal_last_time_ms = Time.get_ticks_msec()
			_is_touch_modal_dragging = false
			if was_moving:
				_last_modal_scroll_time_ms = Time.get_ticks_msec()
		else:
			var now = Time.get_ticks_msec()
			var dt = (now - _touch_modal_last_time_ms) / 1000.0
			if dt < 0.12 and abs(_modal_scroll_velocity) > 60.0:
				_modal_momentum_target = scroll_container
				_last_modal_scroll_time_ms = now
			else:
				_modal_scroll_velocity = 0.0
				_modal_momentum_target = null

			if _is_touch_modal_dragging or _touch_modal_total_drag_dist > 6.0:
				_last_modal_scroll_time_ms = now
			_touch_scroll_modal = null
			call_deferred("_reset_modal_drag_flag")

	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0):
		var rel_y: float = 0.0
		var vel_y: float = 0.0
		if event is InputEventScreenDrag:
			rel_y = event.relative.y
			vel_y = event.velocity.y
		elif event is InputEventMouseMotion:
			rel_y = event.relative.y
			vel_y = event.velocity.y

		_touch_modal_total_drag_dist += abs(rel_y)

		if abs(rel_y) > 0.0:
			var now = Time.get_ticks_msec()
			var dt = (now - _touch_modal_last_time_ms) / 1000.0
			_touch_modal_last_time_ms = now

			if _touch_modal_total_drag_dist > 6.0 or _is_touch_modal_dragging:
				_is_touch_modal_dragging = true
				_last_modal_scroll_time_ms = now

				var vbar = scroll_container.get_v_scroll_bar()
				var max_val = max(0, int(vbar.max_value - vbar.page))
				var new_val = clamp(int(scroll_container.scroll_vertical - rel_y), 0, max_val)
				scroll_container.scroll_vertical = new_val

				if abs(vel_y) > 0.0:
					_modal_scroll_velocity = -vel_y
				elif dt > 0.001:
					_modal_scroll_velocity = -rel_y / dt

				var fo = get_viewport().gui_get_focus_owner()
				if fo:
					fo.release_focus()

func _on_profiles_scroll_gui_input(ev: InputEvent) -> void:
	if profiles_scroll:
		_handle_modal_scroll_gui_input(profiles_scroll, ev)

func _on_history_scroll_gui_input(ev: InputEvent) -> void:
	if history_scroll_container:
		_handle_modal_scroll_gui_input(history_scroll_container, ev)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _handle_back_or_escape():
				get_viewport().set_input_as_handled()
				return

	_handle_modal_scroll_input(event)

func _handle_modal_scroll_input(event: InputEvent) -> void:
	var is_down = false
	var is_up = false
	var is_drag = false
	var ev_pos = Vector2.ZERO

	if event is InputEventScreenTouch:
		ev_pos = event.position
		if event.pressed:
			is_down = true
		else:
			is_up = true
	elif event is InputEventScreenDrag:
		ev_pos = event.position
		is_drag = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		ev_pos = event.position
		if event.pressed:
			is_down = true
		else:
			is_up = true
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		ev_pos = event.position
		is_drag = true
	else:
		return

	if is_down:
		var was_moving = (abs(_modal_scroll_velocity) > 15.0) or ((Time.get_ticks_msec() - _last_modal_scroll_time_ms) < 250)
		_modal_scroll_velocity = 0.0
		_modal_momentum_target = null
		_touch_scroll_modal = null
		_is_touch_modal_dragging = false
		_touch_modal_total_drag_dist = 0.0

		if was_moving:
			_last_modal_scroll_time_ms = Time.get_ticks_msec()

		# 1. Comprobar si se tocó dentro del Historial de Partidas
		if match_history_overlay and match_history_overlay.is_visible_in_tree() and history_scroll_container and history_scroll_container.is_visible_in_tree():
			var local_pos = history_scroll_container.make_input_local(event)
			var in_local = Rect2(Vector2.ZERO, history_scroll_container.size).has_point(local_pos.position)
			var in_global = history_scroll_container.get_global_rect().has_point(ev_pos)
			if in_local or in_global:
				_touch_scroll_modal = history_scroll_container
				_touch_modal_start_pos = ev_pos
				_touch_modal_last_pos = ev_pos
				_touch_modal_start_scroll_val = history_scroll_container.scroll_vertical
				_touch_modal_last_time_ms = Time.get_ticks_msec()
				return

		# 2. Comprobar si se tocó dentro de Selección de Perfil
		if profile_select_overlay and profile_select_overlay.is_visible_in_tree() and profiles_scroll and profiles_scroll.is_visible_in_tree():
			var local_pos = profiles_scroll.make_input_local(event)
			var in_local = Rect2(Vector2.ZERO, profiles_scroll.size).has_point(local_pos.position)
			var in_global = profiles_scroll.get_global_rect().has_point(ev_pos)
			if in_local or in_global:
				_touch_scroll_modal = profiles_scroll
				_touch_modal_start_pos = ev_pos
				_touch_modal_last_pos = ev_pos
				_touch_modal_start_scroll_val = profiles_scroll.scroll_vertical
				_touch_modal_last_time_ms = Time.get_ticks_msec()
				return

	elif is_drag and _touch_scroll_modal != null:
		var now = Time.get_ticks_msec()
		var dt = (now - _touch_modal_last_time_ms) / 1000.0
		_touch_modal_last_time_ms = now

		var total_delta = (ev_pos - _touch_modal_start_pos).length()
		_touch_modal_total_drag_dist = max(_touch_modal_total_drag_dist, total_delta)

		var delta_y = ev_pos.y - _touch_modal_start_pos.y
		if abs(delta_y) > _touch_modal_drag_threshold or _is_touch_modal_dragging or _touch_modal_total_drag_dist > 6.0:
			_is_touch_modal_dragging = true
			_last_modal_scroll_time_ms = now
			var vbar = _touch_scroll_modal.get_v_scroll_bar()
			var max_val = max(0, int(vbar.max_value - vbar.page))
			var target_val = clamp(int(_touch_modal_start_scroll_val - delta_y), 0, max_val)
			_touch_scroll_modal.scroll_vertical = target_val

			var move_dy = ev_pos.y - _touch_modal_last_pos.y
			if dt > 0.001:
				var instant_v = -move_dy / dt
				_modal_scroll_velocity = lerp(_modal_scroll_velocity, instant_v, 0.4)
			_touch_modal_last_pos = ev_pos
			get_viewport().set_input_as_handled()

			var fo = get_viewport().gui_get_focus_owner()
			if fo:
				fo.release_focus()

	elif is_up and _touch_scroll_modal != null:
		var now = Time.get_ticks_msec()
		var time_since_last_drag = (now - _touch_modal_last_time_ms) / 1000.0
		if time_since_last_drag > 0.15:
			_modal_scroll_velocity = 0.0

		if abs(_modal_scroll_velocity) > 60.0:
			_modal_momentum_target = _touch_scroll_modal
			_last_modal_scroll_time_ms = now
		else:
			_modal_scroll_velocity = 0.0
			_modal_momentum_target = null

		_touch_scroll_modal = null

		if _is_touch_modal_dragging or _touch_modal_total_drag_dist > 6.0:
			get_viewport().set_input_as_handled()
		call_deferred("_reset_modal_drag_flag")

func _on_academy_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/AcademyMap.tscn")

func _on_practice_bot_pressed() -> void:
	get_tree().change_scene_to_file("res://tablero_juego.tscn")

# =========================================================================
# GESTIÓN Y VINCULACIÓN DE PERFILES
# =========================================================================

func _get_pm() -> Node:
	var pm: Node = null
	if has_node("/root/ProfileManager"):
		pm = get_node("/root/ProfileManager")
	elif ProfileManagerScript.instance:
		pm = ProfileManagerScript.instance
	if pm:
		if not pm.has_method("is_adult"):
			var new_script = ResourceLoader.load("res://scripts/ProfileManager.gd", "", ResourceLoader.CACHE_MODE_REPLACE)
			if new_script:
				pm.set_script(new_script)
				if pm.has_method("_load_profiles"):
					pm._load_profiles()
	return pm

# =========================================================================
# ESTILOS Y HELPERS UNIFICADOS DE POPUPS (ESTILO NUEVA PARTIDA / TOY 3D)
# =========================================================================

func _apply_uniform_popup_card_style(card: Control, border_col: Color = Color("#F472B6"), bg_col: Color = Color("#FFF9FB")) -> void:
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
	card_sb.content_margin_left = 26
	card_sb.content_margin_right = 26
	card_sb.content_margin_top = 22
	card_sb.content_margin_bottom = 26
	card_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	card_sb.shadow_size = 24
	card_sb.shadow_offset = Vector2(0, 10)
	card_sb.anti_aliasing = true
	card.add_theme_stylebox_override("panel", card_sb)

func _style_circular_close_btn(btn: Button) -> void:
	if not btn:
		return
	btn.text = "✕"
	btn.custom_minimum_size = Vector2(50, 50)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#EF4444")
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 5
	sb.border_color = Color("#B91C1C")
	sb.set_corner_radius_all(25)
	var sb_hov := sb.duplicate()
	sb_hov.bg_color = Color("#F87171")
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hov)
	btn.add_theme_stylebox_override("pressed", sb)

func _style_popup_header_label(lbl: Label, text_str: String = "", font_sz: int = 32) -> void:
	if not lbl:
		return
	if not text_str.is_empty():
		lbl.text = text_str
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", CHERRY_FONT_MOB)
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_color", Color("#BE185D"))
	lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 8)

func _setup_dimmer_dismiss(overlay: Control, close_callable: Callable) -> void:
	if not overlay:
		return
	var dimmer: Control = overlay.get_node_or_null("Dimmer")
	if not dimmer:
		dimmer = overlay.get_node_or_null("ModalBackdrop")
	if not dimmer:
		dimmer = overlay.get_node_or_null("HistoryBackdrop")
	if not dimmer:
		return

	if dimmer is ColorRect:
		dimmer.color = Color(0.09, 0.04, 0.14, 0.72)
		dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
		if not dimmer.gui_input.is_connected(_on_dimmer_input_event):
			dimmer.gui_input.connect(func(ev: InputEvent): _on_dimmer_input_event(ev, close_callable))

func _on_dimmer_input_event(ev: InputEvent, close_callable: Callable) -> void:
	if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
		close_callable.call()

func _open_styled_popup(overlay: Control, card: Control) -> void:
	if not overlay:
		return
	overlay.visible = true
	overlay.move_to_front()
	overlay.z_index = 1000
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	if card:
		var is_mob: bool = false
		if has_node("/root/ScreenManager"):
			var sm = get_node("/root/ScreenManager")
			if sm.has_method("is_mobile"):
				is_mob = sm.is_mobile()

		var vp_sz = get_viewport().get_visible_rect().size
		var is_portrait = (vp_sz.x < vp_sz.y)
		var target_scale = Vector2.ONE
		if is_mob and is_portrait:
			var s: float = clampf((vp_sz.x * 0.92) / maxf(card.custom_minimum_size.x, 440.0), 0.95, 1.15)
			target_scale = Vector2(s, s)

		card.pivot_offset = card.size * 0.5
		card.scale = target_scale * 0.85
		var safe_top: float = 0.0
		if has_node("/root/ScreenManager"):
			safe_top = get_node("/root/ScreenManager").get_safe_top_margin()
		if safe_top > 0.0 and card.global_position.y < safe_top:
			card.position.y += (safe_top - card.global_position.y) + 8.0

		var tw := create_tween()
		tw.tween_property(card, "scale", target_scale, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _setup_profile_ui() -> void:
	var pm = _get_pm()
	if pm:
		if not pm.active_profile_changed.is_connected(_on_active_profile_changed):
			pm.active_profile_changed.connect(_on_active_profile_changed)
		if not pm.profiles_updated.is_connected(_on_profiles_updated):
			pm.profiles_updated.connect(_on_profiles_updated)

	# Botones de la barra principal
	if btn_change_profile and not btn_change_profile.pressed.is_connected(_open_select_modal):
		btn_change_profile.pressed.connect(_open_select_modal)
	if btn_edit_profile and not btn_edit_profile.pressed.is_connected(_open_edit_current_profile):
		btn_edit_profile.pressed.connect(_open_edit_current_profile)
	if btn_new_profile and not btn_new_profile.pressed.is_connected(_open_create_new_profile):
		btn_new_profile.pressed.connect(_open_create_new_profile)

	# Botones de modal selector
	if btn_modal_new_profile and not btn_modal_new_profile.pressed.is_connected(_open_create_new_profile):
		btn_modal_new_profile.pressed.connect(_open_create_new_profile)
	if btn_close_select_modal and not btn_close_select_modal.pressed.is_connected(_close_select_modal):
		btn_close_select_modal.pressed.connect(_close_select_modal)
	if profiles_scroll:
		profiles_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		profiles_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		if not profiles_scroll.gui_input.is_connected(_on_profiles_scroll_gui_input):
			profiles_scroll.gui_input.connect(_on_profiles_scroll_gui_input)
		var vbar = profiles_scroll.get_v_scroll_bar()
		if vbar and not vbar.value_changed.is_connected(_on_modal_scroll_value_changed):
			vbar.value_changed.connect(_on_modal_scroll_value_changed)
	if profiles_list_vbox:
		profiles_list_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		if not profiles_list_vbox.gui_input.is_connected(_on_profiles_scroll_gui_input):
			profiles_list_vbox.gui_input.connect(_on_profiles_scroll_gui_input)

	# Botones de modal editor
	_ensure_archetype_buttons_exist()

	if btn_save_profile and not btn_save_profile.pressed.is_connected(_on_save_profile_pressed):
		btn_save_profile.pressed.connect(_on_save_profile_pressed)
	if btn_cancel_edit_profile and not btn_cancel_edit_profile.pressed.is_connected(_close_edit_modal):
		btn_cancel_edit_profile.pressed.connect(_close_edit_modal)
	if btn_delete_profile and not btn_delete_profile.pressed.is_connected(_on_delete_profile_pressed):
		btn_delete_profile.pressed.connect(_on_delete_profile_pressed)
	if edit_name_input and not edit_name_input.text_submitted.is_connected(func(_t): _on_save_profile_pressed()):
		edit_name_input.text_submitted.connect(func(_t): _on_save_profile_pressed())

	_setup_uniform_popups_ui()
	_style_main_buttons()
	_update_active_profile_display()

func _setup_uniform_popups_ui() -> void:
	# 1. SelectCard
	if select_card:
		_apply_uniform_popup_card_style(select_card)
		var sel_vbox = select_card.find_child("VBox", true, false) as VBoxContainer
		var sel_header = select_card.find_child("Header", true, false) as Label
		if sel_vbox and sel_header and not select_card.has_node("SelectHeaderHBox"):
			var hdr_hbox = HBoxContainer.new()
			hdr_hbox.name = "SelectHeaderHBox"
			hdr_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			sel_vbox.add_child(hdr_hbox)
			sel_vbox.move_child(hdr_hbox, 0)

			var sp_l = Control.new()
			sp_l.custom_minimum_size = Vector2(50, 50)
			hdr_hbox.add_child(sp_l)

			sel_header.reparent(hdr_hbox)
			_style_popup_header_label(sel_header, "👑 Seleccionar Perfil", 32)

			if btn_close_select_modal:
				btn_close_select_modal.reparent(hdr_hbox)
				_style_circular_close_btn(btn_close_select_modal)

		var sel_subtitle = select_card.find_child("Subtitle", true, false) as Label
		if sel_subtitle:
			sel_subtitle.text = "Elige quién jugará hoy o crea un nuevo perfil:"
			sel_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sel_subtitle.add_theme_font_size_override("font_size", 15)
			sel_subtitle.add_theme_color_override("font_color", Color("#701A75"))

		if btn_modal_new_profile:
			btn_modal_new_profile.text = "➕ Crear Nuevo Perfil"
			btn_modal_new_profile.custom_minimum_size = Vector2(0, 52)
			btn_modal_new_profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn_modal_new_profile.add_theme_font_override("font", CHERRY_FONT_MOB)
			btn_modal_new_profile.add_theme_font_size_override("font_size", 18)
			var btn_new_sb := StyleBoxFlat.new()
			btn_new_sb.bg_color = Color("#F59E0B")
			btn_new_sb.border_width_bottom = 5
			btn_new_sb.border_color = Color("#D97706")
			btn_new_sb.set_corner_radius_all(18)
			var btn_new_hov := btn_new_sb.duplicate()
			btn_new_hov.bg_color = Color("#FBBF24")
			btn_modal_new_profile.add_theme_stylebox_override("normal", btn_new_sb)
			btn_modal_new_profile.add_theme_stylebox_override("hover", btn_new_hov)
			btn_modal_new_profile.add_theme_stylebox_override("pressed", btn_new_sb)
			btn_modal_new_profile.add_theme_color_override("font_color", Color.WHITE)

	_setup_dimmer_dismiss(profile_select_overlay, _close_select_modal)

	# 2. EditCard
	if edit_card:
		_apply_uniform_popup_card_style(edit_card)
		var edit_vbox = edit_card.find_child("VBox", true, false) as VBoxContainer
		if edit_vbox and edit_modal_title and not edit_card.has_node("EditHeaderHBox"):
			var edit_hdr_hbox = HBoxContainer.new()
			edit_hdr_hbox.name = "EditHeaderHBox"
			edit_hdr_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			edit_vbox.add_child(edit_hdr_hbox)
			edit_vbox.move_child(edit_hdr_hbox, 0)

			var sp_el = Control.new()
			sp_el.custom_minimum_size = Vector2(50, 50)
			edit_hdr_hbox.add_child(sp_el)

			edit_modal_title.reparent(edit_hdr_hbox)
			_style_popup_header_label(edit_modal_title, "🌟 Configurar Perfil", 30)

			var edit_x_btn = Button.new()
			edit_x_btn.name = "BtnCloseEditHeader"
			_style_circular_close_btn(edit_x_btn)
			edit_x_btn.pressed.connect(_close_edit_modal)
			edit_hdr_hbox.add_child(edit_x_btn)

		if edit_name_input:
			edit_name_input.custom_minimum_size = Vector2(0, 52)
			edit_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
			edit_name_input.add_theme_font_size_override("font_size", 18)
			var in_sb = StyleBoxFlat.new()
			in_sb.bg_color = Color.WHITE
			in_sb.border_width_left = 3
			in_sb.border_width_top = 3
			in_sb.border_width_right = 3
			in_sb.border_width_bottom = 5
			in_sb.border_color = Color("#F472B6")
			in_sb.set_corner_radius_all(16)
			edit_name_input.add_theme_stylebox_override("normal", in_sb)
			edit_name_input.add_theme_stylebox_override("focus", in_sb)

		if btn_save_profile:
			btn_save_profile.text = "✨ ¡Guardar Perfil!"
			btn_save_profile.custom_minimum_size = Vector2(0, 54)
			btn_save_profile.add_theme_font_override("font", CHERRY_FONT_MOB)
			btn_save_profile.add_theme_font_size_override("font_size", 20)
			var save_sb := StyleBoxFlat.new()
			save_sb.bg_color = Color("#10B981")
			save_sb.border_width_bottom = 6
			save_sb.border_color = Color("#047857")
			save_sb.set_corner_radius_all(18)
			var save_hov := save_sb.duplicate()
			save_hov.bg_color = Color("#34D399")
			btn_save_profile.add_theme_stylebox_override("normal", save_sb)
			btn_save_profile.add_theme_stylebox_override("hover", save_hov)
			btn_save_profile.add_theme_stylebox_override("pressed", save_sb)
			btn_save_profile.add_theme_color_override("font_color", Color.WHITE)

		if btn_cancel_edit_profile:
			btn_cancel_edit_profile.custom_minimum_size = Vector2(0, 44)
			var cancel_sb := StyleBoxFlat.new()
			cancel_sb.bg_color = Color("#F1F5F9")
			cancel_sb.border_width_bottom = 3
			cancel_sb.border_color = Color("#CBD5E1")
			cancel_sb.set_corner_radius_all(14)
			btn_cancel_edit_profile.add_theme_stylebox_override("normal", cancel_sb)
			btn_cancel_edit_profile.add_theme_stylebox_override("hover", cancel_sb)
			btn_cancel_edit_profile.add_theme_stylebox_override("pressed", cancel_sb)
			btn_cancel_edit_profile.add_theme_color_override("font_color", Color("#475569"))
			btn_cancel_edit_profile.add_theme_font_size_override("font_size", 14)

		if btn_delete_profile:
			btn_delete_profile.custom_minimum_size = Vector2(0, 44)
			var del_sb := StyleBoxFlat.new()
			del_sb.bg_color = Color("#FEE2E2")
			del_sb.border_width_bottom = 3
			del_sb.border_color = Color("#F87171")
			del_sb.set_corner_radius_all(14)
			btn_delete_profile.add_theme_stylebox_override("normal", del_sb)
			btn_delete_profile.add_theme_stylebox_override("hover", del_sb)
			btn_delete_profile.add_theme_stylebox_override("pressed", del_sb)
			btn_delete_profile.add_theme_color_override("font_color", Color("#DC2626"))
			btn_delete_profile.add_theme_font_size_override("font_size", 14)

	_setup_dimmer_dismiss(profile_edit_overlay, _close_edit_modal)

	# 3. HistoryCard
	if history_card:
		_apply_uniform_popup_card_style(history_card)
		var hist_title = history_card.find_child("HistoryTitle", true, false) as Label
		if hist_title:
			_style_popup_header_label(hist_title, "📜 Historial de Partidas", 32)
		if btn_close_history_modal:
			_style_circular_close_btn(btn_close_history_modal)
		if btn_clear_all_history:
			btn_clear_all_history.text = "🗑️ Borrar"
			btn_clear_all_history.custom_minimum_size = Vector2(95, 42)
			var clr_sb := StyleBoxFlat.new()
			clr_sb.bg_color = Color("#FEE2E2")
			clr_sb.border_width_bottom = 3
			clr_sb.border_color = Color("#F87171")
			clr_sb.set_corner_radius_all(14)
			btn_clear_all_history.add_theme_stylebox_override("normal", clr_sb)
			btn_clear_all_history.add_theme_stylebox_override("hover", clr_sb)
			btn_clear_all_history.add_theme_stylebox_override("pressed", clr_sb)
			btn_clear_all_history.add_theme_color_override("font_color", Color("#B91C1C"))
			btn_clear_all_history.add_theme_font_size_override("font_size", 14)
		_setup_dimmer_dismiss(match_history_overlay, _close_history_overlay)

	# 4. LobbyCard
	if lobby_card:
		_apply_uniform_popup_card_style(lobby_card)
		var lobby_title = lobby_card.find_child("LobbyTitle", true, false) as Label
		if lobby_title:
			_style_popup_header_label(lobby_title, "🌐 Partida Versus", 30)
		if btn_close_lobby:
			_style_circular_close_btn(btn_close_lobby)
		var title_box = lobby_card.find_child("TitleHBox", true, false) as HBoxContainer
		if title_box and not lobby_card.has_node("LobbySpacerL"):
			var spl = Control.new()
			spl.name = "LobbySpacerL"
			spl.custom_minimum_size = Vector2(50, 50)
			title_box.add_child(spl)
			title_box.move_child(spl, 0)
		_setup_dimmer_dismiss(online_lobby_overlay, _close_online_lobby)

func _style_main_buttons() -> void:
	# Estilo suave para los botones de cambio y edición
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(1, 1, 1, 0.9)
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.9, 0.82, 0.88, 1)
	btn_style.set_corner_radius_all(10)
	btn_style.anti_aliasing = true

	var btn_hov = btn_style.duplicate()
	btn_hov.bg_color = Color(0.98, 0.94, 0.97, 1)
	btn_hov.border_color = Color(0.85, 0.15, 0.45, 0.8)

	for btn in [btn_change_profile, btn_edit_profile, btn_new_profile, btn_close_select_modal, btn_cancel_edit_profile]:
		if btn:
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_hov)
			btn.add_theme_stylebox_override("pressed", btn_hov)
			btn.add_theme_color_override("font_color", Color(0.3, 0.35, 0.45, 1))

	if btn_save_profile:
		var save_norm = StyleBoxFlat.new()
		save_norm.bg_color = Color(0.06, 0.72, 0.50, 1) # Emerald green
		save_norm.border_width_bottom = 3
		save_norm.border_color = Color(0.03, 0.52, 0.36, 1)
		save_norm.set_corner_radius_all(12)
		save_norm.anti_aliasing = true

		var save_hov = save_norm.duplicate()
		save_hov.bg_color = Color(0.12, 0.80, 0.58, 1)

		btn_save_profile.add_theme_stylebox_override("normal", save_norm)
		btn_save_profile.add_theme_stylebox_override("hover", save_hov)
		btn_save_profile.add_theme_stylebox_override("pressed", save_norm)
		btn_save_profile.add_theme_color_override("font_color", Color.WHITE)

	if btn_delete_profile:
		var del_norm = StyleBoxFlat.new()
		del_norm.bg_color = Color(0.99, 0.95, 0.95, 1)
		del_norm.border_width_left = 1
		del_norm.border_width_top = 1
		del_norm.border_width_right = 1
		del_norm.border_width_bottom = 2
		del_norm.border_color = Color(0.95, 0.7, 0.7, 1)
		del_norm.set_corner_radius_all(10)
		del_norm.anti_aliasing = true

		btn_delete_profile.add_theme_stylebox_override("normal", del_norm)
		btn_delete_profile.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2, 1))

func _update_active_profile_display() -> void:
	var pm = _get_pm()
	if not pm:
		return
	var prof = pm.get_active_profile()
	var p_name = prof.get("name", "")
	var is_fem = (str(prof.get("gender", "f")).to_lower() == "f")
	var cat = str(prof.get("category", "child")).to_lower()
	var is_ad = (cat in ["adult", "adulto", "adulta"] or prof.get("is_adult", false) == true)
	var icon = ("👩" if is_fem else "👨") if is_ad else ("👧" if is_fem else "👦")
	var tag = ("Adulta" if is_fem else "Adulto") if is_ad else ("Niña" if is_fem else "Niño")
	var color_code = ("#7c3aed" if is_fem else "#059669") if is_ad else ("#db2777" if is_fem else "#2563eb")

	if p_name.strip_edges().is_empty():
		p_name = ("Adulta" if is_fem else "Adulto") if is_ad else ("Niña" if is_fem else "Niño")

	if active_profile_name:
		active_profile_name.text = "%s %s (%s)" % [icon, p_name, tag]
		active_profile_name.add_theme_color_override("font_color", Color(color_code))

	_update_mobile_profile_and_stats()

func _on_active_profile_changed(_prof: Dictionary) -> void:
	_update_active_profile_display()

func _on_profiles_updated() -> void:
	_update_active_profile_display()
	if profile_select_overlay and profile_select_overlay.visible:
		_populate_select_list()

# =========================================================================
# MODAL SELECCIONAR PERFIL
# =========================================================================

func _open_select_modal() -> void:
	if profile_select_overlay:
		_populate_select_list()
		_open_styled_popup(profile_select_overlay, select_card)

func _close_select_modal() -> void:
	if profile_select_overlay:
		profile_select_overlay.visible = false

func _populate_select_list() -> void:
	if not profiles_list_vbox:
		return

	# Limpiar hijos previos
	for child in profiles_list_vbox.get_children():
		child.queue_free()

	var pm = _get_pm()
	if not pm:
		return

	var is_mob: bool = false
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if sm.has_method("is_mobile"):
			is_mob = sm.is_mobile()

	var all_profs = pm.get_all_profiles()
	var active_id = pm.get_active_profile().get("id", "")

	for p in all_profs:
		var p_id = p.get("id", "")
		var p_name = p.get("name", "Jugador")
		var is_fem = (str(p.get("gender", "f")).to_lower() == "f")
		var cat = str(p.get("category", "child")).to_lower()
		var is_ad = (cat in ["adult", "adulto", "adulta"] or p.get("is_adult", false) == true)
		var icon = ("👩" if is_fem else "👨") if is_ad else ("👧" if is_fem else "👦")
		var gender_label = ("Adulta" if is_fem else "Adulto") if is_ad else ("Niña" if is_fem else "Niño")
		var is_active = (p_id == active_id)

		var card = PanelContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		card.gui_input.connect(func(ev): _handle_modal_scroll_gui_input(profiles_scroll, ev))
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color("#FFF0F6") if is_active else Color("#FFFFFF")
		card_style.border_width_left = 3 if is_active else 2
		card_style.border_width_top = 3 if is_active else 2
		card_style.border_width_right = 3 if is_active else 2
		card_style.border_width_bottom = 6 if is_active else 4
		card_style.border_color = Color("#F472B6") if is_active else Color("#E2E8F0")
		card_style.set_corner_radius_all(18)
		card_style.anti_aliasing = true
		card.add_theme_stylebox_override("panel", card_style)

		var margin = MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 16 if is_mob else 14)
		margin.add_theme_constant_override("margin_top", 12 if is_mob else 10)
		margin.add_theme_constant_override("margin_right", 16 if is_mob else 14)
		margin.add_theme_constant_override("margin_bottom", 12 if is_mob else 10)
		card.add_child(margin)

		var row = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 14 if is_mob else 12)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		margin.add_child(row)

		var info_label = Label.new()
		info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_label.text = "%s %s  (%s)" % [icon, p_name, gender_label]
		var col = (Color("#7C3AED") if is_fem else Color("#059669")) if is_ad else (Color("#DB2777") if is_fem else Color("#2563EB"))
		info_label.add_theme_color_override("font_color", col)
		info_label.add_theme_font_size_override("font_size", 20 if is_mob else 16)
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_label)

		if is_active:
			var active_badge = Label.new()
			active_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			active_badge.text = "✓ Activo"
			active_badge.add_theme_color_override("font_color", Color("#059669"))
			active_badge.add_theme_font_size_override("font_size", 18 if is_mob else 14)
			row.add_child(active_badge)
		else:
			var btn_select = Button.new()
			btn_select.text = "Elegir"
			btn_select.focus_mode = Control.FOCUS_NONE
			btn_select.add_theme_font_size_override("font_size", 16 if is_mob else 13)
			btn_select.custom_minimum_size = Vector2(110, 46) if is_mob else Vector2(90, 36)
			var sel_sb := StyleBoxFlat.new()
			sel_sb.bg_color = Color("#10B981")
			sel_sb.border_width_bottom = 4
			sel_sb.border_color = Color("#047857")
			sel_sb.set_corner_radius_all(14)
			var sel_hov := sel_sb.duplicate()
			sel_hov.bg_color = Color("#34D399")
			btn_select.add_theme_stylebox_override("normal", sel_sb)
			btn_select.add_theme_stylebox_override("hover", sel_hov)
			btn_select.add_theme_stylebox_override("pressed", sel_sb)
			btn_select.add_theme_color_override("font_color", Color.WHITE)
			btn_select.gui_input.connect(func(ev): _handle_modal_scroll_gui_input(profiles_scroll, ev))
			var cur_id = p_id
			btn_select.pressed.connect(func():
				if not _can_interact_modal_buttons():
					return
				pm.set_active_profile_by_id(cur_id)
				_close_select_modal()
			)
			row.add_child(btn_select)

		var btn_edit = Button.new()
		btn_edit.text = "✏️"
		btn_edit.tooltip_text = "Editar este perfil"
		btn_edit.focus_mode = Control.FOCUS_NONE
		btn_edit.add_theme_font_size_override("font_size", 18 if is_mob else 14)
		btn_edit.custom_minimum_size = Vector2(48, 46) if is_mob else Vector2(40, 36)
		var edit_sb := StyleBoxFlat.new()
		edit_sb.bg_color = Color("#F1F5F9")
		edit_sb.border_width_bottom = 3
		edit_sb.border_color = Color("#CBD5E1")
		edit_sb.set_corner_radius_all(12)
		var edit_hov := edit_sb.duplicate()
		edit_hov.bg_color = Color("#E2E8F0")
		btn_edit.add_theme_stylebox_override("normal", edit_sb)
		btn_edit.add_theme_stylebox_override("hover", edit_hov)
		btn_edit.add_theme_stylebox_override("pressed", edit_sb)
		btn_edit.gui_input.connect(func(ev): _handle_modal_scroll_gui_input(profiles_scroll, ev))
		var edit_id = p_id
		btn_edit.pressed.connect(func():
			if not _can_interact_modal_buttons():
				return
			_open_edit_specific_profile(edit_id)
		)
		row.add_child(btn_edit)

		profiles_list_vbox.add_child(card)

# =========================================================================
# MODAL CREADOR / EDITOR DE PERFIL
# =========================================================================

func _open_create_new_profile() -> void:
	_is_editing_existing = false
	_target_edit_profile_id = ""
	_selected_gender = "f" # Predeterminado femenina
	_selected_category = "child" # Predeterminado infantil

	if edit_modal_title:
		edit_modal_title.text = "🌟 Crear Nuevo Perfil"
	if edit_name_input:
		edit_name_input.text = ""
		edit_name_input.placeholder_text = "Escribe tu nombre o apodo..."
	if btn_delete_profile:
		btn_delete_profile.visible = false
	if btn_cancel_edit_profile:
		btn_cancel_edit_profile.visible = true

	_ensure_archetype_buttons_exist()
	_refresh_gender_buttons_ui()

	if profile_edit_overlay:
		_open_styled_popup(profile_edit_overlay, edit_card)
	if edit_card:
		var x_btn = edit_card.find_child("BtnCloseEditHeader", true, false)
		if x_btn:
			x_btn.visible = true
	if edit_name_input:
		edit_name_input.grab_focus()

func _open_first_time_profile_modal() -> void:
	_open_create_new_profile()
	if edit_modal_title:
		edit_modal_title.text = "🌟 ¡Bienvenida/o! Configura tu Perfil"
	if btn_cancel_edit_profile:
		btn_cancel_edit_profile.visible = false
	if btn_delete_profile:
		btn_delete_profile.visible = false
	if edit_card:
		var x_btn = edit_card.find_child("BtnCloseEditHeader", true, false)
		if x_btn:
			x_btn.visible = false

func _open_edit_current_profile() -> void:
	var pm = _get_pm()
	if not pm:
		return
	var prof = pm.get_active_profile()
	_open_edit_specific_profile(prof.get("id", ""))

func _open_edit_specific_profile(p_id: String) -> void:
	var pm = _get_pm()
	if not pm:
		return

	var target_prof = {}
	for p in pm.get_all_profiles():
		if p.get("id", "") == p_id:
			target_prof = p
			break

	if target_prof.is_empty():
		return

	_is_editing_existing = true
	_target_edit_profile_id = p_id
	_selected_gender = str(target_prof.get("gender", "f")).to_lower()
	var cat = str(target_prof.get("category", "child")).to_lower()
	_selected_category = "adult" if (cat in ["adult", "adulto", "adulta"] or target_prof.get("is_adult", false) == true) else "child"

	if edit_modal_title:
		edit_modal_title.text = "✏️ Editar Perfil de %s" % target_prof.get("name", "")
	if edit_name_input:
		edit_name_input.text = target_prof.get("name", "")

	if btn_delete_profile:
		# Solo mostrar botón eliminar si hay más de 1 perfil en total
		btn_delete_profile.visible = (pm.get_all_profiles().size() > 1)

	_ensure_archetype_buttons_exist()
	_refresh_gender_buttons_ui()

	if profile_edit_overlay:
		_open_styled_popup(profile_edit_overlay, edit_card)
	if edit_card:
		var x_btn = edit_card.find_child("BtnCloseEditHeader", true, false)
		if x_btn:
			x_btn.visible = true
	if edit_name_input:
		edit_name_input.grab_focus()

func _ensure_archetype_buttons_exist() -> void:
	if not profile_edit_overlay:
		return
	var gender_sec = profile_edit_overlay.find_child("GenderSection", true, false)
	if not gender_sec:
		return

	# 1. Asegurar categoría (Niño vs Adulto)
	var cat_hbox = gender_sec.find_child("CategoryHBox", true, false)
	if not cat_hbox:
		var cat_prompt = Label.new()
		cat_prompt.name = "CategoryPrompt"
		cat_prompt.text = "1. Tipo de Jugador (Elige si es Niño o Adulto):"
		cat_prompt.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55, 1))
		cat_prompt.add_theme_font_size_override("font_size", 13)
		gender_sec.add_child(cat_prompt)
		gender_sec.move_child(cat_prompt, 0)

		cat_hbox = HBoxContainer.new()
		cat_hbox.name = "CategoryHBox"
		cat_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		cat_hbox.add_theme_constant_override("separation", 12)
		gender_sec.add_child(cat_hbox)
		gender_sec.move_child(cat_hbox, 1)

		var b_child = Button.new()
		b_child.name = "BtnCatChild"
		b_child.custom_minimum_size = Vector2(160, 46)
		b_child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_child.focus_mode = Control.FOCUS_NONE
		b_child.text = "🧒 Modo Infantil"
		cat_hbox.add_child(b_child)
		btn_cat_child = b_child

		var b_adult = Button.new()
		b_adult.name = "BtnCatAdult"
		b_adult.custom_minimum_size = Vector2(160, 46)
		b_adult.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_adult.focus_mode = Control.FOCUS_NONE
		b_adult.text = "🧑 Modo Adulto"
		cat_hbox.add_child(b_adult)
		btn_cat_adult = b_adult
	else:
		if not btn_cat_child:
			btn_cat_child = cat_hbox.find_child("BtnCatChild", true, false)
		if not btn_cat_adult:
			btn_cat_adult = cat_hbox.find_child("BtnCatAdult", true, false)

	# 2. Asegurar filas de avatares (ChildRowHBox y AdultRowHBox)
	if not child_row_hbox:
		child_row_hbox = gender_sec.find_child("ChildRowHBox", true, false)
	if not adult_row_hbox:
		adult_row_hbox = gender_sec.find_child("AdultRowHBox", true, false)

	if not adult_row_hbox:
		adult_row_hbox = HBoxContainer.new()
		adult_row_hbox.name = "AdultRowHBox"
		adult_row_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		adult_row_hbox.add_theme_constant_override("separation", 12)
		gender_sec.add_child(adult_row_hbox)

		var b_af = Button.new()
		b_af.name = "BtnAdultFemale"
		b_af.custom_minimum_size = Vector2(160, 46)
		b_af.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_af.focus_mode = Control.FOCUS_NONE
		b_af.text = "👩 Adulta"
		adult_row_hbox.add_child(b_af)
		btn_adult_female = b_af

		var b_am = Button.new()
		b_am.name = "BtnAdultMale"
		b_am.custom_minimum_size = Vector2(160, 46)
		b_am.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_am.focus_mode = Control.FOCUS_NONE
		b_am.text = "👨 Adulto"
		adult_row_hbox.add_child(b_am)
		btn_adult_male = b_am
	else:
		if not btn_adult_female:
			btn_adult_female = adult_row_hbox.find_child("BtnAdultFemale", true, false)
		if not btn_adult_male:
			btn_adult_male = adult_row_hbox.find_child("BtnAdultMale", true, false)

	if child_row_hbox:
		if not btn_gender_girl:
			btn_gender_girl = child_row_hbox.find_child("BtnGenderGirl", true, false)
		if not btn_gender_boy:
			btn_gender_boy = child_row_hbox.find_child("BtnGenderBoy", true, false)

	# 3. Conectar señales si no están conectadas
	if btn_cat_child and not btn_cat_child.pressed.is_connected(_on_category_child_pressed):
		btn_cat_child.pressed.connect(_on_category_child_pressed)
	if btn_cat_adult and not btn_cat_adult.pressed.is_connected(_on_category_adult_pressed):
		btn_cat_adult.pressed.connect(_on_category_adult_pressed)
	if btn_gender_girl and not btn_gender_girl.pressed.is_connected(_on_select_girl_pressed):
		btn_gender_girl.pressed.connect(_on_select_girl_pressed)
	if btn_gender_boy and not btn_gender_boy.pressed.is_connected(_on_select_boy_pressed):
		btn_gender_boy.pressed.connect(_on_select_boy_pressed)
	if btn_adult_female and not btn_adult_female.pressed.is_connected(_on_select_adult_female_pressed):
		btn_adult_female.pressed.connect(_on_select_adult_female_pressed)
	if btn_adult_male and not btn_adult_male.pressed.is_connected(_on_select_adult_male_pressed):
		btn_adult_male.pressed.connect(_on_select_adult_male_pressed)

func _on_category_child_pressed() -> void:
	_selected_category = "child"
	_refresh_gender_buttons_ui()

func _on_category_adult_pressed() -> void:
	_selected_category = "adult"
	_refresh_gender_buttons_ui()

func _on_select_girl_pressed() -> void:
	_selected_gender = "f"
	_selected_category = "child"
	_refresh_gender_buttons_ui()

func _on_select_boy_pressed() -> void:
	_selected_gender = "m"
	_selected_category = "child"
	_refresh_gender_buttons_ui()

func _on_select_adult_female_pressed() -> void:
	_selected_gender = "f"
	_selected_category = "adult"
	_refresh_gender_buttons_ui()

func _on_select_adult_male_pressed() -> void:
	_selected_gender = "m"
	_selected_category = "adult"
	_refresh_gender_buttons_ui()

func _set_modal_archetype(g: String, cat: String) -> void:
	_selected_gender = g
	_selected_category = cat
	_refresh_gender_buttons_ui()

func _set_modal_gender(g: String) -> void:
	_set_modal_archetype(g, _selected_category)

func _refresh_gender_buttons_ui() -> void:
	var is_child_cat = (_selected_category != "adult")
	var is_adult_cat = (_selected_category == "adult")

	_style_category_button(btn_cat_child, "🧒 Modo Infantil", is_child_cat, Color("#EFF6FF"), Color("#3B82F6"), Color("#1D4ED8"))
	_style_category_button(btn_cat_adult, "🧑 Modo Adulto", is_adult_cat, Color("#FAF5FF"), Color("#8B5CF6"), Color("#6D28D9"))

	if child_row_hbox:
		child_row_hbox.visible = is_child_cat
	if adult_row_hbox:
		adult_row_hbox.visible = is_adult_cat

	var is_girl_sel = (_selected_gender == "f" and is_child_cat)
	var is_boy_sel = (_selected_gender == "m" and is_child_cat)
	var is_adult_f_sel = (_selected_gender == "f" and is_adult_cat)
	var is_adult_m_sel = (_selected_gender == "m" and is_adult_cat)

	_style_archetype_button(btn_gender_girl, "👧 Niña", is_girl_sel, Color("#FDF2F8"), Color("#EC4899"), Color("#BE185D"))
	_style_archetype_button(btn_gender_boy, "👦 Niño", is_boy_sel, Color("#EFF6FF"), Color("#3B82F6"), Color("#1D4ED8"))
	_style_archetype_button(btn_adult_female, "👩 Adulta", is_adult_f_sel, Color("#FAF5FF"), Color("#8B5CF6"), Color("#6D28D9"))
	_style_archetype_button(btn_adult_male, "👨 Adulto", is_adult_m_sel, Color("#ECFDF5"), Color("#10B981"), Color("#047857"))

func _style_category_button(btn: Button, base_text: String, is_selected: bool, bg_col: Color, border_col: Color, text_col: Color) -> void:
	if not btn:
		return
	btn.custom_minimum_size = Vector2(160, 48)

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(14)
	sb.anti_aliasing = true

	if is_selected:
		sb.bg_color = bg_col
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 6
		sb.border_color = border_col
		btn.text = "%s  ✓" % base_text
		btn.add_theme_color_override("font_color", text_col)
		btn.add_theme_font_size_override("font_size", 15)
	else:
		sb.bg_color = Color("#F1F5F9")
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 3
		sb.border_color = Color("#CBD5E1")
		btn.text = base_text
		btn.add_theme_color_override("font_color", Color("#64748B"))
		btn.add_theme_font_size_override("font_size", 14)

	var sb_hov = sb.duplicate()
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hov)
	btn.add_theme_stylebox_override("pressed", sb)

func _style_archetype_button(btn: Button, base_text: String, is_selected: bool, bg_col: Color, border_col: Color, text_col: Color) -> void:
	if not btn:
		return
	btn.custom_minimum_size = Vector2(160, 48)

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(16)
	sb.anti_aliasing = true

	if is_selected:
		sb.bg_color = bg_col
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 6
		sb.border_color = border_col
		btn.text = "%s  ✓" % base_text
		btn.add_theme_color_override("font_color", text_col)
		btn.add_theme_font_size_override("font_size", 16)
	else:
		sb.bg_color = Color("#F8FAFC")
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 3
		sb.border_color = Color("#CBD5E1")
		btn.text = base_text
		btn.add_theme_color_override("font_color", Color("#64748B"))
		btn.add_theme_font_size_override("font_size", 15)

	var sb_hov = sb.duplicate()
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hov)
	btn.add_theme_stylebox_override("pressed", sb)

func _on_save_profile_pressed() -> void:
	var pm = _get_pm()
	if not pm:
		return

	var entered_name = ""
	if edit_name_input:
		entered_name = edit_name_input.text.strip_edges()

	if entered_name.is_empty():
		if _selected_category == "adult":
			entered_name = "Adulta" if _selected_gender == "f" else "Adulto"
		else:
			entered_name = "Niña" if _selected_gender == "f" else "Niño"

	if _is_editing_existing:
		pm.update_profile(_target_edit_profile_id, entered_name, _selected_gender, _selected_category)
	else:
		pm.create_profile(entered_name, _selected_gender, _selected_category)

	if btn_cancel_edit_profile:
		btn_cancel_edit_profile.visible = true

	_close_edit_modal()
	if profile_select_overlay and profile_select_overlay.visible:
		_populate_select_list()

func _on_delete_profile_pressed() -> void:
	var pm = _get_pm()
	if not pm or not _is_editing_existing or _target_edit_profile_id.is_empty():
		return

	pm.delete_profile(_target_edit_profile_id)
	_close_edit_modal()
	if profile_select_overlay and profile_select_overlay.visible:
		_populate_select_list()

func _close_edit_modal() -> void:
	var pm = _get_pm()
	if pm and pm.is_first_time:
		return
	if profile_edit_overlay:
		profile_edit_overlay.visible = false

# =========================================================================
# LOBBY ONLINE Y MODO VERSUS
# =========================================================================

func _get_nm() -> Node:
	if has_node("/root/NetworkManager"):
		return get_node("/root/NetworkManager")
	if NetworkManagerClassScript.instance:
		return NetworkManagerClassScript.instance
	return null

func _setup_online_lobby_ui() -> void:
	if btn_online_versus and not btn_online_versus.pressed.is_connected(_open_online_lobby):
		btn_online_versus.pressed.connect(_open_online_lobby)

	if btn_close_lobby and not btn_close_lobby.pressed.is_connected(_close_online_lobby):
		btn_close_lobby.pressed.connect(_close_online_lobby)

	# Pestañas del Lobby
	if btn_tab_create and not btn_tab_create.pressed.is_connected(func(): _set_lobby_tab("create")):
		btn_tab_create.pressed.connect(func(): _set_lobby_tab("create"))
	if btn_tab_join and not btn_tab_join.pressed.is_connected(func(): _set_lobby_tab("join")):
		btn_tab_join.pressed.connect(func(): _set_lobby_tab("join"))
	if btn_tab_lan and not btn_tab_lan.pressed.is_connected(func(): _set_lobby_tab("lan")):
		btn_tab_lan.pressed.connect(func(): _set_lobby_tab("lan"))

	# Selección de Bando en Crear Sala
	if btn_color_white and not btn_color_white.pressed.is_connected(func(): _select_online_color("white")):
		btn_color_white.pressed.connect(func(): _select_online_color("white"))
	if btn_color_black and not btn_color_black.pressed.is_connected(func(): _select_online_color("black")):
		btn_color_black.pressed.connect(func(): _select_online_color("black"))
	if btn_color_random and not btn_color_random.pressed.is_connected(func(): _select_online_color("random")):
		btn_color_random.pressed.connect(func(): _select_online_color("random"))

	# Selección de Tiempo en Crear Sala
	if btn_time_none and not btn_time_none.pressed.is_connected(func(): _select_online_time(0)):
		btn_time_none.pressed.connect(func(): _select_online_time(0))
	if btn_time_3m and not btn_time_3m.pressed.is_connected(func(): _select_online_time(3)):
		btn_time_3m.pressed.connect(func(): _select_online_time(3))
	if btn_time_5m and not btn_time_5m.pressed.is_connected(func(): _select_online_time(5)):
		btn_time_5m.pressed.connect(func(): _select_online_time(5))
	if btn_time_10m and not btn_time_10m.pressed.is_connected(func(): _select_online_time(10)):
		btn_time_10m.pressed.connect(func(): _select_online_time(10))

	# Acciones de Crear y Unirse
	if btn_do_create_room and not btn_do_create_room.pressed.is_connected(_on_do_create_room_pressed):
		btn_do_create_room.pressed.connect(_on_do_create_room_pressed)
	if btn_copy_code and not btn_copy_code.pressed.is_connected(_on_copy_code_pressed):
		btn_copy_code.pressed.connect(_on_copy_code_pressed)
	if btn_cancel_created_room and not btn_cancel_created_room.pressed.is_connected(_on_cancel_created_room_pressed):
		btn_cancel_created_room.pressed.connect(_on_cancel_created_room_pressed)

	if btn_do_join_room and not btn_do_join_room.pressed.is_connected(_on_do_join_room_pressed):
		btn_do_join_room.pressed.connect(_on_do_join_room_pressed)

	# Acciones LAN
	if btn_do_lan_host and not btn_do_lan_host.pressed.is_connected(_on_do_lan_host_pressed):
		btn_do_lan_host.pressed.connect(_on_do_lan_host_pressed)
	if btn_do_lan_join and not btn_do_lan_join.pressed.is_connected(_on_do_lan_join_pressed):
		btn_do_lan_join.pressed.connect(_on_do_lan_join_pressed)

	# Señales de NetworkManager
	var nm = _get_nm()
	if nm:
		if not nm.room_created.is_connected(_on_network_room_created):
			nm.room_created.connect(_on_network_room_created)
		if not nm.room_join_failed.is_connected(_on_network_join_failed):
			nm.room_join_failed.connect(_on_network_join_failed)
		if not nm.opponent_joined.is_connected(_on_network_opponent_joined):
			nm.opponent_joined.connect(_on_network_opponent_joined)

func _open_online_lobby() -> void:
	if online_lobby_overlay:
		_open_styled_popup(online_lobby_overlay, lobby_card)
	_set_lobby_tab("create")
	_select_online_color(_selected_online_color)
	_select_online_time(_selected_online_time)
	_reset_create_view()

func _close_online_lobby() -> void:
	if online_lobby_overlay:
		online_lobby_overlay.visible = false
	var nm = _get_nm()
	if nm:
		nm.leave_current_session()

func _set_lobby_tab(tab_name: String) -> void:
	_current_lobby_tab = tab_name
	if create_room_view: create_room_view.visible = (tab_name == "create")
	if join_room_view: join_room_view.visible = (tab_name == "join")
	if lan_room_view: lan_room_view.visible = (tab_name == "lan")
	_update_lobby_tabs_ui()

func _select_online_color(color_name: String) -> void:
	_selected_online_color = color_name
	_update_color_buttons_ui()

func _select_online_time(minutes: int) -> void:
	_selected_online_time = minutes
	_update_time_buttons_ui()

func _create_style_box(bg: Color, border_c: Color, border_w: int, border_b: int, radius: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border_c
	sb.border_width_left = border_w
	sb.border_width_top = border_w
	sb.border_width_right = border_w
	sb.border_width_bottom = border_b
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	return sb

func _apply_btn_style(btn: Button, style: StyleBoxFlat, font_color: Color) -> void:
	if not is_instance_valid(btn):
		return
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", font_color)
	btn.add_theme_color_override("font_pressed_color", font_color)

func _update_lobby_tabs_ui() -> void:
	var active_style = _create_style_box(Color("#ec4899"), Color("#be185d"), 0, 4, 10)
	var inactive_style = _create_style_box(Color("#f3f4f6"), Color("#d1d5db"), 1, 2, 10)

	if btn_tab_create:
		var is_act = (_current_lobby_tab == "create")
		_apply_btn_style(btn_tab_create, active_style if is_act else inactive_style, Color.WHITE if is_act else Color("#4b5563"))
	if btn_tab_join:
		var is_act = (_current_lobby_tab == "join")
		_apply_btn_style(btn_tab_join, active_style if is_act else inactive_style, Color.WHITE if is_act else Color("#4b5563"))
	if btn_tab_lan:
		var is_act = (_current_lobby_tab == "lan")
		_apply_btn_style(btn_tab_lan, active_style if is_act else inactive_style, Color.WHITE if is_act else Color("#4b5563"))

func _update_color_buttons_ui() -> void:
	var sel_style = _create_style_box(Color("#059669"), Color("#047857"), 0, 3, 8)
	var unsel_style = _create_style_box(Color("#f3f4f6"), Color("#d1d5db"), 1, 2, 8)

	if btn_color_white:
		var is_sel = (_selected_online_color == "white")
		_apply_btn_style(btn_color_white, sel_style if is_sel else unsel_style, Color.WHITE if is_sel else Color("#374151"))
		btn_color_white.text = "⚪ Blancas ✓" if is_sel else "⚪ Blancas"

	if btn_color_black:
		var is_sel = (_selected_online_color == "black")
		_apply_btn_style(btn_color_black, sel_style if is_sel else unsel_style, Color.WHITE if is_sel else Color("#374151"))
		btn_color_black.text = "⚫ Negras ✓" if is_sel else "⚫ Negras"

	if btn_color_random:
		var is_sel = (_selected_online_color == "random")
		_apply_btn_style(btn_color_random, sel_style if is_sel else unsel_style, Color.WHITE if is_sel else Color("#374151"))
		btn_color_random.text = "🎲 Aleatorio ✓" if is_sel else "🎲 Aleatorio"

func _update_time_buttons_ui() -> void:
	var sel_style = _create_style_box(Color("#059669"), Color("#047857"), 0, 3, 8)
	var unsel_style = _create_style_box(Color("#f3f4f6"), Color("#d1d5db"), 1, 2, 8)

	if btn_time_none:
		var is_sel = (_selected_online_time == 0)
		_apply_btn_style(btn_time_none, sel_style if is_sel else unsel_style, Color.WHITE if is_sel else Color("#374151"))
		btn_time_none.text = "Sin reloj ✓" if is_sel else "Sin reloj"

	if btn_time_3m:
		var is_sel = (_selected_online_time == 3)
		_apply_btn_style(btn_time_3m, sel_style if is_sel else unsel_style, Color.WHITE if is_sel else Color("#374151"))
		btn_time_3m.text = "⚡ 3 Min ✓" if is_sel else "⚡ 3 Min"

	if btn_time_5m:
		var is_sel = (_selected_online_time == 5)
		_apply_btn_style(btn_time_5m, sel_style if is_sel else unsel_style, Color.WHITE if is_sel else Color("#374151"))
		btn_time_5m.text = "⏱️ 5 Min ✓" if is_sel else "⏱️ 5 Min"

	if btn_time_10m:
		var is_sel = (_selected_online_time == 10)
		_apply_btn_style(btn_time_10m, sel_style if is_sel else unsel_style, Color.WHITE if is_sel else Color("#374151"))
		btn_time_10m.text = "⏳ 10 Min ✓" if is_sel else "⏳ 10 Min"

func _reset_create_view() -> void:
	if btn_do_create_room:
		btn_do_create_room.visible = true
		btn_do_create_room.disabled = false
	if waiting_container:
		waiting_container.visible = false

func _on_do_create_room_pressed() -> void:
	var nm = _get_nm()
	if not nm:
		return

	var pm = _get_pm()
	var player_name = pm.get_active_profile().name if pm else "Jugador"
	var code = NetworkManagerClassScript.generate_room_code()

	if btn_do_create_room:
		btn_do_create_room.disabled = true
		btn_do_create_room.visible = false

	nm.create_online_room(code, player_name, _selected_online_time, _selected_online_color)

func _on_network_room_created(code: String) -> void:
	if room_code_label:
		room_code_label.text = code
	if waiting_container:
		waiting_container.visible = true
	if waiting_status_label:
		waiting_status_label.text = "Esperando que tu amigo se una con el código... ⏳"

func _on_copy_code_pressed() -> void:
	if room_code_label:
		DisplayServer.clipboard_set(room_code_label.text)
	if btn_copy_code:
		btn_copy_code.text = "¡Copiado! ✓"
		get_tree().create_timer(1.8).timeout.connect(func():
			if btn_copy_code: btn_copy_code.text = "📋 Copiar"
		)

func _on_cancel_created_room_pressed() -> void:
	var nm = _get_nm()
	if nm:
		nm.leave_current_session()
	_reset_create_view()

func _on_do_join_room_pressed() -> void:
	var nm = _get_nm()
	if not nm or not join_code_input:
		return

	var code = join_code_input.text.strip_edges().to_upper()
	if code == "":
		if join_status_label:
			join_status_label.text = "Por favor ingresa un código de sala válido."
		return

	if join_status_label:
		join_status_label.text = "Conectando a la sala %s... ⏳" % code
	if btn_do_join_room:
		btn_do_join_room.disabled = true

	var pm = _get_pm()
	var guest_name = pm.get_active_profile().name if pm else "Jugador"
	nm.join_online_room(code, guest_name)

func _on_network_join_failed(reason: String) -> void:
	if join_status_label:
		join_status_label.text = reason
	if lan_status_label:
		lan_status_label.text = reason
	if btn_do_join_room:
		btn_do_join_room.disabled = false
	if btn_do_lan_join:
		btn_do_lan_join.disabled = false

func _on_do_lan_host_pressed() -> void:
	var nm = _get_nm()
	if not nm:
		return

	var pm = _get_pm()
	var host_name = pm.get_active_profile().name if pm else "Host"
	var err = nm.start_lan_host(nm.enet_default_port, host_name, _selected_online_time, _selected_online_color)
	if err == OK:
		if lan_status_label:
			lan_status_label.text = "Servidor LAN iniciado en puerto %d. Esperando rival..." % nm.enet_default_port
		if btn_do_lan_host:
			btn_do_lan_host.disabled = true
	else:
		if lan_status_label:
			lan_status_label.text = "Error al iniciar LAN (código: %d)." % err

func _on_do_lan_join_pressed() -> void:
	var nm = _get_nm()
	if not nm or not lan_ip_input:
		return

	var ip = lan_ip_input.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"

	var pm = _get_pm()
	var guest_name = pm.get_active_profile().name if pm else "Invitado"

	if lan_status_label:
		lan_status_label.text = "Conectando a %s:%d..." % [ip, nm.enet_default_port]
	if btn_do_lan_join:
		btn_do_lan_join.disabled = true

	var err = nm.join_lan_game(ip, nm.enet_default_port, guest_name)
	if err != OK:
		if lan_status_label:
			lan_status_label.text = "Error al conectar por LAN (código: %d)." % err
		if btn_do_lan_join:
			btn_do_lan_join.disabled = false

func _on_network_opponent_joined(_opponent_name: String, _your_color: String) -> void:
	get_tree().change_scene_to_file("res://scenes/tablero_online.tscn")

# =========================================================================
# RESPONSIVIDAD Y ESCALADO MÓVIL
# =========================================================================


# =========================================================================
# GESTIÓN DEL HISTORIAL DE PARTIDAS
# =========================================================================

func _setup_match_history_ui() -> void:
	if btn_close_history_modal and not btn_close_history_modal.pressed.is_connected(_close_history_overlay):
		btn_close_history_modal.pressed.connect(_close_history_overlay)

	if btn_clear_all_history and not btn_clear_all_history.pressed.is_connected(_on_clear_history_pressed):
		btn_clear_all_history.pressed.connect(_on_clear_history_pressed)

	if btn_filter_all and not btn_filter_all.pressed.is_connected(_on_filter_all_pressed):
		btn_filter_all.pressed.connect(_on_filter_all_pressed)

	if btn_filter_bots and not btn_filter_bots.pressed.is_connected(_on_filter_bots_pressed):
		btn_filter_bots.pressed.connect(_on_filter_bots_pressed)

	if btn_filter_versus and not btn_filter_versus.pressed.is_connected(_on_filter_versus_pressed):
		btn_filter_versus.pressed.connect(_on_filter_versus_pressed)

	if history_scroll_container:
		history_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		history_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		if not history_scroll_container.gui_input.is_connected(_on_history_scroll_gui_input):
			history_scroll_container.gui_input.connect(_on_history_scroll_gui_input)
		var vbar = history_scroll_container.get_v_scroll_bar()
		if vbar and not vbar.value_changed.is_connected(_on_modal_scroll_value_changed):
			vbar.value_changed.connect(_on_modal_scroll_value_changed)

	if history_content:
		history_content.mouse_filter = Control.MOUSE_FILTER_PASS
		if not history_content.gui_input.is_connected(_on_history_scroll_gui_input):
			history_content.gui_input.connect(_on_history_scroll_gui_input)

	if history_list_vbox:
		history_list_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		if not history_list_vbox.gui_input.is_connected(_on_history_scroll_gui_input):
			history_list_vbox.gui_input.connect(_on_history_scroll_gui_input)

func _on_filter_all_pressed() -> void:
	_set_history_filter("all")

func _on_filter_bots_pressed() -> void:
	_set_history_filter("bot")

func _on_filter_versus_pressed() -> void:
	_set_history_filter("versus")

func _open_history_overlay() -> void:
	if match_history_overlay:
		_open_styled_popup(match_history_overlay, history_card)

	var is_mob: bool = false
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if sm.has_method("is_mobile"):
			is_mob = sm.is_mobile()

	if history_card:
		var vp_sz = get_viewport().get_visible_rect().size
		if is_mob:
			history_card.custom_minimum_size = Vector2(minf(vp_sz.x - 20.0, 680.0), minf(vp_sz.y - 40.0, 640.0))
		else:
			history_card.custom_minimum_size = Vector2(660, 540)

	for btn in [btn_filter_all, btn_filter_bots, btn_filter_versus]:
		if is_instance_valid(btn):
			btn.custom_minimum_size.y = 44.0 if is_mob else 34.0
			btn.add_theme_font_size_override("font_size", 15 if is_mob else 13)

	_render_history_list()

func _close_history_overlay() -> void:
	if match_history_overlay:
		match_history_overlay.visible = false

func _set_history_filter(filter_name: String) -> void:
	_current_history_filter = filter_name
	_update_history_filter_tabs()
	_render_history_list()

func _update_history_filter_tabs() -> void:
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = Color("#6366F1")
	active_style.border_width_bottom = 4
	active_style.border_color = Color("#4338CA")
	active_style.set_corner_radius_all(16)
	active_style.anti_aliasing = true

	var inactive_style = StyleBoxFlat.new()
	inactive_style.bg_color = Color("#F1F5F9")
	inactive_style.border_width_bottom = 3
	inactive_style.border_color = Color("#CBD5E1")
	inactive_style.set_corner_radius_all(16)
	inactive_style.anti_aliasing = true

	if btn_filter_all:
		var is_act = (_current_history_filter == "all")
		_apply_btn_style(btn_filter_all, active_style if is_act else inactive_style, Color.WHITE if is_act else Color("#475569"))
	if btn_filter_bots:
		var is_act = (_current_history_filter == "bot")
		_apply_btn_style(btn_filter_bots, active_style if is_act else inactive_style, Color.WHITE if is_act else Color("#475569"))
	if btn_filter_versus:
		var is_act = (_current_history_filter == "versus")
		_apply_btn_style(btn_filter_versus, active_style if is_act else inactive_style, Color.WHITE if is_act else Color("#475569"))

func _on_clear_history_pressed() -> void:
	var mhm = _get_mhm()
	if mhm:
		mhm.clear_history()
	_render_history_list()

func _render_history_list() -> void:
	if not history_list_vbox:
		return

	# Limpiar elementos anteriores
	for child in history_list_vbox.get_children():
		child.queue_free()

	var mhm = _get_mhm()
	var all_matches: Array[Dictionary] = []
	if mhm:
		all_matches = mhm.get_all_matches()

	var bot_count: int = 0
	var versus_count: int = 0
	for m in all_matches:
		if m.get("mode", "") == "bot":
			bot_count += 1
		elif m.get("mode", "") == "versus":
			versus_count += 1

	if btn_filter_all:
		btn_filter_all.text = "Todas (%d)" % all_matches.size()
	if btn_filter_bots:
		btn_filter_bots.text = "🐣 Contra Bots (%d)" % bot_count
	if btn_filter_versus:
		btn_filter_versus.text = "🌐 Versus (%d)" % versus_count

	_update_history_filter_tabs()

	var displayed_matches: Array[Dictionary] = []
	for m in all_matches:
		if _current_history_filter == "all":
			displayed_matches.append(m)
		elif m.get("mode", "") == _current_history_filter:
			displayed_matches.append(m)

	if displayed_matches.is_empty():
		if empty_history_label:
			empty_history_label.visible = true
			if all_matches.is_empty():
				empty_history_label.text = "Aún no tienes partidas registradas en el historial.\n\n¡Juega una partida contra los Bots o en Modo Versus\ny se guardará automáticamente aquí para revisarla!"
			else:
				empty_history_label.text = "No hay partidas en esta categoría."
		return

	if empty_history_label:
		empty_history_label.visible = false

	for match_data in displayed_matches:
		var card = _create_match_card(match_data)
		history_list_vbox.add_child(card)

func _create_match_card(m: Dictionary) -> Control:
	var is_mob: bool = false
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if sm.has_method("is_mobile"):
			is_mob = sm.is_mobile()

	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.gui_input.connect(func(ev): _handle_modal_scroll_gui_input(history_scroll_container, ev))
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("#ffffff")
	card_style.set_border_width_all(1)
	card_style.border_color = Color("#e2e8f0")
	card_style.set_corner_radius_all(12)
	card_style.content_margin_left = 14
	card_style.content_margin_right = 14
	card_style.content_margin_top = 10
	card_style.content_margin_bottom = 10
	card_style.shadow_color = Color(0, 0, 0, 0.04)
	card_style.shadow_size = 4
	card_style.shadow_offset = Vector2(0, 2)
	panel.add_theme_stylebox_override("panel", card_style)

	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	# Columna Izquierda: Datos de la partida
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	# Fila 1: Badges y Fecha
	var row1 = HBoxContainer.new()
	row1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)

	var mode_str = m.get("mode", "bot")
	var mode_badge = Label.new()
	mode_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mode_style = StyleBoxFlat.new()
	mode_style.set_corner_radius_all(6)
	mode_style.content_margin_left = 6
	mode_style.content_margin_right = 6
	mode_style.content_margin_top = 2
	mode_style.content_margin_bottom = 2
	if mode_str == "bot":
		mode_badge.text = "🐣 BOT"
		mode_style.bg_color = Color("#fdf2f8")
		mode_badge.add_theme_color_override("font_color", Color("#db2777"))
	else:
		mode_badge.text = "🌐 VERSUS"
		mode_style.bg_color = Color("#f0fdf4")
		mode_badge.add_theme_color_override("font_color", Color("#059669"))
	mode_badge.add_theme_stylebox_override("normal", mode_style)
	mode_badge.add_theme_font_size_override("font_size", 13 if is_mob else 11)
	row1.add_child(mode_badge)

	var res = m.get("result", "draw")
	var res_title = m.get("result_title", "Tablas")
	var res_badge = Label.new()
	res_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var res_style = StyleBoxFlat.new()
	res_style.set_corner_radius_all(6)
	res_style.content_margin_left = 6
	res_style.content_margin_right = 6
	res_style.content_margin_top = 2
	res_style.content_margin_bottom = 2

	if res == "victory":
		res_badge.text = "🏆 " + res_title.to_upper()
		res_style.bg_color = Color("#dcfce7")
		res_badge.add_theme_color_override("font_color", Color("#15803d"))
	elif res == "defeat":
		res_badge.text = "💔 " + res_title.to_upper()
		res_style.bg_color = Color("#fee2e2")
		res_badge.add_theme_color_override("font_color", Color("#dc2626"))
	else:
		res_badge.text = "🤝 " + res_title.to_upper()
		res_style.bg_color = Color("#e0e7ff")
		res_badge.add_theme_color_override("font_color", Color("#4338ca"))
	res_badge.add_theme_stylebox_override("normal", res_style)
	res_badge.add_theme_font_size_override("font_size", 13 if is_mob else 11)
	row1.add_child(res_badge)

	var date_lbl = Label.new()
	date_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	date_lbl.text = "• " + str(m.get("date", ""))
	date_lbl.add_theme_color_override("font_color", Color("#64748b"))
	date_lbl.add_theme_font_size_override("font_size", 14 if is_mob else 12)
	row1.add_child(date_lbl)

	# Fila 2: Título del oponente y razón
	var opp_name = str(m.get("opponent_name", "Rival"))
	var reason = str(m.get("reason", ""))
	var row2 = Label.new()
	row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row2.text = "vs %s (%s)" % [opp_name, reason] if not reason.is_empty() else "vs %s" % opp_name
	row2.add_theme_color_override("font_color", Color("#1e293b"))
	row2.add_theme_font_size_override("font_size", 17 if is_mob else 14)
	vbox.add_child(row2)

	# Fila 3: Estadísticas (Turnos, duración, color)
	var moves_cnt = int(m.get("moves_count", 0))
	var dur_sec = int(m.get("duration_seconds", 0))
	var dur_str = "%02d:%02d" % [dur_sec / 60, dur_sec % 60]
	var p_color_str = "Blancas" if m.get("player_color", "w") == "w" else "Negras"
	var row3 = Label.new()
	row3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row3.text = "♟️ %d jugadas • ⏱️ %s • 👤 %s" % [moves_cnt, dur_str, p_color_str]
	row3.add_theme_color_override("font_color", Color("#64748b"))
	row3.add_theme_font_size_override("font_size", 14 if is_mob else 12)
	vbox.add_child(row3)

	# Columna Derecha: Botón Revisar y Botón Eliminar
	var actions_vbox = VBoxContainer.new()
	actions_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(actions_vbox)

	var btn_rev = Button.new()
	btn_rev.text = "🔍 Revisar"
	btn_rev.custom_minimum_size = Vector2(115, 42) if is_mob else Vector2(105, 36)
	var rev_style = _create_style_box(Color("#6366f1"), Color("#4338ca"), 0, 3, 8)
	_apply_btn_style(btn_rev, rev_style, Color.WHITE)
	btn_rev.add_theme_font_size_override("font_size", 15 if is_mob else 13)
	btn_rev.gui_input.connect(func(ev): _handle_modal_scroll_gui_input(history_scroll_container, ev))
	btn_rev.pressed.connect(func():
		if not _can_interact_modal_buttons():
			return
		_review_saved_match(m)
	)
	actions_vbox.add_child(btn_rev)

	var btn_del = Button.new()
	btn_del.text = "🗑️ Eliminar"
	btn_del.custom_minimum_size = Vector2(115, 34) if is_mob else Vector2(105, 26)
	var del_style = _create_style_box(Color("#f8fafc"), Color("#cbd5e1"), 1, 1, 6)
	_apply_btn_style(btn_del, del_style, Color("#64748b"))
	btn_del.add_theme_font_size_override("font_size", 13 if is_mob else 11)
	btn_del.gui_input.connect(func(ev): _handle_modal_scroll_gui_input(history_scroll_container, ev))
	var match_id = str(m.get("id", ""))
	btn_del.pressed.connect(func():
		if not _can_interact_modal_buttons():
			return
		_delete_saved_match(match_id)
	)
	actions_vbox.add_child(btn_del)

	return panel

func _review_saved_match(match_data: Dictionary) -> void:
	var mhm = _get_mhm()
	if mhm:
		mhm.set_review_match(match_data, true)
	get_tree().change_scene_to_file("res://tablero_juego.tscn")

func _delete_saved_match(match_id: String) -> void:
	var mhm = _get_mhm()
	if mhm:
		mhm.delete_match(match_id)
	_render_history_list()
	_update_mobile_profile_and_stats()

func _setup_responsive_menu() -> void:
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if not sm.orientation_changed.is_connected(_on_orientation_changed):
			sm.orientation_changed.connect(_on_orientation_changed)
		if sm.has_signal("mobile_mode_changed") and not sm.mobile_mode_changed.is_connected(_on_mobile_mode_changed):
			sm.mobile_mode_changed.connect(_on_mobile_mode_changed)
		if sm.has_signal("safe_area_changed") and not sm.safe_area_changed.is_connected(_on_safe_area_changed):
			sm.safe_area_changed.connect(_on_safe_area_changed)
	if has_node("/root/AcademyManager"):
		var am = get_node("/root/AcademyManager")
		if am.has_signal("progress_updated") and not am.progress_updated.is_connected(_update_mobile_profile_and_stats):
			am.progress_updated.connect(_update_mobile_profile_and_stats)
	var vp = get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_resized):
		vp.size_changed.connect(_on_viewport_resized)
	call_deferred("_update_responsive_menu")

func _on_mobile_mode_changed(_active: bool) -> void:
	_update_responsive_menu()

func _on_orientation_changed(_is_portrait: bool) -> void:
	_update_responsive_menu()

func _on_safe_area_changed(_top: float) -> void:
	_update_responsive_menu()

func _on_viewport_resized() -> void:
	_update_responsive_menu()

func _update_responsive_menu() -> void:
	var vp = get_viewport()
	if not vp:
		return
	var vp_size = vp.get_visible_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		return
	var is_portrait = vp_size.y > vp_size.x

	var is_mob: bool = false
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if sm.has_method("is_mobile"):
			is_mob = sm.is_mobile()

	# Alternar entre el nuevo Menú Escénico Android y la tarjeta clásica de PC
	var center_node = get_node_or_null("Center") as Control
	var deco_node = get_node_or_null("DecorativeDeco") as Control
	if center_node:
		center_node.visible = not is_mob
	if deco_node:
		deco_node.visible = not is_mob
	if _mobile_root:
		_mobile_root.visible = is_mob
	if not is_mob and _mobile_mode_popup:
		_mobile_mode_popup.visible = false

	if is_mob:
		_update_mobile_profile_and_stats()
		_layout_mobile_scenic_menu(vp_size, is_portrait)

	if menu_card:
		if is_mob:
			if is_portrait:
				var target_w = clampf(vp_size.x * 0.94, 460.0, 680.0)
				menu_card.custom_minimum_size = Vector2(target_w, 660.0)
			else:
				menu_card.custom_minimum_size = Vector2(560.0, 640.0)
		else:
			if is_portrait:
				var target_w = clampf(vp_size.x * 0.88, 440.0, 560.0)
				menu_card.custom_minimum_size = Vector2(target_w, 610.0)
			else:
				menu_card.custom_minimum_size = Vector2(500.0, 610.0)

	_apply_menu_scaling(is_mob, is_portrait, vp_size.x)
	_adjust_modal_widths(is_portrait, vp_size.x)

func _apply_menu_scaling(is_mob: bool, is_portrait: bool, vp_width: float) -> void:
	var main_btns = [btn_academy, btn_practice_bot, btn_online_versus, btn_match_history]
	var btn_min_h = 62.0 if is_mob else 54.0
	var btn_font_size = 21 if is_mob else 18
	var btn_min_w = (vp_width * 0.86 if is_portrait else 420.0) if is_mob else 340.0

	for b in main_btns:
		if b:
			b.custom_minimum_size = Vector2(btn_min_w, btn_min_h)
			b.add_theme_font_size_override("font_size", btn_font_size)
			if is_mob and is_portrait:
				b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			else:
				b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var prof_btns = [btn_change_profile, btn_edit_profile, btn_new_profile]
	var prof_h = 44.0 if is_mob else 32.0
	var prof_font = 15 if is_mob else 12
	var prof_min_w = 110.0 if is_mob else 90.0
	for pb in prof_btns:
		if pb:
			pb.custom_minimum_size = Vector2(prof_min_w, prof_h)
			pb.add_theme_font_size_override("font_size", prof_font)

	var sub_hdr = find_child("SubHeader", true, false) as Label
	if sub_hdr:
		sub_hdr.add_theme_font_size_override("font_size", 20 if is_mob else 16)
	var main_hdr = find_child("MainHeader", true, false) as Label
	if main_hdr:
		main_hdr.add_theme_font_size_override("font_size", 32 if is_mob else 26)
	var subt = find_child("Subtitle", true, false) as Label
	if subt:
		subt.add_theme_font_size_override("font_size", 15 if is_mob else 13)
	if active_profile_name:
		active_profile_name.add_theme_font_size_override("font_size", 17 if is_mob else 14)

func _adjust_modal_widths(is_portrait: bool, vp_width: float) -> void:
	var is_mob: bool = false
	if has_node("/root/ScreenManager"):
		var sm = get_node("/root/ScreenManager")
		if sm.has_method("is_mobile"):
			is_mob = sm.is_mobile()

	var max_modal_w = vp_width - 36.0 if is_portrait else 540.0
	var modals = [profile_select_overlay, profile_edit_overlay, online_lobby_overlay, match_history_overlay]
	for m in modals:
		if m:
			var center_c = m.get_node_or_null("Center")
			if center_c and center_c.get_child_count() > 0:
				var card = center_c.get_child(0) as Control
				if card:
					if is_portrait:
						card.custom_minimum_size.x = minf(card.custom_minimum_size.x, max_modal_w)
					card.pivot_offset = card.size * 0.5
					if is_mob and is_portrait:
						var s: float = clampf((vp_width * 0.90) / maxf(card.custom_minimum_size.x, 440.0), 1.0, 1.24)
						card.scale = Vector2(s, s)
					else:
						card.scale = Vector2.ONE

# =========================================================================
# NUEVO MENÚ PRINCIPAL ESCÉNICO EXCLUSIVO PARA ANDROID (DISEÑO V2)
# =========================================================================

func _build_mobile_scenic_menu() -> void:
	if _mobile_root:
		return

	_mobile_root = Control.new()
	_mobile_root.name = "MobileScenicMenu"
	_mobile_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mobile_root.visible = false
	_mobile_root.z_index = 10
	_mobile_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mobile_root)

	# 1. Lienzo escénico (Cielo pastel, nubes animadas, colinas, árboles, flores y tablero 3D)
	_mobile_bg_canvas = Control.new()
	_mobile_bg_canvas.name = "ScenicBackground"
	_mobile_bg_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mobile_bg_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_bg_canvas.draw.connect(_on_draw_mobile_scenic)
	_mobile_root.add_child(_mobile_bg_canvas)

	# 2. Personaje central vivo: Profe Pollito sobre el tablero 3D
	_mobile_gallo = GALLO_SCENE_MOB.instantiate() as GalloProfe
	_mobile_gallo.name = "MobileGalloProfe"
	_mobile_root.add_child(_mobile_gallo)
	call_deferred("_trigger_initial_mobile_gallo_wave")

	# Botón táctil invisible sobre Pollito para que al tocarlo salude o celebre
	var gallo_touch := Button.new()
	gallo_touch.name = "GalloTouchArea"
	gallo_touch.flat = true
	gallo_touch.focus_mode = Control.FOCUS_NONE
	gallo_touch.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty_sb := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		gallo_touch.add_theme_stylebox_override(st, empty_sb)
	gallo_touch.pressed.connect(func():
		if _mobile_gallo:
			if randf() < 0.5:
				_mobile_gallo.celebrar(1.8)
			else:
				_mobile_gallo.saludar(1.8)
	)
	_mobile_root.add_child(gallo_touch)

	# 3. Píldoras superiores de progreso (Estrellas de Academia y Victorias)
	_mob_top_bar = HBoxContainer.new()
	_mob_top_bar.name = "TopStatusPills"
	_mob_top_bar.add_theme_constant_override("separation", 16)
	_mobile_root.add_child(_mob_top_bar)

	var stars_pill := _create_mobile_status_pill("star")
	_mob_lbl_stars = stars_pill.get_meta("value_label") as Label
	_mob_top_bar.add_child(stars_pill)

	var wins_pill := _create_mobile_status_pill("trophy")
	_mob_lbl_wins = wins_pill.get_meta("value_label") as Label
	_mob_top_bar.add_child(wins_pill)

	# 3b. Píldora superior derecha: Versión y Actualizador OTA
	_mob_btn_update = Button.new()
	_mob_btn_update.name = "BtnMobileUpdate"
	_mob_btn_update.text = "🔄 v1.0.0"
	_mob_btn_update.focus_mode = Control.FOCUS_NONE
	_mob_btn_update.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_mob_btn_update.add_theme_font_override("font", CHERRY_FONT_MOB)
	_mob_btn_update.add_theme_font_size_override("font_size", 22)
	_mob_btn_update.add_theme_color_override("font_color", Color("#9D174D"))
	_mob_btn_update.add_theme_color_override("font_hover_color", Color("#BE185D"))
	_mob_btn_update.add_theme_color_override("font_pressed_color", Color("#831843"))
	_apply_mobile_update_pill_style(false)
	_mob_btn_update.pressed.connect(_on_update_button_pressed)
	_mobile_root.add_child(_mob_btn_update)

	# 4. Saludo gigante en el cielo ("¡Hola!" + Nombre del perfil activo)
	_mob_greeting_box = VBoxContainer.new()
	_mob_greeting_box.name = "SkyGreetingBox"
	_mob_greeting_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_mob_greeting_box.add_theme_constant_override("separation", -4)
	_mob_greeting_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_root.add_child(_mob_greeting_box)

	_mob_lbl_hello = Label.new()
	_mob_lbl_hello.text = "¡Hola!"
	_mob_lbl_hello.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mob_lbl_hello.add_theme_font_override("font", CHERRY_FONT_MOB)
	_mob_lbl_hello.add_theme_color_override("font_color", Color.WHITE)
	_mob_lbl_hello.add_theme_color_override("font_outline_color", Color("#BE185D"))
	_mob_lbl_hello.add_theme_constant_override("outline_size", 10)
	_mob_lbl_hello.add_theme_color_override("font_shadow_color", Color(0.75, 0.09, 0.36, 0.28))
	_mob_lbl_hello.add_theme_constant_override("shadow_offset_x", 0)
	_mob_lbl_hello.add_theme_constant_override("shadow_offset_y", 4)
	_mob_greeting_box.add_child(_mob_lbl_hello)

	_mob_lbl_player_name = Label.new()
	_mob_lbl_player_name.text = "Lyanna"
	_mob_lbl_player_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mob_lbl_player_name.add_theme_font_override("font", CHERRY_FONT_MOB)
	_mob_lbl_player_name.add_theme_color_override("font_color", Color("#DB2777"))
	_mob_lbl_player_name.add_theme_color_override("font_outline_color", Color.WHITE)
	_mob_lbl_player_name.add_theme_constant_override("outline_size", 16)
	_mob_lbl_player_name.add_theme_color_override("font_shadow_color", Color(0.75, 0.09, 0.36, 0.25))
	_mob_lbl_player_name.add_theme_constant_override("shadow_offset_x", 0)
	_mob_lbl_player_name.add_theme_constant_override("shadow_offset_y", 5)
	_mob_greeting_box.add_child(_mob_lbl_player_name)

	# 5. Botón gigante "¡Nueva Partida!"
	_mob_btn_new_game = Button.new()
	_mob_btn_new_game.name = "BtnMobileNewGame"
	_mob_btn_new_game.text = "¡Nueva Partida!"
	_mob_btn_new_game.focus_mode = Control.FOCUS_NONE
	_mob_btn_new_game.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_mob_btn_new_game.add_theme_font_override("font", CHERRY_FONT_MOB)
	_mob_btn_new_game.add_theme_color_override("font_color", Color.WHITE)
	_mob_btn_new_game.add_theme_color_override("font_hover_color", Color.WHITE)
	_mob_btn_new_game.add_theme_color_override("font_pressed_color", Color("#FEF08A"))
	_mob_btn_new_game.add_theme_color_override("font_outline_color", Color("#831843"))
	_mob_btn_new_game.add_theme_constant_override("outline_size", 11)

	var cta_norm := StyleBoxFlat.new()
	cta_norm.bg_color = Color("#EC4899")
	cta_norm.border_width_left = 4
	cta_norm.border_width_top = 4
	cta_norm.border_width_right = 4
	cta_norm.border_width_bottom = 11
	cta_norm.border_color = Color("#FDE047")
	cta_norm.set_corner_radius_all(48)
	cta_norm.shadow_color = Color(0.616, 0.09, 0.302, 0.42)
	cta_norm.shadow_size = 14
	cta_norm.shadow_offset = Vector2(0, 7)
	cta_norm.anti_aliasing = true

	var cta_hov := cta_norm.duplicate()
	cta_hov.bg_color = Color("#F472B6")

	var cta_press := cta_norm.duplicate()
	cta_press.bg_color = Color("#DB2777")
	cta_press.border_width_bottom = 6
	cta_press.shadow_offset = Vector2(0, 3)

	_mob_btn_new_game.add_theme_stylebox_override("normal", cta_norm)
	_mob_btn_new_game.add_theme_stylebox_override("hover", cta_hov)
	_mob_btn_new_game.add_theme_stylebox_override("pressed", cta_press)
	_mob_btn_new_game.pressed.connect(_open_mobile_mode_popup)
	_mobile_root.add_child(_mob_btn_new_game)

	# Brillo superior cristalino dentro del botón "¡Nueva Partida!"
	_mob_btn_gloss = Panel.new()
	_mob_btn_gloss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gloss_sb := StyleBoxFlat.new()
	gloss_sb.bg_color = Color(1.0, 1.0, 1.0, 0.22)
	gloss_sb.set_corner_radius_all(24)
	_mob_btn_gloss.add_theme_stylebox_override("panel", gloss_sb)
	_mob_btn_new_game.add_child(_mob_btn_gloss)

	# 6. Barra de navegación inferior con 3 botones grandes (Academia, Historial, Perfil)
	_mob_bottom_bar = PanelContainer.new()
	_mob_bottom_bar.name = "MobileBottomNavBar"
	var bar_sb := StyleBoxFlat.new()
	bar_sb.bg_color = Color("#BE185D")
	bar_sb.border_width_top = 5
	bar_sb.border_color = Color("#FDE047")
	bar_sb.content_margin_left = 18
	bar_sb.content_margin_right = 18
	bar_sb.content_margin_top = 12
	bar_sb.content_margin_bottom = 14
	_mob_bottom_bar.add_theme_stylebox_override("panel", bar_sb)
	_mobile_root.add_child(_mob_bottom_bar)

	var nav_hbox := HBoxContainer.new()
	nav_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_hbox.add_theme_constant_override("separation", 18)
	_mob_bottom_bar.add_child(nav_hbox)

	_mob_nav_btns.clear()
	_mob_nav_labels.clear()
	_mob_nav_icons.clear()

	var nav_specs := [
		{"title": "Academia", "kind": "academia", "cb": _on_academy_pressed},
		{"title": "Historial", "kind": "historial", "cb": _open_history_overlay},
		{"title": "Perfil", "kind": "perfil", "cb": _open_select_modal}
	]
	for spec in nav_specs:
		var nav_btn := _create_mobile_nav_button(spec["title"], spec["kind"], spec["cb"])
		nav_hbox.add_child(nav_btn)

func _trigger_initial_mobile_gallo_wave() -> void:
	if _mobile_gallo and is_instance_valid(_mobile_gallo):
		_mobile_gallo.saludar(2.2)

func _create_mobile_status_pill(kind: String) -> PanelContainer:
	var pill := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.97, 0.94, 0.96) # #FFF6ED
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 5
	sb.border_color = Color("#F472B6")
	sb.set_corner_radius_all(30)
	sb.content_margin_left = 16
	sb.content_margin_right = 20
	sb.content_margin_top = 6
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0.75, 0.09, 0.36, 0.16)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	pill.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	pill.add_child(hbox)

	var icon_ctrl := Control.new()
	icon_ctrl.custom_minimum_size = Vector2(36, 36)
	icon_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_ctrl.draw.connect(func(): _draw_status_pill_icon(icon_ctrl, kind))
	hbox.add_child(icon_ctrl)

	var val_lbl := Label.new()
	val_lbl.text = "0"
	val_lbl.add_theme_font_override("font", CHERRY_FONT_MOB)
	val_lbl.add_theme_font_size_override("font_size", 28)
	val_lbl.add_theme_color_override("font_color", Color("#9D174D"))
	hbox.add_child(val_lbl)

	pill.set_meta("value_label", val_lbl)
	return pill

func _create_mobile_nav_button(title: String, kind: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var sb_norm := StyleBoxFlat.new()
	sb_norm.bg_color = Color("#9D174D")
	sb_norm.border_width_left = 2
	sb_norm.border_width_top = 2
	sb_norm.border_width_right = 2
	sb_norm.border_width_bottom = 5
	sb_norm.border_color = Color("#F472B6")
	sb_norm.set_corner_radius_all(22)
	sb_norm.anti_aliasing = true

	var sb_hov := sb_norm.duplicate()
	sb_hov.bg_color = Color("#DB2777")
	sb_hov.border_color = Color("#FDE047")

	var sb_press := sb_norm.duplicate()
	sb_press.bg_color = Color("#831843")
	sb_press.border_color = Color("#FDE047")

	btn.add_theme_stylebox_override("normal", sb_norm)
	btn.add_theme_stylebox_override("hover", sb_hov)
	btn.add_theme_stylebox_override("pressed", sb_press)
	btn.pressed.connect(callback)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	var icon_holder := CenterContainer.new()
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_holder)

	var icon_canvas := Control.new()
	icon_canvas.custom_minimum_size = Vector2(68, 62)
	icon_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_canvas.draw.connect(func(): _draw_mobile_nav_icon(icon_canvas, kind))
	icon_holder.add_child(icon_canvas)

	var lbl := Label.new()
	lbl.text = title
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", CHERRY_FONT_MOB)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_outline_color", Color("#500724"))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)

	_mob_nav_btns.append(btn)
	_mob_nav_labels.append(lbl)
	_mob_nav_icons.append(icon_canvas)
	return btn

func _build_mobile_mode_popup() -> void:
	if _mobile_mode_popup:
		return

	_mobile_mode_popup = Control.new()
	_mobile_mode_popup.name = "MobileModePopupOverlay"
	_mobile_mode_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mobile_mode_popup.visible = false
	_mobile_mode_popup.z_index = 950
	add_child(_mobile_mode_popup)

	# Fondo oscurecido que cierra el popup al tocar fuera
	var dimmer := Button.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.focus_mode = Control.FOCUS_NONE
	var dim_sb := StyleBoxFlat.new()
	dim_sb.bg_color = Color(0.09, 0.04, 0.14, 0.72)
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		dimmer.add_theme_stylebox_override(st, dim_sb)
	dimmer.pressed.connect(_close_mobile_mode_popup)
	_mobile_mode_popup.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_mode_popup.add_child(center)

	_mob_popup_card = PanelContainer.new()
	_mob_popup_card.name = "ModePopupCard"
	_mob_popup_card.custom_minimum_size = Vector2(560, 440)
	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = Color("#FFF9FB")
	card_sb.border_width_left = 5
	card_sb.border_width_top = 5
	card_sb.border_width_right = 5
	card_sb.border_width_bottom = 10
	card_sb.border_color = Color("#F472B6")
	card_sb.set_corner_radius_all(36)
	card_sb.content_margin_left = 28
	card_sb.content_margin_right = 28
	card_sb.content_margin_top = 24
	card_sb.content_margin_bottom = 28
	card_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	card_sb.shadow_size = 24
	card_sb.shadow_offset = Vector2(0, 10)
	_mob_popup_card.add_theme_stylebox_override("panel", card_sb)
	center.add_child(_mob_popup_card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	_mob_popup_card.add_child(vbox)

	# Cabecera del popup: Título + Botón X
	var header_hbox := HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header_hbox)

	var spacer_l := Control.new()
	spacer_l.custom_minimum_size = Vector2(52, 52)
	header_hbox.add_child(spacer_l)

	var title_lbl := Label.new()
	title_lbl.text = "¡Elige tu Modo!"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", CHERRY_FONT_MOB)
	title_lbl.add_theme_font_size_override("font_size", 38)
	title_lbl.add_theme_color_override("font_color", Color("#BE185D"))
	title_lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	title_lbl.add_theme_constant_override("outline_size", 8)
	header_hbox.add_child(title_lbl)

	var btn_close := Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(54, 54)
	btn_close.focus_mode = Control.FOCUS_NONE
	btn_close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_close.add_theme_font_size_override("font_size", 24)
	btn_close.add_theme_color_override("font_color", Color.WHITE)
	var close_sb := StyleBoxFlat.new()
	close_sb.bg_color = Color("#EF4444")
	close_sb.border_width_left = 3
	close_sb.border_width_top = 3
	close_sb.border_width_right = 3
	close_sb.border_width_bottom = 5
	close_sb.border_color = Color("#B91C1C")
	close_sb.set_corner_radius_all(27)
	var close_hov := close_sb.duplicate()
	close_hov.bg_color = Color("#F87171")
	btn_close.add_theme_stylebox_override("normal", close_sb)
	btn_close.add_theme_stylebox_override("hover", close_hov)
	btn_close.add_theme_stylebox_override("pressed", close_sb)
	btn_close.pressed.connect(_close_mobile_mode_popup)
	header_hbox.add_child(btn_close)

	# Opción 1: Contra BOT
	var card_bot := _create_mode_option_card(
		"Contra BOT",
		"Entrena con el Profe Pollito",
		"bot",
		Color("#DB2777"),
		Color("#9D174D"),
		Color("#FDE047"),
		func():
			_close_mobile_mode_popup()
			_on_practice_bot_pressed()
	)
	vbox.add_child(card_bot)

	# Opción 2: Versus Amigos
	var card_versus := _create_mode_option_card(
		"Versus Amigos",
		"Partida Online o en Red Local",
		"versus",
		Color("#10B981"),
		Color("#047857"),
		Color("#A7F3D0"),
		func():
			_close_mobile_mode_popup()
			_open_online_lobby()
	)
	vbox.add_child(card_versus)

func _create_mode_option_card(
	title: String,
	subtitle: String,
	icon_kind: String,
	bg_col: Color,
	lip_col: Color,
	border_col: Color,
	callback: Callable
) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 138)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 9
	sb.border_color = border_col
	sb.set_corner_radius_all(28)
	sb.shadow_color = Color(lip_col.r, lip_col.g, lip_col.b, 0.35)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	sb.anti_aliasing = true

	var sb_hov := sb.duplicate()
	sb_hov.bg_color = bg_col.lightened(0.08)

	var sb_press := sb.duplicate()
	sb_press.bg_color = bg_col.darkened(0.08)
	sb_press.border_width_bottom = 5

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hov)
	btn.add_theme_stylebox_override("pressed", sb_press)
	btn.pressed.connect(callback)

	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 16)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(m)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(hbox)

	var badge_icon := Control.new()
	badge_icon.custom_minimum_size = Vector2(96, 96)
	badge_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_icon.draw.connect(func(): _draw_mode_popup_badge(badge_icon, icon_kind))
	hbox.add_child(badge_icon)

	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	text_vbox.add_theme_constant_override("separation", 4)
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(text_vbox)

	var lbl_t := Label.new()
	lbl_t.text = title
	lbl_t.add_theme_font_override("font", CHERRY_FONT_MOB)
	lbl_t.add_theme_font_size_override("font_size", 32)
	lbl_t.add_theme_color_override("font_color", Color.WHITE)
	lbl_t.add_theme_color_override("font_outline_color", lip_col.darkened(0.35))
	lbl_t.add_theme_constant_override("outline_size", 8)
	lbl_t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(lbl_t)

	var lbl_sub := Label.new()
	lbl_sub.text = subtitle
	lbl_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_sub.add_theme_font_size_override("font_size", 18)
	lbl_sub.add_theme_color_override("font_color", Color("#FFFBEB"))
	lbl_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(lbl_sub)

	var arrow_badge := Control.new()
	arrow_badge.custom_minimum_size = Vector2(48, 48)
	arrow_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow_badge.draw.connect(func():
		var c := arrow_badge.size * 0.5
		arrow_badge.draw_circle(c, 22.0, Color(0.0, 0.0, 0.0, 0.18))
		var pts := PackedVector2Array([
			c + Vector2(-6, -10),
			c + Vector2(10, 0),
			c + Vector2(-6, 10)
		])
		arrow_badge.draw_colored_polygon(pts, Color.WHITE)
	)
	hbox.add_child(arrow_badge)

	return btn

func _open_mobile_mode_popup() -> void:
	if not _mobile_mode_popup:
		return
	_open_styled_popup(_mobile_mode_popup, _mob_popup_card)

func _close_mobile_mode_popup() -> void:
	if _mobile_mode_popup:
		_mobile_mode_popup.visible = false

func _update_mobile_profile_and_stats() -> void:
	var pm = _get_pm()
	if pm and _mob_lbl_player_name:
		var prof = pm.get_active_profile()
		var p_name: String = str(prof.get("name", "")).strip_edges()
		var is_fem: bool = (str(prof.get("gender", "f")).to_lower() == "f")
		var cat: String = str(prof.get("category", "child")).to_lower()
		var is_ad: bool = (cat in ["adult", "adulto", "adulta"] or prof.get("is_adult", false) == true)
		var icon: String = ("👩" if is_fem else "👨") if is_ad else ("👧" if is_fem else "👦")
		if p_name.is_empty():
			p_name = ("Adulta" if is_fem else "Adulto") if is_ad else ("Niña" if is_fem else "Niño")
		_mob_lbl_player_name.text = "%s %s" % [icon, p_name]
		var col = ("#7C3AED" if is_fem else "#059669") if is_ad else ("#DB2777" if is_fem else "#2563EB")
		_mob_lbl_player_name.add_theme_color_override("font_color", Color(col))

	if _mob_lbl_stars:
		var total_stars: int = 0
		if has_node("/root/AcademyManager"):
			var am = get_node("/root/AcademyManager")
			if am.has_method("get_total_stars"):
				total_stars = int(am.get_total_stars())
		_mob_lbl_stars.text = str(total_stars)

	if _mob_lbl_wins:
		var wins_count: int = 0
		var mhm = _get_mhm()
		if mhm and mhm.has_method("get_all_matches"):
			var all_m: Array = mhm.get_all_matches()
			for m in all_m:
				if str(m.get("result", "")) == "victory":
					wins_count += 1
		_mob_lbl_wins.text = str(wins_count)

func _layout_mobile_scenic_menu(vp_size: Vector2, is_portrait: bool) -> void:
	if not _mobile_root:
		return

	var touch_btn := _mobile_root.get_node_or_null("GalloTouchArea") as Button
	var safe_top: float = 0.0
	if has_node("/root/ScreenManager"):
		safe_top = get_node("/root/ScreenManager").get_safe_top_margin()

	if is_portrait:
		# Diseño Vertical (Portrait) idéntico a la propuesta v2 aprobada con Safe Area
		_mob_top_bar.position = Vector2(28, safe_top + 16)
		_mob_top_bar.scale = Vector2.ONE
		if _mob_btn_update:
			_mob_btn_update.size = Vector2(184, 54)
			_mob_btn_update.position = Vector2(vp_size.x - 184.0 - 28.0, safe_top + 16)

		_mob_greeting_box.position = Vector2(24, safe_top + 88)
		_mob_greeting_box.size = Vector2(vp_size.x - 48.0, 175.0)
		_mob_lbl_hello.add_theme_font_size_override("font_size", 42)
		_mob_lbl_player_name.add_theme_font_size_override("font_size", 68)

		var gallo_scale: float = clampf((vp_size.y / 1402.0) * 1.10, 0.85, 1.22)
		var gallo_pos := Vector2(vp_size.x * 0.5, vp_size.y * 0.675)
		if _mobile_gallo:
			_mobile_gallo.scale = Vector2(gallo_scale, gallo_scale)
			_mobile_gallo.position = gallo_pos
		if touch_btn:
			var t_w: float = 340.0 * gallo_scale
			var t_h: float = 470.0 * gallo_scale
			touch_btn.position = Vector2(gallo_pos.x - t_w * 0.5, gallo_pos.y - t_h)
			touch_btn.size = Vector2(t_w, t_h)

		var bar_h: float = 178.0
		_mob_bottom_bar.position = Vector2(0, vp_size.y - bar_h)
		_mob_bottom_bar.size = Vector2(vp_size.x, bar_h)

		var cta_w: float = clampf(vp_size.x * 0.86, 420.0, 580.0)
		var cta_h: float = 104.0
		var cta_y: float = vp_size.y - bar_h - cta_h - 32.0
		_mob_btn_new_game.position = Vector2((vp_size.x - cta_w) * 0.5, cta_y)
		_mob_btn_new_game.size = Vector2(cta_w, cta_h)
		_mob_btn_new_game.add_theme_font_size_override("font_size", 46)

		if _mob_btn_gloss:
			_mob_btn_gloss.position = Vector2(28, 10)
			_mob_btn_gloss.size = Vector2(cta_w - 56.0, 32.0)

		for i in range(_mob_nav_labels.size()):
			_mob_nav_labels[i].add_theme_font_size_override("font_size", 25)
			_mob_nav_icons[i].custom_minimum_size = Vector2(68, 64)
			_mob_nav_icons[i].queue_redraw()
	else:
		# Diseño Horizontal (Landscape) adaptado ergonómicamente para móvil con Safe Area
		_mob_top_bar.position = Vector2(28, safe_top + 14)
		if _mob_btn_update:
			_mob_btn_update.size = Vector2(180, 50)
			_mob_btn_update.position = Vector2(vp_size.x - 180.0 - 28.0, safe_top + 14)

		var left_center_x: float = vp_size.x * 0.30
		var gallo_scale: float = clampf((vp_size.y / 648.0) * 0.78, 0.58, 0.88)
		var gallo_pos := Vector2(left_center_x, vp_size.y * 0.77)
		if _mobile_gallo:
			_mobile_gallo.scale = Vector2(gallo_scale, gallo_scale)
			_mobile_gallo.position = gallo_pos
		if touch_btn:
			var t_w: float = 340.0 * gallo_scale
			var t_h: float = 470.0 * gallo_scale
			touch_btn.position = Vector2(gallo_pos.x - t_w * 0.5, gallo_pos.y - t_h)
			touch_btn.size = Vector2(t_w, t_h)

		var right_col_x: float = vp_size.x * 0.53
		var right_col_w: float = vp_size.x * 0.43

		_mob_greeting_box.position = Vector2(right_col_x, vp_size.y * 0.13)
		_mob_greeting_box.size = Vector2(right_col_w, 140.0)
		_mob_lbl_hello.add_theme_font_size_override("font_size", 34)
		_mob_lbl_player_name.add_theme_font_size_override("font_size", 52)

		var cta_w: float = clampf(right_col_w * 0.94, 360.0, 520.0)
		var cta_h: float = 92.0
		_mob_btn_new_game.position = Vector2(right_col_x + (right_col_w - cta_w) * 0.5, vp_size.y * 0.45)
		_mob_btn_new_game.size = Vector2(cta_w, cta_h)
		_mob_btn_new_game.add_theme_font_size_override("font_size", 38)

		if _mob_btn_gloss:
			_mob_btn_gloss.position = Vector2(24, 9)
			_mob_btn_gloss.size = Vector2(cta_w - 48.0, 26.0)

		var bar_h: float = 118.0
		_mob_bottom_bar.position = Vector2(0, vp_size.y - bar_h)
		_mob_bottom_bar.size = Vector2(vp_size.x, bar_h)

		for i in range(_mob_nav_labels.size()):
			_mob_nav_labels[i].add_theme_font_size_override("font_size", 21)
			_mob_nav_icons[i].custom_minimum_size = Vector2(52, 46)
			_mob_nav_icons[i].queue_redraw()

	if _mob_popup_card:
		var pop_w: float = clampf(vp_size.x - 48.0, 440.0, 580.0) if is_portrait else 580.0
		_mob_popup_card.custom_minimum_size = Vector2(pop_w, 430.0)

	if _mobile_bg_canvas:
		_mobile_bg_canvas.queue_redraw()

func _on_draw_mobile_scenic() -> void:
	if not _mobile_bg_canvas:
		return
	var sz: Vector2 = _mobile_bg_canvas.size
	if sz.x <= 0 or sz.y <= 0:
		return

	var is_portrait: bool = sz.y > sz.x
	var horizon_y: float = sz.y * (0.44 if is_portrait else 0.47)

	# 1. Cielo degradado pastel (#FCD6E8 -> #FFEBF5 -> #FFF6ED)
	var sky_steps: int = 24
	var c_top := Color("#FCD6E8")
	var c_Bot := Color("#FFF6ED")
	for i in range(sky_steps):
		var t0: float = float(i) / float(sky_steps)
		var t1: float = float(i + 1) / float(sky_steps)
		var col := c_top.lerp(c_Bot, (t0 + t1) * 0.5)
		_mobile_bg_canvas.draw_rect(
			Rect2(0, horizon_y * t0, sz.x, horizon_y * (t1 - t0) + 2.0),
			col
		)

	# 2. Nubes esponjosas animadas lentamente
	var drift1: float = fmod(_mob_cloud_time * 12.0, sz.x + 260.0) - 130.0
	var drift2: float = fmod(_mob_cloud_time * 8.0 + sz.x * 0.55, sz.x + 260.0) - 130.0
	_draw_fluffy_cloud(_mobile_bg_canvas, Vector2(drift1, horizon_y * 0.25), 1.0)
	_draw_fluffy_cloud(_mobile_bg_canvas, Vector2(drift2, horizon_y * 0.42), 0.85)
	_draw_fluffy_cloud(_mobile_bg_canvas, Vector2(sz.x * 0.78, horizon_y * 0.18), 0.75)

	# 3. Colinas suaves rosadas en el horizonte
	_draw_horizon_hill(_mobile_bg_canvas, Vector2(sz.x * 0.22, horizon_y + 8.0), sz.x * 0.36, 95.0, Color("#F9C6DC"))
	_draw_horizon_hill(_mobile_bg_canvas, Vector2(sz.x * 0.78, horizon_y + 8.0), sz.x * 0.38, 105.0, Color("#F9C6DC"))
	_draw_horizon_hill(_mobile_bg_canvas, Vector2(sz.x * 0.50, horizon_y + 10.0), sz.x * 0.34, 72.0, Color("#FBCFE8"))

	# 4. Árboles y flores en los bordes del horizonte
	_draw_scenic_tree(_mobile_bg_canvas, Vector2(44.0, horizon_y + 6.0), 1.05 if is_portrait else 0.90)
	_draw_scenic_tree(_mobile_bg_canvas, Vector2(sz.x - 42.0, horizon_y + 6.0), 1.12 if is_portrait else 0.95)

	_draw_scenic_flower(_mobile_bg_canvas, Vector2(sz.x * 0.16, horizon_y), Color("#FB923C"), Color("#FEF08A"))
	_draw_scenic_flower(_mobile_bg_canvas, Vector2(sz.x * 0.24, horizon_y + 2.0), Color("#FEF08A"), Color("#F59E0B"))
	_draw_scenic_flower(_mobile_bg_canvas, Vector2(sz.x * 0.83, horizon_y + 1.0), Color("#FEF08A"), Color("#EC4899"))
	_draw_scenic_flower(_mobile_bg_canvas, Vector2(sz.x * 0.90, horizon_y + 2.0), Color("#F472B6"), Color("#FEF08A"))

	# 5. Suelo de Tablero de Ajedrez 3D en perspectiva (#FFF6ED y #F39BB0)
	var floor_bottom_y: float = sz.y
	var rows: int = 7
	var cols: int = 6
	var col_light := Color("#FFF6ED")
	var col_dark := Color("#F39BB0")

	_mobile_bg_canvas.draw_rect(Rect2(0, horizon_y, sz.x, floor_bottom_y - horizon_y), col_light)

	var vanish := Vector2(sz.x * 0.5, horizon_y - (sz.y * 0.28))
	var row_t: Array[float] = [0.0, 0.10, 0.22, 0.36, 0.53, 0.74, 1.0]

	for r in range(rows - 1):
		var t0: float = row_t[r]
		var t1: float = row_t[r + 1]
		var y0: float = lerpf(horizon_y, floor_bottom_y, t0)
		var y1: float = lerpf(horizon_y, floor_bottom_y, t1)

		var spread0: float = lerpf(sz.x * 0.92, sz.x * 1.95, t0)
		var spread1: float = lerpf(sz.x * 0.92, sz.x * 1.95, t1)
		var left0: float = vanish.x - spread0 * 0.5
		var left1: float = vanish.x - spread1 * 0.5

		for c in range(cols):
			var u0: float = float(c) / float(cols)
			var u1: float = float(c + 1) / float(cols)
			var quad := PackedVector2Array([
				Vector2(left0 + spread0 * u0, y0),
				Vector2(left0 + spread0 * u1, y0),
				Vector2(left1 + spread1 * u1, y1),
				Vector2(left1 + spread1 * u0, y1)
			])
			var is_dark_cell: bool = ((r + c) % 2 == 1)
			_mobile_bg_canvas.draw_colored_polygon(quad, col_dark if is_dark_cell else col_light)

	# Línea divisoria suave del horizonte
	_mobile_bg_canvas.draw_line(
		Vector2(0, horizon_y),
		Vector2(sz.x, horizon_y),
		Color("#E18A9F"),
		4.0
	)

	# 6. Sombra elíptica suave bajo los pies del Profe Pollito
	if _mobile_gallo:
		var shadow_c := _mobile_gallo.position + Vector2(0, 6)
		var rx: float = 115.0 * _mobile_gallo.scale.x
		var ry: float = 24.0 * _mobile_gallo.scale.y
		_draw_filled_ellipse(_mobile_bg_canvas, shadow_c, rx, ry, Color(0.55, 0.20, 0.34, 0.22))

func _draw_fluffy_cloud(canvas: Control, pos: Vector2, s: float) -> void:
	var c := Color(1.0, 1.0, 1.0, 0.90)
	canvas.draw_circle(pos + Vector2(-38, 8) * s, 26.0 * s, c)
	canvas.draw_circle(pos + Vector2(0, -6) * s, 36.0 * s, c)
	canvas.draw_circle(pos + Vector2(40, 6) * s, 28.0 * s, c)
	canvas.draw_rect(Rect2(pos.x - 38.0 * s, pos.y + 4.0 * s, 78.0 * s, 30.0 * s), c)

func _draw_horizon_hill(canvas: Control, center_bottom: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var segs: int = 24
	for i in range(segs + 1):
		var ang: float = PI + (float(i) / float(segs)) * PI
		pts.append(Vector2(center_bottom.x + cos(ang) * rx, center_bottom.y + sin(ang) * ry))
	canvas.draw_colored_polygon(pts, col)

func _draw_scenic_tree(canvas: Control, base_pos: Vector2, s: float) -> void:
	# Tronco
	var trunk_rect := Rect2(base_pos.x - 12.0 * s, base_pos.y - 95.0 * s, 24.0 * s, 95.0 * s)
	canvas.draw_rect(trunk_rect, Color("#B47B56"))
	# Copa frondosa
	var c_back := Color("#4ADE80")
	var c_front := Color("#86EFAC")
	canvas.draw_circle(base_pos + Vector2(0, -145) * s, 56.0 * s, c_back)
	canvas.draw_circle(base_pos + Vector2(-34, -108) * s, 46.0 * s, c_back)
	canvas.draw_circle(base_pos + Vector2(34, -108) * s, 46.0 * s, c_back)
	canvas.draw_circle(base_pos + Vector2(-8, -135) * s, 44.0 * s, c_front)
	canvas.draw_circle(base_pos + Vector2(18, -112) * s, 38.0 * s, c_front)

func _draw_scenic_flower(canvas: Control, base_pos: Vector2, petal_col: Color, center_col: Color) -> void:
	canvas.draw_line(base_pos, base_pos + Vector2(0, -28), Color("#22C55E"), 4.0)
	var head := base_pos + Vector2(0, -32)
	for i in range(5):
		var a: float = float(i) * TAU / 5.0
		canvas.draw_circle(head + Vector2(cos(a), sin(a)) * 9.0, 7.5, petal_col)
	canvas.draw_circle(head, 6.5, center_col)

func _draw_filled_ellipse(canvas: Control, center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var segs: int = 28
	for i in range(segs):
		var a: float = float(i) * TAU / float(segs)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	canvas.draw_colored_polygon(pts, col)

func _draw_star_polygon(canvas: Control, center: Vector2, outer_r: float, inner_r: float, col: Color, border_col: Color = Color(0, 0, 0, 0)) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var a: float = -PI * 0.5 + float(i) * PI / 5.0
		var r: float = outer_r if (i % 2 == 0) else inner_r
		pts.append(center + Vector2(cos(a) * r, sin(a) * r))
	canvas.draw_colored_polygon(pts, col)
	if border_col.a > 0.01:
		pts.append(pts[0])
		canvas.draw_polyline(pts, border_col, 2.2)

func _draw_status_pill_icon(canvas: Control, kind: String) -> void:
	var c := canvas.size * 0.5
	if kind == "star":
		_draw_star_polygon(canvas, c, 16.0, 7.5, Color("#FACC15"), Color("#CA8A04"))
	else:
		# Trofeo / Corona dorada de victorias
		canvas.draw_circle(c, 15.0, Color("#FDE047"))
		var crown := PackedVector2Array([
			c + Vector2(-10, 6),
			c + Vector2(-12, -5),
			c + Vector2(-5, 0),
			c + Vector2(0, -9),
			c + Vector2(5, 0),
			c + Vector2(12, -5),
			c + Vector2(10, 6)
		])
		canvas.draw_colored_polygon(crown, Color("#EA580C"))

func _draw_mobile_nav_icon(canvas: Control, kind: String) -> void:
	var c := canvas.size * 0.5
	# Medallón circular de fondo
	canvas.draw_circle(c + Vector2(0, 2), 26.0, Color(0.0, 0.0, 0.0, 0.20))
	if kind == "academia":
		canvas.draw_circle(c, 25.0, Color("#F43F5E"))
		# Birrete de graduación + Estrella
		var cap_top := PackedVector2Array([
			c + Vector2(0, -15),
			c + Vector2(19, -6),
			c + Vector2(0, 3),
			c + Vector2(-19, -6)
		])
		canvas.draw_colored_polygon(cap_top, Color("#1E293B"))
		canvas.draw_rect(Rect2(c.x - 10, c.y + 1, 20, 9), Color("#334155"))
		canvas.draw_line(c + Vector2(14, -4), c + Vector2(16, 9), Color("#FACC15"), 2.5)
		_draw_star_polygon(canvas, c + Vector2(0, 12), 7.5, 3.5, Color("#FACC15"))
	elif kind == "historial":
		canvas.draw_circle(c, 25.0, Color("#F59E0B"))
		# Reloj / Pergamino de partidas
		canvas.draw_circle(c, 16.0, Color("#FFFBEB"))
		canvas.draw_arc(c, 16.0, 0.0, TAU, 28, Color("#B45309"), 3.0)
		canvas.draw_line(c, c + Vector2(0, -9), Color("#92400E"), 3.0)
		canvas.draw_line(c, c + Vector2(8, 4), Color("#92400E"), 3.0)
		canvas.draw_circle(c, 2.5, Color("#B45309"))
	elif kind == "perfil":
		canvas.draw_circle(c, 25.0, Color("#8B5CF6"))
		# Avatar con coronita
		canvas.draw_circle(c + Vector2(0, -3), 9.0, Color("#FDE68A"))
		var shoulders := PackedVector2Array([
			c + Vector2(-13, 16),
			c + Vector2(-9, 7),
			c + Vector2(9, 7),
			c + Vector2(13, 16)
		])
		canvas.draw_colored_polygon(shoulders, Color("#F472B6"))
		var crown := PackedVector2Array([
			c + Vector2(-7, -11),
			c + Vector2(-8, -18),
			c + Vector2(-3, -14),
			c + Vector2(0, -20),
			c + Vector2(3, -14),
			c + Vector2(8, -18),
			c + Vector2(7, -11)
		])
		canvas.draw_colored_polygon(crown, Color("#FACC15"))

func _draw_mode_popup_badge(canvas: Control, kind: String) -> void:
	var c := canvas.size * 0.5
	canvas.draw_circle(c + Vector2(0, 3), 42.0, Color(0.0, 0.0, 0.0, 0.22))
	if kind == "bot":
		canvas.draw_circle(c, 40.0, Color("#FDE047"))
		canvas.draw_circle(c, 35.0, Color("#38BDF8"))
		# Antena
		canvas.draw_line(c + Vector2(0, -18), c + Vector2(0, -29), Color("#0284C7"), 4.0)
		canvas.draw_circle(c + Vector2(0, -30), 5.5, Color("#EF4444"))
		# Cabeza de Robot amigable
		canvas.draw_rect(Rect2(c.x - 20, c.y - 16, 40, 32), Color("#E0F2FE"))
		canvas.draw_rect(Rect2(c.x - 16, c.y - 11, 32, 14), Color("#0F172A"))
		canvas.draw_circle(c + Vector2(-8, -4), 4.0, Color("#38BDF8"))
		canvas.draw_circle(c + Vector2(8, -4), 4.0, Color("#38BDF8"))
		canvas.draw_rect(Rect2(c.x - 10, c.y + 7, 20, 4), Color("#0284C7"))
	else:
		canvas.draw_circle(c, 40.0, Color("#FDE047"))
		canvas.draw_circle(c, 35.0, Color("#059669"))
		# Dos coronas / estrella de duelo amistoso
		_draw_star_polygon(canvas, c, 24.0, 11.0, Color("#FACC15"), Color("#B45309"))
		canvas.draw_circle(c, 6.5, Color("#FFFBEB"))

# =========================================================================
# SISTEMA DE ACTUALIZACIÓN OTA VÍA GITHUB RELEASES
# =========================================================================

func _get_um() -> Node:
	if has_node("/root/UpdateManager"):
		return get_node("/root/UpdateManager")
	return null

func _apply_mobile_update_pill_style(has_update: bool) -> void:
	if not _mob_btn_update:
		return
	var sb := StyleBoxFlat.new()
	if has_update:
		sb.bg_color = Color("#10B981")
		sb.border_color = Color("#FDE047")
		_mob_btn_update.add_theme_color_override("font_color", Color.WHITE)
		_mob_btn_update.add_theme_color_override("font_hover_color", Color.WHITE)
		_mob_btn_update.add_theme_color_override("font_outline_color", Color("#064E3B"))
		_mob_btn_update.add_theme_constant_override("outline_size", 6)
	else:
		sb.bg_color = Color(1.0, 0.97, 0.94, 0.96)
		sb.border_color = Color("#F472B6")
		_mob_btn_update.add_theme_color_override("font_color", Color("#9D174D"))
		_mob_btn_update.add_theme_color_override("font_hover_color", Color("#BE185D"))
		_mob_btn_update.add_theme_constant_override("outline_size", 0)

	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 5
	sb.set_corner_radius_all(28)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 4
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(0.75, 0.09, 0.36, 0.16)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)

	var sb_hov := sb.duplicate()
	sb_hov.bg_color = sb.bg_color.lightened(0.08)

	_mob_btn_update.add_theme_stylebox_override("normal", sb)
	_mob_btn_update.add_theme_stylebox_override("hover", sb_hov)
	_mob_btn_update.add_theme_stylebox_override("pressed", sb)

func _build_update_popup_ui() -> void:
	if _update_popup_overlay:
		return

	_update_popup_overlay = Control.new()
	_update_popup_overlay.name = "UpdatePopupOverlay"
	_update_popup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_popup_overlay.visible = false
	_update_popup_overlay.z_index = 1050
	add_child(_update_popup_overlay)

	var dimmer := Button.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.focus_mode = Control.FOCUS_NONE
	var dim_sb := StyleBoxFlat.new()
	dim_sb.bg_color = Color(0.08, 0.04, 0.12, 0.74)
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		dimmer.add_theme_stylebox_override(st, dim_sb)
	dimmer.pressed.connect(_close_update_popup)
	_update_popup_overlay.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_popup_overlay.add_child(center)

	_update_popup_card = PanelContainer.new()
	_update_popup_card.custom_minimum_size = Vector2(540, 400)
	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = Color("#FFF9FB")
	card_sb.border_width_left = 5
	card_sb.border_width_top = 5
	card_sb.border_width_right = 5
	card_sb.border_width_bottom = 10
	card_sb.border_color = Color("#F472B6")
	card_sb.set_corner_radius_all(34)
	card_sb.content_margin_left = 28
	card_sb.content_margin_right = 28
	card_sb.content_margin_top = 22
	card_sb.content_margin_bottom = 26
	card_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	card_sb.shadow_size = 24
	card_sb.shadow_offset = Vector2(0, 10)
	_update_popup_card.add_theme_stylebox_override("panel", card_sb)
	center.add_child(_update_popup_card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_update_popup_card.add_child(vbox)

	# Cabecera
	var header_hbox := HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header_hbox)

	var spacer_l := Control.new()
	spacer_l.custom_minimum_size = Vector2(48, 48)
	header_hbox.add_child(spacer_l)

	var title_lbl := Label.new()
	title_lbl.text = "🚀 Actualizador"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", CHERRY_FONT_MOB)
	title_lbl.add_theme_font_size_override("font_size", 34)
	title_lbl.add_theme_color_override("font_color", Color("#BE185D"))
	title_lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	title_lbl.add_theme_constant_override("outline_size", 8)
	header_hbox.add_child(title_lbl)

	var btn_close := Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(50, 50)
	btn_close.focus_mode = Control.FOCUS_NONE
	btn_close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_close.add_theme_font_size_override("font_size", 22)
	btn_close.add_theme_color_override("font_color", Color.WHITE)
	var close_sb := StyleBoxFlat.new()
	close_sb.bg_color = Color("#EF4444")
	close_sb.border_width_left = 3
	close_sb.border_width_top = 3
	close_sb.border_width_right = 3
	close_sb.border_width_bottom = 5
	close_sb.border_color = Color("#B91C1C")
	close_sb.set_corner_radius_all(25)
	btn_close.add_theme_stylebox_override("normal", close_sb)
	btn_close.add_theme_stylebox_override("hover", close_sb)
	btn_close.add_theme_stylebox_override("pressed", close_sb)
	btn_close.pressed.connect(_close_update_popup)
	header_hbox.add_child(btn_close)

	# Estado de versión
	_upd_lbl_status = Label.new()
	_upd_lbl_status.text = "Buscando actualizaciones en GitHub..."
	_upd_lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upd_lbl_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_upd_lbl_status.add_theme_font_override("font", CHERRY_FONT_MOB)
	_upd_lbl_status.add_theme_font_size_override("font_size", 24)
	_upd_lbl_status.add_theme_color_override("font_color", Color("#9D174D"))
	vbox.add_child(_upd_lbl_status)

	# Caja de notas de versión
	var notes_panel := PanelContainer.new()
	var notes_sb := StyleBoxFlat.new()
	notes_sb.bg_color = Color("#FFF0F6")
	notes_sb.border_width_left = 2
	notes_sb.border_width_top = 2
	notes_sb.border_width_right = 2
	notes_sb.border_width_bottom = 3
	notes_sb.border_color = Color("#FBCFE8")
	notes_sb.set_corner_radius_all(18)
	notes_sb.content_margin_left = 18
	notes_sb.content_margin_right = 18
	notes_sb.content_margin_top = 14
	notes_sb.content_margin_bottom = 14
	notes_panel.add_theme_stylebox_override("panel", notes_sb)
	vbox.add_child(notes_panel)

	_upd_lbl_notes = Label.new()
	_upd_lbl_notes.text = "Consultando el repositorio Xx5n0wxX/ajedrez-de-pollito..."
	_upd_lbl_notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_upd_lbl_notes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upd_lbl_notes.add_theme_font_size_override("font_size", 18)
	_upd_lbl_notes.add_theme_color_override("font_color", Color("#475569"))
	notes_panel.add_child(_upd_lbl_notes)

	# Barra de progreso de descarga
	_upd_progress_box = VBoxContainer.new()
	_upd_progress_box.visible = false
	_upd_progress_box.add_theme_constant_override("separation", 6)
	vbox.add_child(_upd_progress_box)

	_upd_progress_bar = ProgressBar.new()
	_upd_progress_bar.min_value = 0.0
	_upd_progress_bar.max_value = 100.0
	_upd_progress_bar.value = 0.0
	_upd_progress_bar.show_percentage = false
	_upd_progress_bar.custom_minimum_size = Vector2(0, 28)
	var p_bg := StyleBoxFlat.new()
	p_bg.bg_color = Color("#FCE7F3")
	p_bg.border_width_left = 2
	p_bg.border_width_top = 2
	p_bg.border_width_right = 2
	p_bg.border_width_bottom = 3
	p_bg.border_color = Color("#F472B6")
	p_bg.set_corner_radius_all(14)
	var p_fill := StyleBoxFlat.new()
	p_fill.bg_color = Color("#10B981")
	p_fill.set_corner_radius_all(12)
	_upd_progress_bar.add_theme_stylebox_override("background", p_bg)
	_upd_progress_bar.add_theme_stylebox_override("fill", p_fill)
	_upd_progress_box.add_child(_upd_progress_bar)

	_upd_lbl_progress = Label.new()
	_upd_lbl_progress.text = "Descargando... 0%"
	_upd_lbl_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upd_lbl_progress.add_theme_font_size_override("font_size", 17)
	_upd_lbl_progress.add_theme_color_override("font_color", Color("#047857"))
	_upd_progress_box.add_child(_upd_lbl_progress)

	# Botón principal: Actualización rápida OTA (.pck)
	_upd_btn_ota = Button.new()
	_upd_btn_ota.text = "⚡ ¡Actualizar Ahora! (Rápido)"
	_upd_btn_ota.custom_minimum_size = Vector2(0, 74)
	_upd_btn_ota.focus_mode = Control.FOCUS_NONE
	_upd_btn_ota.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_upd_btn_ota.add_theme_font_override("font", CHERRY_FONT_MOB)
	_upd_btn_ota.add_theme_font_size_override("font_size", 26)
	_upd_btn_ota.add_theme_color_override("font_color", Color.WHITE)
	_upd_btn_ota.add_theme_color_override("font_outline_color", Color("#064E3B"))
	_upd_btn_ota.add_theme_constant_override("outline_size", 7)

	var ota_sb := StyleBoxFlat.new()
	ota_sb.bg_color = Color("#10B981")
	ota_sb.border_width_left = 3
	ota_sb.border_width_top = 3
	ota_sb.border_width_right = 3
	ota_sb.border_width_bottom = 8
	ota_sb.border_color = Color("#FDE047")
	ota_sb.set_corner_radius_all(24)
	var ota_hov := ota_sb.duplicate()
	ota_hov.bg_color = Color("#34D399")
	_upd_btn_ota.add_theme_stylebox_override("normal", ota_sb)
	_upd_btn_ota.add_theme_stylebox_override("hover", ota_hov)
	_upd_btn_ota.add_theme_stylebox_override("pressed", ota_sb)
	_upd_btn_ota.pressed.connect(_on_start_ota_pressed)
	vbox.add_child(_upd_btn_ota)

	# Botón secundario: Descargar APK/EXE completo en el navegador
	_upd_btn_apk = Button.new()
	if OS.get_name() == "Windows":
		_upd_btn_apk.text = "💻 Descargar Ejecutable EXE Completo (Navegador)"
	else:
		_upd_btn_apk.text = "📦 Descargar APK Completo (Navegador)"
	_upd_btn_apk.custom_minimum_size = Vector2(0, 52)
	_upd_btn_apk.focus_mode = Control.FOCUS_NONE
	_upd_btn_apk.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_upd_btn_apk.add_theme_font_size_override("font_size", 17)
	_upd_btn_apk.add_theme_color_override("font_color", Color("#9D174D"))
	var apk_sb := StyleBoxFlat.new()
	apk_sb.bg_color = Color("#FFF0F6")
	apk_sb.border_width_left = 2
	apk_sb.border_width_top = 2
	apk_sb.border_width_right = 2
	apk_sb.border_width_bottom = 4
	apk_sb.border_color = Color("#F472B6")
	apk_sb.set_corner_radius_all(18)
	_upd_btn_apk.add_theme_stylebox_override("normal", apk_sb)
	_upd_btn_apk.add_theme_stylebox_override("hover", apk_sb)
	_upd_btn_apk.add_theme_stylebox_override("pressed", apk_sb)
	_upd_btn_apk.pressed.connect(_on_open_apk_pressed)
	vbox.add_child(_upd_btn_apk)

func _setup_updater_connections() -> void:
	var um = _get_um()
	if not um:
		return

	if not um.update_check_started.is_connected(_on_update_check_started):
		um.update_check_started.connect(_on_update_check_started)
	if not um.update_check_completed.is_connected(_on_update_check_completed):
		um.update_check_completed.connect(_on_update_check_completed)
	if not um.download_progress_updated.is_connected(_on_download_progress_updated):
		um.download_progress_updated.connect(_on_download_progress_updated)
	if not um.update_installed_successfully.is_connected(_on_update_installed_successfully):
		um.update_installed_successfully.connect(_on_update_installed_successfully)
	if not um.update_failed.is_connected(_on_update_failed):
		um.update_failed.connect(_on_update_failed)

	# Actualizar texto del pie de página en PC y añadir botón de actualización inline
	var footer_lbl := find_child("Footer", true, false) as Label
	if footer_lbl:
		footer_lbl.text = "Creado para Lyanna ❤️ •"
		var parent_vbox := footer_lbl.get_parent() as VBoxContainer
		if parent_vbox and not _pc_btn_update:
			var footer_hbox := HBoxContainer.new()
			footer_hbox.name = "FooterHBox"
			footer_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			footer_hbox.add_theme_constant_override("separation", 8)
			parent_vbox.add_child(footer_hbox)
			footer_lbl.reparent(footer_hbox)

			_pc_btn_update = Button.new()
			_pc_btn_update.text = "🔄 v%s" % str(um.current_version_name)
			_pc_btn_update.custom_minimum_size = Vector2(96, 24)
			_pc_btn_update.focus_mode = Control.FOCUS_NONE
			_pc_btn_update.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			_pc_btn_update.add_theme_font_size_override("font_size", 11)
			_pc_btn_update.pressed.connect(_on_update_button_pressed)
			footer_hbox.add_child(_pc_btn_update)

	_refresh_version_badges()

func _refresh_version_badges() -> void:
	var um = _get_um()
	if not um:
		return
	var ver_txt: String = str(um.current_version_name)
	var has_upd: bool = bool(um.has_pending_update)
	if _mob_btn_update:
		if has_upd:
			_mob_btn_update.text = "✨ ¡Actualizar!"
		else:
			_mob_btn_update.text = "🔄 v" + ver_txt
		_apply_mobile_update_pill_style(has_upd)
	if _pc_btn_update:
		var pc_sb := StyleBoxFlat.new()
		pc_sb.set_corner_radius_all(10)
		pc_sb.anti_aliasing = true
		if has_upd:
			_pc_btn_update.text = "✨ ¡Actualizar a v%s!" % str(um.remote_version_info.get("version_name", ver_txt))
			pc_sb.bg_color = Color("#10B981")
			pc_sb.border_color = Color("#059669")
			pc_sb.border_width_bottom = 2
			_pc_btn_update.add_theme_color_override("font_color", Color.WHITE)
		else:
			_pc_btn_update.text = "🔄 v%s" % ver_txt
			pc_sb.bg_color = Color(0.96, 0.94, 0.96, 1.0)
			pc_sb.border_color = Color(0.85, 0.75, 0.82, 1.0)
			pc_sb.border_width_left = 1
			pc_sb.border_width_top = 1
			pc_sb.border_width_right = 1
			pc_sb.border_width_bottom = 2
			_pc_btn_update.add_theme_color_override("font_color", Color(0.4, 0.42, 0.5, 1.0))
		_pc_btn_update.add_theme_stylebox_override("normal", pc_sb)
		var pc_hov := pc_sb.duplicate()
		pc_hov.bg_color = pc_sb.bg_color.lightened(0.08)
		_pc_btn_update.add_theme_stylebox_override("hover", pc_hov)
		_pc_btn_update.add_theme_stylebox_override("pressed", pc_sb)

func _trigger_auto_update_check() -> void:
	var um = _get_um()
	if um and um.has_method("check_for_updates_once_per_session"):
		um.check_for_updates_once_per_session()

func _on_update_button_pressed() -> void:
	_open_update_popup()
	var um = _get_um()
	if um and not um.is_downloading:
		um.check_for_updates(true)

func _open_update_popup() -> void:
	if not _update_popup_overlay:
		return
	_open_styled_popup(_update_popup_overlay, _update_popup_card)

func _close_update_popup() -> void:
	var um = _get_um()
	if um and um.is_downloading:
		return
	if _update_popup_overlay:
		_update_popup_overlay.visible = false

func _on_update_check_started() -> void:
	if _upd_lbl_status:
		_upd_lbl_status.text = "🔍 Buscando actualizaciones en GitHub..."
	if _upd_lbl_notes:
		_upd_lbl_notes.text = "Conectando con Xx5n0wxX/ajedrez-de-pollito..."
	if _upd_btn_ota:
		_upd_btn_ota.disabled = true

func _on_update_check_completed(has_update: bool, remote_info: Dictionary, is_manual: bool, error_message: String) -> void:
	_refresh_version_badges()
	var um = _get_um()
	var cur_ver: String = str(um.current_version_name) if um else "1.0.0"

	if not error_message.is_empty():
		if _upd_lbl_status:
			_upd_lbl_status.text = "⚠️ Sin conexión con el servidor"
		if _upd_lbl_notes:
			_upd_lbl_notes.text = "%s\nVersión actual instalada: v%s" % [error_message, cur_ver]
		if _upd_btn_ota:
			_upd_btn_ota.disabled = false
			_upd_btn_ota.text = "🔄 Reintentar Descarga (.pck)"
		return

	var rem_ver: String = str(remote_info.get("version_name", cur_ver))
	var rem_notes: String = str(remote_info.get("notes", "Mejoras generales y correcciones.")).strip_edges()

	if has_update:
		if _upd_lbl_status:
			_upd_lbl_status.text = "🎉 ¡Nueva versión v%s disponible!" % rem_ver
		if _upd_lbl_notes:
			_upd_lbl_notes.text = "Instalada: v%s  ➔  Nueva: v%s\n\n📝 Novedades:\n%s" % [cur_ver, rem_ver, rem_notes]
		if _upd_btn_ota:
			_upd_btn_ota.disabled = false
			_upd_btn_ota.text = "⚡ ¡Actualizar Ahora a v%s!" % rem_ver
		# Si fue chequeo automático al abrir el juego y hay versión nueva, mostrar el popup automáticamente
		if not is_manual:
			_open_update_popup()
	else:
		if _upd_lbl_status:
			_upd_lbl_status.text = "✅ ¡Ya tienes la última versión (v%s)!" % cur_ver
		if _upd_lbl_notes:
			_upd_lbl_notes.text = "📝 Notas de v%s:\n%s" % [cur_ver, rem_notes]
		if _upd_btn_ota:
			_upd_btn_ota.disabled = false
			_upd_btn_ota.text = "🔄 Reinstalar Paquete Rápido (.pck)"

func _on_start_ota_pressed() -> void:
	var um = _get_um()
	if not um or um.is_downloading:
		return
	if _upd_progress_box:
		_upd_progress_box.visible = true
	if _upd_progress_bar:
		_upd_progress_bar.value = 0.0
	if _upd_lbl_progress:
		_upd_lbl_progress.text = "Iniciando descarga desde GitHub..."
	if _upd_btn_ota:
		_upd_btn_ota.disabled = true
	um.start_ota_download()

func _on_open_apk_pressed() -> void:
	var um = _get_um()
	if um:
		um.open_full_apk_download()

func _on_download_progress_updated(percent: float, downloaded_mb: float, total_mb: float) -> void:
	if _upd_progress_box:
		_upd_progress_box.visible = true
	if _upd_progress_bar:
		_upd_progress_bar.value = percent
	if _upd_lbl_progress:
		_upd_lbl_progress.text = "Descargando paquete... %.2f MB / %.2f MB (%d%%)" % [downloaded_mb, total_mb, int(percent)]

func _on_update_installed_successfully(new_version_name: String) -> void:
	if _upd_lbl_status:
		_upd_lbl_status.text = "✨ ¡Actualizado a v%s!" % new_version_name
	if _upd_lbl_progress:
		_upd_lbl_progress.text = "¡Listo! Reiniciando el juego..."

func _on_update_failed(error_message: String) -> void:
	if _upd_lbl_status:
		_upd_lbl_status.text = "⚠️ No se pudo completar la actualización"
	if _upd_lbl_progress:
		_upd_lbl_progress.text = error_message
	if _upd_btn_ota:
		_upd_btn_ota.disabled = false
		_upd_btn_ota.text = "🔄 Reintentar Actualización"


