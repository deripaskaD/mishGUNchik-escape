# Launch / Export Notes — Timokha Escape

Готовность к экспортным сборкам (НЕ собраны автоматически — нужны платформенные SDK/подписи).

## Общее
- Рендер: Mobile; ландшафт; логический вьюпорт 1280×720, stretch `keep`.
- Тач-ввод первичный; клавиатура — для desktop-теста.

## Android
- Установить Android export templates + SDK/JDK в Godot (Editor → Manage Export Templates).
- ⚠️ Godot 4.7 breaking change: формат **OBB legacy** изменён — использовать актуальную
  APK/AAB-упаковку, не legacy OBB (см. `docs/engine-reference/godot/VERSION.md`).
- Создать keystore, заполнить package name (напр. `com.example.timokhaescape`).
- Экспорт AAB для Google Play.

## iOS
- Требуется macOS + Xcode + Apple Developer аккаунт.
- Godot iOS export templates; настроить Bundle Identifier, подпись, иконки.
- Собрать Xcode-проект → архив → App Store Connect.

## Перед релизом (рекомендуемый чек-лист пайплайна)
- [ ] Реальный арт (drop-in `art/<key>.png`) и звук (`audio/sfx`, `audio/music`).
- [ ] Туториал/онбординг, настройки (громкость), локализация-хуки.
- [ ] `/security-audit` — защита сейва от подмены (сейчас открытый JSON).
- [ ] `/soak-test` и плейтест баланса погони на реальных устройствах.
- [ ] `/launch-checklist` — финальная проверка готовности к стору.
