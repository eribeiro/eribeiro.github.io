#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$REPO_ROOT/../reading-tracks"
DEST_DIR="$REPO_ROOT/reading-tracks"
DRY_RUN=false

usage() {
  printf 'Usage: %s [--source PATH] [--dry-run]\n' "$0"
  printf '\n'
  printf 'Sync the ReadingTracks runtime files into reading-tracks/.\n'
  printf 'The source defaults to the sibling checkout at ../reading-tracks.\n'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      if [[ $# -lt 2 ]]; then
        printf 'Error: --source requires a path.\n' >&2
        exit 2
      fi
      SOURCE_DIR="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Error: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

SOURCE_DIR="$(cd "$SOURCE_DIR" 2>/dev/null && pwd)" || {
  printf 'Error: ReadingTracks source directory not found.\n' >&2
  exit 1
}

for required_file in index.html app.js styles.css config.yaml; do
  if [[ ! -f "$SOURCE_DIR/$required_file" ]]; then
    printf 'Error: expected %s in %s\n' "$required_file" "$SOURCE_DIR" >&2
    exit 1
  fi
done

for required_dir in data assets vendor; do
  if [[ ! -d "$SOURCE_DIR/$required_dir" ]]; then
    printf 'Error: expected %s/ in %s\n' "$required_dir" "$SOURCE_DIR" >&2
    exit 1
  fi
done

RSYNC_ARGS=(-a --delete --delete-excluded --itemize-changes)
if [[ "$DRY_RUN" == true ]]; then
  RSYNC_ARGS+=(--dry-run)
fi

mkdir -p "$DEST_DIR"

rsync "${RSYNC_ARGS[@]}" \
  --include='/index.html' \
  --include='/app.js' \
  --include='/styles.css' \
  --include='/config.yaml' \
  --include='/data/***' \
  --include='/assets/***' \
  --include='/vendor/***' \
  --exclude='*' \
  "$SOURCE_DIR/" "$DEST_DIR/"

if [[ "$DRY_RUN" == true ]]; then
  printf 'Dry run complete; no files were changed.\n'
else
  printf 'ReadingTracks synced from %s to %s\n' "$SOURCE_DIR" "$DEST_DIR"
fi
