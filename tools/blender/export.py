import bpy
for o in bpy.data.objects:
    o.select_set(o.type == "MESH")
bpy.ops.export_scene.gltf(filepath="/home/user/Reborn/game/assets/maps/oldtown2.glb", export_format="GLB",
    use_selection=True, export_apply=True, export_image_format="AUTO", export_materials="EXPORT", export_cameras=False, export_lights=False)
print("EXPORTED")
