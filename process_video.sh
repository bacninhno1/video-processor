#!/bin/bash
set -e

INPUT_FILE="$1"
INTRO_FILE="$2"
FLIP="$3"
OUTPUT_FILE="$4"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
  echo "❌ Usage: $0 input.mp4 [intro.mp4] flip output.mp4"
  exit 1
fi

# -----------------------------
# Bộ lọc video cho INPUT
# -----------------------------
VF_FILTERS="hqdn3d=3:3:6:6,unsharp=5:5:1.0:5:5:0.0,scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1:1"

if [ "$FLIP" -eq 2 ]; then
  VF_FILTERS="$VF_FILTERS,hflip"
fi

# Encode INPUT (nâng chất lượng + filter)
echo "🎬 Encoding INPUT..."
ffmpeg -y -i "$INPUT_FILE" \
  -vf "$VF_FILTERS" \
  -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -profile:v high \
  -c:a aac -b:a 192k -ar 44100 \
  -movflags +faststart -fflags +genpts \
  input_encoded.mp4

# Encode INTRO nếu có
if [ -n "$INTRO_FILE" ] && [ -f "$INTRO_FILE" ]; then
  echo "🎬 Encoding INTRO..."
  ffmpeg -y -i "$INTRO_FILE" \
    -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1:1" \
    -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -profile:v high \
    -c:a aac -b:a 192k -ar 44100 \
    -movflags +faststart -fflags +genpts \
    intro_encoded.mp4

  echo "🔗 Ghép INPUT + INTRO (intro ở cuối, giữ cả audio)..."
  echo -e "file 'input_encoded.mp4'\nfile 'intro_encoded.mp4'" > concat_list.txt
  ffmpeg -y -f concat -safe 0 -i concat_list.txt -c copy "$OUTPUT_FILE"
else
  echo "👉 Không có intro, chỉ dùng INPUT."
  mv input_encoded.mp4 "$OUTPUT_FILE"
fi

echo "✅ Done! Output: $OUTPUT_FILE"
