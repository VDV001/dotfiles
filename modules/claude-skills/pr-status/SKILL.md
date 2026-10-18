---
name: pr-status
description: Show the live stage strip of pull requests ("life of a change" - verified, CI, AI review, security, risk decision, merge, release) in the terminal and update the same strip as a comment in the PR. Use when the owner says "/pr-status", "что с PR", "на каком этапе", "статус PR", "где мы", "что по проектам", "что ждёт меня", or after opening, pushing to, reviewing or merging a PR.
---

# PR stage strip

The owner runs several projects at once and must see at a glance where every
change is, what is happening at that stage, when it happened and what is next.
This skill makes that visible. Write everything to the owner in Russian.

## Commands

The script is installed at `~/.claude/pr-status/pr-status.sh`.

| Owner asks | Run |
|---|---|
| this repo, my open PRs | `~/.claude/pr-status/pr-status.sh` |
| one PR | `~/.claude/pr-status/pr-status.sh 912` |
| all projects (`/pr-status all`, «что по проектам») | `~/.claude/pr-status/pr-status.sh all` |
| only look, do not touch PR comments | add `--no-post` |

The project list lives in `~/.config/pr-status/repos` (one `OWNER/REPO` per line).

## GitHub Actions is not relied on

The owner is on the free plan: Actions jobs do not start. Jobs that failed to
start for billing are ignored by the strip. The stages are confirmed locally by
commit statuses (free API):

| Status | Set by | Meaning |
|---|---|---|
| `local/ci` | the PostToolUse hook after `git push` (not `--no-verify`), or `pr-status.sh ci-passed` | the repo has a pre-push hook and HEAD reached the remote, so the gates passed |
| `local/review` | `pr-status.sh review ok|issues "summary" --body-file f.md` | your review by REVIEW.md |
| `local/security` | same with `--security` | your security pass |
| `local/visual` | `pr-status.sh visual ok|issues "what you looked at" --body-file f.md` | you opened the change in a browser and looked; required when the PR touches `web/`, `frontend/` or `*.tsx|jsx|vue|svelte|css|scss|html` |

## Local review, the required step after a PR is opened

1. Read the repo's `REVIEW.md` and the PR diff (`git diff origin/<base>...HEAD`,
   three dots: two dots also shows newer commits of the base).
2. Review only by REVIEW.md: defects with a file, line and failure scenario.
   No style notes, no praise. List what you did NOT check.
3. Write the findings to a file and record them:
   `~/.claude/pr-status/pr-status.sh review issues "N замечаний: ..." --body-file f.md`
   or `review ok "замечаний нет" --body-file f.md`.
4. For high-risk changes run the security pass too and record it with `--security`.
5. If the PR touches the frontend, the strip shows ✗ "Посмотрено глазами" and
   blocks the merge. Open the changed screens with Playwright at 390px and
   1280px, look at them (Read the screenshots), and record what you saw:
   `visual ok "390 и 1280: форма заявки, поля видны" --body-file f.md` with the
   URL, widths, what was checked and the screenshot paths. `visual issues` if
   something is wrong. Green tests do not count: an input with an undefined CSS
   token passes every test and is invisible on screen (deal-sense #495).
6. A new commit invalidates the statuses (they are per commit): after fixes,
   review only the new diff and record again.

## How to report

1. Run the command. It prints the strip and updates the comment in each PR.
2. Show its output **verbatim in a code block** so the columns stay aligned. Do
   not paraphrase it into prose and do not drop rows.
3. Below the block, at most three lines: what is blocking (✗), what is running
   (⏳), and what waits for the owner (◆). For `all`, the `ЖДЁТ ТЕБЯ` section
   already lists the ◆ rows; repeat nothing else.
4. If a row says Actions did not start because of billing, say so plainly: the
   code is not at fault and nothing will turn green until billing is fixed.

## Legend

✓ done automatically · ◆ a person decides · ⏳ running · ○ ahead or switched off · ✗ blocks · ↻ recovery

## Same strip during your own work

Before any verification, review, release or multi-step task, also show your own
strip in the same style (groups, icon, stage, one phrase about what is happening)
and show it again on every transition, not only at the end. Rows waiting for the
owner go into a separate `ЖДЁТ ТЕБЯ` group.

## Boundaries

- The script only reads PR data and writes one marked comment
  (`<!-- pipeline-status -->`). It never approves, merges or pushes.
- Do not post into repos that are not the owner's without asking: for someone
  else's repo use `--no-post`.
