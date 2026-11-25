extends CanvasLayer
## Screen feedback shared across every scene (autoload): red damage vignette
## when the player is hurt, and a center hitmarker when the player lands a hit.

var _vig: ColorRect
var _hm: HitMarker
var _hurt_t := 0.0

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_vig = ColorRect.new()
	_vig.color = Color(0.85, 0.06, 0.06, 0.0)
	_vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vig)
	_hm = HitMarker.new()
	add_child(_hm)

func hurt() -> void:
	_hurt_t = 1.0

func hitmarker() -> void:
	if _hm:
		_hm.pop()

func _process(dt: float) -> void:
	if _hurt_t > 0.0:
		_hurt_t = maxf(0.0, _hurt_t - dt * 2.2)
	if _vig:
		_vig.color.a = _hurt_t * 0.42
