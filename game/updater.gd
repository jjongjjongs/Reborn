extends CanvasLayer
## In-app update check (tier 1). Reads the public GitHub release, compares the
## latest reborn-vN.apk against this build's code, and (if newer) opens the APK
## download in the browser to install. No special install permission needed.

signal checked(has_update: bool, latest: int)

const API := "https://api.github.com/repos/jjongjjongs/Reborn/releases/tags/game-latest"

var _http: HTTPRequest
var _latest := 0
var _url := ""
var _has := false
var _done := false
var _dialog: Control
var _title: Label
var _body: Label
var _getbtn: Button

func _ready() -> void:
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_done)
	_build()
	_dialog.visible = false

func installed() -> int:
	return int(ProjectSettings.get_setting("application/config/build_code", 0))

func refresh() -> void:
	_http.cancel_request()
	var err := _http.request(API, PackedStringArray([
		"User-Agent: RebornGame", "Accept: application/vnd.github+json"]))
	if err != OK:
		_fail(-1)

func show_dialog() -> void:
	Sfx.play("ui")
	_dialog.visible = true
	if _done:
		_render()
	else:
		_title.text = "업데이트 확인 중…"
		_body.text = ""
		_getbtn.visible = false
		refresh()

func _fail(code: int) -> void:
	_done = true; _latest = 0; _has = false; _url = ""
	if _dialog.visible:
		_title.text = "확인 실패"
		_body.text = "네트워크를 확인하고 다시 시도해 주세요. (%d)" % code
		_getbtn.visible = false
	checked.emit(false, 0)

func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail(code)
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	var best := 0
	var besturl := ""
	if typeof(data) == TYPE_DICTIONARY and data.has("assets"):
		var re := RegEx.create_from_string("reborn-v(\\d+)\\.apk")
		for a in data["assets"]:
			var m := re.search(str(a.get("name", "")))
			if m:
				var n := int(m.get_string(1))
				if n > best:
					best = n
					besturl = str(a.get("browser_download_url", ""))
	_done = true
	_latest = best
	_url = besturl
	_has = best > installed()
	if _dialog.visible:
		_render()
	checked.emit(_has, _latest)

func _render() -> void:
	var inst := installed()
	if _has:
		_title.text = "새 버전 v%d 있음" % _latest
		_body.text = "현재 v%d → 최신 v%d\n받기를 누르면 브라우저에서 APK를 내려받아 설치합니다." % [inst, _latest]
		_getbtn.visible = _url != ""
	else:
		_title.text = "최신 버전"
		_body.text = "현재 v%d 가 최신입니다." % inst
		_getbtn.visible = false

func _build() -> void:
	_dialog = Control.new()
	_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new(); bg.color = Color(0.04, 0.06, 0.08, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT); bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_dialog.add_child(bg)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5; panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -260; panel.offset_right = 260; panel.offset_top = -150; panel.offset_bottom = 150
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.09, 0.12, 0.15)
	sb.set_border_width_all(1); sb.border_color = Color(0.18, 0.22, 0.26)
	sb.set_corner_radius_all(16); sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", sb)
	_dialog.add_child(panel)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 14); v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	_title = Label.new(); _title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title)
	_body = Label.new(); _body.add_theme_font_size_override("font_size", 20)
	_body.add_theme_color_override("font_color", Color(0.75, 0.82, 0.88))
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_body)
	var h := HBoxContainer.new(); h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 12)
	_getbtn = _mk("받기", true, func() -> void:
		if _url != "": OS.shell_open(_url))
	h.add_child(_mk("닫기", false, func() -> void: _dialog.visible = false))
	h.add_child(_getbtn)
	v.add_child(h)
	add_child(_dialog)

func _mk(txt: String, pri: bool, cb: Callable) -> Button:
	var b := Button.new(); b.text = txt; b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 24)
	b.custom_minimum_size = Vector2(150, 56)
	if pri:
		b.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	b.pressed.connect(cb)
	return b
