# Claude Newspaper

A daily personal newspaper, written and delivered automatically.

## How it works

```
 ┌─────────────────┐     ┌──────────────────────┐     ┌─────────────────┐
 │  Routine (cron) │ ──▶ │  Claude cloud agent  │ ──▶ │  Telegram bot   │
 │  daily 7am ET   │     │  researches + writes │     │  DMs the edition│
 └─────────────────┘     └──────────┬───────────┘     └─────────────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │  this GitHub repo    │
                         │  editions/ archive   │
                         └──────────────────────┘
```

1. A **scheduled cloud routine** (managed at <https://claude.ai/code/routines>) fires once a day.
2. It spins up a Claude Code cloud agent that clones this repo.
3. The agent alternates by day-of-year between two tracks (see `config.json`):
   - **Health & Regenerative Medicine** — [`guidelines/health-regenerative-medicine.md`](guidelines/health-regenerative-medicine.md)
   - **Tech, Business & Sales** (Oracle NetSuite SDR focus) — [`guidelines/tech-business-sales.md`](guidelines/tech-business-sales.md)
4. It researches the day's developments with web search, writes the edition following
   [`templates/edition.md`](templates/edition.md) — TL;DR at the top, full stories below —
   and commits it to [`editions/`](editions/).
5. It turns the TL;DR into a spoken summary with [`scripts/generate-audio.sh`](scripts/generate-audio.sh) (OpenAI TTS).
6. It delivers both the full edition and the audio summary to Telegram via
   [`scripts/send-telegram.sh`](scripts/send-telegram.sh).

## Repo layout

| Path | Purpose |
|------|---------|
| `prompts/daily-routine.md` | The exact instructions the routine runs. Edit here, then update the routine. |
| `guidelines/health-regenerative-medicine.md` | Editorial brief for the health track. |
| `guidelines/tech-business-sales.md` | Editorial brief for the tech/business/sales track. |
| `templates/edition.md` | The format every edition follows (TL;DR + per-track story fields). |
| `scripts/send-telegram.sh` | Delivers the Markdown edition (+ optional MP3) to Telegram. |
| `scripts/generate-audio.sh` | Turns the TL;DR into an MP3 via OpenAI TTS. |
| `editions/YYYY-MM-DD.md` / `.mp3` | One file per published edition, plus its audio summary. |
| `editions/latest.md` | Always a copy of the most recent edition. |
| `config.json` | Track alternation rule, format, and editorial rules. |

## Secrets

This repo is **public**, so no credentials live here. The Telegram bot token, chat ID, and
OpenAI API key are stored in the routine's prompt/environment (private to the account that
owns the routine). The scripts read them from the environment:

- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` — used by `scripts/send-telegram.sh`
- `OPENAI_API_KEY` — used by `scripts/generate-audio.sh`

## Changing the schedule or format

- **Schedule / delivery target:** update the routine at <https://claude.ai/code/routines>.
- **Content, sections, tone:** edit `prompts/daily-routine.md`, `templates/edition.md`, or
  `config.json`, push, then re-point the routine at the new prompt.
