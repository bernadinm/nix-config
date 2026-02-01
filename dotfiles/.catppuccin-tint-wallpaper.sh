#!/usr/bin/env bash
# Catppuccin Blue Tint Wallpaper Filter
# Applies Catppuccin Mocha blue tint to wallpapers
#
# Usage:
#   catppuccin-tint-wallpaper.sh input.jpg [output.jpg]
#   catppuccin-tint-wallpaper.sh ~/Pictures/my-wallpaper.jpg
#
# If no output file is specified, creates: input-catppuccin.jpg

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 input.jpg [output.jpg]"
    echo ""
    echo "Applies Catppuccin Mocha blue tint to wallpapers"
    echo "Filter: 85% brightness, grayscale, 30% blue (#89b4fa) tint"
    echo ""
    echo "Examples:"
    echo "  $0 ~/Pictures/wallpaper.jpg"
    echo "  $0 ~/Pictures/wallpaper.jpg ~/Pictures/wallpaper-blue.jpg"
    exit 1
fi

INPUT="$1"
OUTPUT="${2:-}"

# If no output specified, create one based on input filename
if [ -z "$OUTPUT" ]; then
    DIR="$(dirname "$INPUT")"
    FILENAME="$(basename "$INPUT")"
    BASENAME="${FILENAME%.*}"
    EXT="${FILENAME##*.}"
    OUTPUT="${DIR}/${BASENAME}-catppuccin.${EXT}"
fi

# Check if input file exists
if [ ! -f "$INPUT" ]; then
    echo "Error: Input file '$INPUT' not found"
    exit 1
fi

# Apply Catppuccin Mocha blue tint filter
echo "Applying Catppuccin blue tint to: $INPUT"
echo "Output: $OUTPUT"

magick "$INPUT" \
    -modulate 85,120,100 \
    -colorspace Gray \
    -fill "#89b4fa" \
    -tint 30 \
    "$OUTPUT"

echo "✓ Done! Created: $OUTPUT"
