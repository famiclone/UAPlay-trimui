## UAPlay 0.5.1 — TrimUI Brick & Smart Pro (NextUI `tg5040`)

Нативний порт **UAPlay** (україномовного відеокаталогу фільмів, серіалів, мультфільмів та аніме на базі `SDL2` + `libmpv`) під портативні консолі **TrimUI Brick** (`1024×768`) та **TrimUI Smart Pro** (`1280×720`) з прошивкою **NextUI**.

### Що реалізовано в порті
- **Готовий пакет NextUI Tool Pak (`UAPlay.pak.zip`):** запуск просто з меню **Tools → UAPlay**.
- **Адаптивний інтерфейс 1:1 піксель:** підтримка дисплеїв `1024×768` (TrimUI Brick / Brick Pro, 5 колонок постерів) та `1280×720` (TrimUI Smart Pro, 6 колонок постерів).
- **Вбудована екранна клавіатура (`УКР` / `ENG`):** введення пошукових запитів хрестовиною або стіком (`A` — символ, `X`/`L1` — стерти, `R1` — пробіл, `Y`/`MENU` — перемкнути мову, `START` — пошук, `B` — скасувати).
- **Вбудований плеєр `libmpv` + `FFmpeg` (ARM64 NEON):** плавне відтворення HLS/MP4, вибір озвучок, аудіодоріжок та субтитрів (включно з SubDL), завантаження на SD-карту для офлайн-перегляду, аудіовивід через `ALSA` (сумісний зі штатним динаміком та Bluetooth-аудіо NextUI).
- **Індикатор заряду батареї TrimUI (`axp2202-battery`)** та збереження бібліотеки в `/mnt/SDCARD/.userdata/tg5040/uaplay/`.

### Встановлення
1. Розпакуйте **`UAPlay.pak.zip`** у папку `/mnt/SDCARD/Tools/tg5040/UAPlay.pak/` на SD-карті з NextUI *(або встановіть через Pak Manager / Pak Store)*.
2. Додайте власний **TMDB v3 API Key** (одним рядком) у файл `Tools/tg5040/UAPlay.pak/tmdb.key` або `.userdata/tg5040/uaplay/tmdb.key` *(якщо ключ не вмонтовано під час збірки)*.
3. Запустіть **Tools → UAPlay** у меню NextUI.

---

### English Summary
Native **NextUI (`tg5040`)** port of [Small182/UAPlay-nx](https://github.com/Small182/UAPlay-nx) for **TrimUI Brick** (`1024×768`) and **TrimUI Smart Pro** (`1280×720`), featuring responsive 4:3 & 16:9 UI layouts, a built-in Ukrainian/English gamepad on-screen keyboard, static `libmpv` + `FFmpeg` (NEON) video playback, ALSA audio routing, offline HLS/MP4 downloads, and `axp2202` battery monitoring.

1. Extract **`UAPlay.pak.zip`** into `/mnt/SDCARD/Tools/tg5040/UAPlay.pak/` on your NextUI SD card.
2. Place your TMDB v3 API key in `Tools/tg5040/UAPlay.pak/tmdb.key` or `.userdata/tg5040/uaplay/tmdb.key`.
3. Launch from **Tools → UAPlay**.
