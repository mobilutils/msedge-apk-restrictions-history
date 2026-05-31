#!/bin/bash
set -euo pipefail

PATH_EDGE_RESTRICTIONS_EXTRACTOR="/Users/enola/Workspace-gitmobilutils/msedge-apk-restrictions-extract"
PATH_EDGE_RESTRICTIONS_HISTORY="/Users/enola/Workspace-gitmobilutils/msedge-apk-restrictions-history"

# ── Helper: commit & push the latest extracted version ──────────────────────
commit_if_new() {
  cd "${PATH_EDGE_RESTRICTIONS_HISTORY}"

  # Nothing to commit?
  if ! git diff --quiet HEAD -- MicrosoftEdge_restrictions_history/; then
    # Detect the latest version folder
    local LATEST_MSEDGE_RESTRICTIONS_DIRNAME
    LATEST_MSEDGE_RESTRICTIONS_DIRNAME="$(ls -d com.microsoft.emmx* 2>/dev/null | sort -V | tail -n 1)" || true

    if [[ -z "${LATEST_MSEDGE_RESTRICTIONS_DIRNAME}" ]]; then
      echo "No versioned folder found — nothing to commit."
      return 0
    fi

    local MSEDGE_APK_VERSION
    MSEDGE_APK_VERSION="$(echo "${LATEST_MSEDGE_RESTRICTIONS_DIRNAME}" | cut -d '_' -f 2)"

    echo "Committing version: ${MSEDGE_APK_VERSION}"

    # Stage everything under the history folder (new folders + updated logs.txt, etc.)
    git add MicrosoftEdge_restrictions_history/

    git commit -m "${MSEDGE_APK_VERSION}"

    git push
  else
    echo "No changes since last commit — skipping."
  fi
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

