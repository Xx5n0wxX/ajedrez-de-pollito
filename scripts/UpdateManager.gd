extends Node

## UpdateManager: Gestor de actualizaciones Over-The-Air (OTA) vía GitHub Releases.
## Permite descargar paquetes ligeros (.pck) e instalarlos en caliente sin reinstalar el APK,
## además de ofrecer descarga directa del APK completo como respaldo.

signal update_check_started()
signal update_check_completed(has_update: bool, remote_info: Dictionary, is_manual: bool, error_message: String)
signal download_progress_updated(percent: float, downloaded_mb: float, total_mb: float)
signal update_installed_successfully(new_version_name: String)
signal update_failed(error_message: String)

const GITHUB_OWNER: String = "Xx5n0wxX"
const GITHUB_REPO: String = "ajedrez-de-pollito"
const REMOTE_VERSION_URL: String = "https://github.com/Xx5n0wxX/ajedrez-de-pollito/releases/latest/download/version.json"
const RAW_FALLBACK_URL: String = "https://raw.githubusercontent.com/Xx5n0wxX/ajedrez-de-pollito/main/version.json"
const DEFAULT_PCK_ANDROID_URL: String = "https://github.com/Xx5n0wxX/ajedrez-de-pollito/releases/latest/download/update_android.pck"
const DEFAULT_PCK_WIN_URL: String = "https://github.com/Xx5n0wxX/ajedrez-de-pollito/releases/latest/download/update_windows.pck"
const DEFAULT_APK_URL: String = "https://github.com/Xx5n0wxX/ajedrez-de-pollito/releases/latest/download/Ajedrez_de_Pollito.apk"

const LOCAL_VERSION_PATH: String = "res://version.json"
const OTA_PCK_PATH: String = "user://ota_update.pck"
const OTA_TMP_PATH: String = "user://ota_update.pck.tmp"
const OTA_META_PATH: String = "user://ota_meta.json"

var base_version_code: int = 1
var base_version_name: String = "1.0.0"
var current_version_code: int = 1
var current_version_name: String = "1.0.0"
var current_notes: String = ""
var is_ota_active: bool = false

var has_pending_update: bool = false
var remote_version_info: Dictionary = {}
var is_checking: bool = false
var is_downloading: bool = false
var _auto_checked_this_session: bool = false
var _last_check_manual: bool = false
var _tried_fallback_url: bool = false

var _http_checker: HTTPRequest = null
var _http_downloader: HTTPRequest = null

func _init() -> void:
	_load_builtin_version()
	_try_mount_saved_ota_pack_on_boot()

func _ready() -> void:
	_http_checker = HTTPRequest.new()
	_http_checker.name = "VersionCheckerHTTP"
	_http_checker.timeout = 12.0
	_http_checker.use_threads = true
	_http_checker.request_completed.connect(_on_check_request_completed)
	add_child(_http_checker)

	_http_downloader = HTTPRequest.new()
	_http_downloader.name = "PackDownloaderHTTP"
	_http_downloader.timeout = 120.0
	_http_downloader.use_threads = true
	_http_downloader.request_completed.connect(_on_download_request_completed)
	add_child(_http_downloader)

func _process(_delta: float) -> void:
	if is_downloading and _http_downloader:
		var downloaded: int = _http_downloader.get_downloaded_bytes()
		var total: int = _http_downloader.get_body_size()
		var dl_mb: float = float(downloaded) / (1024.0 * 1024.0)
		var tot_mb: float = float(total) / (1024.0 * 1024.0) if total > 0 else 2.4
		var pct: float = 0.0
		if total > 0:
			pct = clampf((float(downloaded) / float(total)) * 100.0, 0.0, 99.0)
		else:
			pct = clampf((dl_mb / 2.4) * 100.0, 0.0, 95.0)
		download_progress_updated.emit(pct, dl_mb, tot_mb)

func _load_builtin_version() -> void:
	if FileAccess.file_exists(LOCAL_VERSION_PATH):
		var f := FileAccess.open(LOCAL_VERSION_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			f.close()
			if parsed is Dictionary:
				base_version_code = int(parsed.get("version_code", 1))
				base_version_name = str(parsed.get("version_name", "1.0.0"))
				current_notes = str(parsed.get("notes", ""))
	current_version_code = base_version_code
	current_version_name = base_version_name

func _try_mount_saved_ota_pack_on_boot() -> void:
	# En el editor de PC no montamos un .pck viejo encima de los archivos fuente en vivo
	if OS.has_feature("editor"):
		return
	if not FileAccess.file_exists(OTA_META_PATH) or not FileAccess.file_exists(OTA_PCK_PATH):
		return

	var f := FileAccess.open(OTA_META_PATH, FileAccess.READ)
	if not f:
		return
	var meta = JSON.parse_string(f.get_as_text())
	f.close()
	if not (meta is Dictionary):
		return

	var ota_code: int = int(meta.get("version_code", 0))
	var ota_name: String = str(meta.get("version_name", ""))
	var ota_notes: String = str(meta.get("notes", ""))

	# Si el APK instalado es igual o más nuevo que el .pck guardado, limpiar el .pck antiguo
	if ota_code <= base_version_code:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(OTA_PCK_PATH))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(OTA_META_PATH))
		return

	var ok: bool = ProjectSettings.load_resource_pack(OTA_PCK_PATH, true)
	if ok:
		current_version_code = ota_code
		current_version_name = ota_name if not ota_name.is_empty() else ("1.0." + str(ota_code))
		if not ota_notes.is_empty():
			current_notes = ota_notes
		is_ota_active = true
		print("[UpdateManager] Paquete OTA montado al inicio: v%s (build %d)" % [current_version_name, current_version_code])

func check_for_updates_once_per_session() -> void:
	if _auto_checked_this_session:
		return
	_auto_checked_this_session = true
	check_for_updates(false)

func check_for_updates(manual: bool = true) -> void:
	if is_checking or is_downloading:
		return
	is_checking = true
	_last_check_manual = manual
	_tried_fallback_url = false
	update_check_started.emit()

	var cache_buster: String = "?t=" + str(int(Time.get_unix_time_from_system()))
	var headers := PackedStringArray([
		"Cache-Control: no-cache, no-store, must-revalidate",
		"Pragma: no-cache",
		"User-Agent: AjedrezDePollito-Updater/1.0"
	])
	var err := _http_checker.request(REMOTE_VERSION_URL + cache_buster, headers)
	if err != OK:
		is_checking = false
		update_check_completed.emit(false, {}, manual, "No se pudo iniciar la consulta de versión.")

func _on_check_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		if not _tried_fallback_url:
			_tried_fallback_url = true
			var cache_buster: String = "?t=" + str(int(Time.get_unix_time_from_system()))
			var headers := PackedStringArray([
				"Cache-Control: no-cache",
				"User-Agent: AjedrezDePollito-Updater/1.0"
			])
			var err := _http_checker.request(RAW_FALLBACK_URL + cache_buster, headers)
			if err == OK:
				return
		is_checking = false
		update_check_completed.emit(
			false,
			{},
			_last_check_manual,
			"No se pudo conectar con GitHub (Código %d)." % response_code
		)
		return

	is_checking = false
	var text: String = body.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		update_check_completed.emit(false, {}, _last_check_manual, "Formato de versión remoto inválido.")
		return

	remote_version_info = parsed
	var remote_code: int = int(parsed.get("version_code", current_version_code))
	has_pending_update = (remote_code > current_version_code)
	update_check_completed.emit(has_pending_update, remote_version_info, _last_check_manual, "")

func start_ota_download() -> void:
	if is_downloading:
		return
	var target_url: String = DEFAULT_PCK_ANDROID_URL
	if OS.get_name() == "Windows":
		target_url = str(remote_version_info.get("pck_win_url", DEFAULT_PCK_WIN_URL))
	else:
		target_url = str(remote_version_info.get("pck_url", DEFAULT_PCK_ANDROID_URL))

	if FileAccess.file_exists(OTA_TMP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(OTA_TMP_PATH))

	is_downloading = true
	_http_downloader.download_file = OTA_TMP_PATH
	var cache_buster: String = "?t=" + str(int(Time.get_unix_time_from_system()))
	var headers := PackedStringArray([
		"Cache-Control: no-cache",
		"User-Agent: AjedrezDePollito-Updater/1.0"
	])
	var err := _http_downloader.request(target_url + cache_buster, headers)
	if err != OK:
		is_downloading = false
		update_failed.emit("No se pudo iniciar la descarga del paquete de actualización.")

func _on_download_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	is_downloading = false
	_http_downloader.download_file = ""

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		if FileAccess.file_exists(OTA_TMP_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(OTA_TMP_PATH))
		update_failed.emit("Error al descargar la actualización (Código %d)." % response_code)
		return

	if not FileAccess.file_exists(OTA_TMP_PATH):
		update_failed.emit("El archivo descargado no se encontró en el dispositivo.")
		return

	var f_check := FileAccess.open(OTA_TMP_PATH, FileAccess.READ)
	var file_len: int = f_check.get_length() if f_check else 0
	if f_check:
		f_check.close()

	if file_len < 50000:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(OTA_TMP_PATH))
		update_failed.emit("El paquete descargado está incompleto (%d bytes)." % file_len)
		return

	# Reemplazar user://ota_update.pck con el nuevo paquete descargado
	var abs_tmp := ProjectSettings.globalize_path(OTA_TMP_PATH)
	var abs_pck := ProjectSettings.globalize_path(OTA_PCK_PATH)
	if FileAccess.file_exists(OTA_PCK_PATH):
		DirAccess.remove_absolute(abs_pck)
	var ren_err := DirAccess.rename_absolute(abs_tmp, abs_pck)
	if ren_err != OK:
		# Fallback por copia de bytes
		var bytes := FileAccess.get_file_as_bytes(OTA_TMP_PATH)
		var fw := FileAccess.open(OTA_PCK_PATH, FileAccess.WRITE)
		if fw:
			fw.store_buffer(bytes)
			fw.close()
		DirAccess.remove_absolute(abs_tmp)

	# Guardar metadatos de la versión OTA instalada
	var new_code: int = int(remote_version_info.get("version_code", current_version_code + 1))
	var new_name: String = str(remote_version_info.get("version_name", "1.0." + str(new_code)))
	var new_notes: String = str(remote_version_info.get("notes", ""))
	var meta_dict := {
		"version_code": new_code,
		"version_name": new_name,
		"notes": new_notes,
		"installed_at": Time.get_datetime_string_from_system()
	}
	var fm := FileAccess.open(OTA_META_PATH, FileAccess.WRITE)
	if fm:
		fm.store_string(JSON.stringify(meta_dict, "\t"))
		fm.close()

	# Montar el paquete inmediatamente en memoria
	var loaded_ok: bool = ProjectSettings.load_resource_pack(OTA_PCK_PATH, true)
	if not loaded_ok:
		update_failed.emit("No se pudo montar el paquete de recursos actualizado.")
		return

	current_version_code = new_code
	current_version_name = new_name
	current_notes = new_notes
	is_ota_active = true
	has_pending_update = false

	_reload_updated_scripts_in_cache()
	download_progress_updated.emit(100.0, float(file_len) / (1024.0 * 1024.0), float(file_len) / (1024.0 * 1024.0))
	update_installed_successfully.emit(current_version_name)

	# Recargar a través de la pantalla de carga animada para aplicar todas las escenas nuevas
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/SplashScreen.tscn")

func _reload_updated_scripts_in_cache() -> void:
	var scripts_to_refresh: Array[String] = [
		"res://scripts/MainMenu.gd",
		"res://scripts/SplashScreen.gd",
		"res://scripts/GameController.gd",
		"res://scripts/ChessBoard.gd",
		"res://scripts/ChessBot.gd",
		"res://scripts/ChessRules.gd",
		"res://scripts/AcademyMap.gd",
		"res://scripts/AulaAcademia.gd",
		"res://scripts/OnlineGameController.gd",
		"res://scripts/GalloProfe.gd",
		"res://MainMenu.tscn",
		"res://tablero_juego.tscn",
		"res://scenes/AcademyMap.tscn",
		"res://scenes/AulaAcademia.tscn",
		"res://scenes/SplashScreen.tscn"
	]
	for path in scripts_to_refresh:
		if ResourceLoader.exists(path):
			ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)

func open_full_apk_download() -> void:
	var apk_url: String = str(remote_version_info.get("apk_url", DEFAULT_APK_URL))
	if apk_url.is_empty():
		apk_url = DEFAULT_APK_URL
	OS.shell_open(apk_url)
