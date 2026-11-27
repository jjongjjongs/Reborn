#!/bin/bash
# build + rig one concept character into the game: tools/blender/make_char.sh CLASS [faces]
# (headless Blender; previews of the raw model land in /tmp/mv3/CLASS_*.png)
set -e
C=$1; T=${2:-40000}; SUF=${3:-}      # 3rd arg "_lod": light copy for bots
CORE=0.0
R="$(cd "$(dirname "$0")/../.." && pwd)"
N="$(echo ${C:0:1} | tr a-z A-Z)${C:1}"
mkdir -p /tmp/mv3 /tmp/bwork
[ -n "$RIG_ONLY" ] || blender -b --python "$R/tools/blender/build_mini_v3.py" -- "$C" > /tmp/mv3/build_$C.log 2>&1
blender -b --python-expr "OWN='/tmp/mv3/$C.blend'; OUT='$R/game/assets/soldier/$N$SUF.glb'; MESH_NAME='${N}_Body'; TARGET=$T; REF=(-0.02816, 1.81243, 0.0, -0.0387); FIX=(1.21, 0.20, 1.38, 0.73); CORE_X=$CORE; exec(open('$R/tools/blender/rig_tripo.py').read())" > /tmp/mv3/rig_$C.log 2>&1
grep -E "figure faces|H [0-9]|exported" /tmp/mv3/rig_$C.log
