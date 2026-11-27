#!/bin/bash
# bump the build: tools/bump.sh <code> <name>  (keeps project.godot and the Android preset in sync;
# the in-game updater compares application/config/build_code with the latest release)
set -e
cd "$(dirname "$0")/../game"
sed -i "s/^config\/build_code=.*/config\/build_code=$1/; s/^config\/version=.*/config\/version=\"$2\"/" project.godot
sed -i "s/^version\/code=.*/version\/code=$1/; s/^version\/name=.*/version\/name=\"$2\"/" export_presets.cfg
grep -n "build_code\|config/version" project.godot; grep -n "version/code\|version/name" export_presets.cfg
