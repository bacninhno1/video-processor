#!/bin/bash
set -e

INPUT_FILE="$1"
INTRO_FILE="$2"
FLIP="$3"
OUTPUT_FILE="$4"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
  echo "❌ Usage: $0 input.mp4 [intro.mp4] flip output.mp4"
  echo "   flip = 0 (bình thường), 1 (lật ngang)"
  exit 1
fi

# -----------------------------
# Bộ lọc cơ bản cho video dọc
# -----------------------------
BASE_FILTER="scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1:1,fps=30"

# Chỉ lật INPUT nếu FLIP=1
if [ "$FLIP" -eq 1 ]; then
  VF_FILTERS_INPUT="$BASE_FILTER,hflip"
else
  VF_FILTERS_INPUT="$BASE_FILTER"
fi

# Intro luôn không lật
VF_FILTERS_INTRO="$BASE_FILTER"

# -----------------------------
# Encode INPUT
# -----------------------------
echo "🎬 Encode INPUT..."
ffmpeg -y -i "$INPUT_FILE" \
  -vf "$VF_FILTERS_INPUT" \
  -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -profile:v high \
  -c:a aac -b:a 192k -ar 44100 \
  -movflags +faststart -fflags +genpts \
  input_encoded.mp4

# -----------------------------
# Nếu có intro, encode và nối
# -----------------------------
if [ -n "$INTRO_FILE" ] && [ -f "$INTRO_FILE" ]; then
  echo "🎬 Encode INTRO..."
  ffmpeg -y -i "$INTRO_FILE" \
    -vf "$VF_FILTERS_INTRO" \
    -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -profile:v high \
    -c:a aac -b:a 192k -ar 44100 \
    -movflags +faststart -fflags +genpts \
    intro_encoded.mp4

  echo "📝 Concat list..."
  cat > list.txt <<EOF
file 'intro_encoded.mp4'
file 'input_encoded.mp4'
EOF

  echo "🔗 Merge intro + main..."
  ffmpeg -y -f concat -safe 0 -i list.txt -c copy merged_temp.mp4

  echo "🎞 Final encode..."
  ffmpeg -y -i merged_temp.mp4 \
    -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -profile:v high \
    -c:a aac -b:a 192k -ar 44100 \
    -movflags +faststart -fflags +genpts -vsync 2 -avoid_negative_ts make_zero -video_track_timescale 30 \
    "$OUTPUT_FILE"
else
  echo "👉 No intro, finalizing..."
  ffmpeg -y -i input_encoded.mp4 \
    -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -profile:v high \
    -c:a aac -b:a 192k -ar 44100 \
    -movflags +faststart -fflags +genpts -vsync 2 -avoid_negative_ts make_zero -video_track_timescale 30 \
    "$OUTPUT_FILE"
fi

echo "✅ Done! Output: $OUTPUT_FILE"
