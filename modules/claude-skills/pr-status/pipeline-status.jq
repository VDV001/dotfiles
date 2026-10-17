def msk: if . == null then "" else (sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601 + 10800 | strftime("%d.%m %H:%M")) end;
def section($h): (.body // "") as $b
  | ($b | split("\n")) as $l
  | ([$l | to_entries[] | select(.value | test("^##\\s*" + $h; "i")) | .key] | first) as $i
  | if $i == null then "" else
      ($l[($i+1):] | until(length == 0 or (.[0] | test("^##")); .[1:]) as $rest
      | $l[($i+1):(($l | length) - ($rest | length))] | join("\n")
      | gsub("<!--[\\s\\S]*?-->"; "") | gsub("^\\s+|\\s+$"; "")) end;
def bad: .conclusion as $c | ["failure","timed_out","cancelled","action_required","startup_failure"] | index($c) != null;
def group: if length == 0 then "none"
  elif any(.[]; bad) then "fail"
  elif any(.[]; .status != "completed") then "run" else "ok" end;
def when: [.[] | (.completed_at // .started_at)] | map(select(. != null)) | max | msk;
def billing: [$notes[] | select(.msg | test("payments have failed|spending limit"))] | length > 0;
def row($icon; $stage; $what; $when): "| \($icon) | **\($stage)** | \($what) | \($when) |";

. as $pr
| ($checks | map(select(.name == "review"))) as $rev
| ($checks | map(select(.name | test("secur|codeql|gitleaks|redteam|analyze"; "i")))) as $sec
| ($checks | map(select(.name != "review" and (.name | test("secur|codeql|gitleaks|redteam|analyze"; "i") | not)))) as $ci
| ($ci | group) as $cis | ($sec | group) as $secs | ($rev | group) as $revs
| ([$notes[] | select(.msg | test("Добавьте секрет"))] | length > 0) as $nokey
| ($pr | section("(Testing|Проверка)")) as $testing
| ($pr | section("(Risk|Риск)")) as $risk
| (if ($risk | test("[Вв]ысок")) then "high" elif ($risk | test("[Сс]редн")) then "mid"
   elif ($risk | test("[Нн]изк")) then "low" else "none" end) as $tier
| ($pr | section("(How to revert|Откат)") | split("\n")[0] // "") as $revert
| ($pr.merged_at != null) as $merged
| ($pr.user.login) as $author

| [ row(if $testing != "" then "✓" else "✗" end; "Проверено автором";
        if $testing != "" then "секция Testing заполнена: что запускали и с каким итогом"
        else "секция Testing пустая: непонятно, чем проверено" end; $pr.created_at | msk),

    row(if $cis == "ok" then "✓" elif $cis == "run" then "⏳" elif $cis == "none" then "○" else "✗" end;
        "CI";
        if ($ci | billing) then "Actions не стартуют: биллинг аккаунта (payments have failed). Код не виноват"
        elif $cis == "ok" then "\($ci | length) проверок зелёные: \([$ci[].name] | join(", "))"
        elif $cis == "run" then "идут: \([$ci[] | select(.status != "completed") | .name] | join(", "))"
        elif $cis == "none" then "проверок на этом коммите нет"
        else "упали: \([$ci[] | select(bad) | .name] | join(", ")). Красное блокирует мерж" end;
        $ci | when),

    row(if $revs == "run" then "⏳" elif $revs == "fail" then "✗"
        elif $revs == "none" or $nokey then "○" elif ($bot | tonumber) > 0 then "◆" else "✓" end;
        "AI-ревью Claude";
        if $revs == "run" then "Claude читает дифф по правилам REVIEW.md"
        elif $revs == "fail" and ($rev | billing) then "не стартовало: биллинг Actions"
        elif $revs == "fail" then "ревьюер упал, смотри лог задачи review"
        elif $revs == "none" then "не запускалось на этом коммите"
        elif $nokey then "выключено: нет секрета CLAUDE_CODE_OAUTH_TOKEN"
        elif ($bot | tonumber) > 0 then "замечаний на строках: \($bot). Разобрать до мержа"
        else "замечаний нет" end;
        $rev | when),

    row(if $secs == "ok" then "✓" elif $secs == "run" then "⏳" elif $secs == "none" then "○" else "✗" end;
        "Security";
        if $secs == "none" then "отдельного прохода безопасности в этом репо нет"
        elif $secs == "ok" then "чисто: \([$sec[].name] | join(", "))"
        elif $secs == "run" then "идёт: \([$sec[] | select(.status != "completed") | .name] | join(", "))"
        else "есть находки: \([$sec[] | select(bad) | .name] | join(", ")). Блокирует мерж" end;
        $sec | when),

    row(if $merged then "✓" elif $tier == "none" then "✗" elif $tier == "low" then "✓" else "◆" end;
        "Решение по риску";
        if $tier == "none" then "уровень риска не указан в секции Risk"
        elif $tier == "low" then "низкий: хватает AI-ревью и зелёных проверок"
        elif $tier == "mid" then "средний: @\($author) читает дифф глазами"
        else "высокий: только человек, AI-апрув не заменяет" end; ""),

    "| | **МЕРЖ** | | |",
    row(if $merged then "✓" elif $pr.state == "closed" then "✗" elif $pr.draft then "○"
        elif ($cis == "ok" or $cis == "none") and $secs != "fail" and $revs != "fail" and ($bot | tonumber) == 0 and $tier != "none" then "◆"
        else "○" end;
        "Мерж в \($pr.base.ref)";
        if $merged then "влит"
        elif $pr.state == "closed" then "PR закрыт без мержа"
        elif $pr.draft then "черновик"
        elif ($cis == "ok" or $cis == "none") and $secs != "fail" and $revs != "fail" and ($bot | tonumber) == 0 and $tier != "none"
          then "можно мержить: блокеров нет" else "ждёт: сначала закрыть строки выше с ✗, ⏳ и ◆" end;
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
