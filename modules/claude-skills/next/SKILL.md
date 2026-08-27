---
name: next
description: Propose what to do next as an interactive choice instead of making the owner type it out. Use when the owner says "что дальше", "предложи", "/next", "что делаем", "предложи интерактивно", or otherwise asks the assistant to drive the agenda. Also use after finishing a chunk of work when the next step is not already decided.
---

# What next — propose, do not ask to be told

The owner is tired of typing out the agenda. Your job is to **measure the current
state, then offer concrete choices** — not to ask an open question.

## Hard rule

End this skill with **one `AskUserQuestion` call**, `multiSelect: true`.
Never end it with a plain-text question like "что делать дальше?" — that is the
exact thing this skill exists to remove.

## Step 1 — Measure before proposing (do not skip)

Never build options from memory. Memory reflects what was true when written.
Run the cheap checks that fit the current context, in parallel where possible:

```bash
# незакрытая работа в репозиториях, которых касались в этой сессии
gh pr list --state open --limit 10 2>/dev/null
gh issue list --state open --limit 10 2>/dev/null
git status --short 2>/dev/null

# рабочее место — каждая строка самодостаточна: cwd между вызовами не переживает
# смену каталога, а валидатору нужны ДВА аргумента (карта и корень), иначе он
# падает с IsADirectoryError либо молча проверяет пустоту
cd ~/claude-cowork && python3 docs/architecture-map/validate.py docs/architecture-map/map.json . 2>&1 | tail -3
cd ~/claude-cowork && python3 _tools/skill_guard.py --watch 2>&1 | tail -2
cd ~/claude-cowork && kbengine fin sync --from finances/Учёт_финансов.xlsx \
  --ledger finances/transactions.jsonl --dry-run 2>&1 | tail -1
```

Read `memory/active-pipeline.md` when the question is "what are we working on".
Prefer a measurement over a recollection every time.

## Step 2 — Split by who can act

Two piles, and they are not equal:

- **Yours.** Anything you can finish without the owner: code, checks, pages,
  memory, cleanup you already have permission for.
- **His.** Anything requiring a human: sending a message, a phone call, a
  decision only he owns, `darwin-rebuild switch`, merging his own PR.

**Offer mainly from your pile.** Listing his pile as "options" turns the tool
into a nagging list. Mention those items in one closing sentence instead — and
only the ones that are actually blocking or time-bound.

## Step 3 — Write options that carry their own cost

Each option needs: what happens, and **what it costs to skip it**. A deadline, a
number, a risk. Options without a cost make every choice look equal, and then the
owner has to think — which is the work you were supposed to do for him.

Good: "Сторож на расписание — без него гейт работает только когда я его руками
зову, то есть опять правило без исполнителя."

Bad: "Заняться автоматизацией."

Rules for the option set:
- **2–4 options.** More than four is a list, not a choice.
- **Concrete and finishable**, not themes. "Дописать раздел X" beats "поработать
  над документом".
- **Name the deadline** when one exists (a return date, a booking cancellation
  window, a registration window).
- Include a **"ничего, отдыхаем"** option only when the work genuinely is at a
  clean stopping point. Offering it mid-task is noise.
- Never offer something already finished this session. Check before proposing.

## Step 4 — Destructive things are a separate question

Deleting files, force-pushing, sending anything outward — these never go in as a
plain option. Show exactly what would be affected first, then ask separately.
The owner's red line is explicit: no deleting without an explicit "удали это".

## Step 5 — After the answer

Do the chosen items. If several were chosen, do them in the order that unblocks
the most, and say which order you picked and why in one line.

If the owner picks nothing, or answers with something outside the list, drop the
proposals entirely and follow what he actually said — the list was a convenience,
not a contract.

## What this skill is not

It is not a status report. Do not dump everything measured in Step 1 — that
information exists to make the options right, not to be printed. Two or three
lines of state, then the question.
