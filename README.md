# Zapshop Garage MVP

Полноценный MVP Flutter-приложения для Android/iOS: гараж авто, история обслуживания, маркет запчастей Zapshop, избранное, корзина, заявки и AI-помощник с mock backend proxy интерфейсом.

## Запуск
1. Установите Flutter SDK (3.3+).
2. Выполните:
   ```bash
   flutter pub get
   flutter run
   ```

## API Zapshop
Base URL: `https://zapshop.by/wp-json/pmm/v1` в `lib/features/market/data/zapshop_api_client.dart`.

Используемые endpoints:
- `GET /parts`
- `GET /parts/match-car`
- `GET /parts/{id}`
- `POST /requests`

## Что реализовано
- Нижняя навигация: Главная / Гараж / Маркет / AI / Профиль.
- Hive-локальное хранение:
  - cars
  - service_records
  - favorites
  - cart
  - requests
  - profile
- Гараж:
  - добавление/редактирование/удаление авто
  - выбор активного авто
- История обслуживания:
  - добавление записей ремонта/обслуживания
  - расчёт расходов по авто на главной
- Маркет:
  - реальные API-запросы
  - поиск
  - infinite scroll
  - loading/error/empty
  - карточки товаров
  - карточка товара (детали + оформление заявки)
  - добавление в избранное/корзину
- Заявки:
  - отправка через `POST /requests`
  - локальное сохранение «Мои заявки»
- AI:
  - слой `AiService`
  - `MockAiService` с правилами (VIN/OEM, риски б/у, без 100% fit обещаний)

## AI Proxy (как заменить mock)
Сейчас используется `MockAiService` в `lib/features/ai/presentation/ai_screen.dart`.

Переход на реальный backend:
1. Реализовать `BackendAiService` с запросом `POST /api/ai/chat`.
2. Вынести в `features/ai/data` и внедрять через provider.
3. На сервере вызывать OpenAI Responses API.
4. Не хранить OpenAI ключ в мобильном приложении.

## Что можно доработать
- Отдельные экраны: избранное, корзина, мои заявки, авто из США, калькулятор ремонта (сейчас доступно через текущие разделы и данные профиля/маркета).
- Более глубокие фильтры и сортировка маркета.
- Синхронизация статусов заявок с серверным API (когда появится).
- Тесты widget/integration и CI pipeline.
