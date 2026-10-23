#!/bin/sh
# Rebuild the Qt shader packages (.qsb) after editing anything in shaders/.
set -eu
dir=$(cd "$(dirname "$0")/../shaders" && pwd)
qsb=$(command -v qsb-qt6 || command -v /usr/lib64/qt6/bin/qsb || command -v qsb)
for f in "$dir"/*.frag "$dir"/*.vert; do
    [ -e "$f" ] || continue
    "$qsb" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$f.qsb" "$f"
    echo "built ${f##*/}.qsb"
done
