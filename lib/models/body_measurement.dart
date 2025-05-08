class BodyMeasurement {
  final DateTime date;
  final double weight; // in kg
  final Map<String, double> measurements; // name -> value in cm
  final String? note;

  BodyMeasurement({
    required this.date,
    required this.weight,
    required this.measurements,
    this.note,
  });

  static const List<String> defaultMeasurements = [
    'Chest',
    'Waist',
    'Hips',
    'Biceps (L)',
    'Biceps (R)',
    'Thigh (L)',
    'Thigh (R)',
    'Calf (L)',
    'Calf (R)',
  ];
} 