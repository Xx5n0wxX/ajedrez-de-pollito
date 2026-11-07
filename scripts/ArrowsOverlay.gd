class_name ArrowsOverlay
extends Control

## Capa de flechas tácticas translúcidas estilo Chess.com.
## Permite dibujar flechas arrastrando el botón derecho del ratón y limpiarlas con clic izquierdo.

var arrows: Array[Dictionary] = [] # [{start: Vector2, end: Vector2}]
var current_arrow_start: Vector2 = Vector2(-1, -1)
var current_mouse_pos: Vector2 = Vector2.ZERO
var arrow_color: Color = Color(1.0, 0.64, 0.0, 0.6) # Naranja translúcido

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchors_preset = Control.PRESET_FULL_RECT
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func add_arrow(start_pos: Vector2, end_pos: Vector2) -> void:
	add_arrow_with_color(start_pos, end_pos, arrow_color, false)

func add_arrow_with_color(start_pos: Vector2, end_pos: Vector2, col: Color, is_suggestion: bool = false) -> void:
	if start_pos == end_pos:
		return
	# Si ya existe una flecha idéntica, la alternamos (toggle estilo Chess.com)
	for i in range(arrows.size() - 1, -1, -1):
		if arrows[i].start.distance_to(start_pos) < 4.0 and arrows[i].end.distance_to(end_pos) < 4.0:
			arrows.remove_at(i)
			queue_redraw()
			return
	arrows.append({"start": start_pos, "end": end_pos, "color": col, "is_suggestion": is_suggestion})
	queue_redraw()

func clear_user_arrows() -> void:
	var changed: bool = false
	for i in range(arrows.size() - 1, -1, -1):
		if not arrows[i].get("is_suggestion", false):
			arrows.remove_at(i)
			changed = true
	current_arrow_start = Vector2(-1, -1)
	if changed:
		queue_redraw()

func clear_suggestion_arrows() -> void:
	var changed: bool = false
	for i in range(arrows.size() - 1, -1, -1):
		if arrows[i].get("is_suggestion", false):
			arrows.remove_at(i)
			changed = true
	if changed:
		queue_redraw()

func clear_arrows() -> void:
	arrows.clear()
	current_arrow_start = Vector2(-1, -1)
	queue_redraw()

func has_user_arrows() -> bool:
	for a in arrows:
		if not a.get("is_suggestion", false):
			return true
	return false

func has_suggestion_arrow() -> bool:
	for a in arrows:
		if a.get("is_suggestion", false):
			return true
	return false

func _draw() -> void:
	var head_length = 22.0
	var head_width = 16.0
	var line_width = 12.0

	for arrow in arrows:
		var c: Color = arrow.get("color", arrow_color)
		_draw_single_arrow(arrow.start, arrow.end, line_width, head_length, head_width, c)

	if current_arrow_start != Vector2(-1, -1):
		_draw_single_arrow(current_arrow_start, current_mouse_pos, line_width, head_length, head_width, arrow_color)

func _draw_single_arrow(start_v: Vector2, end_v: Vector2, l_width: float, h_length: float, h_width: float, c: Color = arrow_color) -> void:
	var total_dist = start_v.distance_to(end_v)
	if total_dist < 8.0:
		return

	# Distancias absolutas en X e Y
	var dx = absf(end_v.x - start_v.x)
	var dy = absf(end_v.y - start_v.y)

	# Tolerancia de 16 píxeles para el arrastre dinámico del mouse.
	# Si es casi horizontal, vertical o diagonal, se traza como flecha recta.
	var is_straight = (dx < 16.0) or (dy < 16.0) or (absf(dx - dy) < 16.0)

	var points: PackedVector2Array

	if is_straight:
		points = _build_straight_arrow_polygon(start_v, end_v, l_width, h_length, h_width)
	else:
		# Trazo en forma de L (Caballo)
		var elbow: Vector2
		if dy > dx:
			elbow = Vector2(start_v.x, end_v.y)
		else:
			elbow = Vector2(end_v.x, start_v.y)

		points = _build_l_arrow_polygon(start_v, elbow, end_v, l_width, h_length, h_width)

	if points.size() >= 3:
		draw_colored_polygon(points, c)
		var outline = points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, c, 1.0, true)

func _build_straight_arrow_polygon(start_v: Vector2, end_v: Vector2, l_width: float, h_length: float, h_width: float) -> PackedVector2Array:
	var total_dist = start_v.distance_to(end_v)
	var dir = (end_v - start_v).normalized()
	var normal = Vector2(-dir.y, dir.x)
	var sw = l_width * 0.5

	if total_dist <= h_length:
		return PackedVector2Array([
			end_v,
			end_v - dir * total_dist + normal * h_width,
			end_v - dir * total_dist - normal * h_width
		])

	var base_pt = end_v - dir * h_length
	return PackedVector2Array([
		start_v - normal * sw,
		base_pt - normal * sw,
		base_pt - normal * h_width,
		end_v,
		base_pt + normal * h_width,
		base_pt + normal * sw,
		start_v + normal * sw
	])

func _build_l_arrow_polygon(start_v: Vector2, elbow: Vector2, end_v: Vector2, l_width: float, h_length: float, h_width: float) -> PackedVector2Array:
	var dir1 = (elbow - start_v).normalized()
	var dir2 = (end_v - elbow).normalized()
	var normal1 = Vector2(-dir1.y, dir1.x)
	var normal2 = Vector2(-dir2.y, dir2.x)
	var sw = l_width * 0.5
	var seg2_dist = elbow.distance_to(end_v)

	var turn = dir1.cross(dir2) # >0 = giro a la derecha, <0 = giro a la izquierda
	var base_pt = end_v - dir2 * minf(h_length, seg2_dist)

	var pts = PackedVector2Array()

	# 1. Base inicial lado izquierdo
	pts.append(start_v - normal1 * sw)

	# 2. Esquina del codo lado izquierdo
	if turn > 0:
		# Esquina exterior izquierda: biselado suave de 2 puntos
		pts.append(elbow - normal1 * sw)
		pts.append(elbow - normal2 * sw)
	else:
		# Esquina interior izquierda: intersección exacta
		pts.append(elbow + dir1 * (sw * turn) - dir2 * (sw * turn))

	# 3. Cabeza de la flecha
	pts.append(base_pt - normal2 * sw)
	pts.append(base_pt - normal2 * h_width)
	pts.append(end_v)
	pts.append(base_pt + normal2 * h_width)
	pts.append(base_pt + normal2 * sw)

	# 4. Esquina del codo lado derecho
	if turn > 0:
		# Esquina interior derecha: intersección exacta
		pts.append(elbow - dir1 * (sw * turn) + dir2 * (sw * turn))
	else:
		# Esquina exterior derecha: biselado suave de 2 puntos
		pts.append(elbow + normal2 * sw)
		pts.append(elbow + normal1 * sw)

	# 5. Base inicial lado derecho
	pts.append(start_v + normal1 * sw)

	return pts
