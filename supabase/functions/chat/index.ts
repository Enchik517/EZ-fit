// Follow this setup guide to integrate the Deno runtime into your project:
// https://deno.land/manual/getting_started/setup_your_environment

// @ts-ignore
// deno-lint-ignore-file no-explicit-any
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

console.log("Chat function started")

// Новая функция для определения намерений с помощью AI
async function classifyIntentWithAI(message: string, userProfile: any): Promise<string> {
  try {
    // Проверяем, является ли сообщение ответом на уточняющий вопрос
    if (chatContext.messageHistory.length > 0) {
      const lastAIMessage = chatContext.messageHistory.find(msg => msg.role === 'assistant')?.content || '';
      
      // Если последний ответ AI был уточняющим вопросом
      if (lastAIMessage.includes('?') && 
          (lastAIMessage.toLowerCase().includes('lose weight') || lastAIMessage.toLowerCase().includes('похудеть')) &&
          (lastAIMessage.toLowerCase().includes('gain weight') || lastAIMessage.toLowerCase().includes('набрать'))) {
        
        // Если пользователь указывает на похудение
        if (message.toLowerCase().includes('lose') || 
            message.toLowerCase().includes('похуд') || 
            message.toLowerCase().includes('сбросить') ||
            message.toLowerCase().includes('первое') ||
            message.toLowerCase().includes('первый') ||
            message.toLowerCase().includes('1')) {
          return 'weight_loss_plan';
        }
        
        // Если пользователь указывает на набор веса/массы
        if (message.toLowerCase().includes('gain') || 
            message.toLowerCase().includes('набр') || 
            message.toLowerCase().includes('массу') ||
            message.toLowerCase().includes('второе') ||
            message.toLowerCase().includes('второй') ||
            message.toLowerCase().includes('2')) {
          return 'muscle_gain_plan';
        }
      }
    }
  
    // Создаем промпт для классификации
    const classificationPrompt = `
[TASK: Classify user message intent]

USER PROFILE:
${userProfile ? `
- Age: ${userProfile.age}
- Gender: ${userProfile.gender}
- Weight: ${userProfile.weight} kg
- Height: ${userProfile.height} cm
- Fitness level: ${userProfile.fitness_level}
- Goals: ${userProfile.goals?.join(', ')}
- Equipment: ${userProfile.equipment?.join(', ')}
` : 'No profile available'}

USER MESSAGE: "${message}"

CLASSIFY into EXACTLY ONE of:
- profile_info (user wants to see their profile data)
- profile_update (user wants to update their profile)
- weight_loss_plan (user wants a weight loss plan or advice)
- muscle_gain_plan (user wants a muscle gain plan)
- general_workout_plan (user wants any workout not specific to weight loss or muscle gain)
- nutrition_advice (user wants dietary or nutrition advice)
- recovery_advice (user wants recovery or rest advice)
- general_chat (general fitness chat, default if nothing matches)

REPLY WITH ONLY THE INTENT LABEL, nothing else.`;

    // Формируем запрос к API
    const requestBody = {
      contents: [{
        role: 'user',
        parts: [{ text: classificationPrompt }]
      }],
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 10
      }
    };

    // Отправляем запрос
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${Deno.env.get('GEMINI_API_KEY')}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(requestBody)
    });

    if (!response.ok) {
      throw new Error(`AI classification error: ${await response.text()}`);
    }

    const result = await response.json();
    const intentText = result.candidates?.[0]?.content?.parts?.[0]?.text || '';
    
    // Очищаем ответ от лишних символов и приводим к нижнему регистру
    const cleanIntent = intentText.trim().toLowerCase();
    
    // Проверяем, что ответ соответствует одному из намерений
    const validIntents = [
      'profile_info', 'profile_update', 'weight_loss_plan', 
      'muscle_gain_plan', 'general_workout_plan', 'nutrition_advice',
      'recovery_advice', 'general_chat'
    ];
    
    if (validIntents.includes(cleanIntent)) {
      return cleanIntent;
    }
    
    // Если ответ не соответствует ни одному из намерений, вернем общий чат
    return 'general_chat';
  } catch (error) {
    console.error('Error classifying intent:', error);
    return 'general_chat';
  }
}

const messageEmojis = {
  greeting: ['👋', '✨', '🌟', '💫', '😊', '🤗', '👍', '🙌', '👏', '🎉'],
  workout: ['💪', '🏋️', '🎯', '⚡', '🔥', '🏃', '🤸', '🧘', '🏆', '💯', '🚀', '🏄', '🧗', '🤾', '🏊', '🚴', '🥊'],
  nutrition: ['🥗', '🍎', '🥑', '🥩', '🍗', '🥦', '🥛', '🍓', '🍽️', '🥝', '🍹', '🥤', '🍚', '🥜', '🧉', '🍲', '🫐'],
  progress: ['📈', '🎯', '🌟', '💫', '🚀', '🔝', '🏆', '🌈', '💎', '✅', '📊', '🔄', '↗️', '🏅', '🎖️', '🦾', '⬆️'],
  motivation: ['💪', '🔥', '⚡', '✨', '💯', '🚀', '🎯', '📈', '⭐', '💎', '🏁', '🧠', '💥', '👊', '😤', '🔋', '⏱️'],
  recovery: ['🧘', '💆', '🌿', '🎋', '🧠', '😴', '🌙', '⏱️', '🔄', '🌊', '🧖', '☕', '💤', '🛌', '🌼', '🧘‍♀️', '🌱'],
  profile: ['👤', '📝', '✏️', '✨', '🧩', '📊', '🔍', '🧿', '📌', '📋', '📂', '🗃️', '📇', '👁️', '📱', '🖊️', '📔'],
  system: ['🔄', '⚙️', '🔧', '📢', '🔔', '🔎', '🖥️', '📱', '⌨️', '🔌', '📡', '🗃️', '📂', '⏰', '🔐', '🛠️', '📊'],
  error: ['⚠️', '❌', '🚫', '⛔', '😵', '🆘', '⭕', '🔴', '❗', '❓', '⁉️', '🔇', '💢', '😬', '🤬', '😱', '🤔'],
  success: ['✅', '👍', '🌟', '💫', '🎉', '🥳', '🏆', '🎊', '💯', '🤩', '💚', '👌', '🙌', '💪', '🚀', '🔥', '👏']
};

const systemPrompts = {
  default: `You are an AI fitness coach and personal assistant. Be smart, friendly and context-aware.

CORE RULES:
1. Keep all responses SHORT and CONCISE - max 250 words
2. Be friendly, warm, and encouraging
3. Use appropriate emojis to make responses engaging
4. Give specific, actionable advice
5. NEVER return JSON code blocks or technical formats
6. Focus only on fitness and health

FORMAT RULES:
- Use conversational, casual tone
- Add 1-2 emojis maximum per response
- Avoid long lists of information
- Break text into small, readable chunks
- Use **bold** for important points only (sparingly!)
- Be brief but helpful

RESPONSE STRUCTURE:
- Greet user if appropriate
- Answer their question directly
- End with a brief encouragement

Make users feel motivated and supported!`,

  workoutSuggestion: `You are creating a personalized workout suggestion. 
Keep it BRIEF and CONVERSATIONAL:

1. Suggest only 2-3 exercises maximum
2. Do NOT use JSON or code blocks
3. Keep response under 200 words
4. Be friendly and encouraging
5. Use simple language and explanations
6. Add 1-2 emojis maximum

FORMAT AS:
"[Emoji] Here's a quick [type] exercise you can try:

• [Exercise 1]: Brief description
• [Exercise 2]: Brief description

Let me know if you'd like to try it!"

NO OTHER TEXT ALLOWED.`,

  profileUpdate: `You are updating user profile. USE THIS FORMAT EXACTLY:
"[Emoji] Updated your **[change]**! I'll adjust my recommendations for you."
NO OTHER TEXT ALLOWED.`,

  goalsUpdate: `You are updating user fitness goals.

CORE RULES:
1. Be brief and friendly
2. Keep response under 150 words
3. Format response exactly as:
"[Emoji] Updated your goals from [previous] to [new]. I'll adapt my advice to help you reach them!"

NO OTHER TEXT ALLOWED.`,

  injuriesUpdate: `You are acknowledging injury status changes.

FORMAT RESPONSE AS:
"[Emoji] Got it - I'll be careful about your [injury]. I'll modify my advice to keep you safe and comfortable."

NO OTHER TEXT ALLOWED.`
};

const MAX_HISTORY_LENGTH = 8;
const MAX_WORKOUTS_LENGTH = 8;

interface MuscleLoad {
  muscleGroup: string;
  lastTrainedDate: string;
  recoveryStatus: number; // 0-100%, где 100% - полное восстановление
  frequencyLastMonth: number;
  intensity: number; // 1-10
}

interface WorkoutHistory {
  date: string;
  muscleGroups: {
    [key: string]: {
      intensity: number;
      exercises: string[];
    }
  };
}

interface ChatContext {
  messageHistory: Array<{role: string, content: string}>;
  userMessageHistories: { [userId: string]: Array<{role: string, content: string}> };
  savedWorkouts: Array<any>;
  userProfile: any;
  currentGoal?: string;
  muscleLoads: { [key: string]: MuscleLoad };
  workoutHistory: WorkoutHistory[];
  lastDetectedLanguage?: string;
}

let chatContext: ChatContext = {
  messageHistory: [],
  userMessageHistories: {},
  savedWorkouts: [],
  userProfile: null,
  currentGoal: null,
  muscleLoads: {},
  workoutHistory: [],
  lastDetectedLanguage: 'en'
};

// Создаем Supabase клиент
const supabaseClient = createClient(
  Deno.env.get('SUPABASE_URL') || '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
);

// Функция для получения профиля пользователя
async function getUserProfile(userId: string) {
  if (!userId) return null;
  
  try {
    const { data, error } = await supabaseClient
      .from('user_profiles')
      .select('*')
      .eq('id', userId);

    if (error) throw error;
    return data?.[0] || null;
  } catch (e) {
    console.error('Error fetching user profile:', e);
    return null;
  }
}

// Add new function to select appropriate emoji
function selectEmoji(message: string, context: any): string {
  const lowerMessage = message.toLowerCase();
  
  // Determine message type
  if (lowerMessage.includes('hi') || lowerMessage.includes('hello') || lowerMessage.includes('hey')) {
    return messageEmojis.greeting[Math.floor(Math.random() * messageEmojis.greeting.length)];
  }
  
  if (lowerMessage.includes('workout') || lowerMessage.includes('exercise') || lowerMessage.includes('training')) {
    return messageEmojis.workout[Math.floor(Math.random() * messageEmojis.workout.length)];
  }
  
  if (lowerMessage.includes('eat') || lowerMessage.includes('food') || lowerMessage.includes('diet') || lowerMessage.includes('nutrition')) {
    return messageEmojis.nutrition[Math.floor(Math.random() * messageEmojis.nutrition.length)];
  }
  
  if (lowerMessage.includes('progress') || lowerMessage.includes('improve') || lowerMessage.includes('better')) {
    return messageEmojis.progress[Math.floor(Math.random() * messageEmojis.progress.length)];
  }
  
  if (lowerMessage.includes('tired') || lowerMessage.includes('rest') || lowerMessage.includes('recovery')) {
    return messageEmojis.recovery[Math.floor(Math.random() * messageEmojis.recovery.length)];
  }
  
  if (lowerMessage.includes('profile') || lowerMessage.includes('update') || lowerMessage.includes('change')) {
    return messageEmojis.profile[Math.floor(Math.random() * messageEmojis.profile.length)];
  }
  
  if (lowerMessage.includes('can') || lowerMessage.includes('want') || lowerMessage.includes('need')) {
    return messageEmojis.motivation[Math.floor(Math.random() * messageEmojis.motivation.length)];
  }
  
  // Default to random workout emoji
  return messageEmojis.workout[Math.floor(Math.random() * messageEmojis.workout.length)];
}

function formatAIResponse(message: string, context: any): string {
  // Remove newlines and multiple spaces
  let formatted = message.replace(/\n/g, ' ').replace(/\s+/g, ' ').trim();

  // Remove all parentheses and their content (оставляем только один проход)
  formatted = formatted.replace(/\(.*?\)/g, '');

  // Простое определение типа сообщения для эмодзи
  let messageType = 'workout'; // Default
  if (formatted.toLowerCase().includes('hello') || formatted.toLowerCase().includes('привет')) {
    messageType = 'greeting';
  } else if (formatted.toLowerCase().includes('eat') || formatted.toLowerCase().includes('nutrition')) {
    messageType = 'nutrition';
  } else if (formatted.toLowerCase().includes('rest') || formatted.toLowerCase().includes('recovery')) {
    messageType = 'recovery';
  } else if (formatted.toLowerCase().includes('progress') || formatted.toLowerCase().includes('improve')) {
    messageType = 'progress';
  } else if (formatted.toLowerCase().includes('motivation') || formatted.toLowerCase().includes('goal')) {
    messageType = 'motivation';
  }

  // Handle system messages differently
  if (message.toLowerCase().includes('history cleared') || message.toLowerCase().includes('deleted')) {
    const systemEmoji = messageEmojis.system[Math.floor(Math.random() * messageEmojis.system.length)];
    return `${systemEmoji} ${formatted}`;
  }

  // Handle error messages
  if (message.toLowerCase().includes('error') || message.toLowerCase().includes('failed')) {
    const errorEmoji = messageEmojis.error[Math.floor(Math.random() * messageEmojis.error.length)];
    return `${errorEmoji} ${formatted}`;
  }

  // Handle success messages
  if (message.toLowerCase().includes('success') || message.toLowerCase().includes('updated')) {
    const successEmoji = messageEmojis.success[Math.floor(Math.random() * messageEmojis.success.length)];
    return `${successEmoji} ${formatted}`;
  }

  // Получаем соответствующий набор эмодзи и выбираем один случайный
  const emojiSet = messageEmojis[messageType] || messageEmojis.workout;
  const primaryEmoji = emojiSet[Math.floor(Math.random() * emojiSet.length)];
  
  // Добавляем эмодзи в начало, если его еще нет
  if (!formatted.match(/^[\p{Emoji}]/u)) {
    formatted = `${primaryEmoji} ${formatted}`;
  }

  // Больше не делаем сложного форматирования со списками и предложениями
  // Просто добавляем базовое выделение ключевых терминов
  if (!formatted.includes('**')) {
    formatted = formatted
      .replace(/\b(workout|strength|cardio|form|muscle|fitness|goal|progress|training|exercise|protein|calories|weight|rest|recovery|sets|reps)\b/gi, '**$1**')
      .replace(/\b(\d+(?:\.\d+)?(?:\s*(?:kg|lbs|kcal|calories|mins|minutes|reps|sets))?)\b/gi, '**$1**');
  }

  return formatted;
}

// Добавляем автоматическое определение состояния пользователя
function detectUserState(message: string, context: any): string {
  const lowerMessage = message.toLowerCase();
  
  // Определяем усталость/восстановление
  if (lowerMessage.includes('tired') || lowerMessage.includes('sore') || lowerMessage.includes('exhausted')) {
    return 'recovery_needed';
  }
  
  // Определяем прогресс
  if (lowerMessage.includes('easier') || lowerMessage.includes('better') || lowerMessage.includes('stronger')) {
    return 'progress_made';
  }
  
  // Определяем временные ограничения
  if (lowerMessage.includes('busy') || lowerMessage.includes('no time') || lowerMessage.includes('quick')) {
    return 'time_constrained';
  }
  
  // Определяем пропуск тренировок
  if (lowerMessage.includes('missed') || lowerMessage.includes('skipped') || lowerMessage.includes('couldn\'t workout')) {
    return 'missed_workouts';
  }
  
  return 'normal';
}

// Функция для расчета восстановления мышечных групп
function calculateMuscleRecovery(muscleLoads: { [key: string]: MuscleLoad }): { [key: string]: MuscleLoad } {
  const now = new Date();
  const updatedLoads = { ...muscleLoads };

  for (const [muscle, load] of Object.entries(updatedLoads)) {
    const daysSinceLastTraining = (now.getTime() - new Date(load.lastTrainedDate).getTime()) / (1000 * 60 * 60 * 24);
    
    // Базовое восстановление: 2 дня для полного восстановления при средней интенсивности
    let recoveryRate = 50 / (load.intensity || 5); // % восстановления в день
    let newRecoveryStatus = Math.min(100, load.recoveryStatus + (daysSinceLastTraining * recoveryRate));
    
    updatedLoads[muscle] = {
      ...load,
      recoveryStatus: newRecoveryStatus
    };
  }

  return updatedLoads;
}

// Функция для обновления нагрузки после тренировки
function updateMuscleLoads(workout: any, muscleLoads: { [key: string]: MuscleLoad }): { [key: string]: MuscleLoad } {
  const now = new Date().toISOString();
  const updatedLoads = { ...muscleLoads };
  
  // Обновляем нагрузку для каждой мышечной группы в тренировке
  for (const muscle of workout.targetMuscles) {
    const currentLoad = updatedLoads[muscle] || {
      muscleGroup: muscle,
      lastTrainedDate: now,
      recoveryStatus: 100,
      frequencyLastMonth: 0,
      intensity: 5
    };

    // Обновляем статистику
    updatedLoads[muscle] = {
      ...currentLoad,
      lastTrainedDate: now,
      recoveryStatus: Math.max(0, currentLoad.recoveryStatus - 60), // Уменьшаем восстановление
      frequencyLastMonth: currentLoad.frequencyLastMonth + 1,
      intensity: workout.intensity || currentLoad.intensity
    };
  }

  return updatedLoads;
}

// Функция для определения приоритетных мышечных групп
function getPriorityMuscles(muscleLoads: { [key: string]: MuscleLoad }): string[] {
  const muscleEntries = Object.entries(muscleLoads);
  
  // Сортируем мышечные группы по восстановлению и частоте тренировок
  return muscleEntries
    .sort(([, a], [, b]) => {
      // Приоритет отдаем наиболее восстановленным и редко тренируемым мышцам
      const recoveryScore = b.recoveryStatus - a.recoveryStatus;
      const frequencyScore = a.frequencyLastMonth - b.frequencyLastMonth;
      return recoveryScore + frequencyScore;
    })
    .map(([muscle]) => muscle);
}

// Добавляем в начало файла функцию для получения контекста профиля
function getProfileContext(profile: any) {
  // Если профиль не найден, возвращаем ошибку
  if (!profile) {
    throw new Error('Profile not found. Please complete your profile setup.');
  }
  
  const context = {
    weight: Number(profile.weight) || 70,
    height: Number(profile.height) || 170,
    age: Number(profile.age) || 30,
    gender: profile.gender || 'male',
    activity_level: profile.activity_level || 'moderate',
    fitness_level: profile.fitness_level || 'intermediate',
    goals: Array.isArray(profile.goals) ? profile.goals : [],
    injuries: Array.isArray(profile.injuries) ? profile.injuries : [],
    equipment: Array.isArray(profile.equipment) ? profile.equipment : [],
    weekly_workouts: Number(profile.weekly_workouts) || 3,
    workout_duration: Number(profile.workout_duration) || 45,
  };

  // Рассчитываем BMR используя формулу Миффлина-Сан Жеора
  const bmr = context.gender === 'male'
    ? (10 * context.weight) + (6.25 * context.height) - (5 * context.age) + 5
    : (10 * context.weight) + (6.25 * context.height) - (5 * context.age) - 161;

  // Коэффициенты активности
  const activityMultipliers = {
    sedentary: 1.2,      // Малоподвижный образ жизни
    light: 1.375,        // Легкая активность (1-3 раза в неделю)
    moderate: 1.55,      // Умеренная активность (3-5 раз в неделю)
    very_active: 1.725,  // Высокая активность (6-7 раз в неделю)
    extra_active: 1.9    // Очень высокая активность (2 раза в день)
  };

  // Определяем множитель активности на основе тренировок в неделю
  let activityLevel = context.activity_level;
  if (context.weekly_workouts <= 1) activityLevel = 'sedentary';
  else if (context.weekly_workouts <= 3) activityLevel = 'light';
  else if (context.weekly_workouts <= 5) activityLevel = 'moderate';
  else if (context.weekly_workouts <= 7) activityLevel = 'very_active';
  else activityLevel = 'extra_active';

  const multiplier = activityMultipliers[activityLevel];
  const tdee = Math.round(bmr * multiplier);

  // Рассчитываем макронутриенты
  const proteinPerKg = context.fitness_level === 'beginner' ? 1.6 : 
                       context.fitness_level === 'intermediate' ? 1.8 : 2.0;
  
  const protein = Math.round(context.weight * proteinPerKg);
  const fat = Math.round((tdee * 0.25) / 9); // 25% калорий из жиров
  const carbs = Math.round((tdee - (protein * 4) - (fat * 9)) / 4); // оставшиеся калории из углеводов

  return {
    ...context,
    bmr: Math.round(bmr),
    tdee: tdee,
    calories_for_loss: tdee - 500,
    calories_for_gain: tdee + 500,
    protein_target: protein,
    fat_target: fat,
    carbs_target: carbs,
    activity_multiplier: multiplier,
    calculated_activity_level: activityLevel
  };
}

function detectUserIntent(message: string, context: ChatContext): {
  intent: string,
  confidence: number,
  entities: any
} {
  const lowerMessage = message.toLowerCase();
  
  // Анализируем сообщение и контекст
  const intents = [
    {
      type: 'profile_update',
      patterns: ['change', 'update', 'set', 'modify'],
      fields: ['weight', 'height', 'age', 'goals', 'level']
    },
    {
      type: 'workout_request',
      patterns: ['workout', 'exercise', 'training', 'routine', 'plan for', 'make me plan', 'create plan', 'give me a plan']
    },
    {
      type: 'nutrition_advice',
      patterns: ['eat', 'food', 'diet', 'nutrition', 'calories', 'meal plan']
    },
    {
      type: 'weight_loss_plan',
      patterns: ['lose weight', 'weight loss', 'get leaner', 'shed pounds', 'drop fat', 'slim down', 'burn fat', 'reduce body fat']
    },
    {
      type: 'muscle_gain_plan',
      patterns: ['gain muscle', 'build muscle', 'bulk up', 'get bigger', 'get stronger', 'gain mass', 'build mass']
    },
    {
      type: 'progress_tracking',
      patterns: ['progress', 'track', 'measure', 'improve']
    },
    {
      type: 'profile_info',
      patterns: ['my profile', 'profile data', 'my data', 'my info', 'my information', 'my stats', 
                'tell me about my profile', 'show my profile', 'what do you know about me', 
                'my height', 'my weight', 'my age', 'my fitness']
    }
  ];

  // Находим наиболее вероятное намерение
  let bestMatch = {
    intent: 'chat',
    confidence: 0,
    entities: {}
  };

  for (const intent of intents) {
    const matches = intent.patterns.filter(p => lowerMessage.includes(p));
    const confidence = matches.length > 0 ? matches.length / intent.patterns.length : 0;
    
    if (confidence > bestMatch.confidence) {
      bestMatch = {
        intent: intent.type,
        confidence,
        entities: extractEntities(message, intent)
      };
    }
  }

  // Специальная логика для фраз, которые комбинируют намерения
  if (lowerMessage.includes('plan') && lowerMessage.includes('according to my profile')) {
    if (lowerMessage.includes('lose weight') || lowerMessage.includes('weight loss')) {
      return {
        intent: 'weight_loss_plan',
        confidence: 0.9,
        entities: extractEntities(message, { type: 'weight_loss_plan' })
      };
    } else if (lowerMessage.includes('muscle') || lowerMessage.includes('strength')) {
      return {
        intent: 'muscle_gain_plan',
        confidence: 0.9,
        entities: extractEntities(message, { type: 'muscle_gain_plan' })
      };
    } else {
      return {
        intent: 'workout_request',
        confidence: 0.8,
        entities: {}
      };
    }
  }

  return bestMatch;
}

function extractEntities(message: string, intent: any): any {
  const entities: any = {};
  
  if (intent.fields) {
    for (const field of intent.fields) {
      const regex = new RegExp(`${field}[:\\s]+(\\d+|\\w+)`, 'i');
      const match = message.match(regex);
      if (match) {
        entities[field] = match[1];
      }
    }
  }
  
  return entities;
}

async function handleProfileUpdate(userId: string, message: string, currentProfile: any) {
  const updates = extractProfileUpdates(message);
  if (!updates) return null;

  try {
    const { data, error } = await supabaseClient
      .from('user_profiles')
      .update(updates)
      .eq('id', userId)
      .select()
      .single();

    if (error) throw error;
    return {
      success: true,
      changes: Object.keys(updates),
      newProfile: data
    };
  } catch (e) {
    console.error('Error updating profile:', e);
    return null;
  }
}

function extractProfileUpdates(message: string): any {
  const updates: any = {};
  const patterns = {
    weight: /(\d+(?:\.\d+)?)\s*(?:kg|pounds|lbs)/i,
    height: /(\d+(?:\.\d+)?)\s*(?:cm|meters|m)/i,
    age: /(\d+)\s*(?:years|year|yo|y\.o\.|years old)/i,
    goals: /(lose weight|gain muscle|get stronger|improve endurance|stay fit)/gi,
    fitness_level: /(beginner|intermediate|advanced)/i
  };

  for (const [field, pattern] of Object.entries(patterns)) {
    const match = message.match(pattern);
    if (match) {
      if (field === 'goals') {
        updates[field] = Array.from(message.matchAll(pattern)).map(m => m[1].toLowerCase());
      } else {
        updates[field] = match[1];
      }
    }
  }

  return Object.keys(updates).length > 0 ? updates : null;
}

// Функция определения языка сообщения
function detectLanguage(text: string): string {
  // Русские буквы
  const cyrillicPattern = /[а-яА-ЯёЁ]/g;
  // Китайские, японские и корейские символы
  const cjkPattern = /[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\uff66-\uff9f\u3131-\uD79D]/g;
  // Арабские символы
  const arabicPattern = /[\u0600-\u06FF]/g;
  
  const cyrillicMatches = text.match(cyrillicPattern);
  const cjkMatches = text.match(cjkPattern);
  const arabicMatches = text.match(arabicPattern);
  
  if (cyrillicMatches && cyrillicMatches.length > 3) {
    return 'ru';
  } else if (cjkMatches && cjkMatches.length > 3) {
    if (text.match(/[\u3040-\u309F\u30A0-\u30FF]/g)) {
      return 'ja';
    } else if (text.match(/[\u1100-\u11FF\uAC00-\uD7AF\u3130-\u318F]/g)) {
      return 'ko';
    }
    return 'zh';
  } else if (arabicMatches && arabicMatches.length > 3) {
    return 'ar';
  }
  
  return 'en'; // По умолчанию - английский
}

// Изменяем параметры запроса к Gemini API для более кратких ответов
async function generateContextAwareResponse(message: string, context: ChatContext): Promise<string> {
  try {
    // Создаем копию истории сообщений
    const messageHistory = [...context.messageHistory].slice(-MAX_HISTORY_LENGTH);
    
    // Определяем язык пользователя
    const detectedLanguage = detectLanguage(message);
    context.lastDetectedLanguage = detectedLanguage;
    
    // Создаем системный промпт на основе языка
    const systemPrompt = systemPrompts.default;

    // Формируем сообщения для API
    const messages = [
      { role: 'system', content: systemPrompt },
      ...messageHistory,
      { role: 'user', content: message }
    ];

    // Добавляем явную инструкцию быть кратким в последнем сообщении пользователя
    messages[messages.length - 1].content += "\n\n[IMPORTANT: Keep your response brief, friendly and under 250 words. Do NOT provide JSON or code blocks.]";

    // Преобразуем сообщения для Gemini API (убираем role: 'system')
    const transformedMessages = messages.map(msg => {
      // Если это системное сообщение, превращаем его в пользовательское с префиксом
      if (msg.role === 'system') {
        return {
          role: 'user', 
          content: `[Instructions for AI assistant]: ${msg.content}`
        };
      }
      return msg;
    });

    // Формируем запрос к API
    const requestBody = {
      contents: transformedMessages.map(msg => ({
        role: msg.role === 'user' ? 'user' : 'model',
        parts: [{ text: msg.content }]
      })),
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 500, // Ограничиваем количество токенов
        stopSequences: ["Remember:", "Note:", "Here are", "First,"]
      }
    };

    // Отправляем запрос к API
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${Deno.env.get('GEMINI_API_KEY')}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(requestBody)
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(`Gemini API error: ${JSON.stringify(errorData)}`);
    }

    const result = await response.json();
    const messageText = result.candidates?.[0]?.content?.parts?.[0]?.text || '';
    
    // Форматируем ответ и ограничиваем его длину
    const formattedResponse = formatAIResponse(messageText, context);
    
    return formattedResponse;
  } catch (error) {
    console.error('Error generating response:', error);
    return '⚠️ Sorry, there was an error processing your request. Please try again later.';
  }
}

async function generateWorkout(message: string, profile: any, context: ChatContext): Promise<string> {
  try {
    // Используем специальный промпт для генерации тренировки
    const systemPrompt = systemPrompts.workoutSuggestion;
    
    // Формируем сообщения
    const messages = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: message }
    ];

    // Преобразуем сообщения для Gemini API
    const transformedMessages = messages.map(msg => {
      if (msg.role === 'system') {
        return {
          role: 'user', 
          content: `[Instructions for AI workout generator]: ${msg.content}`
        };
      }
      return msg;
    });

    // Формируем запрос
    const requestBody = {
      contents: transformedMessages.map(msg => ({
        role: msg.role === 'user' ? 'user' : 'model',
        parts: [{ text: msg.content }]
      })),
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 1000,
        stopSequences: ["Remember:", "Note:", "Here are", "First,"]
      }
    };

    // Отправляем запрос
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${Deno.env.get('GEMINI_API_KEY')}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(requestBody)
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(`Gemini API error: ${JSON.stringify(errorData)}`);
    }

    const result = await response.json();
    const workoutText = result.candidates?.[0]?.content?.parts?.[0]?.text || '';
    
    // Извлекаем JSON из ответа
    const workoutData = extractWorkoutJson(workoutText);
    
    // Сохраняем тренировку в контекст
    if (workoutData) {
      context.savedWorkouts.push(workoutData);
      if (context.savedWorkouts.length > MAX_WORKOUTS_LENGTH) {
        context.savedWorkouts.shift();
      }
    }
    
    return workoutText;
  } catch (error) {
    console.error('Error generating workout:', error);
    return '⚠️ Sorry, there was an error generating your workout. Please try again later.';
  }
}

function generateNutritionAdvice(message: string, profile: any): string {
  if (!profile) {
    return "Please complete your profile setup to get personalized nutrition advice.";
  }

  const { tdee, calories_for_loss, calories_for_gain, protein_target, fat_target, carbs_target } = getProfileContext(profile);
  
  // Определяем язык сообщения
  const messageLanguage = detectLanguage(message);
  
  if (messageLanguage === 'ru') {
    if (message.toLowerCase().includes('похуд') || message.toLowerCase().includes('снизить вес')) {
      return `Ваши дневные цели: **${calories_for_loss}** ккал, **${protein_target}г** белка, **${fat_target}г** жира, **${carbs_target}г** углеводов. __Начните отслеживать в MyFitnessPal__.`;
    } else if (message.toLowerCase().includes('набрать') || message.toLowerCase().includes('масс')) {
      return `Ваши дневные цели: **${calories_for_gain}** ккал, **${protein_target}г** белка, **${fat_target}г** жира, **${carbs_target}г** углеводов. __Начните отслеживать в MyFitnessPal__.`;
    } else {
      return `Ваша поддерживающая калорийность: **${tdee}** ккал. Потребляйте **${protein_target}г** белка, **${fat_target}г** жира, **${carbs_target}г** углеводов. __Отслеживайте свои приемы пищи__.`;
    }
  }
  
  // Для других языков можно добавить подобным образом
  
  // Исходный код на английском
  if (message.toLowerCase().includes('lose weight')) {
    return `Your daily targets: **${calories_for_loss}** kcal, **${protein_target}g** protein, **${fat_target}g** fat, **${carbs_target}g** carbs. __Start tracking with MyFitnessPal__.`;
  } else if (message.toLowerCase().includes('gain')) {
    return `Your daily targets: **${calories_for_gain}** kcal, **${protein_target}g** protein, **${fat_target}g** fat, **${carbs_target}g** carbs. __Start tracking with MyFitnessPal__.`;
  } else {
    return `Your maintenance calories: **${tdee}** kcal. Eat **${protein_target}g** protein, **${fat_target}g** fat, **${carbs_target}g** carbs. __Track your meals__.`;
  }
}

function formatProfileUpdateResponse(update: any): string {
  if (!update) {
    return "I couldn't update your profile. Please try again with specific values (e.g., 'weight: 75kg').";
  }

  const changes = update.changes.join(', ');
  
  // Возвращаем ответ в зависимости от языка последнего сообщения
  const lastMessageLanguage = chatContext.messageHistory.length > 0 
    ? detectLanguage(chatContext.messageHistory[chatContext.messageHistory.length - 1].content)
    : 'en';
    
  if (lastMessageLanguage === 'ru') {
    return `✨ Обновлены ваши **${changes}**! __Ваш профиль теперь актуален__.`;
  }
  
  // Для других языков можно добавить подобные ответы
  
  return `✨ Updated your **${changes}**! __Your profile is now current__.`;
}

function updateChatContext(context: ChatContext, userMessage: string, aiResponse: string, intent: any): void {
  // Update message history
  if (context.messageHistory.length >= MAX_HISTORY_LENGTH) {
    context.messageHistory.shift();
  }
  
  context.messageHistory.push(
    { role: 'user', content: userMessage },
    { role: 'assistant', content: aiResponse }
  );

  // Update current goal if detected
  if (userMessage.toLowerCase().includes('goal')) {
    const goalMatch = userMessage.match(/goal(?:s)?:?\s*(.+)/i);
    if (goalMatch) {
      context.currentGoal = goalMatch[1].trim();
    }
  }
}

function formatSystemMessage(type: string, message: string): string {
  let emoji;
    
  switch (type) {
    case 'success':
      emoji = messageEmojis.success[Math.floor(Math.random() * messageEmojis.success.length)];
      return `${emoji} **Success**: ${message}`;
      
    case 'error':
      emoji = messageEmojis.error[Math.floor(Math.random() * messageEmojis.error.length)];
      return `${emoji} **Error**: ${message}`;
      
    case 'system':
      emoji = messageEmojis.system[Math.floor(Math.random() * messageEmojis.system.length)];
      return `${emoji} **System**: ${message}`;
      
    default:
      return message;
  }
}

// Функция для обогащения сообщения на основе намерения
function enhanceMessageBasedOnIntent(message: string, intent: string, userProfile: any): string {
  // Сначала проверяем, содержит ли сообщение противоречивые намерения
  if ((message.toLowerCase().includes('lose') && message.toLowerCase().includes('gain')) ||
      (message.toLowerCase().includes('похуд') && (message.toLowerCase().includes('набр') || message.toLowerCase().includes('масс')))) {
    return `[TASK: Ask clarifying question about contradictory goals]
USER PROFILE:
- Height: ${userProfile?.height || '?'} cm
- Weight: ${userProfile?.weight || '?'} kg
- Gender: ${userProfile?.gender || '?'}
- Age: ${userProfile?.age || '?'}

INSTRUCTIONS:
1. The user requested contradictory goals (lose AND gain weight)
2. DIRECTLY ASK the user which goal they actually want to achieve
3. Format as a DIRECT QUESTION, not as advice
4. Keep it very friendly and casual
5. Offer exactly TWO clear options (lose weight OR gain weight)
6. Use only 1-2 sentences maximum
7. Use appropriate emoji
8. DO NOT provide any advice yet - just ask for clarification
9. Make clear you're waiting for their choice

USER MESSAGE: ${message}`;
  }

  // Далее проверяем, не содержит ли сообщение конкретно про сон и питание
  if (message.toLowerCase().includes('sleep') && 
      (message.toLowerCase().includes('food') || 
       message.toLowerCase().includes('nutrition') || 
       message.toLowerCase().includes('diet') || 
       message.toLowerCase().includes('meal') || 
       message.toLowerCase().includes('eat'))) {
    return `[TASK: Provide personalized sleep and nutrition advice]
USER PROFILE:
- Height: ${userProfile?.height || '?'} cm
- Weight: ${userProfile?.weight || '?'} kg
- Gender: ${userProfile?.gender || '?'}
- Age: ${userProfile?.age || '?'}
- Fitness Level: ${userProfile?.fitness_level || 'Beginner'}
- Goals: ${userProfile?.goals?.join(', ') || 'General fitness'}

INSTRUCTIONS:
1. Give specific, actionable advice on BOTH sleep and nutrition
2. Split your response into TWO clear sections: Sleep and Nutrition
3. For sleep: Include optimal hours, routine tips, and quality improvement
4. For nutrition: Include specific macros, meal timing, and 2-3 food examples
5. Keep response under 250 words but make it DETAILED and SPECIFIC
6. Be friendly and supportive
7. Use appropriate emojis to organize information
8. Answer "I want to lose weight" if their message is unclear about goals

USER MESSAGE: ${message}`;
  }
  
  // Проверяем запросы на похудение/набор веса
  if ((message.toLowerCase().includes('lose weight') || message.toLowerCase().includes('weight loss')) && 
      (message.toLowerCase().includes('plan') || message.toLowerCase().includes('make me'))) {
    return `[TASK: Provide practical weight loss plan]
USER PROFILE:
- Height: ${userProfile?.height || '?'} cm
- Weight: ${userProfile?.weight || '?'} kg
- Gender: ${userProfile?.gender || '?'}
- Age: ${userProfile?.age || '?'}
- Fitness Level: ${userProfile?.fitness_level || 'Beginner'}

INSTRUCTIONS:
1. Create a PRACTICAL daily plan with specific time-based recommendations
2. Include precise calorie target and macros based on their stats
3. Suggest 3 specific meals with actual portions (breakfast, lunch, dinner)
4. Add 1-2 snack ideas with timing
5. Include hydration guidelines with specific amounts
6. Keep response under 250 words but make it DETAILED and SPECIFIC
7. Use emojis to organize information clearly
8. Be friendly and encouraging

USER MESSAGE: ${message}`;
  }
  
  if ((message.toLowerCase().includes('gain weight') || message.toLowerCase().includes('weight gain') || 
       message.toLowerCase().includes('bulk')) && 
      (message.toLowerCase().includes('plan') || message.toLowerCase().includes('make me'))) {
    return `[TASK: Provide practical weight gain plan]
USER PROFILE:
- Height: ${userProfile?.height || '?'} cm
- Weight: ${userProfile?.weight || '?'} kg
- Gender: ${userProfile?.gender || '?'}
- Age: ${userProfile?.age || '?'}
- Fitness Level: ${userProfile?.fitness_level || 'Beginner'}

INSTRUCTIONS:
1. Create a PRACTICAL daily plan with specific time-based recommendations
2. Include precise calorie surplus target and macros based on their stats
3. Suggest 3 specific calorie-dense meals with actual portions
4. Add 2-3 high-calorie snack ideas with timing
5. Include protein timing guidelines
6. Keep response under 250 words but make it DETAILED and SPECIFIC
7. Use emojis to organize information clearly
8. Be friendly and encouraging

USER MESSAGE: ${message}`;
  }

  // Далее идут стандартные интенты
  switch (intent) {
    case 'weight_loss_plan':
      return `[TASK: Provide practical weight loss advice]
USER PROFILE:
- Height: ${userProfile?.height || '?'} cm
- Weight: ${userProfile?.weight || '?'} kg
- Gender: ${userProfile?.gender || '?'}
- Age: ${userProfile?.age || '?'}
- Fitness Level: ${userProfile?.fitness_level || 'Beginner'}

INSTRUCTIONS:
1. Give 5 specific, actionable weight loss tips
2. Include one daily meal example with exact portions
3. Include exact calorie target based on their stats
4. Include protein, fat and carb targets in grams
5. Keep response under 250 words but make it SPECIFIC
6. Use simple language with specific numbers and measures
7. Use emojis to organize information clearly

USER MESSAGE: ${message}`;
      
    case 'muscle_gain_plan':
      return `[TASK: Provide practical muscle gain advice]
USER PROFILE:
- Height: ${userProfile?.height || '?'} cm
- Weight: ${userProfile?.weight || '?'} kg
- Gender: ${userProfile?.gender || '?'}
- Age: ${userProfile?.age || '?'}
- Fitness Level: ${userProfile?.fitness_level || 'Beginner'}

INSTRUCTIONS:
1. Give 5 specific, actionable muscle gain tips
2. Include one daily meal example with exact portions
3. Include exact calorie surplus target based on their stats
4. Include protein, fat and carb targets in grams
5. Keep response under 250 words but make it SPECIFIC
6. Use simple language with specific numbers and measures
7. Use emojis to organize information clearly

USER MESSAGE: ${message}`;
      
    case 'general_workout_plan':
      return `[TASK: Provide specific fitness advice]
USER PROFILE:
- Height: ${userProfile?.height || '?'} cm
- Weight: ${userProfile?.weight || '?'} kg
- Gender: ${userProfile?.gender || '?'}
- Age: ${userProfile?.age || '?'}
- Fitness Level: ${userProfile?.fitness_level || 'Beginner'}

INSTRUCTIONS:
1. Give 5 specific, actionable fitness tips
2. Keep your response brief but SPECIFIC
3. Include one practical tip they can implement TODAY
4. Keep response under 250 words
5. Use simple language with specific examples
6. Use emojis to organize information clearly

USER MESSAGE: ${message}`;

    case 'nutrition_advice':
      return `[TASK: Provide specific nutrition advice]
USER PROFILE:
- Height: ${userProfile?.height || '?'} cm
- Weight: ${userProfile?.weight || '?'} kg
- Gender: ${userProfile?.gender || '?'}
- Age: ${userProfile?.age || '?'}
- Goals: ${userProfile?.goals?.join(', ') || 'General fitness'}

INSTRUCTIONS:
1. Give specific nutrition advice with EXACT numbers (calories, macros)
2. Include one daily meal plan example with SPECIFIC foods and portions
3. Include meal timing recommendations
4. Keep response under 250 words but make it DETAILED
5. Use simple language with specific measures
6. Use emojis to organize information clearly

USER MESSAGE: ${message}`;

    case 'recovery_advice':
      return `[TASK: Provide specific recovery advice]
USER PROFILE:
- Height: ${userProfile?.height || '?'} cm
- Weight: ${userProfile?.weight || '?'} kg
- Gender: ${userProfile?.gender || '?'}
- Age: ${userProfile?.age || '?'}
- Fitness Level: ${userProfile?.fitness_level || 'Beginner'}

INSTRUCTIONS:
1. Give 5 specific recovery tips with EXACT recommendations
2. Include specific sleep guidelines (hours, timing)
3. Include one practical stretching or mobility exercise
4. Keep response under 250 words but make it DETAILED
5. Use simple language with specific examples
6. Use emojis to organize information clearly

USER MESSAGE: ${message}`;
      
    default:
      // Удаляем дублирующую проверку, так как она перенесена в начало функции
      return `${message} [INSTRUCTIONS: Keep your response brief, friendly and conversational. Include SPECIFIC numbers and recommendations when possible. Keep total response under 250 words. Use emoji where appropriate.]`;
  }
}

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { message, action = 'chat', chatId = 'default' } = await req.json();
    const messageLanguage = detectLanguage(message);
    
    // Получаем авторизационный заголовок
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('No authorization header');
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);
    
    if (userError || !user) {
      throw new Error('Invalid token');
    }

    const userId = user.id;
    
    // Загружаем историю сообщений из базы данных
    const { data: messagesData, error: messagesError } = await supabaseClient
      .from('chat_messages')
      .select('*')
      .eq('user_id', userId)
      .eq('chat_id', chatId)
      .order('created_at', { ascending: true })
      .limit(MAX_HISTORY_LENGTH * 2); // Загружаем больше сообщений, чтобы учесть диалоги

    if (!messagesError && messagesData && messagesData.length > 0) {
      // Преобразуем сообщения в формат для контекста
      chatContext.messageHistory = messagesData.map(msg => ({
        role: msg.is_user ? 'user' : 'assistant',
        content: msg.content
      }));
      
      // Ограничиваем размер истории
      if (chatContext.messageHistory.length > MAX_HISTORY_LENGTH) {
        chatContext.messageHistory = chatContext.messageHistory.slice(-MAX_HISTORY_LENGTH);
      }
    } else {
      // Если нет истории или ошибка, начинаем с пустой истории
      chatContext.messageHistory = [];
    }
    
    // Загружаем профиль пользователя
    let userProfile = await getUserProfile(userId);
    chatContext.userProfile = userProfile;
    
    // Определяем намерение пользователя с помощью AI
    const userIntent = await classifyIntentWithAI(message, userProfile);
    console.log(`Detected intent with AI: ${userIntent}`);
    
    // Обрабатываем намерение
    let response;
    switch (userIntent) {
      case 'profile_update':
        const update = await handleProfileUpdate(userId, message, userProfile);
        response = formatProfileUpdateResponse(update);
        break;
        
      case 'profile_info':
        if (!userProfile) {
          response = "I couldn't find your profile. Please complete your profile information.";
        } else {
          const formattedProfile = formatProfileData(userProfile);
          response = formattedProfile;
        }
        break;
      
      case 'weight_loss_plan':
      case 'muscle_gain_plan':
      case 'general_workout_plan':
        if (!userProfile) {
          userProfile = await getUserProfile(userId);
        }
        
        // Обогащаем сообщение контекстом на основе намерения
        const enhancedMessage = enhanceMessageBasedOnIntent(message, userIntent, userProfile);
        
        response = userProfile ? 
          await generateWorkout(enhancedMessage, userProfile, chatContext) : 
          await generateContextAwareResponse(enhancedMessage, chatContext);
        break;
      
      case 'nutrition_advice':
        const nutritionMessage = enhanceMessageBasedOnIntent(message, 'nutrition_advice', userProfile);
        response = await generateContextAwareResponse(nutritionMessage, chatContext);
        break;
      
      case 'recovery_advice':
        const recoveryMessage = enhanceMessageBasedOnIntent(message, 'recovery_advice', userProfile);
        response = await generateContextAwareResponse(recoveryMessage, chatContext);
        break;
      
      default:
        response = await generateContextAwareResponse(message, chatContext);
    }

    // Форматируем ответ, добавляем информацию о языке в контекст
    chatContext.lastDetectedLanguage = messageLanguage;
    response = formatAIResponse(response, chatContext);

    // Обновляем контекст
    updateChatContext(chatContext, message, response, { intent: userIntent, confidence: 0.9 });
    
    return new Response(
      JSON.stringify({
        message: response, 
        context: chatContext,
        intent: userIntent,
        detectedLanguage: messageLanguage
      }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );

  } catch (error) {
    console.error('Error:', error);
    
    // Используем английское сообщение об ошибке независимо от языка пользователя
    let errorMessage = error.message;
    if (error.message.includes('Profile not found')) {
      errorMessage = 'Profile not found. Please complete your profile setup.';
    } else if (error.message.includes('Invalid token')) {
      errorMessage = 'Invalid token. Please log in again.';
    } else if (error.message.includes('No authorization header')) {
      errorMessage = 'Missing authorization header.';
    } else {
      errorMessage = 'An error occurred: ' + error.message;
    }
    
    // Определяем язык только для логирования
    let errorLanguage = 'en';
    if (chatContext && chatContext.messageHistory && chatContext.messageHistory.length > 0) {
      const lastMessage = chatContext.messageHistory[chatContext.messageHistory.length - 1];
      if (lastMessage && lastMessage.content) {
        errorLanguage = detectLanguage(lastMessage.content);
      }
    }
    
    return new Response(
      JSON.stringify({ error: errorMessage, detectedLanguage: errorLanguage }),
      { status: 500, headers: { ...corsHeaders } }
    );
  }
});

function extractWorkoutJson(content: string): any {
  try {
    const jsonStart = content.indexOf('{');
    const jsonEnd = content.lastIndexOf('}');
    
    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      const jsonStr = content.substring(jsonStart, jsonEnd + 1);
      const json = JSON.parse(jsonStr);
      
      // Validate required fields
      if (!json || !json.name || !json.exercises || !Array.isArray(json.exercises)) {
        console.error('Invalid workout JSON structure:', json);
        return null;
      }

      // Ensure exercises have required fields
      for (const exercise of json.exercises) {
        if (!exercise.name || !exercise.targetMuscleGroup) {
          console.error('Invalid exercise structure:', exercise);
          return null;
        }
        // Set default time values if not provided
        exercise.timePerSet = exercise.timePerSet || 45;
      }

      // Ensure targetMuscles is an array
      if (!Array.isArray(json.targetMuscles)) {
        json.targetMuscles = [];
      }

      // Add target muscles from exercises if not specified
      const exerciseMuscles = new Set(json.exercises.map(e => e.targetMuscleGroup));
      json.targetMuscles = Array.from(new Set([...json.targetMuscles, ...exerciseMuscles]));

      // Set default time values
      json.timePerExercise = json.timePerExercise || 180;
      json.restBetweenSets = json.restBetweenSets || 60;
      json.restBetweenExercises = json.restBetweenExercises || 90;
      
      // Calculate total time if not provided
      if (!json.totalTime) {
        const exerciseTime = json.exercises.reduce((total, ex) => {
          const sets = parseInt(ex.sets) || 3;
          return total + (sets * (ex.timePerSet + json.restBetweenSets));
        }, 0);
        const transitionTime = (json.exercises.length - 1) * json.restBetweenExercises;
        json.totalTime = Math.round((exerciseTime + transitionTime) / 60); // Convert to minutes
      }

      return json;
    }
  } catch (e) {
    console.error('Error extracting workout JSON:', e);
  }
  return null;
}

// Добавляем новую функцию для форматирования данных профиля
function formatProfileData(userProfile: any, language: string = 'en'): string {
  if (userProfile) {
    const height = userProfile.height ? `**${userProfile.height}** cm` : 'Not set';
    const weight = userProfile.weight ? `**${userProfile.weight}** kg` : 'Not set';
    const age = userProfile.age ? `**${userProfile.age}**` : 'Not set';
    const gender = userProfile.gender || 'Not set';
    const fitnessLevel = userProfile.fitness_level || 'Not set';
    const goals = userProfile.goals?.join(', ') || 'Not set';
    
    // Всегда возвращаем на английском
    return `👤 **Your Profile Data:**\n\n` +
      `**Height:** ${height}\n` +
      `**Weight:** ${weight}\n` +
      `**Age:** ${age}\n` +
      `**Gender:** ${gender}\n` +
      `**Fitness Level:** ${fitnessLevel}\n` +
      `**Goals:** ${goals}\n\n` +
      `You can update this information anytime by just telling me.`;
  }
  return "Profile data not available. Please complete your profile setup.";
}