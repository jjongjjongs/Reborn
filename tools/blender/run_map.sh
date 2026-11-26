#!/bin/bash
# build + cast + export one plan in the running Blender
m=$1; cd /tmp/bwork
{ echo "PLAN_OVERRIDE = '/home/user/Reborn/game/assets/maps/$m.json'"; cat /home/user/Reborn/tools/blender/build_quarter.py; } > _b.py
python3 bclient.py code _b.py | grep -o '"result": "[^"]*'
sed "s/n = \"mine\"/n = \"$m\"/" study_cast_current.py > _c.py; python3 bclient.py code _c.py | grep -o 'cast [0-9 ]*'
{ echo "NAME = '$m'"; cat /home/user/Reborn/tools/blender/export_plan.py; } > _e.py; python3 bclient.py code _e.py | grep -o EXPORTED
