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
if [[ "$OS_NAME" == "MINGW"* || "$OS_NAME" == "MSYS"* || "$OS_NAME" == "CYGWIN"* ]]; then
  echo "Windows detected — using PowerShell to compress logs"
  LOG_DIR_WIN=$(cygpath -w "$LOG_DIR")
  ZIP_FILE_WIN=$(cygpath -w "$ZIP_FILE")
  powershell.exe -Command "Compress-Archive -Path '${LOG_DIR_WIN}\\*.log' -DestinationPath '${ZIP_FILE_WIN}'"
else
  echo "🐧 Linux/macOS detected — using zip"
  if command -v zip >/dev/null 2>&1; then
    zip -j "$ZIP_FILE" "$LOG_DIR"/*.log || echo "⚠️ Failed to zip logs"
  else
    echo "❌ 'zip' command not found"
  fi
fi

echo "📤 Uploading logs..."
curl -sL https://github.com/actions/upload-artifact/releases/latest/download/upload-artifact-linux -o upload-artifact
chmod +x upload-artifact
./upload-artifact --name artifactory-logs --path "$ZIP_FILE" || echo "⚠️ Failed to upload logs"