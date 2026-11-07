class_name ChessSparringEngine
extends RefCounted

const ChessTutorConcepts = preload("res://scripts/ChessTutorConcepts.gd")

## Motor de Sparring Pedagógico para Nivel 1 (🐣 Principiante)
## Diseñado para que Pollito actúe como un verdadero profesor/sparring humano:
## 1. No regala piezas de forma absurda ni juega aleatoriamente.
## 2. Juega las respuestas canónicas de las aperturas del manual.
## 3. Plantea obstáculos típicos de partida (clavadas, amenazas al centro, murallas, etc.).
## 4. En el turno del jugador, explica el problema y la técnica de manual para superarlo.
## 5. Permite contraatacar y rematar con técnica (Mates canónicos y finales limpios).

# ==============================================================================
# 1. REPERTORIO DE APERTURAS Y DEFENSAS DE MANUAL (9 SISTEMAS COMPLETOS)
# ==============================================================================
const OPENING_SYSTEMS: Dictionary = {
	"italiana": {
		"id": "italiana",
		"name": "Apertura Italiana (Giuoco Piano)",
		"desc": "Lucha clásica por las casillas centrales y el punto débil f7.",
		"white_plan": "Dominar el centro con peón y apuntar con el Alfil a f7 antes de enrocar.",
		# Secuencia: par de jugadas [blancas, negras]
		"book": [
			{"w": "e2e4", "b": "e7e5", "b_why": "Respondo en el centro para no cederte espacio.", "w_tip": "Avanza tu peón a [b]E4[/b] para abrir paso a tu Dama y Alfil."},
			{"w": "g1f3", "b": "b8c6", "b_why": "Desarrollo mi Caballo a c6 defendiendo mi peón de e5.", "w_tip": "Desarrolla tu Caballo a [b]F3[/b] atacando mi peón central."},
			{"w": "f1c4", "b": "f8c5", "b_why": "Activo mi Alfil a c5 en simetría con el tuyo.", "w_tip": "¡La jugada estrella! Coloca tu Alfil en [b]C4[/b] apuntando al punto débil F7."},
			{"w": "e1g1", "b": "g8f6", "b_why": "Desarrollo mi Caballo a f6 presionando tu peón e4.", "w_tip": "¡Asegura a tu Rey en su castillo! Haz el [b]Enroque Corto[/b]."}
		]
	},
	"espanola": {
		"id": "espanola",
		"name": "Apertura Española (Ruy López)",
		"desc": "La apertura de los campeones mundiales. Presiona al defensor del centro.",
		"white_plan": "Presionar con el Alfil en b5 al caballo que custodia el centro.",
		"book": [
			{"w": "e2e4", "b": "e7e5", "b_why": "Ocupo el centro para equilibrar las fuerzas.", "w_tip": "Comienza con peón a [b]E4[/b] ganando presencia central."},
			{"w": "g1f3", "b": "b8c6", "b_why": "Protejo mi peón e5 con mi Caballo.", "w_tip": "Saca tu Caballo a [b]F3[/b] amenazando mi centro."},
			{"w": "f1b5", "b": "a7a6", "b_why": "¡Variante Morphy! Pregunto a tu Alfil qué quiere hacer con a6.", "w_tip": "¡Clave de la Española! Lleva tu Alfil a [b]B5[/b] presionando a mi caballo guardián."},
			{"w": "b5a4", "b": "g8f6", "b_why": "Desarrollo mi Caballo atacando tu peón central.", "w_tip": "Retira tu Alfil a [b]A4[/b]: mantienes la diagonal y la presión sin perder la pieza."}
		]
	},
	"cuatro_caballos": {
		"id": "cuatro_caballos",
		"name": "Apertura de los Cuatro Caballos",
		"desc": "Desarrollo armónico, seguro y simétrico de todas las piezas menores.",
		"white_plan": "Desarrollar ambos caballos y alfiles de forma sólida antes de atacar.",
		"book": [
			{"w": "e2e4", "b": "e7e5", "b_why": "Lucho por las casillas centrales.", "w_tip": "Peón a [b]E4[/b] para abrir camino a tus piezas."},
			{"w": "g1f3", "b": "b8c6", "b_why": "Defiendo mi peón con mi primer caballo.", "w_tip": "Caballo a [b]F3[/b] buscando actividad hacia el centro."},
			{"w": "b1c3", "b": "g8f6", "b_why": "Saco mi segundo caballo: los cuatro caballos ya están en juego.", "w_tip": "Saca tu segundo Caballo a [b]C3[/b] para un desarrollo armónico."},
			{"w": "f1b5", "b": "f8b4", "b_why": "Clavo tu caballo en c3 en perfecta simetría.", "w_tip": "Activa tu Alfil a [b]B5[/b] disputando casillas clave."}
		]
	},
	"escocesa": {
		"id": "escocesa",
		"name": "Apertura Escocesa",
		"desc": "Ruptura enérgica y rápida del centro en la jugada 3 con d4.",
		"white_plan": "Romper el centro de inmediato para abrir diagonales a ambos alfiles.",
		"book": [
			{"w": "e2e4", "b": "e7e5", "b_why": "Respuesta clásica de peón de rey.", "w_tip": "Peón a [b]E4[/b] tomando posición en el centro."},
			{"w": "g1f3", "b": "b8c6", "b_why": "Caballo a c6 defendiendo.", "w_tip": "Caballo a [b]F3[/b] atacando la posición en e5."},
			{"w": "d2d4", "b": "e5d4", "b_why": "Acepto el reto y capturo tu peón d4.", "w_tip": "¡La explosión de la Escocesa! Rompe con [b]D4[/b] para abrir el centro."},
			{"w": "f3d4", "b": "f8c5", "b_why": "Saco mi alfil a c5 atacando a tu caballo centralizado.", "w_tip": "Recaptura en [b]D4[/b] con tu Caballo dominante en el corazón del tablero."}
		]
	},
	"francesa": {
		"id": "francesa",
		"name": "Defensa Francesa (Centro Cerrado)",
		"desc": "El rival prepara d5 protegiéndose con e6. Enseña a quebrar centros cerrados.",
		"white_plan": "Ocupar todo el centro con e4 y d4, y luego atacar la cadena de peones.",
		"book": [
			{"w": "e2e4", "b": "e7e6", "b_why": "¡Defensa Francesa! Preparo d5 apoyado por mi peón e6.", "w_tip": "Peón a [b]E4[/b] para comenzar la partida."},
			{"w": "d2d4", "b": "d7d5", "b_why": "Desafío tu centro con d5.", "w_tip": "¡Aprovecha y aduéñate de todo el centro con [b]D4[/b]! Tienes dos peones centrales ideales."},
			{"w": "b1c3", "b": "g8f6", "b_why": "Aumento la presión sobre tu peón e4.", "w_tip": "Desarrolla tu Caballo a [b]C3[/b] para defender e4 con solidez."}
		]
	},
	"caro_kann": {
		"id": "caro_kann",
		"name": "Defensa Caro-Kann (Muralla de Peones)",
		"desc": "Una de las defensas más sólidas y resistentes del ajedrez.",
		"white_plan": "Controlar el centro con e4 y d4 y mantener actividad de piezas.",
		"book": [
			{"w": "e2e4", "b": "c7c6", "b_why": "¡Defensa Caro-Kann! Preparo d5 con estructura de roca.", "w_tip": "Peón a [b]E4[/b] abriendo diagonales."},
			{"w": "d2d4", "b": "d7d5", "b_why": "Lucho por el centro con d5.", "w_tip": "Coloca tu peón en [b]D4[/b]: ¡el control del centro es todo tuyo!"},
			{"w": "b1c3", "b": "d5e4", "b_why": "Capturo en e4 para cambiar peones.", "w_tip": "Caballo a [b]C3[/b] protegiendo tu posición."},
			{"w": "c3e4", "b": "c8f5", "b_why": "Activo mi Alfil a f5 atacando a tu caballo.", "w_tip": "Recaptura en [b]E4[/b] con tu Caballo centralizado."}
		]
	},
	"escandinava": {
		"id": "escandinava",
		"name": "Defensa Escandinava (Castigo a la Dama)",
		"desc": "El rival ataca tu peón en la jugada 1. Enseña a castigar la Dama que sale pronto.",
		"white_plan": "Capturar el peón d5 y desarrollar el caballo atacando a la Dama rival.",
		"book": [
			{"w": "e2e4", "b": "d7d5", "b_why": "¡Defensa Escandinava! Ataco tu peón de e4 de inmediato.", "w_tip": "Avanza tu peón a [b]E4[/b] al centro."},
			{"w": "e4d5", "b": "d8d5", "b_why": "Recapturo con mi Dama en d5.", "w_tip": "¡Captura el peón en [b]D5[/b]! No temas al intercambio en el centro."},
			{"w": "b1c3", "b": "d5a5", "b_why": "Retiro mi Dama a a5 para no perderla.", "w_tip": "¡Regla de oro de manual! Saca tu Caballo a [b]C3[/b]: te desarrollas atacando a mi Dama y ganando un tiempo gratis."}
		]
	},
	"siciliana": {
		"id": "siciliana",
		"name": "Defensa Siciliana Básica",
		"desc": "El rival usa un peón lateral para combatir tu centro. La defensa más combativa.",
		"white_plan": "Desarrollar piezas menores hacia el centro y abrir con d4.",
		"book": [
			{"w": "e2e4", "b": "c7c5", "b_why": "¡Defensa Siciliana! Uso mi peón c5 para luchar por el centro desde el flanco.", "w_tip": "Peón a [b]E4[/b] para dominar el centro."},
			{"w": "g1f3", "b": "b8c6", "b_why": "Desarrollo mi Caballo a c6.", "w_tip": "Desarrolla tu Caballo a [b]F3[/b] preparando la ruptura central d4."},
			{"w": "d2d4", "b": "c5d4", "b_why": "Cambio mi peón de c5 por tu peón central d4.", "w_tip": "Avanza con [b]D4[/b] para abrir el centro a tus alfiles."},
			{"w": "f3d4", "b": "g8f6", "b_why": "Presiono tu peón e4 con mi caballo f6.", "w_tip": "Recaptura en [b]D4[/b] con tu Caballo activo."}
		]
	},
	"gambito_dama": {
		"id": "gambito_dama",
		"name": "Gambito de Dama",
		"desc": "La gran apertura de peón de dama. Enseña a ofrecer un peón lateral para dominar el centro.",
		"white_plan": "Ofrecer el peón de c4 para dominar el centro absoluto con e4.",
		"book": [
			{"w": "d2d4", "b": "d7d5", "b_why": "Respondo firme en el centro con d5.", "w_tip": "Comienza con peón a [b]D4[/b] controlando el centro con seguridad."},
			{"w": "c2c4", "b": "e7e6", "b_why": "Rechazo el gambito y defiendo mi peón con e6.", "w_tip": "¡El famoso Gambito de Dama! Juega [b]C4[/b] para presionar mi peón central."},
			{"w": "b1c3", "b": "g8f6", "b_why": "Refuerzo mi centro con Caballo a f6.", "w_tip": "Desarrolla tu Caballo a [b]C3[/b] aumentando la presión central."},
			{"w": "c1g5", "b": "f8e7", "b_why": "Desclavo mi caballo con Alfil e7.", "w_tip": "¡Clavada activa! Lleva tu Alfil a [b]G5[/b] clavando a mi caballo guardián."}
		]
	}
}

# ==============================================================================
# 2. CATÁLOGO DE OBSTÁCULOS Y RETOS DE MEDIO JUEGO (12 RETOS DE MANUAL)
# ==============================================================================
const MIDGAME_CHALLENGES: Array[Dictionary] = [
	{
		"id": "clavada_alfil",
		"name": "🎯 La Clavada de Alfil",
		"desc": "Pollito clava una pieza blanca contra la Dama o Rey.",
		"lesson": "Cuando una pieza tuya está clavada, no puedes moverla sin perder algo valioso. Se resuelve de dos formas: 1. Poniendo un escudo con tu Alfil para desclavar, o 2. Haciendo una pregunta al Alfil rival con h3 o a3."
	},
	{
		"id": "amenaza_centro",
		"name": "🛡️ Amenaza Activa al Centro",
		"desc": "Pollito ataca un peón central no defendido.",
		"lesson": "¡Nunca te asustes ni retrocedas de forma pasiva! En ajedrez de manual, la mejor defensa es la defensa activa desarrollando otra pieza que proteja el punto amenazado."
	},
	{
		"id": "caballo_pulpo",
		"name": "🐙 El Caballo en Puesto Avanzado",
		"desc": "Pollito instala un Caballo peligroso en el corazón de tu campo.",
		"lesson": "Un Caballo rival centralizado controla 8 casillas y es muy molesto. La técnica de manual enseña: o lo expulsas empujando un peón, o lo cambias por una pieza propia equivalente para neutralizar su ventaja."
	},
	{
		"id": "bateria_dama_alfil",
		"name": "⚡ La Batería Apuntando al Rey",
		"desc": "Pollito alinea Dama y Alfil apuntando al enroque blanco.",
		"lesson": "¡Ojo clínico! No juegues en automático. Cuando veas Dama y Alfil en la misma diagonal mirando a tu Rey, refuerza tu fortaleza avanzando un peón como escudo (g3) o trayendo un caballo protector."
	},
	{
		"id": "columna_abierta",
		"name": "🛣️ Invasión de Columna Abierta",
		"desc": "Pollito ubica una Torre en una columna sin peones.",
		"lesson": "Las Torres aman las columnas abiertas. Si el rival toma una columna, la técnica es disputarla colocando tu propia Torre cara a cara o doblando torres para dominar la autopista."
	},
	{
		"id": "ruptura_peones",
		"name": "🧱 La Muralla de Peones (Ruptura)",
		"desc": "El centro está bloqueado por cadenas de peones.",
		"lesson": "Cuando las piezas chocan contra una muralla de peones, necesitas una 'ruptura': avanzar un peón lateral para demoler la cadena rival y abrir diagonales a tus alfiles."
	},
	{
		"id": "luft_preventivo",
		"name": "🌬️ El Respiradero del Rey (Luft)",
		"desc": "Peligro latente de invasión en la primera fila.",
		"lesson": "Regla de oro de seguridad: antes de lanzarte al ataque, avanza un pasito tu peón h3 o g3 para abrirle una 'ventanita' de escape a tu Rey y evitar sustos con el Mate del Pasillo."
	},
	{
		"id": "trampa_horquilla",
		"name": "⚔️ Oportunidad de Horquilla (Ataque Doble)",
		"desc": "Pollito deja calculadamente dos piezas en radio de salto de Caballo.",
		"lesson": "¡Ataque Doble! Busca la casilla clave donde tu Caballo pueda amenazar a dos piezas grandes rivales a la vez. ¡El oponente solo podrá salvar a una!"
	},
	{
		"id": "enfilada_skewer",
		"name": "🏹 Oportunidad de Enfilada (Skewer)",
		"desc": "Pollito alinea dos piezas en una diagonal o columna abierta.",
		"lesson": "En la enfilada, atacas a una pieza de mayor valor (como la Dama o Rey). Cuando esta se vea forzada a huir, ¡capturamos a la pieza que estaba escondida detrás!"
	},
	{
		"id": "eliminar_defensor",
		"name": "✂️ Eliminar al Defensor (Desviación)",
		"desc": "Pollito protege una pieza valiosa con otra menor.",
		"lesson": "Si una pieza rival está bien defendida por un caballo o alfil, la técnica de manual es capturar o desviar primero al defensor: así la pieza detrás queda totalmente indefensa."
	},
	{
		"id": "pieza_dormida",
		"name": "💤 Activar la Pieza Dormida",
		"desc": "Posición tranquila en medio juego.",
		"lesson": "Pregúntate siempre: ¿cuál de mis piezas está haciendo menos trabajo? Maniobra tu pieza menos activa hacia una casilla central para sumarla al combate."
	},
	{
		"id": "dama_prematura",
		"name": "👑 Castigo a la Dama Prematura",
		"desc": "Pollito saca su Dama antes de tiempo.",
		"lesson": "Si el rival saca su Dama antes de tiempo para intimidar, no te asustes: saca piezas menores atacándola. Cada vez que la Dama rival tenga que huir, ¡tú ganas un turno gratis de desarrollo!"
	}
]

# ==============================================================================
# 3. CATÁLOGO DE TÉCNICAS DE FINAL Y REMATE (5 TÉCNICAS CANÓNICAS)
# ==============================================================================
const ENDGAME_CHALLENGES: Array[Dictionary] = [
	{
		"id": "mate_pasillo",
		"name": "👑 Mate del Pasillo (Back-Rank Mate)",
		"lesson": "Cuando los propios peones del Rey le tapan las casillas de escape en su enroque, una sola Torre o Dama que invada la fila 8 da un jaque mate imparable."
	},
	{
		"id": "mate_beso",
		"name": "👑 Mate del Beso de la Muerte",
		"lesson": "Llevar la Dama cara a cara con el Rey enemigo en la banda, siempre respaldada por otra pieza (un Alfil, Caballo o tu propio Rey), no le deja ninguna salida."
	},
	{
		"id": "mate_escalera",
		"name": "🪜 Mate de la Escalera (Dos Torres o Dama + Torre)",
		"lesson": "Una pieza pesada corta una fila como una barrera, y la otra pieza avanza a la siguiente fila para dar jaque. Se van turnando fila por fila hasta arrinconar al Rey en la orilla."
	},
	{
		"id": "peon_pasado_coronacion",
		"name": "🌟 Conducción del Peón Pasado",
		"lesson": "Un peón pasado no tiene peones rivales que le bloqueen el paso. Usa a tu propio Rey como 'guardaespaldas' avanzando delante de él para abrirle paso hasta coronar una Dama."
	},
	{
		"id": "evitar_rey_ahogado",
		"name": "🤝 Alerta Roja: Evitar el Rey Ahogado",
		"lesson": "Cuando tienes ventaja abrumadora, ¡el mayor peligro son las tablas por ahogado! En cada jugada de final, verifica: ¿el Rey rival tiene al menos una casilla libre para mover si no está en jaque? ¡Siempre dale jaque o déjale un escape!"
	}
]

# ==============================================================================
# GESTIÓN DE LA SESIÓN DE SPARRING DIDÁCTICO
# ==============================================================================

## Crea una nueva sesión didáctica combinando una apertura, un reto de medio juego y un final
static func create_session() -> Dictionary:
	var opening_keys = OPENING_SYSTEMS.keys()
	opening_keys.shuffle()
	var chosen_op_key = opening_keys[0]

	var midgame_pool = MIDGAME_CHALLENGES.duplicate()
	midgame_pool.shuffle()
	var chosen_mid = midgame_pool[0]

	var endgame_pool = ENDGAME_CHALLENGES.duplicate()
	endgame_pool.shuffle()
	var chosen_end = endgame_pool[0]

	return {
		"opening_id": chosen_op_key,
		"opening": OPENING_SYSTEMS[chosen_op_key],
		"opening_ply": 0,
		"book_step_index": 0,
		"last_white_move": "",
		"opening_completed": false,
		"opening_deviated": false,
		"midgame": chosen_mid,
		"midgame_active": false,
		"midgame_presented": false,
		"midgame_solved": false,
		"endgame": chosen_end,
		"endgame_active": false,
		"last_sparring_event": "",
		"last_sparring_tip": ""
	}

## Obtiene la sugerencia de jugada para las Blancas en Nivel 1 (🐣 Principiante).
## Si la apertura canónica está activa y el jugador no se ha desviado, devuelve directamente
## el paso del libro canónico sin consultar al motor (garantiza coherencia pedagógica total).
## Si la apertura terminó o el jugador se desvió, consulta asíncronamente a Stockfish depth 4.
static func get_player_guidance_step(rules: ChessRules, session: Dictionary, bot: ChessBot, on_guidance_ready: Callable) -> void:
	if not rules:
		on_guidance_ready.call({})
		return

	var book_idx: int = int(session.get("book_step_index", 0))
	var op_data: Dictionary = session.get("opening", {})
	var book: Array = op_data.get("book", [])

	# 1. ¿Apertura canónica activa y pendiente?
	if not session.get("opening_completed", false) and book_idx >= 0 and book_idx < book.size():
		var step: Dictionary = book[book_idx]
		var expected_w: String = step.get("w", "")
		if expected_w.length() == 4:
			var from_sq: String = expected_w.substr(0, 2)
			var to_sq: String = expected_w.substr(2, 2)
			var from_v: Vector2i = ChessRules.sq_to_vec(from_sq)
			var to_v: Vector2i = ChessRules.sq_to_vec(to_sq)

			# Validar que la jugada canónica sea legal en la posición actual
			var legals: Array[Vector2i] = rules.get_legal_moves(from_v)
			if to_v in legals:
				var op_name: String = op_data.get("name", "Apertura")
				var coaching = {
					"tag": "📖 %s" % op_name,
					"l1": step.get("w_tip", ""),
					"why": "Siguiendo el plan clásico del manual para dominar el centro.",
					"from_sq": from_sq,
					"to_sq": to_sq,
					"move": {"from": from_v, "to": to_v, "promo": ""}
				}
				on_guidance_ready.call(coaching)
				return

	# Si no se pudo jugar el paso del libro, la fase de apertura se considera concluida o desviada
	session["opening_completed"] = true

	# 2. Consultar Stockfish depth 4 para la mejor jugada táctica del jugador
	bot.get_best_move_async(rules, 4, func(best_m: Dictionary):
		if best_m.is_empty():
			on_guidance_ready.call({})
			return
		var coaching = get_player_coaching(rules, session, best_m)
		coaching["from_sq"] = ChessRules.vec_to_sq(best_m["from"])
		coaching["to_sq"] = ChessRules.vec_to_sq(best_m["to"])
		coaching["move"] = best_m
		on_guidance_ready.call(coaching)
	)

## Determina la jugada que Pollito (Negras) debe hacer como sparring formativo
static func get_sparring_move(rules: ChessRules, session: Dictionary, fallback_bot: ChessBot, on_move_ready: Callable) -> void:
	if not rules or rules.white_to_move:
		on_move_ready.call({})
		return

	var legal_moves = rules.get_all_legal_moves(false)
	if legal_moves.is_empty():
		on_move_ready.call({})
		return

	var fullmove = rules.fullmove_number
	var op_data: Dictionary = session.get("opening", {})
	var book: Array = op_data.get("book", [])
	var book_idx: int = int(session.get("book_step_index", 0))

	# --------------------------------------------------------------------------
	# FASE 1: APERTURA DIDÁCTICA CANÓNICA (Turnos 1 a 4)
	# --------------------------------------------------------------------------
	if not session.get("opening_completed", false) and book_idx >= 0 and book_idx < book.size():
		var step: Dictionary = book[book_idx]
		var expected_w: String = step.get("w", "")
		var actual_w: String = session.get("last_white_move", "")

		# Verificar si las Blancas jugaron efectivamente la jugada sugerida del libro
		if actual_w == expected_w:
			var expected_b: String = step.get("b", "")
			if expected_b.length() == 4:
				var from_sq = expected_b.substr(0, 2)
				var to_sq = expected_b.substr(2, 2)
				var from_v = ChessRules.sq_to_vec(from_sq)
				var to_v = ChessRules.sq_to_vec(to_sq)

				for lm in legal_moves:
					if lm["from"] == from_v and lm["to"] == to_v:
						session["book_step_index"] = book_idx + 1
						session["opening_ply"] = session["book_step_index"]
						session["last_sparring_event"] = "opening_step"
						session["last_sparring_tip"] = step.get("b_why", "")
						if session["book_step_index"] >= book.size():
							session["opening_completed"] = true
						on_move_ready.call(lm)
						return
		else:
			# Las Blancas se desviaron del libro de apertura: adaptación pedagógica suave
			session["opening_completed"] = true
			session["opening_deviated"] = true
			session["last_sparring_event"] = "opening_deviated"
			session["last_sparring_tip"] = "¡Interesante variante! Has elegido otro camino. ¡Nos adaptamos a esta posición!"
	else:
		session["opening_completed"] = true

	# --------------------------------------------------------------------------
	# FASE 2: PLANTEAR UN OBSTÁCULO DE MEDIO JUEGO (Turnos 5 a 14)
	# --------------------------------------------------------------------------
	var mid_id = session.get("midgame", {}).get("id", "")
	if not session.get("midgame_presented", false) and fullmove >= 5 and fullmove <= 14:
		var challenge_move = _try_generate_midgame_challenge_move(rules, legal_moves, mid_id)
		if not challenge_move.is_empty():
			session["midgame_presented"] = true
			session["midgame_active"] = true
			session["last_sparring_event"] = "challenge_presented"
			session["last_sparring_tip"] = session.get("midgame", {}).get("desc", "")
			on_move_ready.call(challenge_move)
			return

	# --------------------------------------------------------------------------
	# FASE 3: CEBO DIDÁCTICO PARA PERMITIR REMATE DE FINAL (Turnos 15+)
	# --------------------------------------------------------------------------
	if fullmove >= 15:
		var end_id = session.get("endgame", {}).get("id", "")
		var endgame_move = _try_generate_endgame_setup_move(rules, legal_moves, end_id)
		if not endgame_move.is_empty():
			session["endgame_active"] = true
			session["last_sparring_event"] = "endgame_setup"
			on_move_ready.call(endgame_move)
			return

	# --------------------------------------------------------------------------
	# FALLBACK SANO Y HUMANO CON EL MOTOR (Stockfish depth 2)
	# --------------------------------------------------------------------------
	fallback_bot.get_best_move_async(rules, 2, func(best_m: Dictionary):
		session["last_sparring_event"] = "engine_move"
		session["last_sparring_tip"] = ""
		if not best_m.is_empty():
			on_move_ready.call(best_m)
		else:
			on_move_ready.call(legal_moves[0])
	)

## Genera la explicación didáctica y la sugerencia de jugada para el turno de las Blancas
static func get_player_coaching(rules: ChessRules, session: Dictionary, best_move: Dictionary) -> Dictionary:
	if not rules or best_move.is_empty():
		return {
			"tag": "✨ Jugada de Desarrollo",
			"l1": "Mueve una pieza activa hacia el centro del tablero.",
			"why": "El control del centro te da ventaja de espacio."
		}

	var from_sq = ChessRules.vec_to_sq(best_move["from"])
	var to_sq = ChessRules.vec_to_sq(best_move["to"])
	var p_type = rules.get_piece_at(best_move["from"]).to_lower()
	var p_name = _get_piece_name(p_type)
	var fullmove = rules.fullmove_number
	var op_data: Dictionary = session.get("opening", {})
	var book: Array = op_data.get("book", [])

	# 1. ¿Estamos en el libro de apertura canónica?
	if fullmove <= book.size():
		var step_idx = fullmove - 1
		if step_idx >= 0 and step_idx < book.size():
			var step = book[step_idx]
			var expected_w = step.get("w", "")
			var actual_w = from_sq + to_sq
			if expected_w == actual_w:
				var op_name = op_data.get("name", "Apertura")
				return {
					"tag": "📖 %s" % op_name,
					"l1": "Mueve tu [b]%s[/b] a [b]%s[/b]. %s" % [p_name, to_sq.to_upper(), step.get("w_tip", "")],
					"why": "Siguiendo el plan clásico del manual para dominar el centro."
				}

	# 2. Marcar el reto de medio juego como atendido para evitar repeticiones
	if session.get("midgame_active", false):
		session["midgame_active"] = false
		session["midgame_solved"] = true

	# 3. Analizar dinámicamente el movimiento real en el tablero (Mates, Jaques, Capturas, etc.)
	var concept = ChessTutorConcepts.analyze_move_concept(rules, from_sq, to_sq, session.get("opening_id", ""))
	return {
		"tag": concept.get("tag", "✨ Jugada Estratégica"),
		"l1": concept.get("l1", "Mueve tu %s a %s." % [p_name, to_sq.to_upper()]),
		"why": concept.get("l2", "")
	}

# ==============================================================================
# GENERADORES DE RETOS Y OBSTÁCULOS CONTROLADOS DE NEGRAS
# ==============================================================================

static func _try_generate_midgame_challenge_move(rules: ChessRules, legal_moves: Array[Dictionary], challenge_id: String) -> Dictionary:
	match challenge_id:
		"clavada_alfil":
			# Buscar si un Alfil negro puede moverse a g4 (clavando Nf3) o b4 (clavando Nc3)
			for m in legal_moves:
				var p = rules.get_piece_at(m["from"]).to_lower()
				if p == "b":
					var to_sq = ChessRules.vec_to_sq(m["to"])
					if to_sq in ["g4", "b4"]:
						# Verificar que la casilla sea segura o tenga sentido
						return m

		"amenaza_centro":
			# Buscar un caballo o peón negro que ataque e4 o d4
			for m in legal_moves:
				var to_sq = ChessRules.vec_to_sq(m["to"])
				if to_sq in ["f6", "c6", "d5", "e5"]:
					var sim = rules.clone()
					sim.make_move(m["from"], m["to"])
					var e4_v = ChessRules.sq_to_vec("e4")
					var d4_v = ChessRules.sq_to_vec("d4")
					if sim.is_square_attacked(e4_v, true) or sim.is_square_attacked(d4_v, true):
						return m

		"caballo_pulpo":
			# Buscar mover un Caballo negro a d4 o e4 (puesto avanzado)
			for m in legal_moves:
				var p = rules.get_piece_at(m["from"]).to_lower()
				if p == "n":
					var to_sq = ChessRules.vec_to_sq(m["to"])
					if to_sq in ["d4", "e4", "c4"]:
						return m

		"columna_abierta":
			# Buscar mover una Torre negra a una columna abierta
			for m in legal_moves:
				var p = rules.get_piece_at(m["from"]).to_lower()
				if p == "r":
					if _is_column_open(rules, m["to"].x):
						return m

		"trampa_horquilla":
			# Dejar dos piezas negras en casillas que permitan una horquilla de caballo blanco
			for m in legal_moves:
				var sim = rules.clone()
				sim.make_move(m["from"], m["to"])
				var white_moves = sim.get_all_legal_moves(true)
				for wm in white_moves:
					if sim.get_piece_at(wm["from"]).to_lower() == "n":
						var fork_targets = ChessTutorConcepts._detect_fork_targets(sim, wm["to"], false)
						if fork_targets.size() >= 2:
							return m

		"bateria_dama_alfil":
			# Alinear Dama o Alfil negro mirando a h2
			for m in legal_moves:
				var p = rules.get_piece_at(m["from"]).to_lower()
				if p in ["q", "b"]:
					var to_sq = ChessRules.vec_to_sq(m["to"])
					if to_sq in ["d6", "c7", "b8"]:
						return m

	return {}

static func _try_generate_endgame_setup_move(rules: ChessRules, legal_moves: Array[Dictionary], endgame_id: String) -> Dictionary:
	match endgame_id:
		"mate_pasillo":
			# Si el Rey negro está en la fila 8 o puede resguardarse en g8/h8 detrás de sus peones
			for m in legal_moves:
				var p = rules.get_piece_at(m["from"]).to_lower()
				if p == "k" and m["to"].y == 7:
					return m

		"evitar_rey_ahogado":
			# Mover el Rey hacia la banda buscando recursos defensivos
			for m in legal_moves:
				var p = rules.get_piece_at(m["from"]).to_lower()
				if p == "k" and (m["to"].x in [0, 7] or m["to"].y in [0, 7]):
					return m

	return {}

static func _is_column_open(rules: ChessRules, col_x: int) -> bool:
	for y in range(8):
		var p = rules.get_piece_at(Vector2i(col_x, y)).to_lower()
		if p == "p":
			return false
	return true

static func _get_piece_name(p: String) -> String:
	match p.to_lower():
		"p": return "Peón"
		"n": return "Caballo"
		"b": return "Alfil"
		"r": return "Torre"
		"q": return "Dama"
		"k": return "Rey"
	return "Pieza"
