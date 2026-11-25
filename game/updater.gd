extends CanvasLayer
## In-app updater (tier 2). Reads the public GitHub release, compares the latest
## reborn-vN.apk with this build's code, downloads it INSIDE the app (progress
## bar) to user://update.apk, then hands it to the system installer through the
## native RebornUpdater plugin (FileProvider + ACTION_VIEW). The leftover APK is
## deleted on the next launch. Falls back to the browser link if the plugin is
## missing (e.g. desktop/editor runs).

signal checked(has_update: bool, latest: int)

const API := "https://api.github.com/repos/jjongjjongs/Reborn/releases/tags/game-latest"
const APK_PATH := "user://update.apk"

var _http: HTTPRequest
var _dl: HTTPRequest
var _latest := 0
var _url := ""
var _has := false
var _done := false
var _downloading := false
var _ready_to_install := false
var _dialog: Control
var _title: Label
var _body: Label
var _bar: ProgressBar
var _getbtn: Button
var _permbtn: Button

func _ready() -> void:
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cleanup_old_apk()
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_done)
	_dl = HTTPRequest.new()
	_dl.download_chunk_size = 262144
	_dl.use_threads = true
	add_child(_dl)
	_dl.request_completed.connect(_on_downloaded)
	_build()
	_dialog.visible = false

func installed() -> int:
	return int(ProjectSettings.get_setting("application/config/build_code", 0))

func _plugin() -> Object:
	if Engine.has_singleton("RebornUpdater"):
		return Engine.get_singleton("RebornUpdater")
	return null

func _cleanup_old_apk() -> void:
	# after an update installs, the new app launches and removes the leftover file
	if FileAccess.file_exists(APK_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(APK_PATH))

func refresh() -> void:
	_http.cancel_request()
	var err := _http.request(API, PackedStringArray([
		"User-Agent: RebornGame", "Accept: application/vnd.github+json"]))
	if err != OK:
		_fail(-1)

func show_dialog() -> void:
	Sfx.play("ui")
	_dialog.visible = true
	if _downloading or _ready_to_install:
		return
	if _done:
		_render()
	else:
		_title.text = "업데이트 확인 중…"
		_body.text = ""
		_getbtn.visible = false
		_permbtn.visible = false
		_bar.visible = false
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
	if _dialog.visible and not _downloading:
		_render()
	checked.emit(_has, _latest)

func _render() -> void:
	var inst := installed()
	_bar.visible = false
	_permbtn.visible = false
	if _has:
		_title.text = "새 버전 v%d 있음" % _latest
		_body.text = "현재 v%d → 최신 v%d\n지금 업데이트를 누르면 앱 안에서 받아 바로 설치합니다." % [inst, _latest]
		_getbtn.text = "지금 업데이트"
		_getbtn.visible = _url != ""
	else:
		_title.text = "최신 버전"
		_body.text = "현재 v%d 가 최신입니다." % inst
		_getbtn.visible = false

# ---- download + install ----
func _on_get() -> void:
	if _ready_to_install:
		_install()
		return
	if _url == "" or _downloading:
		return
	if _plugin() == null:
		OS.shell_open(_url)   # no native installer (desktop/editor): browser fallback
		return
	_cleanup_old_apk()
	_dl.download_file = APK_PATH
	var err := _dl.request(_url, PackedStringArray(["User-Agent: RebornGame"]))
	if err != OK:
		_title.text = "다운로드 실패"
		_body.text = "다시 시도해 주세요. (%d)" % err
		return
	_downloading = true
	_title.text = "다운로드 중…"
	_body.text = "v%d 받는 중" % _latest
	_bar.value = 0.0
	_bar.visible = true
	_getbtn.visible = false

func _process(_dt: float) -> void:
	if _downloading:
		var total := _dl.get_body_size()
		var got := _dl.get_downloaded_bytes()
		if total > 0:
			_bar.value = 100.0 * float(got) / float(total)
			_body.text = "v%d 받는 중  %.1f / %.1f MB" % [_latest, got / 1048576.0, total / 1048576.0]

func _on_downloaded(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	_downloading = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_title.text = "다운로드 실패"
		_body.text = "네트워크를 확인하고 다시 시도해 주세요. (%d/%d)" % [result, code]
		_bar.visible = false
		_getbtn.text = "다시 받기"
		_getbtn.visible = true
		return
	_bar.value = 100.0
	_ready_to_install = true
	_install()

func _install() -> void:
	var p := _plugin()
	if p == null:
		OS.shell_open(_url)
		return
	if not p.can_install():
		_title.text = "설치 권한 필요"
		_body.text = "‘이 출처의 앱 설치 허용’을 켠 뒤 돌아와서 [설치]를 눌러 주세요."
		_permbtn.visible = true
		_getbtn.text = "설치"
		_getbtn.visible = true
		return
	var res: String = p.install_apk(ProjectSettings.globalize_path(APK_PATH))
	if res != "":
		_title.text = "설치 실패"
		_body.text = "사유: %s" % res
		_getbtn.text = "설치 다시 시도"
		_getbtn.visible = true
	else:
		_title.text = "설치 화면을 여는 중…"
		_body.text = "안내에 따라 [업데이트]를 눌러 주세요."
		_getbtn.visible = false
		_permbtn.visible = false

func _build() -> void:
	_dialog = Control.new()
	_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new(); bg.color = Color(0.04, 0.06, 0.08, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT); bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_dialog.add_child(bg)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5; panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -280; panel.offset_right = 280; panel.offset_top = -170; panel.offset_bottom = 170
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
	_bar = ProgressBar.new()
	_bar.min_value = 0.0; _bar.max_value = 100.0; _bar.custom_minimum_size = Vector2(0, 22)
	_bar.visible = false
	v.add_child(_bar)
	var h := HBoxContainer.new(); h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 12)
	_getbtn = _mk("지금 업데이트", true, _on_get)
	_permbtn = _mk("권한 설정", false, func() -> void:
		var p := _plugin()
		if p: p.open_install_settings())
	_permbtn.visible = false
	h.add_child(_mk("닫기", false, func() -> void: _dialog.visible = false))
	h.add_child(_permbtn)
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
