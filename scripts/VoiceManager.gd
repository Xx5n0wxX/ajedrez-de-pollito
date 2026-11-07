extends Node

## Singleton Autoload para gestión de voz TTS del Profe Pollito
signal speech_started
signal speech_finished

# Activado y sincronizado con las animaciones faciales del Profe Pollito
const TTS_ENABLED: bool = true

var current_voice_id: String = ""
var is_speaking: bool = false
var is_muted: bool = false:
	set(val):
		is_muted = val
		if is_muted:
			stop()
var _current_callback: Callable = Callable()
var _current_utterance_id: int = 0
var _safety_timer: SceneTreeTimer = null

func _ready() -> void:
	if not TTS_ENABLED:
		return
	_init_voice()
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED, Callable(self, "_on_tts_started"))
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, Callable(self, "_on_tts_ended"))
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, Callable(self, "_on_tts_canceled"))

func _init_voice() -> void:
	if not TTS_ENABLED or not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return

	var voices: Array = DisplayServer.tts_get_voices()
	if voices.is_empty():
		print("[VoiceManager] No hay voces TTS instaladas en el sistema.")
		return
	
	# Buscar voz en español prioritariamente
	for v in voices:
		var lang: String = str(v.get("language", "")).to_lower()
		var vname: String = str(v.get("name", "")).to_lower()
		if lang.begins_with("es") or "spanish" in vname or "español" in vname or "helena" in vname or "sabina" in vname or "raul" in vname:
			current_voice_id = str(v.get("id", ""))
			print("[VoiceManager] Voz en español detectada: ", v.get("name"), " (", lang, ")")
			return
			
	# Fallback a la primera voz disponible
	current_voice_id = str(voices[0].get("id", ""))
	print("[VoiceManager] Usando voz fallback: ", voices[0].get("name"))

func speak(text: String, on_finished: Callable = Callable()) -> void:
	if not TTS_ENABLED:
		if on_finished.is_valid():
			on_finished.call()
		return

	if is_speaking:
		if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
			DisplayServer.tts_stop()
		is_speaking = false
		speech_finished.emit()
	_current_callback = Callable()

	if is_muted:
		if on_finished.is_valid():
			on_finished.call()
		return
	
	var active_name := "Lyanna"
	var clean_text := text.strip_edges()
	var pm = get_node_or_null("/root/ProfileManager")
	if pm:
		if pm.has_method("get_active_name"):
			active_name = str(pm.get_active_name())
		if pm.has_method("format_dialogue"):
			clean_text = str(pm.format_dialogue(text)).replace("{nombre}", active_name).strip_edges()
		else:
			clean_text = clean_text.replace("{nombre}", active_name)
	if clean_text.is_empty():
		if on_finished.is_valid():
			on_finished.call()
		return
		
	_current_callback = on_finished
	_current_utterance_id += 1
	var this_id := _current_utterance_id
	
	if current_voice_id.is_empty():
		_init_voice()
		
	if current_voice_id.is_empty() or not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		_trigger_callback_safely()
		return

	is_speaking = true
	speech_started.emit()
	
	# Llamada nativa no bloqueante
	DisplayServer.tts_speak(clean_text, current_voice_id, 80, 1.05, 1.0, this_id, true)
	
	# Temporizador de respaldo por si el SO no dispara el callback de finalización
	var words := clean_text.split(" ", false).size()
	var estimated_time: float = maxf(2.0, float(words) * 0.45)
	_safety_timer = get_tree().create_timer(estimated_time)
	_safety_timer.timeout.connect(func():
		if is_speaking and _current_utterance_id == this_id:
			_on_tts_ended(this_id)
	)

func stop() -> void:
	if is_speaking:
		if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
			DisplayServer.tts_stop()
		is_speaking = false
		speech_finished.emit()
	_current_callback = Callable()

func toggle_mute() -> bool:
	is_muted = not is_muted
	return is_muted

func _on_tts_started(_utterance_id: int) -> void:
	is_speaking = true
	speech_started.emit()

func _on_tts_ended(utterance_id: int) -> void:
	if utterance_id == _current_utterance_id and is_speaking:
		is_speaking = false
		speech_finished.emit()
		_trigger_callback_safely()

func _on_tts_canceled(utterance_id: int) -> void:
	if utterance_id == _current_utterance_id:
		is_speaking = false
		speech_finished.emit()
		_current_callback = Callable()

func _trigger_callback_safely() -> void:
	if _current_callback.is_valid():
		var cb := _current_callback
		_current_callback = Callable()
		cb.call()
