#!/bin/bash
set -e

PING_RESPONSE=""
CURL_EXIT_CODE=0

PING_RESPONSE=$(curl -s http://localhost:8082/artifactory/api/v1/system/ping) || CURL_EXIT_CODE=$?

if [[ $CURL_EXIT_CODE -ne 0 ]]; then
  echo "⚠️ Curl failed with exit code $CURL_EXIT_CODE — Continuing with installation."
else
  echo "🔍 Ping response: $PING_RESPONSE"
  if echo "$PING_RESPONSE" | grep -q "OK"; then
    echo "✅ Artifactory is already running. Skipping installation."
    exit 0
  fi
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

echo "📦 Zipping logs for macOS/Linux"

if command -v zip >/dev/null 2>&1; then
  if compgen -G "$LOG_DIR"/*.log > /dev/null; then
    zip -j "$ZIP_FILE" "$LOG_DIR"/*.log
  else
    echo "⚠️ No logs found to zip"
    touch "$ZIP_FILE"
  fi
else
  echo "❌ 'zip' command not found"
  touch "$ZIP_FILE"
fi

echo "📤 Skipping direct upload inside action."
echo "ℹ️ Please add a step in your workflow using 'actions/upload-artifact' to upload the file: $ZIP_FILE"