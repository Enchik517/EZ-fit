import 'package:uuid/uuid.dart';

class Exercise {
  final String id;
  final String name;
  final String description;
  final String muscleGroup;
  final String equipment;
  final String difficultyLevel;
  final String sets;
  final String reps;
  final String targetMuscleGroup;
  final double? weight;
  final String? instructions; // Инструкции по выполнению
  final List<String>? commonMistakes; // Частые ошибки
  final String? videoUrl; // Ссылка на видео демонстрацию
  final String? imageUrl; // Ссылка на изображение упражнения
  final List<String>? modifications; // Модификации упражнения
  final Duration exerciseTime; // Время выполнения
  final Duration restTime; // Время отдыха
  final String difficulty; // Добавляем для обратной совместимости
  final String? superSetId;
  final String? notes;

  // Новые поля для системы рейтинга
  final double baseRating; // Базовый рейтинг упражнения (1-100)
  final double currentRating; // Текущий рейтинг с учетом всех модификаторов
  final DateTime? lastUsed; // Когда упражнение было использовано последний раз
  final int usageCount; // Сколько раз упражнение было использовано
  final bool isFavorite; // Является ли упражнение избранным
  final int
      userPreference; // Предпочтение пользователя: +1 (нравится), 0 (нейтрально), -1 (не нравится)

  Exercise({
    String? id,
    required this.name,
    required this.description,
    required this.muscleGroup,
    required this.equipment,
    required this.difficultyLevel,
    this.sets = "4", // значение по умолчанию
    this.reps = "10", // значение по умолчанию
    required this.targetMuscleGroup,
    this.weight,
    this.instructions,
    this.commonMistakes,
    this.videoUrl,
    this.imageUrl,
    this.modifications,
    this.exerciseTime = const Duration(seconds: 45),
    this.restTime = const Duration(seconds: 30),
    this.superSetId,
    this.notes,
    this.baseRating = 50.0, // значение по умолчанию
    double? currentRating, // будет вычислено, если не задано
    this.lastUsed,
    this.usageCount = 0,
    this.isFavorite = false,
    this.userPreference = 0,
  })  : id = id ?? name.replaceAll(' ', '_').toLowerCase(),
        difficulty = difficultyLevel,
        currentRating = currentRating ?? baseRating; // Инициализируем рейтинг

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    String? muscleGroup,
    String? equipment,
    String? difficultyLevel,
    String? sets,
    String? reps,
    String? targetMuscleGroup,
    double? weight,
    String? instructions,
    List<String>? commonMistakes,
    String? videoUrl,
    String? imageUrl,
    List<String>? modifications,
    Duration? exerciseTime,
    Duration? restTime,
    String? superSetId,
    String? notes,
    double? baseRating,
    double? currentRating,
    DateTime? lastUsed,
    int? usageCount,
    bool? isFavorite,
    int? userPreference,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      targetMuscleGroup: targetMuscleGroup ?? this.targetMuscleGroup,
      weight: weight ?? this.weight,
      instructions: instructions ?? this.instructions,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      modifications: modifications ?? this.modifications,
      exerciseTime: exerciseTime ?? this.exerciseTime,
      restTime: restTime ?? this.restTime,
      superSetId: superSetId ?? this.superSetId,
      notes: notes ?? this.notes,
      baseRating: baseRating ?? this.baseRating,
      currentRating: currentRating ?? this.currentRating,
      lastUsed: lastUsed ?? this.lastUsed,
      usageCount: usageCount ?? this.usageCount,
      isFavorite: isFavorite ?? this.isFavorite,
      userPreference: userPreference ?? this.userPreference,
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    String? processedSuperSetId;
    if (json['superSetId'] != null) {
      if (json['superSetId'] is String) {
        processedSuperSetId = json['superSetId'];
      } else if (json['superSetId'] is List) {
        processedSuperSetId = (json['superSetId'] as List).first.toString();
      }
    }

    // Логируем данные видео для отладки
    final videoUrl = json['videoUrl'] as String?;
    final imageUrl = json['imageUrl'] as String?;
    final name = json['name']?.toString() ?? 'Unknown Exercise';
    print('📹 Десериализация упражнения: $name');
    print('📹 URL видео из JSON: $videoUrl');
    print('🖼️ URL изображения из JSON: $imageUrl');

    return Exercise(
      id: json['id']?.toString(),
      name: name,
      description:
          json['description']?.toString() ?? 'No description available',
      muscleGroup: json['muscleGroup']?.toString() ?? 'Not specified',
      equipment: json['equipment']?.toString() ?? 'No equipment',
      difficultyLevel: json['difficultyLevel']?.toString() ?? 'Beginner',
      targetMuscleGroup: json['targetMuscleGroup']?.toString() ??
          json['muscleGroup']?.toString() ??
          'Not specified',
      sets: json['sets']?.toString() ?? "4",
      reps: json['reps']?.toString() ?? "10",
      weight: json['weight'] as double?,
      instructions: json['instructions'] as String?,
      commonMistakes: (json['commonMistakes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      videoUrl: videoUrl,
      imageUrl: imageUrl,
      modifications: (json['modifications'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      exerciseTime: Duration(seconds: json['exerciseTime'] as int? ?? 45),
      restTime: Duration(seconds: json['restTime'] as int? ?? 30),
      superSetId: processedSuperSetId,
      notes: json['notes'] as String?,
      baseRating: (json['baseRating'] as num?)?.toDouble() ?? 50.0,
      currentRating: (json['currentRating'] as num?)?.toDouble(),
      lastUsed:
          json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
      usageCount: json['usageCount'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      userPreference: json['userPreference'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    // Удаляем null значения и конвертируем типы для совместимости с PostgreSQL
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'difficultyLevel': difficultyLevel,
      'difficulty': difficultyLevel, // Для совместимости
      'targetMuscleGroup': targetMuscleGroup,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'instructions': instructions ?? '',
      'commonMistakes': commonMistakes ?? [],
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'modifications': modifications ?? [],
      'exerciseTime': exerciseTime.inSeconds,
      'restTime': restTime.inSeconds,
      'superSetId': superSetId,
      'notes': notes,
      'baseRating': baseRating,
      'currentRating': currentRating ?? baseRating,
      'lastUsed': lastUsed?.toIso8601String(),
      'usageCount': usageCount,
      'userPreference': userPreference,
      'isFavorite': isFavorite,
    };

    // Удаляем null значения
    map.removeWhere((key, value) => value == null);

    return map;
  }

  static final List<Exercise> sampleExercises = [
    Exercise(
      name: 'Жим гантелей',
      description: 'Жим гантелей лежа на скамье',
      muscleGroup: 'chest',
      equipment: 'dumbbells',
      difficultyLevel: 'Intermediate',
      targetMuscleGroup: 'chest',
      sets: "4",
      reps: "12",
      superSetId: "chest_triceps_1",
      instructions: 'Лягте на скамью, гантели на уровне груди, выжимайте вверх',
      exerciseTime: const Duration(seconds: 45),
      restTime: const Duration(seconds: 30),
    ),
    Exercise(
      name: 'Разгибания на трицепс',
      description: 'Разгибания рук на трицепс с гантелями',
      muscleGroup: 'triceps',
      equipment: 'dumbbells',
      difficultyLevel: 'Intermediate',
      targetMuscleGroup: 'triceps',
      sets: "4",
      reps: "15",
      superSetId: "chest_triceps_1",
      instructions: 'Поднимите гантели за голову и разгибайте руки',
      exerciseTime: const Duration(seconds: 45),
      restTime: const Duration(seconds: 30),
    ),
    Exercise(
      name: 'Подтягивания',
      description: 'Подтягивания широким хватом',
      muscleGroup: 'back',
      equipment: 'pullup_bar',
      difficultyLevel: 'Advanced',
      targetMuscleGroup: 'back',
      sets: "3",
      reps: "8",
      superSetId: "back_biceps_1",
      instructions: 'Подтягивайтесь к перекладине, сводя лопатки',
      exerciseTime: const Duration(seconds: 45),
      restTime: const Duration(seconds: 30),
    ),
    Exercise(
      name: 'Сгибания на бицепс',
      description: 'Сгибания рук на бицепс с гантелями',
      muscleGroup: 'biceps',
      equipment: 'dumbbells',
      difficultyLevel: 'Intermediate',
      targetMuscleGroup: 'biceps',
      sets: "3",
      reps: "12",
      superSetId: "back_biceps_1",
      instructions: 'Выполняйте сгибания рук с гантелями стоя',
      exerciseTime: const Duration(seconds: 45),
      restTime: const Duration(seconds: 30),
    ),
    Exercise(
      name: 'Приседания',
      description: 'Приседания с гантелями',
      muscleGroup: 'legs',
      equipment: 'dumbbells',
      difficultyLevel: 'Intermediate',
      targetMuscleGroup: 'legs',
      sets: "4",
      reps: "15",
      superSetId: "legs_1",
      instructions: 'Приседайте с гантелями у плеч',
      exerciseTime: const Duration(seconds: 45),
      restTime: const Duration(seconds: 30),
    ),
    Exercise(
      name: 'Выпады',
      description: 'Выпады с гантелями',
      muscleGroup: 'legs',
      equipment: 'dumbbells',
      difficultyLevel: 'Intermediate',
      targetMuscleGroup: 'legs',
      sets: "4",
      reps: "12",
      superSetId: "legs_1",
      instructions: 'Выполняйте выпады поочередно каждой ногой',
      exerciseTime: const Duration(seconds: 45),
      restTime: const Duration(seconds: 30),
    ),
    Exercise(
      name: 'Икры стоя',
      description: 'Подъемы на носки стоя',
      muscleGroup: 'calves',
      equipment: 'dumbbells',
      difficultyLevel: 'Beginner',
      targetMuscleGroup: 'calves',
      sets: "4",
      reps: "20",
      superSetId: "legs_1",
      instructions: 'Поднимайтесь на носки с гантелями в руках',
      exerciseTime: const Duration(seconds: 45),
      restTime: const Duration(seconds: 30),
    ),
    Exercise(
      name: 'Жим в тренажере',
      description: 'Жим от груди в тренажере',
      muscleGroup: 'shoulders',
      equipment: 'machine',
      difficultyLevel: 'Intermediate',
      targetMuscleGroup: 'shoulders',
      sets: "3",
      reps: "12",
      superSetId: "shoulders_1",
      instructions: 'Выполняйте жим от груди в тренажере',
      exerciseTime: const Duration(seconds: 45),
      restTime: const Duration(seconds: 30),
    ),
    Exercise(
      name: 'Разведения гантелей',
      description: 'Разведения гантелей в стороны',
      muscleGroup: 'shoulders',
      equipment: 'dumbbells',
      difficultyLevel: 'Intermediate',
      targetMuscleGroup: 'shoulders',
      sets: "3",
      reps: "15",
      superSetId: "shoulders_1",
      instructions: 'Разводите гантели в стороны до уровня плеч',
      exerciseTime: const Duration(seconds: 45),
      restTime: const Duration(seconds: 30),
    ),
    Exercise(
      name: 'Подъемы перед собой',
      description: 'Подъемы гантелей перед собой',
      muscleGroup: 'shoulders',
      equipment: 'dumbbells',
      difficultyLevel: 'Beginner',
      targetMuscleGroup: 'shoulders',
      sets: "3",
      reps: "15",
      superSetId: "shoulders_1",
      instructions: 'Поднимайте гантели перед собой до уровня плеч',
      exerciseTime: const Duration(seconds: 45),
      restTime: const Duration(seconds: 30),
    ),
  ];

  // Упрощенный конструктор для создания базовых упражнений
  factory Exercise.basic({
    required String name,
    required String targetMuscleGroup,
    required String equipment,
    String? sets,
    String? reps,
    String difficulty = 'Beginner',
    String? description,
    String? superSetId,
  }) {
    return Exercise(
      name: name,
      description: description ?? 'Basic exercise',
      muscleGroup: targetMuscleGroup,
      equipment: equipment,
      difficultyLevel: difficulty,
      targetMuscleGroup: targetMuscleGroup,
      sets: sets ?? "4",
      reps: reps ?? "10",
      superSetId: superSetId,
    );
  }

  // Метод для вычисления текущего рейтинга на основе различных факторов
  double calculateCurrentRating() {
    double rating = baseRating;

    // Применяем предпочтения пользователя
    rating += userPreference * 15.0; // +15 для like, -15 для dislike

    // Снижаем приоритет недавно использованных упражнений
    if (lastUsed != null) {
      final daysSinceLastUse = DateTime.now().difference(lastUsed!).inDays;
      if (daysSinceLastUse < 7) {
        // Упражнение использовалось в течение последней недели
        rating -= 10.0 *
            (7 - daysSinceLastUse) /
            7; // Больше штраф для недавно использованных
      }
    }

    // Повышаем рейтинг избранных упражнений
    if (isFavorite) {
      rating += 20.0;
    }

    // Ограничиваем рейтинг диапазоном 1-100
    return rating.clamp(1.0, 100.0);
  }

  // Обновляем рейтинг при использовании упражнения
  Exercise markAsUsed() {
    return copyWith(
      lastUsed: DateTime.now(),
      usageCount: usageCount + 1,
      currentRating: calculateCurrentRating() -
          10.0, // Временно снижаем рейтинг после использования
    );
  }

  // Обновляем предпочтение пользователя (like или dislike)
  Exercise updateUserPreference(int newPreference) {
    return copyWith(
      userPreference: newPreference,
      currentRating: null, // Пересчитаем при создании нового объекта
    );
  }

  // Переключаем статус избранного
  Exercise toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, videoUrl: $videoUrl, muscleGroup: $muscleGroup, equipment: $equipment, difficultyLevel: $difficultyLevel)';
  }
}
