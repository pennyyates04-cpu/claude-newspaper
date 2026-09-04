#!/usr/bin/env bash
#
# Turns text (the edition's TL;DR summary) into an MP3 via OpenAI's TTS API.
#
# Usage:
#   scripts/generate-audio.sh "<summary text>" <output.mp3>
#
# Requires in the environment:
#   OPENAI_API_KEY

set -euo pipefail

TEXT="${1:?usage: generate-audio.sh \"<summary text>\" <output.mp3>}"
OUT="${2:?usage: generate-audio.sh \"<summary text>\" <output.mp3>}"

: "${OPENAI_API_KEY:?OPENAI_API_KEY is not set}"

curl -sS -f https://api.openai.com/v1/audio/speech \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg text "$TEXT" '{model: "gpt-4o-mini-tts", voice: "alloy", input: $text, response_format: "mp3"}')" \
  --output "$OUT"

echo "generate-audio: wrote $OUT"
