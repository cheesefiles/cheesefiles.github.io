#!/usr/bin/env bash
set -e

# ---------- ANSI (RGB, inline; robust) ----------
HDR()  { printf "\033[38;2;0;200;255m📺 %s\033[0m\n" "$1"; }
OK()   { printf "\033[38;2;80;220;120m✔ %s\033[0m\n" "$1"; }
WARN() { printf "\033[38;2;255;200;0m⚠ %s\033[0m\n" "$1"; }
ERR()  { printf "\033[38;2;255;80;80m✖ %s\033[0m\n" "$1"; exit 1; }

need() { command -v "$1" >/dev/null 2>&1; }

HDR "Installing tv (terminal video)…"
echo

# VS Code notice (known ANSI limitations)
[ -n "$VSCODE_PID" ] && WARN "VS Code terminal detected — ANSI colors may be limited"

# Homebrew check
need brew || ERR "Homebrew not found (https://brew.sh)"

# mpv
if need mpv; then
  OK "mpv found"
else
  brew install mpv >/dev/null || ERR "mpv install failed"
  OK "mpv installed"
fi

# yt-dlp
if need yt-dlp; then
  OK "yt-dlp found"
else
  brew install yt-dlp >/dev/null || ERR "yt-dlp install failed"
  OK "yt-dlp installed"
fi

# install location
BIN="/usr/local/bin"
if [ ! -w "$BIN" ]; then
  BIN="$HOME/bin"
  mkdir -p "$BIN"
  WARN "Using $BIN (ensure it is in PATH)"
fi

TV="$BIN/tv"

# ---------- tv script ----------
cat > "$TV" <<'EOF'
#!/usr/bin/env bash
set -e

MPV=$(command -v mpv || true)
[ -z "$MPV" ] && { echo "mpv not found"; exit 1; }

if [ $# -lt 1 ]; then
  echo "Usage:"
  echo "  tv <video-file>"
  echo "  tv yt <url>"
  exit 1
fi

MODE="$1"

COLS=$(tput cols 2>/dev/null || echo 120)
MAX_COLS=600
WIDTH=$(( COLS > MAX_COLS ? MAX_COLS : COLS ))

COMMON_ARGS=(
  --no-config
  --vo=tct
  --profile=low-latency
  --vf=scale=${WIDTH}:-1:flags=bilinear,fps=20
  --no-sub
  --osd-level=0
)

# Prefer non-AV1 for terminal playback
YTDL_FMT="bestvideo[vcodec!=av1][height<=1080]+bestaudio/best"

if [ "$MODE" = "yt" ]; then
  URL="$2"
  [ -z "$URL" ] && { echo "tv yt <url>"; exit 1; }
  exec "$MPV" "${COMMON_ARGS[@]}" --ytdl-format="$YTDL_FMT" "$URL"
else
  exec "$MPV" "${COMMON_ARGS[@]}" "$MODE"
fi
EOF

chmod +x "$TV"
OK "tv installed"

echo
OK "installation complete"
echo
HDR "Try:"
HDR "  tv video.mp4"
HDR "  tv yt https://www.youtube.com/watch?v=..."
