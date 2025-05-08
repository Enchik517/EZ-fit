
---

# Product Requirements Document (PRD)

## 1. Introduction

### 1.1 Purpose

The purpose of the **FitBod** application is to provide users with an AI-driven strength training experience—one that adapts workouts to individual fitness levels and goals. By leveraging DeepSeek-R1 for personalized plans, real-time exercise guidance, and an AI “personal trainer,” FitBod aims to become a user’s best coach. Through intuitive coaching, customized workouts, and the ability to ask the AI about specific exercises or gym machines, FitBod helps users train smarter and achieve better results.

### 1.2 Scope

1. **AI-Optimized Training Plans**: Users receive adaptive workout routines tailored to their goals, experience, and available equipment.  
2. **Camera-Based Exercise Guidance**: Users can snap photos of unfamiliar gym machines or equipment. The AI then identifies the equipment and explains proper usage and exercise form.  
3. **Conversation with an AI Trainer**: Users can chat with the AI to clarify questions, modify their routines, and get advanced tips—anytime.  
4. **Tracking & Adaptation**: As users log workouts and interact with AI, the system learns and adapts, ensuring a continuously evolving workout program.  

### 1.3 Target Audience

Everyone interested in strength training—from beginners learning proper form to experienced athletes seeking to optimize their workouts. The app’s AI-driven approach makes high-quality coaching accessible to all skill levels.

### 1.4 Goals

1. **Effective Fitness Coaching**: Enable users to train effectively, learn correct form, and progress safely.  
2. **Revenue Generation**: Premium features (such as enhanced workout plans, personalized progress tracking, premium AI interactions) and free subscription options will be offered.  
---

## 2. User Stories

1. **AI-Optimized Workouts**  
   *As a user, I want an AI to generate strength training plans for me based on my current fitness level, so I can improve efficiently.*

2. **Camera-Based Guidance**  
   *As a user, I want to take a picture of a gym machine or equipment so I can learn how to use it properly and incorporate it into my workout.*

3. **Chat with a Personal Trainer (AI)**  
   *As a user, I want to chat with an AI personal trainer to ask questions, get form checks, and adapt my routine as I progress.*

4. **Progress Tracking & Adaptation**  
   *As a user, I want the app to track my sets, reps, and performance over time, so the AI can adjust my workout plan to keep me challenged.*

5. **Premium Features & Monetization**  
   *As a user, I want to unlock advanced coaching insights and remove ads, so I can have a more seamless and personalized experience.*  

---

## 3. Core Technologies

FitBod will use:

1. **Flutter**: For building a cross-platform app (Android, iOS, potentially web/desktop).  
2. **Supabase**: For backend services like authentication, database storage, and user data management.  
3. **DeepSeek-R1 API**: For the AI/ML functionality—camera-based recognition of gym machines, workout planning, and chat interactions.  
4. **Apple Sign-In & In-App Purchases** (or alternative sign-in/purchase flows for non-Apple platforms).  

Below are relevant documentation links and code snippets, mirroring the example structure.

### 3.1 Flutter

**Description**: Flutter is a UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.  
**Documentation**: [Flutter Docs](https://docs.flutter.dev/)


---

### 3.2 Supabase

**Description**: Supabase provides an open-source Postgres database, real-time subscriptions, and user authentication.  
**Documentation**: [Supabase Docs](https://supabase.com/docs)


---

### 3.3 Apple Sign-In

**Description**: Allows secure and private login using an Apple ID.  
**Documentation**: [Sign in with Apple Docs](https://developer.apple.com/sign-in-with-apple/)


---

### 3.4 Apple In-App Purchases

**Description**: Integrate in-app subscriptions or one-time purchases in iOS apps for premium coaching features or ad-free experiences.  
**Documentation**: [In-App Purchase Docs](https://developer.apple.com/in-app-purchase/)


---

### 3.5 DeepSeek-R1 API

**Description**: A specialized AI/ML API for image recognition of gym equipment, workout plan generation, and real-time chat capabilities.  
**Documentation**: *Will be provided by the DeepSeek-R1 vendor.*  

Example request code (similar to the reference PRD):

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

const deepSeekUrl = 'https://api.deepseek.com/chat/completions';
const deepSeekApiKey = '<Your DeepSeek API Key>'; // Replace with your actual key

Future<http.Response> sendDeepSeekRequest(String message) async {
  final body = {
    "model": "deepseek-reasoner",
    "messages": [
      {"role": "system", "content": "You are a helpful fitness trainer."},
      {"role": "user", "content": message}
    ],
    "stream": false,
  };

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $deepSeekApiKey',
  };

  return await http.post(
    Uri.parse(deepSeekUrl),
    headers: headers,
    body: jsonEncode(body),
  );
}
```

---

### 3.6 Phone Camera

**Description**: Access the device’s camera to take pictures of gym equipment for recognition.  
**Key Package**: `image_picker` (or `camera` for more advanced use cases)


---

## 4. Core Functionalities

### 4.1 AI-Powered Strength Training

1. **Equipment Recognition (Camera)**  
   - Use the device’s camera to capture images of gym machines or equipment.  
   - The DeepSeek-R1 API recognizes the equipment and explains proper usage, muscles targeted, and recommended rep ranges.

2. **AI-Optimized Workout Planning**  
   - Collect user data (e.g., fitness goals, available equipment, experience level).  
   - The DeepSeek-R1 API generates personalized workout routines—progressively adapting based on logged performance.

3. **Real-Time Trainer Chat**  
   - Users can converse with the AI about exercise form, alternative exercises, progression tips, and nutrition suggestions.  
   - Chat history is stored in Supabase, allowing users to revisit past tips or continue a conversation.

4. **Progress Logging & Analytics**  
   - The app tracks sets, reps, weights used, and overall progress.  
   - AI adjusts future workouts in response to each user’s performance and feedback.

---

### 4.2 Personalized Learning & Guidance

1. **User-Specific Advice**  
   - The AI highlights areas of improvement (e.g., posture, rep speed, rest intervals).  
   - It suggests supplemental exercises, stretches, or mobility work.

2. **Adaptive Training Method**  
   - The app recalculates training frequency, volume, and intensity based on user results.  
   - Offers advanced methods (e.g., supersets, drop sets) for experienced users who want more challenge.

3. **Study/Reference Material** (Optional)  
   - Provide quick guides or short videos on exercise form—especially helpful for beginners.  
   - Potentially generate short “cheat sheets” for advanced lifting techniques.

---

### 4.3 User Management & Security

1. **User Authentication**  
   - Sign in with Apple, email/password, or other secure methods (similar to the original reference).  
   - All personal data (e.g., progress, workouts) is protected and only accessible to the user.

2. **User Data Storage**  
   - Supabase stores user workouts, chat history, and preferences.  
   - Sensitive data (like payment info) is handled securely via Apple In-App Purchases and/or other secure payment gateways.

3. **Premium Features**  
   - Offer advanced personalization, form-checking tips, or specialized routines behind a subscription or one-time purchase paywall.  
   - Provide an ad-free environment for paying subscribers.

---

### 4.4 Additional Features

1. **Offline Mode**  
   - Users can view their saved workouts or reference materials without an internet connection.  
   - Chat features require connectivity, but prior workout data remains accessible offline.

2. **Achievements & Badges**  
   - Reward users when they reach milestones (e.g., completing 100 workouts, hitting a personal record).

3. **Community Features (Optional)**  
   - Allow sharing workout progress with friends or on social media.  
   - Possibly integrate a forum or group challenges for motivation.

---

## 5. Page Structure

Below is an outline of the main UI pages, following the same organizational style as the reference PRD.

### 5.1 Login Page

- **Requirement**: Users must log in or create an account to unlock the app’s main features.  
- **Privacy & Terms**: Provide options to read and accept Terms of Service and Privacy Policy.

### 5.2 Camera/Equipment Page

- **Camera Access**: Capture photos of gym machines or equipment.  
- **Option for Text Input**: Allow users to text-chat with the AI (e.g., “How should I use a barbell for squats?”).  
- **Live Feed/Background**: Display the real-time camera feed while the user lines up the shot.

### 5.3 Workout Plan & History Page

- **Workout Overview**: Show today’s recommended routine, sets, and reps.  
- **Log & History**: Display past workouts with performance metrics.  
- **Chat Continuation**: Users can open a chat from any workout session and discuss progress or queries with the AI trainer.

### 5.4 Account Page

- **Subscription Management**: View and manage premium features, handle payments, and check subscription status.  
- **Payment History**: Display past transactions, refunds, or purchases.  
- **Profile & Data**: Update user information, goals, and app preferences.  
- **Account Deletion**: Offer a secure and transparent method to remove user data completely.

---

## 6. Suggested Project File Structure

```
fitbod_app/
│
├── android/
├── ios/
├── web/
├── macos/
├── linux/
├── windows/
├── pubspec.yaml
└── lib/
    ├── main.dart
    ├── config/
    │    └── environment.dart         // Environment variables, API keys
    ├── services/
    │    ├── supabase_service.dart    // Supabase initialization and queries
    │    ├── auth_service.dart        // Apple Sign-In, other auth methods
    │    ├── in_app_purchase_service.dart
    │    ├── deepseek_service.dart    // Interactions with DeepSeek-R1
    │    └── camera_service.dart      // Higher-level camera logic if needed
    ├── models/
    │    └── user_model.dart
    │    └── workout_model.dart
    │    └── equipment_model.dart
    ├── providers/                    // If using Provider or Riverpod
    │    └── user_provider.dart
    │    └── workout_provider.dart
    ├── screens/
    │    ├── login/
    │    │    └── login_page.dart
    │    ├── camera/
    │    │    └── camera_page.dart    // For snapping gym equipment photos
    │    ├── workout/
    │    │    └── workout_page.dart   // Show recommended routine, track progress
    │    ├── history/
    │    │    └── history_page.dart
    │    └── account/
    │         └── account_page.dart
    ├── widgets/
    │    └── custom_button.dart
    │    └── exercise_card.dart
    └── utils/
        └── helpers.dart             // Shared utility functions
```

**Notes**:  
- Keep sensitive keys outside the repository (e.g., `.env` files).  
- Maintain clear separation of concerns between services (backend logic), models (data structures), and UI.

---

## 7. Efficiency and Performance Considerations

1. **Backend Calls**  
   - Minimize API requests to DeepSeek-R1 by caching previously recognized equipment or queries.  
   - For real-time AI chat, streamline calls to reduce latency and manage usage costs.

2. **Local Caching & Logging**  
   - Cache frequently accessed user data (recent workouts, recognized machines) in local storage to enhance offline accessibility and speed.  

3. **Image Handling**  
   - Compress images before sending them to the DeepSeek-R1 API for faster processing and reduced bandwidth usage.  
   - Consider limiting image resolution or size if users are on cellular data.

4. **Adaptive Algorithms**  
   - Keep the AI logic efficient—avoid overly frequent plan recalculations.  
   - Use incremental updates (e.g., after each workout) rather than recalculating from scratch.

---

## 8. Conclusion

This PRD outlines **FitBod**—an AI-driven strength training application that helps users optimize their workouts, learn equipment usage through camera recognition, and continuously adapt training routines for faster, safer progress. By integrating DeepSeek-R1 for AI-based insights, Supabase for robust backend services, and offering premium features via in-app purchases, FitBod can deliver a personalized coaching experience accessible to everyone, from beginners to advanced athletes.