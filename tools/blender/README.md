# Map building with Blender (blender-mcp)

Maps are drawn as *streets first*: `game/assets/maps/<map>.json` lists the walkable
streets, squares, canal, bridges, sites and spawns. `build_<map>.py` runs inside Blender,
carves the plan (marching squares, so diagonal streets get straight facades) and fills
every non-walkable area with buildings (parcel heights, windows, cornices).

1. Install the blender-mcp addon (https://github.com/ahujasid/blender-mcp, MIT) and start
   Blender — `start.py` installs/enables it; its socket server listens on localhost:9876.
2. `python3 bclient.py code build_oldtown2.py` — build the map through the addon.
3. `python3 bclient.py code render_views.py` — preview renders (optional).
4. `python3 bclient.py code export.py` — writes `game/assets/maps/oldtown2.glb`.
5. Re-run the texture slimmer so the GLB points at `game/assets/city/tex/`.

Godot side: `game/map_oldtown2.gd` loads the GLB, adds collisions, props, spawns and sites.

## 구도심 (oldquarter) — multi-level bomb map
`build_quarter.py` reads `game/assets/maps/oldquarter.json` (spaces / ramps / blocks)
and meshes every 0.5 m column as a stack of solid intervals, so rooms, a tunnel
under a street, balconies and catwalks are possible. Stair steps go to a separate
visual-only `Steps` mesh; Godot (`map_quarter.gd`) walks on smooth wedge colliders
built from the same `ramps` list. Export with `export_quarter.py`.

## All maps from ASCII plans
`maps/paint.py` paints every map (`maps/*.txt`, 1 char = 2 m) from rectangle
operations; `ascii_plan.py maps/<name>.txt` turns one into `game/assets/maps/<name>.json`
(legend at the top of that file). Build in Blender with `PLAN_OVERRIDE = '<json>'`
prepended to `build_quarter.py`, then export `<name>.glb`. Godot loads them all
through `MapPlan` (themes: old, desert, prison, harbor, city, lab).

## Detail pass + shared textures (v54)
`build_quarter.py` now also emits visual-only meshes: `Detail` (plinths, doors, shop
fronts, awnings, floor bands, cornices + parapets, roof AC units / tanks), `Windows`
(framed windows with sills, some lit) and `Shadows` (alpha contact-shadow strips along
wall bases). Small textures come from `gen_tex.py`. Maps are exported with
`export_plan.py` as `.gltf + .bin` with every texture shared in `game/assets/maps/tex`.
`run_map.sh <name>` builds, ray-casts (for analyze.py) and exports one map.
Plan props (`L` lamp, `T` tree/palm, `V` car, `b` barrels) are placed by `MapPlan`.
