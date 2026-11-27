class_name Footsteps
extends RefCounted
## stride counter shared by the player and bots: a step sound every ~1.9 m while running on the
## floor (quieter when walking / crouched), a whoosh on jump, a thud on landing.
var _acc := 0.0
var _air := 0.0
var _alt := false

func update(body: CharacterBody3D, delta: float, own := false) -> void:
	var hs := Vector2(body.velocity.x, body.velocity.z).length()
	if body.is_on_floor():
		if _air > 0.35: _emit(body, "land", own, 0.0)
		_air = 0.0
		if hs > 1.2:
			_acc += hs * delta
			var stride := 1.9 if hs > 4.0 else 1.5
			if _acc >= stride:
				_acc = 0.0; _alt = not _alt
				_emit(body, "step2" if _alt else "step", own, 0.0 if hs > 4.0 else -9.0)
	else:
		_air += delta

func jumped(body: CharacterBody3D, own := false) -> void:
	_emit(body, "jump", own, 0.0)

func _emit(body: Node3D, snd: String, own: bool, db: float) -> void:
	if own: Sfx.play(snd, db - 12.0)              # your own feet: quiet, not positional
	else: Sfx.play_at(snd, body.global_position, db)
