extends Node

## ScreenManager: Gestor central de orientación y escala responsiva (Móvil / Escritorio)
## Sincroniza dinámicamente content_scale_size para mantener proporciones idénticas
## tanto en vertical (720x1280) como en horizontal (1280x720) sin que la interfaz se encoja.

signal orientation_changed(is_portrait: bool)
signal layout_swap_toggled(is_swapped: bool)
signal mobile_mode_changed(is_mobile_active: bool)

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

func is_portrait() -> bool:
	return _is_portrait

func get_visible_size() -> Vector2:
	var win = _get_active_window()
	if win:
		return win.get_visible_rect().size
	return Vector2(1280, 720)
