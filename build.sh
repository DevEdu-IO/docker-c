#!/usr/bin/env bash
#
# Build the code-esaas image with docker buildx.
#
# Usage:
#   ./build.sh                          Verify-build amd64 + arm64 (no output kept).
#   ./build.sh --load                   Build for the host arch and load into local docker.
#   ./build.sh --push                   Build amd64 + arm64 and push as a multi-arch image.
#                                       Requires `docker login`.
#   ./build.sh --tag <ref>              Image tag. Repeat for multiple tags, e.g.
#                                         --tag deveduio/cpp:latest --tag deveduio/cpp:1.0.0
#                                       Default if omitted: deveduio/cpp:latest.
#   ./build.sh --platforms <list>       Override platform list (default linux/amd64,linux/arm64).
#
# Env overrides: TAGS (space-separated list), PLATFORMS, DOCKERFILE, BUILDER_NAME.

set -euo pipefail

read -ra TAGS <<<"${TAGS:-}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
BUILDER_NAME="${BUILDER_NAME:-multiarch}"
MODE="verify"

usage() { sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --load)      MODE="load"; shift ;;
    --push)      MODE="push"; shift ;;
    --tag)       TAGS+=("$2"); shift 2 ;;
    --platforms) PLATFORMS="$2"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    *)           echo "unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ ${#TAGS[@]} -eq 0 ]]; then
  TAGS=("deveduio/cpp:latest")
fi

# --load can only emit one platform via the docker driver. Pick the host's.
if [[ "$MODE" == "load" ]]; then
  case "$(uname -m)" in
    x86_64)         PLATFORMS="linux/amd64" ;;
    aarch64|arm64)  PLATFORMS="linux/arm64" ;;
    *) echo "unknown host arch: $(uname -m)" >&2; exit 1 ;;
  esac
fi

# --push needs a real registry path on every tag.
if [[ "$MODE" == "push" ]]; then
  for t in "${TAGS[@]}"; do
    [[ "$t" == */* ]] || { echo "--push requires every --tag as <repo/name:tag> (got '$t')" >&2; exit 2; }
  done
fi

# Prereqs.
command -v docker >/dev/null || { echo "missing: docker" >&2; exit 1; }
docker buildx version >/dev/null 2>&1 || {
  echo "docker buildx not installed. On Arch: sudo pacman -S docker-buildx" >&2
  exit 1
}

# Register arm64 emulator if we'll need it. Idempotent; non-persistent across reboots.
if [[ "$PLATFORMS" == *arm64* && ! -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]]; then
  echo ">>> registering arm64 QEMU emulator"
  docker run --privileged --rm tonistiigi/binfmt --install arm64 >/dev/null
fi

# Builder must use the docker-container driver to emit multi-arch.
if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
  echo ">>> creating buildx builder '$BUILDER_NAME'"
  docker buildx create --name "$BUILDER_NAME" --driver docker-container >/dev/null
fi
docker buildx use "$BUILDER_NAME"

TAG_ARGS=()
for t in "${TAGS[@]}"; do TAG_ARGS+=(-t "$t"); done

case "$MODE" in
  verify)
    echo ">>> verify-build for $PLATFORMS"
    docker buildx build --platform "$PLATFORMS" -f "$DOCKERFILE" .
    ;;
  load)
    echo ">>> build+load ${TAGS[*]} for $PLATFORMS"
    docker buildx build --platform "$PLATFORMS" -f "$DOCKERFILE" "${TAG_ARGS[@]}" --load .
    ;;
  push)
    echo ">>> build+push ${TAGS[*]} for $PLATFORMS"
    docker buildx build --platform "$PLATFORMS" -f "$DOCKERFILE" "${TAG_ARGS[@]}" --push .
    ;;
esac
