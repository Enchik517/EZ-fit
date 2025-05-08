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

Этот промпт используется для обновления целей пользователя. Он проверяет безопасность и реалистичность новых целей.

Пример ответа:
```
💪 Updated your **goals**:
- Previous: weight loss, general fitness
- New: muscle gain, strength improvement
__Adjusting your training plan__ to match your updated goals.
``` 