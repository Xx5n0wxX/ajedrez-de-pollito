class_name ChessBoard
extends Control

## Tablero de ajedrez dinámico 8x8 estilo ChessKid con coordenadas exteriores,
## integración estricta de reglas de ajedrez (ChessRules) y física 60 FPS de plastilina.

signal square_clicked(square: String)
signal move_completed(from_square: String, to_square: String)
signal move_failed(from_square: String, to_square: String)
signal turn_completed(move_data: Dictionary, game_state: String)

const FILES: Array[String] = ["a", "b", "c", "d", "e", "f", "g", "h"]
const RANKS: Array[String] = ["8", "7", "6", "5", "4", "3", "2", "1"]
const PADDING: float = 12.0
const GUTTER_SIZE: float = 38.0
const GRID_GAP: float = 4.0
const TOTAL_GAPS: float = 7.0 * GRID_GAP # 28.0 px entre las 8 casillas
const COORD_FONT = preload("res://assets/fonts/CherryBombOne-Regular.ttf")
const CHESS_PIECE_SCENE = preload("res://scenes/ChessPiece.tscn")

@warning_ignore("shadowed_global_identifier")
const ChessRules = preload("res://scripts/ChessRules.gd")
@warning_ignore("shadowed_global_identifier")
const PromotionPopup = preload("res://scripts/PromotionPopup.gd")
@warning_ignore("shadowed_global_identifier")
const ArrowsOverlay = preload("res://scripts/ArrowsOverlay.gd")

# Motor de reglas integrado, diálogo modal de coronación y capa de flechas tácticas
var rules: ChessRules = ChessRules.new()
var promotion_popup: PromotionPopup
var arrows_overlay: ArrowsOverlay
var ghost_piece_rect: TextureRect = null
var ghost_tween: Tween = null
var check_pulse_tween: Tween = null
var last_check_king_sq: String = ""
var move_interceptor: Callable = Callable()

# Subclase para dibujar puntos indicadores circulares y halos de captura vectoriales
class MoveIndicator extends Control:
	var mode: int = 0 # 0: dot regular, 1: captura, 2: enroque

	func _init() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		anchors_preset = PRESET_FULL_RECT
		set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		visible = false

	func show_dot() -> void:
		mode = 0
		visible = true
		queue_redraw()

	func show_capture_ring() -> void:
		mode = 1
		visible = true
		queue_redraw()

	func show_castling_indicator() -> void:
		mode = 2
		visible = true
		queue_redraw()

	func hide_indicator() -> void:
		visible = false

	func _draw() -> void:
		if not visible:
			return
		var center = size / 2.0
		var min_dim = minf(size.x, size.y)
		if mode == 1:
			# Aro suave translúcido para capturas
			var radius = min_dim * 0.44
			var ring_width = maxf(4.0, min_dim * 0.09)
			draw_circle(center, radius, Color(0.93, 0.27, 0.27, 0.22))
			draw_arc(center, radius, 0.0, TAU, 32, Color(0.93, 0.27, 0.27, 0.85), ring_width, true)
		elif mode == 2:
			# Indicador especial de Enroque (Anillo dorado de protección para el Rey)
			var radius = min_dim * 0.42
			var ring_width = maxf(4.0, min_dim * 0.08)
			draw_circle(center, radius, Color(0.98, 0.75, 0.18, 0.22))
			draw_arc(center, radius, 0.0, TAU, 32, Color(0.95, 0.65, 0.12, 0.90), ring_width, true)
			var dot_radius = maxf(5.0, min_dim * 0.15)
			draw_circle(center, dot_radius, Color(0.98, 0.75, 0.18, 0.90))
			draw_circle(center, dot_radius * 0.6, Color(1.0, 1.0, 1.0, 0.75))
		else:
			# Punto circular suave translúcido para movimientos regulares
			var dot_radius = maxf(6.0, min_dim * 0.16)
			draw_circle(center, dot_radius, Color(0.12, 0.65, 0.52, 0.70))
			draw_circle(center, dot_radius * 0.75, Color(1.0, 1.0, 1.0, 0.45))

# Estilos visuales 2.5D
var style_light: StyleBox
var style_dark: StyleBox
var style_highlight: StyleBoxFlat

# Texturas cacheadas por conjunto
var textures_clasicas: Dictionary = {}
var piece_textures: Dictionary = {}

# Mapeo de nodos y estado
var square_controls: Dictionary = {}
var square_panels: Dictionary = {}
var square_highlights: Dictionary = {}
var square_indicators: Dictionary = {}
var square_pieces: Dictionary = {}
var pieces_by_square: Dictionary = {}
var current_fen: String = ""
var current_square_size: float = 64.0
var rank_labels: Array[Label] = []
var file_labels: Array[Label] = []
var is_flipped: bool = false

# Estado de selección y arrastre
var selected_square: String = ""
var last_from_square: String = ""
var last_to_square: String = ""
var is_animating: bool = false
var interactable: bool = true
var is_interactive: bool = true
var player_is_white: bool = true

func set_player_color(color: String) -> void:
	player_is_white = (color == "w" or color == "white")

# Drag-and-Drop
var is_dragging: bool = false
var is_drag_move: bool = false
var drag_start_square: String = ""
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_proxy: Control = null
var current_legal_destinations: Array[String] = []
var _pending_anim_finalize: Callable = Callable()
var _active_castling_rook_sq: String = ""

# Flechas tácticas (Botón derecho)
var is_right_dragging: bool = false
var right_drag_start_square: String = ""

# Nodos contenedores
var bg_panel: Panel
var coords_layer: Control
var grid_container: GridContainer
var animation_layer: Control
var drag_layer: Control

# Efectos de audio
var sfx_move: AudioStreamPlayer
var sfx_capture: AudioStreamPlayer
var sfx_click: AudioStreamPlayer
var sfx_check: AudioStreamPlayer
var sfx_victory: AudioStreamPlayer

func _ready() -> void:
	custom_minimum_size = Vector2(280, 280)
	_setup_board_styles()
	_load_piece_textures()
	_setup_audio_players()
	_create_board_ui()
	reset_to_starting_position()
	call_deferred("_update_board_layout")

func _restore_base_board_styles() -> void:
	# Casilla Clara (Bloque de plastilina crema cálido)
	var sb_l = StyleBoxFlat.new()
	sb_l.bg_color = Color("#FFF6ED")
	sb_l.set_corner_radius_all(8)
	sb_l.border_width_bottom = 4
	sb_l.border_color = Color("#E4D2C1")
	sb_l.anti_aliasing = true
	style_light = sb_l

	# Casilla Oscura (Bloque de plastilina rosa pastel)
	var sb_d = StyleBoxFlat.new()
	sb_d.bg_color = Color("#F39BB0")
	sb_d.set_corner_radius_all(8)
	sb_d.border_width_bottom = 4
	sb_d.border_color = Color("#C46B81")
	sb_d.anti_aliasing = true
	style_dark = sb_d

func _setup_board_styles() -> void:
	_restore_base_board_styles()

	# 3. Casilla Resaltada (Pistas o casilla seleccionada en amarillo ámbar dorado)
	style_highlight = StyleBoxFlat.new()
	style_highlight.bg_color = Color("#FFE082")
	style_highlight.set_corner_radius_all(8)
	style_highlight.border_width_bottom = 4
	style_highlight.border_color = Color("#D4AF37")
	style_highlight.anti_aliasing = true

func apply_square_style(square_panel: Panel, is_light: bool) -> void:
	square_panel.add_theme_stylebox_override("panel", style_light if is_light else style_dark)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_board_layout()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_cancel_active_drag()

func _on_resized() -> void:
	_update_board_layout()

func _cancel_active_drag() -> void:
	if is_dragging or drag_start_square != "" or (drag_proxy and drag_proxy.visible):
		if drag_start_square != "":
			_cleanup_drag_proxy_to_square(drag_start_square)
		elif drag_proxy:
			drag_proxy.visible = false
			if drag_proxy is ChessPiece:
				drag_proxy.clear_piece()
		is_dragging = false
		is_drag_move = false
		drag_start_square = ""

func _clear_animation_layer() -> void:
	_pending_anim_finalize = Callable()
	_active_castling_rook_sq = ""
	if is_instance_valid(animation_layer):
		for child in animation_layer.get_children():
			if child is ChessPiece:
				child._kill_tween()
			child.queue_free()

func _flush_pending_animation() -> void:
	if _pending_anim_finalize.is_valid():
		var cb = _pending_anim_finalize
		_pending_anim_finalize = Callable()
		_active_castling_rook_sq = ""
		if is_instance_valid(animation_layer):
			for child in animation_layer.get_children():
				if child is ChessPiece:
					child._kill_tween()
				child.queue_free()
		cb.call()

func _reconcile_visual_pieces_with_rules(skip_sq: String = "") -> void:
	pieces_by_square.clear()
	for y in range(8):
		for x in range(8):
			var pos = Vector2i(x, y)
			var sq_name = ChessRules.vec_to_sq(pos)
			var p = rules.get_piece_at(pos)
			if p != "":
				pieces_by_square[sq_name] = p
			if sq_name == skip_sq:
				continue
			var p_node = square_pieces.get(sq_name, null)
			if p_node is ChessPiece:
				if p != "":
					var want_white = (p == p.to_upper())
					var want_type = p.to_upper()
					if not p_node.visible or p_node.piece_type != want_type or p_node.is_white != want_white or (p_node.sprite and p_node.sprite.texture == null):
						p_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
						p_node.scale = Vector2.ONE
						p_node.set_piece_key(p, piece_textures.get(p, null))
						p_node.visible = true
				else:
					if p_node.visible or p_node.piece_type != "":
						p_node.clear_piece()

func _load_piece_textures() -> void:
	var piece_types = ["p", "r", "n", "b", "q", "k"]
	var colors = ["w", "b"]
	textures_clasicas.clear()
	for c in colors:
		for p in piece_types:
			var key = (p.to_upper() if c == "w" else p)
			var path_svg = "res://assets/pieces/%s_%s.svg" % [c, p]
			if ResourceLoader.exists(path_svg):
				textures_clasicas[key] = load(path_svg)
	piece_textures = textures_clasicas.duplicate()

	# Actualizar inmediatamente la textura de todas las piezas vivas en el tablero
	for sq_name in square_pieces:
		var p_char = pieces_by_square.get(sq_name, "")
		if p_char != "":
			var p_node = square_pieces[sq_name]
			var tex = piece_textures.get(p_char, null)
			if p_node != null and is_instance_valid(p_node):
				if p_node.has_method("set_texture"):
					p_node.set_texture(tex)
				elif p_node is TextureRect:
					p_node.texture = tex

	# Si se está arrastrando una pieza, actualizar también el drag_proxy
	if is_instance_valid(drag_proxy) and drag_proxy.visible:
		var drag_char = pieces_by_square.get(drag_start_square, "")
		if drag_char != "":
			var drag_tex = piece_textures.get(drag_char, null)
			if drag_proxy.has_method("set_texture"):
				drag_proxy.set_texture(drag_tex)
			elif drag_proxy is TextureRect:
				drag_proxy.texture = drag_tex

func _setup_audio_players() -> void:
	sfx_move = AudioStreamPlayer.new()
	sfx_move.stream = load("res://assets/sounds/move.wav")
	sfx_move.volume_db = -8.0
	add_child(sfx_move)

	sfx_capture = AudioStreamPlayer.new()
	sfx_capture.stream = load("res://assets/sounds/capture.wav")
	sfx_capture.volume_db = -6.0
	add_child(sfx_capture)

	sfx_click = AudioStreamPlayer.new()
	sfx_click.stream = load("res://assets/sounds/click.wav")
	sfx_click.volume_db = -10.0
	add_child(sfx_click)

	sfx_check = AudioStreamPlayer.new()
	sfx_check.stream = load("res://assets/sounds/check.wav")
	sfx_check.volume_db = -6.0
	add_child(sfx_check)

	sfx_victory = AudioStreamPlayer.new()
	sfx_victory.stream = load("res://assets/sounds/victory.wav")
	sfx_victory.volume_db = -4.0
	add_child(sfx_victory)

func _create_board_ui() -> void:
	# Marco / Bandeja exterior del tablero estilo juguete de plastilina
	bg_panel = Panel.new()
	bg_panel.name = "BoardBgPanel"
	bg_panel.mouse_filter = MOUSE_FILTER_IGNORE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#E2BAC5")
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 6
	sb.border_color = Color("#C99BA8")
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	sb.anti_aliasing = true
	bg_panel.add_theme_stylebox_override("panel", sb)
	add_child(bg_panel)

	# Capa de etiquetas de coordenadas exteriores
	coords_layer = Control.new()
	coords_layer.name = "CoordsLayer"
	coords_layer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(coords_layer)

	rank_labels.clear()
	for r_idx in range(8):
		var lbl = Label.new()
		lbl.name = "Rank_" + RANKS[r_idx]
		lbl.text = RANKS[r_idx]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color("#701a35"))
		coords_layer.add_child(lbl)
		rank_labels.append(lbl)

	file_labels.clear()
	for f_idx in range(8):
		var lbl = Label.new()
		lbl.name = "File_" + FILES[f_idx]
		lbl.text = FILES[f_idx]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color("#701a35"))
		coords_layer.add_child(lbl)
		file_labels.append(lbl)

	# GridContainer con 8 columnas exactas y ranuras entre bloques
	grid_container = GridContainer.new()
	grid_container.name = "Grid64"
	grid_container.columns = 8
	grid_container.add_theme_constant_override("h_separation", int(GRID_GAP))
	grid_container.add_theme_constant_override("v_separation", int(GRID_GAP))
	add_child(grid_container)

	# Capa de animación para movimientos regulares
	animation_layer = Control.new()
	animation_layer.name = "AnimationLayer"
	animation_layer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(animation_layer)

	# Capa de flechas tácticas translúcidas estilo Chess.com (z_index 80)
	arrows_overlay = ArrowsOverlay.new()
	arrows_overlay.name = "ArrowsOverlay"
	arrows_overlay.z_index = 80
	add_child(arrows_overlay)

	# Capa superior para arrastre con z_index elevado
	drag_layer = Control.new()
	drag_layer.name = "DragLayer"
	drag_layer.z_index = 100
	drag_layer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(drag_layer)

	# Crear proxy visual para arrastre con física táctil
	drag_proxy = CHESS_PIECE_SCENE.instantiate()
	drag_proxy.name = "DragProxy"
	drag_proxy.visible = false
	drag_proxy.top_level = true
	drag_proxy.mouse_filter = MOUSE_FILTER_IGNORE
	drag_proxy.set_anchors_preset(Control.PRESET_TOP_LEFT)
	drag_layer.add_child(drag_proxy)

	# Menú modal de coronación centrado sobre el tablero
	promotion_popup = PromotionPopup.new()
	promotion_popup.name = "PromotionPopup"
	promotion_popup.z_index = 150
	add_child(promotion_popup)

	# Generar las 64 casillas dinámicas
	for r_idx in range(8):
		var rank = RANKS[r_idx]
		for f_idx in range(8):
			var file_char = FILES[f_idx]
			var sq_name = file_char + rank
			var is_light = (f_idx + r_idx) % 2 == 0

			var sq_ctrl = Control.new()
			sq_ctrl.name = "Sq_" + sq_name
			sq_ctrl.mouse_filter = MOUSE_FILTER_STOP
			sq_ctrl.gui_input.connect(_on_square_gui_input.bind(sq_name))

			# 1. Bloque de plastilina 2.5D
			var sq_panel = Panel.new()
			sq_panel.name = "ClayBlock"
			sq_panel.anchors_preset = PRESET_FULL_RECT
			sq_panel.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
			sq_panel.mouse_filter = MOUSE_FILTER_IGNORE
			apply_square_style(sq_panel, is_light)
			sq_ctrl.add_child(sq_panel)
			square_panels[sq_name] = sq_panel

			# 2. Capa de Resaltado 2.5D
			var hl_panel = Panel.new()
			hl_panel.name = "Highlight"
			hl_panel.anchors_preset = PRESET_FULL_RECT
			hl_panel.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
			hl_panel.mouse_filter = MOUSE_FILTER_IGNORE
			hl_panel.visible = false
			sq_ctrl.add_child(hl_panel)
			square_highlights[sq_name] = hl_panel

			# 3. Indicador de jugada legal
			var indicator = MoveIndicator.new()
			indicator.name = "MoveIndicator"
			sq_ctrl.add_child(indicator)
			square_indicators[sq_name] = indicator

			# 4. Pieza de ajedrez táctil con física de plastilina
			var piece_ctrl: ChessPiece = CHESS_PIECE_SCENE.instantiate()
			piece_ctrl.name = "Piece"
			piece_ctrl.anchors_preset = PRESET_FULL_RECT
			piece_ctrl.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
			piece_ctrl.mouse_filter = MOUSE_FILTER_IGNORE
			sq_ctrl.add_child(piece_ctrl)
			square_pieces[sq_name] = piece_ctrl

			grid_container.add_child(sq_ctrl)
			square_controls[sq_name] = sq_ctrl

func _update_board_layout() -> void:
	if not is_instance_valid(grid_container) or square_controls.is_empty():
		return
	if size.x < 64.0 or size.y < 64.0:
		return

	var available_width: float = size.x - (PADDING * 2.0) - GUTTER_SIZE
	var available_height: float = size.y - (PADDING * 2.0) - GUTTER_SIZE
	if available_width < 64.0 or available_height < 64.0:
		return

	var max_grid_dim: float = floor(minf(available_width, available_height))
	current_square_size = floor((max_grid_dim - TOTAL_GAPS) / 8.0)
	var board_dimension: float = (current_square_size * 8.0) + TOTAL_GAPS

	var total_width: float = GUTTER_SIZE + board_dimension
	var total_height: float = board_dimension + GUTTER_SIZE

	var offset_x: float = floor((size.x - total_width) / 2.0)
	var offset_y: float = floor((size.y - total_height) / 2.0)

	# 1. Marco / Bandeja exterior
	if is_instance_valid(bg_panel):
		bg_panel.position = Vector2(offset_x - PADDING, offset_y - PADDING)
		bg_panel.size = Vector2(total_width + (PADDING * 2.0), total_height + (PADDING * 2.0))

	# 2. GridContainer de las 64 casillas
	grid_container.position = Vector2(offset_x + GUTTER_SIZE, offset_y)
	grid_container.size = Vector2(board_dimension, board_dimension)

	for sq_name in square_controls:
		var sq_ctrl: Control = square_controls[sq_name]
		sq_ctrl.custom_minimum_size = Vector2(current_square_size, current_square_size)
		sq_ctrl.size = Vector2(current_square_size, current_square_size)

	# 3. Capa de coordenadas y capa de flechas tácticas
	coords_layer.position = Vector2.ZERO
	coords_layer.size = size
	if is_instance_valid(arrows_overlay):
		arrows_overlay.position = Vector2.ZERO
		arrows_overlay.set_deferred("size", size)

	var font_sz: int = clampi(int(current_square_size * 0.30), 12, 22)

	# 4. Números (8 a 1) en la fila exterior izquierda
	for r_idx in range(8):
		if r_idx < rank_labels.size():
			var r_lbl: Label = rank_labels[r_idx]
			r_lbl.text = RANKS[7 - r_idx] if is_flipped else RANKS[r_idx]
			r_lbl.position = Vector2(offset_x + 2.0, offset_y + (r_idx * (current_square_size + GRID_GAP)))
			r_lbl.size = Vector2(GUTTER_SIZE - 4.0, current_square_size)
			r_lbl.add_theme_font_override("font", COORD_FONT)
			r_lbl.add_theme_font_size_override("font_size", font_sz)
			r_lbl.add_theme_color_override("font_color", Color("#701a35"))

	# 5. Letras (a a h) en la fila exterior inferior
	for f_idx in range(8):
		if f_idx < file_labels.size():
			var f_lbl: Label = file_labels[f_idx]
			f_lbl.text = FILES[7 - f_idx] if is_flipped else FILES[f_idx]
			f_lbl.position = Vector2(offset_x + GUTTER_SIZE + (f_idx * (current_square_size + GRID_GAP)), offset_y + board_dimension + 2.0)
			f_lbl.size = Vector2(current_square_size, GUTTER_SIZE)
			f_lbl.add_theme_font_override("font", COORD_FONT)
			f_lbl.add_theme_font_size_override("font_size", font_sz)
			f_lbl.add_theme_color_override("font_color", Color("#701a35"))

	if is_instance_valid(ghost_piece_rect) and ghost_piece_rect.visible and _suggestion_to_sq != "" and square_controls.has(_suggestion_to_sq):
		var target_ctrl: Control = square_controls[_suggestion_to_sq]
		ghost_piece_rect.position = grid_container.position + target_ctrl.position
		ghost_piece_rect.size = Vector2(current_square_size, current_square_size)

# -------------------------------------------------------------
# CONTROL DE ESTADO E INICIALIZACIÓN
# -------------------------------------------------------------
var _suggestion_to_sq: String = ""

func set_interactive(enabled: bool) -> void:
	is_interactive = enabled
	interactable = enabled
	if not enabled:
		selected_square = ""
		_hide_all_indicators()
		clear_highlights()
		_cancel_active_drag()

func reset_to_starting_position() -> void:
	rules.reset()
	clear_suggestion()
	if arrows_overlay:
		arrows_overlay.clear_arrows()
	set_fen(rules.to_fen())

func reset_board() -> void:
	reset_to_starting_position()
	set_interactive(true)

func sync_board_to_rules(_rules_state = null) -> void:
	_clear_animation_layer()
	selected_square = ""
	last_from_square = ""
	last_to_square = ""
	_hide_all_indicators()
	clear_highlights()
	clear_suggestion()
	_cancel_active_drag()
	is_animating = false

	for sq_name in square_pieces:
		var p_node = square_pieces[sq_name]
		if p_node is ChessPiece:
			p_node.clear_piece()

	# Repintar instantáneamente basándose en la matriz actual de ChessRules
	pieces_by_square.clear()
	for y in range(8):
		for x in range(8):
			var pos = Vector2i(x, y)
			var p = rules.get_piece_at(pos)
			if p != "":
				var sq_name = ChessRules.vec_to_sq(pos)
				pieces_by_square[sq_name] = p
				var p_node = square_pieces.get(sq_name, null)
				if p_node is ChessPiece:
					p_node.set_piece_key(p, piece_textures.get(p, null))
					p_node.visible = true

	current_fen = rules.to_fen()
	update_check_highlight()

func set_fen(fen_string: String) -> void:
	_clear_animation_layer()
	current_fen = fen_string
	rules.set_fen(fen_string)
	pieces_by_square.clear()
	selected_square = ""
	_hide_all_indicators()
	_cancel_active_drag()
	is_animating = false

	for sq_name in square_pieces:
		var p_node = square_pieces[sq_name]
		if p_node is ChessPiece:
			p_node.clear_piece()

	clear_highlights()

	for y in range(8):
		for x in range(8):
			var pos = Vector2i(x, y)
			var p = rules.get_piece_at(pos)
			if p != "":
				var sq_name = ChessRules.vec_to_sq(pos)
				pieces_by_square[sq_name] = p
				var p_node = square_pieces.get(sq_name, null)
				if p_node is ChessPiece:
					p_node.set_piece_key(p, piece_textures.get(p, null))

func get_piece_at(square: String) -> String:
	return pieces_by_square.get(square, "")

func show_suggestion(from_sq: String, to_sq: String) -> void:
	clear_suggestion()
	if not square_controls.has(from_sq) or not square_controls.has(to_sq):
		return
	_suggestion_to_sq = to_sq

	# 1. Flecha verde esmeralda
	if arrows_overlay:
		var p1 = get_square_center(from_sq)
		var p2 = get_square_center(to_sq)
		arrows_overlay.add_arrow_with_color(p1, p2, Color(0.15, 0.85, 0.45, 0.85), true)

	# 2. Pieza fantasma translúcida pulsando en destino
	var from_pos = ChessRules.sq_to_vec(from_sq)
	var piece = rules.get_piece_at(from_pos)
	if piece != "" and piece_textures.has(piece):
		if not ghost_piece_rect:
			ghost_piece_rect = TextureRect.new()
			ghost_piece_rect.name = "GhostPieceRect"
			ghost_piece_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ghost_piece_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ghost_piece_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ghost_piece_rect.z_index = 85
			add_child(ghost_piece_rect)

		var target_ctrl: Control = square_controls[to_sq]
		ghost_piece_rect.texture = piece_textures[piece]
		ghost_piece_rect.position = grid_container.position + target_ctrl.position
		ghost_piece_rect.size = target_ctrl.size
		ghost_piece_rect.modulate = Color(1, 1, 1, 0.5)
		ghost_piece_rect.visible = true

		if ghost_tween and ghost_tween.is_valid():
			ghost_tween.kill()
		ghost_tween = create_tween().set_loops()
		ghost_tween.tween_property(ghost_piece_rect, "modulate:a", 0.75, 0.6).set_trans(Tween.TRANS_SINE)
		ghost_tween.tween_property(ghost_piece_rect, "modulate:a", 0.35, 0.6).set_trans(Tween.TRANS_SINE)

func clear_suggestion() -> void:
	_suggestion_to_sq = ""
	if arrows_overlay:
		arrows_overlay.clear_suggestion_arrows()
	if ghost_tween and ghost_tween.is_valid():
		ghost_tween.kill()
	if ghost_piece_rect:
		ghost_piece_rect.visible = false

func show_piece_hint(from_sq: String) -> void:
	clear_highlights()
	highlight_square(from_sq, Color("#F59E0B")) # Brillo dorado / ámbar táctico

func clear_highlights() -> void:
	for sq_name in square_highlights:
		var hl: Panel = square_highlights[sq_name]
		hl.visible = false

func highlight_square(square: String, color: Color = ThemeColors.MOVE_HIGHLIGHT) -> void:
	if square_highlights.has(square):
		var hl: Panel = square_highlights[square]
		if color.a <= 0.01:
			hl.visible = false
			return

		if color == ThemeColors.MOVE_HIGHLIGHT or color == Color("#FFE082"):
			hl.add_theme_stylebox_override("panel", style_highlight)
		else:
			var dyn_style := StyleBoxFlat.new()
			dyn_style.bg_color = color
			dyn_style.set_corner_radius_all(8)
			dyn_style.border_width_bottom = 4
			dyn_style.border_color = color.darkened(0.22)
			dyn_style.anti_aliasing = true
			hl.add_theme_stylebox_override("panel", dyn_style)
		hl.visible = true

func set_move_highlights(from_sq: String, to_sq: String) -> void:
	clear_highlights()
	last_from_square = from_sq
	last_to_square = to_sq
	highlight_square(from_sq, ThemeColors.HIGHLIGHT_MOVE)
	highlight_square(to_sq, ThemeColors.HIGHLIGHT_MOVE)

func update_check_highlight() -> void:
	var state = rules.get_game_state()
	if state == "check" or state == "checkmate":
		var king_pos = rules.find_king(rules.white_to_move)
		if king_pos != Vector2i(-1, -1):
			var k_sq = ChessRules.vec_to_sq(king_pos)
			last_check_king_sq = k_sq
			highlight_square(k_sq, Color(0.95, 0.22, 0.22, 0.72))

			# Halo con pulso suave y continuo en la casilla del Rey
			if square_highlights.has(k_sq):
				var hl: Panel = square_highlights[k_sq]
				if check_pulse_tween:
					check_pulse_tween.kill()
				hl.modulate.a = 1.0
				check_pulse_tween = create_tween().set_loops()
				check_pulse_tween.tween_property(hl, "modulate:a", 0.35, 0.45).set_trans(Tween.TRANS_SINE)
				check_pulse_tween.tween_property(hl, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)

			# Flechas tácticas de amenaza desde las piezas que dan jaque hacia el Rey
			var attackers = rules.get_checking_pieces(rules.white_to_move)
			if arrows_overlay and not attackers.is_empty():
				arrows_overlay.clear_suggestion_arrows()
				var k_center = get_square_center(k_sq)
				for att_pos in attackers:
					var att_sq = ChessRules.vec_to_sq(att_pos)
					var att_center = get_square_center(att_sq)
					arrows_overlay.add_arrow_with_color(att_center, k_center, Color(0.95, 0.15, 0.15, 0.8), true)
	else:
		if check_pulse_tween:
			check_pulse_tween.kill()
			check_pulse_tween = null
		if last_check_king_sq != "" and square_highlights.has(last_check_king_sq):
			square_highlights[last_check_king_sq].modulate.a = 1.0
			last_check_king_sq = ""

# -------------------------------------------------------------
# INDICADORES DE DESTINO LEGAL MEDIANTE CHESSRULES
# -------------------------------------------------------------
func show_legal_moves_for(sq_name: String, allow_passive: bool = false) -> void:
	_hide_all_indicators()
	current_legal_destinations.clear()

	var from_pos = ChessRules.sq_to_vec(sq_name)
	var piece = rules.get_piece_at(from_pos)
	if piece == "":
		return

	var is_piece_white = ChessRules.is_white_piece(piece)
	if not allow_passive and is_piece_white != rules.white_to_move:
		return

	var is_king = (piece.to_lower() == "k")
	var legal_vecs = rules.get_legal_moves(from_pos)
	for dest_vec in legal_vecs:
		var dest_sq = ChessRules.vec_to_sq(dest_vec)
		current_legal_destinations.append(dest_sq)
		if square_indicators.has(dest_sq):
			var target_piece = rules.get_piece_at(dest_vec)
			if is_king and absi(dest_vec.x - from_pos.x) == 2:
				# Indicador dorado de Enroque (protección real)
				square_indicators[dest_sq].show_castling_indicator()
			elif target_piece != "" or dest_vec == rules.en_passant_target:
				square_indicators[dest_sq].show_capture_ring()
			else:
				square_indicators[dest_sq].show_dot()

	# Añadir casillas de torre como destinos válidos al enrocar para permitir click directo
	if is_king:
		var rank_y = from_pos.y
		if legal_vecs.has(Vector2i(6, rank_y)): # Enroque corto disponible
			var rook_sq = "h1" if rank_y == 0 else "h8"
			if not current_legal_destinations.has(rook_sq):
				current_legal_destinations.append(rook_sq)
		if legal_vecs.has(Vector2i(2, rank_y)): # Enroque largo disponible
			var rook_sq = "a1" if rank_y == 0 else "a8"
			if not current_legal_destinations.has(rook_sq):
				current_legal_destinations.append(rook_sq)

func _hide_all_indicators() -> void:
	for sq_name in square_indicators:
		square_indicators[sq_name].hide_indicator()

# -------------------------------------------------------------
# CONTROL DE ENTRADA HÍBRIDA (DRAG & DROP + CLICK-TO-MOVE + SELECCIÓN PASIVA + FLECHAS)
# -------------------------------------------------------------
func _on_square_gui_input(event: InputEvent, sq_name: String) -> void:
	if is_animating:
		return

	# Flechas tácticas con botón derecho (disponible siempre)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_handle_right_mouse_down(sq_name, event.global_position)
		else:
			_handle_right_mouse_up(event.global_position)
		return

	# Clic izquierdo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Limpieza solo de flechas manuales con clic izquierdo (mantiene la sugerencia de Pollito intacta)
		if arrows_overlay and arrows_overlay.has_user_arrows():
			arrows_overlay.clear_user_arrows()

		if is_interactive and interactable:
			_handle_mouse_down(sq_name, event.global_position)
		else:
			# Selección pasiva: permitir ver movimientos válidos incluso si es el turno del bot
			_handle_passive_selection(sq_name)

func _handle_passive_selection(sq_name: String) -> void:
	var from_pos = ChessRules.sq_to_vec(sq_name)
	var piece = rules.get_piece_at(from_pos)
	if piece != "":
		selected_square = sq_name
		clear_highlights()
		highlight_square(sq_name, ThemeColors.MOVE_HIGHLIGHT)
		show_legal_moves_for(sq_name, true)
		play_click_sound()
	else:
		selected_square = ""
		current_legal_destinations.clear()
		clear_highlights()
		_hide_all_indicators()

func _input(event: InputEvent) -> void:
	# 1. Limpieza solo de flechas manuales al hacer clic izquierdo en cualquier punto del tablero
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if arrows_overlay and arrows_overlay.has_user_arrows():
			arrows_overlay.clear_user_arrows()

	# 2. Control de flechas tácticas con botón derecho
	if is_right_dragging:
		if event is InputEventMouseMotion:
			if arrows_overlay:
				arrows_overlay.current_mouse_pos = get_local_mouse_position()
				arrows_overlay.queue_redraw()
			return
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			_handle_right_mouse_up(event.global_position)
			return

	# 3. Control de arrastre de piezas (requiere turno activo e interactividad)
	if not is_interactive or not interactable:
		if is_dragging and drag_proxy:
			_cleanup_drag_proxy_to_square(drag_start_square)
			is_dragging = false
		return

	if not is_dragging:
		return

	if event is InputEventMouseMotion:
		_handle_mouse_motion(event.global_position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_handle_mouse_up(event.global_position)

func _handle_right_mouse_down(sq_name: String, _global_pos: Vector2) -> void:
	is_right_dragging = true
	right_drag_start_square = sq_name
	var center = get_square_center(sq_name)
	if arrows_overlay:
		arrows_overlay.current_arrow_start = center
		arrows_overlay.current_mouse_pos = get_local_mouse_position()
		arrows_overlay.queue_redraw()

func _handle_right_mouse_up(global_pos: Vector2) -> void:
	if not is_right_dragging:
		return
	is_right_dragging = false

	var from_sq = right_drag_start_square
	right_drag_start_square = ""

	if not arrows_overlay:
		return

	arrows_overlay.current_arrow_start = Vector2(-1, -1)

	var target_sq = _get_square_at_position(global_pos)
	if target_sq != "" and target_sq != from_sq:
		var start_center = _get_square_center_in_arrows_overlay(from_sq)
		var end_center = _get_square_center_in_arrows_overlay(target_sq)
		arrows_overlay.add_arrow(start_center, end_center)
	else:
		arrows_overlay.queue_redraw()

func set_flipped(flipped: bool) -> void:
	if is_flipped == flipped:
		return
	is_flipped = flipped
	_reorder_grid_for_flip()
	_update_board_layout()
	if arrows_overlay:
		arrows_overlay.queue_redraw()

func _reorder_grid_for_flip() -> void:
	if not is_instance_valid(grid_container):
		return
	for r_idx in range(8):
		var r_name = RANKS[7 - r_idx] if is_flipped else RANKS[r_idx]
		for f_idx in range(8):
			var f_name = FILES[7 - f_idx] if is_flipped else FILES[f_idx]
			var sq_name = f_name + r_name
			if square_controls.has(sq_name):
				var ctrl = square_controls[sq_name]
				grid_container.move_child(ctrl, -1)

func get_square_center(sq_name: String) -> Vector2:
	if sq_name.length() < 2 or not is_instance_valid(grid_container):
		return Vector2.ZERO
	var lower_sq = sq_name.to_lower()
	var f_idx = FILES.find(lower_sq.substr(0, 1))
	var r_idx = RANKS.find(lower_sq.substr(1, 1))
	if f_idx < 0 or r_idx < 0:
		return Vector2.ZERO

	if is_flipped:
		f_idx = 7 - f_idx
		r_idx = 7 - r_idx

	var sq_step: float = current_square_size + GRID_GAP
	var local_in_grid = Vector2(
		(float(f_idx) * sq_step) + (current_square_size / 2.0),
		(float(r_idx) * sq_step) + (current_square_size / 2.0)
	)
	return grid_container.position + local_in_grid

func _get_square_center_in_arrows_overlay(sq_name: String) -> Vector2:
	return get_square_center(sq_name)

func _handle_mouse_down(sq_name: String, global_pos: Vector2) -> void:
	if not is_interactive or not interactable or is_animating:
		return

	if is_dragging or drag_start_square != "":
		_cancel_active_drag()

	var from_pos = ChessRules.sq_to_vec(sq_name)
	var piece = rules.get_piece_at(from_pos)

	# CASO CLICK-TO-MOVE: Si ya había una casilla seleccionada previamente y se toca un destino legal
	if selected_square != "" and selected_square != sq_name:
		var target_dest = sq_name
		# Mapeo de enroque intuitivo: Tocar la torre cuando el rey está seleccionado
		if selected_square == "e1" and sq_name == "h1" and current_legal_destinations.has("g1"):
			target_dest = "g1"
		elif selected_square == "e1" and sq_name == "a1" and current_legal_destinations.has("c1"):
			target_dest = "c1"
		elif selected_square == "e8" and sq_name == "h8" and current_legal_destinations.has("g8"):
			target_dest = "g8"
		elif selected_square == "e8" and sq_name == "a8" and current_legal_destinations.has("c8"):
			target_dest = "c8"
		# Tocar el rey cuando la torre está seleccionada
		elif selected_square == "h1" and sq_name == "e1" and rules.get_legal_moves(Vector2i(4, 0)).has(Vector2i(6, 0)):
			selected_square = ""
			_hide_all_indicators()
			is_drag_move = false
			_try_player_move("e1", "g1", true, false)
			return
		elif selected_square == "a1" and sq_name == "e1" and rules.get_legal_moves(Vector2i(4, 0)).has(Vector2i(2, 0)):
			selected_square = ""
			_hide_all_indicators()
			is_drag_move = false
			_try_player_move("e1", "c1", true, false)
			return
		elif selected_square == "h8" and sq_name == "e8" and rules.get_legal_moves(Vector2i(4, 7)).has(Vector2i(6, 7)):
			selected_square = ""
			_hide_all_indicators()
			is_drag_move = false
			_try_player_move("e8", "g8", true, false)
			return
		elif selected_square == "a8" and sq_name == "e8" and rules.get_legal_moves(Vector2i(4, 7)).has(Vector2i(2, 7)):
			selected_square = ""
			_hide_all_indicators()
			is_drag_move = false
			_try_player_move("e8", "c8", true, false)
			return

		var selected_origin_piece = rules.get_piece_at(ChessRules.sq_to_vec(selected_square))
		var is_selected_piece_turn = (selected_origin_piece != "" and ChessRules.is_white_piece(selected_origin_piece) == rules.white_to_move and rules.white_to_move == player_is_white)

		if is_selected_piece_turn and (current_legal_destinations.has(target_dest) or current_legal_destinations.has(sq_name)):
			var from_sq = selected_square
			selected_square = ""
			_hide_all_indicators()
			is_drag_move = false
			_try_player_move(from_sq, target_dest, true, false)
			return

	# Si toca una pieza válida de su turno
	if piece != "" and ChessRules.is_white_piece(piece) == rules.white_to_move and rules.white_to_move == player_is_white:
		is_dragging = true
		is_drag_move = false
		drag_start_square = sq_name
		drag_start_mouse_pos = global_pos

		var sq_ctrl: Control = square_controls[sq_name]
		var sq_size := sq_ctrl.size
		if drag_proxy is ChessPiece:
			drag_proxy.set_piece_size(sq_size)
			drag_proxy.set_piece_key(piece, piece_textures.get(piece, null))
			drag_proxy.play_pickup()
		else:
			drag_proxy.size = sq_size
			drag_proxy.texture = piece_textures.get(piece, null)
		drag_proxy.global_position = global_pos - (sq_size / 2.0)
		drag_proxy.visible = true

		# Ocultar la pieza original en la casilla
		square_pieces[sq_name].visible = false

		clear_highlights()
		highlight_square(sq_name, ThemeColors.MOVE_HIGHLIGHT)
		show_legal_moves_for(sq_name)
		play_click_sound()
	elif piece != "":
		# Toca una pieza contraria: mostrar sus movimientos legales de manera informativa/pasiva
		selected_square = sq_name
		clear_highlights()
		highlight_square(sq_name, ThemeColors.MOVE_HIGHLIGHT)
		show_legal_moves_for(sq_name, true)
		play_click_sound()
	else:
		selected_square = ""
		clear_highlights()
		_hide_all_indicators()
		square_clicked.emit(sq_name)

func _handle_mouse_motion(global_pos: Vector2) -> void:
	if is_dragging and drag_proxy.visible:
		drag_proxy.global_position = global_pos - (drag_proxy.size / 2.0)

func _handle_mouse_up(global_pos: Vector2) -> void:
	if not is_dragging:
		return

	is_dragging = false
	var distance_moved = global_pos.distance_to(drag_start_mouse_pos)
	var target_sq = _get_square_at_position(global_pos)
	var from_sq = drag_start_square
	drag_start_square = ""

	# CASO 1: Toque leve en la misma casilla -> Mantiene selección
	if distance_moved < 8.0 or target_sq == from_sq:
		_cleanup_drag_proxy_to_square(from_sq)
		selected_square = from_sq
		square_clicked.emit(from_sq)
		highlight_square(from_sq, ThemeColors.MOVE_HIGHLIGHT)
		show_legal_moves_for(from_sq)
		var p_node = square_pieces.get(from_sq, null)
		if p_node is ChessPiece:
			p_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			p_node.scale = Vector2.ONE
			p_node.play_landing()
		return

	# CASO 2: Soltado sobre una casilla en el tablero
	if target_sq != "":
		selected_square = ""
		_hide_all_indicators()

		# Validar con ChessRules
		var from_pos = ChessRules.sq_to_vec(from_sq)
		var to_pos = ChessRules.sq_to_vec(target_sq)
		var legal_moves = rules.get_legal_moves(from_pos)

		# Mapeo de enroque intuitivo: Soltar Rey sobre su Torre, o Torre sobre su Rey
		var moving_p = rules.get_piece_at(from_pos)
		var p_type = moving_p.to_lower()
		if p_type == "k":
			if from_sq == "e1" and target_sq == "h1" and legal_moves.has(Vector2i(6, 0)):
				target_sq = "g1"
				to_pos = Vector2i(6, 0)
			elif from_sq == "e1" and target_sq == "a1" and legal_moves.has(Vector2i(2, 0)):
				target_sq = "c1"
				to_pos = Vector2i(2, 0)
			elif from_sq == "e8" and target_sq == "h8" and legal_moves.has(Vector2i(6, 7)):
				target_sq = "g8"
				to_pos = Vector2i(6, 7)
			elif from_sq == "e8" and target_sq == "a8" and legal_moves.has(Vector2i(2, 7)):
				target_sq = "c8"
				to_pos = Vector2i(2, 7)
		elif p_type == "r":
			if from_sq == "h1" and target_sq == "e1" and rules.get_legal_moves(Vector2i(4, 0)).has(Vector2i(6, 0)):
				_cleanup_drag_proxy_to_square(from_sq)
				is_drag_move = false
				_try_player_move("e1", "g1", true, false)
				return
			elif from_sq == "a1" and target_sq == "e1" and rules.get_legal_moves(Vector2i(4, 0)).has(Vector2i(2, 0)):
				_cleanup_drag_proxy_to_square(from_sq)
				is_drag_move = false
				_try_player_move("e1", "c1", true, false)
				return
			elif from_sq == "h8" and target_sq == "e8" and rules.get_legal_moves(Vector2i(4, 7)).has(Vector2i(6, 7)):
				_cleanup_drag_proxy_to_square(from_sq)
				is_drag_move = false
				_try_player_move("e8", "g8", true, false)
				return
			elif from_sq == "a8" and target_sq == "e8" and rules.get_legal_moves(Vector2i(4, 7)).has(Vector2i(2, 7)):
				_cleanup_drag_proxy_to_square(from_sq)
				is_drag_move = false
				_try_player_move("e8", "c8", true, false)
				return

		if legal_moves.has(to_pos):
			# Movimiento 100% legal
			is_drag_move = true
			if drag_proxy:
				drag_proxy.visible = false
				if drag_proxy is ChessPiece:
					drag_proxy.clear_piece()
			_try_player_move(from_sq, target_sq, false, true)
		else:
			# Movimiento Ilegal -> Rebote suave de regreso
			is_drag_move = false
			_animate_bounce_back(from_sq)
			get_tree().create_timer(0.18).timeout.connect(func():
				move_failed.emit(from_sq, target_sq)
			)
		return

	# CASO 3: Soltado fuera del tablero -> Rebote elástico
	is_drag_move = false
	_animate_bounce_back(from_sq)
	get_tree().create_timer(0.18).timeout.connect(func():
		move_failed.emit(from_sq, "")
	)

func _get_square_at_position(global_pos: Vector2) -> String:
	if not is_instance_valid(grid_container):
		return ""

	var rect := grid_container.get_global_rect()
	if not rect.has_point(global_pos):
		return ""

	var local_pos := global_pos - grid_container.global_position
	var sq_step: float = current_square_size + GRID_GAP
	if sq_step > 0.0:
		var f_idx: int = clampi(int(local_pos.x / sq_step), 0, 7)
		var r_idx: int = clampi(int(local_pos.y / sq_step), 0, 7)
		var f_char = FILES[7 - f_idx] if is_flipped else FILES[f_idx]
		var r_char = RANKS[7 - r_idx] if is_flipped else RANKS[r_idx]
		return f_char + r_char

	return ""

func _cleanup_drag_proxy_to_square(sq_name: String) -> void:
	if drag_proxy:
		drag_proxy.visible = false
		if drag_proxy is ChessPiece:
			drag_proxy.clear_piece()
	if square_pieces.has(sq_name):
		var p_node = square_pieces[sq_name]
		var expected_p = rules.get_piece_at(ChessRules.sq_to_vec(sq_name)) if sq_name.length() == 2 else ""
		if expected_p != "":
			p_node.visible = true
			if p_node is ChessPiece:
				p_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				p_node.scale = Vector2.ONE
				if p_node.piece_type != expected_p.to_upper() or p_node.is_white != (expected_p == expected_p.to_upper()):
					p_node.set_piece_key(expected_p, piece_textures.get(expected_p, null))
		elif p_node is ChessPiece:
			p_node.clear_piece()

func _animate_bounce_back(origin_sq: String) -> void:
	if not square_controls.has(origin_sq) or not drag_proxy:
		_cleanup_drag_proxy_to_square(origin_sq)
		return

	is_animating = true
	var target_global_pos = square_controls[origin_sq].global_position

	if drag_proxy is ChessPiece:
		drag_proxy.play_bounce_back(target_global_pos)
		get_tree().create_timer(0.18).timeout.connect(func():
			_cleanup_drag_proxy_to_square(origin_sq)
			is_animating = false
			selected_square = origin_sq
			highlight_square(origin_sq, ThemeColors.MOVE_HIGHLIGHT)
			show_legal_moves_for(origin_sq)
			var piece_node = square_pieces.get(origin_sq, null)
			if piece_node is ChessPiece:
				piece_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				piece_node.scale = Vector2.ONE
				piece_node.play_landing()
		)

func _try_player_move(from_sq: String, to_sq: String, animated: bool, is_drag: bool) -> void:
	if is_drag:
		_cleanup_drag_proxy_to_square(from_sq)

	if move_interceptor.is_valid():
		var allow_cb = func():
			is_drag_move = false
			make_move(from_sq, to_sq, true)
		var cancel_cb = func():
			is_drag_move = false
			_cleanup_drag_proxy_to_square(from_sq)
			_hide_all_indicators()
			selected_square = ""
		move_interceptor.call(from_sq, to_sq, allow_cb, cancel_cb)
	else:
		is_drag_move = is_drag
		make_move(from_sq, to_sq, animated)

# -------------------------------------------------------------
# EJECUCIÓN VISUAL Y FÍSICA DEL MOVIMIENTO
# -------------------------------------------------------------
func make_move(from_sq: String, to_sq: String, animated: bool = true, is_bot: bool = false, promo_choice: String = "") -> void:
	if _pending_anim_finalize.is_valid():
		_flush_pending_animation()

	if not is_drag_move and (is_dragging or drag_start_square != ""):
		_cancel_active_drag()

	var from_pos = ChessRules.sq_to_vec(from_sq)
	var to_pos = ChessRules.sq_to_vec(to_sq)

	var origin_piece = rules.get_piece_at(from_pos)
	if origin_piece == "":
		push_warning("ChessBoard.make_move ignorado: casilla origen vacía (%s -> %s)" % [from_sq, to_sq])
		is_drag_move = false
		_reconcile_visual_pieces_with_rules()
		return

	var is_pawn = (origin_piece.to_lower() == "p")
	var is_promo = is_pawn and (to_pos.y == 7 or to_pos.y == 0)
	var mover_is_white = ChessRules.is_white_piece(origin_piece)

	# Ejecutar en el motor de reglas (usar promo_choice si viene especificado, sino reina)
	var promo_arg = promo_choice if (is_promo and promo_choice != "") else "q"
	var move_info = rules.make_move(from_pos, to_pos, promo_arg)
	var moving_piece = move_info.piece
	var is_capture = move_info.is_capture

	_hide_all_indicators()
	selected_square = ""
	if arrows_overlay:
		arrows_overlay.clear_user_arrows()

	var travel_anim: bool = animated and not is_drag_move
	is_drag_move = false

	var apply_captures = func():
		if move_info.is_en_passant:
			var ep_sq = ChessRules.vec_to_sq(move_info.en_passant_captured_pos)
			if square_pieces.has(ep_sq):
				var ep_piece = square_pieces[ep_sq]
				if ep_piece is ChessPiece: ep_piece.clear_piece()
				pieces_by_square.erase(ep_sq)
		elif is_capture:
			if square_pieces.has(to_sq):
				var to_piece = square_pieces[to_sq]
				if to_piece is ChessPiece: to_piece.clear_piece()
				pieces_by_square.erase(to_sq)

	# Si es enroque, animar torre simultáneamente
	if move_info.is_castling:
		var r_from = ChessRules.vec_to_sq(move_info.castling_rook_from)
		var r_to = ChessRules.vec_to_sq(move_info.castling_rook_to)
		_animate_rook_castling(r_from, r_to)

	# Pieza visual mostrada durante el viaje (el peón si aún no corona)
	var visual_piece_name = origin_piece if (is_promo and not is_bot) else moving_piece

	if not travel_anim:
		# CASO DRAG & DROP: La pieza ya está en destino
		apply_captures.call()
		pieces_by_square.erase(from_sq)
		pieces_by_square[to_sq] = visual_piece_name
		if square_pieces.has(from_sq):
			var from_p = square_pieces[from_sq]
			if from_p is ChessPiece: from_p.clear_piece()
		if square_pieces.has(to_sq):
			var to_p = square_pieces[to_sq]
			if to_p is ChessPiece:
				to_p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				to_p.scale = Vector2.ONE
				to_p.set_piece_key(visual_piece_name, piece_textures.get(visual_piece_name, null))
				to_p.play_landing()
		set_move_highlights(from_sq, to_sq)
		update_check_highlight()
		play_move_sound(is_capture)
		clear_suggestion()

		if is_promo:
			if not is_bot:
				is_animating = true
				is_interactive = false
				var chosen_type: String = "q"
				if promotion_popup:
					chosen_type = await promotion_popup.open_promotion(mover_is_white, piece_textures)
				if not is_inside_tree() or rules.history.is_empty():
					is_animating = false
					return

				var final_char = chosen_type.to_upper() if mover_is_white else chosen_type.to_lower()
				rules.set_piece_at(to_pos, final_char)
				move_info.piece = final_char
				move_info.promotion_piece = final_char
				pieces_by_square[to_sq] = final_char
				if square_pieces.has(to_sq):
					var to_p = square_pieces[to_sq]
					if to_p is ChessPiece:
						to_p.set_piece_key(final_char, piece_textures.get(final_char, null))
						to_p.play_landing()
				update_check_highlight()
				play_move_sound(false)
				is_animating = false
				is_interactive = interactable
			elif promo_choice != "":
				var final_char = promo_choice.to_upper() if mover_is_white else promo_choice.to_lower()
				rules.set_piece_at(to_pos, final_char)
				move_info.piece = final_char
				move_info.promotion_piece = final_char
				pieces_by_square[to_sq] = final_char
				if square_pieces.has(to_sq):
					var to_p = square_pieces[to_sq]
					if to_p is ChessPiece:
						to_p.set_piece_key(final_char, piece_textures.get(final_char, null))
						to_p.play_landing()
				update_check_highlight()
				play_move_sound(false)

		_reconcile_visual_pieces_with_rules(_active_castling_rook_sq)
		move_completed.emit(from_sq, to_sq)
		turn_completed.emit(move_info, rules.get_game_state())
		return

	# CASO AUTÓNOMO / BOT / CLICK-TO-MOVE: Viaje deslizante suave
	is_animating = true
	var from_ctrl: Control = square_controls[from_sq]
	var to_ctrl: Control = square_controls[to_sq]

	if square_pieces.has(from_sq):
		var from_p = square_pieces[from_sq]
		if from_p is ChessPiece: from_p.clear_piece()

	var ghost_piece: ChessPiece = CHESS_PIECE_SCENE.instantiate()
	ghost_piece.top_level = true
	ghost_piece.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ghost_piece.mouse_filter = MOUSE_FILTER_IGNORE
	animation_layer.add_child(ghost_piece)
	ghost_piece.set_piece_size(from_ctrl.size)
	ghost_piece.set_piece_key(visual_piece_name, piece_textures.get(visual_piece_name, null))
	ghost_piece.global_position = from_ctrl.global_position
	ghost_piece.play_pickup()

	var finalize_move = func():
		_pending_anim_finalize = Callable()
		if is_instance_valid(ghost_piece):
			ghost_piece.queue_free()
		apply_captures.call()
		pieces_by_square.erase(from_sq)
		pieces_by_square[to_sq] = visual_piece_name
		if square_pieces.has(to_sq):
			var to_p = square_pieces[to_sq]
			if to_p is ChessPiece:
				to_p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				to_p.scale = Vector2.ONE
				to_p.set_piece_key(visual_piece_name, piece_textures.get(visual_piece_name, null))
				to_p.play_landing()
		set_move_highlights(from_sq, to_sq)
		update_check_highlight()
		play_move_sound(is_capture)
		clear_suggestion()

		if is_promo:
			if not is_bot:
				is_animating = true
				is_interactive = false
				var chosen_type: String = "q"
				if promotion_popup:
					chosen_type = await promotion_popup.open_promotion(mover_is_white, piece_textures)
				if not is_inside_tree() or rules.history.is_empty():
					is_animating = false
					return

				var final_char = chosen_type.to_upper() if mover_is_white else chosen_type.to_lower()
				rules.set_piece_at(to_pos, final_char)
				move_info.piece = final_char
				move_info.promotion_piece = final_char
				pieces_by_square[to_sq] = final_char
				if square_pieces.has(to_sq):
					var to_p = square_pieces[to_sq]
					if to_p is ChessPiece:
						to_p.set_piece_key(final_char, piece_textures.get(final_char, null))
						to_p.play_landing()
				update_check_highlight()
				play_move_sound(false)
				is_animating = false
				is_interactive = interactable
			elif promo_choice != "":
				var final_char = promo_choice.to_upper() if mover_is_white else promo_choice.to_lower()
				rules.set_piece_at(to_pos, final_char)
				move_info.piece = final_char
				move_info.promotion_piece = final_char
				pieces_by_square[to_sq] = final_char
				if square_pieces.has(to_sq):
					var to_p = square_pieces[to_sq]
					if to_p is ChessPiece:
						to_p.set_piece_key(final_char, piece_textures.get(final_char, null))
						to_p.play_landing()
				update_check_highlight()
				play_move_sound(false)

		is_animating = false
		_reconcile_visual_pieces_with_rules(_active_castling_rook_sq)
		move_completed.emit(from_sq, to_sq)
		turn_completed.emit(move_info, rules.get_game_state())

	_pending_anim_finalize = finalize_move
	ghost_piece.animate_move_to(to_ctrl.global_position, func():
		if _pending_anim_finalize == finalize_move:
			finalize_move.call()
	)

func _animate_rook_castling(r_from: String, r_to: String) -> void:
	if not square_pieces.has(r_from) or not square_controls.has(r_to):
		return
	var rook_p = pieces_by_square.get(r_from, "")
	if rook_p == "":
		rook_p = "R" if r_from.ends_with("1") else "r"
	pieces_by_square.erase(r_from)
	pieces_by_square[r_to] = rook_p
	_active_castling_rook_sq = r_to

	var from_ctrl = square_controls[r_from]
	var to_ctrl = square_controls[r_to]
	var rook_node = square_pieces[r_from]
	if rook_node is ChessPiece: rook_node.clear_piece()

	var ghost: ChessPiece = CHESS_PIECE_SCENE.instantiate()
	ghost.top_level = true
	ghost.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ghost.mouse_filter = MOUSE_FILTER_IGNORE
	animation_layer.add_child(ghost)
	ghost.set_piece_size(from_ctrl.size)
	ghost.set_piece_key(rook_p, piece_textures.get(rook_p, null))
	ghost.global_position = from_ctrl.global_position

	ghost.animate_move_to(to_ctrl.global_position, func():
		if is_instance_valid(ghost):
			ghost.queue_free()
		_active_castling_rook_sq = ""
		if square_pieces.has(r_to):
			var target_p = square_pieces[r_to]
			if target_p is ChessPiece:
				target_p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				target_p.scale = Vector2.ONE
				target_p.set_piece_key(rook_p, piece_textures.get(rook_p, null))
				target_p.play_landing()
		_reconcile_visual_pieces_with_rules()
	)

func execute_bot_move(from_sq: String, to_sq: String, promo_choice: String = "q") -> void:
	if not square_pieces.has(from_sq) or not square_controls.has(to_sq):
		return
	set_interactive(false)
	is_drag_move = false
	make_move(from_sq, to_sq, true, true, promo_choice)

func play_move_sound(is_capture: bool = false) -> void:
	if is_capture:
		if sfx_capture and sfx_capture.stream:
			# Modulación sutil de pitch para impacto suave y orgánico de plastilina
			sfx_capture.pitch_scale = randf_range(0.96, 1.04)
			sfx_capture.volume_db = -6.0
			sfx_capture.play()
	else:
		if sfx_move and sfx_move.stream:
			# Impacto acústico sutil y cálido
			sfx_move.pitch_scale = randf_range(0.95, 1.05)
			sfx_move.volume_db = -8.0
			sfx_move.play()

func play_victory_sound() -> void:
	if sfx_victory and sfx_victory.stream:
		sfx_victory.play()

func play_check_sound() -> void:
	if sfx_check and sfx_check.stream:
		sfx_check.pitch_scale = randf_range(0.98, 1.02)
		sfx_check.volume_db = -6.0
		sfx_check.play()

func play_click_sound() -> void:
	if sfx_click and sfx_click.stream:
		sfx_click.pitch_scale = randf_range(0.97, 1.03)
		sfx_click.volume_db = -10.0
		sfx_click.play()
