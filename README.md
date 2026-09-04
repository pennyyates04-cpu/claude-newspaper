# Claude Newspaper

A daily personal newspaper, written and delivered automatically.

## How it works

```
 ┌─────────────────┐     ┌──────────────────────┐     ┌──────────────────────┐
 │  Routine (cron) │ ──▶ │  Claude cloud agent  │ ──▶ │  this GitHub repo    │
 │  daily 7am ET   │     │  researches + writes │     │  git push to master  │
 └─────────────────┘     └──────────────────────┘     └──────────┬───────────┘
                                                                  │ triggers
                                                                  ▼
                                                       ┌──────────────────────┐
                                                       │  GitHub Actions      │
                                                       │  (normal internet)   │
                                                       └──────────┬───────────┘
                                                                  │
                                                                  ▼
                                                       ┌──────────────────────┐
                                                       │  Telegram bot        │
                                                       │  DMs the edition     │
                                                       └──────────────────────┘
```

1. A **scheduled cloud routine** (managed at <https://claude.ai/code/routines>) fires once a day.
2. It spins up a Claude Code cloud agent that clones this repo.
3. The agent alternates by day-of-year between two tracks (see `config.json`):
   - **Health & Regenerative Medicine** — [`guidelines/health-regenerative-medicine.md`](guidelines/health-regenerative-medicine.md)
   - **Tech, Business & Sales** (Oracle NetSuite SDR focus) — [`guidelines/tech-business-sales.md`](guidelines/tech-business-sales.md)
4. It researches the day's developments with web search, writes the edition following
   [`templates/edition.md`](templates/edition.md) — TL;DR at the top, full stories below —
   and commits it to [`editions/`](editions/) (`latest.md` always mirrors the newest one).
5. If audio is enabled, it turns the TL;DR into a spoken summary with
   [`scripts/generate-audio.sh`](scripts/generate-audio.sh) (OpenAI TTS) and commits
   `latest.mp3` too.
6. **The routine's job ends at `git push`.** A separate
   [`.github/workflows/notify-telegram.yml`](.github/workflows/notify-telegram.yml) GitHub
   Actions workflow fires on that push and delivers `editions/latest.md` (+ `latest.mp3` if
   present) to Telegram via [`scripts/send-telegram.sh`](scripts/send-telegram.sh). This
   split exists because the routine's cloud sandbox has restricted network egress and
   cannot reach `api.telegram.org` directly — GitHub's own runners can.

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

This repo is **public**, so no credentials live in tracked files.

- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` — **GitHub Actions repository secrets**
  (Settings → Secrets and variables → Actions). Used by
  `.github/workflows/notify-telegram.yml`, which calls `scripts/send-telegram.sh`.
- `OPENAI_API_KEY` — stored in the routine's prompt/environment at
  <https://claude.ai/code/routines> (private to the account that owns the routine). Used by
  `scripts/generate-audio.sh`, which the routine itself runs (audio generation needs to
  happen before the commit, so it can't be a GitHub Action step).

## Changing the schedule or format

- **Schedule / delivery target:** update the routine at <https://claude.ai/code/routines>.
- **Content, sections, tone:** edit `prompts/daily-routine.md`, `templates/edition.md`, or
  `config.json`, push, then re-point the routine at the new prompt.
