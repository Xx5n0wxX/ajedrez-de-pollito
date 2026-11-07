extends Node

## MatchHistoryManager: Almacenamiento persistente del historial de partidas (Bots y Versus)
## Permite guardar, listar, filtrar, eliminar y cargar partidas para su revisión completa.

signal match_saved(match_data: Dictionary)
signal history_cleared()
signal match_deleted(match_id: String)

const SAVE_PATH: String = "user://match_history.json"
const MAX_SAVED_MATCHES: int = 150

static var instance: MatchHistoryManager = null

var matches: Array[Dictionary] = []
var active_review_match: Dictionary = {}
var open_history_on_main_menu: bool = false

func _init() -> void:
	instance = self
	_load_history()

func _ready() -> void:
	if instance == null:
		instance = self

func _load_history() -> void:
	matches.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_warning("MatchHistoryManager: no se pudo abrir el archivo para lectura.")
		return

	var json_str = file.get_as_text()
	file.close()

	if json_str.strip_edges().is_empty():
		return

	var json = JSON.new()
	var err = json.parse(json_str)
	if err == OK and json.data is Array:
		for item in json.data:
			if item is Dictionary:
				matches.append(item)
	else:
		push_warning("MatchHistoryManager: error al parsear JSON del historial.")

func _save_to_disk() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("MatchHistoryManager: no se pudo abrir el archivo para escritura.")
		return

	var json_str = JSON.stringify(matches, "\t")
	file.store_string(json_str)
	file.close()

func save_match(match_data: Dictionary) -> bool:
	var moves = match_data.get("moves", [])
	if moves.size() == 0:
		return false

	# Generar ID único si no existe
	if not match_data.has("id") or str(match_data["id"]).is_empty():
		match_data["id"] = "match_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 10000]

	if not match_data.has("timestamp"):
		match_data["timestamp"] = int(Time.get_unix_time_from_system())

	if not match_data.has("date"):
		var dt = Time.get_datetime_dict_from_system()
		match_data["date"] = "%02d/%02d/%d %02d:%02d" % [dt.day, dt.month, dt.year, dt.hour, dt.minute]

	# Insertar al inicio (orden cronológico inverso: más reciente primero)
	matches.insert(0, match_data)

	# Limitar a MAX_SAVED_MATCHES
	if matches.size() > MAX_SAVED_MATCHES:
		matches.resize(MAX_SAVED_MATCHES)

	_save_to_disk()
	match_saved.emit(match_data)
	return true

func get_all_matches() -> Array[Dictionary]:
	return matches.duplicate()

func get_matches_by_mode(mode: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for m in matches:
		if m.get("mode", "") == mode:
			result.append(m)
	return result

func get_match_by_id(match_id: String) -> Dictionary:
	for m in matches:
		if str(m.get("id", "")) == match_id:
			return m
	return {}

func delete_match(match_id: String) -> bool:
	for i in range(matches.size()):
		if str(matches[i].get("id", "")) == match_id:
			matches.remove_at(i)
			_save_to_disk()
			match_deleted.emit(match_id)
			return true
	return false

func clear_history() -> void:
	matches.clear()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	history_cleared.emit()

func set_review_match(match_data: Dictionary, return_to_history: bool = true) -> void:
	active_review_match = match_data.duplicate()
	open_history_on_main_menu = return_to_history

func clear_review_match() -> void:
	active_review_match.clear()
