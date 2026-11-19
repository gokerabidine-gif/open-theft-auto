class_name TouchHUD
extends CanvasLayer
## GTA-style mobile layout: left movement stick, right camera drag and
## separate action controls arranged around the right edge.

signal action(name: StringName)

var stick: Vector2 = Vector2.ZERO
var look_rel: Vector2 = Vector2.ZERO
var sprint_held: bool = false
var fire_held: bool = false
var aim_touch_held: bool = false
var alt_fire_touch_held: bool = false

const LOOK_SENS := 0.48
const SPRINT_THRESHOLD := 0.88

var _stick_touch := -1
var _stick_base: Vector2 = Vector2.ZERO
var _stick_knob: Vector2 = Vector2.ZERO
var _look_touch := -1
var _fire_touch := -1
var _aim_touch := -1
var _alt_touch := -1
var _sprint_touch := -1

var _stick_radius := 92.0
var _button_radius := 42.0
var _fire_radius := 66.0

var _btn_fire := Vector2.ZERO
var _btn_aim := Vector2.ZERO
var _btn_melee := Vector2.ZERO
var _btn_sprint := Vector2.ZERO
var _btn_interact := Vector2.ZERO
var _btn_vehicle := Vector2.ZERO
var _btn_next := Vector2.ZERO
var _btn_prev := Vector2.ZERO
var _btn_suit := Vector2.ZERO
var _btn_phone := Vector2.ZERO

var _pad: Control


class TouchPad extends Control:
	var hud
	func _draw() -> void:
		if hud != null:
			hud._draw_overlay(self)


func _ready() -> void:
	layer = 30
	_pad = TouchPad.new()
	_pad.hud = self
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pad)
	get_viewport().size_changed.connect(_resize)
	_resize()


func _process(_dt: float) -> void:
	var want := GameState.started and not GameState.paused
	if visible and not want:
		_clear_touches()
	visible = want


func _clear_touches() -> void:
	_stick_touch = -1
	_look_touch = -1
	_fire_touch = -1
	_aim_touch = -1
	_alt_touch = -1
	_sprint_touch = -1
	stick = Vector2.ZERO
	look_rel = Vector2.ZERO
	sprint_held = false
	fire_held = false
	aim_touch_held = false
	alt_fire_touch_held = false
	_stick_knob = _stick_base
	_pad.queue_redraw()


func _resize() -> void:
	var sz := get_viewport().get_visible_rect().size
	_stick_radius = clampf(sz.y * 0.105, 68.0, 108.0)
	_button_radius = clampf(sz.y * 0.047, 32.0, 48.0)
	_fire_radius = clampf(sz.y * 0.073, 48.0, 72.0)

	# GTA-like layout: movement lower-left; combat cluster on the right.
	_stick_base = Vector2(sz.x * 0.15, sz.y * 0.78)
	_btn_fire = Vector2(sz.x * 0.91, sz.y * 0.78)
	_btn_aim = Vector2(sz.x * 0.79, sz.y * 0.80)
	_btn_melee = Vector2(sz.x * 0.91, sz.y * 0.57)
	_btn_sprint = Vector2(sz.x * 0.78, sz.y * 0.58)
	_btn_interact = Vector2(sz.x * 0.91, sz.y * 0.94)
	_btn_vehicle = Vector2(sz.x * 0.78, sz.y * 0.94)
	_btn_next = Vector2(sz.x * 0.66, sz.y * 0.70)
	_btn_prev = Vector2(sz.x * 0.66, sz.y * 0.84)
	_btn_suit = Vector2(sz.x * 0.91, sz.y * 0.39)
	_btn_phone = Vector2(sz.x * 0.78, sz.y * 0.39)
	if _stick_touch < 0:
		_stick_knob = _stick_base
	_pad.queue_redraw()


func consume_look_rel() -> Vector2:
	var r := look_rel
	look_rel = Vector2.ZERO
	return r


func _input(event: InputEvent) -> void:
	if not visible:
		if event is InputEventScreenTouch and not event.pressed:
			_release(event.index)
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index, event.position)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position, event.relative)


func _press(idx: int, pos: Vector2) -> void:
	# Hold controls are checked before tap controls.
	if pos.distance_to(_btn_fire) <= _fire_radius:
		fire_held = true
		_fire_touch = idx
		_pad.queue_redraw()
		return
	if pos.distance_to(_btn_aim) <= _button_radius:
		aim_touch_held = true
		_aim_touch = idx
		_pad.queue_redraw()
		return
	if pos.distance_to(_btn_sprint) <= _button_radius:
		sprint_held = true
		_sprint_touch = idx
		_pad.queue_redraw()
		return

	if pos.distance_to(_btn_melee) <= _button_radius:
		action.emit(&"melee")
		return
	if pos.distance_to(_btn_interact) <= _button_radius:
		action.emit(&"interact")
		return
	if pos.distance_to(_btn_vehicle) <= _button_radius:
		action.emit(&"enter_exit")
		return
	if pos.distance_to(_btn_next) <= _button_radius:
		action.emit(&"weapon_next")
		return
	if pos.distance_to(_btn_prev) <= _button_radius:
		action.emit(&"weapon_prev")
		return
	if pos.distance_to(_btn_suit) <= _button_radius:
		action.emit(&"summon")
		return
	if pos.distance_to(_btn_phone) <= _button_radius:
		action.emit(&"phone")
		return

	var sz := get_viewport().get_visible_rect().size
	if pos.x < sz.x * 0.42 and pos.y > sz.y * 0.38 and _stick_touch < 0:
		_stick_touch = idx
		_update_stick(pos)
		return
	if pos.x >= sz.x * 0.42 and _look_touch < 0:
		_look_touch = idx


func _release(idx: int) -> void:
	if idx == _fire_touch:
		fire_held = false
		_fire_touch = -1
		_pad.queue_redraw()
	if idx == _aim_touch:
		aim_touch_held = false
		_aim_touch = -1
		_pad.queue_redraw()
	if idx == _sprint_touch:
		sprint_held = false
		_sprint_touch = -1
		_pad.queue_redraw()
	if idx == _stick_touch:
		_stick_touch = -1
		stick = Vector2.ZERO
		_stick_knob = _stick_base
		_pad.queue_redraw()
	if idx == _look_touch:
		_look_touch = -1


func _update_stick(pos: Vector2) -> void:
	var delta := pos - _stick_base
	if delta.length() > _stick_radius:
		delta = delta.normalized() * _stick_radius
	_stick_knob = _stick_base + delta
	stick = Vector2(delta.x / _stick_radius, -delta.y / _stick_radius)
	_pad.queue_redraw()


func _drag(idx: int, pos: Vector2, rel: Vector2) -> void:
	if idx == _stick_touch:
		_update_stick(pos)
	elif idx == _look_touch:
		look_rel += rel * LOOK_SENS


func _draw_overlay(pad: Control) -> void:
	pad.draw_circle(_stick_base, _stick_radius, Color(1, 1, 1, 0.12))
	pad.draw_arc(_stick_base, _stick_radius, 0.0, TAU, 48,
		Color(1, 1, 1, 0.42), 2.5)
	pad.draw_circle(_stick_knob, _stick_radius * 0.34,
		Color(0.35, 0.9, 0.75, 0.82 if _stick_touch >= 0 else 0.30))

	_draw_button(pad, _btn_fire, _fire_radius, "FIRE",
		Color(0.95, 0.20, 0.16), fire_held)
	_draw_button(pad, _btn_aim, _button_radius, "AIM",
		Color(0.95, 0.78, 0.25), aim_touch_held)
	_draw_button(pad, _btn_melee, _button_radius, "HIT",
		Color(0.90, 0.48, 0.18), false)
	_draw_button(pad, _btn_sprint, _button_radius, "RUN",
		Color(0.30, 0.72, 0.95), sprint_held)
	_draw_button(pad, _btn_interact, _button_radius, "USE",
		Color(0.25, 0.78, 0.48), false)
	_draw_button(pad, _btn_vehicle, _button_radius, "CAR",
		Color(0.30, 0.72, 0.95), false)
	_draw_button(pad, _btn_next, _button_radius * 0.82, "+",
		Color(0.45, 0.52, 0.68), false)
	_draw_button(pad, _btn_prev, _button_radius * 0.82, "-",
		Color(0.45, 0.52, 0.68), false)
	_draw_button(pad, _btn_suit, _button_radius, "SUIT",
		Color(0.55, 0.50, 0.85), false)
	_draw_button(pad, _btn_phone, _button_radius, "PHONE",
		Color(0.35, 0.62, 0.72), false)


func _draw_button(pad: Control, center: Vector2, radius: float,
		label: String, col: Color, pressed: bool) -> void:
	var fill := Color(col.r, col.g, col.b, 0.92 if pressed else 0.58)
	pad.draw_circle(center, radius, fill)
	pad.draw_arc(center, radius, 0.0, TAU, 48,
		Color(1, 1, 1, 0.82), 2.0)
	var font := ThemeDB.fallback_font
	var font_size := 19 if radius >= 46.0 else 16
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER,
		-1.0, font_size)
	pad.draw_string(font,
		center - text_size * 0.5 + Vector2(0, font_size * 0.35),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size,
		Color(1, 1, 1, 0.98))
