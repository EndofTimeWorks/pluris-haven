#!/usr/bin/env bash

set -euo pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source_image=${1:-"$project_dir/assets/brand/pluris_haven_app_icon_dark.png"}

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
adaptive_foreground_source="$scratch_dir/adaptive-foreground-source.png"
adaptive_background='17 6 45'
read -r source_red source_green source_blue source_alpha _ < <(
  vips getpoint "$source_image" 0 0 2>/dev/null
)
if [[ "$source_red $source_green $source_blue $source_alpha" != '17 6 45 255' ]]; then
  echo 'Icon source background changed; update adaptive foreground extraction deliberately.' >&2
  exit 1
fi
vips thumbnail "$source_image" "$master_icon" 1024 \
  --height 1024 --size down 2>/dev/null
vips flatten "$master_icon" "$master_with_background" \
  --background "$adaptive_background" 2>/dev/null

# The brand source is intentionally an opaque iOS/legacy icon. Build a separate
# transparent Android adaptive foreground by removing only its exact background
# colour, preserving every artwork pixel and the original proportions.
for band_and_background in '0 17 red' '1 6 green' '2 45 blue'; do
  read -r band background name <<<"$band_and_background"
  vips extract_band "$source_image" "$scratch_dir/$name.png" "$band" 2>/dev/null
  vips relational_const "$scratch_dir/$name.png" "$scratch_dir/$name-mask.png" \
    noteq "$background" 2>/dev/null
done
vips boolean "$scratch_dir/red-mask.png" "$scratch_dir/green-mask.png" \
  "$scratch_dir/red-green-mask.png" or 2>/dev/null
vips boolean "$scratch_dir/red-green-mask.png" "$scratch_dir/blue-mask.png" \
  "$scratch_dir/foreground-alpha.png" or 2>/dev/null
vips extract_band "$source_image" "$scratch_dir/source-rgb.png" 0 --n 3 2>/dev/null
vips bandjoin "$scratch_dir/source-rgb.png $scratch_dir/foreground-alpha.png" \
  "$adaptive_foreground_source" 2>/dev/null

render() {
  local side=$1
  local target=$2
  vips thumbnail "$master_with_background" "$target" "$side" \
    --height "$side" --size down 2>/dev/null
}

render_adaptive_foreground() {
  local side=$1
  local target=$2
  # This renders the current mark at roughly 64 dp: inside Android's 66 dp
  # maximum safe viewport, with room for resampling at lower densities.
  local art_side=$((side * 7 / 9))
  local offset=$(((side - art_side) / 2))
  local scaled="$scratch_dir/adaptive-foreground-${side}.png"

  vips thumbnail "$adaptive_foreground_source" "$scaled" "$art_side" \
    --height "$art_side" --size force 2>/dev/null
  vips embed "$scaled" "$target" "$offset" "$offset" "$side" "$side" \
    --extend background --background '0 0 0 0' 2>/dev/null
}

render_round_fallback() {
  local side=$1
  local target=$2
  local square="$scratch_dir/round-square-${side}.png"
  local rgb="$scratch_dir/round-rgb-${side}.png"
  local mask="$scratch_dir/round-mask-${side}.v"

  render "$side" "$square"
  vips extract_band "$square" "$rgb" 0 --n 3 2>/dev/null
  vips black "$mask" "$side" "$side" 2>/dev/null
  vips draw_circle "$mask" 255 $(((side - 1) / 2)) $(((side - 1) / 2)) \
    $((side / 2)) --fill 2>/dev/null
  vips bandjoin "$rgb $mask" "$target" 2>/dev/null
}

for density_and_sides in \
  'mdpi 48 108' \
  'hdpi 72 162' \
  'xhdpi 96 216' \
  'xxhdpi 144 324' \
  'xxxhdpi 192 432'; do
  read -r density legacy_side adaptive_side <<<"$density_and_sides"
  resource_dir="$project_dir/android/app/src/main/res/mipmap-$density"
  render "$legacy_side" "$resource_dir/ic_launcher.png"
  render_round_fallback "$legacy_side" "$resource_dir/ic_launcher_round.png"
  render_adaptive_foreground \
    "$adaptive_side" "$resource_dir/ic_launcher_foreground.png"
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
