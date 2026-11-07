class_name MatchEndEffectsOverlay
extends Control

## Capa de efectos visuales de pantalla completa para fin de partida:
## 1. Victoria (¡Lyanna gana!): Cañones de confeti multicolor, serpentinas y destellos dorados.
## 2. Derrota (Ánimo / Fin de partida): Lluvia suave de plumitas de pollito y corazoncitos de apoyo.

enum EffectType { NONE, VICTORY_CONFETTI, DEFEAT_FEATHERS, DEFEAT_RAIN }

var current_effect: EffectType = EffectType.NONE
var particles: Array[Dictionary] = []
var effect_timer: float = 0.0
var effect_duration: float = 5.0
var is_active: bool = false

# Paleta festiva para confeti de victoria
const CONFETTI_COLORS: Array[Color] = [
	Color(0.96, 0.25, 0.44), # Rosa fucsia
	Color(1.0, 0.78, 0.15),  # Dorado brillante
	Color(0.22, 0.74, 0.97), # Celeste cielo
	Color(0.66, 0.33, 0.97), # Lavanda púrpura
	Color(0.10, 0.75, 0.50), # Verde menta esmeralda
	Color(1.0, 0.55, 0.35),  # Naranja durazno
	Color(0.98, 0.90, 0.30)   # Amarillo canario
]

# Paleta cálida para plumitas de Pollito
const FEATHER_COLORS: Array[Color] = [
	Color(1.0, 0.93, 0.55),  # Amarillo pollito suave
	Color(0.98, 0.98, 1.0),   # Blanco plumita
	Color(1.0, 0.86, 0.50),  # Crema cálido
	Color(0.95, 0.90, 0.65)   # Vainilla pastel
]

const HEART_COLORS: Array[Color] = [
	Color(0.96, 0.45, 0.65), # Rosa pastel
	Color(0.98, 0.75, 0.35), # Ámbar suave
	Color(0.90, 0.55, 0.85)  # Lila tierno
]

const CHERRY_FONT = preload("res://assets/fonts/CherryBombOne-Regular.ttf")

var check_banner_container: Control = null
var check_banner_panel: PanelContainer = null
var check_banner_label: Label = null
var check_banner_tween: Tween = null

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 120 # Visible sobre tablero y paneles, sin interferir con ventanas modales críticas
	_setup_check_banner()

func _setup_check_banner() -> void:
	check_banner_container = Control.new()
	check_banner_container.name = "CheckBannerContainer"
	check_banner_container.mouse_filter = MOUSE_FILTER_IGNORE
	check_banner_container.visible = false
	add_child(check_banner_container)

	check_banner_panel = PanelContainer.new()
	check_banner_panel.name = "CheckBannerPanel"
	check_banner_panel.mouse_filter = MOUSE_FILTER_IGNORE
	check_banner_container.add_child(check_banner_panel)

	var margin = MarginContainer.new()
	margin.mouse_filter = MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	check_banner_panel.add_child(margin)

	check_banner_label = Label.new()
	check_banner_label.mouse_filter = MOUSE_FILTER_IGNORE
	check_banner_label.add_theme_font_override("font", CHERRY_FONT)
	check_banner_label.add_theme_font_size_override("font_size", 26)
	check_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	margin.add_child(check_banner_label)

func _get_screen_size() -> Vector2:
	if is_inside_tree() and get_viewport():
		return get_viewport_rect().size
	return size if size != Vector2.ZERO else Vector2(1280, 720)

func _process(delta: float) -> void:
	if not is_active:
		return

	effect_timer += delta
	var vp_size = _get_screen_size()

	match current_effect:
		EffectType.VICTORY_CONFETTI:
			_update_confetti(delta, vp_size)
		EffectType.DEFEAT_FEATHERS:
			_update_feathers(delta, vp_size)
		EffectType.DEFEAT_RAIN:
			_update_rain(delta, vp_size)

	queue_redraw()

	if particles.is_empty() or effect_timer >= effect_duration:
		clear_effects()

func play_victory_effect() -> void:
	clear_effects()
	current_effect = EffectType.VICTORY_CONFETTI
	is_active = true
	effect_timer = 0.0
	effect_duration = 5.5

	var vp_size = _get_screen_size()
	particles.clear()

	# 1. Cañones laterales inferiores (explosión hacia arriba y hacia adentro)
	# Cañón Izquierdo
	for i in range(50):
		particles.append(_create_confetti_particle(
			Vector2(vp_size.x * 0.08, vp_size.y * 0.95),
			Vector2(randf_range(250.0, 650.0), -randf_range(650.0, 1100.0)),
			false
		))

	# Cañón Derecho
	for i in range(50):
		particles.append(_create_confetti_particle(
			Vector2(vp_size.x * 0.92, vp_size.y * 0.95),
			Vector2(-randf_range(250.0, 650.0), -randf_range(650.0, 1100.0)),
			false
		))

	# 2. Lluvia suave superior para llenar la pantalla
	for i in range(35):
		particles.append(_create_confetti_particle(
			Vector2(randf_range(0.0, vp_size.x), randf_range(-150.0, 0.0)),
			Vector2(randf_range(-60.0, 60.0), randf_range(120.0, 260.0)),
			true
		))

	# 3. Estrellitas doradas brillantes
	for i in range(25):
		particles.append({
			"type": "star",
			"pos": Vector2(randf_range(vp_size.x * 0.1, vp_size.x * 0.9), randf_range(-100.0, vp_size.y * 0.4)),
			"vel": Vector2(randf_range(-20.0, 20.0), randf_range(40.0, 90.0)),
			"size": randf_range(7.0, 14.0),
			"rot": randf_range(0.0, TAU),
			"rot_speed": randf_range(-2.0, 2.0),
			"color": Color(1.0, 0.85, 0.2),
			"life": randf_range(4.0, 5.2),
			"max_life": 5.2,
			"phase": randf_range(0.0, TAU)
		})

func play_defeat_effect(style: String = "feathers") -> void:
	clear_effects()
	is_active = true
	effect_timer = 0.0
	effect_duration = 5.5
	var vp_size = _get_screen_size()

	if style == "rain":
		current_effect = EffectType.DEFEAT_RAIN
		for i in range(70):
			particles.append({
				"pos": Vector2(randf_range(-100.0, vp_size.x + 100.0), randf_range(-300.0, vp_size.y)),
				"speed": randf_range(400.0, 700.0),
				"len": randf_range(16.0, 28.0),
				"color": Color(0.4, 0.7, 0.95, randf_range(0.35, 0.75)),
				"life": randf_range(4.0, 5.2),
				"max_life": 5.2
			})
		return

	# Estilo por defecto y recomendado: Lluvia de Plumitas Cálidas de Pollito + Corazoncitos
	current_effect = EffectType.DEFEAT_FEATHERS
	# 1. Plumitas suaves meciéndose
	for i in range(40):
		particles.append({
			"type": "feather",
			"pos": Vector2(randf_range(0.0, vp_size.x), randf_range(-250.0, -10.0)),
			"vel_y": randf_range(65.0, 125.0),
			"sway_amp": randf_range(35.0, 75.0),
			"sway_freq": randf_range(1.5, 2.8),
			"sway_phase": randf_range(0.0, TAU),
			"size": randf_range(16.0, 26.0),
			"rot": randf_range(-0.5, 0.5),
			"color": FEATHER_COLORS[randi() % FEATHER_COLORS.size()],
			"life": randf_range(4.2, 5.4),
			"max_life": 5.4
		})

	# 2. Corazoncitos de apoyo y aliento flotando hacia arriba o meciéndose
	for i in range(16):
		particles.append({
			"type": "heart",
			"pos": Vector2(randf_range(vp_size.x * 0.15, vp_size.x * 0.85), randf_range(vp_size.y * 0.5, vp_size.y + 100.0)),
			"vel_y": -randf_range(40.0, 90.0),
			"sway_amp": randf_range(20.0, 45.0),
			"sway_freq": randf_range(1.2, 2.2),
			"sway_phase": randf_range(0.0, TAU),
			"size": randf_range(12.0, 18.0),
			"color": HEART_COLORS[randi() % HEART_COLORS.size()],
			"life": randf_range(3.8, 5.0),
			"max_life": 5.0
		})

func show_check_banner(is_player_attack: bool, custom_text: String = "") -> void:
	if not check_banner_container:
		_setup_check_banner()

	if check_banner_tween:
		check_banner_tween.kill()

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(24)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 5
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	style.shadow_color = Color(0, 0, 0, 0.38)

	if custom_text != "":
		check_banner_label.text = custom_text
	elif is_player_attack:
		check_banner_label.text = "⚔️ ¡JAQUE AL REY! ⚔️"
	else:
		check_banner_label.text = "⚠️ ¡JAQUE A TU REY! ⚠️"

	if is_player_attack:
		style.bg_color = Color("#065f46") # Esmeralda intenso
		style.border_color = Color("#f59e0b") # Oro festivo
		check_banner_label.add_theme_color_override("font_color", Color("#ffffff"))
		check_banner_label.add_theme_color_override("font_shadow_color", Color("#064e3b"))
	else:
		style.bg_color = Color("#991b1b") # Rojo carmesí intenso
		style.border_color = Color("#fde047") # Amarillo advertencia
		check_banner_label.add_theme_color_override("font_color", Color("#ffffff"))
		check_banner_label.add_theme_color_override("font_shadow_color", Color("#450a0a"))

	check_banner_panel.add_theme_stylebox_override("panel", style)

	var vp_size = _get_screen_size()
	check_banner_container.reset_size()
	check_banner_panel.reset_size()

	var min_sz = check_banner_panel.get_combined_minimum_size()
	check_banner_container.pivot_offset = min_sz * 0.5
	check_banner_container.position = Vector2(vp_size.x * 0.5 - min_sz.x * 0.5, vp_size.y * 0.08)
	check_banner_container.scale = Vector2(0.2, 0.2)
	check_banner_container.modulate.a = 0.0
	check_banner_container.visible = true

	# Animación elástica de entrada y salida
	check_banner_tween = create_tween()
	check_banner_tween.set_parallel(true)
	check_banner_tween.tween_property(check_banner_container, "modulate:a", 1.0, 0.22)
	check_banner_tween.tween_property(check_banner_container, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	check_banner_tween.set_parallel(false)
	check_banner_tween.tween_interval(1.5)
	check_banner_tween.set_parallel(true)
	check_banner_tween.tween_property(check_banner_container, "modulate:a", 0.0, 0.3)
	check_banner_tween.tween_property(check_banner_container, "scale", Vector2(1.15, 1.15), 0.3)
	check_banner_tween.set_parallel(false)
	check_banner_tween.tween_callback(func():
		if check_banner_container: check_banner_container.visible = false
	)

func clear_effects() -> void:
	current_effect = EffectType.NONE
	particles.clear()
	is_active = false
	effect_timer = 0.0
	if check_banner_tween:
		check_banner_tween.kill()
		check_banner_tween = null
	if check_banner_container:
		check_banner_container.visible = false
	queue_redraw()

# ==============================================================================
# CREACIÓN Y ACTUALIZACIÓN DE PARTÍCULAS
# ==============================================================================

func _create_confetti_particle(pos: Vector2, vel: Vector2, from_top: bool) -> Dictionary:
	var shape_rand = randf()
	var shape_type = "rect"
	if shape_rand > 0.75:
		shape_type = "circle"
	elif shape_rand > 0.60:
		shape_type = "ribbon"

	return {
		"type": "confetti",
		"shape": shape_type,
		"pos": pos,
		"vel": vel,
		"gravity": randf_range(450.0, 650.0) if not from_top else randf_range(120.0, 220.0),
		"drag": randf_range(0.975, 0.988),
		"sway_amp": randf_range(20.0, 50.0),
		"sway_freq": randf_range(2.0, 4.5),
		"sway_phase": randf_range(0.0, TAU),
		"flip_phase": randf_range(0.0, TAU),
		"flip_speed": randf_range(3.0, 8.0),
		"rot": randf_range(0.0, TAU),
		"rot_speed": randf_range(-5.0, 5.0),
		"size": Vector2(randf_range(8.0, 14.0), randf_range(12.0, 20.0)),
		"color": CONFETTI_COLORS[randi() % CONFETTI_COLORS.size()],
		"life": randf_range(4.0, 5.4),
		"max_life": 5.4
	}

func _update_confetti(delta: float, vp_size: Vector2) -> void:
	var i = particles.size() - 1
	while i >= 0:
		var p = particles[i]
		p["life"] -= delta
		if p["life"] <= 0.0:
			particles.remove_at(i)
			i -= 1
			continue

		if p.get("type", "") == "star":
			p["pos"] += p["vel"] * delta
			p["rot"] += p["rot_speed"] * delta
			p["phase"] += delta * 4.0
		else:
			p["vel"].y += p["gravity"] * delta
			p["vel"] *= p["drag"]
			p["pos"] += p["vel"] * delta
			p["sway_phase"] += delta * p["sway_freq"]
			p["pos"].x += sin(p["sway_phase"]) * (p["sway_amp"] * delta)
			p["rot"] += p["rot_speed"] * delta
			p["flip_phase"] += delta * p["flip_speed"]

		i -= 1

func _update_feathers(delta: float, vp_size: Vector2) -> void:
	var i = particles.size() - 1
	while i >= 0:
		var p = particles[i]
		p["life"] -= delta
		if p["life"] <= 0.0:
			particles.remove_at(i)
			i -= 1
			continue

		p["sway_phase"] += delta * p["sway_freq"]
		var horiz_drift = cos(p["sway_phase"]) * p["sway_amp"] * delta

		if p["type"] == "feather":
			p["pos"].y += p["vel_y"] * delta
			p["pos"].x += horiz_drift
			# Rotación sincronizada con el balanceo del viento
			p["rot"] = sin(p["sway_phase"]) * 0.45
		elif p["type"] == "heart":
			p["pos"].y += p["vel_y"] * delta
			p["pos"].x += horiz_drift * 0.6

		i -= 1

func _update_rain(delta: float, vp_size: Vector2) -> void:
	var i = particles.size() - 1
	while i >= 0:
		var p = particles[i]
		p["life"] -= delta
		if p["life"] <= 0.0:
			particles.remove_at(i)
			i -= 1
			continue

		p["pos"].y += p["speed"] * delta
		p["pos"].x += (p["speed"] * 0.18) * delta # Inclinación diagonal ligera

		if p["pos"].y > vp_size.y + 40.0:
			p["pos"].y = randf_range(-100.0, -20.0)
			p["pos"].x = randf_range(-50.0, vp_size.x)

		i -= 1

# ==============================================================================
# RENDERIZADO VISUAL (_draw)
# ==============================================================================

func _draw() -> void:
	if not is_active:
		return

	match current_effect:
		EffectType.VICTORY_CONFETTI:
			_draw_confetti()
		EffectType.DEFEAT_FEATHERS:
			_draw_feathers_and_hearts()
		EffectType.DEFEAT_RAIN:
			_draw_rain()

func _draw_confetti() -> void:
	for p in particles:
		var alpha = clampf(p["life"] / 1.2, 0.0, 1.0)
		var c = p["color"]
		c.a *= alpha

		if p.get("type", "") == "star":
			var star_twinkle = 0.7 + 0.3 * sin(p["phase"])
			c.a *= star_twinkle
			_draw_star(p["pos"], p["size"] * star_twinkle, p["rot"], c)
			continue

		var flip = absf(cos(p["flip_phase"]))
		draw_set_transform(p["pos"], p["rot"], Vector2(flip, 1.0))

		var sz: Vector2 = p["size"]
		var half_sz = sz * 0.5

		if p["shape"] == "circle":
			draw_circle(Vector2.ZERO, half_sz.x, c)
		elif p["shape"] == "ribbon":
			draw_rect(Rect2(-half_sz.x * 0.6, -half_sz.y * 1.4, sz.x * 0.6, sz.y * 1.4), c, true)
		else:
			draw_rect(Rect2(-half_sz.x, -half_sz.y, sz.x, sz.y), c, true)

		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_feathers_and_hearts() -> void:
	for p in particles:
		var alpha = clampf(p["life"] / 1.4, 0.0, 1.0)
		var c = p["color"]
		c.a *= alpha

		if p["type"] == "feather":
			draw_set_transform(p["pos"], p["rot"], Vector2.ONE)
			_draw_feather_shape(p["size"], c)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif p["type"] == "heart":
			draw_set_transform(p["pos"], 0.0, Vector2.ONE)
			_draw_heart_shape(p["size"], c)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_feather_shape(sz: float, c: Color) -> void:
	# Plumita estilizada y esponjosa
	var h = sz * 1.6
	var w = sz * 0.6

	# Tallo central suave
	var stem_c = Color(1.0, 1.0, 1.0, c.a * 0.9)
	draw_line(Vector2(0, -h * 0.5), Vector2(0, h * 0.5), stem_c, 1.5)

	# Vane / Cuerpo de la pluma (polígono suave curvado)
	var pts: PackedVector2Array = [
		Vector2(0, -h * 0.5),
		Vector2(w * 0.7, -h * 0.25),
		Vector2(w, 0.0),
		Vector2(w * 0.6, h * 0.3),
		Vector2(0, h * 0.5),
		Vector2(-w * 0.6, h * 0.3),
		Vector2(-w, 0.0),
		Vector2(-w * 0.7, -h * 0.25)
	]
	draw_colored_polygon(pts, c)

	# Borde sutil y suave
	var outline_c = Color(c.r * 0.9, c.g * 0.85, c.b * 0.7, c.a * 0.8)
	draw_polyline(pts, outline_c, 1.0)

func _draw_heart_shape(sz: float, c: Color) -> void:
	# Corazoncito tierno kawaii
	var r = sz * 0.35
	# Dos lóbulos circulares superiores
	draw_circle(Vector2(-r * 0.9, -r * 0.4), r, c)
	draw_circle(Vector2(r * 0.9, -r * 0.4), r, c)

	# Triángulo inferior que une la punta
	var pts: PackedVector2Array = [
		Vector2(-r * 1.8, -r * 0.3),
		Vector2(r * 1.8, -r * 0.3),
		Vector2(0, r * 1.8)
	]
	draw_colored_polygon(pts, c)

func _draw_star(pos: Vector2, r: float, rot: float, c: Color) -> void:
	draw_set_transform(pos, rot, Vector2.ONE)
	# Estrella de 4 puntas estilizada (brillo mágico)
	var inner = r * 0.3
	var pts: PackedVector2Array = [
		Vector2(0, -r),
		Vector2(inner, -inner),
		Vector2(r, 0),
		Vector2(inner, inner),
		Vector2(0, r),
		Vector2(-inner, inner),
		Vector2(-r, 0),
		Vector2(-inner, -inner)
	]
	draw_colored_polygon(pts, c)
	draw_circle(Vector2.ZERO, inner * 0.6, Color(1.0, 1.0, 0.9, c.a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_rain() -> void:
	for p in particles:
		var alpha = clampf(p["life"] / 1.0, 0.0, 1.0)
		var c = p["color"]
		c.a *= alpha
		var dir = Vector2(0.18, 1.0).normalized()
		draw_line(p["pos"], p["pos"] + dir * p["len"], c, 2.0)
