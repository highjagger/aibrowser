#!/usr/bin/env bash
set -e

# Default settings
MODE="headless"
BROWSER="firefox"
IMAGE_NAME="aibrowser:latest"

usage() {
  echo "Usage: $0 [--gui | --headless] [--browser <firefox|chromium|webkit>] [--build]"
  echo ""
  echo "Options:"
  echo "  --gui                  Run in headed GUI mode (opens browser window locally via X11)"
  echo "  --headless             Run in headless mode (default, for CI / Cloud Compute)"
  echo "  --browser <name>       Choose browser engine (firefox [default], chromium, webkit)"
  echo "  --build                Force rebuild the Docker image before running"
  echo "  --help                 Show this help message"
  exit 0
}

DO_BUILD=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --gui)
      MODE="gui"
      shift
      ;;
    --headless)
      MODE="headless"
      shift
      ;;
    --browser)
      BROWSER="$2"
      shift 2
      ;;
    --build)
      DO_BUILD=true
      shift
      ;;
    --help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Build image if it doesn't exist or --build flag passed
if [[ "$DO_BUILD" = true ]] || [[ "$(docker images -q "$IMAGE_NAME" 2> /dev/null)" == "" ]]; then
  echo "==> Building Docker image: $IMAGE_NAME ..."
  docker build -t "$IMAGE_NAME" .
fi

if [[ "$MODE" == "gui" ]]; then
  echo "==> Running in GUI mode (headed) with $BROWSER ..."
  # Authorize local container connections to X11
  if command -v xhost >/dev/null 2>&1; then
    xhost +local: >/dev/null 2>&1 || true
  fi

  docker run --rm -it \
    --ipc=host \
    --net=host \
    -e DISPLAY="${DISPLAY:-:0}" \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v "$SCRIPT_DIR":/app \
    -e HEADLESS=false \
    -e BROWSER="$BROWSER" \
    "$IMAGE_NAME"
else
  echo "==> Running in HEADLESS mode with $BROWSER ..."
  docker run --rm -it \
    --ipc=host \
    -v "$SCRIPT_DIR":/app \
    -e HEADLESS=true \
    -e BROWSER="$BROWSER" \
    "$IMAGE_NAME"
fi
