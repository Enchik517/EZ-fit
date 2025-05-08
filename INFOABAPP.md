# Fitness App Documentation

## Table of Contents
1. [Models](#models)
2. [Services](#services)
3. [Database Schema](#database-schema)
4. [Providers](#providers)
5. [Screens](#screens)
6. [Application Logic](#application-logic)
7. [AI Integration](#ai-integration)

## Models

### UserProfile
```dart
class UserProfile {
  final String id;
  final String fullName;
  final DateTime? birthDate;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String fitnessLevel;
  final String weeklyWorkouts;
  final String workoutDuration;
  final List<String> goals;
  final List<String> equipment;
  final List<String>? injuries;
  final bool hasCompletedSurvey;
}
```

### ChatMessage
```dart
class ChatMessage {
  final String id;
  final String userId;
  final String? text;
  final String? imageUrl;
  final bool isUser;
  final DateTime createdAt;
  final String chatId;
}
```

### AIWorkoutPlan
```dart
class AIWorkoutPlan {
  final String name;
  final String description;
  final String difficulty;
  final String category;
  final List<AIWorkoutDay> days;
  final Duration exerciseTime;
  final Duration restBetweenSets;
  final Duration restBetweenExercises;
  final Duration totalDuration;
  final String instructions;
  final List<String> tips;
  final String? notes;
}
```

## Services

### AuthService
- Handles authentication flow
- Supports Google/Apple sign-in
- Manages user profile

### ChatService
- Interacts with Groq AI API
- Manages chat messages and history
- Generates workout plans
- Handles image recognition requests

### EquipmentRecognitionService
- Recognizes gym equipment from photos
- Provides equipment usage recommendations
- Integrates with Groq AI for analysis

## Database Schema (Supabase)

### Tables

#### workouts
```sql
CREATE TABLE public.workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    name TEXT NOT NULL,
    description TEXT,
    difficulty TEXT,
    category TEXT,
    focus TEXT,
    duration INTEGER,
    exercises JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### user_profiles
```sql
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    full_name TEXT,
    birth_date TIMESTAMPTZ,
    age INTEGER,
    gender TEXT,
    height DECIMAL,
    weight DECIMAL,
    fitness_level TEXT,
    weekly_workouts INTEGER,
    workout_duration INTEGER,
    goals TEXT[],
    equipment TEXT[],
    injuries TEXT[],
    has_completed_survey BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Providers

### AuthProvider
- Manages authentication state
- Handles user profile loading/saving
- Tracks onboarding completion

### ChatProvider
- Manages chat state
- Processes messages
- Handles workout generation
- Processes equipment photos

## Screens

### AuthScreen
- Google/Apple sign-in
- Email/password authentication
- Registration flow

### BasicsScreen
- Basic user information input
- Gender selection
- Age/height/weight input

### ChatScreen
- AI chat interface
- Equipment photo upload
- Chat history management
- Separate chat threads

## Application Logic

### Registration Flow
```
1. AuthScreen
2. BasicsScreen (User info)
3. AppInfoScreen (Additional info)
4. MainNavigationScreen
```

### Workout Creation Flow
```
1. User describes desired workout
2. ChatService generates plan via AI
3. Plan is saved to database
4. Plan appears in workouts section
```

### Equipment Recognition Flow
```
1. User takes equipment photo
2. Photo is analyzed by AI
3. AI provides usage recommendations
4. Info is saved in chat history
```

## AI Integration

### Chat Function Definitions
```typescript
const functions = {
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

### AI Prompts

#### Equipment Recognition Prompt
```
Analyze this gym equipment image and provide:
1. Equipment name and type
2. Main exercises that can be performed
3. Tips for proper form and safety
4. Target muscle groups
5. Difficulty level (beginner/intermediate/advanced)

Format the response as JSON with the following structure:
{
  "equipment": {
    "name": "equipment name",
    "type": "equipment type",
    "confidence": 0.95
  },
  "recommendations": {
    "exercises": ["exercise1", "exercise2"],
    "tips": ["tip1", "tip2"],
    "muscles": ["muscle1", "muscle2"],
    "difficulty": "difficulty level"
  }
}
```

#### Workout Generation Prompt
```
Based on user profile:
- Fitness Level: ${profile.fitnessLevel}
- Goals: ${profile.goals.join(', ')}
- Equipment: ${profile.equipment.join(', ')}
${profile.injuries ? `- Injuries: ${profile.injuries.join(', ')}` : ''}

Create a workout plan that:
1. Matches user's fitness level
2. Targets specified goals
3. Uses available equipment
4. Considers any injuries/limitations
5. Includes proper warm-up and cool-down

Format response as:
Name: [Workout Name]
Description: [Brief description]
Difficulty: [Level]
Category: [Type]
Exercises:
- [Exercise 1]: [Sets] x [Reps]
  Instructions: [Details]
  Common mistakes: [List]
  Modifications: [Options]
Tips: [Safety and form tips]
Notes: [Additional information]
```

#### Health Issue Analysis Prompt
```
Please analyze this health-related message and extract:
1. Type of issue (injury/condition)
2. Affected body part/area
3. Severity (if mentioned)
4. Recommended exercise modifications
5. Activities to avoid

Based on the analysis, provide:
1. Exercise modifications
2. Recovery recommendations
3. Warning signs to watch for
4. When to consult healthcare provider
5. Safe alternative exercises
```

#### Recovery Analysis Prompt
```
Please analyze this recovery message and confirm:
1. Which condition has improved
2. Whether it's a full or partial recovery
3. Any remaining limitations

Provide:
1. Congratulatory message
2. Gradual return to activity recommendations
3. Prevention tips
4. Signs to watch for during return to exercise
```

## Security Considerations

### Data Protection
- All sensitive data is stored in Supabase with RLS policies
- Authentication tokens are securely managed
- API keys are stored in environment variables

### Privacy
- User data is only accessible to the user
- Workout data is private by default
- Chat history is encrypted and user-specific

## Error Handling

### Common Error Scenarios
1. Authentication failures
2. Network connectivity issues
3. AI service unavailability
4. Invalid input data

### Error Recovery
1. Automatic retry for transient failures
2. Graceful degradation for AI features
3. Offline support for basic functionality
4. Data validation at all levels 