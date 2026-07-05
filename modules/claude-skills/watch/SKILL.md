---
name: watch
description: "Заставить Claude «посмотреть» видео - не только транскрипция, но и понимание того, что на экране (кадры по сменам сцен, привязанные к таймкодам). Работает с YouTube, Loom, Zoom, прямыми видео-URL и локальными файлами. Используй когда пользователь говорит «/watch <ссылка>», «посмотри видео», «разбери этот скринкаст», «что в этом видео», «изучи это видео», «watch <url>», кидает ссылку на YouTube/Loom/Zoom или путь к видеофайлу с просьбой разобрать. Три бесплатных инструмента под капотом: yt-dlp (скачать видео/субтитры/метаданные), whisper (транскрипция аудио локально если субтитров нет), ffmpeg (нарезка кадров = «глаза»)."
---

# Watch - Claude смотрит видео

Даёт Claude возможность «посмотреть» любое видео: скачать, получить транскрипт (публичные субтитры или whisper), нарезать кадры по сменам сцен с привязкой к таймкодам, прочитать кадры и собрать понимание того, что реально происходило на экране - без галлюцинаций и угадывания.

## Зависимости (все через Nix, НЕ ставить через pip/brew)
- `yt-dlp` - метаданные, субтитры, скачивание видео (nixpkgs: `pkgs.yt-dlp`; держать свежим - YouTube часто ломает старые версии).
- `ffmpeg` - нарезка кадров (уже в systemPackages).
- `whisper` - транскрипция аудио когда нет публичных субтитров. У Daniilа: whisper-cpp (nix, модель `~/models/whisper/ggml-small.bin`) ИЛИ python-venv `~/.claude-whisper/venv/bin/python transcribe.py <audio> small ru`.
- Браузер с залогиненной сессией (firefox/librewolf) - для `--cookies-from-browser` (age/private видео + часть YouTube-барьеров).

Перед работой: `command -v yt-dlp ffmpeg`. Если чего-то нет - НЕ ставить через pip; сказать добавить в Nix (`environment.systemPackages` в hosts/daniil-laptop/default.nix) и `home-manager switch`.

## Рабочая папка
Всё в `$PWD/.watch/<slug>/` — в корне ТОГО проекта, из которого вызван скилл (`$PWD` = текущая рабочая директория). Постоянный путь, не scratchpad — переживает сессию; каждый проект копит свои нарезки у себя. Тяжёлые кадры/аудио/видео удалять после разбора; оставлять транскрипт + итоговый markdown-конспект. Финальный конспект по запросу — в KB `~/claude-cowork/knowledge-base/docs/` (централизованно, независимо от проекта).

## Пайплайн

### 1. Определить источник
YouTube / Loom / Zoom / прямой видео-URL / локальный файл. От этого зависит, нужен ли обход PO-token (только YouTube).

### 2. Метаданные (yt-dlp)
```
yt-dlp --skip-download --cookies-from-browser firefox \
  --print "title:%(title)s | channel:%(channel)s | duration:%(duration_string)s | id:%(id)s" \
  --extractor-args "youtube:player_client=tv,web_safari" "<URL>"
```

### 3. Транскрипт (сначала субтитры - быстро, бесплатно, PO-token НЕ нужен)
```
yt-dlp --skip-download --write-auto-subs --write-subs \
  --cookies-from-browser firefox \
  --sub-langs "ru,ru-orig,en" --sub-format "vtt" \
  -o "$PWD/.watch/<slug>/subs.%(ext)s" "<URL>"
```
Распарсить .vtt в чистый текст: убрать таймкоды/теги/`[...]`, схлопнуть дублирующиеся строки (авто-субтитры повторяют при скролле). Субтитры лежат на отдельном открытом эндпоинте (timedtext) - работают даже когда видеофайл скачать нельзя. Если публичных субтитров нет → шаг 3b.

### 3b. Fallback: whisper (нет субтитров) - нужен аудиофайл (см. барьер в шаге 4)
```
yt-dlp -f "bestaudio/worst" --extract-audio --audio-format wav \
  --cookies-from-browser firefox \
  -o "$PWD/.watch/<slug>/audio.%(ext)s" "<URL>"
~/.claude-whisper/venv/bin/python ~/.claude-whisper/transcribe.py $PWD/.watch/<slug>/audio.wav small ru
```

### 4. Кадры = «глаза» (ffmpeg по сменам сцен) - нужен видеофайл
Скачать (низкое качество хватает):
```
yt-dlp -f "worst[ext=mp4]/worst" --cookies-from-browser firefox \
  -o "$PWD/.watch/<slug>/video.%(ext)s" "<URL>"
```
Нарезать кадры с таймкодами:
```
ffmpeg -i $PWD/.watch/<slug>/video.mp4 \
  -vf "select='gt(scene,0.3)',showinfo" -vsync vfr \
  $PWD/.watch/<slug>/frame_%04d.jpg 2>$PWD/.watch/<slug>/frames.log
```
Из frames.log (поле `pts_time` в showinfo) сопоставить каждый frame_NNNN.jpg с таймкодом. Для плотных скринкастов вместо scene-детекции: `-vf fps=1/5` (кадр каждые 5с). Затем Read каждый кадр (модель видит изображения) и привязать к таймкоду.

### 5. Синтез
Таймкодированный транскрипт + визуальные заметки по ключевым кадрам + summary «о чём видео и главные выводы». Спросить, сохранить ли конспект (KB `knowledge-base/docs/` или Obsidian).

## PO-token для YouTube - РЕШЕНО через Nix (проверено 2026-07-03)
YouTube за 2025-2026 требует GVS PO-token на скачивание видео/аудио (без него 403 на всех клиентах). Решено: пакет `bgutil-ytdlp-pot-provider` (nixpkgs) даёт yt-dlp плагин + бандлит node-сервер; работает в **script-режиме** (без постоянного сервиса). Настроено декларативно:
- В systemPackages: `(python3.withPackages (ps: [ yt-dlp bgutil-ytdlp-pot-provider ]))` - yt-dlp грузит плагин.
- В `~/.config/yt-dlp/config`: `--extractor-args "youtubepot-bgutilscript:server_home=<nix-store>/share/bgutil-ytdlp-pot-provider"` - автоподхват, ручных флагов не надо.
Проверено end-to-end: PO-token генерится через node-скрипт → YouTube-видео качается → ffmpeg режет кадры. Всё nix-native, без docker/pip.

Если `yt-dlp -v <URL>` НЕ показывает `PO Token Providers: bgutil` или снова 403 - проверить что `~/.config/yt-dlp/config` есть и server_home указывает на актуальный store-путь (после rebuild перегенерится).

## Честные оговорки
- **`--cookies-from-browser firefox`** нужен для age/private/региональных видео (сессия). Для публичных не обязателен, но не мешает.
- **Loom / Zoom / прямые файлы / локальные скринкасты** - PO-token вообще не при чём, всё работало и без bgutil.
- Кадры едят память/контекст: scene-детекция (порог 0.3) или 1 кадр/5с по умолчанию; не тащить сотни кадров без нужды.
- whisper медленнее субтитров - только когда публичных субтитров нет.

## Мета
Собран 2026-07-03 из разбора видео «Я научил Claude смотреть видео за меня» (Нейропросвещение/Ромарай) - с Nix-интеграцией вместо pip и честной поправкой на текущую PO-token-блокировку YouTube. Идея: агент, который смотрит = конкурентная разведка, обучение по видео-туториалам, разбор скринкастов команды/клиента → авто-план фиксов.
