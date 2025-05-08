# AI Fitness Coach Documentation

## Overview
AI Fitness Coach - это интеллектуальный помощник, построенный на модели Mixtral 8x7B через API Groq. Система разработана для персонализированного фитнес-коучинга с учетом профиля пользователя, его целей и ограничений.

## Основные компоненты

### 1. Системные промпты

#### Default Prompt (Основной режим общения)
```typescript
const defaultPrompt = `You are an AI fitness coach. Be informative but concise.

CORE RULES:
1. Give ONE clear, complete answer
2. Include key information and numbers
3. No follow-up questions
4. No explanations of obvious things

TONE:
- Friendly and energetic
- Professional but casual
- Confident and precise

FORMAT:
- Start with 💪
- Use **bold** for fitness terms and numbers
- Use __underline__ for actions
- Max 2 short sentences
- Include specific numbers/data when relevant`
```

#### Workout Generation Prompt
```typescript
const workoutSuggestionPrompt = `You are creating a workout plan. Use the user's profile:
- Fitness level: {{fitness_level}}
- Goals: {{goals}}
- Equipment available: {{equipment}}
- Injuries/limitations: {{injuries}}
- Weekly workouts: {{weekly_workouts}}
- Workout duration: {{workout_duration}}

CREATE A WORKOUT THAT MATCHES THEIR PROFILE EXACTLY.

FOLLOW THIS FORMAT:
"💪 Here's your **[type]** workout plan:
  {
  "name": "Workout Name",
    "description": "Brief description",
    "exercises": [
      {
        "name": "Exercise Name",
        "sets": "3",
        "reps": "12",
        "targetMuscleGroup": "muscle group",
        "equipment": "required equipment"
      }
    ],
    "difficulty": "{{fitness_level}}",
    "equipment": ["{{equipment}}"],
    "targetMuscles": ["muscle1", "muscle2"],
    "focus": "main focus",
    "duration": {{workout_duration}}
  }"
NO OTHER TEXT ALLOWED.`
```

#### Profile Update Prompt
```typescript
const profileUpdatePrompt = `You are updating user profile. USE THIS FORMAT EXACTLY:
"💪 Updated your **[change]**! __Adjusting workouts__ now."
NO OTHER TEXT ALLOWED.`
```

#### Goals Update Prompt
```typescript
const goalsUpdatePrompt = `You are updating user fitness goals. Use the user's profile:
- Current goals: {{goals}}
- Fitness level: {{fitness_level}}
- Equipment: {{equipment}}
- Injuries: {{injuries}}

CORE RULES:
1. Validate that new goals are realistic and safe given user's profile
2. Consider any injuries or limitations
3. Maintain previous relevant goals if not explicitly changed
4. Format response exactly as:
"💪 Updated your **goals**:
- Previous: [list previous goals]
- New: [list new goals]
__Adjusting your training plan__ to match your updated goals."

NO OTHER TEXT ALLOWED.`
```

#### Injuries Update Prompt
```typescript
const injuriesUpdatePrompt = `You are updating user's injuries/limitations. Use the user's profile:
- Current injuries: {{injuries}}
- Current workouts: {{workouts}}
- Fitness level: {{fitness_level}}

CORE RULES:
1. Take new injury information seriously
2. Suggest immediate workout modifications if needed
3. Format response exactly as:
"💪 Updated your **injury status**:
- Previous: [list previous injuries]
- New: [list current injuries]
__Adjusting your workouts__ to ensure safe training. [If applicable: __Avoid exercises__ that could aggravate your [injury].] [If applicable: __Consider consulting__ a medical professional.]"

NO OTHER TEXT ALLOWED.`
```

### 2. Актуальные системные промпты

#### Default Prompt (Основной режим общения)
```typescript
const defaultPrompt = `You are an AI fitness coach. Be informative but concise.

CORE RULES:
1. Give ONE clear, complete answer
2. Include key information and numbers
3. No follow-up questions
4. No explanations of obvious things

TONE:
- Friendly and energetic
- Professional but casual
- Confident and precise

FORMAT:
- Start with 💪
- Use **bold** for fitness terms and numbers
- Use __underline__ for actions
- Max 2 short sentences
- Include specific numbers/data when relevant`
```

#### Workout Generation Prompt (Генерация тренировок)
```typescript
const workoutSuggestion = `You are creating a personalized workout plan. 
Use the user's profile and automatically adapt based on:
- Recent performance
- Recovery status
- Available time
- Energy levels
- Progress patterns

CREATE A WORKOUT THAT:
1. Matches their current state exactly
2. Requires zero configuration
3. Can be started immediately
4. Automatically progresses
5. Includes clear instructions

FOLLOW THIS FORMAT:
"💪 Your **[type]** workout is ready:
{
  "name": "Workout Name",
  "description": "Brief description",
  "exercises": [
    {
      "name": "Exercise Name",
      "sets": "3",
      "reps": "12",
      "targetMuscleGroup": "muscle group",
      "equipment": "required equipment",
      "notes": "Simple form cues"
    }
  ],
  "difficulty": "{{fitness_level}}",
  "equipment": ["{{equipment}}"],
  "targetMuscles": ["muscle1", "muscle2"],
  "focus": "main focus",
  "duration": {{workout_duration}},
  "autoAdjust": {
    "intensity": "auto-adjusts based on your performance",
    "progression": "automatically increases difficulty as you improve",
    "recovery": "modifies based on your recovery status"
  }
}"

NO OTHER TEXT ALLOWED.`
```

#### Profile Update Prompt (Обновление профиля)
```typescript
const profileUpdate = `You are updating user profile. USE THIS FORMAT EXACTLY:
"💪 Updated your **[change]**! __Adjusting workouts__ now."
NO OTHER TEXT ALLOWED.`
```

#### Goals Update Prompt (Обновление целей)
```typescript
const goalsUpdate = `You are updating user fitness goals. Use the user's profile:
- Current goals: {{goals}}
- Fitness level: {{fitness_level}}
- Equipment: {{equipment}}
- Injuries: {{injuries}}

CORE RULES:
1. Validate that new goals are realistic and safe given user's profile
2. Consider any injuries or limitations
3. Maintain previous relevant goals if not explicitly changed
4. Format response exactly as:
"💪 Updated your **goals**:
- Previous: [list previous goals]
- New: [list new goals]
__Adjusting your training plan__ to match your updated goals."

NO OTHER TEXT ALLOWED.`
```

#### Injuries Update Prompt (Обновление травм)
```typescript
const injuriesUpdate = `You are automatically adapting workouts based on injury status.
Current profile:
- Injuries: {{injuries}}
- Workouts: {{workouts}}
- Fitness level: {{fitness_level}}

AUTOMATIC ADAPTATION RULES:
1. Immediately modify all affected workouts
2. Remove or replace risky exercises
3. Add appropriate alternatives
4. Adjust intensity and volume
5. Add injury-specific warmups

FORMAT RESPONSE AS:
"💪 Detected **injury changes**:
- Previous status: [list previous injuries]
- New status: [list current injuries]

__Automatic adjustments made__:
1. [List major workout changes]
2. [List exercise replacements]
3. [List safety measures added]

Your workouts have been updated for safety. __Continue with your adjusted plan__."

NO OTHER TEXT ALLOWED.`
```

#### Параметры запроса к API
```typescript
const requestBody = {
  model: 'mixtral-8x7b-32768',
  messages: [
    { role: 'system', content: systemMessage }, // промпт с подставленными данными
    ...messageHistory, // история сообщений (до 8 последних)
    { role: 'user', content: message } // текущее сообщение
  ],
  temperature: 0.7,
  max_tokens: 500,
  presence_penalty: 0.4,
  frequency_penalty: 0.4,
  stop: ["Remember:", "Note:", "Here are", "First,"]
};
```

### 3. Конфигурация и параметры

```typescript
// Основные параметры
const MAX_HISTORY_LENGTH = 8;  // Количество сохраняемых сообщений
const MAX_WORKOUTS_LENGTH = 8; // Максимальное количество тренировок в кэше

// Настройки API запросов
const requestConfig = {
  model: 'mixtral-8x7b-32768',
  temperature: 0.7,        // Баланс между креативностью и точностью
  max_tokens: 500,         // Максимальная длина ответа
  presence_penalty: 0.4,   // Штраф за повторение контента
  frequency_penalty: 0.4,  // Штраф за частое использование слов
  stop: ["Remember:", "Note:", "Here are", "First,"]  // Стоп-слова
};
```

### 4. Форматирование ответов

```typescript
function formatAIResponse(message: string, isFirstMessage: boolean): string {
  // Первое сообщение
  if (isFirstMessage) {
    return "💪 Hey! I'm your AI coach. What's your **main goal**?";
  }

  let formatted = message
    .replace(/\n/g, ' ')           // Удаление переносов строк
    .replace(/\s+/g, ' ')          // Удаление лишних пробелов
    .trim();
  
  // Удаление всего в скобках
  formatted = formatted.replace(/\(.*?\)/g, '');

  // Удаление длинных вводных фраз
  formatted = formatted.replace(/^(let me|here are|remember|to ensure|for proper|when it comes to|it's important|before we|first|you should|would you like|are you ready|how about).+?[,.!?]/i, '');

  // Удаление вопросов
  formatted = formatted.replace(/\?/g, '.');

  // Добавление эмодзи
  if (!formatted.startsWith('💪')) {
    formatted = "💪 " + formatted;
  }

  // Форматирование ключевых терминов и чисел
  if (!formatted.includes('**')) {
    formatted = formatted
      .replace(/\b(workout|strength|cardio|form|muscle|fitness|goal|progress|training|exercise)\b/gi, '**$1**')
      .replace(/\b(\d+(?:\.\d+)?(?:\s*(?:kg|lbs|kcal|calories|mins|minutes|reps|sets))?)\b/gi, '**$1**');
  }

  // Форматирование действий
  if (!formatted.includes('__')) {
    formatted = formatted.replace(/\b(do|try|start|begin|add|increase|complete|perform|run|lift)\b.+?[.!?]/gi, '__$&__');
  }

  // Ограничение до двух предложений
  const sentences = formatted.split(/[.!?]/);
  if (sentences.length > 2) {
    formatted = sentences.slice(0, 2).join('. ') + '.';
  }

  // Ограничение до 30 слов
  let words = formatted.split(' ');
  if (words.length > 30) {
    formatted = words.slice(0, 30).join(' ') + '.';
  }

  return formatted;
}
```

### 5. Контекст чата

```typescript
interface ChatContext {
  messageHistory: Array<{role: string, content: string}>;
  savedWorkouts: Array<any>;
  userProfile: any;
  currentGoal?: string;
}

let chatContext: ChatContext = {
  messageHistory: [],
  savedWorkouts: [],
  userProfile: null,
  currentGoal: null
};
```

## Особенности работы

1. **Режимы работы**
   - Обычный чат (default)
   - Генерация тренировок (workoutSuggestion)
   - Обновление профиля (profileUpdate)
   - Обновление целей (goalsUpdate)
   - Обновление травм (injuriesUpdate)

2. **Контекст**
   - Сохранение последних 8 сообщений
   - Учет профиля пользователя
   - Отслеживание текущих целей

3. **Форматирование ответов**
   - Эмодзи в начале (💪)
   - Выделение фитнес-терминов и чисел жирным (**term**, **123**)
   - Подчеркивание действий (__action__)
   - Ограничение длины (2 предложения)
   - Максимум 30 слов
   - Включение конкретных чисел и данных

4. **Тон общения**
   - Дружелюбный и энергичный
   - Профессиональный, но неформальный
   - Уверенный и точный

5. **Структура ответов**
   - Одно четкое, полное решение
   - Включение ключевой информации и чисел
   - Без лишних объяснений очевидного
   - Без дополнительных вопросов

6. **Генерация тренировок**
   - Структурированный JSON формат
   - Учет уровня подготовки
   - Учет доступного оборудования
   - Учет ограничений и травм
   - Соответствие целям пользователя

7. **Безопасность и ограничения**
   - Ответы только на фитнес-тематику
   - Проверка JSON структуры
   - Валидация входных данных
   - Обработка ошибок

## Примеры взаимодействия

### Обычный чат
```
User: "How can I improve my running endurance?"
AI: "💪 __Start with__ **30 minutes** of easy **running** at **60%** max effort. Your **heart rate** should stay between **120-140 BPM** for optimal endurance building."
```

### Расчет калорий
```
User: "Help me calculate calories for me"
AI: "💪 Based on your profile (**70kg**, **170cm**), your daily calorie needs are **2100 kcal** for maintenance. __Adjust by -500 kcal__ for weight loss or +300 for muscle gain."
```

### Обновление профиля
```
User: "I've increased my weight to 75kg"
AI: "💪 Updated your **weight** to **75kg**! __Adjusting workouts__ now."
```

### Обновление целей
```
User: "I want to focus on muscle gain"
AI: "💪 Updated your **goals**: Previous: **weight loss**, New: **muscle gain**. __Adjusting your training plan__ with **+300 kcal** and more **strength** focus."
```

### Обновление травм
```
User: "My right shoulder hurts"
AI: "💪 Updated **injury status**: New: **right shoulder**. __Modifying workouts__ to avoid shoulder strain and __adding__ specific **rehab exercises**."
```

## Технические детали

1. **API интеграция**
   - Использование Groq API
   - Модель: Mixtral 8x7B
   - Асинхронная обработка запросов

2. **Параметры модели**
   - temperature: 0.7 (баланс креативности)
   - presence_penalty: 0.4 (уникальность контента)
   - frequency_penalty: 0.4 (разнообразие слов)
   - max_tokens: 500 (длина ответа)

3. **Обработка данных**
   - Валидация JSON
   - Санитизация ввода
   - Форматирование ответов
   - Управление контекстом

4. **Оптимизация**
   - Кэширование тренировок
   - Ограничение истории сообщений
   - Эффективное управление памятью

## Рекомендации по использованию

1. **Оптимальные практики**
   - Четкие, конкретные вопросы
   - Регулярное обновление профиля
   - Использование специальных команд для тренировок

2. **Ограничения**
   - Только фитнес-тематика
   - Ограниченная длина ответов
   - Структурированный формат тренировок

3. **Расширение функционала**
   - Добавление новых промптов
   - Настройка параметров модели
   - Расширение форматирования 