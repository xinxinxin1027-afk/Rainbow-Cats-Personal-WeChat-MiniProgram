#!/usr/bin/env bash
set -euo pipefail
if [[ -z "${RAINBOW_KEYSTORE_BASE64:-}" ]]; then
  echo "未配置正式签名 Secrets，将使用 Flutter 默认侧载签名。"
  exit 0
fi
KEYSTORE_PATH="$RUNNER_TEMP/rainbow-cats-release.jks"
printf '%s' "$RAINBOW_KEYSTORE_BASE64" | base64 --decode > "$KEYSTORE_PATH"
echo "RAINBOW_KEYSTORE_PATH=$KEYSTORE_PATH" >> "$GITHUB_ENV"
