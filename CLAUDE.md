# Mini Soldier (game/) — working rules

The owner tests on an Android phone only (no PC) and reads Korean. These rules come from mistakes
that were made and reported more than once. Follow them on every task.

## Verify the way the player sees it
- Never report a feature as done from a test-only override (`Soldier.test_body`, forced loadouts,
  standalone harness scenes). Before reporting, run the real path: `Profile.equip(...)` / shop item,
  Menu -> loadout screen -> a mode, third person AND first person (`_dev/realpath.gd`).
- A new body / weapon / item is not "in the game" until it is registered (Profile.ITEMS, BODIES,
  Weapons, sortie lists) and reachable from the menus. Say plainly what is and is not wired up.
- When the owner asks "is X implemented?", answer with a table of what exists in the build.

## Grip / hand checklist (third person and first person, every body x every weapon)
- Palm centre (midpoint Hand -> Middle2 bone) must sit on the grip / foregrip anchor:
  run `_dev/gripsheet.gd -- <body>`; every long gun must print R-grip and L-fore <= 0.04
  (pistol L <= 0.06). Look at the close-up sheet too, not only the numbers.
- Hand size is measured from the skeleton (`hand_back` in soldier.gd), never a per-body constant.
- Short arms (chibi bodies): `_fit_reach` slides the gun toward the body; first person moves the arms
  (`fp_shift`) instead. Do not scale guns up to fix looks if the hands stop reaching.
- First person uses the equipped body's own arms (`Soldier.arms_only`). Check `_dev/fpall.gd`
  for all 9 weapons with each shop body before reporting.
- A new gun model needs measured anchors (butt, grip, fore; `vfore` for vertical foregrips).

## Models
- Keep proportions to the concept turnaround sheets (head incl. helmet ~1/3 of height). Do not
  enlarge heads "for chibi" beyond the sheet.
- Avoid boxy shapes: wide multi-segment bevels, fused soft cloth (build_mini_v3.py).
- After rigging, look at the model from the BACK in game (third person camera is behind the
  player): torso / vest / back pack are skinned to the spine only.

## Characters (five concept classes, one skeleton)
- All player / bot bodies are built in Blender: `tools/blender/make_char.sh <rookie|scout|tech|sniper|heavy>`
  (build_mini_v3.py -> rig_tripo.py OWN, ~45-55k faces). Class gear lives in build_mini_v3.py
  (plate_carrier / light_rig / pack / heavy_extras / ghillie / tech_extras, cap_gear / hood_gear / helmet_gear).
- Rig: every class is scaled and jointed like the Rookie (REF / FIX in make_char.sh) - never let a cap, hood
  or antenna rescale the figure. Rigid gear must sit inside |x| < 0.21 (rides on the chest) or fully on the
  arm; anything straddling the shoulder tears when aiming. Check `_dev/gripsheet.gd -- <class>` close-ups
  (left side, arm across the chest) for stretched wedges, not only the T-pose renders.
- Team colour only on the "Team" material (armbands, patches, tabs) - keep armbands on every class.
- Skins = material colour sets (Profile ITEMS cat "skin", "mats": material -> colour; Soldier.skin applied in
  _team_tint). One equipped skin per character (equip key "skin_<class>"); a skin needs its character owned.

## Process
- Bump `tools/bump.sh <code> <name>` on every push (project.godot + Android preset together).
- Show a mockup before large features. Send screenshots of the real game, not only Blender renders.
- If something cannot reach the requested quality, say so before starting, not after.
