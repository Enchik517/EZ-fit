```typescript
const requestConfig = {
  model: 'gemini-2.0-flash-lite',
  temperature: 0.7,        // Баланс между креативностью и точностью
  max_tokens: 500,         // Максимальная длина ответа
  presence_penalty: 0.4,   // Штраф за повторение контента
  frequency_penalty: 0.4,  // Штраф за частое использование слов
  stop: ["Remember:", "Note:", "Here are", "First,"]  // Стоп-слова
};

// Формат запроса к API
const requestBody = {
  model: 'gemini-2.0-flash-lite',
  messages: [
    { role: 'system', content: systemMessage }, // промпт с подставленными данными
    ...messageHistory,                          // история сообщений (до 8 последних)
    { role: 'user', content: message }         // текущее сообщение
  ],
  temperature: 0.7,
  max_tokens: 500,
  presence_penalty: 0.4,
  frequency_penalty: 0.4,
  stop: ["Remember:", "Note:", "Here are", "First,"]
};
```

Этот файл содержит конфигурацию для запросов к Gemini API, включая параметры модели и формат запроса.

Основные параметры:
- model: gemini-2.0-flash-lite
- temperature: 0.7 (баланс креативности)
- max_tokens: 500 (длина ответа)
- presence_penalty: 0.4 (уникальность)
- frequency_penalty: 0.4 (разнообразие) 