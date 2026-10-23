#!/bin/sh
# Opal wallpaper thumbnails: thumbs.sh <thumb-dir> <image>...
# Prints each source path once its thumbnail exists (cached ones included).
# Thumbnail name = md5 of the source path, matching Qt.md5() in Wallpapers.qml.
dir=$1
shift
mkdir -p "$dir" || exit 1
for f in "$@"; do
    h=$(printf '%s' "$f" | md5sum | cut -d' ' -f1)
    out="$dir/$h.jpg"
    if [ ! -s "$out" ] || [ "$f" -nt "$out" ]; then
        if magick -define jpeg:size=1024x640 "$f[0]" -auto-orient -thumbnail '512x320^' \
            -gravity center -extent 512x320 -strip -quality 82 "$out.part.jpg" 2>/dev/null; then
            mv -f "$out.part.jpg" "$out"
        else
            rm -f "$out.part.jpg"
            continue
        fi
    fi
    printf '%s\n' "$f"
done
