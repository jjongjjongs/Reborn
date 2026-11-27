class_name TeamTags
extends Node
## Who is who, at a glance (all PvP modes): a thin outline round every other soldier -
## blue for teammates (also seen through walls), red for enemies (hidden by walls like the body).
## No markers over heads (they covered the sniper scope). Created by the Radar.

const ALLY := Color(0.3, 0.62, 1.0)
const ENEMY := Color(1.0, 0.2, 0.16)
var player: Node3D
var _t := 0.0

func _on_my_side(n) -> bool:
	var pt: int = int(player.team) if "team" in player else -1
	return pt != -1 and "team" in n and int(n.team) == pt

func _process(dt: float) -> void:
	_t -= dt
	if _t > 0.0 or player == null or not is_instance_valid(player): return
	_t = 0.4                         # new / respawned soldiers pick it up within a moment
	for n in get_tree().get_nodes_in_group("combatant"):
		if n == player or not is_instance_valid(n): continue
		var s = n.get("_soldier")
		if s == null or not is_instance_valid(s): continue
		var ally := _on_my_side(n)
		var want := ALLY if ally else ENEMY
		if s.outline_col != want or s.get_meta("ol_n", -1) != s.find_children("*", "MeshInstance3D", true, false).size():
			s.set_outline(want, 0.014, ally)
			s.set_meta("ol_n", s.find_children("*", "MeshInstance3D", true, false).size())
