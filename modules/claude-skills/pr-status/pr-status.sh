#!/usr/bin/env bash
# pr-status: лента этапов PR в терминале и в самом PR.
#
#   pr-status              открытые PR текущего репозитория (мои)
#   pr-status 912          один PR текущего репозитория
#   pr-status all          все открытые PR по проектам из ~/.config/pr-status/repos
#   pr-status --no-post …  только показать, комментарий в PR не трогать
#   pr-status --hook       режим хука: читает JSON PostToolUse со stdin
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
    pr="$(gh pr view --json number --jq .number 2>/dev/null)" || exit 0
    out="$(EVENT="хук: ${cmd%% *} ${cmd#* }" one "$repo" "$pr" 2>/dev/null)" || exit 0
    jq -n --arg o "$out" '{hookSpecificOutput: {hookEventName: "PostToolUse",
      additionalContext: ("Лента этапов PR обновлена (и в комментарии PR). Покажи её владельцу в блоке кода как есть:\n" + $o)}}'
    ;;
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
