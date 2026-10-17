#!/usr/bin/env bash
# Защита публичного репозитория от утечки секретов (17.10.2026).
#
#   check-secrets.sh staged          перед коммитом: индекс
#   check-secrets.sh range A..B      перед push: каждый уходящий коммит
#
# Две проверки:
#   1. gitleaks с .gitleaks.toml (правила по умолчанию).
#   2. Любой файл secrets/*.yaml обязан быть зашифрован sops: есть блок
#      `sops:` и каждое значение до него в виде ENC[...]. Открытое значение
#      рядом с ключом gitleaks может и не узнать, а этот файл и есть секреты.
#
# Нет gitleaks — отказ, а не пропуск: молчащий сторож хуже отсутствующего.
set -Eeuo pipefail
root="$(git rev-parse --show-toplevel)"
cd "$root"

gl="$(command -v gitleaks || true)"
[ -n "$gl" ] || [ ! -x "$HOME/go/bin/gitleaks" ] || gl="$HOME/go/bin/gitleaks"
[ -n "$gl" ] || { echo "✘ gitleaks не найден: проверка секретов невозможна, операция остановлена" >&2; exit 1; }

# Открытые значения в файле sops: строки «ключ: значение» до блока sops без ENC[.
plain_in() { awk '/^sops:/{exit} /:[[:space:]]*[^[:space:]]/ && !/ENC\[/ && !/^[A-Za-z0-9_-]+:[[:space:]]*$/' | wc -l | tr -d ' '; }

check_sops() { # ref (":" для индекса); имена файлов со stdin, по одному в строке
  local ref="$1" bad=0 f n
  while IFS= read -r f; do
    case "$f" in secrets/*.yaml|secrets/*.yml) ;; *) continue ;; esac
    git cat-file -e "$ref$f" 2>/dev/null || continue   # файл удалён
    if ! git show "$ref$f" | grep -q '^sops:'; then
      echo "✘ $f: нет блока sops, файл не зашифрован" >&2; bad=1; continue
    fi
    n="$(git show "$ref$f" | plain_in)"
    [ "$n" = 0 ] || { echo "✘ $f: открытых значений $n (нужно sops -e)" >&2; bad=1; }
  done
  return $bad
}

case "${1:-}" in
  staged)
    "$gl" git --pre-commit --staged --redact --no-banner -c .gitleaks.toml >/dev/null 2>&1 \
      || { "$gl" git --pre-commit --staged --redact --no-banner -c .gitleaks.toml 2>&1 | grep -vE '^\s*$' | tail -20 >&2; echo "✘ в индексе похоже на секрет, коммит остановлен" >&2; exit 1; }
    git diff --cached --name-only --diff-filter=AM | check_sops ":" || exit 1
    ;;
  range)
    r="${2:?A..B}"
    "$gl" git --log-opts="$r" --redact --no-banner -c .gitleaks.toml >/dev/null 2>&1 \
      || { "$gl" git --log-opts="$r" --redact --no-banner -c .gitleaks.toml 2>&1 | grep -vE '^\s*$' | tail -20 >&2; echo "✘ в уходящих коммитах похоже на секрет, push остановлен" >&2; exit 1; }
    for c in $(git rev-list $r); do   # $r без кавычек: «sha --not --remotes» это три аргумента
      git show --name-only --format= --diff-filter=AM "$c" | check_sops "$c:" || { echo "  (коммит ${c:0:8})" >&2; exit 1; }
    done
    ;;
  *) echo "использование: check-secrets.sh staged | range A..B" >&2; exit 2 ;;
esac
echo "✓ секретов не найдено"
