---
name: finance-tracker
description: "Personal finance tracker (учёт финансов) for income and expense management. Use this skill whenever the user sends a photo of a receipt or bank notification screenshot, mentions spending or earning money, asks about their budget or finances, wants to add an expense or income entry, or asks for a financial summary or report. Triggers on Russian: 'потратил', 'заработал', 'чек', 'расход', 'доход', 'баланс', 'сколько потратил', 'добавь трату', 'запиши расход', 'финансы', 'бюджет', 'учёт финансов', 'сводка'. Triggers on English: receipt, expense, income, transaction, finance tracker, budget, spending, salary, balance. Also triggers on category mentions: groceries, taxi, rent, продукты, такси, аренда, зарплата. MANDATORY: Always use the xlsx skill alongside this skill when modifying the spreadsheet."
---

# Finance Tracker

Personal income and expense tracker. The user sends receipts (photos), bank notifications, or simply describes transactions in natural language. Claude parses the data and records it into an Excel spreadsheet.

## Dependencies

**This skill requires the `xlsx` skill.** Before modifying the spreadsheet, always read and follow the xlsx skill instructions.

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

Always use the **xlsx skill** when working with the spreadsheet. Read the xlsx SKILL.md first.

### Steps:

1. Mount `~/claude-cowork` via `request_cowork_directory` if not already mounted. Store the returned VM path.
2. Load the workbook with openpyxl:
   ```python
   from openpyxl import load_workbook
   # Use the VM path returned by request_cowork_directory + /finances/Учёт_финансов.xlsx
   wb = load_workbook(f'{mounted_path}/finances/Учёт_финансов.xlsx')
   ```
3. Select the target sheet (`Расходы` or `Доходы`)
4. Find the last filled row (iterate from the bottom or use `ws.max_row`)
5. Write data to the next row, matching the column structure exactly
6. Save the workbook
7. Recalculate the Сводка sheet (run `scripts/recalc.py` if it exists, or update formulas manually via openpyxl)

### Date handling

Store dates as `DD.MM.YYYY` strings. If the receipt has a different format, convert it. If no year is present, assume the current year.

### Amount handling

- Strip currency symbols, spaces, and thousand separators
- Convert comma decimals to dots if needed for numeric storage
- Store as a plain number (float or int)

---

## Natural Language Input

The user may skip photos and just type something like:
- "потратил 300 на такси"
- "зарплата 150000"
- "обед в Теремке 450р"
- "купил кроссовки за 8000"

Parse intent:
- If it describes spending → add to Расходы
- If it describes earning → add to Доходы
- Extract amount, venue/source, and infer category
- If category is ambiguous, ask
- Set Источник to `вручную`

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

## Reporting and Analysis

When the user asks "сколько потратил", "покажи сводку", "баланс", or similar:

1. Read the Сводка sheet
2. Present a clean summary in Russian
3. Optionally offer to create a chart or more detailed breakdown
4. If the user wants a visual report, consider creating an HTML artifact with charts

---

## Important Rules

- **Always read the xlsx skill** before modifying the spreadsheet. Invoke the `xlsx` skill or read its SKILL.md. This is non-negotiable.
- **Verify formulas** on the Сводка sheet after every change. If formulas reference row ranges, expand them if needed to include new data.
- **Consistent naming.** Before adding a venue, search existing entries in column D of Расходы. Reuse existing names exactly.
- **Ask when uncertain.** If a receipt is partially unreadable or the category is ambiguous, ask the user rather than guessing wrong.
- **One transaction = one row.** Never duplicate entries from the same purchase.
- **Backup awareness.** Before making large batch changes, mention to the user that they might want to keep a backup.
- **Date awareness.** Today's date is available from the system. Use it as default when the user says "сегодня" or doesn't specify a date.
