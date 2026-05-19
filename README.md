# Zapshop Garage MVP

Flutter MVP-приложение Zapshop Garage: гараж, история обслуживания, маркет запчастей Zapshop, избранное/корзина/заявки и AI-помощник.

## Установка и запуск
1. Установите Flutter SDK (stable 3.3+).
2. Откройте проект в VS Code.
3. Выполните:
   ```bash
   flutter pub get
   flutter run
   ```

## Маркет API (реальный)
Base URL: `https://zapshop.by/wp-json/pmm/v1`

Используемые endpoints:
- `GET /parts` (основной список, например `https://zapshop.by/wp-json/pmm/v1/parts?page=1&per_page=20`)
- `GET /parts/match-car`
- `GET /parts/{id}`
- `POST /requests`

## Реализовано
- Нижняя навигация: Главная / Гараж / Маркет / AI / Профиль.
- Hive-локальное хранение:
  - cars
  - service_records
  - favorites
  - cart
  - requests
  - profile
- Гараж: добавление/редактирование/удаление авто, выбор активного авто.
- История обслуживания: добавление записи и учет расходов по авто.
- Маркет:
  - загрузка реальных товаров из `/parts`
  - поиск
  - infinite scroll
  - фильтр «Запчасти под мое авто» через `/parts/match-car`
  - карточка товара через `/parts/{id}`
  - добавление в избранное и корзину
  - отправка заявки через `/requests`
  - loading / error / empty состояния + retry
- AI-помощник:
  - архитектурный интерфейс `AiService`
  - `MockAiService` для работы без backend
  - безопасные ответы без обещаний 100% совместимости без VIN/OEM
  - архитектура готова для backend proxy

## ChatGPT/AI backend proxy
Важно: OpenAI API key нельзя хранить в мобильном приложении.

Как подключить real ChatGPT:
1. Реализовать backend endpoint `POST /api/ai/chat`.
2. На backend вызывать OpenAI Responses API.
3. В мобильном приложении использовать `BackendAiProxyService` (уже подготовлен контракт).
4. Для фото-анализа запчасти отправлять изображение в backend proxy (base64/multipart), а не в OpenAI напрямую из приложения.

## Что еще можно улучшить
- Выделить AI-фичу по слоям `data/domain/presentation` в отдельные файлы.
- Добавить отдельные экраны Избранное / Корзина / Мои заявки.
- Добавить авто-термины USA import и калькулятор ремонта как отдельные разделы.
- Добавить widget/integration тесты и CI.
