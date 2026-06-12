#!/bin/bash
set -euo pipefail

# ── Parse arguments ────────────────────────────────────────────────────────────
extractor_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --extractor-path)
      extractor_path="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${extractor_path}" ]]; then
  echo "Error: --extractor-path is required" >&2
  exit 1
fi

PATH_EDGE_RESTRICTIONS_EXTRACTOR="${extractor_path}"
PATH_EDGE_RESTRICTIONS_HISTORY="$(cd "$(dirname "$0")" && pwd)"

# ── Helper: commit & push the latest extracted version ──────────────────────
commit_if_new() {
  cd "${PATH_EDGE_RESTRICTIONS_HISTORY}"

    # Detect any changes (tracked modifications + untracked files/folders)
  local STATUS_OUTPUT
  STATUS_OUTPUT="$(git status --porcelain -- MicrosoftEdge_restrictions_history/)"

  if [[ -z "${STATUS_OUTPUT}" ]]; then
    echo "No changes since last commit — skipping."
    return 0
  fi

    # Check if only logs.txt has changed — if so, skip commit
  local CHANGED_FILES
  CHANGED_FILES="$(echo "${STATUS_OUTPUT}" | grep -v 'logs\.txt$' || true)"

  if [[ -z "${CHANGED_FILES}" ]]; then
    echo "Only logs.txt has changed — skipping commit."
    return 0
  fi

    # Detect the latest version folder
    local LATEST_MSEDGE_RESTRICTIONS_DIRNAME

    cd MicrosoftEdge_restrictions_history
    LATEST_MSEDGE_RESTRICTIONS_DIRNAME="$(ls -d com.microsoft.emmx* 2>/dev/null | sort -V | tail -n 1)" || true

    if [[ -z "${LATEST_MSEDGE_RESTRICTIONS_DIRNAME}" ]]; then
      echo "No versioned folder found — nothing to commit."
      return 0
    fi
    cd "${PATH_EDGE_RESTRICTIONS_HISTORY}"
    echo "Versioned folder: ${LATEST_MSEDGE_RESTRICTIONS_DIRNAME}"

    local MSEDGE_APK_VERSION
    MSEDGE_APK_VERSION="$(echo "${LATEST_MSEDGE_RESTRICTIONS_DIRNAME}" | cut -d '_' -f 2)"

    echo "Committing version: ${MSEDGE_APK_VERSION}"

    # Stage everything under the history folder (new folders + updated logs.txt, etc.)
    git add MicrosoftEdge_restrictions_history/

    git commit -m "${MSEDGE_APK_VERSION}"

    git push
}

# ── Main ────────────────────────────────────────────────────────────────────

# Run the extractor once to produce the latest versioned folder
cd "${PATH_EDGE_RESTRICTIONS_EXTRACTOR}"
./main.sh

# Copy extracted data (excluding .apk) into the history repo
rsync -av --exclude '*.apk' \
   "${PATH_EDGE_RESTRICTIONS_EXTRACTOR}/PlaystoreDL_MicrosoftEdge/" \
   "${PATH_EDGE_RESTRICTIONS_HISTORY}/MicrosoftEdge_restrictions_history/"

# Attempt to commit & push any new version
commit_if_new
