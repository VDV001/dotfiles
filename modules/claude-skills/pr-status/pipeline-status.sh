#!/usr/bin/env bash
# Живая лента этапов PR: «что, где, когда, что дальше» в одном комментарии.
# Формат по образцу «The life of a change» (Anthropic, 15.10.2026).
#
# ЭТАЛОН: dotfiles, modules/claude-skills/pr-status/. В репозиториях лежит копия
# в .github/scripts/: правка здесь, потом копия, иначе разойдутся.
#
# Вызов: pipeline-status.sh OWNER/REPO PR_NUMBER [EVENT]
#   DRY_RUN=1  печатает комментарий, ничего не пишет в PR.
# Нужны gh и jq (на раннерах GitHub есть). Токен: GH_TOKEN.
set -Eeuo pipefail

repo="${1:?OWNER/REPO}"; pr="${2:?PR}"; event="${3:-вручную}"
marker='<!-- pipeline-status -->'
case "$event" in
  pull_request*review_comment*) event="комментарий к строке${event#pull_request_review_comment}" ;;
  pull_request_review*) event="ревью${event#pull_request_review}" ;;
  pull_request*) event="PR обновлён${event#pull_request}" ;;
  workflow_run*) event="проверка${event#workflow_run}" ;;
esac

pr_json="$(gh api "repos/$repo/pulls/$pr")"
sha="$(jq -r .head.sha <<<"$pr_json")"
checks="$(gh api "repos/$repo/commits/$sha/check-runs?per_page=100" --paginate --jq '.check_runs[]' | jq -s '[.[] | select(.name != "pipeline-status")]')"

# Аннотации нужны двум вещам: ревью без секрета пишет notice, а упавший из-за
# биллинга запуск пишет «payments have failed». Без них оба выглядят иначе, чем есть.
notes='[]'
for id in $(jq -r '.[] | select(.name == "review" or .conclusion == "failure") | .id' <<<"$checks" | head -20); do
  a="$(gh api "repos/$repo/check-runs/$id/annotations" --jq "[.[] | {id: $id, msg: .message}]" 2>/dev/null || echo '[]')"
  notes="$(jq -s 'add' <<<"$notes $a")"
done

# Запуски, не стартовавшие из-за лимита Actions (бесплатный план), это не
# провал и не проверка: убираем их и считаем отдельно. Статус этапа тогда
# дают статусы коммита local/* с машины владельца (pr-status).
billing_ids="$(jq -c '[.[] | select(.msg | test("payments have failed|spending limit")) | .id] | unique' <<<"$notes")"
billed="$(jq 'length' <<<"$billing_ids")"
checks="$(jq --argjson b "$billing_ids" '[.[] | select(.id as $i | $b | index($i) | not)]' <<<"$checks")"
statuses="$(gh api "repos/$repo/commits/$sha/status" --jq '[.statuses[] | {context, state, description, updated_at}]')"

bot_comments="$(gh api "repos/$repo/pulls/$pr/comments?per_page=100" --paginate --jq '.[] | select(.user.type == "Bot" and (.user.login | test("claude"; "i"))) | .id' | wc -l | tr -d ' ')"

body="$(jq --arg event "$event" --argjson checks "$checks" --argjson notes "$notes" \
  --arg bot "$bot_comments" --arg marker "$marker" \
  --argjson statuses "$statuses" --arg billed "$billed" -r -f "$(dirname "$0")/pipeline-status.jq" <<<"$pr_json")"


if [ "${DRY_RUN:-}" = 1 ]; then printf '%s\n' "$body"; exit 0; fi

existing="$(gh api "repos/$repo/issues/$pr/comments?per_page=100" --paginate --jq ".[] | select(.body | startswith(\"$marker\")) | .id" | head -1)"
if [ -n "$existing" ]; then
  gh api -X PATCH "repos/$repo/issues/comments/$existing" -f body="$body" >/dev/null
else
  gh api -X POST "repos/$repo/issues/$pr/comments" -f body="$body" >/dev/null
fi
echo "✓ лента обновлена: $repo#$pr ($event)"
