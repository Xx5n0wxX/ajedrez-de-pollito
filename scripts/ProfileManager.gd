extends Node

## ProfileManager: Gestión y persistencia de perfiles de jugador (Nombre y Sexo)
## Permite crear, editar, alternar perfiles y adaptar dinámicamente nombres y concordancia
## de género en los diálogos hablados y escritos del Profe Pollito.

signal active_profile_changed(profile: Dictionary)
signal profiles_updated()

const SAVE_PATH: String = "user://player_profiles.json"

static var instance: ProfileManager = null

var profiles: Array = []
var active_profile_id: String = ""
var is_first_time: bool = false

func _init() -> void:
	instance = self
	_load_profiles()

func _ready() -> void:
	if instance == null:
		instance = self

func _load_profiles() -> void:
	profiles.clear()
	var file_exists = FileAccess.file_exists(SAVE_PATH)
	if file_exists:
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(text) == OK and json.data is Dictionary:
				var data: Dictionary = json.data
				profiles = data.get("profiles", [])
				active_profile_id = data.get("active_profile_id", "")

	# Si no hay perfiles guardados, marcar is_first_time y proveer un perfil provisional en memoria
	# (NO guardarlo en disco hasta que el usuario confirme sus datos en el modal inicial)
	if profiles.is_empty():
		is_first_time = true
		var default_prof = {
			"id": "profile_init_temp",
			"name": "",
			"gender": "f", # "f": Niña / "m": Niño
			"category": "child", # "child" | "adult"
			"is_adult": false
		}
		profiles.append(default_prof)
		active_profile_id = "profile_init_temp"
	else:
		is_first_time = false
		# Validar que el active_profile_id sea válido
		var found_active = false
		for p in profiles:
			if p is Dictionary and p.get("id", "") == active_profile_id:
				found_active = true
				break
		if not found_active and not profiles.is_empty():
			active_profile_id = profiles[0].get("id", "")

func _save_profiles() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("[ProfileManager] No se pudo guardar perfiles en: " + SAVE_PATH)
		return
	var data = {
		"active_profile_id": active_profile_id,
		"profiles": profiles
	}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func get_active_profile() -> Dictionary:
	for p in profiles:
		if p is Dictionary and p.get("id", "") == active_profile_id:
			return p
	if not profiles.is_empty() and profiles[0] is Dictionary:
		return profiles[0]
	return {"id": "default", "name": "Jugador", "gender": "f", "category": "child", "is_adult": false}

func is_adult() -> bool:
	var prof = get_active_profile()
	var cat = str(prof.get("category", "child")).to_lower()
	return cat in ["adult", "adulto", "adulta"] or prof.get("is_adult", false) == true

func is_adult_profile() -> bool:
	return is_adult()

func get_player_category() -> String:
	return "adult" if is_adult() else "child"

func get_player_name() -> String:
	var prof = get_active_profile()
	var n = str(prof.get("name", "")).strip_edges()
	if n.is_empty():
		if is_adult():
			return "Adulta" if is_female() else "Adulto"
		return "Jugadora" if is_female() else "Jugador"
	return n

func get_player_gender() -> String:
	var prof = get_active_profile()
	var g = str(prof.get("gender", "f")).to_lower()
	return "m" if g in ["m", "niño", "nino", "chico", "adulto", "hombre"] else "f"

func is_female() -> bool:
	return get_player_gender() == "f"

func is_male() -> bool:
	return get_player_gender() == "m"

func get_gender_label() -> String:
	if is_adult():
		return "Adulta" if is_female() else "Adulto"
	return "Niña" if is_female() else "Niño"

func get_gender_icon() -> String:
	if is_adult():
		return "👩" if is_female() else "👨"
	return "👧" if is_female() else "👦"

func get_all_profiles() -> Array:
	return profiles.duplicate(true)

func set_active_profile_by_id(p_id: String) -> bool:
	for p in profiles:
		if p is Dictionary and p.get("id", "") == p_id:
			active_profile_id = p_id
			_save_profiles()
			active_profile_changed.emit(p)
			return true
	return false

func create_profile(p_name: String, p_gender: String, p_category: String = "child") -> Dictionary:
	var clean_cat = "adult" if p_category.to_lower() in ["adult", "adulto", "adulta"] else "child"
	var is_ad = (clean_cat == "adult")
	var clean_name = p_name.strip_edges()
	var clean_gender = "m" if p_gender.to_lower() in ["m", "niño", "nino", "chico", "adulto", "hombre"] else "f"
	if clean_name.is_empty():
		if is_ad:
			clean_name = "Adulta" if clean_gender == "f" else "Adulto"
		else:
			clean_name = "Niño" if clean_gender == "m" else "Niña"
	var new_id = "profile_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 1000]
	var new_prof = {
		"id": new_id,
		"name": clean_name,
		"gender": clean_gender,
		"category": clean_cat,
		"is_adult": is_ad
	}
	if is_first_time:
		profiles.clear()
		is_first_time = false
	profiles.append(new_prof)
	active_profile_id = new_id
	_save_profiles()
	profiles_updated.emit()
	active_profile_changed.emit(new_prof)
	return new_prof

func update_profile(p_id: String, new_name: String, new_gender: String, new_category: String = "") -> bool:
	for i in range(profiles.size()):
		if profiles[i] is Dictionary and profiles[i].get("id", "") == p_id:
			var clean_name = new_name.strip_edges()
			var clean_gender = "m" if new_gender.to_lower() in ["m", "niño", "nino", "chico", "adulto", "hombre"] else "f"
			var cur_cat = str(profiles[i].get("category", "child"))
			var clean_cat = new_category.to_lower() if not new_category.is_empty() else cur_cat
			if clean_cat not in ["adult", "adulto", "adulta", "child"]:
				clean_cat = "child"
			if clean_cat in ["adult", "adulto", "adulta"]:
				clean_cat = "adult"
			var is_ad = (clean_cat == "adult")
			if clean_name.is_empty():
				if is_ad:
					clean_name = "Adulta" if clean_gender == "f" else "Adulto"
				else:
					clean_name = "Niño" if clean_gender == "m" else "Niña"
			profiles[i]["name"] = clean_name
			profiles[i]["gender"] = clean_gender
			profiles[i]["category"] = clean_cat
			profiles[i]["is_adult"] = is_ad
			if is_first_time:
				is_first_time = false
			_save_profiles()
			profiles_updated.emit()
			if p_id == active_profile_id:
				active_profile_changed.emit(profiles[i])
			return true
	return false

func delete_profile(p_id: String) -> bool:
	if profiles.size() <= 1:
		return false # Mantener siempre al menos un perfil
	var idx = -1
	for i in range(profiles.size()):
		if profiles[i] is Dictionary and profiles[i].get("id", "") == p_id:
			idx = i
			break
	if idx != -1:
		profiles.remove_at(idx)
		if active_profile_id == p_id:
			active_profile_id = profiles[0].get("id", "")
			active_profile_changed.emit(profiles[0])
		_save_profiles()
		profiles_updated.emit()
		return true
	return false

# =========================================================================
# ADAPTACIÓN DINÁMICA DE TEXTO Y CONCORDANCIA DE GÉNERO
# =========================================================================

func adapt_text(text: String) -> String:
	if text.is_empty():
		return ""
	var p_name = get_player_name()
	var fem = is_female()

	var res = text

	# 1. Reemplazo del nombre
	res = res.replace("Lyanna", p_name)
	res = res.replace("{nombre}", p_name)
	res = res.replace("{player}", p_name)

	# 2. Reemplazo de plantillas explícitas
	if fem:
		res = res.replace("{a/o}", "a")
		res = res.replace("{o/a}", "a")
		res = res.replace("{campeona/campeon}", "campeona")
		res = res.replace("{campeon/campeona}", "campeona")
		res = res.replace("{graciosa/gracioso}", "graciosa")
		res = res.replace("{gracioso/graciosa}", "graciosa")
		res = res.replace("{segura/seguro}", "segura")
		res = res.replace("{seguro/segura}", "segura")
		res = res.replace("{bienvenida/bienvenido}", "bienvenida")
		res = res.replace("{bienvenido/bienvenida}", "bienvenida")
		res = res.replace("{amiga/amigo}", "amiga")
		res = res.replace("{amigo/amiga}", "amiga")
		res = res.replace("{la/el}", "la")
		res = res.replace("{el/la}", "la")
		res = res.replace("{una/un}", "una")
		res = res.replace("{un/una}", "una")
		res = res.replace("{divertida/divertido}", "divertida")
	else:
		res = res.replace("{a/o}", "o")
		res = res.replace("{o/a}", "o")
		res = res.replace("{campeona/campeon}", "campeón")
		res = res.replace("{campeon/campeona}", "campeón")
		res = res.replace("{graciosa/gracioso}", "gracioso")
		res = res.replace("{gracioso/graciosa}", "gracioso")
		res = res.replace("{segura/seguro}", "seguro")
		res = res.replace("{seguro/segura}", "seguro")
		res = res.replace("{bienvenida/bienvenido}", "bienvenido")
		res = res.replace("{bienvenido/bienvenida}", "bienvenido")
		res = res.replace("{amiga/amigo}", "amigo")
		res = res.replace("{amigo/amiga}", "amigo")
		res = res.replace("{la/el}", "el")
		res = res.replace("{el/la}", "el")
		res = res.replace("{una/un}", "un")
		res = res.replace("{un/una}", "un")
		res = res.replace("{divertida/divertido}", "divertido")

	# 3. Adaptaciones gramaticales para jugadores masculinos en textos existentes
	if not fem:
		# Frases clave completas y vocabulario específico
		res = res.replace("¡Eres una campeona del ajedrez!", "¡Eres un campeón del ajedrez!")
		res = res.replace("eres una campeona del ajedrez", "eres un campeón del ajedrez")
		res = res.replace("eres una campeona", "eres un campeón")
		res = res.replace("una campeona", "un campeón")
		res = res.replace("la campeona", "el campeón")
		res = res.replace("¡Campeona!", "¡Campeón!")
		res = res.replace("campeona del ajedrez", "campeón del ajedrez")
		res = res.replace("gran campeona", "gran campeón")
		res = res.replace("grandes maestras", "grandes maestros")

		# Segura / Seguro
		res = res.replace("¿Estás segura", "¿Estás seguro")
		res = res.replace("estás segura", "estás seguro")
		res = res.replace("Estoy segura", "Estoy seguro")
		res = res.replace("estoy segura", "estoy seguro")

		# Graciosa / Gracioso (requerimiento explícito del usuario)
		res = res.replace("muy graciosa", "muy gracioso")
		res = res.replace("eres muy graciosa", "eres muy gracioso")
		res = res.replace("eres tan graciosa", "eres tan gracioso")
		res = res.replace("qué graciosa", "qué gracioso")
		res = res.replace("graciosa", "gracioso")
		res = res.replace("Graciosa", "Gracioso")

		# Bienvenida / Preparada / Atenta / Concentrada
		res = res.replace("¡Bienvenida!", "¡Bienvenido!")
		res = res.replace("Bienvenida", "Bienvenido")
		res = res.replace("bienvenida", "bienvenido")
		res = res.replace("preparada para", "preparado para")
		res = res.replace("¿Estás preparada", "¿Estás preparado")
		res = res.replace("estás preparada", "estás preparado")
		res = res.replace("debes estar atenta", "debes estar atento")
		res = res.replace("muy atenta", "muy atento")
		res = res.replace("atenta a", "atento a")
		res = res.replace("muy concentrada", "muy concentrado")
		res = res.replace("tan concentrada", "tan concentrado")
		res = res.replace("concentrada en", "concentrado en")
		res = res.replace("eres muy rápida", "eres muy rápido")
		res = res.replace("muy rápida", "muy rápido")
		res = res.replace("pequeña amiga", "pequeño amigo")
		res = res.replace("amiga mía", "amigo mío")
		res = res.replace("la jugadora", "el jugador")
		res = res.replace("de la jugadora", "del jugador")
		res = res.replace("estás lista", "estás listo")
		res = res.replace("lista para jugar", "listo para jugar")
		res = res.replace("lista para empezar", "listo para empezar")

	# 4. Adaptaciones específicas para perfil de Adulto
	if is_adult():
		# Reemplazar diminutivos infantiles por trato respetuoso de ajedrecista
		res = res.replace("pequeña campeona", "gran campeona" if fem else "gran campeón")
		res = res.replace("pequeño campeón", "gran campeón")
		res = res.replace("pequeña amiga", "amiga mía" if fem else "amigo mío")
		res = res.replace("pequeño amigo", "amigo mío")
		res = res.replace("mi pequeña amiga", "mi estimada colega" if fem else "mi estimado colega")
		res = res.replace("mi pequeño amigo", "mi estimado colega")
		res = res.replace("mi pequeña alumna", "mi estimada alumna")
		res = res.replace("mi pequeño alumno", "mi estimado alumno")
		res = res.replace("mi pequeña", "mi colega")
		res = res.replace("mi pequeño", "mi colega")
		res = res.replace("¡Hola peque!", "¡Hola!")
		res = res.replace("hola peque", "hola")
		res = res.replace("Hola peque", "Hola")

	return res

# Métodos estáticos de conveniencia
static func get_active_name() -> String:
	if instance:
		return instance.get_player_name()
	return "Lyanna"

static func is_girl() -> bool:
	if instance:
		return instance.is_female()
	return true

static func is_adult_player() -> bool:
	if instance:
		return instance.is_adult()
	return false

static func format_dialogue(text: String) -> String:
	if instance:
		return instance.adapt_text(text)
	return text
