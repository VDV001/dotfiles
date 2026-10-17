#!/usr/bin/env bash
# pr-status: лента этапов PR в терминале и в самом PR.
#
#   pr-status              открытые PR текущего репозитория (мои)
#   pr-status 912          один PR текущего репозитория
#   pr-status all          все открытые PR по проектам из ~/.config/pr-status/repos
#   pr-status --no-post …  только показать, комментарий в PR не трогать
#   pr-status --hook       режим хука: читает JSON PostToolUse со stdin
#   pr-status ci-passed    отметить коммит: pre-push хуки прошли (local/ci)
#   pr-status review ok|issues "итог" [--security] [--body-file f.md]
#                          записать итог локального ревью (local/review или
#                          local/security) и полный текст комментарием в PR
#
# Actions на бесплатном плане не стартуют, поэтому этапы CI, ревью и
# security подтверждаются статусами коммита local/* (API статусов бесплатен).
#
# Сам расчёт этапов: pipeline-status.sh/.jq рядом (тот же код лежит в
# .github/scripts/ репозиториев и гоняется там из Actions).
# ponytail: копии в репозиториях правятся отдельно; эталон здесь. Если
# начнут расходиться, сверять `diff` и тащить отсюда.
set -Eeuo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repos_file="${PR_STATUS_REPOS:-$HOME/.config/pr-status/repos}"
post=1

render() { # markdown ленты → колонки для терминала (python: awk считает байты, кириллица ломает ширину)
  python3 -c '
import sys
for line in sys.stdin.read().splitlines():
    if line.startswith("_Обновлено"): print("  " + line.strip("_"))
    elif line.startswith("| | **"): print("  " + line.split(" | ")[1].strip("*"))
    elif line.startswith("| ") and not line.startswith("| |") and not line.startswith("|---"):
        f = [x.strip() for x in line.strip("|").split(" | ")]
        if len(f) < 4 or f[1] == "Этап": continue
        icon, stage, what, when = f[0], f[1].strip("*"), f[2], f[3].rstrip("|").strip()
        print(f"    {icon} {stage:<20} {what}" + (f"  · {when}" if when else ""))
    elif line.startswith("**Дальше"): print("  → " + line.replace("**", ""))
'
}

one() { # repo pr
  local repo="$1" pr="$2" md title
  md="$(DRY_RUN=1 bash "$here/pipeline-status.sh" "$repo" "$pr" "${EVENT:-вручную}")"
  title="$(gh pr view "$pr" -R "$repo" --json title --jq .title)"
  printf '\n%s #%s  %s\n' "$repo" "$pr" "$title"
  render <<<"$md"
  if [ "$post" = 1 ]; then bash "$here/pipeline-status.sh" "$repo" "$pr" "${EVENT:-вручную}" >/dev/null; fi
}

waiting() { # одна строка на PR с ◆: что ждёт человека
  local repo="$1" pr="$2"
  DRY_RUN=1 bash "$here/pipeline-status.sh" "$repo" "$pr" x \
    | awk -F' \\| ' -v r="$repo#$pr" '/^\| ◆ /{ s=$2; gsub(/\*/, "", s); print "  ◆ " r "  " s ": " $3 }'
}

current_repo() { gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null; }
my_prs() { gh pr list -R "$1" --author @me --state open --json number --jq '.[].number'; }

set_status() { # repo sha context state description
  gh api -X POST "repos/$1/statuses/$2" -f context="$3" -f state="$4" -f description="${5:0:140}" >/dev/null
}

# pre-push есть? Тогда успешный push означает, что гейты прошли.
has_pre_push() {
  local hp; hp="$(git config core.hooksPath || true)"
  [ -n "$hp" ] && [ -x "$(git rev-parse --show-toplevel)/$hp/pre-push" ] && return 0
  [ -x "$(git rev-parse --git-common-dir)/hooks/pre-push" ]
}

# ci-passed: только если HEAD реально уехал (совпал с @{push}) и в репо есть
# pre-push. ponytail: обход --no-verify отсюда не виден; хук отсекает его по
# тексту команды, ручной вызов доверяет вызвавшему.
ci_passed() {
  local repo sha
  repo="$(current_repo)" || return 1
  has_pre_push || { echo "○ в репо нет pre-push: отмечать нечего"; return 0; }
  sha="$(git rev-parse HEAD)"
  [ "$sha" = "$(git rev-parse '@{push}' 2>/dev/null)" ] || { echo "○ HEAD ещё не запушен"; return 0; }
  set_status "$repo" "$sha" local/ci success "pre-push хуки прошли на машине владельца"
  echo "✓ local/ci: $repo@${sha:0:7}"
}

record_review() { # ok|issues summary [--security] [--body-file f]
  local verdict="${1:?ok|issues}" summary="${2:?итог}" ctx=local/review marker='<!-- local-review -->' file="" repo pr sha
  shift 2
  while [ $# -gt 0 ]; do case "$1" in
    --security) ctx=local/security; marker='<!-- local-security -->' ;;
    --body-file) file="$2"; shift ;;
  esac; shift; done
  repo="$(current_repo)"; pr="$(gh pr view --json number --jq .number)"
  sha="$(gh pr view --json headRefOid --jq .headRefOid)"
  [ "$sha" = "$(git rev-parse HEAD)" ] || { echo "✘ локальный HEAD не совпадает с головой PR: ревью не того коммита" >&2; return 2; }
  set_status "$repo" "$sha" "$ctx" "$([ "$verdict" = ok ] && echo success || echo failure)" "$summary"
  if [ -n "$file" ]; then
    local body existing; body="$marker"$'\n'"$(cat "$file")"
    existing="$(gh api "repos/$repo/issues/$pr/comments?per_page=100" --paginate --jq ".[] | select(.body | startswith(\"$marker\")) | .id" | head -1)"
    if [ -n "$existing" ]; then gh api -X PATCH "repos/$repo/issues/comments/$existing" -f body="$body" >/dev/null
    else gh api -X POST "repos/$repo/issues/$pr/comments" -f body="$body" >/dev/null; fi
  fi
  echo "✓ $ctx: $repo#$pr ${sha:0:7} $verdict"
  EVENT="$ctx" one "$repo" "$pr"
}

args=()
for a in "$@"; do case "$a" in --no-post) post=0 ;; *) args+=("$a") ;; esac; done
set -- "${args[@]+"${args[@]}"}"

case "${1:-}" in
  --hook)
    # Хук PostToolUse: после gh pr create / git push / gh pr merge обновляет
    # ленту PR текущей ветки и отдаёт её ассистенту, чтобы тот показал её
    # владельцу. Любая ошибка молча выходит: хук не должен ломать работу.
    input="$(cat)"
    cmd="$(jq -r '.tool_input.command // ""' <<<"$input" 2>/dev/null || true)"
    grep -qE '(^|[;&| ])(gh pr (create|merge|ready)|git push)( |$)' <<<"$cmd" || exit 0
    cwd="$(jq -r '.cwd // ""' <<<"$input")"; [ -d "$cwd" ] && cd "$cwd"
    repo="$(current_repo)" || exit 0; [ -n "$repo" ] || exit 0
    if grep -q 'git push' <<<"$cmd" && ! grep -q -- '--no-verify' <<<"$cmd"; then ci_passed >/dev/null 2>&1 || true; fi
    pr="$(gh pr view --json number --jq .number 2>/dev/null)" || exit 0
    out="$(EVENT="хук: ${cmd%% *} ${cmd#* }" one "$repo" "$pr" 2>/dev/null)" || exit 0
    hint=""
    grep -q 'gh pr create' <<<"$cmd" && hint=$'\n\nPR только что открыт: проведи /code-review по REVIEW.md репозитория (и /security-review для высокого риска), затем запиши итог: ~/.claude/pr-status/pr-status.sh review ok|issues "итог" --body-file <файл с находками>.'
    jq -n --arg o "$out" --arg h "$hint" '{hookSpecificOutput: {hookEventName: "PostToolUse",
      additionalContext: ("Лента этапов PR обновлена (и в комментарии PR). Покажи её владельцу в блоке кода как есть:\n" + $o + $h)}}'
    ;;
  ci-passed) ci_passed ;;
  review) shift; record_review "$@" ;;
  all)
    [ -f "$repos_file" ] || { echo "✘ нет $repos_file (по репозиторию OWNER/REPO на строку)" >&2; exit 2; }
    pending=""
    while IFS= read -r repo; do
      case "$repo" in ''|\#*) continue ;; esac
      for pr in $(my_prs "$repo"); do one "$repo" "$pr"; pending+="$(waiting "$repo" "$pr")"$'\n'; done
    done < "$repos_file"
    printf '\nЖДЁТ ТЕБЯ\n%s' "${pending:-  ничего}"
    ;;
  '')
    repo="$(current_repo)" || { echo "✘ не в репозитории GitHub" >&2; exit 2; }
    prs="$(my_prs "$repo")"; [ -n "$prs" ] || { echo "открытых PR нет: $repo"; exit 0; }
    for pr in $prs; do one "$repo" "$pr"; done
    ;;
  *)
    repo="$(current_repo)" || { echo "✘ не в репозитории GitHub" >&2; exit 2; }
    one "$repo" "$1"
    ;;
esac
