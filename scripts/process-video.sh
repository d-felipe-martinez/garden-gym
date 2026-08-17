#!/usr/bin/env bash
# Garden Gym — form-check frame extractor (see CLAUDE.md, "process video").
#
# Usage:
#   process-video.sh                     # info: newest recording + duration
#   process-video.sh --at <seconds>      # frames covering t-45s..t+10s (repeatable)
#   process-video.sh --sheets            # contact sheets, 1 frame / 5 s
#   process-video.sh --video <file> ...  # use a specific file instead of newest
#
# Frames are 1280 px wide, written to ~/Desktop/form-check-<timestamp>/.
set -euo pipefail

# Where session recordings land on this Mac. ~/Pictures/Camera Hub is the
# app's own output folder (verified 2026-08-16), but the first real session
# ("Full Body Workout Session.mp4", 2026-08-17) appeared in ~/Downloads —
# so both are scanned and the newest video wins.
RECORDINGS_DIRS=("$HOME/Pictures/Camera Hub" "$HOME/Downloads")

usage() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; }

video=""
sheets=false
at_times=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --video)  video="${2:?--video needs a file}"; shift 2 ;;
    --at)     at_times+=("${2:?--at needs seconds}"); shift 2 ;;
    --sheets) sheets=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

command -v ffmpeg >/dev/null || { echo "ffmpeg not found — brew install ffmpeg" >&2; exit 1; }

if [[ -z "$video" ]]; then
  video=$(find "${RECORDINGS_DIRS[@]}" -maxdepth 1 -type f \( -iname '*.mp4' -o -iname '*.mov' -o -iname '*.mkv' \) -print0 2>/dev/null \
          | xargs -0 ls -t 2>/dev/null | head -n 1)
  [[ -n "$video" ]] || { echo "no recordings in: ${RECORDINGS_DIRS[*]}" >&2; exit 1; }
fi
[[ -f "$video" ]] || { echo "not a file: $video" >&2; exit 1; }

duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video")
duration=${duration%.*}
echo "video:    $video"
echo "duration: ${duration}s"

if [[ ${#at_times[@]} -eq 0 && "$sheets" == false ]]; then
  echo "nothing to extract — pass --at <seconds> and/or --sheets"
  exit 0
fi

out="$HOME/Desktop/form-check-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$out"

# --sheets: one frame every 5 s, tiled 6x5. One sheet covers 150 s; within a
# sheet cells read left-to-right, top-to-bottom, so cell k (1-based) on sheet N
# is at t = (N-1)*150 + (k-1)*5 seconds.
if [[ "$sheets" == true ]]; then
  ffmpeg -v error -i "$video" \
    -vf "fps=1/5,scale=320:-2,tile=6x5" \
    -fps_mode passthrough "$out/sheet-%02d.png"
  echo "sheets:   $(ls "$out" | grep -c '^sheet-') written (cell = 5s, sheet = 150s)"
fi

# --at t: 6 frames spanning t-45s .. t+10s (the last-set window), 1280 px wide
for t in "${at_times[@]}"; do
  for i in 0 1 2 3 4 5; do
    ts=$(( t - 45 + i * 11 ))
    (( ts < 0 )) && ts=0
    (( duration > 0 && ts > duration )) && ts=$duration
    ffmpeg -v error -y -ss "$ts" -i "$video" -frames:v 1 \
      -vf "scale=1280:-2" "$out/at${t}s-f$((i+1))-t${ts}s.png"
  done
  echo "at ${t}s:  6 frames (t-45s..t+10s)"
done

echo "output:   $out"
