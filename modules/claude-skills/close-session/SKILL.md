---
name: close-session
description: Close out a work session — update both memory layers, write a handoff draft and a next-session prompt, and report what is genuinely unfinished. Use when the user says "закрываем сессию", "заканчиваем", "обновляй память и пиши промпт", "/close-session", or otherwise signals the session is ending.
---

# Closing a session

Run this end-to-end without asking for confirmation between steps. The user
invokes it precisely so they do not have to spell the routine out again.

Write everything **in Russian** — this file is in English, the artefacts are not.

## The one rule that outranks the rest

**Report only what you verified.** A session log that overstates is worse than
no log: the next session trusts it and builds on sand. If something was
started and not finished, say so in those words. If a claim rests on a single
run, name the scope.

## 1. Establish the real state before writing anything

Do not summarise from memory of the conversation. Measure:

- `git -C <repo> log --oneline -1` and `git status --short` for every repo touched.
- `gh pr list --state open` and `gh issue list --state open` — anything left hanging.
- **Verify merges by content, not by PR status**: `git grep -c "<symbol>" main -- <path>`.
  A squash merge rewrites hashes, and a stacked PR can show MERGED while its
  work never reached `main`.
- Kill background processes started during the session (servers, watchers) and
  confirm the ports are free.

## 2. Update the two memory layers

**L1 — the project's `CLAUDE.md`** (hot context, loaded every session).
Only facts that change how the next session acts: current versions, open
issue numbers, decisions taken, traps discovered. Correct anything the
session proved wrong — a stale line here misleads every future session.
Keep it dense; this file is read in full every time.

**L2 — auto-memory** at the path given in the system prompt (`memory/`):
- Update the existing file when one covers the topic; never create a duplicate.
- New `feedback` entries only for rules that will apply again, with the **why**
  and the concrete precedent that produced them.
- New `project` entries for ongoing work, with absolute dates.
- Add a one-line pointer to `MEMORY.md`. If that index approaches its size
  limit, compress by trimming hooks on **old** entries, never by cutting entries.
  A truncated hook ending in a preposition is worse than no hook — check for
  those after any bulk edit.

**Chronicles** (`memory/chronicles.md` in the project, if present): one entry
per non-trivial decision, format `YYYY-MM-DD: [decision] — [why exactly this]`.
Include what did **not** work — that is the part with future value.

## 3. Handoff draft

Write to `outputs/YYYY-MM-DD_<тема>.md` — **never** into `.claude/handoffs/`,
which the owner maintains by hand. Four sections, in this order:

1. **Что сделано** — with the numbers that were actually measured.
2. **Что НЕ сработало** — the most valuable section. False starts, reverted
   fixes, measurements that turned out to be wrong, and why.
3. **Следующий шаг** — exactly one, concrete enough to start on.
4. **Нюансы** — traps that will cost time if forgotten.

## 4. Next-session prompt

Write to `outputs/YYYY-MM-DD_next-session-prompt.md`. It is pasted into a
fresh session, so it must stand alone: state on entry, the open items with the
cost of getting each wrong, candidate first steps, and the rules this session
learned the hard way. Keep it scannable — a table beats prose for open items.

## 5. Report back, briefly

In the chat: what was updated, where the artefacts are, and **what remains
unfinished** stated plainly. If a PR still needs the owner's hand to merge,
give the exact command. Do not pad the summary with what went well.

## Boundaries

- Never write to `.claude/handoffs/` — draft to `outputs/`, the owner moves it.
- Never put the owner's real financial figures or personal data into a public
  repo, a PR description, a CHANGELOG or a commit message.
- Do not merge PRs; `--admin` is blocked for the assistant. Print the command.
- Do not invent progress to round out a section. An honest gap is the point.
