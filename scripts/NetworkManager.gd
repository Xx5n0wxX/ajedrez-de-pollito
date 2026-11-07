class_name NetworkManagerClass
extends Node

## NetworkManager: Gestor unificado de partidas Multijugador para Ajedrez de Pollito.
## Soporta:
## 1. Modo Online por Código de Sala (Firebase Realtime Database / REST Serverless).
## 2. Modo LAN / Local Directo (ENetMultiplayerPeer de Godot para misma Wi-Fi o mismo PC).

signal room_created(code: String)
signal room_joined()
signal room_join_failed(reason: String)
signal opponent_joined(opponent_name: String, your_color: String)
signal opponent_disconnected()
signal move_received(from_sq: String, to_sq: String, promotion: String, white_time: float, black_time: float, think_time: float)
signal chat_received(sender: String, message: String)
signal action_received(action_type: String, sender: String)
signal connection_status_changed(is_connected: bool, info: String)

enum ConnectionType {
	NONE,
	ONLINE_FIREBASE,
	LAN_ENET
}

static var instance: NetworkManagerClass = null

# Configuración de Red
var connection_type: ConnectionType = ConnectionType.NONE
var firebase_base_url: String = "https://ajedrez-de-pollito-default-rtdb.firebaseio.com/rooms"
var enet_default_port: int = 7777

# Identificador único de sesión de cliente (evita colisiones cuando ambos jugadores tienen el mismo nombre de perfil)
var session_id: String = ""

# Estado de la Partida Actual
var room_code: String = ""
var is_host: bool = false
var my_player_name: String = "Jugador"
var opponent_name: String = "Rival"
var my_color: String = "w" # "w" (blancas) o "b" (negras)
var opponent_color: String = "b"
var time_control_minutes: int = 5 # 0 para sin reloj, 3, 5, 10
var is_in_game: bool = false

# Variables internas para sincronización en línea (Firebase)
var _http_client: HTTPRequest
var _poll_timer: Timer
var _last_received_move_seq: int = 0
var _last_processed_move_id: String = ""
var _processed_move_ids: Dictionary = {}
var _pending_moves_queue: Array[Dictionary] = []
var _last_received_chat_count: int = 0
var _processed_chat_keys: Dictionary = {}
var _last_received_action_seq: int = 0
var _last_processed_action_id: String = ""
var _processed_action_ids: Dictionary = {}
var _is_polling: bool = false
var _poll_start_msec: int = 0
var _poll_interval: float = 0.35

# Variables internas para sincronización LAN (ENet)
var _enet_peer: ENetMultiplayerPeer = null

func _init() -> void:
	instance = self
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	session_id = "%d_%d_%d" % [OS.get_process_id(), int(Time.get_unix_time_from_system() * 1000.0), rng.randi()]

func _ready() -> void:
	_http_client = HTTPRequest.new()
	_http_client.name = "NetworkHTTPClient"
	_http_client.timeout = 5.0
	add_child(_http_client)
	_http_client.request_completed.connect(_on_http_request_completed)

	_poll_timer = Timer.new()
	_poll_timer.name = "PollTimer"
	_poll_timer.wait_time = _poll_interval
	_poll_timer.one_shot = false
	add_child(_poll_timer)
	_poll_timer.timeout.connect(_on_poll_timer_timeout)

	_load_network_config()

# =========================================================================
# CONFIGURACIÓN Y PERSISTENCIA
# =========================================================================

func _load_network_config() -> void:
	var path = "user://network_settings.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var txt = f.get_as_text()
			var json = JSON.new()
			if json.parse(txt) == OK and json.data is Dictionary:
				var data: Dictionary = json.data
				if data.has("firebase_base_url") and str(data["firebase_base_url"]).strip_edges() != "":
					firebase_base_url = str(data["firebase_base_url"]).strip_edges()
				if data.has("enet_port") and int(data["enet_port"]) > 1024:
					enet_default_port = int(data["enet_port"])

func save_network_config() -> void:
	var path = "user://network_settings.json"
	var data = {
		"firebase_base_url": firebase_base_url,
		"enet_port": enet_default_port
	}
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))

# =========================================================================
# GENERADOR DE CÓDIGOS DE SALA Y UTILIDADES
# =========================================================================

static func generate_room_code() -> String:
	var prefix = "POLLO-"
	var chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var code = prefix
	for i in range(4):
		code += chars[randi() % chars.length()]
	return code

func _get_my_role() -> String:
	return "host" if is_host else "guest"

func _is_from_opponent(item: Dictionary, id_key: String, role_key: String, name_key: String) -> bool:
	var item_id = str(item.get(id_key, "")).strip_edges()
	if item_id != "":
		return item_id != session_id
	var item_role = str(item.get(role_key, "")).strip_edges()
	if item_role != "":
		return item_role != _get_my_role()
	return str(item.get(name_key, "")) != my_player_name

func _send_firebase_write(url: String, method: int, json_body: String, retries_left: int = 2) -> void:
	var http = HTTPRequest.new()
	http.timeout = 6.0
	add_child(http)
	var headers = ["Content-Type: application/json"]
	http.request_completed.connect(func(result: int, response_code: int, _h: PackedStringArray, _b: PackedByteArray):
		http.queue_free()
		if (result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300) and retries_left > 0:
			if connection_type == ConnectionType.ONLINE_FIREBASE and room_code != "":
				_send_firebase_write(url, method, json_body, retries_left - 1)
	)
	var err = http.request(url, headers, method, json_body)
	if err != OK:
		http.queue_free()

# =========================================================================
# GESTIÓN DE SALAS ONLINE (FIREBASE)
# =========================================================================

func create_online_room(code: String, host_name: String, time_mins: int, color_choice: String) -> void:
	leave_current_session()
	var clean_code = code.to_upper().strip_edges()
	if clean_code == "":
		clean_code = generate_room_code()

	connection_type = ConnectionType.ONLINE_FIREBASE
	room_code = clean_code
	is_host = true
	my_player_name = host_name
	time_control_minutes = time_mins

	if color_choice == "random":
		my_color = "w" if randi() % 2 == 0 else "b"
	else:
		my_color = "w" if color_choice == "w" or color_choice == "white" else "b"
	opponent_color = "b" if my_color == "w" else "w"

	_last_received_move_seq = 0
	_last_processed_move_id = ""
	_processed_move_ids.clear()
	_pending_moves_queue.clear()
	_last_received_chat_count = 0
	_processed_chat_keys.clear()
	_last_received_action_seq = 0
	_last_processed_action_id = ""
	_processed_action_ids.clear()

	var initial_room_state = {
		"code": room_code,
		"status": "waiting",
		"time_mins": time_mins,
		"host_name": host_name,
		"host_id": session_id,
		"host_color": my_color,
		"guest_name": "",
		"guest_id": "",
		"guest_color": opponent_color,
		"created_at": Time.get_unix_time_from_system(),
		"moves": [],
		"last_move": null,
		"chat": [],
		"last_action": null
	}

	var json_body = JSON.stringify(initial_room_state)
	var url = "%s/%s.json" % [firebase_base_url, room_code]
	_send_firebase_write(url, HTTPClient.METHOD_PUT, json_body)

	room_created.emit(room_code)
	_poll_timer.start(_poll_interval)

func join_online_room(code: String, guest_name: String) -> void:
	leave_current_session()
	var clean_code = code.to_upper().strip_edges()
	if clean_code == "":
		room_join_failed.emit("Por favor ingresa un código de sala válido.")
		return

	connection_type = ConnectionType.ONLINE_FIREBASE
	room_code = clean_code
	is_host = false
	my_player_name = guest_name

	_last_received_move_seq = 0
	_last_processed_move_id = ""
	_processed_move_ids.clear()
	_pending_moves_queue.clear()
	_last_received_chat_count = 0
	_processed_chat_keys.clear()
	_last_received_action_seq = 0
	_last_processed_action_id = ""
	_processed_action_ids.clear()

	var url = "%s/%s.json" % [firebase_base_url, room_code]
	var headers = ["Content-Type: application/json"]
	_is_polling = true
	_poll_start_msec = Time.get_ticks_msec()
	_http_client.request(url, headers, HTTPClient.METHOD_GET)

func _handle_join_online_response(data: Dictionary) -> void:
	if room_code.strip_edges() == "":
		return

	if data.is_empty():
		room_join_failed.emit("La sala '%s' no existe. Revisa el código." % room_code)
		leave_current_session()
		return

	var status = str(data.get("status", ""))
	if status != "waiting" and status != "playing":
		room_join_failed.emit("La sala '%s' ya finalizó o no está disponible." % room_code)
		leave_current_session()
		return

	var existing_guest_id = str(data.get("guest_id", "")).strip_edges()
	var existing_guest_name = str(data.get("guest_name", "")).strip_edges()
	if status == "playing" and existing_guest_name != "":
		var is_same_guest = (existing_guest_id != "" and existing_guest_id == session_id) or (existing_guest_id == "" and existing_guest_name == my_player_name)
		if not is_same_guest:
			room_join_failed.emit("La sala '%s' ya está llena con 2 jugadores." % room_code)
			leave_current_session()
			return

	opponent_name = str(data.get("host_name", "Rival"))
	var host_color = str(data.get("host_color", "w"))
	opponent_color = host_color
	my_color = "b" if host_color == "w" else "w"
	time_control_minutes = int(data.get("time_mins", 5))

	var patch_data = {
		"guest_name": my_player_name,
		"guest_id": session_id,
		"guest_color": my_color,
		"status": "playing"
	}
	var json_body = JSON.stringify(patch_data)
	var url = "%s/%s.json" % [firebase_base_url, room_code]
	_send_firebase_write(url, HTTPClient.METHOD_PATCH, json_body)

	is_in_game = true
	room_joined.emit()
	opponent_joined.emit(opponent_name, my_color)
	_poll_timer.start(_poll_interval)

func _on_poll_timer_timeout() -> void:
	if connection_type != ConnectionType.ONLINE_FIREBASE or room_code.strip_edges() == "":
		_poll_timer.stop()
		return

	if _is_polling:
		if Time.get_ticks_msec() - _poll_start_msec > 4500:
			_http_client.cancel_request()
			_is_polling = false
		else:
			return

	_is_polling = true
	_poll_start_msec = Time.get_ticks_msec()
	var url = "%s/%s.json" % [firebase_base_url, room_code]
	var headers = ["Content-Type: application/json"]
	var err = _http_client.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_is_polling = false

func _on_http_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_is_polling = false
	if response_code < 200 or response_code >= 300:
		return

	var json_str = body.get_string_from_utf8()
	if json_str.strip_edges() == "" or json_str == "null":
		if not is_host and not is_in_game:
			_handle_join_online_response({})
		return

	var json = JSON.new()
	if json.parse(json_str) != OK or not (json.data is Dictionary):
		return

	var data: Dictionary = json.data

	# Si es el Invitado tratando de unirse a la sala
	if not is_host and not is_in_game:
		_handle_join_online_response(data)
		return

	# Si el Host estaba esperando y ahora el invitado se unió
	if is_host and not is_in_game:
		var status = str(data.get("status", ""))
		var guest = str(data.get("guest_name", "")).strip_edges()
		if (status == "playing" or guest != "") and guest != "":
			opponent_name = guest
			is_in_game = true
			opponent_joined.emit(opponent_name, my_color)
			return

	# Procesar jugadas entrantes
	if is_in_game and data.has("last_move") and data["last_move"] is Dictionary:
		var move: Dictionary = data["last_move"]
		var seq: int = int(move.get("seq", 0))
		var from_sq = str(move.get("from", ""))
		var to_sq = str(move.get("to", ""))
		var move_id = str(move.get("move_id", "")).strip_edges()
		if move_id == "":
			move_id = "%d_%s_%s_%s_%s" % [seq, from_sq, to_sq, str(move.get("by_role", "")), str(move.get("by", ""))]

		if from_sq != "" and to_sq != "" and not _processed_move_ids.has(move_id) and seq > _last_received_move_seq:
			_last_received_move_seq = seq
			_last_processed_move_id = move_id
			_processed_move_ids[move_id] = true
			if _is_from_opponent(move, "by_id", "by_role", "by"):
				var promo = str(move.get("promo", ""))
				var w_time = float(move.get("w_time", 300.0))
				var b_time = float(move.get("b_time", 300.0))
				var think_t = float(move.get("think_time", 0.0))
				if move_received.get_connections().size() > 0:
					move_received.emit(from_sq, to_sq, promo, w_time, b_time, think_t)
				else:
					_pending_moves_queue.append({
						"from": from_sq,
						"to": to_sq,
						"promo": promo,
						"w_time": w_time,
						"b_time": b_time,
						"think_time": think_t
					})

	# Procesar chat entrante
	if is_in_game and data.has("chat") and (data["chat"] is Array or data["chat"] is Dictionary):
		var chat_entries: Array = []
		if data["chat"] is Array:
			var arr: Array = data["chat"]
			for idx in range(arr.size()):
				if arr[idx] is Dictionary:
					chat_entries.append({"key": "idx_%d" % idx, "item": arr[idx]})
		elif data["chat"] is Dictionary:
			var chat_dict: Dictionary = data["chat"]
			var keys = chat_dict.keys()
			keys.sort()
			for k in keys:
				if chat_dict[k] is Dictionary:
					chat_entries.append({"key": str(k), "item": chat_dict[k]})

		for entry in chat_entries:
			var item: Dictionary = entry["item"]
			var unique_key: String = str(item.get("chat_id", "")).strip_edges()
			if unique_key == "":
				unique_key = str(entry["key"])

			if not _processed_chat_keys.has(unique_key):
				_processed_chat_keys[unique_key] = true
				if _is_from_opponent(item, "sender_id", "sender_role", "sender"):
					var sender = str(item.get("sender", "Rival"))
					var text = str(item.get("text", ""))
					if text != "":
						chat_received.emit(sender, text)

		_last_received_chat_count = chat_entries.size()

	# Procesar acciones entrantes (rendición, tablas, revancha)
	if is_in_game and data.has("last_action") and data["last_action"] is Dictionary:
		var act: Dictionary = data["last_action"]
		var seq: int = int(act.get("seq", 0))
		var action_type = str(act.get("type", ""))
		var action_id = str(act.get("action_id", "")).strip_edges()
		if action_id == "":
			action_id = "%d_%s_%s_%s" % [seq, action_type, str(act.get("sender_role", "")), str(act.get("sender", ""))]

		if seq > _last_received_action_seq:
			_last_received_action_seq = seq

		if action_type != "" and not _processed_action_ids.has(action_id):
			_last_processed_action_id = action_id
			_processed_action_ids[action_id] = true
			if _is_from_opponent(act, "sender_id", "sender_role", "sender"):
				var sender = str(act.get("sender", "Rival"))
				action_received.emit(action_type, sender)

# =========================================================================
# GESTIÓN DE SALAS LAN / RED LOCAL (ENet)
# =========================================================================

func start_lan_host(port: int, host_name: String, time_mins: int, color_choice: String) -> Error:
	leave_current_session()
	connection_type = ConnectionType.LAN_ENET
	is_host = true
	my_player_name = host_name
	time_control_minutes = time_mins
	room_code = "LAN-%d" % port

	if color_choice == "random":
		my_color = "w" if randi() % 2 == 0 else "b"
	else:
		my_color = "w" if color_choice == "w" or color_choice == "white" else "b"
	opponent_color = "b" if my_color == "w" else "w"

	_enet_peer = ENetMultiplayerPeer.new()
	var err = _enet_peer.create_server(port, 2)
	if err != OK:
		return err

	multiplayer.multiplayer_peer = _enet_peer
	multiplayer.peer_connected.connect(_on_enet_peer_connected)
	multiplayer.peer_disconnected.connect(_on_enet_peer_disconnected)

	room_created.emit(room_code)
	return OK

func join_lan_game(ip: String, port: int, guest_name: String) -> Error:
	leave_current_session()
	connection_type = ConnectionType.LAN_ENET
	is_host = false
	my_player_name = guest_name
	room_code = "%s:%d" % [ip, port]

	_enet_peer = ENetMultiplayerPeer.new()
	var err = _enet_peer.create_client(ip, port)
	if err != OK:
		return err

	multiplayer.multiplayer_peer = _enet_peer
	multiplayer.connected_to_server.connect(_on_enet_connected_to_server)
	multiplayer.connection_failed.connect(_on_enet_connection_failed)
	multiplayer.server_disconnected.connect(_on_enet_server_disconnected)
	return OK

func _on_enet_peer_connected(_peer_id: int) -> void:
	# El host envía su información al invitado que acaba de unirse
	if is_host:
		rpc("_rpc_handshake_host", my_player_name, my_color, opponent_color, time_control_minutes)

func _on_enet_peer_disconnected(_peer_id: int) -> void:
	opponent_disconnected.emit()

func _on_enet_connected_to_server() -> void:
	room_joined.emit()
	# Enviar información del invitado al host
	rpc("_rpc_handshake_guest", my_player_name)

func _on_enet_connection_failed() -> void:
	room_join_failed.emit("No se pudo conectar al servidor LAN. Verifica la IP y que el host esté iniciado.")
	leave_current_session()

func _on_enet_server_disconnected() -> void:
	opponent_disconnected.emit()

@rpc("any_peer", "call_remote", "reliable")
func _rpc_handshake_host(host_n: String, _h_color: String, g_color: String, t_mins: int) -> void:
	opponent_name = host_n
	my_color = g_color
	opponent_color = "b" if my_color == "w" else "w"
	time_control_minutes = t_mins
	is_in_game = true
	opponent_joined.emit(opponent_name, my_color)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_handshake_guest(guest_n: String) -> void:
	opponent_name = guest_n
	is_in_game = true
	opponent_joined.emit(opponent_name, my_color)

# =========================================================================
# ENVÍO DE JUGADAS, CHAT Y ACCIONES
# =========================================================================

func send_move(from_sq: String, to_sq: String, promotion: String, white_time: float, black_time: float, think_time: float = 0.0) -> void:
	_last_received_move_seq += 1
	var move_id = "%s_%d_%d" % [session_id, _last_received_move_seq, Time.get_ticks_msec()]
	_last_processed_move_id = move_id
	_processed_move_ids[move_id] = true

	if connection_type == ConnectionType.ONLINE_FIREBASE and room_code.strip_edges() != "":
		if _is_polling and _http_client:
			_http_client.cancel_request()
			_is_polling = false
		if _poll_timer:
			_poll_timer.start(_poll_interval)

		var move_data = {
			"seq": _last_received_move_seq,
			"move_id": move_id,
			"by": my_player_name,
			"by_id": session_id,
			"by_role": _get_my_role(),
			"from": from_sq,
			"to": to_sq,
			"promo": promotion,
			"w_time": white_time,
			"b_time": black_time,
			"think_time": think_time,
			"ts": Time.get_unix_time_from_system()
		}
		var json_body = JSON.stringify(move_data)
		var url = "%s/%s/last_move.json" % [firebase_base_url, room_code]
		_send_firebase_write(url, HTTPClient.METHOD_PUT, json_body)

	elif connection_type == ConnectionType.LAN_ENET:
		rpc("_rpc_send_move", from_sq, to_sq, promotion, white_time, black_time, think_time)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_send_move(from_sq: String, to_sq: String, promotion: String, white_time: float, black_time: float, think_time: float = 0.0) -> void:
	if move_received.get_connections().size() > 0:
		move_received.emit(from_sq, to_sq, promotion, white_time, black_time, think_time)
	else:
		_pending_moves_queue.append({
			"from": from_sq,
			"to": to_sq,
			"promo": promotion,
			"w_time": white_time,
			"b_time": black_time,
			"think_time": think_time
		})

func flush_pending_moves() -> void:
	if _pending_moves_queue.is_empty() or move_received.get_connections().size() == 0:
		return
	var queued = _pending_moves_queue.duplicate()
	_pending_moves_queue.clear()
	for m in queued:
		move_received.emit(
			str(m.get("from", "")),
			str(m.get("to", "")),
			str(m.get("promo", "")),
			float(m.get("w_time", 300.0)),
			float(m.get("b_time", 300.0)),
			float(m.get("think_time", 0.0))
		)

func reset_for_rematch() -> void:
	_last_received_move_seq = 0
	_last_processed_move_id = ""
	_processed_move_ids.clear()
	_pending_moves_queue.clear()
	if connection_type == ConnectionType.ONLINE_FIREBASE and room_code.strip_edges() != "":
		if _is_polling and _http_client:
			_http_client.cancel_request()
			_is_polling = false
		if _poll_timer:
			_poll_timer.start(_poll_interval)
		if is_host:
			var patch_data = {
				"last_move": null,
				"moves": []
			}
			var json_body = JSON.stringify(patch_data)
			var url = "%s/%s.json" % [firebase_base_url, room_code]
			_send_firebase_write(url, HTTPClient.METHOD_PATCH, json_body)

func send_chat(message: String) -> void:
	var msg = message.strip_edges()
	if msg == "":
		return

	if connection_type == ConnectionType.ONLINE_FIREBASE and room_code.strip_edges() != "":
		var chat_id = "%s_%d_%d" % [session_id, Time.get_ticks_msec(), randi()]
		_processed_chat_keys[chat_id] = true
		var chat_data = {
			"chat_id": chat_id,
			"sender": my_player_name,
			"sender_id": session_id,
			"sender_role": _get_my_role(),
			"text": msg,
			"ts": Time.get_unix_time_from_system()
		}
		var json_body = JSON.stringify(chat_data)
		var url = "%s/%s/chat.json" % [firebase_base_url, room_code]
		_send_firebase_write(url, HTTPClient.METHOD_POST, json_body)

	elif connection_type == ConnectionType.LAN_ENET:
		rpc("_rpc_send_chat", my_player_name, msg)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_send_chat(sender: String, message: String) -> void:
	chat_received.emit(sender, message)

func send_action(action_type: String) -> void:
	_last_received_action_seq += 1
	var action_id = "%s_%d_%d" % [session_id, _last_received_action_seq, Time.get_ticks_msec()]
	_last_processed_action_id = action_id
	_processed_action_ids[action_id] = true

	if connection_type == ConnectionType.ONLINE_FIREBASE and room_code.strip_edges() != "":
		var action_data = {
			"seq": _last_received_action_seq,
			"action_id": action_id,
			"sender": my_player_name,
			"sender_id": session_id,
			"sender_role": _get_my_role(),
			"type": action_type,
			"ts": Time.get_unix_time_from_system()
		}
		var json_body = JSON.stringify(action_data)
		var url = "%s/%s/last_action.json" % [firebase_base_url, room_code]
		_send_firebase_write(url, HTTPClient.METHOD_PUT, json_body)

	elif connection_type == ConnectionType.LAN_ENET:
		rpc("_rpc_send_action", action_type, my_player_name)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_send_action(action_type: String, sender: String) -> void:
	action_received.emit(action_type, sender)

# =========================================================================
# SALIR O LIMPIAR SESIÓN
# =========================================================================

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_in_game or connection_type != ConnectionType.NONE:
			leave_current_session()

func leave_current_session() -> void:
	if _poll_timer:
		_poll_timer.stop()
	if _http_client:
		_http_client.cancel_request()
	_is_polling = false

	if connection_type == ConnectionType.ONLINE_FIREBASE and room_code.strip_edges() != "" and is_in_game:
		send_action("player_left")

	if connection_type == ConnectionType.LAN_ENET and _enet_peer:
		if is_in_game and multiplayer and multiplayer.has_multiplayer_peer():
			send_action("player_left")
		_enet_peer.close()
		multiplayer.multiplayer_peer = null
		_enet_peer = null

	connection_type = ConnectionType.NONE
	room_code = ""
	is_host = false
	is_in_game = false
	_last_received_move_seq = 0
	_last_processed_move_id = ""
	_processed_move_ids.clear()
	_pending_moves_queue.clear()
	_last_received_chat_count = 0
	_processed_chat_keys.clear()
	_last_received_action_seq = 0
	_last_processed_action_id = ""
	_processed_action_ids.clear()
