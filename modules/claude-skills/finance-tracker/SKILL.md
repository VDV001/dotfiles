---
name: finance-tracker
description: "Разбор ФОТО чеков и скриншотов банковских уведомлений в финансовую запись. Use this skill ONLY when the user sends an image: a photo of a receipt, a screenshot of a bank notification, or a photographed statement. Триггеры: приложенное изображение + 'чек', 'скрин из банка', 'вот чек', 'распознай', receipt photo, bank notification screenshot. НЕ использовать для текстовых записей ('потратил 300 на такси', 'добавь расход', 'запиши трату', 'зарплата 90000', 'обнови баланс') — для них есть finance-log. НЕ использовать для вопросов о балансе, сводке и бюджете — там тоже finance-log. Записывает распознанное ТОЛЬКО через kbengine fin add, прямая запись в xlsx запрещена."
---

# Finance Tracker

Разбор изображений в финансовую запись: фото чека, скриншот банковского
уведомления, снимок выписки. Claude распознаёт данные и отдаёт их движку.

Текстовые записи («потратил 300 на такси») этот скилл не обслуживает — их
ведёт `finance-log`. Разделение по способности, а не по теме: перекрывающиеся
триггеры уже однажды привели к тому, что одна трата записалась дважды.

## Dependencies

**Записывает движок `kbengine`.** Скилл `xlsx` здесь не нужен и не используется:
он пишет в книгу напрямую, а прямая запись создаёт строку без `id` — вторую
копию покупки, которую потом никто не может развести.

## File Location

The spreadsheet lives at:
```
~/claude-cowork/finances/Учёт_финансов.xlsx
```

**Before any operation:**
1. Request access to `~/claude-cowork` using the `request_cowork_directory` tool (path: `~/claude-cowork`)
2. The tool will return the actual VM mount path (e.g., `/sessions/<session-id>/mnt/claude-cowork`)
3. Use that returned path for all file operations — never hardcode VM paths, as they change every session

## Language and Currency

All interface text, categories, and descriptions are in **Russian**. Currency is **Russian Rubles (₽)**. Amounts are always stored as numbers without currency symbols.

---

## Spreadsheet Structure

The workbook has four sheets: **Расходы**, **Доходы**, **Сводка**, **Справочник**.

### Sheet "Расходы" (Expenses) — 7 columns

| Column | Name         | Format / Values                                      |
|--------|-------------|------------------------------------------------------|
| A      | Дата         | DD.MM.YYYY (text or date formatted as DD.MM.YYYY)    |
| B      | Категория    | One of the 8 categories below                        |
| C      | Подкатегория | One of the subcategories mapped to the category      |
| D      | Место        | Specific venue / store name                          |
| E      | Описание     | Free-text description of the purchase                |
| F      | Сумма        | Numeric amount in rubles                             |
| G      | Источник     | `чек` / `вручную` / `почта`                          |

### Expense Categories and Subcategories

```
Еда            → рестораны/кафе, продукты, доставка еды, фастфуд
Транспорт      → такси, общественный, бензин, парковка
Жильё          → аренда, коммуналка, ремонт
Подписки       → сервисы, приложения
Развлечения    → кино, игры, хобби
Здоровье       → аптека, врачи, спорт
Одежда         → одежда, обувь
Прочее         → (no fixed subcategories — use a descriptive one)
```

When the category is "Прочее", invent a reasonable subcategory that describes the purchase (e.g., "канцелярия", "подарки", "электроника").

### Sheet "Доходы" (Income) — 4 columns

| Column | Name       | Format / Values                                               |
|--------|-----------|---------------------------------------------------------------|
| A      | Дата       | DD.MM.YYYY                                                    |
| B      | Источник   | зарплата / фриланс / подработка / инвестиции / подарок / прочее |
| C      | Описание   | Free-text description                                         |
| D      | Сумма      | Numeric amount in rubles                                      |

### Sheet "Сводка" (Summary) — 7 analytical sections

This sheet contains formulas that aggregate data from the other sheets. It has these sections:

1. **Общие итоги** — Total income, total expenses, balance (income − expenses)
2. **Расходы по категориям** — Sum per category (8 rows)
3. **Расходы по подкатегориям** — Sum per subcategory (all 22 subcategories)
4. **Помесячная сводка 2026** — Monthly totals for Jan–Dec 2026
5. **Расходы по дням** — Daily totals for the last 31 days
6. **Топ-20 мест** — Top 20 venues by total spending
7. **Доходы по источникам** — Income totals per source type

After adding rows to Расходы or Доходы, always recalculate this sheet (see Recalculation below).

### Sheet "Справочник" (Reference) — Category ↔ Subcategory mapping

A lookup table used for validation. Two columns: Категория, Подкатегория. One row per subcategory.

---

## Receipt Parsing Process

When the user sends one or more photos:

1. **Read the image(s)** carefully. Extract:
   - Date of the transaction
   - Venue / store name (as printed on the receipt)
   - Total amount (look for "ИТОГО", "ИТОГ", "Всего", "Total", or the final bold number)
   - Individual line items if clearly visible (for the description field)
   - Payment method if shown (card ending, cash)

2. **Determine category and subcategory** based on the venue type:
   - Grocery stores (Пятёрочка, Магнит, Перекрёсток, ВкусВилл, Лента, Ашан) → Еда / продукты
   - Restaurants, cafes, coffee shops → Еда / рестораны/кафе
   - Fast food (McDonald's, KFC, Burger King) → Еда / фастфуд
   - Delivery services (Яндекс Еда, Delivery Club, СберМаркет) → Еда / доставка еды
   - Pharmacies (Аптека, Столичка, Горздрав) → Здоровье / аптека
   - Gas stations → Транспорт / бензин
   - Clothing stores → Одежда / одежда or обувь
   - If unsure, ask the user

3. **Normalize the venue name.** Check existing entries in the spreadsheet. If a venue appeared before under a specific name, reuse that exact name. Do not mix transliterations (e.g., don't write "Paul Bakery" if the spreadsheet already has "Поль Бейкери"). When in doubt, use the name as printed on the receipt.

4. **Detect duplicate receipts.** If the user sends two photos of the same transaction (e.g., a cash register receipt AND a bank terminal slip), record it as ONE entry, not two. Compare amounts and timestamps to detect this.

5. **If something is unreadable**, ask the user instead of guessing. Say what you could read and ask them to fill in the gaps.

6. **Confirm with the user** before writing. Show them a summary:
   ```
   📝 Распознано:
   • Дата: 29.03.2026
   • Место: Перекрёсток
   • Категория: Еда → продукты
   • Сумма: 1 847 ₽
   • Описание: молоко, хлеб, курица, овощи
   • Источник: чек

   Записать?
   ```
   Wait for confirmation before modifying the spreadsheet.

---

## Adding an Entry (Technical Process)

**Записывать ТОЛЬКО через движок. В xlsx напрямую не писать — никогда.**

Этот скилл читает чеки и скриншоты; записывает их движок `kbengine`. Так было
не всегда, и цена известна: прямая запись openpyxl создаёт строку без `id`,
движок не может сопоставить её со своей записью, и одна покупка превращается в
две. Ровно так 2 августа в книге появились две строки по 140 ₽.

```bash
LEDGER=~/claude-cowork/finances/transactions.jsonl
BOOK=~/claude-cowork/finances/Учёт_финансов.xlsx

kbengine fin add --ledger "$LEDGER" \
  --kind expense --date 2026-08-02 \
  --cat 'Еда' --sub 'Продукты' --place 'Магнит' \
  --amount '129,98' --source 'Чек' --account 'Сбербанк'

kbengine fin sync --from "$BOOK" --ledger "$LEDGER"
```

`--date` по умолчанию сегодня, `--amount` понимает `129,98`, `1 500` и `418р`.
`id` движок генерирует сам. Категорию сверять со словарём
`~/claude-cowork/finances/finance-aliases.json` — тем же, что читает терминал.

### Если движок отказал

- **«такая запись уже есть»** — это защита от повтора, а не ошибка. Показать
  владельцу, что именно уже записано, и спросить. Повторять с `--force` только
  по его прямому слову.
- **«в книге повторов уже записанного»** на синке — в книгу попала строка мимо
  движка. Назвать её владельцу; убирать самому не надо.

Обходить отказ прямой записью в xlsx запрещено. Отказ — это работающая
защита, а не препятствие.

### Date handling

Дату отдавать движку как `YYYY-MM-DD`. Если на чеке другой формат — перевести;
если года нет — текущий.

### Amount handling

- Убрать символы валюты и разделители тысяч
- Запятую в дробной части движок принимает сам, переводить в точку не нужно

---

## Текст без картинки — не сюда

Фразы вроде «потратил 300 на такси», «зарплата 150000», «обнови баланс»
обслуживает `finance-log`. Здесь они не обрабатываются, даже если выглядят
знакомо.

Это не формальность: раньше оба скилла отзывались на одни и те же слова, и
какой сработает — решал случай. Один из них писал в книгу мимо движка, и так
одна трата 140 ₽ оказалась записанной дважды. Разделение по способности —
картинка против текста — единственное, что не зависит от везения.

---

## Additional Data Sources

### Gmail
If the user asks to scan email for transactions, search Gmail for bank notification patterns:
- From: notifications from Сбербанк, Тинькофф, Альфа-Банк, ВТБ, etc.
- Subject patterns: "Списание", "Покупка", "Перевод", "Зачисление"
- Extract amount, merchant, date from the email body
- Set Источник to `почта`

### Stripe
If the user has business income tracked in Stripe, pull recent transactions and add to Доходы with Источник = `фриланс` or appropriate type.

### Manual batch input
The user might paste a list of transactions. Parse each line separately and add them all.

---

## Отчёты — не сюда

«Сколько потратил», «покажи сводку», «баланс» считает движок, и считает один
раз на все поверхности:

```bash
kbengine fin report --ledger ~/claude-cowork/finances/transactions.jsonl
```

Читать лист «Сводка» и пересказывать его — это второй счёт тех же денег.
Он однажды разойдётся с первым, и понять, какой из двух прав, будет нельзя.

---

## Important Rules

- **Никогда не писать в xlsx напрямую.** Запись — только `kbengine fin add`,
  затем `kbengine fin sync`. Это не стилевое предпочтение: строка без `id`
  становится второй копией покупки, и развести их потом нельзя.
- **Отказ движка показывать владельцу, а не обходить.** «Такая запись уже есть»
  — сработавшая защита. `--force` только по прямому слову владельца.
- **Consistent naming.** Название места брать из словаря
  `~/claude-cowork/finances/finance-aliases.json` — его же читает терминал.
- **Ask when uncertain.** If a receipt is partially unreadable or the category is ambiguous, ask the user rather than guessing wrong.
- **One transaction = one row.** Never duplicate entries from the same purchase.
- **Backup awareness.** Before making large batch changes, mention to the user that they might want to keep a backup.
- **Date awareness.** Today's date is available from the system. Use it as default when the user says "сегодня" or doesn't specify a date.
