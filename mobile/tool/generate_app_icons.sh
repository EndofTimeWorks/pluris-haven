#!/usr/bin/env bash

set -euo pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source_image=${1:-"$project_dir/assets/brand/pluris_haven_icon.png"}

if [[ ! -f "$source_image" ]]; then
  echo "Icon source does not exist: $source_image" >&2
  exit 1
fi

source_width=$(vipsheader -f width "$source_image" 2>/dev/null)
source_height=$(vipsheader -f height "$source_image" 2>/dev/null)
if [[ "$source_width" != "$source_height" ]]; then
  echo "Icon source must be square, got ${source_width}x${source_height}: $source_image" >&2
  exit 1
fi

scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/pluris-haven-icons.XXXXXX")
trap 'rm -r -- "$scratch_dir"' EXIT HUP INT TERM
master_icon="$scratch_dir/master.png"
master_with_background="$scratch_dir/master-rgb.png"
vips thumbnail "$source_image" "$master_icon" 1024 \
  --height 1024 --size down 2>/dev/null
vips flatten "$master_icon" "$master_with_background" \
  --background '41 39 86' 2>/dev/null

render() {
  local side=$1
  local target=$2
  vips thumbnail "$master_with_background" "$target" "$side" \
    --height "$side" --size down 2>/dev/null
}

for density_and_side in 'mdpi 48' 'hdpi 72' 'xhdpi 96' 'xxhdpi 144' 'xxxhdpi 192'; do
  read -r density side <<<"$density_and_side"
  render "$side" "$project_dir/android/app/src/main/res/mipmap-$density/ic_launcher.png"
done

while read -r filename side; do
  render "$side" "$project_dir/ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename"
done <<'EOF'
Icon-App-20x20@1x.png 20
Icon-App-20x20@2x.png 40
Icon-App-20x20@3x.png 60
Icon-App-29x29@1x.png 29
Icon-App-29x29@2x.png 58
Icon-App-29x29@3x.png 87
Icon-App-40x40@1x.png 40
Icon-App-40x40@2x.png 80
Icon-App-40x40@3x.png 120
Icon-App-60x60@2x.png 120
Icon-App-60x60@3x.png 180
Icon-App-76x76@1x.png 76
Icon-App-76x76@2x.png 152
Icon-App-83.5x83.5@2x.png 167
Icon-App-1024x1024@1x.png 1024
EOF
