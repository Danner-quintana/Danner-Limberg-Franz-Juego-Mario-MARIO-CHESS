extends RefCounted
# Estilos compartidos de los menús: botones, títulos y panel.

const VERDE := Color(0.18, 0.68, 0.3)
const AZUL := Color(0.2, 0.5, 0.95)
const ROJO := Color(0.86, 0.25, 0.25)
const NARANJA := Color(0.95, 0.6, 0.15)
const GRIS := Color(0.42, 0.44, 0.52)
const DORADO := Color(1.0, 0.82, 0.2)

static func caja(color: Color, extra_abajo: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = color.darkened(0.5)
	s.set_border_width_all(3)
	s.border_width_bottom = 3 + extra_abajo
	s.set_corner_radius_all(14)
	s.set_content_margin_all(8)
	return s

static func boton(b: Button, color: Color) -> void:
	b.custom_minimum_size = Vector2(340, 54)
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	b.add_theme_constant_override("outline_size", 4)
	b.add_theme_stylebox_override("normal", caja(color))
	b.add_theme_stylebox_override("hover", caja(color.lightened(0.2)))
	b.add_theme_stylebox_override("pressed", caja(color.darkened(0.15), 2))
	b.add_theme_stylebox_override("disabled", caja(GRIS.darkened(0.45)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

static func titulo(l: Label, tam: int, color: Color) -> void:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 12)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	l.add_theme_constant_override("shadow_offset_x", 4)
	l.add_theme_constant_override("shadow_offset_y", 4)

static func panel_caja() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.1, 0.24, 0.94)
	s.border_color = DORADO
	s.set_border_width_all(4)
	s.set_corner_radius_all(22)
	s.set_content_margin_all(30)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 14
	return s
