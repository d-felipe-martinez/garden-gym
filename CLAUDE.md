# Garden Gym — project context

Read this before doing anything in this repo. It carries the full context of the
conversation that produced this app, which no longer exists anywhere else.

## What this is

A single-file personal workout tracker (`index.html`) for Danny — a deliberately
minimal web app he opens from his phone's home screen (GitHub Pages) in his garden
office gym. It guides him through resistance training sessions, logs sets, and
manages progression automatically.

**This stays a single static HTML file. No frameworks, no build step, no
package.json, no extra runtime assets. Ever.** Changes are edits to `index.html`.
The only other things in this repo: this file, `scripts/`, `form-notes.md`, and
optionally `training-wall-sheet.html` (a printable A4 backup of the plan).

## Who it's for and the non-negotiable rules

Danny is a **novice** lifter. Rules that must survive every future edit:

1. **No jargon without explanation.** Every exercise AND warm-up item is written
   in plain English with step-by-step instructions. Never assume he knows what a
   movement is called or how to do it. Any new movement needs steps, a "feels
   right when" line, a "stop if" safety line, and two hand-picked videos in PLAN:
   `short` — a quick demo (15–75 s, tap-and-see the movement) — and `vid` — a
   full tutorial, with `&t=<s>s` jumping past the intro when the video has
   chapter markers (never guess a timestamp; no chapters → no `t`). Verify both:
   oEmbed for existence/title, `"lengthSeconds"` on the watch page for duration,
   chapter timestamps from the description. `vq` keeps search terms for repair.
2. **Start slow, build up.** The app enforces a gentle ramp (see Volume below).
   Never make an edit that pushes intensity against a "too much" check-in. The
   default direction under uncertainty is easier, not harder.
3. **Minimalist UI.** One exercise per screen, near-monochrome (ink `#191b1e` on
   chalk `#fafaf7`, green `#4e7d18` only for done-states and accents), no
   decoration. When in doubt, remove.

## The science this app encodes

- **Why resistance training:** from the ZOE Science & Nutrition episode with
  Prof. Jimmy Bell (Imperial College) — "3 science-backed ways to shrink the belly
  fat linked to cancer and heart disease" (youtu.be/RcIU1ISszvo). Bell's ranked
  interventions for visceral fat: diet quality, "get breathless" cardio, and
  **resistance training as the single best tool**, because muscle mass drives
  long-term metabolic health. Body-composition change shows in ~12 weeks.
- **Volume target:** from Jeff Nippard's minimalist videos
  (youtube.com/watch?v=eMjyvIQbn9M and watch?v=xc4OtzAnVMI): ~**10 hard sets per
  muscle per week**, split over 2+ sessions, is the growth benchmark; 4–6 is the
  effective minimum. The app ramps toward 10.
- **Effort:** every set ends 1–2 clean reps short of failure. Form breakdown ends
  a set, not the rep target.
- **Progression:** double progression — hit the top of the rep range on all sets
  AND the last session didn't feel like "too much" → add 1.25 kg (or the harder
  variation).
- **Volume ≠ reps, frequency ~neutral:** Pelland et al. 2025 dose-response
  meta-regression (Sports Medicine) — weekly hard SETS drive hypertrophy with
  diminishing returns; at equal volume, extra frequency adds ~nothing for
  growth. So reach 10 sets via the set ramp, never by dropping rest days or
  padding reps.
- **Rest between sets:** Singer et al. 2024 Bayesian meta-analysis — ≥60 s
  beats <60 s; beyond that differences are modest. Encoded: 90 s default,
  60 s for core/carries (`rest` field), floor is 60 — don't go below.
- **Stretching:** post-exercise stretching does NOT prevent DOMS (Afonso 2021
  meta-analysis); consistent stretching DOES improve ROM/perceived stiffness
  over weeks (Sports Med 2025 meta-regression). Hence the standalone evening
  Stretch screen, honestly framed — never sell it as soreness prevention.

## Equipment inventory (all exercises must map to this)

- Power tower: pull-up bar, dip handles, forearm pads for knee raises
- Thick black resistance band + light red band (assistance / pull-aparts)
- 12 kg cast-iron kettlebell, 10 kg soft kettlebell
- Two loadable 1" bars with spring collars; plates: 1.25 kg ×2 (green),
  2.5 kg, 5 kg (rubber); one foam-padded bar
- 20" soft plyo box (pull-up assist / negatives, step-ups if ever needed)
- Ab roller wheel (harder progression from knee raises)
- Mirafit aerobic step platform
- Two exercise mats; grey fabric loop band; red + teal flat therabands;
  a handled skipping rope (probably — confirm before programming it)
- Elgato Facecam 4K + Camera Hub in the garden office (records sessions)
- Spin bike (warm-ups and optional interval day)
- Planned: Apple Watch (~Sept 2026); a ~£1,000 all-in-one machine is deferred
  until this kit stops progress (~6–12 months)

## How the app works (architecture)

- **Screens:** home → get-ready (setup checklist + warm-up) → one exercise at
  a time → feel check-in → done. Plus History, Stretch (standalone evening
  checklist), and Guide, linked from home.
- **Data:** one JSON blob under storage key `gym-log-v2`:
  `{sessions:[{date:"YYYY-MM-DD", type:"A"|"B", feel:"easy"|"right"|"much",
  startedAt:ISO-string|null, entries:{exId:[{w:number|null, r:number,
  t:number|null}]}}]}` where `t` is **seconds since Begin was tapped** (older
  sessions may lack `t`/`startedAt` — tolerate that). Never rename the key or
  break this schema without migrating existing data.
- **Storage adapter** (`store`): uses `window.storage` when running as a Claude
  artifact, otherwise `localStorage` (GitHub Pages). Keep both paths working.
- **Session suggestion:** home recommends A or B by alternating from the last
  logged session.
- **Volume ramp** (`rampSets`): first 2 sessions of a type → 2 sets/exercise;
  then 3; after 8 sessions of a type, 3-set exercises unlock a 4th set unless the
  last session of that type felt like "too much". Timed carries stay at 2.
- **Feel-based gating:** "too much" suppresses add-weight suggestions and shows
  a "same weights, stop a rep earlier" nudge on every exercise next session.
- **Weight & reps prefill:** inputs come pre-filled so Danny types nothing on
  a normal day. Weight: last session's, bumped by 1.25 kg when every set topped
  the range and the session didn't feel like too much, or the exercise's
  `start` value on day one (`start` assumes the ~5 kg bar). Reps: the top of
  the rep range (`hi`) — he edits down when a set ends early. Everything is
  overtypeable; a tick logs whatever the boxes show.
- **Session clock:** `cur.start` is set when Begin is tapped; every logged set
  stores `t`. The warm-up screen tells Danny to start the Camera Hub recording
  just before tapping Begin, so `t` ≈ video timestamp. This powers form checks.
- **Rest timer:** per-exercise `rest` field (default 90 s, 60 s core/carries,
  0 = no timer, e.g. bike intervals). Starts on set-tick, tap to dismiss.
  Chimes via Web Audio at zero — the AudioContext is unlocked on set-tick
  (user gesture); keep that or iOS silences it.
- **How-to videos:** each exercise's fold-out shows "Quick demo" (`short`)
  leading and "Full tutorial" (`vid`) muted beside it; both optional in
  render (bike has none — not a new movement).
- **Form tips:** each exercise may carry a `tip` — the latest form-check note,
  rendered on the exercise screen. "process video" sessions rewrite these.
- **Setup checklist** (`SETUP`): water, trainers (he lifted in socks once),
  AirPods, camera recording + whole tower in frame, floor clear, Apple Watch
  (placeholder until it arrives).
- **CSV export:** `date,session,feel,exercise,set,weight_kg,reps,t_sec`.

## The training plan (encoded in the PLAN object)

- Session A — Squat & Push: Goblet Squat, Assisted Dips, Overhead Press,
  Romanian Deadlift, Knee Raise (pads).
- Session B — Pull & Hinge: Pull-Up, Bent-Over Row, Reverse Lunge, Floor Press,
  Suitcase Carry.
- Session S — Saturday Extras (optional, light, no ramp): Suitcase Carry, Knee
  Raise, Bike Intervals 4–6 × (30 s hard / 90 s easy). S reuses the same
  exercise objects/ids as A/B, so edits and history stay in sync. The home
  A/B alternation ignores S (`lastMain()`).
- Progression chains set after the first form review (2026-08-17):
  dips — box-assisted (two feet → one foot → toes → free; the band alone
  wasn't enough); knee raise — pads first (he swung when hanging) → hanging →
  ab-wheel rollouts.
- Schedule: Mon/Wed/Fri alternating A-B-A then B-A-B; rest days are load-
  bearing, don't program them away.

## Workflows

### Deploy
GitHub Pages from main branch root. After any edit to `index.html`: commit, push,
verify the live URL still loads and contains "Garden Gym".

### "process video" — the form-check command
Danny records **one video per whole session** in Elgato Camera Hub, started just
before he taps Begin in the app. When he says **"process video"** (or similar),
do ALL of this without further questions:

1. **Find the recording:** newest video file across Camera Hub's recording
   folder and `~/Downloads` (the first real session landed in Downloads, not
   `~/Pictures/Camera Hub` — both are scanned by `scripts/process-video.sh`).
2. **Locate the working sets.** Preferred path: if Danny pasted or attached a
   CSV export (or mentions set times), use `t_sec` — extract frames from `t-45s`
   to `t+10s` for the LAST set of each exercise (the money set: fatigue shows
   form truth). Fallback path (no timestamps): run the script's `--sheets` mode
   to tile 1 frame/5 s into contact-sheet grids, view them to identify each
   exercise segment by posture and equipment, then extract full-res frames for
   1–2 sets per exercise.
3. **Pull key positions:** for each chosen set, extract ~6 frames at 1280 px,
   then view and keep the 3 that show: start position, hardest mid-point
   (bottom of squat / top of pull), and lockout/finish.
4. **Critique.** Judge only against the matching exercise's `steps`, `feel`, and
   `stop` lines in the `PLAN` object in `index.html`. Movement-specific checks:
   - Goblet Squat / Reverse Lunge: heels down, knees tracking over toes, chest up
   - Romanian Deadlift / Bent-Over Row: flat back (no rounding), bar close to legs
   - Overhead Press: no lean-back at lockout, bar finishing over mid-head
   - Dips / Floor Press: forearms vertical, controlled 2–3 s lowering
   - Pull-Up: dead-hang start, no kicking, chin clears bar
   - Suitcase Carry / Knee Raise: level shoulders / no swinging
   **Maximum one or two corrections per exercise** — he's a novice; don't bury
   him. Lead with the single highest-impact fix, name what's already good, and
   if anything looks unsafe (rounded lower back under load, shoulder impingement
   pattern) tell him to lower the weight or use the listed easier variation.
5. **Record it:** append to `form-notes.md` — date, exercises reviewed, the
   correction(s) given, one line each. Read existing notes first; if the same
   fault appears in 2+ sessions, open the critique with that recurring pattern.
   Then update the affected exercises' `tip` fields in the PLAN object (and
   clear tips that are fixed) so the next session shows the latest note.
6. **Report** a short summary: per exercise, one line of praise + the fix.
   Offer to delete or archive the processed video.

### Editing the plan
Exercise text lives in the `PLAN` object. Any new exercise must use available
equipment, follow the plain-English rules, and keep IDs stable (history is keyed
on them). If Danny reports pain or a plateau in a movement, prefer swapping to a
listed easier/harder variation over inventing novel movements.

## Roadmap (only when asked)
- Apple Watch arrives ~Sept 2026: session HR via built-in Workout app
  ("Traditional Strength Training"); consider CSV → Hevy migration if he wants
  wrist logging.
- The £1,000 machine decision: revisit when pull-ups exceed bodyweight capacity,
  plates max out on rows/presses, or he wants cable/leg-press patterns.
