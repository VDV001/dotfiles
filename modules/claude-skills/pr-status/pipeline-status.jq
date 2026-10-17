def msk: if . == null then "" else (sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601 + 10800 | strftime("%d.%m %H:%M")) end;
def section($h): (.body // "") as $b
  | ($b | split("\n")) as $l
  | ([$l | to_entries[] | select(.value | test("^##\\s*" + $h; "i")) | .key] | first) as $i
  | if $i == null then "" else
      ($l[($i+1):] | until(length == 0 or (.[0] | test("^##")); .[1:]) as $rest
      | $l[($i+1):(($l | length) - ($rest | length))] | join("\n")
      | gsub("<!--[\\s\\S]*?-->"; "")
      # Невыбранный чекбокс шаблона («- [ ] go test») это заготовка, а не ответ.
      | [split("\n")[] | select(test("^\\s*[-*] \\[ \\]") | not)] | join("\n")
      | gsub("^\\s+|\\s+$"; "")) end;
def bad: .conclusion as $c | ["failure","timed_out","cancelled","action_required","startup_failure"] | index($c) != null;
def group: if length == 0 then "none"
  elif any(.[]; bad) then "fail"
  elif any(.[]; .status != "completed") then "run" else "ok" end;
def when: [.[] | (.completed_at // .started_at)] | map(select(. != null)) | max | msk;
def row($icon; $stage; $what; $when): "| \($icon) | **\($stage)** | \($what) | \($when) |";
# Локальный результат: статус коммита local/* (ставит pr-status с машины владельца).
def lstat($ctx): [$statuses[] | select(.context == $ctx)] | first;
def lstate: if . == null then "none" elif .state == "success" then "ok"
  elif .state == "pending" then "run" else "fail" end;
# Итог этапа из запусков Actions ($g) и локального статуса ($l): красное
# побеждает, потом «идёт», потом зелёное. Запуски, не стартовавшие из-за
# биллинга, сюда не попадают вовсе: их убрал pipeline-status.sh.
def merge($g; $l): if $g == "fail" or $l == "fail" then "fail"
  elif $g == "run" or $l == "run" then "run"
  elif $g == "ok" or $l == "ok" then "ok" else "none" end;
def icon: if . == "ok" then "✓" elif . == "run" then "⏳" elif . == "fail" then "✗" else "○" end;
def lwhen: if . == null then "" else .updated_at | msk end;

. as $pr
| ($checks | map(select(.name == "review"))) as $rev
| ($checks | map(select(.name | test("secur|codeql|gitleaks|redteam|analyze"; "i")))) as $sec
# CI это только задачи GitHub Actions: чеки сторонних приложений (превью
# Vercel и т.п.) тестов не гоняют и зелёным CI не считаются.
| ($checks | map(select(.app.slug == "github-actions" and .name != "review" and (.name | test("secur|codeql|gitleaks|redteam|analyze"; "i") | not)))) as $ci
| lstat("local/ci") as $lci | lstat("local/review") as $lrev | lstat("local/security") as $lsec
| merge($ci | group; $lci | lstate) as $cis
| merge($sec | group; $lsec | lstate) as $secs
| (if $lrev != null then ($lrev | lstate) else ($rev | group) end) as $revs
| ([$notes[] | select(.msg | test("Добавьте секрет"))] | length > 0) as $nokey
| ($billed | tonumber) as $nb
| ($pr | section("(Testing|Проверка)")) as $testing
| ($pr | section("(Risk|Риск)")) as $risk
| (if ($risk | test("[Вв]ысок")) then "high" elif ($risk | test("[Сс]редн")) then "mid"
   elif ($risk | test("[Нн]изк")) then "low" else "none" end) as $tier
| ($pr | section("(How to revert|Откат)") | split("\n")[0] // "") as $revert
| ($pr.merged_at != null) as $merged
| ($pr.user.login) as $author
| (($cis == "ok" or ($cis == "none" and $nb == 0)) and $secs != "fail" and $secs != "run"
   and (($revs == "ok" and ($lrev != null or ($nokey | not))) or ($revs == "none" and $nb == 0 and $lrev == null and ($bot | tonumber) == 0))
   and $tier != "none") as $ready

| [ row(if $testing != "" then "✓" else "✗" end; "Проверено автором";
        if $testing != "" then "секция Testing заполнена: что запускали и с каким итогом"
        else "секция Testing пустая: непонятно, чем проверено" end; $pr.created_at | msk),

    row($cis | icon; "CI";
        if $cis == "fail" then
          ([$ci[] | select(bad) | .name] + (if ($lci | lstate) == "fail" then ["локально: " + $lci.description] else [] end)
           | "упало: " + join(", ") + ". Красное блокирует мерж")
        elif $cis == "run" then "идёт: " + ([$ci[] | select(.status != "completed") | .name] + (if ($lci | lstate) == "run" then ["локальные гейты"] else [] end) | join(", "))
        elif $cis == "ok" then
          ([(if $lci != null then "локально: " + $lci.description else empty end),
            (if ($ci | length) > 0 then "Actions: \([$ci[].name] | join(", "))" else empty end)]
           | join(" · ")) + (if $nb > 0 then " (Actions не стартовали: бесплатный лимит)" else "" end)
        elif $nb > 0 then "нет подтверждения: Actions не стартовали, локального прогона на этом коммите нет. Отметит git push с pre-push хуками"
        else "проверок на этом коммите нет" end;
        (if $lci != null then ($lci | lwhen) else ($ci | when) end)),

    row(if $lrev == null and $nokey then "○"
        elif $revs == "ok" and $lrev == null and ($bot | tonumber) > 0 then "◆"
        elif $revs == "fail" and $lrev != null then "◆" else ($revs | icon) end;
        "AI-ревью Claude";
        if $lrev != null then
          (if $revs == "ok" then "локально по REVIEW.md: " + $lrev.description
           elif $revs == "run" then "идёт локально: " + $lrev.description
           else "локально по REVIEW.md: " + $lrev.description + ". Разобрать до мержа" end)
        elif $revs == "run" then "Claude читает дифф по правилам REVIEW.md"
        elif $nokey then "в Actions выключено (нет секрета): /code-review по REVIEW.md, итог в pr-status review"
        elif $revs == "fail" then "ревьюер упал, смотри лог задачи review"
        elif $revs == "none" then "не запускалось на этом коммите: /code-review по REVIEW.md, итог в pr-status review"
        elif $nokey then "выключено: нет секрета CLAUDE_CODE_OAUTH_TOKEN"
        elif ($bot | tonumber) > 0 then "замечаний на строках: \($bot). Разобрать до мержа"
        else "замечаний нет" end;
        (if $lrev != null then ($lrev | lwhen) else ($rev | when) end)),

    row(if $secs == "fail" and ($lsec | lstate) == "fail" then "◆" else ($secs | icon) end; "Security";
        if $secs == "none" then "не запускалось: /security-review, итог в pr-status review --security"
        elif $secs == "ok" then "чисто: " + ([(if $lsec != null then "локально: " + $lsec.description else empty end), ($sec[] | .name)] | join(", "))
        elif $secs == "run" then "идёт: " + ([$sec[] | select(.status != "completed") | .name] + (if ($lsec | lstate) == "run" then ["локально"] else [] end) | join(", "))
        else "есть находки: " + ([$sec[] | select(bad) | .name] + (if ($lsec | lstate) == "fail" then [$lsec.description] else [] end) | join(", ")) + ". Блокирует мерж" end;
        (if $lsec != null then ($lsec | lwhen) else ($sec | when) end)),

    row(if $merged then "✓" elif $tier == "none" then "✗" elif $tier == "low" then "✓" else "◆" end;
        "Решение по риску";
        if $tier == "none" then "уровень риска не указан в секции Risk"
        elif $tier == "low" then "низкий: хватает AI-ревью и зелёных проверок"
        elif $tier == "mid" then "средний: @\($author) читает дифф глазами"
        else "высокий: только человек, AI-апрув не заменяет" end; ""),

    "| | **МЕРЖ** | | |",
    row(if $merged then "✓" elif $pr.state == "closed" then "✗" elif $pr.draft then "○" elif $ready then "◆" else "○" end;
        "Мерж в \($pr.base.ref)";
        if $merged then "влит"
        elif $pr.state == "closed" then "PR закрыт без мержа"
        elif $pr.draft then "черновик"
        elif $ready then "можно мержить: блокеров нет" else "ждёт: сначала закрыть строки выше с ✗, ⏳ и ◆" end;
        $pr.merged_at | msk),

    "| | **ПОСЛЕ МЕРЖА** | | |",
    row(if $merged then "⏳" else "○" end; "Релиз и прод";
        if $merged then "проверить прод после деплоя" else "после мержа" end; ""),
    row("↻"; "Откат"; if $revert != "" then $revert else "секция How to revert пустая" end; "")
  ] as $rows

| ([ $rows[] | select(test("^\\| (✗|⏳|◆) ")) ] | first // "") as $next
| $marker + "\n### Жизнь изменения\n"
  + "_Обновлено \(now | todate | msk) МСК · событие: \($event) · коммит `\($pr.head.sha[0:7])`_\n\n"
  + "| | Этап | Что происходит | Когда |\n|---|---|---|---|\n"
  + "| | **ДО PR** | | |\n" + $rows[0] + "\n"
  + "| | **НА PR** | | |\n" + ($rows[1:] | join("\n")) + "\n\n"
  + (if $next != "" then "**Дальше:** " + ($next | split(" | ")[1:3] | join(": ") | gsub("\\*\\*"; "")) + "\n\n" else "**Дальше:** всё зелёное\n\n" end)
  + "✓ автоматически · ◆ решает человек · ⏳ идёт · ○ впереди или выключено · ✗ блокирует · ↻ восстановление"
