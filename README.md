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
   It also renders the same content as a newspaper-styled page from
   [`templates/edition.html`](templates/edition.html) (`editions/YYYY-MM-DD.html` +
   `latest.html`), published via **GitHub Pages** at
   <https://pennyyates04-cpu.github.io/claude-newspaper/editions/latest.html>.
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
| `templates/edition.md` | The Markdown format every edition follows (TL;DR + per-track story fields). |
| `templates/edition.html` | The newspaper-styled HTML format, published via GitHub Pages. |
| `scripts/send-telegram.sh` | Delivers the Markdown edition (+ optional MP3) to Telegram. |
| `scripts/generate-audio.sh` | Turns the TL;DR into an MP3 via OpenAI TTS. |
| `editions/YYYY-MM-DD.md` / `.html` / `.mp3` | One set of files per published edition. |
| `editions/latest.md` / `.html` | Always a copy of the most recent edition. |
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

## GitHub Pages (one-time setup)

The newspaper-styled `.html` editions are only reachable at
`https://pennyyates04-cpu.github.io/claude-newspaper/...` once Pages is turned on for this
repo — that's a repo-settings change only a human with admin access can make:

1. Repo → **Settings → Pages**
2. Source: **Deploy from a branch**. Branch: **master**, folder: **/ (root)**
3. Save. The site is live within a minute or two at the URL above.

`.nojekyll` is already committed so GitHub serves the raw HTML/CSS as-is instead of running
it through Jekyll.

## Changing the schedule or format

- **Schedule / delivery target:** update the routine at <https://claude.ai/code/routines>.
- **Content, sections, tone:** edit `prompts/daily-routine.md`, `templates/edition.md`, or
  `config.json`, push, then re-point the routine at the new prompt.

### Daylight saving time

Routine cron expressions run in fixed UTC — there's no timezone-aware cron, so "7am ET"
drifts by an hour twice a year unless the cron is updated by hand:

| Period | Cron (UTC) | = 7:00am ET |
|---|---|---|
| EDT (mid-Mar – early Nov) | `0 11 * * *` | ✅ current |
| EST (early Nov – mid-Mar) | `0 12 * * *` | switch on the first Sunday of November |

Update the cron at <https://claude.ai/code/routines> when clocks change.
