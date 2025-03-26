#!/bin/bash
set -e

if curl -s http://localhost:8082/artifactory/api/v1/system/ping | grep -q "OK"; then
  echo "✅ Artifactory is already running. Skipping installation."
  exit 0
fi

if [[ -z "${JFROG_HOME}" ]]; then
    JFROG_HOME=~/jfrog_home
fi
LOG_DIR="$JFROG_HOME/artifactory/var/log"
mkdir -p "$LOG_DIR"
ZIP_FILE="$HOME/artifactory-logs.zip"
echo "📦 Running local Artifactory setup..."
go install github.com/jfrog/jfrog-testing-infra/local-rt-setup@main
if [[ -n "${VERSION}" ]]; then
  ~/go/bin/local-rt-setup --rt-version "$VERSION"
else
  ~/go/bin/local-rt-setup
fi

zip -j "$ZIP_FILE" "$LOG_DIR"/*.log
echo "📤 Uploading logs..."
curl -sL https://github.com/actions/upload-artifact/releases/latest/download/upload-artifact-linux -o upload-artifact
chmod +x upload-artifact
./upload-artifact --name artifactory-logs --path "$ZIP_FILE" || echo "⚠️ Failed to upload logs"