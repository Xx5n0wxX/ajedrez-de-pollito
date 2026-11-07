extends Node

## Gestor pedagógico y de progreso para La Gran Academia de Ajedrez del Profe Pollito.
## Conecta el currículo oficial con ProfileManager y gestiona el aula y el mapa de grados.

signal progress_updated()
signal medal_earned(badge_id: String, badge_name: String)

const CURRICULUM_PATH: String = "res://data/curriculum_academia.json"
const SAVE_PATH: String = "user://academy_progress.json"

static var instance: AcademyManager = null

var curriculum: Dictionary = {}
var grades: Array = []
var practice_packs: Array = []

# Selección activa para navegación entre pantallas ("grades" o "practice")
var current_mode: String = "grades"
var current_grade_num: int = 1
var current_lesson_idx: int = 0
var current_pack_id: String = "pack_torre"
var current_exercise_idx: int = 0

# Caché de progreso por perfil: { profile_id: { "completed": [...], "stars": {...}, "unlocked_grades": [1], "medals": [...] } }
var _progress_cache: Dictionary = {}

func _init() -> void:
	instance = self
	_load_curriculum()

func _ready() -> void:
	instance = self
	if curriculum.is_empty():
		_load_curriculum()
	_load_progress()
	
	# Escuchar cambios de perfil activo
	if has_node("/root/ProfileManager"):
		var pm = get_node("/root/ProfileManager")
		if pm and not pm.active_profile_changed.is_connected(_on_active_profile_changed):
			pm.active_profile_changed.connect(_on_active_profile_changed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and instance == self:
		instance = null

func _on_active_profile_changed(_prof: Dictionary) -> void:
	progress_updated.emit()

# =========================================================================
# CARGA DE DATOS DEL CURRÍCULO
# =========================================================================

func _load_curriculum() -> void:
	if not FileAccess.file_exists(CURRICULUM_PATH):
		push_error("[AcademyManager] No se encontró el currículo en: " + CURRICULUM_PATH)
		return
	
	var file = FileAccess.open(CURRICULUM_PATH, FileAccess.READ)
	if not file:
		push_error("[AcademyManager] Error al abrir " + CURRICULUM_PATH)
		return
	
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("[AcademyManager] Error parseando JSON: %s (línea %d)" % [json.get_error_message(), json.get_error_line()])
		return
	
	curriculum = json.data
	grades = curriculum.get("grades", [])
	practice_packs = curriculum.get("practice_packs", [])

func get_curriculum_title() -> String:
	return curriculum.get("academy_title", "La Gran Academia de Ajedrez del Profe Pollito")

func get_all_grades() -> Array:
	return grades

func get_all_practice_packs() -> Array:
	return practice_packs

func get_practice_pack(pack_id: String) -> Dictionary:
	for p in practice_packs:
		if p is Dictionary and p.get("id", "") == pack_id:
			return p
	return {}

func get_practice_exercise(pack_id: String, ex_idx: int) -> Dictionary:
	var p = get_practice_pack(pack_id)
	if p.is_empty():
		return {}
	var exs: Array = p.get("exercises", [])
	if ex_idx >= 0 and ex_idx < exs.size():
		return exs[ex_idx]
	return {}

func get_grade(grade_num: int) -> Dictionary:
	for g in grades:
		if g is Dictionary and g.get("number", 0) == grade_num:
			return g
	return {}

func get_lesson(grade_num: int, lesson_idx: int) -> Dictionary:
	var g = get_grade(grade_num)
	if g.is_empty():
		return {}
	var lessons: Array = g.get("lessons", [])
	if lesson_idx >= 0 and lesson_idx < lessons.size():
		return lessons[lesson_idx]
	return {}

func get_lesson_by_id(lesson_id: String) -> Dictionary:
	for g in grades:
		for l in g.get("lessons", []):
			if l.get("id", "") == lesson_id:
				return l
	return {}

# =========================================================================
# GESTIÓN Y PERSISTENCIA DEL PROGRESO
# =========================================================================

func _get_active_profile_id() -> String:
	if has_node("/root/ProfileManager"):
		var pm = get_node("/root/ProfileManager")
		if pm and pm.has_method("get_active_profile"):
			return pm.get_active_profile().get("id", "default_profile")
	return "default_profile"

func _get_player_data() -> Dictionary:
	var pid = _get_active_profile_id()
	if not _progress_cache.has(pid):
		_progress_cache[pid] = {
			"completed_lessons": [],
			"lesson_stars": {},
			"unlocked_grades": [1],
			"earned_medals": []
		}
	return _progress_cache[pid]

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(text) == OK and json.data is Dictionary:
		_progress_cache = json.data

func _save_progress() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("[AcademyManager] No se pudo guardar progreso en: " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(_progress_cache, "\t"))
	file.close()

# =========================================================================
# CONSULTAS DE PROGRESO (ESTRELLAS, DESBLOQUEO, MEDALLAS)
# =========================================================================

func is_grade_unlocked(grade_num: int) -> bool:
	if grade_num <= 1:
		return true
	var pdata = _get_player_data()
	var unlocked_grades: Array = pdata.get("unlocked_grades", [1])
	return unlocked_grades.has(grade_num)

func is_lesson_completed(lesson_id: String) -> bool:
	var pdata = _get_player_data()
	var comp: Array = pdata.get("completed_lessons", [])
	return comp.has(lesson_id)

func get_lesson_stars(lesson_id: String) -> int:
	var pdata = _get_player_data()
	var stars_map: Dictionary = pdata.get("lesson_stars", {})
	return stars_map.get(lesson_id, 0)

func is_lesson_unlocked(grade_num: int, lesson_idx: int) -> bool:
	if not is_grade_unlocked(grade_num):
		return false
	if lesson_idx <= 0:
		return true
	var g = get_grade(grade_num)
	var lessons: Array = g.get("lessons", [])
	if lesson_idx > 0 and lesson_idx < lessons.size():
		var prev_lesson = lessons[lesson_idx - 1]
		return is_lesson_completed(prev_lesson.get("id", ""))
	return false

func get_total_stars() -> int:
	var pdata = _get_player_data()
	var stars_map: Dictionary = pdata.get("lesson_stars", {})
	var sum: int = 0
	for lid in stars_map:
		sum += int(stars_map[lid])
	return sum

func get_earned_medals() -> Array:
	var pdata = _get_player_data()
	return pdata.get("earned_medals", [])

func has_medal(badge_id: String) -> bool:
	return get_earned_medals().has(badge_id)

# =========================================================================
# REGISTRO DE VICTORIAS Y RECOMPENSAS
# =========================================================================

func complete_lesson(lesson_id: String, stars: int, _reward_emeralds: int) -> void:
	var pdata = _get_player_data()
	var completed: Array = pdata.get("completed_lessons", [])
	if not completed.has(lesson_id):
		completed.append(lesson_id)
		pdata["completed_lessons"] = completed
	
	var stars_map: Dictionary = pdata.get("lesson_stars", {})
	var prev_stars: int = stars_map.get(lesson_id, 0)
	if stars > prev_stars:
		stars_map[lesson_id] = clampi(stars, 1, 3)
		pdata["lesson_stars"] = stars_map
	
	# Verificar si se completó el grado entero (solo en modo grados)
	if current_mode == "grades":
		var current_g = get_grade(current_grade_num)
		var g_lessons: Array = current_g.get("lessons", [])
		var all_done = not g_lessons.is_empty()
		for l in g_lessons:
			if not completed.has(l.get("id", "")):
				all_done = false
				break
		
		if all_done:
			var badge_id = current_g.get("badge_id", "")
			var badge_name = current_g.get("badge_name", "")
			var medals: Array = pdata.get("earned_medals", [])
			if not medals.has(badge_id):
				medals.append(badge_id)
				pdata["earned_medals"] = medals
				medal_earned.emit(badge_id, badge_name)
			
			# Desbloquear siguiente grado si existe
			var next_grade = current_grade_num + 1
			var unlocked: Array = pdata.get("unlocked_grades", [1])
			if next_grade <= 6 and not unlocked.has(next_grade):
				unlocked.append(next_grade)
				pdata["unlocked_grades"] = unlocked
	
	_save_progress()
	progress_updated.emit()

# =========================================================================
# ADAPTACIÓN DE TEXTO CON EL PERFIL ACTIVO (Lyanna, etc.)
# =========================================================================

func adapt_text(text: String) -> String:
	if has_node("/root/ProfileManager"):
		var pm = get_node("/root/ProfileManager")
		if pm and pm.has_method("adapt_text"):
			var p_name = pm.get_player_name()
			var replaced = text.replace("{jugador}", p_name).replace("{player}", p_name)
			return pm.adapt_text(replaced)
	return text.replace("{jugador}", "Lyanna").replace("{player}", "Lyanna")
