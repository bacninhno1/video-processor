#!/bin/bash
set -e

INPUT_FILE="$1"       # video gốc
INTRO_FILE="$2"       # intro/outro nếu có
FLIP="$3"             # 0 = giữ nguyên, 2 = flip ngang
OUTPUT_FILE="$4"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
  echo "❌ Usage: $0 input.mp4 [intro.mp4] flip output.mp4"
  exit 1
fi

# -----------------------------
# Tạo filter video
# -----------------------------
VF_FILTERS="scale=1080:1920:force_original_aspect_ratio=decrease,"
VF_FILTERS+="pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1:1,fps=30"

if [ "$FLIP" -eq 2 ]; then
  VF_FILTERS="$VF_FILTERS,hflip"
fi

# -----------------------------
# Encode INPUT
# -----------------------------
echo "🎬 Encoding INPUT..."
ffmpeg -y -i "$INPUT_FILE" \
  -vf "$VF_FILTERS" \
  -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -profile:v high \
  -c:a aac -b:a 192k -ar 44100 \
  -movflags +faststart -fflags +genpts \
  input_encoded.mp4

# -----------------------------
# Encode INTRO nếu có
# -----------------------------
if [ -n "$INTRO_FILE" ] && [ -f "$INTRO_FILE" ]; then
  echo "🎬 Encoding INTRO..."
  ffmpeg -y -i "$INTRO_FILE" \
    -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1:1,fps=30" \
    -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -profile:v high \
    -c:a aac -b:a 192k -ar 44100 \
    -movflags +faststart -fflags +genpts \
    intro_encoded.mp4

  echo "🔗 Ghép INPUT + INTRO (re-encode để tránh lệch audio)..."
  ffmpeg -y -i "concat:input_encoded.mp4|intro_encoded.mp4" \
    -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -profile:v high \
    -c:a aac -b:a 192k -ar 44100 \
    -movflags +faststart -fflags +genpts \
    "$OUTPUT_FILE"
else
  echo "👉 Không có intro, chỉ dùng INPUT."
  mv input_encoded.mp4 "$OUTPUT_FILE"
fi

echo "✅ Done! Output: $OUTPUT_FILE"
