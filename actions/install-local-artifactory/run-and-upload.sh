#!/bin/bash
set -e

PING_RESPONSE=$(curl -s http://localhost:8082/artifactory/api/v1/system/ping)
echo "🔍 Ping response: $PING_RESPONSE"
if echo "$PING_RESPONSE" | grep -q "OK"; then
  echo "✅ Artifactory is already running. Skipping installation."
  exit 0
fi

if [[ -z "${JFROG_HOME}" ]]; then
    JFROG_HOME=~/jfrog_home
fi

if [[ -d "${JFROG_HOME}" ]]; then
  echo "🗑️ Deleting existing JFROG_HOME directory at ${JFROG_HOME}..."
  rm -rf "${JFROG_HOME}"
fi

LOG_DIR="$JFROG_HOME/artifactory/var/log"
ZIP_FILE="$HOME/artifactory-logs.zip"
echo "📦 Running local Artifactory setup..."
go install github.com/jfrog/jfrog-testing-infra/local-rt-setup@main
if [[ -n "${VERSION}" ]]; then
  ~/go/bin/local-rt-setup --rt-version "$VERSION"
else
  ~/go/bin/local-rt-setup
fi

OS_NAME="$(uname -s)"

if [[ "$OS_NAME" == MINGW* || "$OS_NAME" == MSYS* || "$OS_NAME" == CYGWIN* ]]; then
  echo "⚠️ Zip step skipped on Windows — not supported in bash mode"
else
  echo "🐧 Unix-like system detected — using zip"
  if command -v zip >/dev/null 2>&1; then
    zip -j "$ZIP_FILE" "$LOG_DIR"/*.log || echo "⚠️ Failed to zip logs"
  else
    echo "❌ 'zip' command not found"
  fi
fi

echo "📤 Skipping direct upload inside action."
echo "ℹ️ Please add a step in your workflow using 'actions/upload-artifact' to upload the file: $ZIP_FILE"