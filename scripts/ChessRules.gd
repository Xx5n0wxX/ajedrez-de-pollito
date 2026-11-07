class_name ChessRules
extends RefCounted

## Motor lógico estricto de ajedrez completo (FIDE compliant)
## Maneja el estado del tablero, generación de movimientos legales,
## enroques, en passant, coronaciones, clavadas y estados de fin de partida.

const FILES: Array[String] = ["a", "b", "c", "d", "e", "f", "g", "h"]
const RANKS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8"]
const STARTING_FEN: String = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

# Tablero 8x8 representado como arreglo plano de 64 casillas
# Índice = y * 8 + x (donde x = 0..7 es a..h, y = 0..7 es fila 1..8)
var board: Array[String] = []

var white_to_move: bool = true
var castling_rights: Dictionary = {
	"K": true, # Blancas flanco de rey
	"Q": true, # Blancas flanco de dama
	"k": true, # Negras flanco de rey
	"q": true  # Negras flanco de dama
}
var en_passant_target: Vector2i = Vector2i(-1, -1)
var halfmove_clock: int = 0
var fullmove_number: int = 1
var history: Array = []
var history_notation: Array[String] = []
var record_history: bool = true
var position_counts: Dictionary = {}

func _init() -> void:
	board.resize(64)
	reset()

func reset() -> void:
	history.clear()
	history_notation.clear()
	position_counts.clear()
	set_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")

func save_state() -> void:
	if not record_history:
		return
	history.append({
		"board": board.duplicate(true),
		"white_to_move": white_to_move,
		"castling_rights": castling_rights.duplicate(true),
		"en_passant_target": en_passant_target,
		"halfmove_clock": halfmove_clock,
		"fullmove_number": fullmove_number
	})

func undo_turn() -> bool:
	if history.is_empty():
		return false
	if record_history:
		var cur_key = get_position_key()
		if position_counts.has(cur_key):
			var cnt = int(position_counts[cur_key]) - 1
			if cnt <= 0:
				position_counts.erase(cur_key)
			else:
				position_counts[cur_key] = cnt
	var state: Dictionary = history.pop_back()
	board.clear()
	for p in state["board"]:
		board.append(str(p))
	white_to_move = state["white_to_move"]
	castling_rights = (state["castling_rights"] as Dictionary).duplicate(true)
	en_passant_target = state["en_passant_target"]
	halfmove_clock = state["halfmove_clock"]
	fullmove_number = state["fullmove_number"]
	if not history_notation.is_empty():
		history_notation.pop_back()
	return true

# -------------------------------------------------------------
# CONVERSIÓN DE COORDENADAS Y FEN
# -------------------------------------------------------------
static func sq_to_vec(sq: String) -> Vector2i:
	if sq.length() != 2:
		return Vector2i(-1, -1)
	var f = sq.unicode_at(0) - "a".unicode_at(0)
	var r = sq.unicode_at(1) - "1".unicode_at(0)
	var v = Vector2i(f, r)
	return v if is_on_board(v) else Vector2i(-1, -1)

static func vec_to_sq(v: Vector2i) -> String:
	if not is_on_board(v):
		return ""
	var f_char = char("a".unicode_at(0) + v.x)
	var r_char = char("1".unicode_at(0) + v.y)
	return f_char + r_char

static func is_on_board(v: Vector2i) -> bool:
	return v.x >= 0 and v.x < 8 and v.y >= 0 and v.y < 8

func get_piece_at(v: Vector2i) -> String:
	if not is_on_board(v):
		return ""
	return board[v.y * 8 + v.x]

func set_piece_at(v: Vector2i, piece: String) -> void:
	if is_on_board(v):
		board[v.y * 8 + v.x] = piece

func get_piece_at_sq(sq: String) -> String:
	return get_piece_at(sq_to_vec(sq))

static func is_white_piece(p: String) -> bool:
	return p != "" and p == p.to_upper()

static func is_black_piece(p: String) -> bool:
	return p != "" and p == p.to_lower()

func set_fen(fen: String) -> void:
	for i in range(64):
		board[i] = ""

	var parts = fen.strip_edges().split(" ")
	if parts.is_empty():
		return

	# 1. Posición de piezas
	var rows = parts[0].split("/")
	for r_idx in range(mini(8, rows.size())):
		var row_str = rows[r_idx]
		var y = 7 - r_idx # FEN fila 0 es rank 8 (y=7)
		var x = 0
		for c in row_str:
			if c.is_valid_int():
				x += c.to_int()
			else:
				if x < 8:
					set_piece_at(Vector2i(x, y), c)
					x += 1

	# 2. Turno
	if parts.size() > 1:
		white_to_move = (parts[1] == "w")
	else:
		white_to_move = true

	# 3. Derechos de enroque
	castling_rights = {"K": false, "Q": false, "k": false, "q": false}
	if parts.size() > 2 and parts[2] != "-":
		for c in parts[2]:
			if castling_rights.has(c):
				castling_rights[c] = true

	# 4. En Passant
	en_passant_target = Vector2i(-1, -1)
	if parts.size() > 3 and parts[3] != "-":
		en_passant_target = sq_to_vec(parts[3])

	# 5. Halfmove clock & Fullmove number
	if parts.size() > 4:
		halfmove_clock = parts[4].to_int()
	else:
		halfmove_clock = 0

	if parts.size() > 5:
		fullmove_number = parts[5].to_int()
	else:
		fullmove_number = 1

	position_counts.clear()
	if record_history:
		var pos_key = get_position_key()
		position_counts[pos_key] = 1

func get_position_key() -> String:
	var fen_parts = to_fen().split(" ")
	if fen_parts.size() >= 4:
		return "%s %s %s %s" % [fen_parts[0], fen_parts[1], fen_parts[2], fen_parts[3]]
	return to_fen()

func is_threefold_repetition() -> bool:
	return int(position_counts.get(get_position_key(), 0)) >= 3

func to_fen() -> String:
	var fen_str = ""
	for r_idx in range(8):
		var y = 7 - r_idx
		var empty_count = 0
		for x in range(8):
			var p = get_piece_at(Vector2i(x, y))
			if p == "":
				empty_count += 1
			else:
				if empty_count > 0:
					fen_str += str(empty_count)
					empty_count = 0
				fen_str += p
		if empty_count > 0:
			fen_str += str(empty_count)
		if r_idx < 7:
			fen_str += "/"

	fen_str += " " + ("w" if white_to_move else "b")

	var castle_str = ""
	if castling_rights.get("K", false): castle_str += "K"
	if castling_rights.get("Q", false): castle_str += "Q"
	if castling_rights.get("k", false): castle_str += "k"
	if castling_rights.get("q", false): castle_str += "q"
	if castle_str == "": castle_str = "-"
	fen_str += " " + castle_str

	if en_passant_target != Vector2i(-1, -1):
		fen_str += " " + vec_to_sq(en_passant_target)
	else:
		fen_str += " -"

	fen_str += " %d %d" % [halfmove_clock, fullmove_number]
	return fen_str

func clone() -> ChessRules:
	var copy = ChessRules.new()
	copy.record_history = false
	copy.board = board.duplicate()
	copy.white_to_move = white_to_move
	copy.castling_rights = castling_rights.duplicate()
	copy.en_passant_target = en_passant_target
	copy.halfmove_clock = halfmove_clock
	copy.fullmove_number = fullmove_number
	copy.position_counts = position_counts.duplicate()
	return copy

# -------------------------------------------------------------
# DETECCIÓN DE AMENAZAS Y JAQUES
# -------------------------------------------------------------
func find_king(is_white: bool) -> Vector2i:
	var king_char = "K" if is_white else "k"
	for y in range(8):
		for x in range(8):
			if get_piece_at(Vector2i(x, y)) == king_char:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func is_in_check(is_white: bool) -> bool:
	var king_pos = find_king(is_white)
	if king_pos == Vector2i(-1, -1):
		return false
	return is_square_attacked(king_pos, not is_white)

func is_square_attacked(sq: Vector2i, attacked_by_white: bool) -> bool:
	if not is_on_board(sq):
		return false

	# 1. Peones atacantes
	var pawn_char = "P" if attacked_by_white else "p"
	var pawn_dy = -1 if attacked_by_white else 1 # Peón blanco ataca hacia arriba, viene desde y - 1
	for dx in [-1, 1]:
		var p_sq = Vector2i(sq.x + dx, sq.y + pawn_dy)
		if is_on_board(p_sq) and get_piece_at(p_sq) == pawn_char:
			return true

	# 2. Caballos atacantes
	var knight_char = "N" if attacked_by_white else "n"
	var knight_offsets = [
		Vector2i(1, 2), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(-2, 1),
		Vector2i(1, -2), Vector2i(2, -1), Vector2i(-1, -2), Vector2i(-2, -1)
	]
	for d in knight_offsets:
		var n_sq = sq + d
		if is_on_board(n_sq) and get_piece_at(n_sq) == knight_char:
			return true

	# 3. Rey atacante (adyacente)
	var king_char = "K" if attacked_by_white else "k"
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var k_sq = sq + Vector2i(dx, dy)
			if is_on_board(k_sq) and get_piece_at(k_sq) == king_char:
				return true

	# 4. Rayos ortogonales (Torres y Damas)
	var rook_char = "R" if attacked_by_white else "r"
	var queen_char = "Q" if attacked_by_white else "q"
	var ortho_dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for dir in ortho_dirs:
		var step = 1
		while true:
			var target = sq + (dir * step)
			if not is_on_board(target):
				break
			var p = get_piece_at(target)
			if p != "":
				if p == rook_char or p == queen_char:
					return true
				break
			step += 1

	# 5. Rayos diagonales (Alfiles y Damas)
	var bishop_char = "B" if attacked_by_white else "b"
	var diag_dirs = [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
	for dir in diag_dirs:
		var step = 1
		while true:
			var target = sq + (dir * step)
			if not is_on_board(target):
				break
			var p = get_piece_at(target)
			if p != "":
				if p == bishop_char or p == queen_char:
					return true
				break
			step += 1

	return false

## Retorna las coordenadas de todas las piezas enemigas que están atacando directamente al Rey indicado
func get_checking_pieces(king_is_white: bool) -> Array[Vector2i]:
	var attackers: Array[Vector2i] = []
	var k_pos = find_king(king_is_white)
	if k_pos == Vector2i(-1, -1):
		return attackers

	var enemy_is_white = not king_is_white

	# 1. Peones atacantes
	var pawn_char = "P" if enemy_is_white else "p"
	var pawn_dy = -1 if enemy_is_white else 1
	for dx in [-1, 1]:
		var p_sq = Vector2i(k_pos.x + dx, k_pos.y + pawn_dy)
		if is_on_board(p_sq) and get_piece_at(p_sq) == pawn_char:
			attackers.append(p_sq)

	# 2. Caballos atacantes
	var knight_char = "N" if enemy_is_white else "n"
	var knight_offsets = [
		Vector2i(1, 2), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(-2, 1),
		Vector2i(1, -2), Vector2i(2, -1), Vector2i(-1, -2), Vector2i(-2, -1)
	]
	for d in knight_offsets:
		var n_sq = k_pos + d
		if is_on_board(n_sq) and get_piece_at(n_sq) == knight_char:
			attackers.append(n_sq)

	# 3. Rayos lineales (Torres y Damas)
	var rook_char = "R" if enemy_is_white else "r"
	var queen_char = "Q" if enemy_is_white else "q"
	var straight_dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for dir in straight_dirs:
		var step = 1
		while true:
			var target = k_pos + (dir * step)
			if not is_on_board(target):
				break
			var p = get_piece_at(target)
			if p != "":
				if p == rook_char or p == queen_char:
					attackers.append(target)
				break
			step += 1

	# 4. Rayos diagonales (Alfiles y Damas)
	var bishop_char = "B" if enemy_is_white else "b"
	var diag_dirs = [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
	for dir in diag_dirs:
		var step = 1
		while true:
			var target = k_pos + (dir * step)
			if not is_on_board(target):
				break
			var p = get_piece_at(target)
			if p != "":
				if p == bishop_char or p == queen_char:
					attackers.append(target)
				break
			step += 1

	return attackers

# -------------------------------------------------------------
# GENERACIÓN DE MOVIMIENTOS PSEUDO-LEGALES
# -------------------------------------------------------------
func get_pseudo_legal_moves(from_pos: Vector2i) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	if not is_on_board(from_pos):
		return moves

	var piece = get_piece_at(from_pos)
	if piece == "":
		return moves

	var is_white = is_white_piece(piece)
	var type = piece.to_lower()

	match type:
		"p":
			var dy = 1 if is_white else -1
			var start_rank = 1 if is_white else 6

			# Avance 1 casilla
			var fwd = Vector2i(from_pos.x, from_pos.y + dy)
			if is_on_board(fwd) and get_piece_at(fwd) == "":
				moves.append(fwd)
				# Avance doble desde fila inicial
				if from_pos.y == start_rank:
					var fwd2 = Vector2i(from_pos.x, from_pos.y + (dy * 2))
					if is_on_board(fwd2) and get_piece_at(fwd2) == "":
						moves.append(fwd2)

			# Capturas diagonales (y En Passant)
			for dx in [-1, 1]:
				var cap_sq = Vector2i(from_pos.x + dx, from_pos.y + dy)
				if is_on_board(cap_sq):
					var target_p = get_piece_at(cap_sq)
					if target_p != "":
						if is_white != is_white_piece(target_p):
							moves.append(cap_sq)
					elif cap_sq == en_passant_target:
						moves.append(cap_sq)

		"n":
			var offsets = [
				Vector2i(1, 2), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(-2, 1),
				Vector2i(1, -2), Vector2i(2, -1), Vector2i(-1, -2), Vector2i(-2, -1)
			]
			for off in offsets:
				var target = from_pos + off
				if is_on_board(target):
					var target_p = get_piece_at(target)
					if target_p == "" or is_white != is_white_piece(target_p):
						moves.append(target)

		"b":
			_add_sliding_moves(from_pos, is_white, [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)], moves)

		"r":
			_add_sliding_moves(from_pos, is_white, [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)], moves)

		"q":
			_add_sliding_moves(from_pos, is_white, [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
			], moves)

		"k":
			# Pasos individuales del Rey
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if dx == 0 and dy == 0:
						continue
					var target = from_pos + Vector2i(dx, dy)
					if is_on_board(target):
						var target_p = get_piece_at(target)
						if target_p == "" or is_white != is_white_piece(target_p):
							moves.append(target)

			# Enroques
			_add_castling_moves(from_pos, is_white, moves)

	return moves

func _add_sliding_moves(from_pos: Vector2i, is_white: bool, dirs: Array[Vector2i], out_moves: Array[Vector2i]) -> void:
	for dir in dirs:
		var step = 1
		while true:
			var target = from_pos + (dir * step)
			if not is_on_board(target):
				break
			var target_p = get_piece_at(target)
			if target_p == "":
				out_moves.append(target)
			else:
				if is_white != is_white_piece(target_p):
					out_moves.append(target)
				break
			step += 1

func _add_castling_moves(king_pos: Vector2i, is_white: bool, out_moves: Array[Vector2i]) -> void:
	var rank = 0 if is_white else 7
	if king_pos != Vector2i(4, rank):
		return

	# No se puede enrocar si el Rey está actualmente en jaque
	if is_in_check(is_white):
		return

	var enemy_is_white = not is_white
	var k_key = "K" if is_white else "k"
	var q_key = "Q" if is_white else "q"

	# 1. Enroque Corto (Flanco de Rey: e1 -> g1 / e8 -> g8)
	if castling_rights.get(k_key, false):
		var r_pos = Vector2i(7, rank)
		var expected_rook = "R" if is_white else "r"
		if get_piece_at(r_pos) == expected_rook:
			# Casillas intermedias libres: f y g
			if get_piece_at(Vector2i(5, rank)) == "" and get_piece_at(Vector2i(6, rank)) == "":
				# Ni f ni g pueden estar atacadas
				if not is_square_attacked(Vector2i(5, rank), enemy_is_white) and not is_square_attacked(Vector2i(6, rank), enemy_is_white):
					out_moves.append(Vector2i(6, rank))

	# 2. Enroque Largo (Flanco de Dama: e1 -> c1 / e8 -> c8)
	if castling_rights.get(q_key, false):
		var r_pos = Vector2i(0, rank)
		var expected_rook = "R" if is_white else "r"
		if get_piece_at(r_pos) == expected_rook:
			# Casillas intermedias libres: b, c y d
			if get_piece_at(Vector2i(1, rank)) == "" and get_piece_at(Vector2i(2, rank)) == "" and get_piece_at(Vector2i(3, rank)) == "":
				# Ni d ni c pueden estar atacadas (b puede estar atacada según FIDE)
				if not is_square_attacked(Vector2i(3, rank), enemy_is_white) and not is_square_attacked(Vector2i(2, rank), enemy_is_white):
					out_moves.append(Vector2i(2, rank))

# -------------------------------------------------------------
# MOVIMIENTOS LEGALES (FILTRO ESTRICTO CONTRA CLAVADAS Y JAQUES)
# -------------------------------------------------------------
func get_legal_moves(from_pos: Vector2i) -> Array[Vector2i]:
	var pseudo_moves = get_pseudo_legal_moves(from_pos)
	var legal_moves: Array[Vector2i] = []
	var piece = get_piece_at(from_pos)
	if piece == "":
		return legal_moves

	var mover_is_white = is_white_piece(piece)

	for target in pseudo_moves:
		if is_move_legal(from_pos, target, mover_is_white):
			legal_moves.append(target)

	return legal_moves

func is_move_legal(from_pos: Vector2i, to_pos: Vector2i, mover_is_white: bool) -> bool:
	# Simular movimiento in-place de forma ultrarrápida
	var p_from = get_piece_at(from_pos)
	var p_to = get_piece_at(to_pos)
	var is_ep = (p_from.to_lower() == "p" and to_pos == en_passant_target)
	var ep_captured_sq = Vector2i(to_pos.x, from_pos.y) if is_ep else Vector2i(-1, -1)
	var ep_captured_p = get_piece_at(ep_captured_sq) if is_ep else ""

	# Aplicar cambio
	set_piece_at(to_pos, p_from)
	set_piece_at(from_pos, "")
	if is_ep:
		set_piece_at(ep_captured_sq, "")

	# Comprobar si el propio rey queda amenazado
	var in_check = is_in_check(mover_is_white)

	# Revertir cambio
	set_piece_at(from_pos, p_from)
	set_piece_at(to_pos, p_to)
	if is_ep:
		set_piece_at(ep_captured_sq, ep_captured_p)

	return not in_check

func get_all_legal_moves(for_white: bool) -> Array[Dictionary]:
	var all_moves: Array[Dictionary] = []
	for y in range(8):
		for x in range(8):
			var pos = Vector2i(x, y)
			var p = get_piece_at(pos)
			if p != "" and is_white_piece(p) == for_white:
				var legals = get_legal_moves(pos)
				for dest in legals:
					all_moves.append({"from": pos, "to": dest})
	return all_moves

# -------------------------------------------------------------
# EJECUCIÓN FORMAL DE MOVIMIENTO
# -------------------------------------------------------------
func make_move(from_pos: Vector2i, to_pos: Vector2i, promo: String = "q") -> Dictionary:
	save_state()
	var piece = get_piece_at(from_pos)
	var target_p = get_piece_at(to_pos)
	var is_white = is_white_piece(piece)
	var type = piece.to_lower()

	var is_capture = (target_p != "")
	var captured_p = target_p
	var is_ep = false
	var ep_captured_pos = Vector2i(-1, -1)
	var is_castle = false
	var rook_from = Vector2i(-1, -1)
	var rook_to = Vector2i(-1, -1)
	var is_promo = false
	var promo_piece = ""

	# 1. En Passant
	if type == "p" and to_pos == en_passant_target:
		is_ep = true
		ep_captured_pos = Vector2i(to_pos.x, from_pos.y)
		captured_p = get_piece_at(ep_captured_pos)
		set_piece_at(ep_captured_pos, "")
		is_capture = true

	# 2. Enroque
	if type == "k" and absi(to_pos.x - from_pos.x) == 2:
		is_castle = true
		var rank = from_pos.y
		if to_pos.x == 6: # Corto
			rook_from = Vector2i(7, rank)
			rook_to = Vector2i(5, rank)
		elif to_pos.x == 2: # Largo
			rook_from = Vector2i(0, rank)
			rook_to = Vector2i(3, rank)
		var rook = get_piece_at(rook_from)
		set_piece_at(rook_to, rook)
		set_piece_at(rook_from, "")

	# 3. Coronación
	if type == "p":
		if (is_white and to_pos.y == 7) or (not is_white and to_pos.y == 0):
			is_promo = true
			var pr = promo.to_upper() if is_white else promo.to_lower()
			promo_piece = pr
			piece = pr

	# Mover pieza
	set_piece_at(to_pos, piece)
	set_piece_at(from_pos, "")

	# 4. Actualizar casilla En Passant
	if type == "p" and absi(to_pos.y - from_pos.y) == 2:
		en_passant_target = Vector2i(from_pos.x, int(float(from_pos.y + to_pos.y) / 2.0))
	else:
		en_passant_target = Vector2i(-1, -1)

	# 5. Actualizar derechos de enroque
	if type == "k":
		if is_white:
			castling_rights["K"] = false
			castling_rights["Q"] = false
		else:
			castling_rights["k"] = false
			castling_rights["q"] = false
	elif type == "r":
		if from_pos == Vector2i(0, 0): castling_rights["Q"] = false
		elif from_pos == Vector2i(7, 0): castling_rights["K"] = false
		elif from_pos == Vector2i(0, 7): castling_rights["q"] = false
		elif from_pos == Vector2i(7, 7): castling_rights["k"] = false

	# Si una torre es capturada en su esquina original
	if to_pos == Vector2i(0, 0): castling_rights["Q"] = false
	elif to_pos == Vector2i(7, 0): castling_rights["K"] = false
	elif to_pos == Vector2i(0, 7): castling_rights["q"] = false
	elif to_pos == Vector2i(7, 7): castling_rights["k"] = false

	# 6. Reloj de 50 movimientos
	if type == "p" or is_capture:
		halfmove_clock = 0
	else:
		halfmove_clock += 1

	if not is_white:
		fullmove_number += 1

	# Cambiar turno
	white_to_move = not white_to_move

	if record_history:
		var pos_key = get_position_key()
		position_counts[pos_key] = int(position_counts.get(pos_key, 0)) + 1

	return {
		"from": from_pos,
		"to": to_pos,
		"piece": piece,
		"is_white": is_white,
		"is_capture": is_capture,
		"captured_piece": captured_p,
		"is_en_passant": is_ep,
		"en_passant_captured_pos": ep_captured_pos,
		"is_castling": is_castle,
		"castling_rook_from": rook_from,
		"castling_rook_to": rook_to,
		"is_promotion": is_promo,
		"promotion_piece": promo_piece
	}

# -------------------------------------------------------------
# EVALUACIÓN DE ESTADO DE PARTIDA
# -------------------------------------------------------------
func get_game_state() -> String:
	var legal_moves = get_all_legal_moves(white_to_move)

	if legal_moves.is_empty():
		if is_in_check(white_to_move):
			return "checkmate"
		else:
			return "stalemate"

	if halfmove_clock >= 100:
		return "draw_50_moves"

	if is_threefold_repetition():
		return "draw_repetition"

	if _is_insufficient_material():
		return "draw_insufficient_material"

	if is_in_check(white_to_move):
		return "check"

	return "playing"

func _is_insufficient_material() -> bool:
	var white_pieces: Array[String] = []
	var black_pieces: Array[String] = []
	var white_bishop_color: int = -1
	var black_bishop_color: int = -1

	for y in range(8):
		for x in range(8):
			var p = get_piece_at(Vector2i(x, y))
			if p == "" or p.to_lower() == "k":
				continue
			if is_white_piece(p):
				white_pieces.append(p)
				if p == "B":
					white_bishop_color = (x + y) % 2
			else:
				black_pieces.append(p)
				if p == "b":
					black_bishop_color = (x + y) % 2

	# Solo Reyes (K vs k)
	if white_pieces.is_empty() and black_pieces.is_empty():
		return true

	# K+B vs K o K+N vs K
	if (white_pieces.size() == 1 and black_pieces.is_empty() and (white_pieces[0] == "B" or white_pieces[0] == "N")):
		return true
	if (black_pieces.size() == 1 and white_pieces.is_empty() and (black_pieces[0] == "b" or black_pieces[0] == "n")):
		return true

	# K+B vs K+B con alfiles en casillas del mismo color (FIDE)
	if white_pieces.size() == 1 and black_pieces.size() == 1 and white_pieces[0] == "B" and black_pieces[0] == "b":
		if white_bishop_color == black_bishop_color:
			return true

	return false

# -------------------------------------------------------------
# EVALUACIÓN MATERIAL RÁPIDA (ÚTIL PARA BOTS Y UI)
# -------------------------------------------------------------
const PIECE_VALUES: Dictionary = {
	"p": 100,
	"n": 320,
	"b": 330,
	"r": 500,
	"q": 900,
	"k": 20000
}

func evaluate_material_balance() -> int:
	var score = 0
	for y in range(8):
		for x in range(8):
			var p = get_piece_at(Vector2i(x, y))
			if p != "":
				var val = PIECE_VALUES.get(p.to_lower(), 0)
				if is_white_piece(p):
					score += val
				else:
					score -= val
	return score
