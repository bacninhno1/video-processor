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
# Bộ lọc cho video input
# -----------------------------
VF_FILTERS="scale=1080:1920:force_original_aspect_ratio=decrease,"
VF_FILTERS+="pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1:1,fps=30"

if [ "$FLIP" -eq 1 ]; then
  VF_FILTERS="$VF_FILTERS,hflip"
fi

echo "🎬 Encode INPUT..."
ffmpeg -y -i "$INPUT_FILE" \
  -vf "$VF_FILTERS" \
  -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -profile:v high \
  -c:a aac -b:a 192k -ar 44100 \
  -movflags +faststart -fflags +genpts \
  input_encoded.mp4

# Encode INTRO nếu có
if [ -n "$INTRO_FILE" ] && [ -f "$INTRO_FILE" ]; then
  echo "🎬 Encode INTRO..."
  ffmpeg -y -i "$INTRO_FILE" \
    -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1:1,fps=30" \
    -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -profile:v high \
    -c:a aac -b:a 192k -ar 44100 \
    -movflags +faststart -fflags +genpts \
    intro_encoded.mp4

  echo "📝 Tạo danh sách concat..."
  cat > list.txt <<EOF
file 'input_encoded.mp4'
file 'intro_encoded.mp4'
EOF

  echo "🔗 Ghép INPUT + INTRO..."
  ffmpeg -y -f concat -safe 0 -i list.txt -c copy merged_temp.mp4

  # Encode lại lần cuối để tránh lỗi metadata
  ffmpeg -y -i merged_temp.mp4 \
    -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -profile:v high \
    -c:a aac -b:a 192k -ar 44100 \
    -movflags +faststart -fflags +genpts \
    "$OUTPUT_FILE"

else
  echo "👉 Không có intro, chỉ dùng INPUT."
  ffmpeg -y -i input_encoded.mp4 \
    -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -profile:v high \
    -c:a aac -b:a 192k -ar 44100 \
    -movflags +faststart -fflags +genpts \
    "$OUTPUT_FILE"
fi

echo "✅ Done! Output: $OUTPUT_FILE"
