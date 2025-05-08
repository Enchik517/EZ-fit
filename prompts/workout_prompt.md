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

Этот промпт используется для создания персонализированных тренировок. Он учитывает профиль пользователя и автоматически адаптируется под его текущее состояние.

Пример ответа:
```json
💪 Your **Full Body** workout is ready:
{
  "name": "Dynamic Strength Builder",
  "description": "Full body workout focusing on compound movements",
  "exercises": [
    {
      "name": "Push-ups",
      "sets": "3",
      "reps": "12",
      "targetMuscleGroup": "chest",
      "equipment": "none",
      "notes": "Keep core tight, elbows at 45°"
    }
  ],
  "difficulty": "intermediate",
  "equipment": ["none"],
  "targetMuscles": ["chest", "shoulders", "core"],
  "focus": "strength",
  "duration": 45,
  "autoAdjust": {
    "intensity": "auto-adjusts based on your performance",
    "progression": "automatically increases difficulty as you improve",
    "recovery": "modifies based on your recovery status"
  }
}
``` 