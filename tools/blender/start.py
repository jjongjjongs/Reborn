import bpy, sys
bpy.ops.preferences.addon_install(filepath="/tmp/bmcp/blender-mcp/addon.py", overwrite=True)
bpy.ops.preferences.addon_enable(module="addon")
print("BLENDERMCP addon enabled", flush=True)
