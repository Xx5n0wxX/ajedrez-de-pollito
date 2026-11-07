class_name ChessTutorConcepts
extends RefCounted

## Módulo de Pedagogía y Escuela de Ajedrez de Manual para Ajedrez de Pollito
## Detecta aperturas canónicas, tácticas clásicas, patrones de jaque mate,
## alertas contra rey ahogado/tablas y principios estratégicos, generando explicaciones
## adaptadas a los 3 niveles de progresión didáctica:
## - Nivel 1: Guiado Total (Flecha + Pieza Fantasma + Explicación paso a paso)
## - Nivel 2: Entrenamiento Visual (Sugerencia en texto + Explicación sin flechas)
## - Nivel 3: Recordatorio Socrático ("Recuerda esta horquilla", sin revelar jugada)

const OPENINGS_DATA: Dictionary = {
	"italiana": {
		"name": "Apertura Italiana (Giuoco Piano)",
		"desc": "Una de las aperturas más antiguas y formativas. Busca el control del centro con peón y apunta con el alfil al punto más débil del rival: el peón f7.",
		"steps": [
			{"move": "e2e4", "tip": "Avanza tu peón a [b]E4[/b] para ocupar el centro y abrir diagonales a tu Dama y Alfil."},
			{"move": "g1f3", "tip": "Desarrolla tu Caballo a [b]F3[/b]: ataca el peón negro central y prepara el camino para el enroque."},
			{"move": "f1c4", "tip": "¡La jugada estrella de la Italiana! Coloca tu Alfil en [b]C4[/b], apuntando directo a la casilla débil F7."},
			{"move": "e1g1", "tip": "¡Hora de asegurar al Rey! Enróctate en corto para proteger a tu Rey y activar tu Torre."}
		]
	},
	"espanola": {
		"name": "Apertura Española (Ruy López)",
		"desc": "La apertura de los campeones mundiales. Presiona al caballo rival que defiende el centro.",
		"steps": [
			{"move": "e2e4", "tip": "Avanza tu peón a [b]E4[/b] para controlar las casillas centrales clave."},
			{"move": "g1f3", "tip": "Saca tu Caballo a [b]F3[/b] atacando el peón central negro y ganando actividad."},
			{"move": "f1b5", "tip": "¡La clave de la Española! Tu Alfil en [b]B5[/b] presiona al caballo guardián que defiende el peón central enemigo."},
			{"move": "e1g1", "tip": "Pon a tu Rey en su castillo seguro con el enroque corto."}
		]
	},
	"cuatro_caballos": {
		"name": "Apertura de los Cuatro Caballos",
		"desc": "La apertura más simétrica y armónica del ajedrez. Ideal para aprender el desarrollo parejo de piezas menores.",
		"steps": [
			{"move": "e2e4", "tip": "Inicia con peón a [b]E4[/b] para abrir camino a tus piezas."},
			{"move": "g1f3", "tip": "Desarrolla tu primer Caballo a [b]F3[/b] hacia el centro."},
			{"move": "b1c3", "tip": "¡Cuatro Caballos! Saca tu segundo Caballo a [b]C3[/b] para un desarrollo completamente armónico y sólido."},
			{"move": "f1b5", "tip": "Activa tu Alfil a [b]B5[/b] o [b]C4[/b] para disputar casillas clave antes de enrocar."}
		]
	},
	"escocesa": {
		"name": "Apertura Escocesa",
		"desc": "Una apertura enérgica y directa que busca dinamitar y abrir el centro rápidamente con d4.",
		"steps": [
			{"move": "e2e4", "tip": "Peón a [b]E4[/b] tomando posición en el centro del tablero."},
			{"move": "g1f3", "tip": "Caballo a [b]F3[/b], atacando la posición enemiga en E5."},
			{"move": "d2d4", "tip": "¡La explosión de la Escocesa! Rompe el centro con [b]D4[/b] para abrir paso a ambos alfiles y ganar espacio."},
			{"move": "f3d4", "tip": "Recaptura en [b]D4[/b] con tu Caballo centralizado y dominante."}
		]
	},
	"gambito_dama": {
		"name": "Gambito de Dama",
		"desc": "La apertura de peón de dama más prestigiosa del manual. Ofrece un peón lateral para adueñarse de las casillas centrales.",
		"steps": [
			{"move": "d2d4", "tip": "Comienza con peón a [b]D4[/b], controlando con firmeza el centro del tablero."},
			{"move": "c2c4", "tip": "¡El famoso Gambito de Dama! Ofreces el peón de [b]C4[/b] para distraer al rival y luego dominar todo con E4."},
			{"move": "b1c3", "tip": "Desarrolla tu Caballo a [b]C3[/b], reforzando la presión sobre el centro."},
			{"move": "g1f3", "tip": "Suma tu Caballo a [b]F3[/b] para un control absoluto de las casillas blancas centrales."}
		]
	}
}

static func pick_random_opening() -> String:
	var keys = OPENINGS_DATA.keys()
	keys.shuffle()
	return keys[0]

static func get_opening_name(opening_key: String) -> String:
	var op = OPENINGS_DATA.get(opening_key, {})
	return str(op.get("name", "Apertura Clásica"))

## Analiza la jugada sugerida y genera las explicaciones pedagógicas para los 3 niveles
static func analyze_move_concept(rules: ChessRules, from_sq: String, to_sq: String, opening_key: String = "") -> Dictionary:
	var from_v = ChessRules.sq_to_vec(from_sq)
	var to_v = ChessRules.sq_to_vec(to_sq)
	var moved_piece = rules.get_piece_at(from_v)
	var p_type = moved_piece.to_lower()
	var p_name = _get_piece_name(p_type)
	var target_p = rules.get_piece_at(to_v)

	var sim = rules.clone()
	var m_res = sim.make_move(from_v, to_v)
	var state_after = sim.get_game_state()

	# -------------------------------------------------------------
	# 1. JAQUE MATE
	# -------------------------------------------------------------
	if state_after == "checkmate":
		var mate_name = "Jaque Mate"
		var why = "¡Das el golpe final y ganas la partida! 🏆"
		# Detectar Mate del Pasillo
		if to_v.y == 7 and (p_type == "r" or p_type == "q"):
			var enemy_k = sim.find_king(false)
			if enemy_k.y == 7:
				mate_name = "Mate del Pasillo"
				why = "¡Sus propios peones le tapan el escape al Rey en la última fila!"
		elif p_type == "q":
			var enemy_k = sim.find_king(false)
			if enemy_k != Vector2i(-1, -1) and maxi(absi(enemy_k.x - to_v.x), absi(enemy_k.y - to_v.y)) == 1:
				if sim.is_square_attacked(to_v, true):
					mate_name = "El Beso de la Muerte"
					why = "¡Tu Dama se coloca cara a cara con el Rey con apoyo de tus piezas!"

		return {
			"tag": "👑 ¡%s!" % mate_name,
			"l1": "Mueve tu [b]%s[/b] a [b]%s[/b]. %s" % [p_name, to_sq.to_upper(), why],
			"l2": "Te sugiero llevar tu [b]%s[/b] a [b]%s[/b] para dar [b]%s[/b]. %s" % [p_name, to_sq.to_upper(), mate_name, why],
			"l3": "💡 ¡Mira bien el tablero! Tienes una red para dar [b]%s[/b]. ¿Ves qué pieza da el golpe ganador?" % mate_name
		}

	# -------------------------------------------------------------
	# 2. PREVENCIÓN DE REY AHOGADO / EVITAR TABLAS
	# -------------------------------------------------------------
	var is_stalemate_danger = false
	var enemy_legal_moves = sim.get_all_legal_moves(false)
	if enemy_legal_moves.size() <= 2 and not sim.is_in_check(false):
		is_stalemate_danger = true

	if is_stalemate_danger and rules.evaluate_material_balance() >= 400:
		return {
			"tag": "🤝 ¡Cuidado con el Rey Ahogado!",
			"l1": "Mueve tu [b]%s[/b] a [b]%s[/b]. Es vital darle espacio al rey rival o darle jaque para NO empatar por ahogado." % [p_name, to_sq.to_upper()],
			"l2": "Te sugiero [b]%s a %s[/b] para evitar que el rey rival quede sin jugadas legales y termine en tablas." % [p_name, to_sq.to_upper()],
			"l3": "💡 ¡Alerta de tablas! Recuerda el peligro del [b]Rey Ahogado[/b]: asegúrate de no quitarle todas las salidas sin darle jaque."
		}

	# -------------------------------------------------------------
	# 3. EL CASTILLO (ENROQUE OPORTUNO)
	# -------------------------------------------------------------
	if m_res.get("is_castling", false):
		var castle_type = "corto" if to_v.x == 6 else "largo"
		return {
			"tag": "🏰 ¡El Castillo (Enroque %s)!" % castle_type.capitalize(),
			"l1": "Haz el [b]Enroque %s[/b] a [b]%s[/b]. Tu Rey queda seguro en su castillo y tu Torre entra activa al juego." % [castle_type, to_sq.to_upper()],
			"l2": "Te sugiero hacer el [b]Enroque %s[/b] para resguardar a tu Rey y conectar tus torres." % castle_type,
			"l3": "💡 ¡Momento clave de seguridad! Recuerda la regla de oro de [b]El Castillo (Enroque)[/b]: ¿cómo ponemos al Rey a salvo?"
		}

	# -------------------------------------------------------------
	# 3.5. JAQUE AL REY (CHECK DIRECTO O CON CAPTURA)
	# -------------------------------------------------------------
	if sim.is_in_check(false):
		if target_p != "":
			var target_name = _get_piece_name(target_p.to_lower())
			return {
				"tag": "⚔️ ¡Jaque y Captura!",
				"l1": "¡Captura el [b]%s[/b] en [b]%s[/b] con tu %s dando jaque al Rey! Rompes su defensa y pones a su Rey en apuros." % [target_name, to_sq.to_upper(), p_name],
				"l2": "Te sugiero capturar en [b]%s[/b] con tu %s dando jaque al Rey negro." % [to_sq.to_upper(), p_name],
				"l3": "💡 ¡Mira qué jugada agresiva! Puedes capturar material y dar jaque al Rey negro al mismo tiempo."
			}
		else:
			return {
				"tag": "⚔️ ¡Jaque al Rey!",
				"l1": "Lleva tu [b]%s[/b] a [b]%s[/b] dando jaque al Rey rival. ¡Está obligado a responder a tu ataque!" % [p_name, to_sq.to_upper()],
				"l2": "Te sugiero [b]%s a %s[/b] dando jaque para obligar al Rey rival a reaccionar." % [p_name, to_sq.to_upper()],
				"l3": "💡 ¡Al ataque! ¿Ves qué pieza puede amenazar directamente con jaque al Rey negro?"
			}

	# -------------------------------------------------------------
	# 4. TÁCTICA: LA HORQUILLA (ATAQUE DOBLE)
	# -------------------------------------------------------------
	var fork_targets = _detect_fork_targets(sim, to_v, false)
	if fork_targets.size() >= 2:
		var t1 = fork_targets[0]
		var t2 = fork_targets[1]
		return {
			"tag": "⚡ ¡Táctica: La Horquilla!",
			"l1": "Mueve tu [b]%s[/b] a [b]%s[/b]. ¡Ataque doble! Atacas a la vez al [b]%s[/b] y al [b]%s[/b]; el rival no podrá salvar ambos." % [p_name, to_sq.to_upper(), t1, t2],
			"l2": "Te sugiero llevar tu [b]%s[/b] a [b]%s[/b]. Esta situación es perfecta para una [b]Horquilla[/b] atacando a dos piezas a la vez." % [p_name, to_sq.to_upper()],
			"l3": "💡 ¡Mira bien el tablero! Esta posición es perfecta para una [b]Horquilla (Ataque Doble)[/b]. ¿Qué pieza tuya puede amenazar a dos rivales a la vez?"
		}

	# -------------------------------------------------------------
	# 5. TÁCTICA: LA CLAVADA
	# -------------------------------------------------------------
	var pinned_piece = _detect_pin(sim, to_v, false)
	if pinned_piece != "":
		return {
			"tag": "🎯 ¡Táctica: La Clavada!",
			"l1": "Ubica tu [b]%s[/b] en [b]%s[/b]. Clavas al [b]%s[/b] rival: ¡no podrá moverse porque dejaría a su Rey o Dama en peligro!" % [p_name, to_sq.to_upper(), pinned_piece],
			"l2": "Te sugiero mover tu [b]%s[/b] a [b]%s[/b] para realizar una [b]Clavada[/b] e inmovilizar a esa pieza enemiga." % [p_name, to_sq.to_upper()],
			"l3": "💡 ¡Ojo táctico! Esta es una situación ideal para una [b]Clavada[/b]. ¿Qué pieza rival está tapando a su Rey o Dama?"
		}

	# -------------------------------------------------------------
	# 6. TÁCTICA: LA ENFILADA (SKEWER)
	# -------------------------------------------------------------
	var skewer_victim = _detect_skewer(sim, to_v, false)
	if skewer_victim != "":
		return {
			"tag": "🏹 ¡Táctica: La Enfilada!",
			"l1": "Lleva tu [b]%s[/b] a [b]%s[/b]. Atacas a su pieza mayor; cuando huya, capturaremos al [b]%s[/b] que está detrás." % [p_name, to_sq.to_upper(), skewer_victim],
			"l2": "Te sugiero [b]%s a %s[/b] ejecutando una [b]Enfilada[/b] a lo largo de la línea para ganar material." % [p_name, to_sq.to_upper()],
			"l3": "💡 ¡Recuerda la técnica de la [b]Enfilada[/b]! ¿Qué línea puedes atacar para que una pieza grande huya y deje caer a la de atrás?"
		}

	# -------------------------------------------------------------
	# 7. TÁCTICA: ELIMINAR AL DEFENSOR / PIEZA COLGADA
	# -------------------------------------------------------------
	if target_p != "" or m_res.get("is_en_passant", false):
		var target_name = _get_piece_name(target_p.to_lower()) if target_p != "" else "peón al paso"
		var val_gain = ChessRules.PIECE_VALUES.get(target_p.to_lower(), 100) - ChessRules.PIECE_VALUES.get(p_type, 100)

		# Captura gratuita (pieza colgada)
		if not sim.is_square_attacked(to_v, false):
			return {
				"tag": "🎁 ¡Pieza Colgada (Regalo del Rival)!",
				"l1": "¡Captura el [b]%s[/b] en [b]%s[/b] con tu %s! Estaba totalmente indefenso y lo ganas gratis." % [target_name, to_sq.to_upper(), p_name],
				"l2": "Te sugiero capturar en [b]%s[/b]: el rival dejó su [b]%s[/b] desprotegido." % [to_sq.to_upper(), target_name],
				"l3": "💡 ¡Revisa bien las defensas del rival! Hay una pieza enemiga colgada y sin protección. ¿Puedes verla?"
			}

		# Ganancia de calidad (ej. Alfil por Torre)
		if val_gain >= 150:
			return {
				"tag": "💎 ¡Ganancia de Calidad Material!",
				"l1": "Captura en [b]%s[/b] cambiando tu %s por su [b]%s[/b]. ¡Ganamos material valioso en el intercambio!" % [to_sq.to_upper(), p_name, target_name],
				"l2": "Te sugiero el cambio en [b]%s[/b]: ganarás calidad de material a tu favor." % to_sq.to_upper(),
				"l3": "💡 Recuerda la regla del valor de piezas: ¿dónde puedes cambiar una pieza menor por una pieza mayor del rival?"
			}

		return {
			"tag": "⚔️ ¡Captura Favorable!",
			"l1": "Captura el [b]%s[/b] en [b]%s[/b] con tu %s para ganar material y abrir la posición." % [target_name, to_sq.to_upper(), p_name],
			"l2": "Te sugiero capturar en [b]%s[/b] para debilitar las defensas del oponente." % to_sq.to_upper(),
			"l3": "💡 ¡Momento de capturar! Recuerda no regalar piezas y evaluar siempre quién defiende cada casilla."
		}

	# -------------------------------------------------------------
	# 8. DEFENDER PIEZA PROPIA EN PELIGRO
	# -------------------------------------------------------------
	var was_under_attack = rules.is_square_attacked(from_v, false)
	var is_safe_now = not sim.is_square_attacked(to_v, false) or sim.is_square_attacked(to_v, true)
	if was_under_attack and is_safe_now:
		return {
			"tag": "🛡️ ¡A la Defensa!",
			"l1": "Mueve tu [b]%s[/b] a [b]%s[/b]. Estaba bajo amenaza rival y aquí queda a salvo y bien protegida." % [p_name, to_sq.to_upper()],
			"l2": "Te sugiero retirar tu [b]%s[/b] a [b]%s[/b] para salvarla del ataque enemigo." % [p_name, to_sq.to_upper()],
			"l3": "💡 ¡Alerta defensiva! Recuerda revisar siempre si alguna de tus piezas quedó amenazada tras la última jugada del rival."
		}

	# -------------------------------------------------------------
	# 9. APERTURA CANÓNICA DE MANUAL (TURNOS TEMPRANOS)
	# -------------------------------------------------------------
	var move_uci = from_sq + to_sq
	var opening_info = OPENINGS_DATA.get(opening_key, {})
	if not opening_info.is_empty() and rules.fullmove_number <= 5:
		var steps: Array = opening_info.get("steps", [])
		for step in steps:
			if step.get("move", "") == move_uci:
				var op_name = str(opening_info.get("name", "Apertura"))
				var op_tip = str(step.get("tip", ""))
				return {
					"tag": "📖 %s" % op_name,
					"l1": "%s Es el plan del manual para dominar la partida." % op_tip,
					"l2": "Te sugiero [b]%s a %s[/b] siguiendo el desarrollo clásico de la [b]%s[/b]." % [p_name, to_sq.to_upper(), op_name],
					"l3": "💡 En la apertura, recuerda el plan de la [b]%s[/b]: ¿qué pieza nos ayuda a luchar por el centro?" % op_name
				}

	# -------------------------------------------------------------
	# 10. ESTRATEGIA: TORRE EN COLUMNA ABIERTA
	# -------------------------------------------------------------
	if p_type == "r":
		if _is_column_open(rules, to_v.x):
			return {
				"tag": "🛣️ ¡Torre en Columna Abierta!",
				"l1": "Coloca tu [b]Torre[/b] en [b]%s[/b]. Sin peones en la columna, ¡tiene una autopista libre para atacar el campo rival!" % to_sq.to_upper(),
				"l2": "Te sugiero [b]Torre a %s[/b] para adueñarte de la columna abierta y proyectar tus ataques." % to_sq.to_upper(),
				"l3": "💡 Recuerda la regla de oro de las Torres: ¿qué columna abierta está libre para que tu torre domine el tablero?"
			}
		elif to_v.y == 6:
			return {
				"tag": "🦅 ¡Torre en Séptima Fila!",
				"l1": "Avanza tu [b]Torre[/b] a [b]%s[/b]. La 7ma fila es la posición soñada: arrasa con los peones rivales y arrincona a su Rey." % to_sq.to_upper(),
				"l2": "Te sugiero invadir con tu [b]Torre a %s[/b] para dominar la séptima fila." % to_sq.to_upper(),
				"l3": "💡 Recuerda la posición más temida por los rivales: ¿cómo llevamos una torre hasta la séptima fila?"
			}

	# -------------------------------------------------------------
	# 11. ESTRATEGIA: CABALLO EN EL CENTRO
	# -------------------------------------------------------------
	if p_type == "n" and to_v.x >= 2 and to_v.x <= 5 and to_v.y >= 2 and to_v.y <= 5:
		return {
			"tag": "🐴 ¡Caballo Centralizado!",
			"l1": "Lleva tu [b]Caballo[/b] a [b]%s[/b]. En el centro controla 8 casillas a la vez y se vuelve una pieza imparable." % to_sq.to_upper(),
			"l2": "Te sugiero [b]Caballo a %s[/b] para dominar el corazón del tablero con un puesto activo." % to_sq.to_upper(),
			"l3": "💡 Recuerda el dicho de manual: 'Caballo en la banda, caballo que se desbanda'. ¿Dónde se hace fuerte tu caballo?"
		}

	# -------------------------------------------------------------
	# 12. ESTRATEGIA: EL PEÓN PASADO
	# -------------------------------------------------------------
	if p_type == "p" and _is_passed_pawn(rules, to_v):
		return {
			"tag": "🌟 ¡El Peón Pasado!",
			"l1": "Avanza tu [b]Peón[/b] a [b]%s[/b]. ¡Es un peón pasado! No hay peones rivales que le impidan llegar a coronar una Dama." % to_sq.to_upper(),
			"l2": "Te sugiero impulsar tu peón a [b]%s[/b] porque se ha convertido en un peligroso [b]Peón Pasado[/b]." % to_sq.to_upper(),
			"l3": "💡 Recuerda el principio de los peones pasados: ¿cuál de tus peones tiene el camino libre hacia la coronación?"
		}

	# -------------------------------------------------------------
	# 13. RESPIRADERO DEL REY (LUFT)
	# -------------------------------------------------------------
	if p_type == "p" and from_sq in ["h2", "g2"] and to_sq in ["h3", "g3"] and rules.fullmove_number >= 8:
		return {
			"tag": "🌬️ ¡Un Respiro para el Rey!",
			"l1": "Avanza tu peón a [b]%s[/b] para abrir una 'ventanita' de escape y evitar sustos con el Mate del Pasillo." % to_sq.to_upper(),
			"l2": "Te sugiero [b]%s[/b] para darle aire a tu Rey en caso de un ataque a la última fila." % to_sq.to_upper(),
			"l3": "💡 Recuerda la seguridad en el medio juego: ¿cómo le damos un respiradero a nuestro Rey para evitar sorpresas?"
		}

	# -------------------------------------------------------------
	# 14. PRINCIPIOS GENERALES Y DESARROLLO DINÁMICO (ANTI-REPETICIÓN)
	# -------------------------------------------------------------
	var dynamic_tag = "✨ Jugada de Desarrollo"
	var dynamic_l1 = ""
	var dynamic_l2 = ""
	var dynamic_l3 = ""

	match p_type:
		"p":
			dynamic_tag = "♟️ Avance de Peón"
			if to_sq in ["e4", "d4"]:
				dynamic_l1 = "Avanza tu peón a [b]%s[/b] para ocupar las casillas centrales y ganar espacio." % to_sq.to_upper()
				dynamic_l2 = "Te sugiero peón a [b]%s[/b] para consolidar el control del centro." % to_sq.to_upper()
				dynamic_l3 = "💡 En el centro del tablero: ¿qué peón te da el mayor espacio si avanza dos pasos?"
			elif to_sq in ["c4", "c3", "f4", "f3"]:
				dynamic_l1 = "Apoya el centro avanzando tu peón a [b]%s[/b] para reforzar la estructura." % to_sq.to_upper()
				dynamic_l2 = "Te sugiero peón a [b]%s[/b] reforzando la cadena de peones." % to_sq.to_upper()
				dynamic_l3 = "💡 Recuerda: los peones laterales apoyan a los centrales. ¿Cómo reforzamos la estructura?"
			else:
				dynamic_l1 = "Empuja tu peón a [b]%s[/b] para ganar terreno y abrir líneas de juego." % to_sq.to_upper()
				dynamic_l2 = "Te sugiero avanzar tu peón a [b]%s[/b]." % to_sq.to_upper()
				dynamic_l3 = "💡 Avanza tu estructura de peones buscando ganar espacio en ese sector."
		"n":
			dynamic_tag = "🐴 Activación de Caballo"
			if to_sq in ["f3", "c3"]:
				dynamic_l1 = "Desarrolla tu Caballo a [b]%s[/b] saltando hacia el centro donde controla casillas clave." % to_sq.to_upper()
				dynamic_l2 = "Te sugiero [b]Caballo a %s[/b] para activar tu pieza menor hacia el centro." % to_sq.to_upper()
				dynamic_l3 = "💡 Recuerda la regla de oro: los Caballos deben saltar hacia el centro, nunca a las orillas."
			else:
				dynamic_l1 = "Maniobra con tu Caballo a [b]%s[/b] buscando una casilla más activa y coordinada." % to_sq.to_upper()
				dynamic_l2 = "Te sugiero [b]Caballo a %s[/b] mejorando su posición en el tablero." % to_sq.to_upper()
				dynamic_l3 = "💡 Busca casillas activas para tus caballos donde tengan mayor alcance."
		"b":
			dynamic_tag = "🎯 Diagonal de Alfil"
			if to_sq in ["c4", "b5"]:
				dynamic_l1 = "Coloca tu Alfil en [b]%s[/b] apuntando con una gran diagonal hacia el flanco rival." % to_sq.to_upper()
				dynamic_l2 = "Te sugiero [b]Alfil a %s[/b] con una diagonal activa y agresiva." % to_sq.to_upper()
				dynamic_l3 = "💡 Los Alfiles adoran las grandes diagonales abiertas. ¿Qué casilla le da máxima visión?"
			elif to_sq in ["e3", "d3", "e2", "d2"]:
				dynamic_l1 = "Desarrolla tu Alfil a [b]%s[/b] para conectar tus piezas y despejar el camino para enrocar." % to_sq.to_upper()
				dynamic_l2 = "Te sugiero [b]Alfil a %s[/b] completando el desarrollo de tus piezas menores." % to_sq.to_upper()
				dynamic_l3 = "💡 Conecta tu ejército desarrollando tu alfil restante antes de atacar."
			else:
				dynamic_l1 = "Ubica tu Alfil en [b]%s[/b] dominando casillas importantes del tablero." % to_sq.to_upper()
				dynamic_l2 = "Te sugiero [b]Alfil a %s[/b] mejorando su diagonal." % to_sq.to_upper()
				dynamic_l3 = "💡 Activa tus piezas de largo alcance."
		"r":
			dynamic_tag = "🛣️ Maniobra de Torre"
			dynamic_l1 = "Centraliza tu Torre en [b]%s[/b] preparándola para entrar en acción en columnas activas." % to_sq.to_upper()
			dynamic_l2 = "Te sugiero [b]Torre a %s[/b] conectando tus torres en el centro." % to_sq.to_upper()
			dynamic_l3 = "💡 Recuerda ubicar las Torres en las columnas que se van a abrir."
		"q":
			dynamic_tag = "👑 Posición de Dama"
			dynamic_l1 = "Ubica tu Dama en [b]%s[/b] aumentando su alcance y coordinándola con el resto de tu ejército." % to_sq.to_upper()
			dynamic_l2 = "Te sugiero [b]Dama a %s[/b] para mejorar su influencia en el tablero." % to_sq.to_upper()
			dynamic_l3 = "💡 Centraliza tu Dama sólo cuando esté bien protegida por tus piezas."
		"k":
			dynamic_tag = "🛡️ Seguridad del Rey"
			dynamic_l1 = "Mueve tu Rey a [b]%s[/b] buscando un refugio seguro fuera del alcance rival." % to_sq.to_upper()
			dynamic_l2 = "Te sugiero [b]Rey a %s[/b] mejorando su resguardo." % to_sq.to_upper()
			dynamic_l3 = "💡 En el ajedrez, la seguridad del Rey siempre es la prioridad número uno."

	return {
		"tag": dynamic_tag,
		"l1": dynamic_l1,
		"l2": dynamic_l2,
		"l3": dynamic_l3
	}

# -------------------------------------------------------------
# DETECTORES AUXILIARES DE PATRONES DE TABLERO
# -------------------------------------------------------------

static func _get_piece_name(p: String) -> String:
	match p.to_lower():
		"p": return "Peón"
		"n": return "Caballo"
		"b": return "Alfil"
		"r": return "Torre"
		"q": return "Dama"
		"k": return "Rey"
	return "Pieza"

static func _detect_fork_targets(sim: ChessRules, from_pos: Vector2i, target_is_white: bool) -> Array[String]:
	var targets: Array[String] = []
	var legal_dests = sim.get_legal_moves(from_pos)
	for dest in legal_dests:
		var p = sim.get_piece_at(dest)
		if p != "" and ChessRules.is_white_piece(p) == target_is_white:
			var val = ChessRules.PIECE_VALUES.get(p.to_lower(), 0)
			if val >= 300 or p.to_lower() == "k":
				targets.append(_get_piece_name(p.to_lower()))
	return targets

static func _detect_pin(sim: ChessRules, from_pos: Vector2i, target_is_white: bool) -> String:
	var piece = sim.get_piece_at(from_pos).to_lower()
	if not piece in ["b", "r", "q"]:
		return ""

	var dirs: Array[Vector2i] = []
	if piece in ["b", "q"]:
		dirs.append_array([Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)])
	if piece in ["r", "q"]:
		dirs.append_array([Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)])

	for d in dirs:
		var first_enemy = Vector2i(-1, -1)
		var first_p = ""
		for step in range(1, 8):
			var cur = from_pos + (d * step)
			if not ChessRules.is_on_board(cur):
				break
			var p = sim.get_piece_at(cur)
			if p != "":
				if ChessRules.is_white_piece(p) == target_is_white:
					if first_enemy == Vector2i(-1, -1):
						first_enemy = cur
						first_p = p
					else:
						# Segunda pieza en la línea: si es Rey o Dama, la primera está clavada
						if p.to_lower() in ["k", "q"]:
							return _get_piece_name(first_p.to_lower())
						break
				else:
					break
	return ""

static func _detect_skewer(sim: ChessRules, from_pos: Vector2i, target_is_white: bool) -> String:
	var piece = sim.get_piece_at(from_pos).to_lower()
	if not piece in ["b", "r", "q"]:
		return ""

	var dirs: Array[Vector2i] = []
	if piece in ["b", "q"]:
		dirs.append_array([Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)])
	if piece in ["r", "q"]:
		dirs.append_array([Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)])

	for d in dirs:
		var first_p = ""
		for step in range(1, 8):
			var cur = from_pos + (d * step)
			if not ChessRules.is_on_board(cur):
				break
			var p = sim.get_piece_at(cur)
			if p != "":
				if ChessRules.is_white_piece(p) == target_is_white:
					if first_p == "":
						first_p = p
					else:
						# Enfilada: primera pieza es K o Q y la de atrás es de valor >= 300
						if first_p.to_lower() in ["k", "q"] and ChessRules.PIECE_VALUES.get(p.to_lower(), 0) >= 300:
							return _get_piece_name(p.to_lower())
						break
				else:
					break
	return ""

static func _is_column_open(rules: ChessRules, col_x: int) -> bool:
	for y in range(8):
		var p = rules.get_piece_at(Vector2i(col_x, y)).to_lower()
		if p == "p":
			return false
	return true

static func _is_passed_pawn(rules: ChessRules, pawn_pos: Vector2i) -> bool:
	var is_white = ChessRules.is_white_piece(rules.get_piece_at(pawn_pos))
	var enemy_pawn = "p" if is_white else "P"
	var y_range = range(pawn_pos.y + 1, 8) if is_white else range(0, pawn_pos.y)

	for y in y_range:
		for dx in [-1, 0, 1]:
			var cx = pawn_pos.x + dx
			if cx >= 0 and cx < 8:
				if rules.get_piece_at(Vector2i(cx, y)) == enemy_pawn:
					return false
	return true
