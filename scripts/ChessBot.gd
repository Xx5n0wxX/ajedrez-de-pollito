class_name ChessBot
extends RefCounted

@warning_ignore("shadowed_global_identifier")
const ChessRules = preload("res://scripts/ChessRules.gd")

## Motor de Inteligencia Artificial para Ajedrez de Pollito
## 5 Niveles de dificultad calibrados:
## 1: 🐣 Pollito Principiante (~600-800 ELO)
## 2: 🐥 Pollito Aprendiz (~1100-1300 ELO)
## 3: 🐔 Profe Pollito (~1600-1800 ELO)
## 4: 🦅 Pollito Maestro (~2100-2300 ELO)
## 5: 👑 Pollito Gran Maestro (~2600+ ELO / Máxima Fuerza)
##
## Integra Stockfish oficial (vía UCI) para cálculo instantáneo en milisegundos,
## con fallback automático y transparente a Minimax GDScript.

# -------------------------------------------------------------
# CONTROL DEL PROCESO STOCKFISH (UCI)
# -------------------------------------------------------------
static var _sf_path_cached: String = ""
var _sf_stdio: FileAccess = null
var _sf_pid: int = 0
var _sf_ready: bool = false
var _is_shutting_down: bool = false
var _sf_mutex: Mutex = Mutex.new()

static func get_stockfish_path() -> String:
	if _sf_path_cached != "" and FileAccess.file_exists(_sf_path_cached):
		return _sf_path_cached

	var os_name := OS.get_name()
	if os_name == "Android":
		var android_sf := _find_android_stockfish_path()
		if android_sf != "":
			_sf_path_cached = android_sf
			return android_sf
		return ""

	var exe_dir = OS.get_executable_path().get_base_dir()
	var candidates: Array[String] = []
	if os_name == "Windows":
		candidates = [
			exe_dir.path_join("bin/stockfish.exe"),
			exe_dir.path_join("stockfish.exe"),
			ProjectSettings.globalize_path("res://bin/stockfish.exe"),
			ProjectSettings.globalize_path("res://engines/stockfish.exe")
		]
	else:
		candidates = [
			exe_dir.path_join("bin/stockfish"),
			exe_dir.path_join("stockfish"),
			ProjectSettings.globalize_path("res://bin/stockfish"),
			ProjectSettings.globalize_path("res://engines/stockfish")
		]
	for p in candidates:
		if FileAccess.file_exists(p):
			_sf_path_cached = p
			return p
	return ""

static func _find_android_stockfish_path() -> String:
	# 1. Localizar el directorio nativo real (lib/arm64 o lib/arm) leyendo /proc/self/maps
	if FileAccess.file_exists("/proc/self/maps"):
		var maps_file := FileAccess.open("/proc/self/maps", FileAccess.READ)
		if maps_file:
			while not maps_file.eof_reached():
				var line := maps_file.get_line()
				if line.contains("libgodot_android.so") or line.contains("libc++_shared.so"):
					var slash_idx := line.find("/")
					if slash_idx != -1:
						var lib_full_path := line.substr(slash_idx).strip_edges()
						var native_dir := lib_full_path.get_base_dir()
						var candidate := native_dir.path_join("libstockfish.so")
						if FileAccess.file_exists(candidate):
							return candidate
	# 2. Fallback por symlink estándar de datos de aplicación en Android
	var data_base := OS.get_user_data_dir().get_base_dir()
	var fallback_candidates: Array[String] = [
		data_base.path_join("lib/libstockfish.so"),
		"/data/data/com.pollito.ajedrez/lib/libstockfish.so",
		OS.get_executable_path().get_base_dir().path_join("libstockfish.so")
	]
	for c in fallback_candidates:
		if FileAccess.file_exists(c):
			return c
	return ""

func _ensure_stockfish() -> bool:
	if _is_shutting_down:
		return false
	if _sf_ready and _sf_stdio != null and OS.is_process_running(_sf_pid):
		return true

	_close_stockfish()

	var path = get_stockfish_path()
	if path == "":
		return false

	var proc = OS.execute_with_pipe(path, [], false)
	if proc.is_empty() or not proc.has("stdio"):
		return false

	_sf_stdio = proc.get("stdio")
	_sf_pid = proc.get("pid", 0)

	# Handshake UCI inicial
	_sf_stdio.store_line("uci")
	_sf_stdio.flush()

	var start_t = Time.get_ticks_msec()
	var got_uciok = false
	while Time.get_ticks_msec() - start_t < 1500:
		if _is_shutting_down or _sf_stdio == null:
			break
		var line = _sf_stdio.get_line()
		if line == "uciok":
			got_uciok = true
			break
		OS.delay_msec(2)

	if not got_uciok:
		_close_stockfish()
		return false

	_sf_ready = true
	return true

func _close_stockfish() -> void:
	if _sf_stdio != null:
		_sf_stdio.store_line("quit")
		_sf_stdio.flush()
		_sf_stdio = null
	if _sf_pid > 0 and OS.is_process_running(_sf_pid):
		OS.kill(_sf_pid)
	_sf_pid = 0
	_sf_ready = false

func shutdown() -> void:
	_is_shutting_down = true
	# Matar primero el proceso externo para desbloquear cualquier get_line() en hilos secundarios
	if _sf_pid > 0 and OS.is_process_running(_sf_pid):
		OS.kill(_sf_pid)
	if _sf_mutex.try_lock():
		_close_stockfish()
		_sf_mutex.unlock()
	else:
		_sf_ready = false

func _query_stockfish(fen: String, difficulty: int) -> Dictionary:
	if _is_shutting_down or not _ensure_stockfish() or _sf_stdio == null:
		return {}

	var movetime: int = 100
	match difficulty:
		1:
			# Nivel 1: Pollito Principiante (~600-800 ELO)
			_sf_stdio.store_line("setoption name UCI_LimitStrength value false")
			_sf_stdio.store_line("setoption name Skill Level value 0")
			movetime = 40
		2:
			# Nivel 2: Pollito Aprendiz (~1100-1300 ELO)
			_sf_stdio.store_line("setoption name UCI_LimitStrength value true")
			_sf_stdio.store_line("setoption name UCI_Elo value 1320")
			movetime = 70
		3:
			# Nivel 3: Profe Pollito (~1600-1800 ELO)
			_sf_stdio.store_line("setoption name UCI_LimitStrength value true")
			_sf_stdio.store_line("setoption name UCI_Elo value 1700")
			movetime = 100
		4:
			# Nivel 4: Pollito Maestro (~2100-2300 ELO)
			_sf_stdio.store_line("setoption name UCI_LimitStrength value true")
			_sf_stdio.store_line("setoption name UCI_Elo value 2200")
			movetime = 150
		5:
			# Nivel 5: Pollito Gran Maestro (~2600+ ELO / Máxima Fuerza)
			_sf_stdio.store_line("setoption name UCI_LimitStrength value false")
			_sf_stdio.store_line("setoption name Skill Level value 20")
			movetime = 250

	if _is_shutting_down or _sf_stdio == null:
		return {}
	_sf_stdio.store_line("isready")
	_sf_stdio.flush()

	var start_t = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_t < 1000:
		if _is_shutting_down or _sf_stdio == null:
			return {}
		var line = _sf_stdio.get_line()
		if line == "readyok":
			break
		OS.delay_msec(2)

	if _is_shutting_down or _sf_stdio == null:
		return {}
	_sf_stdio.store_line("position fen " + fen)
	_sf_stdio.store_line("go movetime %d" % movetime)
	_sf_stdio.flush()

	var bestmove_str: String = ""
	start_t = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_t < (movetime + 2000):
		if _is_shutting_down or _sf_stdio == null:
			return {}
		var line = _sf_stdio.get_line()
		if line.begins_with("bestmove"):
			var parts = line.split(" ")
			if parts.size() >= 2:
				bestmove_str = parts[1]
			break
		OS.delay_msec(2)

	if bestmove_str == "" or bestmove_str == "(none)" or bestmove_str.length() < 4:
		return {}

	var from_sq = bestmove_str.substr(0, 2)
	var to_sq = bestmove_str.substr(2, 2)
	var promo = bestmove_str.substr(4, 1) if bestmove_str.length() >= 5 else ""

	return {
		"from": ChessRules.sq_to_vec(from_sq),
		"to": ChessRules.sq_to_vec(to_sq),
		"promo": promo
	}

# -------------------------------------------------------------
# EJECUCIÓN ASÍNCRONA (0 MS EN HILO PRINCIPAL)
# -------------------------------------------------------------
func get_best_move_async(rules: ChessRules, difficulty: int, on_complete: Callable) -> void:
	var rules_clone = rules.clone()
	WorkerThreadPool.add_task(func():
		var chosen_move = get_best_move(rules_clone, difficulty)
		on_complete.call_deferred(chosen_move)
	)

# -------------------------------------------------------------
# CÁLCULO PRINCIPAL
# -------------------------------------------------------------
func get_best_move(rules: ChessRules, difficulty: int) -> Dictionary:
	var legal_moves = rules.get_all_legal_moves(rules.white_to_move)
	if legal_moves.is_empty():
		return {}

	# Nivel 1: Descuidos ocasionales para simular jugador principiante / infantil
	if difficulty == 1 and randf() < 0.25:
		var captures: Array[Dictionary] = []
		for m in legal_moves:
			if rules.get_piece_at(m["to"]) != "":
				captures.append(m)
		if not captures.is_empty() and randf() < 0.5:
			captures.shuffle()
			return captures[0]
		legal_moves.shuffle()
		return legal_moves[0]

	# 1. Intentar cálculo ultra-rápido con Stockfish (vía UCI)
	_sf_mutex.lock()
	var sf_move = _query_stockfish(rules.to_fen(), difficulty)
	_sf_mutex.unlock()

	if not sf_move.is_empty():
		# Validar que la jugada devuelta por Stockfish sea legal según ChessRules
		for m in legal_moves:
			if m["from"] == sf_move["from"] and m["to"] == sf_move["to"]:
				return sf_move

	# 2. Fallback a algoritmo nativo GDScript si Stockfish no está disponible
	return get_best_move_gdscript(rules, difficulty)

# -------------------------------------------------------------
# FALLBACK: ALGORITMO NATIVO GDSCRIPT (MINIMAX CON TABLAS PST)
# -------------------------------------------------------------
const PAWN_TABLE: Array[int] = [
	0,  0,  0,  0,  0,  0,  0,  0,
	50, 50, 50, 50, 50, 50, 50, 50,
	10, 10, 20, 30, 30, 20, 10, 10,
	5,  5, 10, 25, 25, 10,  5,  5,
	0,  0,  0, 20, 20,  0,  0,  0,
	5, -5,-10,  0,  0,-10, -5,  5,
	5, 10, 10,-20,-20, 10, 10,  5,
	0,  0,  0,  0,  0,  0,  0,  0
]

const KNIGHT_TABLE: Array[int] = [
	-50,-40,-30,-30,-30,-30,-40,-50,
	-40,-20,  0,  0,  0,  0,-20,-40,
	-30,  0, 10, 15, 15, 10,  0,-30,
	-30,  5, 15, 20, 20, 15,  5,-30,
	-30,  0, 15, 20, 20, 15,  0,-30,
	-30,  5, 10, 15, 15, 10,  5,-30,
	-40,-20,  0,  5,  5,  0,-20,-40,
	-50,-40,-30,-30,-30,-30,-40,-50
]

const BISHOP_TABLE: Array[int] = [
	-20,-10,-10,-10,-10,-10,-10,-20,
	-10,  0,  0,  0,  0,  0,  0,-10,
	-10,  0,  5, 10, 10,  5,  0,-10,
	-10,  5,  5, 10, 10,  5,  5,-10,
	-10,  0, 10, 10, 10, 10,  0,-10,
	-10, 10, 10, 10, 10, 10, 10,-10,
	-10,  5,  0,  0,  0,  0,  5,-10,
	-20,-10,-10,-10,-10,-10,-10,-20
]

const ROOK_TABLE: Array[int] = [
	  0,  0,  0,  0,  0,  0,  0,  0,
	  5, 10, 10, 10, 10, 10, 10,  5,
	 -5,  0,  0,  0,  0,  0,  0, -5,
	 -5,  0,  0,  0,  0,  0,  0, -5,
	 -5,  0,  0,  0,  0,  0,  0, -5,
	 -5,  0,  0,  0,  0,  0,  0, -5,
	 -5,  0,  0,  0,  0,  0,  0, -5,
	  0,  0,  0,  5,  5,  0,  0,  0
]

const QUEEN_TABLE: Array[int] = [
	-20,-10,-10, -5, -5,-10,-10,-20,
	-10,  0,  0,  0,  0,  0,  0,-10,
	-10,  0,  5,  5,  5,  5,  0,-10,
	 -5,  0,  5,  5,  5,  5,  0, -5,
	  0,  0,  5,  5,  5,  5,  0, -5,
	-10,  5,  5,  5,  5,  5,  0,-10,
	-10,  0,  5,  0,  0,  0,  0,-10,
	-20,-10,-10, -5, -5,-10,-10,-20
]

const KING_TABLE: Array[int] = [
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-20,-30,-30,-40,-40,-30,-30,-20,
	-10,-20,-20,-20,-20,-20,-20,-10,
	 20, 20,  0,  0,  0,  0, 20, 20,
	 20, 30, 10,  0,  0, 10, 30, 20
]

func get_best_move_gdscript(rules: ChessRules, difficulty: int) -> Dictionary:
	var is_bot_white = rules.white_to_move
	var legal_moves = rules.get_all_legal_moves(is_bot_white)
	if legal_moves.is_empty():
		return {}

	# Nivel 1: Aleatorio / Capturas simples
	if difficulty == 1:
		var captures: Array[Dictionary] = []
		for m in legal_moves:
			if rules.get_piece_at(m["to"]) != "":
				captures.append(m)
		if not captures.is_empty() and randf() < 0.40:
			captures.shuffle()
			return captures[0]
		legal_moves.shuffle()
		return legal_moves[0]

	# Nivel 2: Minimax profundidad 2
	if difficulty == 2:
		_order_moves(rules, legal_moves)
		var best_s = -999999
		var best_c: Array[Dictionary] = []
		for m in legal_moves:
			var clone_r = rules.clone()
			clone_r.make_move(m["from"], m["to"])
			var score = minimax(clone_r, 1, -999999, 999999, false, is_bot_white)
			score += randi_range(-20, 20)
			if score > best_s:
				best_s = score
				best_c = [m]
			elif score == best_s:
				best_c.append(m)
		if not best_c.is_empty():
			best_c.shuffle()
			return best_c[0]
		return legal_moves[0]

	# Nivel 3, 4, 5: Minimax Alfa-Beta profundidad 3 con tablas posicionales
	_order_moves(rules, legal_moves)
	var best_score = -999999
	var best_candidates: Array[Dictionary] = []

	for m in legal_moves:
		var clone_r = rules.clone()
		clone_r.make_move(m["from"], m["to"])
		var score = minimax(clone_r, 2, -999999, 999999, false, is_bot_white)
		if score > best_score:
			best_score = score
			best_candidates = [m]
		elif score == best_score:
			best_candidates.append(m)

	if not best_candidates.is_empty():
		best_candidates.shuffle()
		return best_candidates[0]

	return legal_moves[0]

func minimax(rules: ChessRules, depth: int, alpha: int, beta: int, is_maximizing: bool, is_bot_white: bool) -> int:
	if rules.halfmove_clock >= 100 or rules.is_threefold_repetition() or rules._is_insufficient_material():
		return 0

	if depth == 0:
		return _evaluate_static_board(rules, is_bot_white)

	var moves = rules.get_all_legal_moves(rules.white_to_move)
	if moves.is_empty():
		if rules.is_in_check(rules.white_to_move):
			var mate_score = 100000 + depth * 100
			return -mate_score if (rules.white_to_move == is_bot_white) else mate_score
		return 0

	_order_moves(rules, moves)

	if is_maximizing:
		var max_eval = -999999
		for m in moves:
			var rules_copy = rules.clone()
			rules_copy.make_move(m["from"], m["to"])
			var eval = minimax(rules_copy, depth - 1, alpha, beta, false, is_bot_white)
			max_eval = maxi(max_eval, eval)
			alpha = maxi(alpha, eval)
			if beta <= alpha:
				break
		return max_eval
	else:
		var min_eval = 999999
		for m in moves:
			var rules_copy = rules.clone()
			rules_copy.make_move(m["from"], m["to"])
			var eval = minimax(rules_copy, depth - 1, alpha, beta, true, is_bot_white)
			min_eval = mini(min_eval, eval)
			beta = mini(beta, eval)
			if beta <= alpha:
				break
		return min_eval

func evaluate_position(rules: ChessRules, is_bot_white: bool) -> int:
	var state = rules.get_game_state()
	if state == "checkmate":
		if rules.white_to_move == is_bot_white:
			return -100000
		else:
			return 100000
	if state == "stalemate" or state.begins_with("draw"):
		return 0

	return _evaluate_static_board(rules, is_bot_white)

func _evaluate_static_board(rules: ChessRules, is_bot_white: bool) -> int:
	var white_score = 0
	var black_score = 0

	for y in range(8):
		for x in range(8):
			var p = rules.get_piece_at(Vector2i(x, y))
			if p == "":
				continue
			var is_white = ChessRules.is_white_piece(p)
			var type = p.to_lower()
			var val = ChessRules.PIECE_VALUES.get(type, 0)
			var pst = _get_pst_value(type, x, y, is_white)

			var total = val + pst
			if is_white:
				white_score += total
			else:
				black_score += total

	return (white_score - black_score) if is_bot_white else (black_score - white_score)

func _get_pst_value(type: String, x: int, y: int, is_white: bool) -> int:
	var idx = ((7 - y) * 8 + x) if is_white else (y * 8 + x)
	match type:
		"p": return PAWN_TABLE[idx]
		"n": return KNIGHT_TABLE[idx]
		"b": return BISHOP_TABLE[idx]
		"r": return ROOK_TABLE[idx]
		"q": return QUEEN_TABLE[idx]
		"k": return KING_TABLE[idx]
	return 0

func _order_moves(rules: ChessRules, moves: Array[Dictionary]) -> void:
	moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var target_a = rules.get_piece_at(a["to"])
		var target_b = rules.get_piece_at(b["to"])
		var score_a = ChessRules.PIECE_VALUES.get(target_a.to_lower(), 0) if target_a != "" else 0
		var score_b = ChessRules.PIECE_VALUES.get(target_b.to_lower(), 0) if target_b != "" else 0

		# Priorizar enroque para seguridad del rey
		var piece_a = rules.get_piece_at(a["from"]).to_lower()
		var piece_b = rules.get_piece_at(b["from"]).to_lower()
		if piece_a == "k" and absi(a["to"].x - a["from"].x) == 2:
			score_a += 45
		if piece_b == "k" and absi(b["to"].x - b["from"].x) == 2:
			score_b += 45

		return score_a > score_b
	)
