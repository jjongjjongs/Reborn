# Export the built map as .gltf + .bin with textures shared in game/assets/maps/tex
# (one copy for every map instead of one embedded copy per map). Prepend NAME = '<map>'.
import bpy
for o in bpy.data.objects:
    o.select_set(o.type == "MESH")
bpy.ops.export_scene.gltf(filepath="/home/user/Reborn/game/assets/maps/%s.gltf" % NAME, export_format="GLTF_SEPARATE",
    export_texture_dir="tex", use_selection=True, export_apply=True, export_image_format="AUTO",
    export_materials="EXPORT", export_cameras=False, export_lights=False)
print("EXPORTED")
