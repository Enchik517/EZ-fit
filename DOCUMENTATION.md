# Fitness App Documentation

[... existing content ...]

## AI Chat System

### System Architecture

#### Edge Function Setup (Supabase)
```typescript
// index.ts
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const { message } = await req.json()
    const apiKey = Deno.env.get('GROQ_API_KEY')

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "mixtral-8x7b-32768",
        messages: [
          {
            role: "system",
            content: "You are an AI fitness coach focused ONLY on workout and exercise advice."
          },
          {
            role: "user",
            content: message
          }
        ],
        temperature: 0.7,
        max_tokens: 1000,
      }),
    })
  }
})
```

### Available Tools

```typescript
const tools = {
  create_workout: {
    name: 'create_workout',
    description: 'Create a new workout based on parameters',
    parameters: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        focus: { type: 'string' },
        difficulty: { type: 'string' },
        duration: { type: 'integer' },
        equipment: {
          type: 'array',
          items: { type: 'string' }
        }
      },
      required: ['name', 'focus', 'difficulty', 'duration']
    }
  },
  modify_workout: {
    name: 'modify_workout',
    description: 'Modify existing workout',
    parameters: {
      type: 'object',
      properties: {
        workout: { type: 'object' },
        newDifficulty: { type: 'string' },
        addExercises: {
          type: 'array',
          items: { type: 'string' }
        },
        removeExercises: {
          type: 'array',
          items: { type: 'string' }
        }
      },
      required: ['workout']
    }
  },
  get_user_profile: {
    name: 'get_user_profile',
    description: 'Get user profile data',
    parameters: {
      type: 'object',
      properties: {}
    }
  }
}
```

### Chat Prompts

#### System Prompt
```
You are an AI fitness coach focused ONLY on workout and exercise advice. Your responses should be:
1. Professional but friendly
2. Safety-focused
3. Based on user's fitness level and goals
4. Considerate of any injuries or limitations
5. Backed by exercise science

Available tools:
- create_workout: Generate personalized workout plans
- modify_workout: Adjust existing workouts
- get_user_profile: Access user's fitness data
```

#### Workout Feedback Prompt
```
Context:
- User's Fitness Level: ${surveyData.fitnessLevel}
- Goals: ${surveyData.selectedGoals?.join(', ')}
${surveyData.injuries?.isNotEmpty ? '- Injuries/Limitations: ${surveyData.injuries?.join(", ")}' : ''}

Please analyze this workout:
Name: ${log.workoutName}
Exercises: ${log.exercises.map((e) => '${e.exercise.name} (${e.exercise.sets} sets x ${e.exercise.reps} reps)').join(', ')}
Duration: ${log.duration.inMinutes} minutes

Provide personalized feedback on:
1. Exercise selection and balance considering user's goals and limitations
2. Volume and intensity relative to fitness level
3. Suggestions for improvement and progression
4. Safety considerations based on any injuries/limitations
```

#### Weekly Schedule Generation
```
User Profile:
- Weekly Workouts: ${surveyData.weeklyWorkouts} times
- Preferred Duration: ${surveyData.workoutDuration} minutes
- Fitness Level: ${surveyData.fitnessLevel}
${surveyData.injuries?.isNotEmpty ? '- Injuries/Limitations: ${surveyData.injuries?.join(", ")}' : ''}

Please create a weekly schedule for these workouts:
${workouts.map((w) => '- ${w.name} (${w.focus})').join('\n')}

Consider:
1. Rest days between similar muscle groups
2. User's preferred workout frequency
3. Progressive overload
4. Recovery time
5. Any injuries/limitations

Format response as:
Monday: [Workout Name] or Rest
Tuesday: [Workout Name] or Rest
...
Sunday: [Workout Name] or Rest
```

#### Profile Update Analysis
```
Please analyze this profile update request and specify:
1. What aspects need to be updated
2. New values/information
3. Reason for update (if provided)

Request: ${text}

Based on the analysis, provide:
1. Updated profile recommendations
2. Adjustments to workout plans
3. Safety considerations for new conditions
4. Progress tracking suggestions
```

### AI Response Processing

#### Workout Plan Parsing
```dart
AIWorkoutPlan _parseWorkoutPlan(String planText) {
  final sections = planText.split('\n\n');
  String name = 'Custom Workout Plan';
  String description = '';
  String difficulty = 'Intermediate';
  String category = 'Full Body';
  List<String> tips = [];
  String instructions = '';
  String? notes;

  for (var section in sections) {
    if (section.startsWith('Name:')) {
      name = section.replaceAll('Name:', '').trim();
    } else if (section.startsWith('Description:')) {
      description = section.replaceAll('Description:', '').trim();
    }
    // ... additional parsing
  }

  return AIWorkoutPlan(
    name: name,
    description: description,
    difficulty: difficulty,
    category: category,
    days: [
      AIWorkoutDay(
        name: 'Day 1',
        exercises: exercises,
      )
    ],
    exerciseTime: const Duration(minutes: 45),
    restBetweenSets: const Duration(seconds: 60),
    restBetweenExercises: const Duration(seconds: 90),
    totalDuration: const Duration(minutes: 45),
    instructions: instructions,
    tips: tips,
    notes: notes,
  );
}
```

#### Schedule Parsing
```dart
Map<String, String> _parseScheduleResponse(String response) {
  final Map<String, String> schedule = {};
  final lines = response.split('\n');
  
  for (var line in lines) {
    if (line.contains(':')) {
      final parts = line.split(':');
      final day = parts[0].trim();
      final workoutName = parts[1].trim();
      schedule[day] = workoutName;
    }
  }
  
  return schedule;
}
```

### AI Error Handling

#### Retry Logic
```dart
Future<String> sendMessage(String message) async {
  int retries = 3;
  while (retries > 0) {
    try {
      final response = await _supabase.functions.invoke(
        'chat',
        body: {
          'message': message,
          'functions': _functions.values.toList(),
        },
      );

      if (response.status != 200) {
        throw Exception('Error: ${response.data['error']}');
      }

      return response.data['response'] as String;
    } catch (e) {
      retries--;
      if (retries == 0) rethrow;
      await Future.delayed(Duration(seconds: 2));
    }
  }
  throw Exception('Failed after multiple retries');
}
```

#### Fallback Responses
```dart
String _getFallbackResponse(String messageType) {
  switch (messageType) {
    case 'workout':
      return 'I apologize, but I'm unable to generate a workout plan right now. Here are some general recommendations based on your profile...';
    case 'equipment':
      return 'I'm having trouble analyzing the equipment image. Here are some safety tips for gym equipment in general...';
    default:
      return 'I apologize, but I'm experiencing technical difficulties. Please try again in a few moments.';
  }
}
```

### AI Integration Points

1. **Chat Interface**
   - Direct user-AI interaction
   - Natural language processing
   - Context awareness

2. **Workout Generation**
   - Custom plan creation
   - Exercise selection
   - Safety checks

3. **Equipment Recognition**
   - Image analysis
   - Usage recommendations
   - Safety guidelines

4. **Health Monitoring**
   - Injury tracking
   - Recovery progress
   - Workout adjustments

5. **Progress Analysis**
   - Performance tracking
   - Goal adjustment
   - Feedback generation