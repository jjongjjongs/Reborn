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
