#!/usr/bin/env bash
#
# Deliver a newspaper edition to Telegram: the full edition as a Markdown document,
# plus (optionally) a spoken summary as an audio message.
#
# Usage:
#   scripts/send-telegram.sh <edition.md> "<caption>" [summary.mp3]
#
# Requires in the environment:
#   TELEGRAM_BOT_TOKEN   from @BotFather
#   TELEGRAM_CHAT_ID     numeric id of the destination chat
#
# The document is sent first (sidesteps Telegram's 4096-char message limit); if a third
# argument (an mp3 path) is given, it's sent right after as a voice-note style audio clip.

set -euo pipefail

FILE="${1:?usage: send-telegram.sh <edition.md> [caption] [summary.mp3]}"
CAPTION="${2:-New edition}"
AUDIO="${3:-}"

: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN is not set}"
: "${TELEGRAM_CHAT_ID:?TELEGRAM_CHAT_ID is not set}"

if [[ ! -f "$FILE" ]]; then
  echo "send-telegram: file not found: $FILE" >&2
  exit 1
fi

API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"

if curl -sS -f -X POST "${API}/sendDocument" \
     -F "chat_id=${TELEGRAM_CHAT_ID}" \
     -F "document=@${FILE};type=text/markdown" \
     -F "caption=${CAPTION}" >/dev/null; then
  echo "send-telegram: delivered ${FILE} to chat ${TELEGRAM_CHAT_ID}"
else
  echo "send-telegram: sendDocument failed, trying a truncated text message" >&2
  BODY="$(head -c 3800 "$FILE")"
  curl -sS -f -X POST "${API}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${CAPTION}"$'\n\n'"${BODY}" >/dev/null
  echo "send-telegram: delivered truncated text fallback"
fi

if [[ -n "$AUDIO" ]]; then
  if [[ ! -f "$AUDIO" ]]; then
    echo "send-telegram: audio file not found: $AUDIO (skipping audio send)" >&2
  else
    curl -sS -f -X POST "${API}/sendAudio" \
      -F "chat_id=${TELEGRAM_CHAT_ID}" \
      -F "audio=@${AUDIO};type=audio/mpeg" \
      -F "title=${CAPTION} (audio summary)" >/dev/null
    echo "send-telegram: delivered audio summary ${AUDIO}"
  fi
fi
