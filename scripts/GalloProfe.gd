@tool
extends Node2D
class_name GalloProfe

## Señales
signal estado_cambiado(nuevo_estado: String)
signal animacion_terminada(estado: String)

## Estados disponibles
enum Estado {
	IDLE,
	HABLANDO,
	EXPLICANDO,
	PENSANDO,
	CELEBRANDO,
	SORPRENDIDO
}

@export var estado_actual: Estado = Estado.EXPLICANDO:
	set(val):
		estado_actual = val
		_actualizar_estado_enum()

@export_range(0.4, 2.0, 0.1) var velocidad_general: float = 1.0
@export_range(0.2, 1.5, 0.1) var intensidad_rebote: float = 1.0

# Nodos del Rig
@onready var sombra: Polygon2D = $Sombra
@onready var patas: Node2D = $Patas
@onready var torso: Node2D = $Torso

# Partes hijas de Torso
@onready var cola: Node2D = $Torso/Cola
@onready var ala_izq: Node2D = $Torso/AlaIzquierda
@onready var cuerpo_base: Sprite2D = $Torso/CuerpoBase
@onready var cresta: Node2D = $Torso/Cresta
@onready var barbilla: Node2D = $Torso/Barbilla
@onready var pico_cerrado: Sprite2D = $Torso/Pico/PicoCerrado
@onready var pico_abierto: Sprite2D = $Torso/Pico/PicoAbierto
@onready var pupilas: Sprite2D = $Torso/Ojos/Pupilas
@onready var ojos_parpadeo: Sprite2D = $Torso/Ojos/OjosParpadeo
@onready var ojos_felices: Sprite2D = $Torso/Ojos/OjosFelices
@onready var ceja_izq: Node2D = $Torso/CejaIzq
@onready var ceja_der: Node2D = $Torso/CejaDer

# Variantes de mano derecha (hijas de Torso)
@onready var ala_der_abajo: Node2D = $Torso/AlaDerechaAbajo
@onready var ala_der_celeb: Node2D = $Torso/AlaDerechaCeleb
@onready var ala_puntero: Node2D = $Torso/AlaPuntero
@onready var ala_pensando: Node2D = $Torso/AlaPensando
@onready var ala_sorp_izq: Node2D = $Torso/AlaSorprendidoIzq
@onready var ala_sorp_der: Node2D = $Torso/AlaSorprendidoDer

# Variables de tiempo y física
var anim_time: float = 0.0
var blink_timer: float = 2.8
var is_blinking: bool = false
var talk_timer: float = 0.0
var mouth_open_talk: bool = false
var estado_duracion_timer: float = 0.0
var is_tts_speaking: bool = false
var hablar_manual_timer: float = 0.0

# Posiciones base para interpolación
var base_pupilas_pos: Vector2 = Vector2.ZERO
var base_ceja_izq_pos: Vector2 = Vector2.ZERO
var base_ceja_der_pos: Vector2 = Vector2.ZERO
var base_torso_pos: Vector2 = Vector2(0, -50)
var base_patas_pos: Vector2 = Vector2(0, -10)
var base_ala_izq_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	if has_node("Torso/Ojos/Pupilas"):
		base_pupilas_pos = pupilas.position
	if has_node("Torso/CejaIzq"):
		base_ceja_izq_pos = ceja_izq.position
	if has_node("Torso/CejaDer"):
		base_ceja_der_pos = ceja_der.position
	if has_node("Torso"):
		base_torso_pos = torso.position
	if has_node("Patas"):
		base_patas_pos = patas.position
	if has_node("Torso/AlaIzquierda"):
		base_ala_izq_pos = ala_izq.position
	_actualizar_estado_enum()
	_connect_tts()

func _connect_tts() -> void:
	if Engine.is_editor_hint():
		return
	if has_node("/root/VoiceManager"):
		var vm = get_node("/root/VoiceManager")
		if vm:
			if not vm.speech_started.is_connected(_on_speech_started):
				vm.speech_started.connect(_on_speech_started)
			if not vm.speech_finished.is_connected(_on_speech_finished):
				vm.speech_finished.connect(_on_speech_finished)
			is_tts_speaking = vm.is_speaking

func _on_speech_started() -> void:
	is_tts_speaking = true
	if estado_actual == Estado.IDLE:
		estado_actual = Estado.HABLANDO

func _on_speech_finished() -> void:
	is_tts_speaking = false
	mouth_open_talk = false
	if estado_actual == Estado.HABLANDO:
		idle()

func _process(delta: float) -> void:
	# Temporizador de duración de estado
	if estado_duracion_timer > 0.0:
		estado_duracion_timer -= delta
		if estado_duracion_timer <= 0.0:
			emit_signal("animacion_terminada", Estado.keys()[estado_actual])
			idle()

	if hablar_manual_timer > 0.0:
		hablar_manual_timer -= delta

	anim_time += delta * velocidad_general
	var s: float = clamp(intensidad_rebote, 0.2, 1.2)

	# Control de Parpadeo
	blink_timer -= delta
	if blink_timer <= 0.0:
		if is_blinking:
			is_blinking = false
			blink_timer = randf_range(2.4, 4.8)
		else:
			is_blinking = true
			blink_timer = 0.14

	# Variables destino (targets)
	var t_body_y: float = 0.0
	var t_patas_y: float = 0.0
	var t_scale_x: float = 1.0
	var t_scale_y: float = 1.0
	var t_body_rot: float = 0.0
	var t_tail_rot: float = 0.0
	var t_wave_rot: float = deg_to_rad(72.0)
	var t_wave_offset: Vector2 = Vector2(-46.0, 28.0)
	var t_right_down_rot: float = 0.0
	var t_right_celeb_rot: float = 0.0
	var t_ptr_rot: float = 0.0
	var t_comb_rot: float = 0.0
	var t_wattle_rot: float = 0.0
	var t_pupil_offset: Vector2 = Vector2.ZERO
	var t_brow_l_y: float = 0.0
	var t_brow_r_y: float = 0.0
	var t_brow_l_rot: float = 0.0
	var t_brow_r_rot: float = 0.0

	var use_happy_eyes: bool = false
	var show_left_wave: bool = true
	var show_right_down: bool = false
	var show_right_celeb: bool = false
	var show_ptr: bool = false
	var show_think: bool = false
	var show_surprise_hands: bool = false

	match estado_actual:
		Estado.IDLE:
			var resp: float = sin(anim_time * 2.4)
			var delay: float = sin(anim_time * 2.4 - 0.65)
			t_scale_x = 1.0 - resp * 0.015 * s
			t_scale_y = 1.0 + resp * 0.02 * s
			t_body_y = -resp * 3.5 * s
			t_tail_rot = deg_to_rad(delay * 4.0 * s)
			show_right_down = true
			t_wave_rot = deg_to_rad(72.0 + delay * 3.5 * s)
			t_right_down_rot = deg_to_rad(resp * 3.0 * s)
			t_comb_rot = deg_to_rad(delay * 3.5 * s)
			t_wattle_rot = deg_to_rad(delay * 3.0 * s)

		Estado.HABLANDO:
			var ritmo: float = sin(anim_time * 8.5)
			var inercia: float = sin(anim_time * 8.5 - 0.55)
			t_scale_x = 1.0 - ritmo * 0.02 * s
			t_scale_y = 1.0 + ritmo * 0.025 * s
			t_body_y = -abs(ritmo) * 6.0 * s
			t_tail_rot = deg_to_rad(inercia * 5.5 * s)
			show_right_down = true
			t_wave_offset = Vector2.ZERO
			t_wave_rot = deg_to_rad(-8.0 + sin(anim_time * 9.0) * 14.0 * s)
			t_right_down_rot = deg_to_rad(-6.0 + cos(anim_time * 5.0) * 6.0 * s)
			t_comb_rot = deg_to_rad(inercia * 5.0 * s)
			t_wattle_rot = deg_to_rad(inercia * 5.5 * s)
			t_brow_l_y = -4.0 - abs(ritmo) * 4.0
			t_brow_r_y = -4.0 - abs(ritmo) * 4.0

		Estado.EXPLICANDO:
			var ritmo: float = sin(anim_time * 6.5)
			var inercia: float = sin(anim_time * 6.5 - 0.5)
			t_scale_x = 1.0 - ritmo * 0.018 * s
			t_scale_y = 1.0 + ritmo * 0.022 * s
			t_body_rot = deg_to_rad(-1.5 * s)
			t_tail_rot = deg_to_rad(-6.0 + inercia * 5.0 * s)
			show_ptr = true
			t_wave_rot = deg_to_rad(72.0 + inercia * 3.5 * s)
			t_ptr_rot = deg_to_rad(-22.0 + sin(anim_time * 5.5) * 6.5 * s)
			t_comb_rot = deg_to_rad(3.0 + inercia * 4.5 * s)
			t_wattle_rot = deg_to_rad(-3.0 + inercia * 4.5 * s)
			t_pupil_offset = Vector2(6.0, -4.0)
			t_brow_l_y = -10.0
			t_brow_r_y = -10.0
			t_brow_l_rot = deg_to_rad(-7.0)
			t_brow_r_rot = deg_to_rad(7.0)

		Estado.PENSANDO:
			var onda: float = sin(anim_time * 2.2)
			var inercia: float = sin(anim_time * 2.2 - 0.6)
			t_body_rot = deg_to_rad(1.5 * s)
			t_scale_y = 1.0 + onda * 0.012 * s
			t_tail_rot = deg_to_rad(-3.0 + inercia * 3.0 * s)
			show_think = true
			t_wave_rot = deg_to_rad(72.0 + onda * 3.5 * s)
			t_comb_rot = deg_to_rad(2.5 + inercia * 2.5 * s)
			t_wattle_rot = deg_to_rad(2.0 + inercia * 2.5 * s)
			t_pupil_offset = Vector2(0.0, -15.0 + sin(anim_time * 1.5) * 1.5)
			t_brow_l_y = -4.0
			t_brow_r_y = -6.0
			t_brow_l_rot = deg_to_rad(-4.0)
			t_brow_r_rot = deg_to_rad(4.0)

		Estado.CELEBRANDO:
			var salto: float = abs(sin(anim_time * 7.5))
			var inercia: float = sin(anim_time * 7.5 - 0.45)
			# Salto alegre coordinado: cuerpo y patas se mueven juntos
			# manteniendo un solapamiento perfecto de 27px (cero huecos)
			t_body_y = -salto * 7.0 * s
			t_patas_y = -salto * 5.5 * s
			t_scale_x = 1.0 - (salto - 0.3) * 0.03 * s
			t_scale_y = 1.0 + (salto - 0.3) * 0.035 * s
			t_tail_rot = deg_to_rad(8.0 + inercia * 8.0 * s)
			show_right_celeb = true
			t_wave_offset = Vector2.ZERO
			t_wave_rot = deg_to_rad(-14.0 - salto * 12.0 * s)
			t_right_celeb_rot = deg_to_rad(10.0 + salto * 12.0 * s)
			t_comb_rot = deg_to_rad(-inercia * 6.0 * s)
			t_wattle_rot = deg_to_rad(inercia * 5.0 * s)
			t_brow_l_y = -10.0
			t_brow_r_y = -10.0
			t_brow_l_rot = deg_to_rad(-8.0)
			t_brow_r_rot = deg_to_rad(8.0)
			use_happy_eyes = true

		Estado.SORPRENDIDO:
			var temblor: float = sin(anim_time * 20.0)
			t_body_y = -5.0 * s
			t_patas_y = -3.0 * s
			t_scale_x = 0.97
			t_scale_y = 1.03
			t_tail_rot = deg_to_rad(-8.0 + temblor * 2.0 * s)
			show_left_wave = false
			show_surprise_hands = true
			t_comb_rot = deg_to_rad(-6.0 + temblor * 2.5 * s)
			t_wattle_rot = deg_to_rad(temblor * 3.0 * s)
			t_pupil_offset = Vector2(0.0, -5.0)
			t_brow_l_y = -16.0
			t_brow_r_y = -16.0
			t_brow_l_rot = deg_to_rad(-14.0)
			t_brow_r_rot = deg_to_rad(14.0)

	# --- CONTROL DE APERTURA/CIERRE DE PICO (SINCRONIZADO CON TTS) ---
	var use_open_beak: bool = false
	var debe_aletear_pico: bool = false

	if not Engine.is_editor_hint() and has_node("/root/VoiceManager"):
		var vm = get_node("/root/VoiceManager")
		if vm and vm.TTS_ENABLED and not vm.is_muted:
			debe_aletear_pico = vm.is_speaking or is_tts_speaking
		else:
			debe_aletear_pico = (estado_actual == Estado.HABLANDO or estado_actual == Estado.EXPLICANDO) and (estado_duracion_timer > 0.0 or hablar_manual_timer > 0.0)
	else:
		debe_aletear_pico = (estado_actual == Estado.HABLANDO or estado_actual == Estado.EXPLICANDO) and (estado_duracion_timer > 0.0 or hablar_manual_timer > 0.0 or Engine.is_editor_hint())

	if debe_aletear_pico:
		talk_timer -= delta
		if talk_timer <= 0.0:
			mouth_open_talk = not mouth_open_talk
			talk_timer = randf_range(0.10, 0.16)
		use_open_beak = mouth_open_talk
	else:
		mouth_open_talk = false
		if estado_actual == Estado.CELEBRANDO or estado_actual == Estado.SORPRENDIDO:
			use_open_beak = true
		else:
			use_open_beak = false

	# Interpolación suave (LERP)
	var w: float = clamp(delta * 14.0, 0.0, 1.0)
	torso.position.y = lerp(torso.position.y, base_torso_pos.y + t_body_y, w)
	patas.position.y = lerp(patas.position.y, base_patas_pos.y + t_patas_y, w)
	torso.scale.x = lerp(torso.scale.x, t_scale_x, w)
	torso.scale.y = lerp(torso.scale.y, t_scale_y, w)
	torso.rotation = lerp(torso.rotation, t_body_rot, w)

	cola.rotation = lerp(cola.rotation, t_tail_rot, w)
	ala_izq.rotation = lerp(ala_izq.rotation, t_wave_rot, w)
	ala_izq.position = lerp(ala_izq.position, base_ala_izq_pos + t_wave_offset, w)
	ala_izq.visible = show_left_wave

	cresta.rotation = lerp(cresta.rotation, t_comb_rot, w)
	barbilla.rotation = lerp(barbilla.rotation, t_wattle_rot, w)

	pupilas.position = lerp(pupilas.position, base_pupilas_pos + t_pupil_offset, w)
	ceja_izq.position.y = lerp(ceja_izq.position.y, base_ceja_izq_pos.y + t_brow_l_y, w)
	ceja_der.position.y = lerp(ceja_der.position.y, base_ceja_der_pos.y + t_brow_r_y, w)
	ceja_izq.rotation = lerp(ceja_izq.rotation, t_brow_l_rot, w)
	ceja_der.rotation = lerp(ceja_der.rotation, t_brow_r_rot, w)

	# Control de ojos y boca
	if use_happy_eyes:
		ojos_felices.visible = true
		ojos_parpadeo.visible = false
		pupilas.visible = false
	elif is_blinking:
		ojos_felices.visible = false
		ojos_parpadeo.visible = true
		pupilas.visible = false
	else:
		ojos_felices.visible = false
		ojos_parpadeo.visible = false
		pupilas.visible = true

	pico_abierto.visible = use_open_beak
	pico_cerrado.visible = not use_open_beak

	# Variantes de mano derecha
	ala_der_abajo.visible = show_right_down
	if show_right_down:
		ala_der_abajo.rotation = lerp(ala_der_abajo.rotation, t_right_down_rot, w)

	ala_der_celeb.visible = show_right_celeb
	if show_right_celeb:
		ala_der_celeb.rotation = lerp(ala_der_celeb.rotation, t_right_celeb_rot, w)

	ala_puntero.visible = show_ptr
	if show_ptr:
		ala_puntero.rotation = lerp(ala_puntero.rotation, t_ptr_rot, w)

	ala_pensando.visible = show_think
	if show_think:
		ala_pensando.rotation = sin(anim_time * 3.0) * 0.045 * s

	ala_sorp_izq.visible = show_surprise_hands
	ala_sorp_der.visible = show_surprise_hands
	if show_surprise_hands:
		var jiggle: float = sin(anim_time * 20.0) * 0.04 * s
		ala_sorp_izq.rotation = jiggle
		ala_sorp_der.rotation = -jiggle

	# Escala de sombra en el suelo
	if sombra:
		var sombra_mult: float = 1.0 - clamp(-t_patas_y / 20.0, 0.0, 0.2)
		sombra.scale.x = torso.scale.x * sombra_mult
		sombra.scale.y = sombra_mult

func _actualizar_estado_enum() -> void:
	emit_signal("estado_cambiado", Estado.keys()[estado_actual])

## API Pública para controlar desde tu juego:
func idle() -> void:
	estado_actual = Estado.IDLE
	estado_duracion_timer = 0.0
	hablar_manual_timer = 0.0

func hablar(duracion: float = 3.0) -> void:
	estado_actual = Estado.HABLANDO
	estado_duracion_timer = duracion
	hablar_manual_timer = duracion

func saludar(duracion: float = 3.0) -> void:
	hablar(duracion)

func explicar(duracion: float = 4.5) -> void:
	estado_actual = Estado.EXPLICANDO
	estado_duracion_timer = duracion
	hablar_manual_timer = duracion

func pensar() -> void:
	estado_actual = Estado.PENSANDO
	estado_duracion_timer = 0.0
	hablar_manual_timer = 0.0

func celebrar(duracion: float = 3.5) -> void:
	estado_actual = Estado.CELEBRANDO
	estado_duracion_timer = duracion
	hablar_manual_timer = 0.0

func sorprendido(duracion: float = 2.0) -> void:
	estado_actual = Estado.SORPRENDIDO
	estado_duracion_timer = duracion
	hablar_manual_timer = 0.0

func parpadear() -> void:
	is_blinking = true
	blink_timer = 0.18

func on_tts_started() -> void:
	is_tts_speaking = true
	if estado_actual == Estado.IDLE:
		estado_actual = Estado.HABLANDO

func on_tts_finished() -> void:
	is_tts_speaking = false
	mouth_open_talk = false
	if estado_actual == Estado.HABLANDO:
		idle()

func set_estado(nombre_estado: String, duracion: float = 0.0) -> void:
	var n: String = nombre_estado.to_upper().strip_edges()
	for k in Estado.keys():
		if k == n:
			estado_actual = Estado[k]
			estado_duracion_timer = duracion
			if estado_actual == Estado.HABLANDO or estado_actual == Estado.EXPLICANDO:
				hablar_manual_timer = duracion
			return
	push_warning("Estado desconocido: " + nombre_estado)
