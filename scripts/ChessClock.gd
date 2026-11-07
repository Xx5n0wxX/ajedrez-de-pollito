class_name ChessClock
extends RefCounted

## Reloj de ajedrez formal con conteo regresivo independiente para Blancas y Negras.
## Formato MM:SS, detección de tiempo agotado (timeout) y control de turnos.

signal time_updated(white_seconds: float, black_seconds: float)
signal timeout(loser_color: String) # "w" si se le agotó a Blancas, "b" a Negras

var is_enabled: bool = false
var initial_time: float = 300.0 # 5 minutos por defecto
var white_time: float = 300.0
var black_time: float = 300.0
var white_turn: bool = true
var is_running: bool = false
var has_ended: bool = false

func reset(time_seconds: float = 300.0) -> void:
	initial_time = time_seconds
	white_time = time_seconds
	black_time = time_seconds
	white_turn = true
	is_running = false
	has_ended = false
	time_updated.emit(white_time, black_time)

func start() -> void:
	if not has_ended:
		is_running = true

func pause() -> void:
	is_running = false

func set_turn(is_white: bool) -> void:
	white_turn = is_white

func update(delta: float) -> void:
	if not is_enabled or not is_running or has_ended:
		return

	if white_turn:
		white_time = maxf(0.0, white_time - delta)
		if white_time <= 0.0:
			has_ended = true
			is_running = false
			timeout.emit("w")
	else:
		black_time = maxf(0.0, black_time - delta)
		if black_time <= 0.0:
			has_ended = true
			is_running = false
			timeout.emit("b")

	time_updated.emit(white_time, black_time)

static func format_time(total_seconds: float) -> String:
	var total_sec_int: int = int(ceilf(total_seconds))
	var minutes: int = int(float(total_sec_int) / 60.0)
	var seconds: int = total_sec_int % 60
	return "%02d:%02d" % [minutes, seconds]
