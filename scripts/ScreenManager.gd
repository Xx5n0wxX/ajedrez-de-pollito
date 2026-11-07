extends Node

## ScreenManager: Gestor central de orientación y escala responsiva (Móvil / Escritorio)
## Sincroniza dinámicamente content_scale_size para mantener proporciones idénticas
## tanto en vertical (720x1280) como en horizontal (1280x720) sin que la interfaz se encoja.

signal orientation_changed(is_portrait: bool)
signal layout_swap_toggled(is_swapped: bool)
signal mobile_mode_changed(is_mobile_active: bool)
signal safe_area_changed(top_margin: float)

const SETTINGS_PATH: String = "user://display_settings.json"

var is_board_swapped: bool = false
var animate_next_swap: bool = false
var _force_mobile_preview: bool = false
var _is_portrait: bool = false
var _initialized: bool = false
var _custom_window: Window = null

var _mobile_presets: Array[Dictionary] = [
	{"name": "💻 Escritorio / Tablet (1280x720)", "size": Vector2i(1280, 720)},
	{"name": "📱 Teléfono Vertical (390x844)", "size": Vector2i(390, 844)},
	{"name": "📱 Teléfono Horizontal (844x390)", "size": Vector2i(844, 390)},
	{"name": "📱 Teléfono Compacto Vertical (405x720)", "size": Vector2i(405, 720)}
]
var _current_preset_index: int = 0

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F9:
			cycle_device_view()

func is_mobile() -> bool:
	return OS.has_feature("android") or OS.has_feature("mobile") or _force_mobile_preview

func set_force_mobile_preview(forced: bool) -> void:
	_force_mobile_preview = forced
	mobile_mode_changed.emit(is_mobile())
	orientation_changed.emit(_is_portrait)

func toggle_board_swap() -> void:
	animate_next_swap = true
	set_board_swapped(!is_board_swapped)
	animate_next_swap = false

func set_board_swapped(swapped: bool) -> void:
	is_board_swapped = swapped
	_save_settings()
	layout_swap_toggled.emit(is_board_swapped)

func cycle_device_view() -> void:
	_current_preset_index = (_current_preset_index + 1) % _mobile_presets.size()
	var preset = _mobile_presets[_current_preset_index]
	var target_size: Vector2i = preset["size"]
	_force_mobile_preview = (_current_preset_index > 0)

	var win = _get_active_window()
	if win:
		win.size = target_size
		var screen_idx = win.current_screen
		var usable_rect = DisplayServer.screen_get_usable_rect(screen_idx)
		var new_pos = usable_rect.position + (usable_rect.size - target_size) / 2
		win.position = new_pos
		print("[ScreenManager] Tecla F9 presionada -> Cambiando a vista: %s (Modo móvil: %s)" % [preset["name"], is_mobile()])
	mobile_mode_changed.emit(is_mobile())
	orientation_changed.emit(_is_portrait)

func set_custom_window(win: Window) -> void:
	_custom_window = win
	if win and not win.size_changed.is_connected(_on_window_size_changed):
		win.size_changed.connect(_on_window_size_changed)

func _get_active_window() -> Window:
	if _custom_window:
		return _custom_window
	if is_inside_tree():
		var w = get_window()
		if w:
			return w
		var t = get_tree()
		if t and t.root:
			return t.root
	return null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	var win = _get_active_window()
	if win:
		if not win.size_changed.is_connected(_on_window_size_changed):
			win.size_changed.connect(_on_window_size_changed)
	_update_screen_scale()
	_initialized = true
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is Control and node.get_parent() == get_tree().root:
		# Escena raíz recién montada: sincronizar Safe Area global
		call_deferred("_apply_global_safe_area_to_root_scene", node)

func _apply_global_safe_area_to_root_scene(scene_control: Control) -> void:
	if not is_instance_valid(scene_control):
		return
	safe_area_changed.emit(get_safe_top_margin())

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not f:
		return
	var text = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(text) == OK and json.data is Dictionary:
		var d = json.data as Dictionary
		if d.has("is_board_swapped"):
			is_board_swapped = bool(d["is_board_swapped"])

func _save_settings() -> void:
	var d = {
		"is_board_swapped": is_board_swapped
	}
	var f = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "\t"))
		f.close()

func _on_window_size_changed() -> void:
	_update_screen_scale()

func _update_screen_scale() -> void:
	var win = _get_active_window()
	if not win:
		return
	
	var win_size = win.size
	if win_size.x <= 0 or win_size.y <= 0:
		return
	
	var new_is_portrait = win_size.y > win_size.x
	var target_scale_size = Vector2i(720, 1280) if new_is_portrait else Vector2i(1280, 720)
	
	if win.content_scale_size != target_scale_size:
		win.content_scale_size = target_scale_size
	
	if not _initialized or _is_portrait != new_is_portrait:
		_is_portrait = new_is_portrait
		orientation_changed.emit(_is_portrait)
	safe_area_changed.emit(get_safe_top_margin())

func get_safe_top_margin() -> float:
	var safe_top: float = 0.0
	var safe_rect = DisplayServer.get_display_safe_area()
	var top_inset = safe_rect.position.y
	var win = _get_active_window()
	if top_inset > 0 and win and win.size.y > 0:
		var scale = float(win.content_scale_size.y) / float(win.size.y)
		safe_top = float(top_inset) * scale

	if is_mobile():
		if is_portrait():
			# En teléfonos verticales modernos la barra de notificaciones y el notch/cámara
			# ocupan entre 48px y 68px de espacio virtual a escala 720p.
			return maxf(safe_top, 58.0)
		else:
			return maxf(safe_top, 24.0)

	return safe_top

func get_safe_bottom_margin() -> float:
	var safe_bottom: float = 0.0
	var safe_rect = DisplayServer.get_display_safe_area()
	var win = _get_active_window()
	if win and win.size.y > 0:
		var bottom_inset = float(win.size.y - (safe_rect.position.y + safe_rect.size.y))
		if bottom_inset > 0:
			var scale = float(win.content_scale_size.y) / float(win.size.y)
			safe_bottom = bottom_inset * scale
	if is_mobile() and is_portrait():
		return maxf(safe_bottom, 16.0)
	return safe_bottom

func is_portrait() -> bool:
	return _is_portrait

func get_visible_size() -> Vector2:
	var win = _get_active_window()
	if win:
		return win.get_visible_rect().size
	return Vector2(1280, 720)
