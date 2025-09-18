#!/bin/bash
set -euo pipefail

: "${INPUT_URL:?INPUT_URL environment variable must be set (e.g. rtp://... or srt://...)}"
: "${SEGMENT_TIME:=1800}"
: "${LOGLEVEL:=info}"
: "${OUTPUT_DIR:=/output}"

CONTAINER_NAME="$(hostname)"

if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo "Error: Output directory $OUTPUT_DIR does not exist"
    exit 1
fi

if [[ ! -w "$OUTPUT_DIR" ]]; then
    echo "Error: Output directory $OUTPUT_DIR is not writable"
    exit 1
fi

CONTAINER_OUTPUT_DIR="$OUTPUT_DIR/$CONTAINER_NAME"
mkdir -p "$CONTAINER_OUTPUT_DIR"

if [[ ! -w "$CONTAINER_OUTPUT_DIR" ]]; then
    echo "Error: Output directory $CONTAINER_OUTPUT_DIR is not writable"
    exit 1
fi

echo "Starting FFmpeg segmentation..."
echo "Input URL: $INPUT_URL"
echo "Segment Time: $SEGMENT_TIME seconds"
echo "Output Directory: $OUTPUT_DIR"
echo "Container Name: $CONTAINER_NAME"

exec ffmpeg -hide_banner -loglevel "$LOGLEVEL" \
    -i "$INPUT_URL" \
    -map 0 \
    -c copy \
    -f segment \
    -segment_time "$SEGMENT_TIME" \
    -reset_timestamps 1 \
    -strftime 1 \
    -segment_format mp4 \
    -segment_format_options movflags=+faststart \
    "$CONTAINER_OUTPUT_DIR/${CONTAINER_NAME}_%Y%m%d_%H%M.mp4"